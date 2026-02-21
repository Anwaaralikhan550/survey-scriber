import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsBoolean,
  IsOptional,
  IsInt,
  IsArray,
  IsUUID,
  Min,
  MaxLength,
} from 'class-validator';

// ============================================
// Request DTOs
// ============================================

export class CreateSectionTypeDto {
  @ApiProperty({ description: 'Section type key (kebab-case)', example: 'about-property' })
  @IsString()
  @MaxLength(50)
  key: string;

  @ApiProperty({ description: 'Display label', example: 'About Property' })
  @IsString()
  @MaxLength(255)
  label: string;

  @ApiPropertyOptional({ description: 'Section description' })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ description: 'Icon name', example: 'home' })
  @IsString()
  @MaxLength(50)
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional({ description: 'Display order', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Survey types that use this section', type: [String] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  surveyTypes?: string[];
}

export class UpdateSectionTypeDto {
  @ApiPropertyOptional({ description: 'Display label' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  label?: string;

  @ApiPropertyOptional({ description: 'Section description' })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ description: 'Icon name' })
  @IsString()
  @MaxLength(50)
  @IsOptional()
  icon?: string;

  @ApiPropertyOptional({ description: 'Display order' })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Survey types that use this section', type: [String] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  surveyTypes?: string[];

  @ApiPropertyOptional({ description: 'Whether the section type is active' })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class ReorderSectionTypesDto {
  @ApiProperty({ description: 'Ordered list of section type IDs', type: [String] })
  @IsArray()
  @IsUUID('4', { each: true, message: 'Each sectionTypeId must be a valid UUID' })
  sectionTypeIds: string[];
}

// ============================================
// Response DTOs
// ============================================

export class SectionTypeResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  key: string;

  @ApiProperty()
  label: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  icon?: string;

  @ApiProperty()
  displayOrder: number;

  @ApiProperty({ type: [String] })
  surveyTypes: string[];

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
