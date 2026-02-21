import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import {
  WebhookEventType,
  WebhookDeliveryStatus,
  BookingStatus,
} from '@prisma/client';
import * as crypto from 'crypto';
import { WebhooksService } from './webhooks.service';
import { PrismaService } from '../prisma/prisma.service';

// Import existing event types
import {
  BookingCreatedEvent,
  BookingStatusChangedEvent,
} from '../notifications/events/booking.events';
import {
  InvoiceIssuedEvent,
  InvoicePaidEvent,
} from '../invoices/events/invoice.events';

/**
 * Webhook payload version - use date-based versioning for Zapier/Make compatibility
 */
const WEBHOOK_PAYLOAD_VERSION = '2024-01-15';

/**
 * Standard webhook envelope structure (Zapier/Make compatible)
 */
interface WebhookEnvelope {
  id: string;           // Unique event ID (evt_<uuid>)
  type: string;         // Event type (e.g., BOOKING_CREATED)
  createdAt: string;    // ISO timestamp
  version: string;      // Payload version for schema evolution
  data: Record<string, any>; // Event-specific data (backward compatible)
}

/**
 * Retry configuration for webhook deliveries
 */
interface RetryConfig {
  maxAttempts: number;
  delays: number[]; // Delays in milliseconds between attempts
}

/**
 * Default retry configuration: 3 attempts with exponential backoff
 * - Attempt 1: Immediate
 * - Attempt 2: After 30 seconds
 * - Attempt 3: After 2 minutes
 */
const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  delays: [0, 30000, 120000], // 0s, 30s, 2min
};

/**
 * WebhookDispatcherService
 *
 * Listens to internal events and dispatches webhooks to registered endpoints.
 * Designed for Zapier/Make integration with standardized payloads.
 *
 * SECURITY: Payloads are signed using HMAC-SHA256.
 *
 * Example verification (Node.js):
 * ```javascript
 * const crypto = require('crypto');
 *
 * function verifyWebhookSignature(payload, signature, secret) {
 *   const expectedSignature = 'sha256=' + crypto
 *     .createHmac('sha256', secret)
 *     .update(payload, 'utf8')
 *     .digest('hex');
 *
 *   return crypto.timingSafeEqual(
 *     Buffer.from(signature),
 *     Buffer.from(expectedSignature)
 *   );
 * }
 *
 * // In your webhook handler:
 * const rawBody = req.rawBody; // Raw request body as string
 * const signature = req.headers['x-signature'];
 * const secret = 'whsec_your_secret_here';
 *
 * if (!verifyWebhookSignature(rawBody, signature, secret)) {
 *   return res.status(401).send('Invalid signature');
 * }
 * ```
 */
@Injectable()
export class WebhookDispatcherService {
  private readonly logger = new Logger(WebhookDispatcherService.name);
  private readonly TIMEOUT_MS = 10000; // 10 second timeout
  private readonly retryConfig: RetryConfig;

  // Track pending retries (in-memory, lost on restart - acceptable for MVP)
  private readonly pendingRetries = new Map<string, NodeJS.Timeout>();

  constructor(
    private readonly webhooksService: WebhooksService,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    // Load retry config from environment or use defaults
    this.retryConfig = {
      maxAttempts: this.configService.get('WEBHOOK_MAX_ATTEMPTS', 3),
      delays: this.parseDelays(
        this.configService.get('WEBHOOK_RETRY_DELAYS', '0,30000,120000'),
      ),
    };
  }

  private parseDelays(delayString: string): number[] {
    try {
      return delayString.split(',').map((d) => parseInt(d.trim(), 10));
    } catch {
      return DEFAULT_RETRY_CONFIG.delays;
    }
  }

  // ============================================
  // Event Listeners
  // ============================================

  @OnEvent('booking.created')
  async handleBookingCreated(event: BookingCreatedEvent) {
    await this.dispatchEvent(WebhookEventType.BOOKING_CREATED, {
      entityId: event.booking.id,
      entityType: 'booking',
      status: event.booking.status,
      date: event.booking.date,
      startTime: event.booking.startTime,
      endTime: event.booking.endTime,
      surveyorId: event.booking.surveyorId,
      clientId: event.booking.clientId,
      propertyAddress: event.booking.propertyAddress,
    });
  }

