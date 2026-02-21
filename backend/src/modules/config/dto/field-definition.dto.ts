import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsBoolean,
  IsOptional,
  IsInt,
  Min,
  MaxLength,
  IsEnum,
  IsObject,
} from 'class-validator';
import { FieldType } from '@prisma/client';

// ============================================
// Request DTOs
// ============================================

export class CreateFieldDefinitionDto {
  @ApiProperty({ description: 'Section type identifier', example: 'aboutProperty' })
  @IsString()
  @MaxLength(50)
  sectionType: string;

  @ApiProperty({ description: 'Field key identifier', example: 'property_type' })
  @IsString()
  @MaxLength(100)
  fieldKey: string;

  @ApiProperty({ enum: FieldType, description: 'Field input type' })
  @IsEnum(FieldType)
  fieldType: FieldType;

  @ApiProperty({ description: 'Field label', example: 'Property Type' })
  @IsString()
  @MaxLength(255)
  label: string;

  @ApiPropertyOptional({ description: 'Placeholder text' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  placeholder?: string;

  @ApiPropertyOptional({ description: 'Help text / hint' })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  hint?: string;

  @ApiPropertyOptional({ description: 'Whether the field is required', default: false })
  @IsBoolean()
  @IsOptional()
  isRequired?: boolean;

  @ApiPropertyOptional({ description: 'Display order', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Phrase category ID for dropdown/radio options' })
  @IsString()
  @IsOptional()
  phraseCategoryId?: string;

  @ApiPropertyOptional({ description: 'Validation rules as JSON' })
  @IsObject()
  @IsOptional()
  validationRules?: Record<string, unknown>;

  @ApiPropertyOptional({ description: 'Max lines for textarea fields' })
  @IsInt()
  @Min(1)
  @IsOptional()
  maxLines?: number;

  @ApiPropertyOptional({ description: 'UI group within the section' })
  @IsString()
  @MaxLength(100)
  @IsOptional()
  fieldGroup?: string;

  @ApiPropertyOptional({ description: 'Show field only when this field key has a value' })
  @IsString()
  @MaxLength(100)
  @IsOptional()
  conditionalOn?: string;

  @ApiPropertyOptional({ description: 'Required value for conditional visibility' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  conditionalValue?: string;

  @ApiPropertyOptional({ description: 'Extended help text shown below the field' })
  @IsString()
  @MaxLength(1000)
  @IsOptional()
  description?: string;
}

export class UpdateFieldDefinitionDto {
  @ApiPropertyOptional({ enum: FieldType, description: 'Field input type' })
  @IsEnum(FieldType)
  @IsOptional()
  fieldType?: FieldType;

  @ApiPropertyOptional({ description: 'Field label' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  label?: string;

  @ApiPropertyOptional({ description: 'Placeholder text' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  placeholder?: string;

  @ApiPropertyOptional({ description: 'Help text / hint' })
  @IsString()
  @MaxLength(500)
  @IsOptional()
  hint?: string;

  @ApiPropertyOptional({ description: 'Whether the field is required' })
  @IsBoolean()
  @IsOptional()
  isRequired?: boolean;

  @ApiPropertyOptional({ description: 'Display order' })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Phrase category ID for dropdown/radio options' })
  @IsString()
  @IsOptional()
  phraseCategoryId?: string;

  @ApiPropertyOptional({ description: 'Validation rules as JSON' })
  @IsObject()
  @IsOptional()
  validationRules?: Record<string, unknown>;

  @ApiPropertyOptional({ description: 'Max lines for textarea fields' })
  @IsInt()
  @Min(1)
  @IsOptional()
  maxLines?: number;

  @ApiPropertyOptional({ description: 'Whether the field is active' })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional({ description: 'UI group within the section' })
  @IsString()
  @MaxLength(100)
  @IsOptional()
  fieldGroup?: string;

  @ApiPropertyOptional({ description: 'Show field only when this field key has a value' })
  @IsString()
  @MaxLength(100)
  @IsOptional()
  conditionalOn?: string;

  @ApiPropertyOptional({ description: 'Required value for conditional visibility' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  conditionalValue?: string;

  @ApiPropertyOptional({ description: 'Extended help text shown below the field' })
  @IsString()
  @MaxLength(1000)
  @IsOptional()
  description?: string;
}

export class ReorderFieldsDto {
  @ApiProperty({ description: 'Section type' })
  @IsString()
  sectionType: string;

  @ApiProperty({ description: 'Ordered list of field IDs', type: [String] })
  @IsString({ each: true })
  fieldIds: string[];
}

// ============================================
// Response DTOs
// ============================================

export class FieldDefinitionResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  sectionType: string;

  @ApiProperty()
  fieldKey: string;

  @ApiProperty({ enum: FieldType })
  fieldType: FieldType;

  @ApiProperty()
  label: string;

  @ApiPropertyOptional()
  placeholder?: string;

  @ApiPropertyOptional()
  hint?: string;

  @ApiProperty()
  isRequired: boolean;

  @ApiProperty()
  displayOrder: number;

  @ApiPropertyOptional()
  phraseCategoryId?: string;

  @ApiPropertyOptional()
  validationRules?: Record<string, unknown>;

  @ApiPropertyOptional()
  maxLines?: number;

  @ApiPropertyOptional()
  fieldGroup?: string;

  @ApiPropertyOptional()
  conditionalOn?: string;

  @ApiPropertyOptional()
  conditionalValue?: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}

export class FieldDefinitionWithOptionsDto extends FieldDefinitionResponseDto {
  @ApiPropertyOptional({ description: 'Options for dropdown/radio/checkbox fields' })
  options?: string[];
}
