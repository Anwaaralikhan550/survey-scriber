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
  Matches,
  ValidateIf,
} from 'class-validator';
import { Type } from 'class-transformer';
import {
  BookingChangeRequestType,
  BookingChangeRequestStatus,
} from '@prisma/client';

// ===========================
// Client DTOs
// ===========================

export class CreateBookingChangeRequestDto {
  @ApiProperty({
    description: 'Booking ID to request change for',
  })
  @IsUUID()
  bookingId: string;

  @ApiProperty({
    description: 'Type of change request',
    enum: BookingChangeRequestType,
  })
  @IsEnum(BookingChangeRequestType)
  type: BookingChangeRequestType;

  @ApiPropertyOptional({
    description: 'Proposed new date (required for RESCHEDULE)',
    example: '2025-02-15',
  })
  @ValidateIf((o) => o.type === BookingChangeRequestType.RESCHEDULE)
  @IsDateString()
  proposedDate?: string;

  @ApiPropertyOptional({
    description: 'Proposed new start time (required for RESCHEDULE)',
    example: '09:00',
  })
  @ValidateIf((o) => o.type === BookingChangeRequestType.RESCHEDULE)
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'proposedStartTime must be in HH:MM format',
  })
  proposedStartTime?: string;

  @ApiPropertyOptional({
    description: 'Proposed new end time (required for RESCHEDULE)',
    example: '11:00',
  })
  @ValidateIf((o) => o.type === BookingChangeRequestType.RESCHEDULE)
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/, {
    message: 'proposedEndTime must be in HH:MM format',
  })
  proposedEndTime?: string;

  @ApiPropertyOptional({
    description: 'Reason for the change request',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  reason?: string;
}

export class ClientBookingChangeRequestsQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by type',
    enum: BookingChangeRequestType,
  })
  @IsOptional()
  @IsEnum(BookingChangeRequestType)
  type?: BookingChangeRequestType;

  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: BookingChangeRequestStatus,
  })
  @IsOptional()
  @IsEnum(BookingChangeRequestStatus)
  status?: BookingChangeRequestStatus;

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

export class StaffBookingChangeRequestsQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by type',
    enum: BookingChangeRequestType,
  })
  @IsOptional()
  @IsEnum(BookingChangeRequestType)
  type?: BookingChangeRequestType;

  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: BookingChangeRequestStatus,
  })
  @IsOptional()
  @IsEnum(BookingChangeRequestStatus)
  status?: BookingChangeRequestStatus;

  @ApiPropertyOptional({
    description: 'Filter by client ID',
  })
  @IsOptional()
  @IsUUID()
  clientId?: string;

  @ApiPropertyOptional({
    description: 'Filter by booking ID',
  })
  @IsOptional()
  @IsUUID()
  bookingId?: string;

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

export class ApproveBookingChangeRequestDto {
  @ApiPropertyOptional({
    description: 'Optional notes from the reviewer',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reviewNotes?: string;
}

export class RejectBookingChangeRequestDto {
  @ApiPropertyOptional({
    description: 'Reason for rejection',
    maxLength: 500,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

// ===========================
// Response DTOs
// ===========================

export class BookingChangeRequestClientDto {
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
}

export class BookingChangeRequestReviewerDto {
  @ApiProperty({ description: 'Reviewer user ID' })
  id: string;

  @ApiProperty({ description: 'Reviewer email' })
  email: string;

  @ApiPropertyOptional({ description: 'Reviewer first name' })
  firstName?: string;

  @ApiPropertyOptional({ description: 'Reviewer last name' })
  lastName?: string;
}

export class BookingChangeRequestBookingDto {
  @ApiProperty({ description: 'Booking ID' })
  id: string;

  @ApiProperty({ description: 'Booking date' })
  date: Date;

  @ApiProperty({ description: 'Start time' })
  startTime: string;

  @ApiProperty({ description: 'End time' })
  endTime: string;

  @ApiProperty({ description: 'Booking status' })
  status: string;

  @ApiPropertyOptional({ description: 'Property address' })
  propertyAddress?: string;
}

export class BookingChangeRequestDto {
  @ApiProperty({ description: 'Change request ID' })
  id: string;

  @ApiProperty({ description: 'Booking ID' })
  bookingId: string;

  @ApiProperty({ description: 'Client ID' })
  clientId: string;

  @ApiProperty({
    description: 'Type of change',
    enum: BookingChangeRequestType,
  })
  type: BookingChangeRequestType;

  @ApiPropertyOptional({ description: 'Proposed new date' })
  proposedDate?: Date;

  @ApiPropertyOptional({ description: 'Proposed new start time' })
  proposedStartTime?: string;

  @ApiPropertyOptional({ description: 'Proposed new end time' })
  proposedEndTime?: string;

  @ApiPropertyOptional({ description: 'Reason for change' })
  reason?: string;

  @ApiProperty({
    description: 'Request status',
    enum: BookingChangeRequestStatus,
  })
  status: BookingChangeRequestStatus;

  @ApiProperty({ description: 'Created at timestamp' })
  createdAt: Date;

  @ApiPropertyOptional({ description: 'Reviewed at timestamp' })
  reviewedAt?: Date;

  @ApiPropertyOptional({ description: 'Reviewer user ID' })
  reviewedById?: string;

  @ApiPropertyOptional({ description: 'Booking details' })
  booking?: BookingChangeRequestBookingDto;

  @ApiPropertyOptional({ description: 'Client details (for staff view)' })
  client?: BookingChangeRequestClientDto;

  @ApiPropertyOptional({ description: 'Reviewer details' })
  reviewedBy?: BookingChangeRequestReviewerDto;
}

export class BookingChangeRequestsListResponseDto {
  @ApiProperty({ type: [BookingChangeRequestDto] })
  data: BookingChangeRequestDto[];

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
