import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsObject, IsOptional, IsString } from 'class-validator';

/** Phrase banks are stored as versioned snapshots next to the V2 trees. */
export const PHRASE_BANK_TYPES = ['inspection_phrases', 'valuation_phrases'] as const;
export type PhraseBankType = (typeof PHRASE_BANK_TYPES)[number];

export class UploadPhraseBankDto {
  @ApiProperty({ enum: PHRASE_BANK_TYPES, example: 'inspection_phrases' })
  @IsIn([...PHRASE_BANK_TYPES], {
    message: 'bankType must be "inspection_phrases" or "valuation_phrases"',
  })
  bankType: string;

  @ApiProperty({
    description:
      'Whole phrase bank. inspection_phrases: {key: sentence}. valuation_phrases: {meta, templates: {id: {text, ...}}}',
    type: 'object',
    additionalProperties: true,
  })
  @IsObject()
  @IsNotEmpty()
  bank: Record<string, unknown>;
}

export class PhraseBankUploadResponseDto {
  @ApiProperty() id: string;
  @ApiProperty() bankType: string;
  @ApiProperty() version: number;
  @ApiProperty() sizeBytes: number;
  @ApiProperty() checksum: string;
  @ApiProperty() publishedAt: Date;
  @ApiProperty({ description: 'true when the bank was identical to the latest one (no new version created)' })
  unchanged: boolean;
}

export class PhraseBankQueryDto {
  @ApiPropertyOptional({
    description: 'Checksum the client already has; when it matches, the bank body is omitted',
  })
  @IsOptional()
  @IsString()
  known?: string;
}

export class PhraseBankLatestResponseDto {
  @ApiProperty() bankType: string;
  @ApiProperty() version: number;
  @ApiProperty() checksum: string;
  @ApiProperty() publishedAt: Date;
  @ApiProperty({ description: 'true when `known` matched the latest checksum; `bank` is then omitted' })
  unchanged: boolean;
  @ApiPropertyOptional({ type: 'object', additionalProperties: true })
  bank?: Record<string, unknown>;
}
