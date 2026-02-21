import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, IsUUID } from 'class-validator';

// ===========================
// Request DTOs
// ===========================

export class RequestMagicLinkDto {
  @ApiProperty({
    description: 'Client email address',
    example: 'client@example.com',
  })
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class VerifyMagicLinkDto {
  @ApiProperty({
    description: 'Magic link token from email',
    example: 'abc123...',
  })
  @IsString()
  @IsNotEmpty()
  token: string;
}

export class RefreshTokenDto {
  @ApiProperty({
    description: 'Refresh token',
    example: 'eyJhbG...',
  })
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}

// ===========================
// Response DTOs
// ===========================

export class ClientResponseDto {
  @ApiProperty({ description: 'Client ID' })
  id: string;

  @ApiProperty({ description: 'Client email' })
  email: string;

  @ApiPropertyOptional({ description: 'First name' })
  firstName?: string;

  @ApiPropertyOptional({ description: 'Last name' })
  lastName?: string;

  @ApiPropertyOptional({ description: 'Phone number' })
  phone?: string;

  @ApiPropertyOptional({ description: 'Company name' })
  company?: string;
}

export class ClientAuthResponseDto {
  @ApiProperty({ description: 'JWT access token' })
  accessToken: string;

  @ApiProperty({ description: 'Refresh token' })
  refreshToken: string;

  @ApiProperty({ description: 'Access token expiry in seconds' })
  expiresIn: number;

  @ApiProperty({ description: 'Client profile', type: ClientResponseDto })
  client: ClientResponseDto;
}

export class MagicLinkResponseDto {
  @ApiProperty({
    description: 'Success message',
    example: 'If an account exists, a login link has been sent.',
  })
  message: string;
}
