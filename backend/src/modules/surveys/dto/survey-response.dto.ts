import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SurveyStatus, SurveyType } from '@prisma/client';

export class AnswerResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'roof_condition' })
  questionKey: string;

  @ApiProperty({ example: 'Good condition with minor wear' })
  value: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;
}

export class SectionResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 'Roof Inspection' })
  title: string;

  @ApiProperty({ example: 1 })
  order: number;

  @ApiPropertyOptional({ example: 'construction' })
  sectionTypeKey?: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;

  @ApiProperty({ type: [AnswerResponseDto] })
  answers: AnswerResponseDto[];
}

export class SurveyResponseDto {
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

  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  parentSurveyId?: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  userId: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;

  @ApiProperty({ type: [SectionResponseDto] })
  sections: SectionResponseDto[];
}
