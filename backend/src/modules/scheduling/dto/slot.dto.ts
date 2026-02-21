import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsInt,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

/**
 * Query available slots
 */
export class GetSlotsDto {
  @ApiProperty({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description: 'Surveyor user ID',
  })
  @IsUUID()
  surveyorId: string;

  @ApiProperty({
    example: '2025-01-15',
    description: 'Start date for slot query (inclusive)',
  })
  @IsDateString()
  startDate: string;

  @ApiProperty({
    example: '2025-01-21',
    description: 'End date for slot query (inclusive)',
  })
  @IsDateString()
  endDate: string;

  @ApiPropertyOptional({
    example: 60,
    description: 'Slot duration in minutes',
    default: 60,
    minimum: 15,
    maximum: 480,
  })
  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(480)
  slotDuration?: number;
}

/**
 * Single time slot
 */
export class TimeSlotDto {
  @ApiProperty({ example: '2025-01-15' })
  date: string;

  @ApiProperty({ example: '09:00' })
  startTime: string;

  @ApiProperty({ example: '10:00' })
  endTime: string;

  @ApiProperty({ example: true })
  isAvailable: boolean;

  @ApiPropertyOptional({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description: 'Booking ID if slot is occupied',
  })
  bookingId?: string;
}

/**
 * Day with slots
 */
export class DaySlotsDto {
  @ApiProperty({ example: '2025-01-15' })
  date: string;

  @ApiProperty({ example: 1, description: 'Day of week (0=Sunday, 6=Saturday)' })
  dayOfWeek: number;

  @ApiProperty({ example: true, description: 'Whether surveyor works this day' })
  isWorkingDay: boolean;

  @ApiPropertyOptional({ example: 'Annual leave', description: 'Exception reason if applicable' })
  exceptionReason?: string;

  @ApiProperty({ type: [TimeSlotDto] })
  slots: TimeSlotDto[];
}

/**
 * Slots response
 */
export class SlotsResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  surveyorId: string;

  @ApiProperty({ example: '2025-01-15' })
  startDate: string;

  @ApiProperty({ example: '2025-01-21' })
  endDate: string;

  @ApiProperty({ example: 60 })
  slotDuration: number;

  @ApiProperty({ type: [DaySlotsDto] })
  days: DaySlotsDto[];
}