  @OnEvent('booking.status.changed')
  async handleBookingStatusChanged(event: BookingStatusChangedEvent) {
    // Dispatch BOOKING_UPDATED for general status changes
    if (event.newStatus !== BookingStatus.CANCELLED) {
      await this.dispatchEvent(WebhookEventType.BOOKING_UPDATED, {
        entityId: event.booking.id,
        entityType: 'booking',
        previousStatus: event.previousStatus,
        status: event.newStatus,
        date: event.booking.date,
        surveyorId: event.booking.surveyorId,
        clientId: event.booking.clientId,
      });
    }

    // Dispatch BOOKING_CANCELLED specifically for cancellations
    if (event.newStatus === BookingStatus.CANCELLED) {
      await this.dispatchEvent(WebhookEventType.BOOKING_CANCELLED, {
        entityId: event.booking.id,
        entityType: 'booking',
        previousStatus: event.previousStatus,
        date: event.booking.date,
        surveyorId: event.booking.surveyorId,
        clientId: event.booking.clientId,
      });
    }
  }

  @OnEvent('invoice.issued')
  async handleInvoiceIssued(event: InvoiceIssuedEvent) {
    await this.dispatchEvent(WebhookEventType.INVOICE_ISSUED, {
      entityId: event.invoice.id,
      entityType: 'invoice',
      invoiceNumber: event.invoice.invoiceNumber,
      status: event.invoice.status,
      clientId: event.invoice.clientId,
      total: event.invoice.total,
      dueDate: event.invoice.dueDate,
    });
  }

  @OnEvent('invoice.paid')
  async handleInvoicePaid(event: InvoicePaidEvent) {
    await this.dispatchEvent(WebhookEventType.INVOICE_PAID, {
      entityId: event.invoice.id,
      entityType: 'invoice',
      invoiceNumber: event.invoice.invoiceNumber,
      status: event.invoice.status,
      clientId: event.invoice.clientId,
      total: event.invoice.total,
      paidDate: event.invoice.paidDate,
    });
  }

  // ============================================
  // Custom Event Handlers (for events not yet using EventEmitter)
  // These can be called directly from other services
  // ============================================

  /**
   * Dispatch booking request created event
   */
  async dispatchBookingRequestCreated(data: {
    id: string;
    clientId: string;
    propertyAddress: string;
    preferredStartDate: Date;
    preferredEndDate: Date;
  }) {
    await this.dispatchEvent(WebhookEventType.BOOKING_REQUEST_CREATED, {
      entityId: data.id,
      entityType: 'booking_request',
      clientId: data.clientId,
      propertyAddress: data.propertyAddress,
      preferredStartDate: data.preferredStartDate,
      preferredEndDate: data.preferredEndDate,
    });
  }

  /**
   * Dispatch booking request approved event
   */
  async dispatchBookingRequestApproved(data: {
    id: string;
    clientId: string;
    reviewedById: string;
  }) {
    await this.dispatchEvent(WebhookEventType.BOOKING_REQUEST_APPROVED, {
      entityId: data.id,
      entityType: 'booking_request',
      clientId: data.clientId,
      reviewedById: data.reviewedById,
    });
  }

  /**
   * Dispatch booking change request approved event
   */
  async dispatchBookingChangeApproved(data: {
    id: string;
    bookingId: string;
    clientId: string;
    type: string;
    reviewedById: string;
  }) {
    await this.dispatchEvent(WebhookEventType.BOOKING_CHANGE_APPROVED, {
      entityId: data.id,
      entityType: 'booking_change_request',
      bookingId: data.bookingId,
      clientId: data.clientId,
      type: data.type,
      reviewedById: data.reviewedById,
    });
  }

  /**
   * Dispatch report approved event
   */
  async dispatchReportApproved(data: {
    id: string;
    title: string;
    clientId?: string;
    userId: string;
  }) {
    await this.dispatchEvent(WebhookEventType.REPORT_APPROVED, {
      entityId: data.id,
      entityType: 'survey',
      title: data.title,
      clientId: data.clientId,
      userId: data.userId,
    });
  }

