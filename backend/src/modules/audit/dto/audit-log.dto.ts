import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsUUID,
  IsString,
  IsDateString,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ActorType, AuditEntityType } from '@prisma/client';

export class AuditLogQueryDto {
  @ApiPropertyOptional({
    description: 'Page number (1-indexed)',
    minimum: 1,
    default: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({
    description: 'Number of items per page',
    minimum: 1,
    maximum: 100,
    default: 50,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @ApiPropertyOptional({
    enum: ActorType,
    description: 'Filter by actor type',
  })
  @IsOptional()
  @IsEnum(ActorType)
  actorType?: ActorType;

  @ApiPropertyOptional({
    description: 'Filter by actor ID (user or client UUID)',
  })
  @IsOptional()
  @IsUUID()
  actorId?: string;

  @ApiPropertyOptional({
    enum: AuditEntityType,
    description: 'Filter by entity type',
  })
  @IsOptional()
  @IsEnum(AuditEntityType)
  entityType?: AuditEntityType;

  @ApiPropertyOptional({
    description: 'Filter by entity ID',
  })
  @IsOptional()
  @IsUUID()
  entityId?: string;

  @ApiPropertyOptional({
    description: 'Filter by action (partial match)',
  })
  @IsOptional()
  @IsString()
  action?: string;

  @ApiPropertyOptional({
    description: 'Filter logs from this date (ISO 8601)',
    example: '2024-01-01T00:00:00.000Z',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'Filter logs until this date (ISO 8601)',
    example: '2024-12-31T23:59:59.999Z',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class AuditLogDto {
  @ApiProperty({ description: 'Audit log ID' })
  id: string;

  @ApiProperty({ enum: ActorType, description: 'Type of actor' })
  actorType: ActorType;

  @ApiPropertyOptional({ description: 'Actor ID (user or client UUID)' })
  actorId?: string;

  @ApiProperty({ description: 'Action performed' })
  action: string;

  @ApiProperty({ enum: AuditEntityType, description: 'Type of entity affected' })
  entityType: AuditEntityType;

  @ApiPropertyOptional({ description: 'Entity ID' })
  entityId?: string;

  @ApiPropertyOptional({ description: 'Additional metadata' })
  metadata?: Record<string, any>;

  @ApiPropertyOptional({ description: 'Client IP address' })
  ip?: string;

  @ApiPropertyOptional({ description: 'User agent string' })
  userAgent?: string;

  @ApiProperty({ description: 'When the action occurred' })
  createdAt: Date;
}

/**
 * Standard pagination metadata structure
 */
export class PaginationMetaDto {
  @ApiProperty({ description: 'Current page number', example: 1 })
  page: number;

  @ApiProperty({ description: 'Items per page', example: 50 })
  limit: number;

  @ApiProperty({ description: 'Total number of items', example: 100 })
  total: number;

  @ApiProperty({ description: 'Total number of pages', example: 2 })
  totalPages: number;

  @ApiProperty({ description: 'Whether there is a next page', example: true })
  hasNext: boolean;

  @ApiProperty({ description: 'Whether there is a previous page', example: false })
  hasPrev: boolean;
}

export class AuditLogListResponseDto {
  @ApiProperty({ type: [AuditLogDto], description: 'Audit log entries' })
  data: AuditLogDto[];

  @ApiProperty({ type: PaginationMetaDto, description: 'Pagination metadata' })
  meta: PaginationMetaDto;

  /**
   * @deprecated Use 'data' instead. Kept for backward compatibility.
   */
  @ApiProperty({
    type: [AuditLogDto],
    description: 'Audit log entries (deprecated, use "data" instead)',
    deprecated: true,
  })
  logs: AuditLogDto[];

  /**
   * @deprecated Use 'meta.page' instead. Kept for backward compatibility.
   */
  @ApiProperty({ description: 'Current page number (deprecated)', deprecated: true })
  page: number;

  /**
   * @deprecated Use 'meta.limit' instead. Kept for backward compatibility.
   */
  @ApiProperty({ description: 'Items per page (deprecated)', deprecated: true })
  limit: number;

  /**
   * @deprecated Use 'meta.total' instead. Kept for backward compatibility.
   */
  @ApiProperty({ description: 'Total number of items (deprecated)', deprecated: true })
  total: number;

  /**
   * @deprecated Use 'meta.totalPages' instead. Kept for backward compatibility.
   */
  @ApiProperty({ description: 'Total number of pages (deprecated)', deprecated: true })
  totalPages: number;
}
