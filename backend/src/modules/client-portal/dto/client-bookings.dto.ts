import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

// ===========================
// Query DTOs
// ===========================

export class ClientBookingsQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by booking status',
    enum: BookingStatus,
  })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiPropertyOptional({
    description: 'Page number (1-based)',
    default: 1,
    minimum: 1,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Items per page',
    default: 20,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number = 20;
}

// ===========================
// Response DTOs
// ===========================

export class SurveyorSummaryDto {
  @ApiProperty({ description: 'Surveyor first name' })
  firstName: string;

  @ApiProperty({ description: 'Surveyor last name' })
  lastName: string;

  @ApiPropertyOptional({ description: 'Surveyor phone (for confirmed bookings)' })
  phone?: string;
}

export class ClientBookingDto {
  @ApiProperty({ description: 'Booking ID' })
  id: string;

  @ApiProperty({ description: 'Booking date (YYYY-MM-DD)' })
  date: string;

  @ApiProperty({ description: 'Start time (HH:MM)' })
  startTime: string;

  @ApiProperty({ description: 'End time (HH:MM)' })
  endTime: string;

  @ApiProperty({
    description: 'Booking status',
    enum: BookingStatus,
  })
  status: BookingStatus;

  @ApiPropertyOptional({ description: 'Property address' })
  propertyAddress?: string;

  @ApiPropertyOptional({ description: 'Notes' })
  notes?: string;

  @ApiProperty({
    description: 'Assigned surveyor',
    type: SurveyorSummaryDto,
  })
  surveyor: SurveyorSummaryDto;

  @ApiProperty({ description: 'Booking created timestamp' })
  createdAt: Date;
}

export class PaginationDto {
  @ApiProperty({ description: 'Current page number' })
  page: number;

  @ApiProperty({ description: 'Items per page' })
  limit: number;

  @ApiProperty({ description: 'Total number of items' })
  total: number;

  @ApiProperty({ description: 'Total number of pages' })
  totalPages: number;
}

export class ClientBookingsResponseDto {
  @ApiProperty({
    description: 'List of bookings',
    type: [ClientBookingDto],
  })
  data: ClientBookingDto[];

  @ApiProperty({
    description: 'Pagination info',
    type: PaginationDto,
  })
  pagination: PaginationDto;
}
