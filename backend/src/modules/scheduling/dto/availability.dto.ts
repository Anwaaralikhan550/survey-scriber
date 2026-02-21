import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

/**
 * Single day availability entry
 */
export class DayAvailabilityDto {
  @ApiProperty({
    example: 1,
    description: 'Day of week (0=Sunday, 1=Monday, ..., 6=Saturday)',
    minimum: 0,
    maximum: 6,
  })
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek: number;

  @ApiProperty({
    example: '09:00',
    description: 'Start time in HH:MM format (24-hour)',
  })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'startTime must be in HH:MM format (24-hour)',
  })
  startTime: string;

  @ApiProperty({
    example: '17:00',
    description: 'End time in HH:MM format (24-hour)',
  })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'endTime must be in HH:MM format (24-hour)',
  })
  endTime: string;

  @ApiPropertyOptional({
    example: true,
    description: 'Whether this day is active',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/**
 * Set weekly availability (bulk upsert)
 */
export class SetAvailabilityDto {
  @ApiProperty({
    type: [DayAvailabilityDto],
    description: 'Weekly availability entries (one per day)',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DayAvailabilityDto)
  availability: DayAvailabilityDto[];
}

/**
 * Response DTO for availability
 */
export class AvailabilityResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  userId: string;

  @ApiProperty({ example: 1, description: 'Day of week (0-6)' })
  dayOfWeek: number;

  @ApiProperty({ example: '09:00' })
  startTime: string;

  @ApiProperty({ example: '17:00' })
  endTime: string;

  @ApiProperty({ example: true })
  isActive: boolean;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
