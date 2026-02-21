import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsUUID } from 'class-validator';
import { MediaType } from '@prisma/client';

export class UploadMediaDto {
  @ApiProperty({
    description: 'Survey UUID to attach media to',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  surveyId: string;

  @ApiProperty({
    description: 'Type of media being uploaded',
    enum: MediaType,
    example: MediaType.PHOTO,
  })
  @IsEnum(MediaType)
  type: MediaType;
}
