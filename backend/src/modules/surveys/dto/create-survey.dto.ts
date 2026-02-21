import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsArray,
  ValidateNested,
  IsInt,
  Min,
  MaxLength,
  IsUUID,
} from 'class-validator';
import { SurveyStatus, SurveyType } from '@prisma/client';

export class CreateAnswerDto {
  @ApiProperty({
    example: 'roof_condition',
    description: 'Unique key identifying the question',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  questionKey: string;

  @ApiProperty({
    example: 'Good condition with minor wear',
    description: 'The answer value. Empty string is allowed for optional fields. Max 10,000 chars.',
  })
  @IsString()
  @MaxLength(10000)
  value: string;
}

export class CreateSectionDto {
  @ApiProperty({
    example: 'Roof Inspection',
    description: 'Title of the section',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({
    example: 1,
    description: 'Order of the section within the survey',
    default: 0,
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  order?: number;

  @ApiPropertyOptional({
    example: 'construction',
    description: 'Section type key for reliable field definition resolution (e.g. "construction", "rooms", "signature")',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sectionTypeKey?: string;

  @ApiPropertyOptional({
    type: [CreateAnswerDto],
    description: 'Answers within this section',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateAnswerDto)
  answers?: CreateAnswerDto[];
}

export class CreateSurveyDto {
  @ApiPropertyOptional({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description:
      'Client-provided UUID for offline-first sync. ' +
      'If omitted, the server generates an ID.',
  })
  @IsOptional()
  @IsUUID()
  id?: string;

  @ApiProperty({
    example: 'Level 2 Home Survey - 123 Main Street',
    description: 'Title of the survey',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiProperty({
    example: '123 Main Street, London, SW1A 1AA',
    description: 'Property address being surveyed',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  propertyAddress: string;

  @ApiPropertyOptional({
    enum: SurveyStatus,
    example: 'DRAFT',
    description: 'Survey status',
    default: 'DRAFT',
  })
  @IsOptional()
  @IsEnum(SurveyStatus)
  status?: SurveyStatus;

  @ApiPropertyOptional({
    enum: SurveyType,
    example: 'INSPECTION',
    description: 'Survey type (INSPECTION, VALUATION, REINSPECTION, OTHER)',
    default: 'INSPECTION',
  })
  @IsOptional()
  @IsEnum(SurveyType)
  type?: SurveyType;

  @ApiPropertyOptional({
    example: 'JOB-2024-001234',
    description: 'Job reference number',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  jobRef?: string;

  @ApiPropertyOptional({
    example: 'John Smith',
    description: 'Client name for the survey',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  clientName?: string;

  @ApiPropertyOptional({
    example: '550e8400-e29b-41d4-a716-446655440000',
    description: 'Parent survey ID for reinspections',
  })
  @IsOptional()
  @IsUUID()
  parentSurveyId?: string;

  @ApiPropertyOptional({
    type: [CreateSectionDto],
    description: 'Sections within the survey',
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSectionDto)
  sections?: CreateSectionDto[];
}
