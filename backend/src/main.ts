import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger, VersioningType } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { ConfigService } from '@nestjs/config';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import * as fs from 'fs';
import * as path from 'path';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { MetricsInterceptor } from './modules/metrics/metrics.interceptor';
import { MetricsService } from './modules/metrics/metrics.service';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    bodyParser: false, // Disable default Express parser (100KB limit) — custom limits below
  });

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);
  const apiPrefix = configService.get<string>('API_PREFIX', 'api');
  const nodeEnv = configService.get<string>('NODE_ENV', 'development');
  const appName = configService.get<string>('APP_NAME', 'SurveyScriber API');
  const appVersion = configService.get<string>('APP_VERSION', '1.0.0');
  const isProduction = nodeEnv === 'production';

  // Increase JSON body size limit for large V2 tree uploads (~2MB+)
  // Default Express limit is 100kb which rejects inspection_v2_tree.json
  // Capped at 10MB (5x headroom) to mitigate OOM/DoS from oversized payloads
  app.useBodyParser('json', { limit: '10mb' });
  app.useBodyParser('urlencoded', { limit: '10mb', extended: true });

  // Security middleware
  app.use(helmet());

  // Trust proxy configuration for AWS ALB/ELB/CloudFront
  // Required for correct client IP extraction from X-Forwarded-For header
  // 'true' = trust first proxy (suitable for single load balancer)
  // For production, consider setting to number of trusted proxies or 'loopback'
  const expressApp = app.getHttpAdapter().getInstance();
  if (isProduction || configService.get<boolean>('TRUST_PROXY', false)) {
    expressApp.set('trust proxy', true);
  }

  // CORS configuration - locked down for production safety
  const corsOrigins = configService.get<string>('CORS_ORIGINS', '');

  // In production, CORS_ORIGINS must be explicitly set
  // In development, allow all origins for easier testing
  let corsOriginConfig: string | string[] | boolean;
  if (corsOrigins) {
    corsOriginConfig = corsOrigins.split(',').map((o) => o.trim());
  } else if (isProduction) {
    // Fail-safe: no CORS origins in production = deny all cross-origin requests
    corsOriginConfig = false;
    logger.warn('CORS_ORIGINS not set in production - cross-origin requests will be blocked');
  } else {
    // Development only: allow all origins
    corsOriginConfig = true;
  }

  app.enableCors({
    origin: corsOriginConfig,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  });

  // API versioning
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Global prefix
  app.setGlobalPrefix(apiPrefix);

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global exception filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Global interceptors
  const metricsService = app.get(MetricsService);
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new MetricsInterceptor(metricsService),
  );

  // OpenAPI/Swagger documentation - SINGLE SOURCE OF TRUTH
  // Generated from NestJS decorators: @ApiTags, @ApiOperation, @ApiResponse, etc.
  const swaggerConfig = new DocumentBuilder()
    .setTitle(appName)
    .setDescription(
      'SurveyScriber Backend API - Professional Field Survey & Inspection Platform\n\n' +
      '## Authentication\n' +
      'This API uses JWT Bearer tokens. Obtain tokens via `/auth/login` and include in the Authorization header.\n\n' +
      '## Offline-First Architecture\n' +
      'The API supports granular CRUD operations for surveys, sections, and answers to enable ' +
      'offline-first Flutter clients to sync individual changes without full survey uploads.',
    )
    .setVersion(appVersion)
    .setContact('SurveyScriber Team', 'https://surveyscriber.com', 'support@surveyscriber.com')
    .setLicense('MIT', 'https://opensource.org/licenses/MIT')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token from /auth/login response',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('Health', 'Health check endpoints for monitoring')
    .addTag('Authentication', 'User authentication: login, register, refresh tokens')
    .addTag('Surveys', 'Survey CRUD - main survey operations')
    .addTag('Sections', 'Section CRUD - granular section management for sync')
    .addTag('Answers', 'Answer CRUD - granular answer management for sync')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);

  // Write OpenAPI spec to file (single source of truth for API documentation)
  if (nodeEnv !== 'production') {
    const openApiPath = path.join(__dirname, '..', 'openapi.json');
    fs.writeFileSync(openApiPath, JSON.stringify(document, null, 2));
    logger.log(`OpenAPI spec written to: ${openApiPath}`);
  }

  // Setup Swagger UI (only in non-production)
  if (nodeEnv !== 'production') {
    SwaggerModule.setup('docs', app, document, {
      swaggerOptions: {
        persistAuthorization: true,
        docExpansion: 'none',
        filter: true,
        showRequestDuration: true,
        tagsSorter: 'alpha',
        operationsSorter: 'alpha',
      },
      customSiteTitle: 'SurveyScriber API Docs',
    });

    logger.log(`Swagger documentation available at http://localhost:${port}/docs`);
  }

  // Graceful shutdown
  app.enableShutdownHooks();

  // Bind to HOST (default: 0.0.0.0 for LAN access, 'localhost' for local-only)
  const host = configService.get<string>('HOST', '0.0.0.0');

  try {
    await app.listen(port, host);
  } catch (err: any) {
    if (err?.code === 'EADDRINUSE') {
      logger.error(
        `╔══════════════════════════════════════════════════════════════╗\n` +
        `║  FATAL: Port ${port} is already in use.                       ║\n` +
        `║                                                              ║\n` +
        `║  Another instance of the server may be running.              ║\n` +
        `║  Fix options:                                                ║\n` +
        `║    1. Kill the existing process using port ${port}              ║\n` +
        `║    2. Set a different port: PORT=${port + 1} npm run start      ║\n` +
        `║    3. On Linux/Mac: lsof -i :${port} | grep LISTEN             ║\n` +
        `║    4. On Windows: netstat -ano | findstr :${port}               ║\n` +
        `╚══════════════════════════════════════════════════════════════╝`,
      );
      process.exit(1);
    }
    throw err;
  }

  logger.log(`${appName} v${appVersion} is running on: http://${host}:${port}/${apiPrefix}`);
  logger.log(`Environment: ${nodeEnv}`);
  logger.log(`Database: ${configService.get<string>('DATABASE_URL', '').replace(/\/\/.*@/, '//<credentials>@')}`);
  logger.log(`CORS: ${corsOrigins || (isProduction ? 'BLOCKED (not configured)' : 'all origins (dev)')}`);
}

bootstrap().catch((err) => {
  console.error('Failed to start application:', err);
  process.exit(1);
});
