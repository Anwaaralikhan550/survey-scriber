import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MetricsService } from './metrics.service';
import { MetricsController } from './metrics.controller';

/**
 * MetricsModule - Global module for Prometheus metrics
 *
 * Provides MetricsService globally so all modules can record metrics
 * without explicit imports.
 *
 * Usage in other services:
 * ```typescript
 * constructor(private readonly metricsService: MetricsService) {}
 *
 * async someMethod() {
 *   this.metricsService.recordSurveyCreated('standard', 'admin');
 * }
 * ```
 */
@Global()
@Module({
  imports: [ConfigModule],
  controllers: [MetricsController],
  providers: [MetricsService],
  exports: [MetricsService],
})
export class MetricsModule {}
