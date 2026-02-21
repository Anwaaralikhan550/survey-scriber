import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SyncOperationType, SyncEntityType } from './sync-push.dto';

export class SyncOperationResultDto {
  @ApiProperty({
    description: 'Client operation ID',
    example: 'op-123e4567-e89b-12d3-a456-426614174000',
  })
  operationId: string;

  @ApiProperty({
    description: 'Whether operation succeeded',
    example: true,
  })
  success: boolean;

  @ApiPropertyOptional({
    description: 'Error message if operation failed',
    example: 'Entity not found',
  })
  error?: string;

  @ApiPropertyOptional({
    description: 'Server-side entity ID (may differ from client for new entities)',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  entityId?: string;

  @ApiPropertyOptional({
    description: 'Whether this operation was a duplicate (idempotent replay)',
    example: false,
  })
  duplicate?: boolean;
}

export class SyncPushResponseDto {
  @ApiProperty({
    description: 'Overall success status',
    example: true,
  })
  success: boolean;

  @ApiProperty({
    description: 'Idempotency key echoed back',
    example: 'batch-123e4567-e89b-12d3-a456-426614174000',
  })
  idempotencyKey: string;

  @ApiProperty({
    description: 'Results for each operation',
    type: [SyncOperationResultDto],
  })
  results: SyncOperationResultDto[];

  @ApiProperty({
    description: 'Server timestamp when sync was processed',
    example: '2024-01-15T10:30:00.000Z',
  })
  serverTimestamp: Date;

  @ApiPropertyOptional({
    description: 'Whether entire batch was replayed (duplicate idempotency key)',
    example: false,
  })
  batchDuplicate?: boolean;
}

export class SyncEntityDto {
  @ApiProperty({
    enum: SyncEntityType,
    description: 'Type of entity',
    example: SyncEntityType.SURVEY,
  })
  entityType: SyncEntityType;

  @ApiProperty({
    description: 'Entity UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  entityId: string;

  @ApiProperty({
    enum: SyncOperationType,
    description: 'Type of change',
    example: SyncOperationType.UPDATE,
  })
  changeType: SyncOperationType;

  @ApiProperty({
    description: 'Entity data (null for DELETE)',
  })
  data: Record<string, unknown> | null;

  @ApiProperty({
    description: 'When entity was last updated on server',
    example: '2024-01-15T10:30:00.000Z',
  })
  updatedAt: Date;
}

export class SyncPullResponseDto {
  @ApiProperty({
    description: 'Array of changed entities',
    type: [SyncEntityDto],
  })
  changes: SyncEntityDto[];

  @ApiProperty({
    description: 'Server timestamp for this response (use as since for next pull)',
    example: '2024-01-15T10:30:00.000Z',
  })
  serverTimestamp: Date;

  @ApiProperty({
    description: 'Whether there are more changes to fetch',
    example: false,
  })
  hasMore: boolean;

  @ApiProperty({
    description: 'Total count of changes matching query',
    example: 15,
  })
  totalCount: number;
}
