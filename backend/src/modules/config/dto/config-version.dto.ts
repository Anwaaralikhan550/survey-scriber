import { ApiProperty } from '@nestjs/swagger';

export class ConfigVersionResponseDto {
  @ApiProperty({ description: 'Current config version number' })
  version: number;

  @ApiProperty({ description: 'Last updated timestamp' })
  updatedAt: Date;
}

export class SectionTypeConfigDto {
  @ApiProperty()
  key: string;

  @ApiProperty()
  label: string;

  @ApiProperty({ required: false })
  description?: string;

  @ApiProperty({ required: false })
  icon?: string;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  displayOrder: number;

  @ApiProperty({ type: [String] })
  surveyTypes: string[];
}

export class FullConfigResponseDto {
  @ApiProperty()
  version: number;

  @ApiProperty()
  updatedAt: Date;

  @ApiProperty({ description: 'All phrase categories with their phrases' })
  categories: CategoryWithPhrasesDto[];

  @ApiProperty({ description: 'All field definitions grouped by section' })
  fields: Record<string, FieldConfigDto[]>;

  @ApiProperty({ description: 'All section type definitions', type: [SectionTypeConfigDto] })
  sectionTypes: SectionTypeConfigDto[];
}

export class CategoryWithPhrasesDto {
  @ApiProperty()
  slug: string;

  @ApiProperty()
  displayName: string;

  @ApiProperty()
  phrases: string[];
}

export class FieldConfigDto {
  @ApiProperty()
  key: string;

  @ApiProperty()
  label: string;

  @ApiProperty()
  type: string;

  @ApiProperty({ required: false })
  hint?: string;

  @ApiProperty({ required: false })
  placeholder?: string;

  @ApiProperty()
  required: boolean;

  @ApiProperty({ required: false })
  options?: string[];

  @ApiProperty({ required: false })
  maxLines?: number;

  @ApiProperty({ required: false })
  group?: string;

  @ApiProperty({ required: false })
  conditionalOn?: string;

  @ApiProperty({ required: false })
  conditionalValue?: string;

  @ApiProperty({ required: false })
  description?: string;
}
