import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import * as nodemailer from 'nodemailer';
import { PrismaService } from '../prisma/prisma.service';
import { EmailTemplatesService } from '../email-templates/email-templates.service';

@Injectable()
export class MagicLinkService {
  private readonly logger = new Logger(MagicLinkService.name);
  private readonly transporter: nodemailer.Transporter | null;
  private readonly fromAddress: string;
  private readonly appName: string;
  private readonly frontendUrl: string;
  private readonly clientPortalUrl: string;
  private readonly magicLinkExpiryMinutes: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly templates: EmailTemplatesService,
  ) {
    // Magic link expiry: use config (in seconds) or default to 15 minutes
    const expirySeconds = this.configService.get<number>('MAGIC_LINK_EXPIRY_SECONDS', 900);
    this.magicLinkExpiryMinutes = Math.ceil(expirySeconds / 60);
    // SMTP configuration from environment
    const host = this.configService.get<string>('SMTP_HOST');
    const port = this.configService.get<number>('SMTP_PORT') || 587;
    const secure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    this.fromAddress = this.configService.get<string>('SMTP_FROM') || 'noreply@surveyscriber.com';
    this.appName = this.configService.get<string>('APP_NAME') || 'SurveyScriber';
    this.frontendUrl = this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';
    this.clientPortalUrl = this.configService.get<string>('CLIENT_PORTAL_URL') || this.frontendUrl;

    // Create transporter only if SMTP is configured
    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass },
      });
      this.logger.log('SMTP configured for magic link emails');
    } else {
      this.transporter = null;
      this.logger.warn('SMTP not configured - magic link emails will be logged only');
    }
  }

  /**
   * Generate a cryptographically secure magic link token.
   * Returns the plain token (to be sent via email) and its hash (to store in DB).
   */
  generateToken(): { plainToken: string; tokenHash: string } {
    // 64 bytes = 128 hex chars = 512 bits of entropy
    const plainToken = crypto.randomBytes(64).toString('hex');
    const tokenHash = this.hashToken(plainToken);
    return { plainToken, tokenHash };
  }

  /**
   * Hash a token using SHA-256.
   */
  hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  /**
   * Create and store a magic link for a client.
   * Returns the plain token to be sent via email.
   */
  async createMagicLink(clientId: string): Promise<string> {
    const { plainToken, tokenHash } = this.generateToken();

    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + this.magicLinkExpiryMinutes);

    // Store the hashed token
    await this.prisma.clientMagicLink.create({
      data: {
        clientId,
        tokenHash,
        expiresAt,
      },
    });

    // Clean up old/expired tokens for this client
    await this.prisma.clientMagicLink.deleteMany({
      where: {
        clientId,
        OR: [
          { expiresAt: { lt: new Date() } },
          { usedAt: { not: null } },
        ],
      },
    });

    return plainToken;
  }

  /**
   * Verify a magic link token.
   * Returns the client ID if valid, null otherwise.
   * Marks the token as used.
   */
  async verifyMagicLink(plainToken: string): Promise<string | null> {
    const tokenHash = this.hashToken(plainToken);

    const magicLink = await this.prisma.clientMagicLink.findFirst({
      where: {
        tokenHash,
        usedAt: null,
        expiresAt: { gte: new Date() },
      },
      include: {
        client: true,
      },
    });

    if (!magicLink) {
      this.logger.debug('Magic link verification failed: token not found or expired');
      return null;
    }

    if (!magicLink.client.isActive) {
      this.logger.debug('Magic link verification failed: client inactive');
      return null;
    }

    // Mark token as used (single-use)
    await this.prisma.clientMagicLink.update({
      where: { id: magicLink.id },
      data: { usedAt: new Date() },
    });

    this.logger.log(`Magic link verified for client: ${magicLink.client.email}`);
    return magicLink.clientId;
  }

  /**
   * Send magic link email to client.
   */
  async sendMagicLinkEmail(
    toEmail: string,
    firstName: string | null,
    plainToken: string,
  ): Promise<void> {
    const loginLink = `${this.clientPortalUrl}/client/verify?token=${plainToken}`;
    const displayName = firstName || 'there';

    const { subject, html, text } = await this.templates.render('magic_link', {
      firstName: displayName,
      loginLink,
      expiryMinutes: String(this.magicLinkExpiryMinutes),
    });

    await this.sendEmail(toEmail, subject, html, text);
  }

  private async sendEmail(
    to: string,
    subject: string,
    html: string,
    text: string,
  ): Promise<void> {
    const mailOptions = {
      from: `"${this.appName}" <${this.fromAddress}>`,
      to,
      subject,
      html,
      text,
    };

    if (!this.transporter) {
      // Log email when SMTP not configured (development mode)
      this.logger.log(`[DEV] Magic link email would be sent to: ${to}`);
      this.logger.log(`[DEV] Subject: ${subject}`);
      this.logger.log(`[DEV] Content:\n${text}`);
      return;
    }

    try {
      const info = await this.transporter.sendMail(mailOptions);
      this.logger.log(`Magic link email sent: ${info.messageId} to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send magic link email to ${to}: ${error}`);
      throw error;
    }
  }

}