  /**
   * Dispatch a test event to a specific webhook
   * Used for testing webhook configuration in Zapier/Make
   */
  async dispatchTestEvent(
    webhookId: string,
    eventType: WebhookEventType,
  ): Promise<{ success: boolean; eventId: string }> {
    const webhook = await this.prisma.webhook.findUnique({
      where: { id: webhookId },
    });

    if (!webhook) {
      throw new NotFoundException('Webhook not found');
    }

    if (!webhook.isActive) {
      throw new BadRequestException('Webhook is disabled');
    }

    // Generate test payload based on event type
    const testData = this.generateTestPayload(eventType);
    const eventId = this.generateEventId();
    const envelope = this.createEnvelope(eventId, eventType, testData);

    // Deliver to this specific webhook
    const result = await this.deliverToWebhook(
      webhook,
      eventType,
      envelope,
      eventId,
      true, // isTest = true
    );

    return { success: result, eventId };
  }

  // ============================================
  // Core Dispatch Logic
  // ============================================

  /**
   * Generate a unique event ID
   */
  private generateEventId(): string {
    return `evt_${crypto.randomUUID()}`;
  }

  /**
   * Create a standardized webhook envelope
   */
  private createEnvelope(
    eventId: string,
    eventType: WebhookEventType,
    data: Record<string, any>,
  ): WebhookEnvelope {
    return {
      id: eventId,
      type: eventType,
      createdAt: new Date().toISOString(),
      version: WEBHOOK_PAYLOAD_VERSION,
      data,
    };
  }

  /**
   * Generate test payload for a given event type
   */
  private generateTestPayload(eventType: WebhookEventType): Record<string, any> {
    const testId = `test_${crypto.randomUUID().substring(0, 8)}`;

    const basePayload: Record<WebhookEventType, Record<string, any>> = {
      [WebhookEventType.BOOKING_CREATED]: {
        entityId: testId,
        entityType: 'booking',
        status: 'PENDING',
        date: new Date().toISOString().split('T')[0],
        startTime: '09:00',
        endTime: '10:00',
        surveyorId: `surveyor_${testId}`,
        clientId: `client_${testId}`,
        propertyAddress: '123 Test Street, London, SW1A 1AA',
      },
      [WebhookEventType.BOOKING_UPDATED]: {
        entityId: testId,
        entityType: 'booking',
        previousStatus: 'PENDING',
        status: 'CONFIRMED',
        date: new Date().toISOString().split('T')[0],
        surveyorId: `surveyor_${testId}`,
        clientId: `client_${testId}`,
      },
      [WebhookEventType.BOOKING_CANCELLED]: {
        entityId: testId,
        entityType: 'booking',
        previousStatus: 'CONFIRMED',
        date: new Date().toISOString().split('T')[0],
        surveyorId: `surveyor_${testId}`,
        clientId: `client_${testId}`,
      },
      [WebhookEventType.BOOKING_REQUEST_CREATED]: {
        entityId: testId,
        entityType: 'booking_request',
        clientId: `client_${testId}`,
        propertyAddress: '123 Test Street, London, SW1A 1AA',
        preferredStartDate: new Date().toISOString(),
        preferredEndDate: new Date(Date.now() + 86400000).toISOString(),
      },
      [WebhookEventType.BOOKING_REQUEST_APPROVED]: {
        entityId: testId,
        entityType: 'booking_request',
        clientId: `client_${testId}`,
        reviewedById: `admin_${testId}`,
      },
      [WebhookEventType.BOOKING_CHANGE_APPROVED]: {
        entityId: testId,
        entityType: 'booking_change_request',
        bookingId: `booking_${testId}`,
        clientId: `client_${testId}`,
        type: 'RESCHEDULE',
        reviewedById: `admin_${testId}`,
      },
      [WebhookEventType.INVOICE_ISSUED]: {
        entityId: testId,
        entityType: 'invoice',
        invoiceNumber: `INV-TEST-${testId.toUpperCase()}`,
        status: 'ISSUED',
        clientId: `client_${testId}`,
        total: 15000, // £150.00 in pence
        dueDate: new Date(Date.now() + 30 * 86400000).toISOString(),
      },
      [WebhookEventType.INVOICE_PAID]: {
        entityId: testId,
        entityType: 'invoice',
        invoiceNumber: `INV-TEST-${testId.toUpperCase()}`,
        status: 'PAID',
        clientId: `client_${testId}`,
        total: 15000,
        paidDate: new Date().toISOString(),
      },
      [WebhookEventType.REPORT_APPROVED]: {
        entityId: testId,
        entityType: 'survey',
        title: 'Test Survey Report',
        clientId: `client_${testId}`,
        userId: `surveyor_${testId}`,
      },
    };

    return basePayload[eventType] || { entityId: testId, entityType: 'unknown' };
  }

