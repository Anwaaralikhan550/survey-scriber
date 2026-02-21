import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateAnswerDto {
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
    example: 'roof_condition',
    description: 'Unique key identifying the question',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  questionKey: string;

  @ApiProperty({
    example: 'Good condition with minor wear',
    description: 'The answer value. Empty string is allowed for optional fields.',
    maxLength: 10000,
  })
  @IsString()
  @MaxLength(10000, {
    message: 'Answer value must not exceed 10,000 characters',
  })
  value: string;
}
