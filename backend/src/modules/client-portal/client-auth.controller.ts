import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  NotFoundException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { SkipThrottle, Throttle } from '@nestjs/throttler';
import { Request as ExpressRequest } from 'express';
import { ClientAuthService } from './client-auth.service';
import { ClientJwtGuard } from './guards/client-jwt.guard';
import { MagicLinkRateLimitGuard } from '../../common/guards/rate-limit.guard';
import {
  RequestMagicLinkDto,
  RefreshTokenDto,
  ClientAuthResponseDto,
  MagicLinkResponseDto,
  ClientResponseDto,
} from './dto/client-auth.dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Auth')
@Controller('client/auth')
export class ClientAuthController {
  constructor(private readonly clientAuthService: ClientAuthService) {}

  @Post('request-magic-link')
  @HttpCode(HttpStatus.OK)
  @SkipThrottle() // Use custom rate limiter instead of global throttler
  @UseGuards(MagicLinkRateLimitGuard)
  @ApiOperation({
    summary: 'Request magic link login',
    description:
      'Sends a magic link email to the client for passwordless authentication. ' +
      'Rate limited to 3 requests per 15 minutes per email/IP.',
  })
  @ApiResponse({
    status: 200,
    description: 'Magic link request processed (always succeeds for security)',
    type: MagicLinkResponseDto,
  })
  @ApiResponse({
    status: 429,
    description: 'Rate limit exceeded',
  })
  async requestMagicLink(
    @Body() dto: RequestMagicLinkDto,
  ): Promise<MagicLinkResponseDto> {
    return this.clientAuthService.requestMagicLink(dto.email);
  }

  @Get('verify')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 verifications per minute per IP (protects against token brute-force)
  @ApiOperation({
    summary: 'Verify magic link token',
    description: 'Verifies the magic link token and returns JWT tokens.',
  })
  @ApiResponse({
    status: 200,
    description: 'Magic link verified, tokens issued',
    type: ClientAuthResponseDto,
  })
  @ApiResponse({
    status: 401,
    description: 'Invalid or expired magic link',
  })
  async verifyMagicLink(
    @Query('token') token: string,
  ): Promise<ClientAuthResponseDto> {
    return this.clientAuthService.verifyMagicLink(token);
  }

  @Post('refresh')
  @Throttle({ default: { limit: 20, ttl: 60000 } }) // 20 refreshes per minute per IP (supports background sync)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Refresh access token',
    description: 'Exchange a valid refresh token for new access and refresh tokens.',
  })
  @ApiResponse({
    status: 200,
    description: 'Tokens refreshed successfully',
    type: ClientAuthResponseDto,
  })
  @ApiResponse({
    status: 401,
    description: 'Invalid or expired refresh token',
  })
  async refreshTokens(
    @Body() dto: RefreshTokenDto,
  ): Promise<ClientAuthResponseDto> {
    return this.clientAuthService.refreshTokens(dto.refreshToken);
  }

  @Post('logout')
  @UseGuards(ClientJwtGuard)
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Logout client',
    description: 'Revokes the refresh token.',
  })
  @ApiResponse({
    status: 200,
    description: 'Logged out successfully',
  })
  async logout(@Body() dto: RefreshTokenDto): Promise<{ success: boolean }> {
    const success = await this.clientAuthService.logout(dto.refreshToken);
    return { success };
  }

  @Get('me')
  @UseGuards(ClientJwtGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Get current client profile',
    description: 'Returns the authenticated client profile.',
  })
  @ApiResponse({
    status: 200,
    description: 'Client profile',
    type: ClientResponseDto,
  })
  async getProfile(@Request() req: ClientRequest): Promise<ClientResponseDto> {
    const client = await this.clientAuthService.getClientById(req.user.id);
    if (!client) {
      throw new NotFoundException('Client not found');
    }
    return {
      id: client.id,
      email: client.email,
      firstName: client.firstName ?? undefined,
      lastName: client.lastName ?? undefined,
      phone: client.phone ?? undefined,
      company: client.company ?? undefined,
    };
  }
}
