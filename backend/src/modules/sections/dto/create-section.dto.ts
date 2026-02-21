import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsInt,
  IsUUID,
  Min,
  MaxLength,
} from 'class-validator';

export class CreateSectionDto {
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
    example: '{"activity_chimney_stacks":["The chimney is brick.","Condition 2."]}',
    description:
      'JSON-encoded phrase engine output per screen. ' +
      'Keys are screen IDs, values are arrays of phrase strings.',
  })
  @IsOptional()
  @IsString()
  phraseOutput?: string;

  @ApiPropertyOptional({
    example: 'section_e_outside',
    description: 'V2 section type key (e.g. section_e_outside)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sectionTypeKey?: string;
}
