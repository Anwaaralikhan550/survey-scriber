import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WebhookEventType, WebhookDeliveryStatus, ActorType, AuditEntityType } from '@prisma/client';
import * as crypto from 'crypto';
import * as dns from 'dns';
import { promisify } from 'util';
import * as net from 'net';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService, AuditActions } from '../audit/audit.service';
import {
  CreateWebhookDto,
  UpdateWebhookDto,
  WebhookResponseDto,
  WebhookCreatedResponseDto,
  WebhookDeliveryDto,
  WebhookDeliveryQueryDto,
  WebhookDeliveryListResponseDto,
  WebhookListResponseDto,
} from './dto/webhook.dto';

interface AuthenticatedUser {
  id: string;
  email: string;
}

const dnsLookup = promisify(dns.lookup);

@Injectable()
export class WebhooksService {
  private readonly logger = new Logger(WebhooksService.name);
  private readonly isProduction: boolean;

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    private readonly configService: ConfigService,
  ) {
    this.isProduction = this.configService.get('NODE_ENV') === 'production';
  }

  /**
   * SEC-004: SSRF protection - validate webhook URL is not targeting internal/private IPs
   * SEC-005: Transport security - enforce HTTPS in production environments
   *
   * Blocks:
   * - localhost, private IPs (RFC1918), link-local, loopback, reserved ranges
   * - HTTP URLs in production (HTTPS required for transport security)
   */
  private async validateWebhookUrl(url: string): Promise<void> {
    let parsedUrl: URL;
    try {
      parsedUrl = new URL(url);
    } catch {
      throw new BadRequestException('Invalid URL format');
    }

    // SEC-005: Enforce HTTPS in production for transport security
    // HTTP is only allowed in development/test environments for local testing
    if (this.isProduction) {
      if (parsedUrl.protocol !== 'https:') {
        this.logger.warn(`Rejected HTTP webhook URL in production: ${url}`);
        throw new BadRequestException(
          'Webhook URLs must use HTTPS in production. ' +
          'HTTP is not allowed for security reasons.',
        );
      }
    } else {
      // In non-production, allow HTTP for local development but log a warning
      if (parsedUrl.protocol === 'http:') {
        this.logger.warn(
          `HTTP webhook URL accepted in ${this.configService.get('NODE_ENV') || 'development'} mode: ${url}. ` +
          'This would be rejected in production.',
        );
      }
      // Reject non-HTTP/HTTPS protocols in all environments
      if (parsedUrl.protocol !== 'https:' && parsedUrl.protocol !== 'http:') {
        throw new BadRequestException('Only HTTP/HTTPS URLs are allowed');
      }
    }

    const hostname = parsedUrl.hostname.toLowerCase();

    // Block localhost and common localhost aliases
    const blockedHostnames = ['localhost', '127.0.0.1', '0.0.0.0', '::1', '[::1]'];
    if (blockedHostnames.includes(hostname)) {
      throw new BadRequestException('Webhook URL cannot target localhost');
    }

    // Resolve hostname to IP and check if it's private/internal
    try {
      const { address } = await dnsLookup(hostname);
      if (this.isPrivateOrReservedIp(address)) {
        this.logger.warn(`SSRF attempt blocked: ${hostname} resolved to private IP ${address}`);
        throw new BadRequestException('Webhook URL cannot target internal/private networks');
      }
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      // DNS resolution failed - could be invalid hostname
      throw new BadRequestException('Could not resolve webhook URL hostname');
    }
  }

  /**
   * Check if IP address is private, internal, or reserved
   */
  private isPrivateOrReservedIp(ip: string): boolean {
    // IPv4 checks
    if (net.isIPv4(ip)) {
      const parts = ip.split('.').map(Number);
      const [a, b] = parts;

      // Loopback: 127.0.0.0/8
      if (a === 127) return true;
      // Private: 10.0.0.0/8
      if (a === 10) return true;
      // Private: 172.16.0.0/12
      if (a === 172 && b >= 16 && b <= 31) return true;
      // Private: 192.168.0.0/16
      if (a === 192 && b === 168) return true;
      // Link-local: 169.254.0.0/16
      if (a === 169 && b === 254) return true;
      // Current network: 0.0.0.0/8
      if (a === 0) return true;
      // Broadcast: 255.255.255.255
      if (ip === '255.255.255.255') return true;
    }

    // IPv6 checks
    if (net.isIPv6(ip)) {
      const normalized = ip.toLowerCase();
      // Loopback ::1
      if (normalized === '::1') return true;
      // Link-local fe80::/10
      if (normalized.startsWith('fe80:')) return true;
      // Unique local fc00::/7
      if (normalized.startsWith('fc') || normalized.startsWith('fd')) return true;
    }

    return false;
  }

  /**
   * Create a new webhook
   * Generates a random secret and stores its hash
   */
  async createWebhook(
    dto: CreateWebhookDto,
    user: AuthenticatedUser,
  ): Promise<WebhookCreatedResponseDto> {
    // SEC-004: Validate URL to prevent SSRF attacks
    await this.validateWebhookUrl(dto.url);

    // I4: Prevent duplicate webhook URLs at app level (DB unique constraint is the safety net)
    const existingUrl = await this.prisma.webhook.findUnique({ where: { url: dto.url } });
    if (existingUrl) {
      throw new ConflictException('A webhook with this URL already exists');
    }

    // Generate a random 64-character secret with prefix for identification
    const secret = `whsec_${crypto.randomBytes(32).toString('hex')}`;
    const secretHash = this.hashSecret(secret);

    const webhook = await this.prisma.webhook.create({
      data: {
        url: dto.url,
        secretHash,
        events: dto.events,
        isActive: true,
      },
    });

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.WEBHOOK_CREATED,
      entityType: AuditEntityType.WEBHOOK,
      entityId: webhook.id,
      metadata: { url: dto.url, events: dto.events },
    });

    this.logger.log(`Webhook created: ${webhook.id} by user ${user.id}`);

    return {
      id: webhook.id,
      url: webhook.url,
      isActive: webhook.isActive,
      events: webhook.events,
      createdAt: webhook.createdAt,
      updatedAt: webhook.updatedAt,
      secret, // Only returned once at creation time
    };
  }

  /**
   * Get all webhooks
   */
  async getWebhooks(): Promise<WebhookListResponseDto> {
    const webhooks = await this.prisma.webhook.findMany({
      orderBy: { createdAt: 'desc' },
    });

    return {
      data: webhooks.map((w) => this.mapToResponseDto(w)),
    };
  }

  /**
   * Get a specific webhook by ID
   */
  async getWebhookById(id: string): Promise<WebhookResponseDto> {
    const webhook = await this.prisma.webhook.findUnique({
      where: { id },
    });

    if (!webhook) {
      throw new NotFoundException('Webhook not found');
    }

    return this.mapToResponseDto(webhook);
  }

  /**
   * Update a webhook
   */
  async updateWebhook(
    id: string,
    dto: UpdateWebhookDto,
    user: AuthenticatedUser,
  ): Promise<WebhookResponseDto> {
    const existing = await this.prisma.webhook.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Webhook not found');
    }

    // SEC-004: Validate URL to prevent SSRF attacks (only if URL is being changed)
    if (dto.url !== undefined) {
      await this.validateWebhookUrl(dto.url);

      // I4: Prevent duplicate webhook URLs at app level
      const existingUrl = await this.prisma.webhook.findUnique({ where: { url: dto.url } });
      if (existingUrl && existingUrl.id !== id) {
        throw new ConflictException('A webhook with this URL already exists');
      }
    }

    const updateData: any = {};
    if (dto.url !== undefined) updateData.url = dto.url;
    if (dto.events !== undefined) updateData.events = dto.events;
    if (dto.isActive !== undefined) updateData.isActive = dto.isActive;

    const webhook = await this.prisma.webhook.update({
      where: { id },
      data: updateData,
    });

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.WEBHOOK_UPDATED,
      entityType: AuditEntityType.WEBHOOK,
      entityId: webhook.id,
      metadata: { changes: dto },
    });

    this.logger.log(`Webhook updated: ${webhook.id} by user ${user.id}`);

    return this.mapToResponseDto(webhook);
  }

  /**
   * Disable (soft delete) a webhook
   */
  async disableWebhook(id: string, user: AuthenticatedUser): Promise<void> {
    const existing = await this.prisma.webhook.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Webhook not found');
    }

    await this.prisma.webhook.update({
      where: { id },
      data: { isActive: false },
    });

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.WEBHOOK_DISABLED,
      entityType: AuditEntityType.WEBHOOK,
      entityId: id,
    });

    this.logger.log(`Webhook disabled: ${id} by user ${user.id}`);
  }

  /**
   * Get delivery logs for a webhook
   */
  async getWebhookDeliveries(
    webhookId: string,
    query: WebhookDeliveryQueryDto,
  ): Promise<WebhookDeliveryListResponseDto> {
    const webhook = await this.prisma.webhook.findUnique({
      where: { id: webhookId },
    });

    if (!webhook) {
      throw new NotFoundException('Webhook not found');
    }

    const { page = 1, limit = 20, event, status, isTest } = query;
    const skip = (page - 1) * limit;

    const where: any = { webhookId };
    if (event) where.event = event;
    if (status) where.status = status;
    if (isTest !== undefined) where.isTest = isTest; // M7 fix: filter by test deliveries

    const [deliveries, total] = await Promise.all([
      this.prisma.webhookDelivery.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.webhookDelivery.count({ where }),
    ]);

    return {
      data: deliveries.map((d) => this.mapToDeliveryDto(d)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get all active webhooks subscribed to a specific event
   */
  async getActiveWebhooksForEvent(event: WebhookEventType) {
    return this.prisma.webhook.findMany({
      where: {
        isActive: true,
        events: { has: event },
      },
    });
  }

  /**
   * Log a webhook delivery attempt (legacy method for backward compatibility)
   */
  async logDelivery(data: {
    webhookId: string;
    event: WebhookEventType;
    payload: object;
    status: WebhookDeliveryStatus;
    responseStatusCode?: number;
    responseBody?: string;
  }): Promise<void> {
    await this.prisma.webhookDelivery.create({
      data: {
        webhookId: data.webhookId,
        event: data.event,
        payload: data.payload,
        status: data.status,
        responseStatusCode: data.responseStatusCode,
        responseBody: data.responseBody?.substring(0, 2000),
        attempts: 1,
      },
    });
  }

  /**
   * Log a webhook delivery attempt with extended details (for retry support)
   * Returns the created delivery ID for retry tracking
   */
  async logDeliveryWithDetails(data: {
    webhookId: string;
    event: WebhookEventType;
    eventId?: string;
    payload: object;
    status: WebhookDeliveryStatus;
    responseStatusCode?: number;
    responseBody?: string;
    attempts: number;
    lastAttemptAt?: Date;
    lastError?: string;
    nextAttemptAt?: Date;
    isTest?: boolean;
  }): Promise<string> {
    const delivery = await this.prisma.webhookDelivery.create({
      data: {
        webhookId: data.webhookId,
        event: data.event,
        eventId: data.eventId,
        payload: data.payload,
        status: data.status,
        responseStatusCode: data.responseStatusCode,
        responseBody: data.responseBody?.substring(0, 2000),
        attempts: data.attempts,
        lastAttemptAt: data.lastAttemptAt,
        lastError: data.lastError?.substring(0, 500),
        nextAttemptAt: data.nextAttemptAt,
        isTest: data.isTest ?? false,
      },
    });
    return delivery.id;
  }

  /**
   * Hash a secret using SHA-256
   */
  private hashSecret(secret: string): string {
    return crypto.createHash('sha256').update(secret).digest('hex');
  }

  private mapToResponseDto(webhook: any): WebhookResponseDto {
    return {
      id: webhook.id,
      url: webhook.url,
      isActive: webhook.isActive,
      events: webhook.events,
      createdAt: webhook.createdAt,
      updatedAt: webhook.updatedAt,
    };
  }

  private mapToDeliveryDto(delivery: any): WebhookDeliveryDto {
    return {
      id: delivery.id,
      webhookId: delivery.webhookId,
      event: delivery.event,
      eventId: delivery.eventId ?? undefined,
      payload: delivery.payload,
      status: delivery.status,
      responseStatusCode: delivery.responseStatusCode ?? undefined,
      responseBody: delivery.responseBody ?? undefined,
      attempts: delivery.attempts,
      lastAttemptAt: delivery.lastAttemptAt ?? undefined,
      nextAttemptAt: delivery.nextAttemptAt ?? undefined,
      lastError: delivery.lastError ?? undefined,
      isTest: delivery.isTest ?? false,
      createdAt: delivery.createdAt,
    };
  }
}
