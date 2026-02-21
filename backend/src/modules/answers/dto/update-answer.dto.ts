import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  MaxLength,
} from 'class-validator';

export class UpdateAnswerDto {
  @ApiPropertyOptional({
    example: 'roof_condition_updated',
    description: 'Unique key identifying the question',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  questionKey?: string;

  @ApiPropertyOptional({
    example: 'Updated: Good condition with minor wear',
    description: 'The answer value',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  value?: string;
}
