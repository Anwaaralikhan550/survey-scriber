import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { APP_GUARD } from '@nestjs/core';
import { validate } from './config/env.validation';
import { PrismaModule } from './modules/prisma/prisma.module';
import { HealthModule } from './modules/health/health.module';
import { AuthModule } from './modules/auth/auth.module';
import { SurveysModule } from './modules/surveys/surveys.module';
import { SectionsModule } from './modules/sections/sections.module';
import { AnswersModule } from './modules/answers/answers.module';
import { MediaModule } from './modules/media/media.module';
import { SyncModule } from './modules/sync/sync.module';
import { ConfigManagementModule } from './modules/config/config.module';
import { SchedulingModule } from './modules/scheduling/scheduling.module';
import { ClientPortalModule } from './modules/client-portal/client-portal.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { InvoicesModule } from './modules/invoices/invoices.module';
import { BookingRequestsModule } from './modules/booking-requests/booking-requests.module';
import { BookingChangeRequestsModule } from './modules/booking-change-requests/booking-change-requests.module';
import { AuditModule } from './modules/audit/audit.module';
import { WebhooksModule } from './modules/webhooks/webhooks.module';
import { ExportsModule } from './modules/exports/exports.module';
import { MetricsModule } from './modules/metrics/metrics.module';
import { AiModule } from './modules/ai/ai.module';

@Module({
  imports: [
    // Configuration with validation
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
      validate,
      cache: true,
    }),

    // Event emitter for loose coupling between modules
    EventEmitterModule.forRoot(),

    // Scheduled tasks (cron jobs)
    ScheduleModule.forRoot(),

    /**
     * Rate Limiting Configuration
     *
     * Global rate limiting using sliding window counters.
     * Applied to ALL endpoints by default via APP_GUARD.
     *
     * Design Decisions:
     * - Auth endpoints have additional throttling via @Throttle() decorators
     * - Some endpoints use @SkipThrottle() for internal/health checks
     * - Read-only endpoints (GET) use these global limits
     * - Write endpoints may have stricter per-endpoint limits
     *
     * The global limits are intentionally permissive to not impact
     * normal mobile app usage while still preventing abuse.
     * Sensitive endpoints (login, password reset) have stricter limits.
     */
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000, // 1 second
        limit: 3, // 3 requests per second
      },
      {
        name: 'medium',
        ttl: 10000, // 10 seconds
        limit: 20, // 20 requests per 10 seconds
      },
      {
        name: 'long',
        ttl: 60000, // 1 minute
        limit: 100, // 100 requests per minute
      },
    ]),

    // Database
    PrismaModule,

    // Feature modules
    HealthModule,
    AuthModule,
    SurveysModule,
    SectionsModule,
    AnswersModule,
    MediaModule,
    SyncModule,
    ConfigManagementModule,
    SchedulingModule,
    ClientPortalModule,
    NotificationsModule,
    InvoicesModule,
    BookingRequestsModule,
    BookingChangeRequestsModule,
    AuditModule,
    WebhooksModule,
    ExportsModule,
    MetricsModule,
    AiModule,
  ],
  providers: [
    // Global throttler guard
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
