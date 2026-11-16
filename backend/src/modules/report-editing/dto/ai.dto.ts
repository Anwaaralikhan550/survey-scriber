import { IsIn, IsInt, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';
import { SUGGESTION_ACTIONS } from '../ai-guardrails';

export class SuggestDto {
  @IsUUID()
  blockId!: string;

  @IsIn(SUGGESTION_ACTIONS)
  action!: string;

  /** The version the user is looking at. A suggestion for text that has moved on is refused. */
  @IsInt()
  @Min(1)
  @Max(2147483647)
  expectedReportVersion!: number;
}

export class SuggestionOutcomeDto {
  @IsUUID()
  suggestionId!: string;

  @IsUUID()
  blockId!: string;

  @IsIn(['ACCEPTED', 'ACCEPTED_MODIFIED', 'REJECTED'])
  outcome!: string;

  @IsOptional()
  @IsIn(SUGGESTION_ACTIONS)
  action?: string;

  /** Final text length only, never the text itself, so the audit trail carries no report content. */
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(20000)
  finalLength?: number;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  note?: string;
}
