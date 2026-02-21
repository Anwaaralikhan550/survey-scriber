import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SurveyStatus, SurveyType } from '@prisma/client';
import { IsInt, IsOptional, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { SurveyorSummaryDto, PaginationDto } from './client-bookings.dto';

// ===========================
// Query DTOs
// ===========================

export class ClientReportsQueryDto {
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

export class ClientReportDto {
  @ApiProperty({ description: 'Survey/Report ID' })
  id: string;

  @ApiProperty({ description: 'Report title' })
  title: string;

  @ApiProperty({ description: 'Property address' })
  propertyAddress: string;

  @ApiPropertyOptional({
    description: 'Survey type',
    enum: SurveyType,
  })
  type?: SurveyType;

  @ApiProperty({
    description: 'Survey status (always APPROVED for client view)',
    enum: SurveyStatus,
  })
  status: SurveyStatus;

  @ApiPropertyOptional({ description: 'Job reference number' })
  jobRef?: string;

  @ApiProperty({
    description: 'Surveyor who conducted the survey',
    type: SurveyorSummaryDto,
  })
  surveyor: SurveyorSummaryDto;

  @ApiProperty({ description: 'Survey creation date' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update date' })
  updatedAt: Date;
}

export class ClientReportsResponseDto {
  @ApiProperty({
    description: 'List of approved reports',
    type: [ClientReportDto],
  })
  data: ClientReportDto[];

  @ApiProperty({
    description: 'Pagination info',
    type: PaginationDto,
  })
  pagination: PaginationDto;
}

export class ClientReportDetailDto extends ClientReportDto {
  @ApiPropertyOptional({ description: 'Number of sections in the report' })
  sectionCount?: number;

  @ApiPropertyOptional({ description: 'Number of photos in the report' })
  photoCount?: number;
}
