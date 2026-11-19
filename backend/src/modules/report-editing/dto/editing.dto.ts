import { IsArray, IsIn, IsInt, IsISO8601, IsNotEmpty, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

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

  /** What the original report was built from (Remote Editor spec v1.4 section 6.1). All optional. */
  @IsOptional()
  @IsString()
  @MaxLength(100)
  treeVersionId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  phraseBankVersionId?: string;

  @IsOptional()
  @IsISO8601()
  generatedAt?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  appVersion?: string;
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
