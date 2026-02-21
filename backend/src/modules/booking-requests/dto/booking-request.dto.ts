import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsUUID,
  IsOptional,
  IsDateString,
  MaxLength,
  IsEnum,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { BookingRequestStatus } from '@prisma/client';

// ===========================
// Client DTOs
// ===========================

export class CreateBookingRequestDto {
  @ApiProperty({
    description: 'Property address for the requested booking',
    example: '123 Main Street, London, SW1A 1AA',
    maxLength: 500,
  })
  @IsString()
  @MaxLength(500)
  propertyAddress: string;

  @ApiProperty({
    description: 'Preferred start date for the booking (ISO 8601)',
    example: '2025-02-01',
  })
  @IsDateString()
  preferredStartDate: string;

  @ApiProperty({
    description: 'Preferred end date for the booking (ISO 8601)',
    example: '2025-02-15',
  })
  @IsDateString()
  preferredEndDate: string;

  @ApiPropertyOptional({
    description: 'Additional notes or requirements',
    example: 'Please contact me in the afternoon.',
    maxLength: 2000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}

export class ClientBookingRequestsQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: BookingRequestStatus,
  })
  @IsOptional()
  @IsEnum(BookingRequestStatus)
  status?: BookingRequestStatus;

  @ApiPropertyOptional({
    description: 'Page number (1-based)',
    example: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Items per page (max 100)',
    example: 20,
    default: 20,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

// ===========================
// Staff DTOs
// ===========================

export class StaffBookingRequestsQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: BookingRequestStatus,
  })
  @IsOptional()
  @IsEnum(BookingRequestStatus)
  status?: BookingRequestStatus;

  @ApiPropertyOptional({
    description: 'Filter by client ID',
  })
  @IsOptional()
  @IsUUID()
  clientId?: string;

  @ApiPropertyOptional({
    description: 'Page number (1-based)',
    example: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Items per page (max 100)',
    example: 20,
    default: 20,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

export class ApproveBookingRequestDto {
  @ApiPropertyOptional({
    description: 'Optional notes from the reviewer',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reviewNotes?: string;
}

export class RejectBookingRequestDto {
  @ApiPropertyOptional({
    description: 'Reason for rejection',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;
}

// ===========================
// Response DTOs
// ===========================

export class BookingRequestClientDto {
  @ApiProperty({ description: 'Client ID' })
  id: string;

  @ApiProperty({ description: 'Client email' })
  email: string;

  @ApiPropertyOptional({ description: 'Client first name' })
  firstName?: string;

  @ApiPropertyOptional({ description: 'Client last name' })
  lastName?: string;

  @ApiPropertyOptional({ description: 'Client phone' })
  phone?: string;

  @ApiPropertyOptional({ description: 'Client company' })
  company?: string;
}

export class BookingRequestReviewerDto {
  @ApiProperty({ description: 'Reviewer user ID' })
  id: string;

  @ApiProperty({ description: 'Reviewer email' })
  email: string;

  @ApiPropertyOptional({ description: 'Reviewer first name' })
  firstName?: string;

  @ApiPropertyOptional({ description: 'Reviewer last name' })
  lastName?: string;
}

export class BookingRequestDto {
  @ApiProperty({ description: 'Booking request ID' })
  id: string;

  @ApiProperty({ description: 'Client ID' })
  clientId: string;

  @ApiProperty({ description: 'Property address' })
  propertyAddress: string;

  @ApiProperty({ description: 'Preferred start date' })
  preferredStartDate: Date;

  @ApiProperty({ description: 'Preferred end date' })
  preferredEndDate: Date;

  @ApiPropertyOptional({ description: 'Additional notes' })
  notes?: string;

  @ApiProperty({ description: 'Request status', enum: BookingRequestStatus })
  status: BookingRequestStatus;

  @ApiProperty({ description: 'Created at timestamp' })
  createdAt: Date;

  @ApiPropertyOptional({ description: 'Reviewed at timestamp' })
  reviewedAt?: Date;

  @ApiPropertyOptional({ description: 'Reviewer user ID' })
  reviewedById?: string;

  @ApiPropertyOptional({ description: 'Client details (for staff view)' })
  client?: BookingRequestClientDto;

  @ApiPropertyOptional({ description: 'Reviewer details' })
  reviewedBy?: BookingRequestReviewerDto;
}

export class BookingRequestsListResponseDto {
  @ApiProperty({ type: [BookingRequestDto] })
  data: BookingRequestDto[];

  @ApiProperty({
    description: 'Pagination info',
    example: { page: 1, limit: 20, total: 50, totalPages: 3 },
  })
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
