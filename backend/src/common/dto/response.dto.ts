import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * API Response Shape Conventions
 *
 * This API uses two response patterns based on endpoint type:
 *
 * 1. PAGINATED RESPONSES - Wrapped in { data, meta }
 *    Used by: GET endpoints that return lists (surveys, users, etc.)
 *    Example: GET /surveys returns { data: Survey[], meta: { total, page, limit, totalPages } }
 *
 * 2. SINGLE ENTITY RESPONSES - Direct object return
 *    Used by: GET/:id, POST, PATCH, DELETE endpoints
 *    Example: GET /surveys/:id returns Survey (not wrapped)
 *
 * This is intentional design:
 * - Paginated endpoints need metadata (pagination info)
 * - Single entity endpoints return clean, predictable objects
 * - Mobile clients benefit from simpler single-entity parsing
 *
 * For new endpoints, follow the existing pattern for that endpoint type.
 */

/**
 * Standard pagination metadata included in paginated responses.
 *
 * Pagination Defaults by Module:
 * - Most modules: limit=20 (general CRUD operations)
 * - Sync module: limit=100 (bulk data synchronization)
 * - Audit module: limit=50 (log review workflows)
 *
 * Design Decision: Module-specific defaults are intentional.
 * Each module optimizes for its primary use case:
 * - User-facing lists: Smaller pages for faster initial load
 * - Sync operations: Larger batches for efficiency
 * - Audit logs: Medium size for review workflows
 *
 * Clients can override defaults via `limit` query parameter.
 * Maximum limit is typically capped at 100 to prevent abuse.
 */
export class PaginationMeta {
  @ApiProperty({ description: 'Total number of items across all pages' })
  total: number;

  @ApiProperty({ description: 'Current page number (1-indexed)' })
  page: number;

  @ApiProperty({ description: 'Number of items per page' })
  limit: number;

  @ApiProperty({ description: 'Total number of pages' })
  totalPages: number;
}

/**
 * Generic paginated response wrapper.
 * Use this for list endpoints that return multiple items.
 *
 * @example
 * // In your controller:
 * @ApiResponse({ type: PaginatedResponse })
 * async findAll(): Promise<PaginatedResponse<SurveyDto>> {
 *   return { data: surveys, meta: { total, page, limit, totalPages } };
 * }
 */
export class PaginatedResponse<T> {
  @ApiProperty({ description: 'Array of items for the current page', isArray: true })
  data: T[];

  @ApiProperty({ type: PaginationMeta, description: 'Pagination metadata' })
  meta: PaginationMeta;
}

/**
 * Standard success response for delete operations.
 */
export class DeleteSuccessResponse {
  @ApiProperty({ description: 'Whether the operation succeeded', example: true })
  success: boolean;

  @ApiProperty({ description: 'ID of the deleted entity' })
  id: string;
}

/**
 * Standard message response for operations that return a status message.
 */
export class MessageResponse {
  @ApiProperty({ description: 'Status message' })
  message: string;
}

/**
 * Helper type for creating concrete paginated response DTOs.
 * Use when you need a specific type for Swagger documentation.
 *
 * @example
 * // surveys.dto.ts
 * export class SurveysListResponse extends PaginatedResponse<SurveyDto> {
 *   @ApiProperty({ type: [SurveyDto] })
 *   declare data: SurveyDto[];
 * }
 */
export type PaginatedOf<T> = {
  data: T[];
  meta: PaginationMeta;
};

/**
 * Response shape factory for documentation purposes.
 * Describes the two standard response shapes.
 */
export const ResponseShapes = {
  /**
   * Paginated list response: { data: T[], meta: PaginationMeta }
   * Used by: GET endpoints returning collections
   */
  PAGINATED: 'paginated' as const,

  /**
   * Direct entity response: T
   * Used by: GET/:id, POST, PATCH, DELETE endpoints
   */
  DIRECT: 'direct' as const,
} as const;
