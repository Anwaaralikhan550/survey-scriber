import { Controller, Get, HttpCode, HttpStatus, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { HealthService } from './health.service';
import { HealthResponseDto, VersionResponseDto, ReadinessResponseDto, LivenessResponseDto } from './dto/health.dto';

/**
 * HealthController - Health check endpoints for Kubernetes and load balancers
 *
 * Endpoints:
 * - GET /health     - Full health check with database status
 * - GET /ready      - Readiness probe (can accept traffic?)
 * - GET /live       - Liveness probe (is process alive?)
 * - GET /version    - Version information
 *
 * Kubernetes probe configuration:
 * ```yaml
 * livenessProbe:
 *   httpGet:
 *     path: /api/v1/live
 *     port: 3000
 *   initialDelaySeconds: 5
 *   periodSeconds: 10
 *   failureThreshold: 3
 *
 * readinessProbe:
 *   httpGet:
 *     path: /api/v1/ready
 *     port: 3000
 *   initialDelaySeconds: 5
 *   periodSeconds: 5
 *   failureThreshold: 3
 * ```
 */
@ApiTags('health')
@SkipThrottle()
@Controller()
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get('health')
  @ApiOperation({ summary: 'Full health check with dependencies' })
  @ApiResponse({
    status: 200,
    description: 'Service is healthy',
    type: HealthResponseDto,
  })
  @ApiResponse({
    status: 503,
    description: 'Service is degraded or unhealthy',
  })
  async getHealth(): Promise<HealthResponseDto> {
    const health = await this.healthService.getHealth();
    if (health.status !== 'ok') {
      throw new ServiceUnavailableException(health);
    }
    return health;
  }

  @Get('ready')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Readiness probe - can this instance accept traffic?',
    description: 'Returns 200 if the service is ready to accept requests (database connected). Returns 503 if not ready.',
  })
  @ApiResponse({
    status: 200,
    description: 'Service is ready to accept traffic',
    type: ReadinessResponseDto,
  })
  @ApiResponse({
    status: 503,
    description: 'Service is not ready (e.g., database unavailable)',
  })
  async getReadiness(): Promise<ReadinessResponseDto> {
    const readiness = await this.healthService.checkReadiness();
    if (!readiness.ready) {
      throw new ServiceUnavailableException(readiness);
    }
    return readiness;
  }

  @Get('live')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Liveness probe - is this process alive?',
    description: 'Returns 200 if the process is alive. Used by Kubernetes to detect deadlocks.',
  })
  @ApiResponse({
    status: 200,
    description: 'Service is alive',
    type: LivenessResponseDto,
  })
  getLiveness(): LivenessResponseDto {
    return this.healthService.checkLiveness();
  }

  @Get('version')
  @ApiOperation({ summary: 'Get API version information' })
  @ApiResponse({
    status: 200,
    description: 'Version information',
    type: VersionResponseDto,
  })
  getVersion(): VersionResponseDto {
    return this.healthService.getVersion();
  }
}
