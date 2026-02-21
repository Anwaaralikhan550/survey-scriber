import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SendReportDto {
  @ApiProperty({
    description: 'Recipient email address',
    example: 'client@example.com',
  })
  @IsEmail({}, { message: 'Must be a valid email address' })
  @MaxLength(254, { message: 'Email address is too long' })
  email: string;

  @ApiPropertyOptional({
    description: 'Report format (currently only pdf supported)',
    example: 'pdf',
    default: 'pdf',
  })
  @IsOptional()
  @IsString()
  format?: string;
}

export class SendReportResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: 'Report sent to client@example.com' })
  message: string;

  @ApiProperty({ example: 'client@example.com' })
  recipientEmail: string;
}
