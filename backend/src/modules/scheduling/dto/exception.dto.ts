import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  ValidateIf,
} from 'class-validator';

/**
 * Create availability exception
 */
export class CreateExceptionDto {
  @ApiProperty({
    example: '2025-01-15',
    description: 'Date of the exception (ISO 8601 date)',
  })
  @IsDateString()
  date: string;

  @ApiProperty({
    example: false,
    description: 'Whether the surveyor is available on this date (false = day off)',
  })
  @IsBoolean()
  isAvailable: boolean;

  @ApiPropertyOptional({
    example: '10:00',
    description: 'Override start time (required if isAvailable=true)',
  })
  @ValidateIf((o) => o.isAvailable === true)
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'startTime must be in HH:MM format (24-hour)',
  })
  startTime?: string;

  @ApiPropertyOptional({
    example: '14:00',
    description: 'Override end time (required if isAvailable=true)',
  })
  @ValidateIf((o) => o.isAvailable === true)
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'endTime must be in HH:MM format (24-hour)',
  })
  endTime?: string;

  @ApiPropertyOptional({
    example: 'Annual leave',
    description: 'Reason for the exception',
    maxLength: 255,
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  reason?: string;
}

/**
 * Update availability exception
 */
export class UpdateExceptionDto {
  @ApiPropertyOptional({
    example: true,
    description: 'Whether the surveyor is available on this date',
  })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @ApiPropertyOptional({
    example: '10:00',
    description: 'Override start time',
  })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'startTime must be in HH:MM format (24-hour)',
  })
  startTime?: string;

  @ApiPropertyOptional({
    example: '14:00',
    description: 'Override end time',
  })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'endTime must be in HH:MM format (24-hour)',
  })
  endTime?: string;

  @ApiPropertyOptional({
    example: 'Sick leave',
    description: 'Reason for the exception',
    maxLength: 255,
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  reason?: string;
}

/**
 * Response DTO for exception
 */
export class ExceptionResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  userId: string;

  @ApiProperty({ example: '2025-01-15' })
  date: string;

  @ApiProperty({ example: false })
  isAvailable: boolean;

  @ApiPropertyOptional({ example: '10:00' })
  startTime?: string;

  @ApiPropertyOptional({ example: '14:00' })
  endTime?: string;

  @ApiPropertyOptional({ example: 'Annual leave' })
  reason?: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
