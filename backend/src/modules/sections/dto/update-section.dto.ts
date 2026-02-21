import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsInt,
  Min,
  MaxLength,
} from 'class-validator';

export class UpdateSectionDto {
  @ApiPropertyOptional({
    example: 'Roof Inspection - Updated',
    description: 'Title of the section',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title?: string;

  @ApiPropertyOptional({
    example: 2,
    description: 'Order of the section within the survey',
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
}
