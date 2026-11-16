import { IsArray, IsIn, IsInt, IsNotEmpty, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

export class UploadSnapshotDto {
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(2147483647)
  baseVersion?: number;

  @IsString()
  @IsIn(['L2', 'L3', 'VALUATION'])
  reportType!: string;

  @IsArray()
  content!: unknown[];
}

export class OpenLinkDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(128)
  @Matches(/^[A-Za-z0-9_-]+$/)
  token!: string;
}

export class SaveChangesDto {
  @IsInt()
  @Min(1)
  @Max(2147483647)
  baseVersion!: number;

  @IsArray()
  changes!: unknown[];

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}

export class RestoreVersionDto {
  @IsInt()
  @Min(1)
  @Max(2147483647)
  baseVersion!: number;
}
