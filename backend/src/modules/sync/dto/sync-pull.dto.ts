import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsISO8601, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class SyncPullDto {
  @ApiPropertyOptional({
    description: 'ISO 8601 timestamp to fetch changes since (exclusive)',
    example: '2024-01-15T10:30:00.000Z',
  })
  @IsISO8601()
  @IsOptional()
  since?: string;

  @ApiPropertyOptional({
    description: 'Maximum number of entities to return',
    example: 100,
    default: 100,
    minimum: 1,
    maximum: 500,
  })
  @IsInt()
  @Min(1)
  @Max(500)
  @Type(() => Number)
  @IsOptional()
  limit?: number;
}
