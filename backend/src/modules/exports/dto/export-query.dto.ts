import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsDateString,
  IsInt,
  Min,
  Max,
  IsEnum,
} from 'class-validator';
import { Type } from 'class-transformer';
import { BookingStatus, InvoiceStatus, SurveyStatus } from '@prisma/client';

/**
 * Base query DTO for all export endpoints
 */
export class BaseExportQueryDto {
  @ApiPropertyOptional({
    description: 'Start date filter (ISO format)',
    example: '2024-01-01',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'End date filter (ISO format)',
    example: '2024-12-31',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({
    description: 'Maximum number of rows to export',
    default: 5000,
    minimum: 1,
    maximum: 10000,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10000)
  @Type(() => Number)
  limit?: number = 5000;
}

/**
 * Query DTO for booking exports
 */
export class BookingExportQueryDto extends BaseExportQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by booking status',
    enum: BookingStatus,
  })
  @IsOptional()
  @IsEnum(BookingStatus)
  status?: BookingStatus;
}

/**
 * Query DTO for invoice exports
 */
export class InvoiceExportQueryDto extends BaseExportQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by invoice status',
    enum: InvoiceStatus,
  })
  @IsOptional()
  @IsEnum(InvoiceStatus)
  status?: InvoiceStatus;
}

/**
 * Query DTO for report/survey exports
 */
export class ReportExportQueryDto extends BaseExportQueryDto {
  @ApiPropertyOptional({
    description: 'Filter by survey status',
    enum: SurveyStatus,
  })
  @IsOptional()
  @IsEnum(SurveyStatus)
  status?: SurveyStatus;
}
