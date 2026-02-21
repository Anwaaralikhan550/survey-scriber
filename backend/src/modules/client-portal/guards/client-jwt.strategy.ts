import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ClientAuthService, ClientJwtPayload } from '../client-auth.service';

/**
 * JWT Strategy specifically for client portal authentication.
 * Uses the same JWT secret but validates 'type: client' in payload.
 */
@Injectable()
export class ClientJwtStrategy extends PassportStrategy(Strategy, 'client-jwt') {
  constructor(
    private readonly configService: ConfigService,
    private readonly clientAuthService: ClientAuthService,
  ) {
    const secret = configService.get<string>('JWT_ACCESS_SECRET');
    if (!secret) {
      throw new Error('JWT_ACCESS_SECRET is not configured');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  /**
   * Validate the JWT payload.
   * Called by Passport after token signature is verified.
   */
  async validate(payload: ClientJwtPayload) {
    // Ensure this is a client token, not a staff token
    if (payload.type !== 'client') {
      throw new UnauthorizedException('Invalid token type');
    }

    const client = await this.clientAuthService.getClientById(payload.sub);

    if (!client) {
      throw new UnauthorizedException('Client not found');
    }

    if (!client.isActive) {
      throw new UnauthorizedException('Client account is deactivated');
    }

    // Return client object to be attached to request.user
    return {
      id: client.id,
      email: client.email,
      firstName: client.firstName,
      lastName: client.lastName,
      type: 'client' as const,
    };
  }
}
