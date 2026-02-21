import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SurveyStatus, SurveyType } from '@prisma/client';

export class SurveyListItemDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'Level 2 Home Survey - 123 Main Street' })
  title: string;

  @ApiProperty({ example: '123 Main Street, London, SW1A 1AA' })
  propertyAddress: string;

  @ApiProperty({ enum: SurveyStatus, example: 'DRAFT' })
  status: SurveyStatus;

  @ApiPropertyOptional({ enum: SurveyType, example: 'INSPECTION' })
  type?: SurveyType;

  @ApiPropertyOptional({ example: 'JOB-2024-001234' })
  jobRef?: string;

  @ApiPropertyOptional({ example: 'John Smith' })
  clientName?: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  userId: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;
}

export class PaginationMetaDto {
  @ApiProperty({ example: 1, description: 'Current page number' })
  page: number;

  @ApiProperty({ example: 20, description: 'Items per page' })
  limit: number;

  @ApiProperty({ example: 100, description: 'Total number of items' })
  total: number;

  @ApiProperty({ example: 5, description: 'Total number of pages' })
  totalPages: number;

  @ApiProperty({ example: true, description: 'Whether there is a next page' })
  hasNext: boolean;

  @ApiProperty({ example: false, description: 'Whether there is a previous page' })
  hasPrev: boolean;
}

export class SurveyListResponseDto {
  @ApiProperty({ type: [SurveyListItemDto] })
  data: SurveyListItemDto[];

  @ApiProperty({ type: PaginationMetaDto })
  meta: PaginationMetaDto;
}

export class DeleteSurveyResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  deletedAt: Date;
}
