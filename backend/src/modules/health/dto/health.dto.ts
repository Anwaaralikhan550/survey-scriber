import { ApiProperty } from '@nestjs/swagger';

export class DatabaseStatus {
  @ApiProperty({ example: 'up', enum: ['up', 'down'] })
  status: 'up' | 'down';

  @ApiProperty({ example: '5ms', required: false })
  responseTime?: string;

  @ApiProperty({ required: false })
  error?: string;
}

export class HealthResponseDto {
  @ApiProperty({ example: 'ok', enum: ['ok', 'degraded'] })
  status: 'ok' | 'degraded';

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  timestamp: string;

  @ApiProperty({ example: 12345.678, description: 'Server uptime in seconds' })
  uptime: number;

  @ApiProperty({ type: DatabaseStatus })
  database: DatabaseStatus;
}

export class VersionResponseDto {
  @ApiProperty({ example: 'SurveyScriber API' })
  name: string;

  @ApiProperty({ example: '1.0.0' })
  version: string;

  @ApiProperty({ example: 'development', enum: ['development', 'production', 'test'] })
  env: string;

  @ApiProperty({ example: 'v20.10.0' })
  nodeVersion: string;
}

/**
 * ReadinessResponseDto - Kubernetes readiness probe response
 * Indicates whether the service can accept traffic
 */
export class ReadinessResponseDto {
  @ApiProperty({ example: true, description: 'Whether the service is ready to accept traffic' })
  ready: boolean;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  timestamp: string;

  @ApiProperty({
    example: { database: true },
    description: 'Status of each dependency',
  })
  checks: {
    database: boolean;
  };

  @ApiProperty({ required: false, description: 'Reason for not being ready' })
  reason?: string;
}

/**
 * LivenessResponseDto - Kubernetes liveness probe response
 * Indicates whether the process is alive (not deadlocked)
 */
export class LivenessResponseDto {
  @ApiProperty({ example: true, description: 'Whether the service is alive' })
  alive: boolean;

  @ApiProperty({ example: '2024-01-15T10:30:00.000Z' })
  timestamp: string;

  @ApiProperty({ example: 12345.678, description: 'Process uptime in seconds' })
  uptime: number;
}
