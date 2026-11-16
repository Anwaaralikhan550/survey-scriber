import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsInt, IsOptional, IsString, IsUUID, Max, MaxLength, Min, ValidateNested } from 'class-validator';

export class ReplacePhotoDto {
  @IsInt()
  @Min(1)
  @Max(2147483647)
  expectedReportVersion!: number;
}

export class PhotoUploadDto extends ReplacePhotoDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sectionKey?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  caption?: string;
}

export class PhotoMetaDto extends ReplacePhotoDto {
  @IsOptional()
  @MaxLength(2000)
  caption?: string | null;

  @IsOptional()
  @MaxLength(100)
  sectionKey?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  order?: number;
}

export class AssignItemDto {
  @IsUUID()
  id!: string;

  @IsOptional()
  @MaxLength(100)
  sectionKey?: string | null;

  @IsOptional()
  @MaxLength(2000)
  caption?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  sortOrder?: number;
}

export class AssignPhotosDto extends ReplacePhotoDto {
  @IsArray()
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => AssignItemDto)
  items!: AssignItemDto[];
}
