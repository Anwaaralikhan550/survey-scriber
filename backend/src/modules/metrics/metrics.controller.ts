import { Controller, Get, UseGuards, Res } from '@nestjs/common';
import { ApiTags, ApiExcludeEndpoint, ApiBearerAuth } from '@nestjs/swagger';
import { Response } from 'express';
import { UserRole } from '@prisma/client';
import { MetricsService } from './metrics.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

/**
 * MetricsController - Prometheus scrape endpoint
 *
 * Exposes /metrics endpoint for Prometheus to scrape.
 * Protected with ADMIN-only access; Prometheus authenticates via
 * a service account JWT or use a network-level allow-list.
 *
 * Prometheus scrape config example:
 * ```yaml
 * scrape_configs:
 *   - job_name: 'surveyscriber-api'
 *     static_configs:
 *       - targets: ['api.surveyscriber.com:3000']
 *     metrics_path: '/api/v1/metrics'
 *     scheme: https
 *     bearer_token_file: /etc/prometheus/jwt_token
 * ```
 */
@ApiTags('metrics')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class MetricsController {
  constructor(private readonly metricsService: MetricsService) {}

  @Get('metrics')
  @Roles(UserRole.ADMIN)
  @ApiExcludeEndpoint() // Hide from Swagger - internal endpoint
  async getMetrics(@Res() res: Response): Promise<void> {
    const metrics = await this.metricsService.getMetrics();
    res.set('Content-Type', this.metricsService.getContentType());
    res.send(metrics);
  }
}
