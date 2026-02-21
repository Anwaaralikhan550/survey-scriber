import { ApiProperty } from '@nestjs/swagger';

export class AnswerResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  sectionId: string;

  @ApiProperty({ example: 'roof_condition' })
  questionKey: string;

  @ApiProperty({ example: 'Good condition with minor wear' })
  value: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;
}

export class DeleteAnswerResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;
}
