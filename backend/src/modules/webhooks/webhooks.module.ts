import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { WebhooksService } from './webhooks.service';
import { WebhookDispatcherService } from './webhook-dispatcher.service';
import { WebhooksController } from './webhooks.controller';

/**
 * WebhooksModule - provides webhook management and event dispatching
 *
 * Features:
 * - Register webhook endpoints (ADMIN/MANAGER only)
 * - Manage webhook subscriptions
 * - Dispatch events to registered webhooks
 * - HMAC-SHA256 payload signing
 * - Delivery logging
 * - SEC-005: HTTPS enforcement in production
 */
@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [WebhooksController],
  providers: [WebhooksService, WebhookDispatcherService],
  exports: [WebhooksService, WebhookDispatcherService],
})
export class WebhooksModule {}
