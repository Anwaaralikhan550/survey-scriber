import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as client from 'prom-client';

/**
 * MetricsService - Prometheus metrics collection for production observability
 *
 * Exposes standard SRE metrics:
 * - Request rate (http_requests_total)
 * - Request duration (http_request_duration_seconds)
 * - Error rate (http_errors_total)
 * - Active connections (http_active_requests)
 * - Business metrics (surveys_created_total, etc.)
 *
 * Usage:
 * - GET /metrics - Prometheus scrape endpoint
 * - Integrate with Prometheus/Grafana stack
 * - Alert on error rates, latency percentiles
 */
@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry: client.Registry;
  private readonly defaultLabels: Record<string, string>;

  // HTTP metrics
  readonly httpRequestsTotal: client.Counter<string>;
  readonly httpRequestDuration: client.Histogram<string>;
  readonly httpErrorsTotal: client.Counter<string>;
  readonly httpActiveRequests: client.Gauge<string>;

  // Business metrics
  readonly surveysCreatedTotal: client.Counter<string>;
  readonly surveysCompletedTotal: client.Counter<string>;
  readonly bookingsCreatedTotal: client.Counter<string>;
  readonly webhooksDeliveredTotal: client.Counter<string>;
  readonly webhooksFailedTotal: client.Counter<string>;

  // Database metrics
  readonly dbQueryDuration: client.Histogram<string>;
  readonly dbConnectionsActive: client.Gauge<string>;

  // AI metrics
  readonly aiRequestsTotal: client.Counter<string>;
  readonly aiRequestDuration: client.Histogram<string>;
  readonly aiFailuresTotal: client.Counter<string>;

  // Auth metrics
  readonly authLoginAttempts: client.Counter<string>;
  readonly authLoginFailures: client.Counter<string>;
  readonly authTokenRefreshes: client.Counter<string>;

  constructor(private readonly configService: ConfigService) {
    this.registry = new client.Registry();

    // Default labels applied to all metrics
    this.defaultLabels = {
      app: this.configService.get('APP_NAME', 'surveyscriber-api'),
      env: this.configService.get('NODE_ENV', 'development'),
    };
    this.registry.setDefaultLabels(this.defaultLabels);

    // ==================================================
    // HTTP Metrics (RED method: Rate, Errors, Duration)
    // ==================================================

    this.httpRequestsTotal = new client.Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'path', 'status_code'],
      registers: [this.registry],
    });

    this.httpRequestDuration = new client.Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration in seconds',
      labelNames: ['method', 'path', 'status_code'],
      buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry],
    });

    this.httpErrorsTotal = new client.Counter({
      name: 'http_errors_total',
      help: 'Total number of HTTP errors (4xx and 5xx)',
      labelNames: ['method', 'path', 'status_code', 'error_type'],
      registers: [this.registry],
    });

    this.httpActiveRequests = new client.Gauge({
      name: 'http_active_requests',
      help: 'Number of active HTTP requests',
      labelNames: ['method'],
      registers: [this.registry],
    });

    // ==================================================
    // Business Metrics
    // ==================================================

    this.surveysCreatedTotal = new client.Counter({
      name: 'surveys_created_total',
      help: 'Total number of surveys created',
      labelNames: ['type', 'user_role'],
      registers: [this.registry],
    });

    this.surveysCompletedTotal = new client.Counter({
      name: 'surveys_completed_total',
      help: 'Total number of surveys completed',
      labelNames: ['type'],
      registers: [this.registry],
    });

    this.bookingsCreatedTotal = new client.Counter({
      name: 'bookings_created_total',
      help: 'Total number of bookings created',
      labelNames: ['source'],
      registers: [this.registry],
    });

    this.webhooksDeliveredTotal = new client.Counter({
      name: 'webhooks_delivered_total',
      help: 'Total number of webhooks successfully delivered',
      labelNames: ['event_type'],
      registers: [this.registry],
    });

    this.webhooksFailedTotal = new client.Counter({
      name: 'webhooks_failed_total',
      help: 'Total number of webhook delivery failures',
      labelNames: ['event_type', 'error_type'],
      registers: [this.registry],
    });

    // ==================================================
    // Database Metrics
    // ==================================================

    this.dbQueryDuration = new client.Histogram({
      name: 'db_query_duration_seconds',
      help: 'Database query duration in seconds',
      labelNames: ['operation', 'table'],
      buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5],
      registers: [this.registry],
    });

    this.dbConnectionsActive = new client.Gauge({
      name: 'db_connections_active',
      help: 'Number of active database connections',
      registers: [this.registry],
    });

    // ==================================================
    // AI Metrics (Gemini integration observability)
    // ==================================================

    this.aiRequestsTotal = new client.Counter({
      name: 'ai_requests_total',
      help: 'Total number of AI requests',
      labelNames: ['operation', 'model', 'status'],
      registers: [this.registry],
    });

    this.aiRequestDuration = new client.Histogram({
      name: 'ai_request_duration_ms',
      help: 'AI request duration in milliseconds',
      labelNames: ['operation', 'model'],
      buckets: [50, 100, 250, 500, 1000, 2500, 5000, 10000, 30000],
      registers: [this.registry],
    });

    this.aiFailuresTotal = new client.Counter({
      name: 'ai_failures_total',
      help: 'Total number of AI request failures by error type',
      labelNames: ['operation', 'model', 'error_type'],
      registers: [this.registry],
    });

    // ==================================================
    // Authentication Metrics
    // ==================================================

    this.authLoginAttempts = new client.Counter({
      name: 'auth_login_attempts_total',
      help: 'Total number of login attempts',
      labelNames: ['result'],
      registers: [this.registry],
    });

    this.authLoginFailures = new client.Counter({
      name: 'auth_login_failures_total',
      help: 'Total number of failed login attempts',
      labelNames: ['reason'],
      registers: [this.registry],
    });

    this.authTokenRefreshes = new client.Counter({
      name: 'auth_token_refreshes_total',
      help: 'Total number of token refresh operations',
      labelNames: ['result'],
      registers: [this.registry],
    });
  }

  onModuleInit() {
    // Collect default Node.js metrics (memory, CPU, event loop lag, etc.)
    client.collectDefaultMetrics({
      register: this.registry,
      prefix: 'nodejs_',
    });
  }

  /**
   * Get all metrics in Prometheus format
   */
  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  /**
   * Get content type for Prometheus response
   */
  getContentType(): string {
    return this.registry.contentType;
  }

  // ==================================================
  // Helper Methods for Recording Metrics
  // ==================================================

  /**
   * Record an HTTP request
   */
  recordHttpRequest(
    method: string,
    path: string,
    statusCode: number,
    durationSeconds: number,
  ): void {
    const normalizedPath = this.normalizePath(path);
    const labels = { method, path: normalizedPath, status_code: String(statusCode) };

    this.httpRequestsTotal.inc(labels);
    this.httpRequestDuration.observe(labels, durationSeconds);

    if (statusCode >= 400) {
      const errorType = statusCode >= 500 ? 'server_error' : 'client_error';
      this.httpErrorsTotal.inc({ ...labels, error_type: errorType });
    }
  }

  /**
   * Increment active requests gauge
   */
  incActiveRequests(method: string): void {
    this.httpActiveRequests.inc({ method });
  }

  /**
   * Decrement active requests gauge
   */
  decActiveRequests(method: string): void {
    this.httpActiveRequests.dec({ method });
  }

  /**
   * Record a database query
   */
  recordDbQuery(operation: string, table: string, durationSeconds: number): void {
    this.dbQueryDuration.observe({ operation, table }, durationSeconds);
  }

  /**
   * Record a login attempt
   */
  recordLoginAttempt(success: boolean, failureReason?: string): void {
    this.authLoginAttempts.inc({ result: success ? 'success' : 'failure' });
    if (!success && failureReason) {
      this.authLoginFailures.inc({ reason: failureReason });
    }
  }

  /**
   * Record a survey creation
   */
  recordSurveyCreated(type: string, userRole: string): void {
    this.surveysCreatedTotal.inc({ type, user_role: userRole });
  }

  /**
   * Record a webhook delivery
   */
  recordWebhookDelivery(eventType: string, success: boolean, errorType?: string): void {
    if (success) {
      this.webhooksDeliveredTotal.inc({ event_type: eventType });
    } else {
      this.webhooksFailedTotal.inc({
        event_type: eventType,
        error_type: errorType || 'unknown',
      });
    }
  }

  /**
   * Record an AI request (called by AiGeminiService)
   */
  recordAiRequest(operation: string, model: string, status: string): void {
    this.aiRequestsTotal.inc({ operation, model, status });
  }

  /**
   * Record AI request latency in milliseconds (called by AiGeminiService)
   */
  recordAiLatency(operation: string, model: string, latencyMs: number): void {
    this.aiRequestDuration.observe({ operation, model }, latencyMs);
  }

  /**
   * Record an AI request failure by error type (called by AiGeminiService)
   */
  recordAiFailure(operation: string, model: string, errorType: string): void {
    this.aiFailuresTotal.inc({ operation, model, error_type: errorType });
  }

  /**
   * Normalize path to reduce cardinality
   * Replaces IDs with placeholders
   */
  private normalizePath(path: string): string {
    return path
      // Remove query string
      .split('?')[0]
      // Replace UUIDs with :id
      .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, ':id')
      // Replace numeric IDs with :id
      .replace(/\/\d+(?=\/|$)/g, '/:id')
      // Normalize trailing slash
      .replace(/\/$/, '');
  }
}
