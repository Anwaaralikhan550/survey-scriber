import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength, MaxLength, Matches } from 'class-validator';

export class ChangePasswordDto {
  @ApiProperty({
    example: 'CurrentPass123!',
    description: 'Current password for verification',
  })
  @IsString()
  @MinLength(1, { message: 'Current password is required' })
  @MaxLength(128)
  currentPassword: string;

  @ApiProperty({
    example: 'NewSecurePass456!',
    description: 'New password (min 8 chars, must include uppercase, lowercase, number)',
    minLength: 8,
  })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters' })
  @MaxLength(128)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9])/, {
    message: 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
  })
  newPassword: string;
}
