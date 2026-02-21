import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { Request, Response } from 'express';
import { MetricsService } from './metrics.service';

/**
 * MetricsInterceptor - Automatically records HTTP request metrics
 *
 * Records:
 * - Request count (by method, path, status)
 * - Request duration histogram
 * - Active request count
 * - Error count
 *
 * Apply globally in main.ts:
 * ```typescript
 * app.useGlobalInterceptors(new MetricsInterceptor(metricsService));
 * ```
 */
@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const ctx = context.switchToHttp();
    const request = ctx.getRequest<Request>();
    const response = ctx.getResponse<Response>();

    const method = request.method;
    const path = request.route?.path || request.path;
    const startTime = process.hrtime.bigint();

    // Track active requests
    this.metricsService.incActiveRequests(method);

    return next.handle().pipe(
      tap(() => {
        this.recordMetrics(method, path, response.statusCode, startTime);
      }),
      catchError((error) => {
        // Record error metrics even on exceptions
        const statusCode = error.status || error.statusCode || 500;
        this.recordMetrics(method, path, statusCode, startTime);
        throw error;
      }),
    );
  }

  private recordMetrics(
    method: string,
    path: string,
    statusCode: number,
    startTime: bigint,
  ): void {
    // Calculate duration in seconds
    const endTime = process.hrtime.bigint();
    const durationNs = Number(endTime - startTime);
    const durationSeconds = durationNs / 1e9;

    // Record metrics
    this.metricsService.recordHttpRequest(method, path, statusCode, durationSeconds);
    this.metricsService.decActiveRequests(method);
  }
}
