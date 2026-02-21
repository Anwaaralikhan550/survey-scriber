import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';

export class UserResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'surveyor@example.com' })
  email: string;

  @ApiProperty({ example: 'John', required: false })
  firstName?: string;

  @ApiProperty({ example: 'Doe', required: false })
  lastName?: string;

  @ApiProperty({ example: '+44 7700 900000', required: false })
  phone?: string;

  @ApiProperty({ example: 'RICS Surveyors Ltd', required: false })
  organization?: string;

  @ApiProperty({ example: 'https://example.com/avatar.png', required: false })
  avatarUrl?: string;

  @ApiProperty({ example: true })
  emailVerified: boolean;

  @ApiProperty({ enum: UserRole, example: 'SURVEYOR' })
  role: UserRole;

  @ApiProperty({ example: true })
  isActive: boolean;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;
}

export class TokenResponseDto {
  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'JWT access token (expires in 15 minutes)',
  })
  accessToken: string;

  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'Refresh token (expires in 7 days)',
  })
  refreshToken: string;

  @ApiProperty({
    example: 900,
    description: 'Access token expiration time in seconds',
  })
  expiresIn: number;
}

/**
 * P0-1 Fix: Login response now includes user object along with tokens
 * This matches Flutter frontend expectations: { user, accessToken, refreshToken, expiresIn }
 */
export class LoginResponseDto {
  @ApiProperty({ type: UserResponseDto })
  user: UserResponseDto;

  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'JWT access token (expires in 15 minutes)',
  })
  accessToken: string;

  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    description: 'Refresh token (expires in 7 days)',
  })
  refreshToken: string;

  @ApiProperty({
    example: 900,
    description: 'Access token expiration time in seconds',
  })
  expiresIn: number;
}

export class RegisterResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'surveyor@example.com' })
  email: string;

  @ApiProperty({ enum: UserRole, example: 'SURVEYOR' })
  role: UserRole;
}

export class LogoutResponseDto {
  @ApiProperty({ example: true })
  success: boolean;
}
