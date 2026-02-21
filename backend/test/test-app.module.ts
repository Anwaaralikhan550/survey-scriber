/**
 * Test Application Module
 *
 * Mirrors AppModule exactly but with relaxed rate limiting
 * to prevent false 429 failures during E2E tests.
 *
 * Changes vs production AppModule:
 * - ThrottlerModule limits raised to 10000 per window
 * - No APP_GUARD for ThrottlerGuard (endpoint @Throttle decorators
 *   still need the ThrottlerModule to be imported, but the guard
 *   is not globally applied)
 */

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { validate } from '../src/config/env.validation';
import { PrismaModule } from '../src/modules/prisma/prisma.module';
import { HealthModule } from '../src/modules/health/health.module';
import { AuthModule } from '../src/modules/auth/auth.module';
import { SurveysModule } from '../src/modules/surveys/surveys.module';
import { SectionsModule } from '../src/modules/sections/sections.module';
import { AnswersModule } from '../src/modules/answers/answers.module';
import { MediaModule } from '../src/modules/media/media.module';
import { SyncModule } from '../src/modules/sync/sync.module';
import { ConfigManagementModule } from '../src/modules/config/config.module';
import { SchedulingModule } from '../src/modules/scheduling/scheduling.module';
import { ClientPortalModule } from '../src/modules/client-portal/client-portal.module';
import { NotificationsModule } from '../src/modules/notifications/notifications.module';
import { InvoicesModule } from '../src/modules/invoices/invoices.module';
import { BookingRequestsModule } from '../src/modules/booking-requests/booking-requests.module';
import { BookingChangeRequestsModule } from '../src/modules/booking-change-requests/booking-change-requests.module';
import { AuditModule } from '../src/modules/audit/audit.module';
import { WebhooksModule } from '../src/modules/webhooks/webhooks.module';
import { ExportsModule } from '../src/modules/exports/exports.module';
import { MetricsModule } from '../src/modules/metrics/metrics.module';
import { AiModule } from '../src/modules/ai/ai.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
      validate,
      cache: true,
    }),
    EventEmitterModule.forRoot(),
    ScheduleModule.forRoot(),

    // Relaxed rate limiting for E2E tests
    ThrottlerModule.forRoot([
      { name: 'short', ttl: 1000, limit: 10000 },
      { name: 'medium', ttl: 10000, limit: 10000 },
      { name: 'long', ttl: 60000, limit: 100000 },
    ]),

    PrismaModule,
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
  // NOTE: No APP_GUARD ThrottlerGuard - this is intentionally omitted
  // to prevent rate limiting from interfering with E2E tests.
  providers: [],
})
export class TestAppModule {}
