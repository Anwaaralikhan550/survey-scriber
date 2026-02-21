import { ApiProperty } from '@nestjs/swagger';
import { MediaType } from '@prisma/client';

export class MediaResponseDto {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  surveyId: string;

  @ApiProperty({ enum: MediaType, example: MediaType.PHOTO })
  type: MediaType;

  @ApiProperty({ example: 'photo_001.jpg' })
  fileName: string;

  @ApiProperty({ example: 'image/jpeg' })
  mimeType: string;

  @ApiProperty({ example: 1024576, description: 'File size in bytes' })
  size: number;

  @ApiProperty({ example: '/api/v1/media/550e8400-e29b-41d4-a716-446655440000/file' })
  url: string;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  updatedAt: Date;
}

export class DeleteMediaResponseDto {
  @ApiProperty({ example: true })
  success: boolean;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;
}
