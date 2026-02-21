import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const ctx = context.switchToHttp();
    const request = ctx.getRequest<Request>();
    const response = ctx.getResponse<Response>();

    // Generate or use existing request ID
    const requestId = (request.headers['x-request-id'] as string) || uuidv4();
    request.headers['x-request-id'] = requestId;
    response.setHeader('X-Request-ID', requestId);

    const { method, url, ip } = request;
    const userAgent = request.get('user-agent') || '';
    const startTime = Date.now();

    // Log incoming request
    const shortUserAgent = userAgent.slice(0, 50);
    this.logger.log(
      `[${requestId}] --> ${method} ${url} - ${ip} - ${shortUserAgent}`,
    );

    return next.handle().pipe(
      tap({
        next: () => {
          const { statusCode } = response;
          const latency = Date.now() - startTime;

          // Log response
          this.logger.log(
            `[${requestId}] <-- ${method} ${url} - ${statusCode} - ${latency}ms`,
          );
        },
        error: () => {
          const latency = Date.now() - startTime;

          // Error logging is handled by the exception filter
          this.logger.debug(
            `[${requestId}] <-- ${method} ${url} - ERROR - ${latency}ms`,
          );
        },
      }),
    );
  }
}
