import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BookingStatus } from '@prisma/client';
import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Create booking DTO
 */
export class CreateBookingDto {
  @ApiProperty({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description: 'Surveyor user ID',
  })
  @IsUUID()
  surveyorId: string;

  @ApiProperty({
    example: '2025-01-15',
    description: 'Booking date (ISO 8601 date)',
  })
  @IsDateString()
  date: string;

  @ApiProperty({
    example: '10:00',
    description: 'Start time in HH:MM format (24-hour)',
  })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'startTime must be in HH:MM format (24-hour)',
  })
  startTime: string;

  @ApiProperty({
    example: '11:00',
    description: 'End time in HH:MM format (24-hour)',
  })
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'endTime must be in HH:MM format (24-hour)',
  })
  endTime: string;

  @ApiPropertyOptional({
    example: 'John Smith',
    description: 'Client name',
    maxLength: 255,
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  clientName?: string;

  @ApiPropertyOptional({
    example: '+44 7700 900000',
    description: 'Client phone number',
    maxLength: 50,
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  clientPhone?: string;

  @ApiPropertyOptional({
    example: 'john.smith@example.com',
    description: 'Client email address',
  })
  @IsOptional()
  @IsEmail()
  @MaxLength(255)
  clientEmail?: string;

  @ApiPropertyOptional({
    example: '123 Main Street, London, SW1A 1AA',
    description: 'Property address for the inspection',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  propertyAddress?: string;

  @ApiPropertyOptional({
    example: 'Please park in the driveway',
    description: 'Additional notes for the booking',
    maxLength: 2000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}

/**
 * Update booking DTO
 */
export class UpdateBookingDto {
  @ApiPropertyOptional({
    example: '2025-01-16',
    description: 'New booking date',
  })
  @IsOptional()
  @IsDateString()
  date?: string;

  @ApiPropertyOptional({
    example: '11:00',
    description: 'New start time',
  })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'startTime must be in HH:MM format (24-hour)',
  })
  startTime?: string;

  @ApiPropertyOptional({
    example: '12:00',
    description: 'New end time',
  })
  @IsOptional()
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'endTime must be in HH:MM format (24-hour)',
  })
  endTime?: string;

  @ApiPropertyOptional({
    example: 'Jane Doe',
    description: 'Updated client name',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  clientName?: string;

  @ApiPropertyOptional({
    example: '+44 7700 900001',
    description: 'Updated client phone',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  clientPhone?: string;

  @ApiPropertyOptional({
    example: 'jane.doe@example.com',
    description: 'Updated client email',
  })
  @IsOptional()
  @IsEmail()
  @MaxLength(255)
  clientEmail?: string;

  @ApiPropertyOptional({
    example: '456 High Street, London, W1A 1AB',
    description: 'Updated property address',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  propertyAddress?: string;

  @ApiPropertyOptional({
    example: 'Updated notes',
    description: 'Updated notes',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}

/**
 * Update booking status DTO
 */
export class UpdateBookingStatusDto {
  @ApiProperty({
    enum: BookingStatus,
    example: 'CONFIRMED',
    description: 'New booking status',
  })
  @IsEnum(BookingStatus)
  status: BookingStatus;
}

/**
 * List bookings query DTO
 */
export class ListBookingsDto {
  @ApiPropertyOptional({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description: 'Filter by surveyor ID',
  })
  @IsOptional()
  @IsUUID()
  surveyorId?: string;

  @ApiPropertyOptional({
    enum: BookingStatus,
    example: 'PENDING',
    description: 'Filter by status',
  })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;

  @ApiPropertyOptional({
    example: '2025-01-01',
    description: 'Filter bookings from this date (inclusive)',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    example: '2025-01-31',
    description: 'Filter bookings until this date (inclusive)',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({
    example: 1,
    description: 'Page number (1-based)',
    default: 1,
    minimum: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    example: 20,
    description: 'Items per page',
    default: 20,
    minimum: 1,
    maximum: 100,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

/**
 * Booking response DTO
 */
export class BookingResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  surveyorId: string;

  @ApiProperty({ example: '2025-01-15' })
  date: string;

  @ApiProperty({ example: '10:00' })
  startTime: string;

  @ApiProperty({ example: '11:00' })
  endTime: string;

  @ApiProperty({ enum: BookingStatus, example: 'PENDING' })
  status: BookingStatus;

  @ApiPropertyOptional({ example: 'John Smith' })
  clientName?: string;

  @ApiPropertyOptional({ example: '+44 7700 900000' })
  clientPhone?: string;

  @ApiPropertyOptional({ example: 'john.smith@example.com' })
  clientEmail?: string;

  @ApiPropertyOptional({ example: '123 Main Street, London, SW1A 1AA' })
  propertyAddress?: string;

  @ApiPropertyOptional({ example: 'Please park in the driveway' })
  notes?: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  createdById: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  // Nested surveyor info (optional)
  @ApiPropertyOptional()
  surveyor?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
}

/**
 * Paginated bookings list response
 */
export class BookingListResponseDto {
  @ApiProperty({ type: [BookingResponseDto] })
  data: BookingResponseDto[];

  @ApiProperty({ example: 50 })
  total: number;

  @ApiProperty({ example: 1 })
  page: number;

  @ApiProperty({ example: 20 })
  limit: number;

  @ApiProperty({ example: 3 })
  totalPages: number;
}
