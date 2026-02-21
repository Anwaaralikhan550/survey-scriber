import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsObject, IsNotEmpty } from 'class-validator';

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
