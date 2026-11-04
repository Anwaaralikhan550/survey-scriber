import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsInt, IsObject, IsNotEmpty, IsOptional, Min } from 'class-validator';

// ============================================
// Request DTOs
// ============================================

export class UploadV2TreeDto {
  @ApiProperty({
    description: 'Tree type identifier',
    example: 'inspection_v2',
    enum: ['inspection_v2', 'valuation_v2'],
  })
  @IsIn(['inspection_v2', 'valuation_v2'], {
    message: 'treeType must be "inspection_v2" or "valuation_v2"',
  })
  treeType: string;

  @ApiProperty({
    description: 'Complete V2 tree JSON with sections, nodes, and fields',
    type: 'object',
    additionalProperties: true,
  })
  @IsObject()
  @IsNotEmpty()
  tree: Record<string, unknown>;

  @ApiPropertyOptional({
    description:
      'The published version these edits started from (0 when none). The upload is refused ' +
      'if someone has published since, so nobody overwrites another person\'s work.',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  baseVersion?: number;
}

export class RollbackV2TreeDto {
  @ApiProperty({ description: 'The version to bring back' })
  @IsInt()
  @Min(1)
  version: number;

  @ApiPropertyOptional({ description: 'The version on screen when the admin chose this' })
  @IsOptional()
  @IsInt()
  @Min(0)
  baseVersion?: number;
}

// ============================================
// Response DTOs
// ============================================

export class V2TreeUploadResponseDto {
  @ApiProperty({ description: 'Record ID' })
  id: string;

  @ApiProperty({ description: 'Tree type', example: 'inspection_v2' })
  treeType: string;

  @ApiProperty({ description: 'Version number' })
  version: number;

  @ApiProperty({ description: 'Tree data size in bytes' })
  sizeBytes: number;

  @ApiProperty({ description: 'SHA-256 checksum of tree JSON' })
  checksum: string;

  @ApiProperty({ description: 'Publish timestamp' })
  publishedAt: Date;

  @ApiPropertyOptional({ description: 'true when the server already had identical content' })
  unchanged?: boolean;
}

export class V2TreePublishedResponseDto {
  @ApiProperty() treeType: string;
  @ApiProperty() version: number;
  @ApiProperty() checksum: string;
  @ApiProperty() publishedAt: Date;
  @ApiProperty({ description: 'true when the client already has this tree; the tree is then left out' })
  unchanged: boolean;
  @ApiPropertyOptional() tree?: Record<string, unknown>;
}

export class V2TreeVersionDto {
  @ApiProperty() version: number;
  @ApiProperty() checksum: string;
  @ApiProperty() sizeBytes: number;
  @ApiProperty() publishedAt: Date;
  @ApiPropertyOptional() publishedBy?: string;
}

export class V2TreeLatestResponseDto {
  @ApiProperty({ description: 'Tree type', example: 'inspection_v2' })
  treeType: string;

  @ApiProperty({ description: 'Version number' })
  version: number;

  @ApiProperty({ description: 'Full tree data' })
  tree: Record<string, unknown>;

  @ApiProperty({ description: 'Publish timestamp' })
  publishedAt: Date;

  @ApiProperty({ description: 'SHA-256 checksum' })
  checksum: string;
}
