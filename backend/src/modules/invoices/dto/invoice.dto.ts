import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsUUID,
  IsOptional,
  IsInt,
  IsNumber,
  Min,
  Max,
  IsArray,
  ArrayMinSize,
  ValidateNested,
  IsEnum,
  IsDateString,
  MinLength,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import { InvoiceStatus } from '@prisma/client';

// ===========================
// Invoice Item DTOs
// ===========================

export class CreateInvoiceItemDto {
  @ApiProperty({ description: 'Item description' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  description: string;

  @ApiProperty({ description: 'Quantity', default: 1 })
  @IsInt()
  @Min(1)
  quantity: number = 1;

  @ApiProperty({ description: 'Unit price in pence' })
  @IsInt()
  @Min(0)
  unitPrice: number;

  @ApiPropertyOptional({ description: 'Item type (SURVEY, TRAVEL, OTHER)' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  itemType?: string;
}

export class InvoiceItemDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  quantity: number;

  @ApiProperty({ description: 'Unit price in pence' })
  unitPrice: number;

  @ApiProperty({ description: 'Total amount in pence (quantity * unitPrice)' })
  amount: number;

  @ApiPropertyOptional()
  itemType?: string;
}

// ===========================
// Create Invoice DTO
// ===========================

export class CreateInvoiceDto {
  @ApiProperty({ description: 'Client ID' })
  @IsUUID()
  clientId: string;

  @ApiPropertyOptional({ description: 'Booking ID (optional)' })
  @IsOptional()
  @IsUUID()
  bookingId?: string;

  @ApiProperty({ description: 'Invoice line items (at least 1 required)', type: [CreateInvoiceItemDto] })
  @IsArray()
  @ArrayMinSize(1, { message: 'Invoice must have at least one line item' })
  @ValidateNested({ each: true })
  @Type(() => CreateInvoiceItemDto)
  items: CreateInvoiceItemDto[];

  @ApiPropertyOptional({ description: 'Invoice notes (max 2000 chars)' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @ApiPropertyOptional({ description: 'Tax rate percentage (default: 20)', default: 20 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  taxRate?: number;

  @ApiPropertyOptional({ description: 'Due date (ISO format)' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ description: 'Payment terms' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  paymentTerms?: string;
}

// ===========================
// Update Invoice DTO
// ===========================

export class UpdateInvoiceDto {
  @ApiPropertyOptional({ description: 'Invoice line items', type: [CreateInvoiceItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateInvoiceItemDto)
  items?: CreateInvoiceItemDto[];

  @ApiPropertyOptional({ description: 'Invoice notes (max 2000 chars)' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @ApiPropertyOptional({ description: 'Tax rate percentage' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  taxRate?: number;

  @ApiPropertyOptional({ description: 'Due date (ISO format)' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ description: 'Payment terms' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  paymentTerms?: string;
}

// ===========================
// Query DTOs
// ===========================

export class InvoicesQueryDto {
  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Items per page', default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({ description: 'Filter by status', enum: InvoiceStatus })
  @IsOptional()
  @IsEnum(InvoiceStatus)
  status?: InvoiceStatus;

  @ApiPropertyOptional({ description: 'Filter by client ID' })
  @IsOptional()
  @IsUUID()
  clientId?: string;

  @ApiPropertyOptional({ description: 'From date (ISO format)' })
  @IsOptional()
  @IsDateString()
  fromDate?: string;

  @ApiPropertyOptional({ description: 'To date (ISO format)' })
  @IsOptional()
  @IsDateString()
  toDate?: string;
}

// ===========================
// Action DTOs
// ===========================

export class MarkPaidDto {
  @ApiPropertyOptional({ description: 'Payment date (ISO format), defaults to now' })
  @IsOptional()
  @IsDateString()
  paidDate?: string;
}

export class CancelInvoiceDto {
  @ApiProperty({ description: 'Cancellation reason' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  reason: string;
}

// ===========================
// Response DTOs
// ===========================

export class InvoiceDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  invoiceNumber: string;

  @ApiProperty({ enum: InvoiceStatus })
  status: InvoiceStatus;

  @ApiProperty()
  clientId: string;

  @ApiProperty()
  clientName: string;

  @ApiPropertyOptional()
  bookingId?: string;

  @ApiPropertyOptional()
  issueDate?: string;

  @ApiPropertyOptional()
  dueDate?: string;

  @ApiPropertyOptional()
  paidDate?: string;

  @ApiProperty({ description: 'Subtotal in pence' })
  subtotal: number;

  @ApiProperty({ description: 'Tax rate as percentage' })
  taxRate: number;

  @ApiProperty({ description: 'Tax amount in pence' })
  taxAmount: number;

  @ApiProperty({ description: 'Total in pence' })
  total: number;

  @ApiProperty()
  createdAt: string;
}

export class ClientInfoDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  email: string;

  @ApiPropertyOptional()
  firstName?: string;

  @ApiPropertyOptional()
  lastName?: string;

  @ApiPropertyOptional()
  company?: string;

  @ApiPropertyOptional()
  phone?: string;
}

export class BookingInfoDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  date: string;

  @ApiPropertyOptional()
  propertyAddress?: string;
}

export class CreatedByDto {
  @ApiProperty()
  id: string;

  @ApiPropertyOptional()
  firstName?: string;

  @ApiPropertyOptional()
  lastName?: string;
}

export class InvoiceDetailDto extends InvoiceDto {
  @ApiProperty({ type: [InvoiceItemDto] })
  items: InvoiceItemDto[];

  @ApiPropertyOptional()
  notes?: string;

  @ApiPropertyOptional()
  paymentTerms?: string;

  @ApiPropertyOptional()
  cancellationReason?: string;

  @ApiPropertyOptional()
  cancelledDate?: string;

  @ApiProperty({ type: ClientInfoDto })
  client: ClientInfoDto;

  @ApiPropertyOptional({ type: BookingInfoDto })
  booking?: BookingInfoDto;

  @ApiProperty({ type: CreatedByDto })
  createdBy: CreatedByDto;
}

export class PaginationDto {
  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  total: number;

  @ApiProperty()
  totalPages: number;
}

export class InvoicesResponseDto {
  @ApiProperty({ type: [InvoiceDto] })
  data: InvoiceDto[];

  @ApiProperty({ type: PaginationDto })
  pagination: PaginationDto;
}
