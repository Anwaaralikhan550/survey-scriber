import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type, Transform } from 'class-transformer';
import {
  IsOptional,
  IsEnum,
  IsInt,
  Min,
  Max,
  IsDateString,
  IsString,
  MaxLength,
} from 'class-validator';
import { SurveyStatus, SurveyType } from '@prisma/client';

export class ListSurveysDto {
  @ApiPropertyOptional({
    description: 'Search query - searches title, client name, and property address',
    example: 'Main Street',
    maxLength: 200,
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  @Transform(({ value }) => value?.trim())
  q?: string;

  @ApiPropertyOptional({
    description: 'Page number (1-based)',
    example: 1,
    default: 1,
    minimum: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Number of items per page',
    example: 20,
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

  @ApiPropertyOptional({
    enum: SurveyStatus,
    description: 'Filter by survey status',
    example: 'DRAFT',
  })
  @IsOptional()
  @IsEnum(SurveyStatus)
  status?: SurveyStatus;

  @ApiPropertyOptional({
    enum: SurveyType,
    description: 'Filter by survey type',
    example: 'INSPECTION',
  })
  @IsOptional()
  @IsEnum(SurveyType)
  type?: SurveyType;

  @ApiPropertyOptional({
    description: 'Filter by client name (partial match)',
    example: 'Smith',
    maxLength: 255,
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  @Transform(({ value }) => value?.trim())
  clientName?: string;

  @ApiPropertyOptional({
    description: 'Filter surveys created on or after this date (ISO 8601)',
    example: '2024-01-01T00:00:00.000Z',
  })
  @IsOptional()
  @IsDateString()
  createdFrom?: string;

  @ApiPropertyOptional({
    description: 'Filter surveys created on or before this date (ISO 8601)',
    example: '2024-12-31T23:59:59.999Z',
  })
  @IsOptional()
  @IsDateString()
  createdTo?: string;
}