  /**
   * Dispatch an event to all registered webhooks
   */
  private async dispatchEvent(
    eventType: WebhookEventType,
    data: Record<string, any>,
  ): Promise<void> {
    try {
      const webhooks = await this.webhooksService.getActiveWebhooksForEvent(eventType);

      if (webhooks.length === 0) {
        this.logger.debug(`No active webhooks for event: ${eventType}`);
        return;
      }

      this.logger.log(`Dispatching ${eventType} to ${webhooks.length} webhook(s)`);

      const eventId = this.generateEventId();
      const envelope = this.createEnvelope(eventId, eventType, data);

      // Dispatch to all webhooks in parallel (fire and forget for each)
      await Promise.allSettled(
        webhooks.map((webhook) =>
          this.deliverToWebhook(webhook, eventType, envelope, eventId, false),
        ),
      );
    } catch (error) {
      this.logger.error(`Failed to dispatch event ${eventType}: ${error}`);
    }
  }

  /**
   * Deliver payload to a single webhook with retry support
   */
  private async deliverToWebhook(
    webhook: { id: string; url: string; secretHash: string },
    eventType: WebhookEventType,
    envelope: WebhookEnvelope,
    eventId: string,
    isTest: boolean,
    attempt: number = 1,
    deliveryId?: string,
  ): Promise<boolean> {
    const payloadString = JSON.stringify(envelope);

    // Sign the payload using the secret hash as the key
    const signature = this.signPayload(payloadString, webhook.secretHash);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.TIMEOUT_MS);

      const response = await fetch(webhook.url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Signature': `sha256=${signature}`,
          'X-Webhook-Event': eventType,
          'X-Event-Type': eventType, // Added for Zapier/Make compatibility
          'X-Event-Id': eventId,
          'X-Webhook-Version': WEBHOOK_PAYLOAD_VERSION,
          'User-Agent': 'SurveyScriber-Webhook/1.0',
        },
        body: payloadString,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const responseBody = await response.text().catch(() => null);

