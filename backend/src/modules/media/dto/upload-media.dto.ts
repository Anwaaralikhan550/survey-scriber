import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';
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

  @ApiProperty({ required: false, description: 'Caption of a photo' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  caption?: string;

  @ApiProperty({ required: false, description: 'Report section the photo belongs to' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sectionKey?: string;

  @ApiProperty({ required: false, description: 'Position of the photo within its section' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  sortOrder?: number;
}
