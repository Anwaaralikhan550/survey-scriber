import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsBoolean,
  IsOptional,
  IsInt,
  Min,
  MaxLength,
  Matches,
} from 'class-validator';

// ============================================
// Request DTOs
// ============================================

export class CreatePhraseCategoryDto {
  @ApiProperty({ description: 'Unique slug identifier', example: 'property_types' })
  @IsString()
  @MaxLength(100)
  @Matches(/^[a-z][a-z0-9_]*$/, {
    message: 'Slug must start with lowercase letter and contain only lowercase letters, numbers, and underscores',
  })
  slug: string;

  @ApiProperty({ description: 'Display name', example: 'Property Types' })
  @IsString()
  @MaxLength(255)
  displayName: string;

  @ApiPropertyOptional({ description: 'Description of the category' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ description: 'Display order for sorting', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;
}

export class UpdatePhraseCategoryDto {
  @ApiPropertyOptional({ description: 'Display name' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  displayName?: string;

  @ApiPropertyOptional({ description: 'Description of the category' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional({ description: 'Display order for sorting' })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Whether the category is active' })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

// ============================================
// Response DTOs
// ============================================

export class PhraseCategoryResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  slug: string;

  @ApiProperty()
  displayName: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiProperty()
  isSystem: boolean;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  displayOrder: number;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;

  @ApiPropertyOptional({ description: 'Number of phrases in this category' })
  phraseCount?: number;
}

export class PhraseCategoryWithPhrasesDto extends PhraseCategoryResponseDto {
  @ApiProperty({ type: () => [PhraseResponseDto] })
  phrases: PhraseResponseDto[];
}

// ============================================
// Phrase DTOs
// ============================================

export class CreatePhraseDto {
  @ApiProperty({ description: 'Category ID' })
  @IsString()
  categoryId: string;

  @ApiProperty({ description: 'Phrase value/text', example: 'Detached House' })
  @IsString()
  @MaxLength(255)
  value: string;

  @ApiPropertyOptional({ description: 'Display order', default: 0 })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Whether this is the default selection' })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class UpdatePhraseDto {
  @ApiPropertyOptional({ description: 'Phrase value/text' })
  @IsString()
  @MaxLength(255)
  @IsOptional()
  value?: string;

  @ApiPropertyOptional({ description: 'Display order' })
  @IsInt()
  @Min(0)
  @IsOptional()
  displayOrder?: number;

  @ApiPropertyOptional({ description: 'Whether the phrase is active' })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional({ description: 'Whether this is the default selection' })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class ReorderPhrasesDto {
  @ApiProperty({ description: 'Category ID' })
  @IsString()
  categoryId: string;

  @ApiProperty({ description: 'Ordered list of phrase IDs', type: [String] })
  @IsString({ each: true })
  phraseIds: string[];
}

export class PhraseResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  categoryId: string;

  @ApiProperty()
  value: string;

  @ApiProperty()
  displayOrder: number;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  isDefault: boolean;

  @ApiPropertyOptional()
  metadata?: Record<string, unknown>;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
