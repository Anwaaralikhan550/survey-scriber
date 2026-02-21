import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SectionResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  surveyId: string;

  @ApiProperty({ example: 'Roof Inspection' })
  title: string;

  @ApiProperty({ example: 1 })
  order: number;

  @ApiPropertyOptional({
    example: '{"activity_chimney_stacks":["The chimney is brick."]}',
    description: 'JSON-encoded phrase engine output per screen',
  })
  phraseOutput?: string | null;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;
}

export class DeleteSectionResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;
}
