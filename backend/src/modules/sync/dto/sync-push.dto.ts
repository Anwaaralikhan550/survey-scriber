import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsUUID,
  IsOptional,
  IsArray,
  ValidateNested,
  IsEnum,
  IsObject,
  IsNotEmpty,
  MaxLength,
  ArrayMaxSize,
  ValidatorConstraint,
  ValidatorConstraintInterface,
  Validate,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * SEC-M8: Reject sync data payloads that serialize to more than 50KB.
 * Prevents memory exhaustion from deeply nested or bloated JSON objects.
 * 50KB is generous for any single entity (survey, section, or answer).
 */
@ValidatorConstraint({ name: 'maxJsonSize', async: false })
class MaxJsonSizeConstraint implements ValidatorConstraintInterface {
  private static readonly MAX_BYTES = 50 * 1024; // 50KB

  validate(value: unknown): boolean {
    if (value === null || value === undefined) return true;
    try {
      const json = JSON.stringify(value);
      return Buffer.byteLength(json, 'utf8') <= MaxJsonSizeConstraint.MAX_BYTES;
    } catch {
      return false;
    }
  }

  defaultMessage(): string {
    return 'Data payload exceeds maximum allowed size of 50KB';
  }
}

export enum SyncOperationType {
  CREATE = 'CREATE',
  UPDATE = 'UPDATE',
  DELETE = 'DELETE',
}

export enum SyncEntityType {
  SURVEY = 'SURVEY',
  SECTION = 'SECTION',
  ANSWER = 'ANSWER',
  MEDIA = 'MEDIA',
}

export class SyncOperationDto {
  @ApiProperty({
    description: 'Client-generated unique ID for this operation (for idempotency)',
    example: 'op-123e4567-e89b-12d3-a456-426614174000',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  operationId: string;

  @ApiProperty({
    enum: SyncOperationType,
    description: 'Type of operation',
    example: SyncOperationType.CREATE,
  })
  @IsEnum(SyncOperationType)
  operationType: SyncOperationType;

  @ApiProperty({
    enum: SyncEntityType,
    description: 'Type of entity being synced',
    example: SyncEntityType.SURVEY,
  })
  @IsEnum(SyncEntityType)
  entityType: SyncEntityType;

  @ApiProperty({
    description: 'UUID of the entity',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID()
  entityId: string;

  @ApiPropertyOptional({
    description: 'Entity data payload (for CREATE/UPDATE). Max 50KB when serialized.',
    example: { title: 'New Survey', propertyAddress: '123 Main St' },
  })
  @IsObject()
  @IsOptional()
  @Validate(MaxJsonSizeConstraint)
  data?: Record<string, unknown>;

  @ApiPropertyOptional({
    description: 'ISO timestamp when operation was created on client',
    example: '2024-01-15T10:30:00.000Z',
  })
  @IsString()
  @IsOptional()
  clientTimestamp?: string;
}

export class SyncPushDto {
  @ApiProperty({
    description: 'Client-generated idempotency key for the entire batch',
    example: 'batch-123e4567-e89b-12d3-a456-426614174000',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  idempotencyKey: string;

  @ApiProperty({
    description: 'Array of sync operations to apply',
    type: [SyncOperationDto],
    maxItems: 100,
  })
  @IsArray()
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => SyncOperationDto)
  operations: SyncOperationDto[];
}
