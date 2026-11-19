import { Transform } from 'class-transformer';
import { IsBoolean, IsISO8601, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

/** Placing or releasing a legal hold: the reason is mandatory and is kept with who and when. */
export class HoldReasonDto {
  @Transform(trim)
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}

export class RunRetentionDto {
  /** Test and rehearsal only: run the job as of another moment. Refused in production. */
  @IsOptional()
  @IsISO8601()
  asOf?: string;

  /** Queue items that gave up retrying are tried again. */
  @IsOptional()
  @IsBoolean()
  retryFailed?: boolean;
}