      if (response.ok) {
        // Log successful delivery
        if (deliveryId) {
          // Update existing delivery record
          await this.updateDeliverySuccess(deliveryId, attempt, response.status, responseBody);
        } else {
          // Create new delivery record
          await this.webhooksService.logDeliveryWithDetails({
            webhookId: webhook.id,
            event: eventType,
            eventId,
            payload: envelope,
            status: WebhookDeliveryStatus.SUCCESS,
            responseStatusCode: response.status,
            responseBody: responseBody ?? undefined,
            attempts: attempt,
            lastAttemptAt: new Date(),
            isTest,
          });
        }

        this.logger.log(`Webhook delivered successfully: ${webhook.id} - ${eventType} (attempt ${attempt})`);
        return true;
      } else {
        // Handle failed delivery
        return await this.handleDeliveryFailure(
          webhook,
          eventType,
          envelope,
          eventId,
          isTest,
          attempt,
          deliveryId,
          response.status,
          responseBody,
          `HTTP ${response.status}`,
        );
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';

      // Handle network/timeout error
      return await this.handleDeliveryFailure(
        webhook,
        eventType,
        envelope,
        eventId,
        isTest,
        attempt,
        deliveryId,
        undefined,
        undefined,
        errorMessage,
      );
    }
  }

  /**
   * Handle delivery failure - either retry or mark as failed
   */
  private async handleDeliveryFailure(
    webhook: { id: string; url: string; secretHash: string },
    eventType: WebhookEventType,
    envelope: WebhookEnvelope,
    eventId: string,
    isTest: boolean,
    attempt: number,
    deliveryId: string | undefined,
    responseStatusCode: number | undefined,
    responseBody: string | null | undefined,
    errorMessage: string,
  ): Promise<boolean> {
    const shouldRetry = attempt < this.retryConfig.maxAttempts;
    const nextDelay = this.retryConfig.delays[attempt] || 120000;
    const nextAttemptAt = shouldRetry ? new Date(Date.now() + nextDelay) : undefined;

    // Create or update delivery record
    let currentDeliveryId = deliveryId;
    if (currentDeliveryId) {
      await this.updateDeliveryFailure(
        currentDeliveryId,
        attempt,
        responseStatusCode,
        responseBody,
        errorMessage,
        shouldRetry ? WebhookDeliveryStatus.FAILED : WebhookDeliveryStatus.FAILED,
        nextAttemptAt,
      );
    } else {
      currentDeliveryId = await this.webhooksService.logDeliveryWithDetails({
        webhookId: webhook.id,
        event: eventType,
        eventId,
        payload: envelope,
        status: WebhookDeliveryStatus.FAILED,
        responseStatusCode,
        responseBody: responseBody ?? undefined,
        attempts: attempt,
        lastAttemptAt: new Date(),
        lastError: errorMessage.substring(0, 500),
        nextAttemptAt,
        isTest,
      });
    }

    this.logger.warn(
      `Webhook delivery failed: ${webhook.id} - ${eventType} (attempt ${attempt}/${this.retryConfig.maxAttempts}) - ${errorMessage}`,
    );

    // Schedule retry if applicable
    if (shouldRetry && currentDeliveryId) {
      this.scheduleRetry(
        webhook,
        eventType,
        envelope,
        eventId,
        isTest,
        attempt + 1,
        currentDeliveryId,
        nextDelay,
      );
    }

    return false;
  }

  /**
   * Schedule a retry attempt
   */
  private scheduleRetry(
    webhook: { id: string; url: string; secretHash: string },
    eventType: WebhookEventType,
    envelope: WebhookEnvelope,
    eventId: string,
    isTest: boolean,
    nextAttempt: number,
    deliveryId: string,
    delay: number,
  ): void {
    this.logger.log(
      `Scheduling retry for ${deliveryId} in ${delay / 1000}s (attempt ${nextAttempt})`,
    );

    const timeoutId = setTimeout(async () => {
      this.pendingRetries.delete(deliveryId);

      try {
        await this.deliverToWebhook(
          webhook,
          eventType,
          envelope,
          eventId,
          isTest,
          nextAttempt,
          deliveryId,
        );
      } catch (error) {
        this.logger.error(`Retry failed for ${deliveryId}: ${error}`);
      }
    }, delay);

    this.pendingRetries.set(deliveryId, timeoutId);
  }

  /**
   * Update delivery record on success
   */
  private async updateDeliverySuccess(
    deliveryId: string,
    attempts: number,
    responseStatusCode: number,
    responseBody: string | null,
  ): Promise<void> {
    await this.prisma.webhookDelivery.update({
      where: { id: deliveryId },
      data: {
        status: WebhookDeliveryStatus.SUCCESS,
        attempts,
        lastAttemptAt: new Date(),
        nextAttemptAt: null,
        lastError: null,
        responseStatusCode,
        responseBody: responseBody?.substring(0, 2000),
      },
    });
  }

  /**
   * Update delivery record on failure
   */
  private async updateDeliveryFailure(
    deliveryId: string,
    attempts: number,
    responseStatusCode: number | undefined,
    responseBody: string | null | undefined,
    lastError: string,
    status: WebhookDeliveryStatus,
    nextAttemptAt: Date | undefined,
  ): Promise<void> {
    await this.prisma.webhookDelivery.update({
      where: { id: deliveryId },
      data: {
        status,
        attempts,
        lastAttemptAt: new Date(),
        nextAttemptAt,
        lastError: lastError.substring(0, 500),
        responseStatusCode,
        responseBody: responseBody?.substring(0, 2000),
      },
    });
  }

  /**
   * Sign a payload using HMAC-SHA256.
   *
   * SEC-M3: The HMAC key is the SHA-256 hash of the original webhook secret,
   * NOT the plaintext secret itself. This is intentional — we never store the
   * original secret (only its hash), so it cannot leak from a DB breach.
   *
   * Signature: HMAC-SHA256(key=SHA256(secret), payload)
   *
   * Consumer verification pseudocode:
   * ```
   *   derivedKey = SHA256(your_whsec_secret)
   *   expectedSig = HMAC-SHA256(key=derivedKey, body)
   *   assert(timingSafeEqual(expectedSig, X-Webhook-Signature header))
   * ```
   */
  private signPayload(payload: string, secretHash: string): string {
    return crypto
      .createHmac('sha256', secretHash)
      .update(payload, 'utf8')
      .digest('hex');
  }

  /**
   * Type guard to validate that a stored payload matches WebhookEnvelope structure.
   * Ensures safe retrieval of payloads from database JSON fields.
   */
  private isValidWebhookEnvelope(payload: unknown): payload is WebhookEnvelope {
    if (payload === null || typeof payload !== 'object') {
      return false;
    }
    const obj = payload as Record<string, unknown>;
    return (
      typeof obj.id === 'string' &&
      typeof obj.type === 'string' &&
      typeof obj.createdAt === 'string' &&
      typeof obj.version === 'string' &&
      obj.data !== null &&
      typeof obj.data === 'object'
    );
  }

  // ============================================
  // Scheduled Retry Job
  // ============================================

  /**
   * Resume failed webhook deliveries that have pending retry times.
   *
   * This cron job ensures webhook reliability by picking up failed deliveries
   * that were scheduled for retry but lost due to server restart. It queries
   * the WebhookDelivery table for records where:
   * - status = FAILED
   * - nextAttemptAt <= now
   * - attempts < maxAttempts
   *
   * Runs every minute to minimize delivery delays.
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async resumeFailedDeliveries(): Promise<void> {
    try {
      // Find failed deliveries that are due for retry
      const failedDeliveries = await this.prisma.webhookDelivery.findMany({
        where: {
          status: WebhookDeliveryStatus.FAILED,
          nextAttemptAt: { lte: new Date() },
          attempts: { lt: this.retryConfig.maxAttempts },
        },
        include: {
          webhook: {
            select: { id: true, url: true, secretHash: true, isActive: true },
          },
        },
        take: 50, // Process in batches to avoid overload
      });

      if (failedDeliveries.length === 0) {
        return;
      }

      this.logger.log(`Resuming ${failedDeliveries.length} failed webhook deliveries`);

      for (const delivery of failedDeliveries) {
        // Skip if webhook is now inactive
        if (!delivery.webhook.isActive) {
          await this.prisma.webhookDelivery.update({
            where: { id: delivery.id },
            data: {
              status: WebhookDeliveryStatus.FAILED,
              lastError: 'Webhook disabled - retry cancelled',
              nextAttemptAt: null,
            },
          });
          continue;
        }

        // Skip if already being retried in-memory
        if (this.pendingRetries.has(delivery.id)) {
          continue;
        }

        // Validate and reconstruct envelope from stored payload
        if (!this.isValidWebhookEnvelope(delivery.payload)) {
          this.logger.error(`Invalid payload structure for delivery ${delivery.id} - skipping retry`);
          await this.prisma.webhookDelivery.update({
            where: { id: delivery.id },
            data: {
              status: WebhookDeliveryStatus.FAILED,
              lastError: 'Invalid payload structure - retry cancelled',
              nextAttemptAt: null,
            },
          });
          continue;
        }
        const envelope = delivery.payload;

        // Resume delivery with next attempt
        try {
          await this.deliverToWebhook(
            delivery.webhook,
            delivery.event,
            envelope,
            delivery.eventId || envelope.id,
            delivery.isTest,
            delivery.attempts + 1,
            delivery.id,
          );
        } catch (error) {
          this.logger.error(`Failed to resume delivery ${delivery.id}: ${error}`);
        }
      }
    } catch (error) {
      this.logger.error(`Failed to query pending webhook retries: ${error}`);
    }
  }

  /**
   * Cancel all pending retries (for graceful shutdown)
   */
  onModuleDestroy() {
    this.logger.log(`Cancelling ${this.pendingRetries.size} pending webhook retries`);
    for (const [id, timeout] of this.pendingRetries) {
      clearTimeout(timeout);
      this.pendingRetries.delete(id);
    }
  }
}
