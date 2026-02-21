import {
  Injectable,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { ActorType, AuditEntityType } from '@prisma/client';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { MagicLinkService } from './magic-link.service';
import { AuditService, AuditActions } from '../audit/audit.service';
import {
  ClientAuthResponseDto,
  ClientResponseDto,
} from './dto/client-auth.dto';

export interface ClientJwtPayload {
  sub: string;       // Client ID
  email: string;
  type: 'client';    // Distinguishes from staff tokens
}

@Injectable()
export class ClientAuthService {
  private readonly logger = new Logger(ClientAuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly magicLinkService: MagicLinkService,
    private readonly auditService: AuditService,
  ) {}

  /**
   * Request a magic link for client login.
   * SECURITY: Always returns success to prevent email enumeration.
   * Auto-creates client from booking email if not exists.
   */
  async requestMagicLink(email: string): Promise<{ message: string }> {
    const normalizedEmail = email.toLowerCase().trim();

    // Find or create client
    let client = await this.prisma.client.findUnique({
      where: { email: normalizedEmail },
    });

    if (!client) {
      // Check if this email exists in any booking
      const booking = await this.prisma.booking.findFirst({
        where: { clientEmail: normalizedEmail },
        orderBy: { createdAt: 'desc' },
      });

      if (booking) {
        // Auto-create client from booking data
        client = await this.prisma.client.create({
          data: {
            email: normalizedEmail,
            firstName: this.extractFirstName(booking.clientName),
            lastName: this.extractLastName(booking.clientName),
            phone: booking.clientPhone,
          },
        });

        // Link this booking to the new client
        await this.prisma.booking.update({
          where: { id: booking.id },
          data: { clientId: client.id },
        });

        // Also link any other bookings with the same email
        await this.prisma.booking.updateMany({
          where: {
            clientEmail: normalizedEmail,
            clientId: null,
          },
          data: { clientId: client.id },
        });

        this.logger.log(`Auto-created client from booking: ${normalizedEmail}`);
      } else {
        // No client and no booking - silently succeed (security)
        this.logger.debug(`Magic link requested for unknown email: ${normalizedEmail}`);
        return { message: 'If an account exists, a login link has been sent.' };
      }
    }

    if (!client.isActive) {
      this.logger.debug(`Magic link requested for inactive client: ${normalizedEmail}`);
      return { message: 'If an account exists, a login link has been sent.' };
    }

    // Generate and send magic link
    try {
      const token = await this.magicLinkService.createMagicLink(client.id);
      await this.magicLinkService.sendMagicLinkEmail(
        client.email,
        client.firstName,
        token,
      );
    } catch (error) {
      this.logger.error(`Failed to send magic link: ${error}`);
      // Don't throw - always return success for security
    }

    return { message: 'If an account exists, a login link has been sent.' };
  }

  /**
   * Verify magic link token and issue JWT tokens.
   */
  async verifyMagicLink(token: string): Promise<ClientAuthResponseDto> {
    const clientId = await this.magicLinkService.verifyMagicLink(token);

    if (!clientId) {
      throw new UnauthorizedException('Invalid or expired link');
    }

    const client = await this.prisma.client.findUnique({
      where: { id: clientId },
    });

    if (!client || !client.isActive) {
      throw new UnauthorizedException('Invalid or expired link');
    }

    // Audit log: successful magic link verification
    await this.auditService.log({
      actorType: ActorType.CLIENT,
      actorId: client.id,
      action: AuditActions.MAGIC_LINK_VERIFIED,
      entityType: AuditEntityType.AUTH,
      metadata: { email: client.email },
    });

    return this.issueTokens(client);
  }

  /**
   * Refresh client access token.
   */
  async refreshTokens(refreshToken: string): Promise<ClientAuthResponseDto> {
    const tokenHash = this.hashToken(refreshToken);

    const storedToken = await this.prisma.clientRefreshToken.findFirst({
      where: { tokenHash },
      include: { client: true },
    });

    if (!storedToken) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (storedToken.revokedAt) {
      // SEC-AUDIT: Potential token theft - log as security incident
      await this.auditService.log({
        actorType: ActorType.CLIENT,
        actorId: storedToken.clientId,
        action: AuditActions.CLIENT_TOKEN_REUSE_DETECTED,
        entityType: AuditEntityType.AUTH,
        metadata: { reason: 'revoked_token_reuse', severity: 'high' },
      });
      this.logger.warn(`Revoked client token reuse detected: ${storedToken.clientId}`);
      await this.revokeAllClientTokens(storedToken.clientId);
      throw new UnauthorizedException('Refresh token has been revoked');
    }

    if (new Date() > storedToken.expiresAt) {
      await this.prisma.clientRefreshToken.update({
        where: { id: storedToken.id },
        data: { revokedAt: new Date() },
      });
      throw new UnauthorizedException('Refresh token has expired');
    }

    if (!storedToken.client.isActive) {
      throw new UnauthorizedException('Account is deactivated');
    }

    // Revoke old token
    await this.prisma.clientRefreshToken.update({
      where: { id: storedToken.id },
      data: { revokedAt: new Date() },
    });

    return this.issueTokens(storedToken.client);
  }

  /**
   * Logout client by revoking refresh token.
   */
  async logout(refreshToken: string, clientId?: string): Promise<boolean> {
    const tokenHash = this.hashToken(refreshToken);

    // Find token first to get clientId for audit if not provided
    const token = await this.prisma.clientRefreshToken.findFirst({
      where: { tokenHash },
      select: { clientId: true },
    });

    const result = await this.prisma.clientRefreshToken.updateMany({
      where: {
        tokenHash,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });

    // SEC-AUDIT: Log successful client logout for session tracking
    if (result.count > 0) {
      const actorId = clientId || token?.clientId;
      if (actorId) {
        await this.auditService.log({
          actorType: ActorType.CLIENT,
          actorId,
          action: AuditActions.CLIENT_LOGOUT,
          entityType: AuditEntityType.AUTH,
        });
      }
    }

    return true;
  }

  /**
   * Get client by ID (for guards/strategies).
   */
  async getClientById(id: string) {
    return this.prisma.client.findUnique({
      where: { id },
    });
  }

  /**
   * Issue JWT access and refresh tokens for a client.
   */
  private async issueTokens(client: {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
    phone: string | null;
    company: string | null;
  }): Promise<ClientAuthResponseDto> {
    const payload: ClientJwtPayload = {
      sub: client.id,
      email: client.email,
      type: 'client',
    };

    const secret = this.configService.get<string>('JWT_ACCESS_SECRET');
    const expiresInStr = this.configService.get<string>('JWT_ACCESS_EXPIRES_IN') || '15m';
    const expiresIn = this.parseExpirationToSeconds(expiresInStr);

    const accessToken = this.jwtService.sign(payload, {
      secret,
      expiresIn,
    });

    const refreshToken = await this.generateAndStoreRefreshToken(client.id);

    this.logger.log(`Client logged in: ${client.email}`);

    const clientResponse: ClientResponseDto = {
      id: client.id,
      email: client.email,
      firstName: client.firstName ?? undefined,
      lastName: client.lastName ?? undefined,
      phone: client.phone ?? undefined,
      company: client.company ?? undefined,
    };

    return {
      accessToken,
      refreshToken,
      expiresIn,
      client: clientResponse,
    };
  }

  private async generateAndStoreRefreshToken(clientId: string): Promise<string> {
    const refreshToken = crypto.randomBytes(64).toString('hex');
    const tokenHash = this.hashToken(refreshToken);

    const expiresDays = this.configService.get<number>('REFRESH_TOKEN_EXPIRES_DAYS') || 7;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expiresDays);

    await this.prisma.clientRefreshToken.create({
      data: {
        clientId,
        tokenHash,
        expiresAt,
      },
    });

    // Clean up old tokens
    await this.prisma.clientRefreshToken.deleteMany({
      where: {
        clientId,
        expiresAt: { lt: new Date() },
      },
    });

    return refreshToken;
  }

  private async revokeAllClientTokens(clientId: string): Promise<void> {
    await this.prisma.clientRefreshToken.updateMany({
      where: {
        clientId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private parseExpirationToSeconds(expiration: string): number {
    const match = expiration.match(/^(\d+)([smhd])$/);
    if (!match) return 900;

    const value = parseInt(match[1], 10);
    const unit = match[2];

    switch (unit) {
      case 's': return value;
      case 'm': return value * 60;
      case 'h': return value * 3600;
      case 'd': return value * 86400;
      default: return 900;
    }
  }

  private extractFirstName(fullName: string | null): string | null {
    if (!fullName) return null;
    const parts = fullName.trim().split(/\s+/);
    return parts[0] || null;
  }

  private extractLastName(fullName: string | null): string | null {
    if (!fullName) return null;
    const parts = fullName.trim().split(/\s+/);
    return parts.length > 1 ? parts.slice(1).join(' ') : null;
  }
}
