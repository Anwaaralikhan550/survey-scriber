import { IsInt, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class FinaliseDto {
  /** The version the owner approved and is finalising. Anything else is refused. */
  @IsInt()
  @Min(1)
  @Max(2147483647)
  expectedReportVersion!: number;
}

export class ReopenDto extends FinaliseDto {
  /** Why the final report is being opened again. Kept with the earlier final version. */
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
