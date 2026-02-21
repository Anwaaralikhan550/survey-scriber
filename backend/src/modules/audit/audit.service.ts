import { Injectable, Logger } from '@nestjs/common';
import { ActorType, AuditEntityType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { Request } from 'express';

/**
 * Parameters for logging an audit event
 */
export interface AuditLogParams {
  actorType: ActorType;
  actorId?: string;
  action: string;
  entityType: AuditEntityType;
  entityId?: string;
  metadata?: Record<string, any>;
  request?: Request;
}

/**
 * Query parameters for fetching audit logs
 */
export interface AuditLogQueryParams {
  page?: number;
  limit?: number;
  actorType?: ActorType;
  actorId?: string;
  entityType?: AuditEntityType;
  entityId?: string;
  action?: string;
  startDate?: Date;
  endDate?: Date;
}

/**
 * Paginated audit log result
 */
export interface AuditLogResult {
  // Standard format
  data: any[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
  // Deprecated fields (kept for backward compatibility)
  logs: any[];
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

/**
 * AuditService - handles all audit logging operations
 * Provides a simple interface for logging security-relevant events
 */
@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Log an audit event
   * This method never throws - failures are logged but don't break application flow
   */
  async log(params: AuditLogParams): Promise<void> {
    try {
      const ip = this.extractIp(params.request);
      const userAgent = this.extractUserAgent(params.request);

      await this.prisma.auditLog.create({
        data: {
          actorType: params.actorType,
          actorId: params.actorId,
          action: params.action,
          entityType: params.entityType,
          entityId: params.entityId,
          metadata: params.metadata ?? Prisma.JsonNull,
          ip,
          userAgent,
        },
      });

      this.logger.debug(
        `Audit: ${params.actorType}/${params.actorId || 'unknown'} performed ${params.action} on ${params.entityType}/${params.entityId || 'unknown'}`,
      );
    } catch (error) {
      // Never throw from audit logging - just log the error
      this.logger.error('Failed to write audit log', error);
    }
  }

  /**
   * Query audit logs with pagination and filters
   */
  async query(params: AuditLogQueryParams): Promise<AuditLogResult> {
    const page = params.page || 1;
    const limit = Math.min(params.limit || 50, 100);
    const skip = (page - 1) * limit;

    const where: Prisma.AuditLogWhereInput = {};

    if (params.actorType) {
      where.actorType = params.actorType;
    }
    if (params.actorId) {
      where.actorId = params.actorId;
    }
    if (params.entityType) {
      where.entityType = params.entityType;
    }
    if (params.entityId) {
      where.entityId = params.entityId;
    }
    if (params.action) {
      where.action = { contains: params.action, mode: 'insensitive' };
    }
    if (params.startDate || params.endDate) {
      where.createdAt = {};
      if (params.startDate) {
        where.createdAt.gte = params.startDate;
      }
      if (params.endDate) {
        where.createdAt.lte = params.endDate;
      }
    }

    const [logs, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.auditLog.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      // Standard format
      data: logs,
      meta: {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
      // Deprecated fields (kept for backward compatibility)
      logs,
      page,
      limit,
      total,
      totalPages,
    };
  }

  /**
   * Extract client IP from request
   */
  private extractIp(request?: Request): string | undefined {
    if (!request) return undefined;

    const forwarded = request.headers['x-forwarded-for'];
    if (forwarded) {
      const ips = (Array.isArray(forwarded) ? forwarded[0] : forwarded).split(',');
      return ips[0].trim().substring(0, 45);
    }
    return (request.ip || request.socket?.remoteAddress)?.substring(0, 45);
  }

  /**
   * Extract user agent from request
   */
  private extractUserAgent(request?: Request): string | undefined {
    if (!request) return undefined;

    const ua = request.headers['user-agent'];
    return ua?.substring(0, 500);
  }
}

/**
 * Common audit actions constants
 */
export const AuditActions = {
  // Auth - Staff
  STAFF_LOGIN: 'staff.login',
  STAFF_LOGOUT: 'staff.logout',
  STAFF_LOGIN_FAILED: 'staff.login_failed',
  STAFF_PASSWORD_CHANGED: 'staff.password_changed',
  STAFF_PASSWORD_RESET: 'staff.password_reset',
  STAFF_TOKEN_REUSE_DETECTED: 'staff.token_reuse_detected',

  // Auth - Client
  MAGIC_LINK_VERIFIED: 'magic_link.verified',
  CLIENT_LOGIN: 'client.login',
  CLIENT_LOGOUT: 'client.logout',
  CLIENT_TOKEN_REUSE_DETECTED: 'client.token_reuse_detected',

  // Legacy alias (kept for backward compatibility)
  LOGIN_FAILED: 'staff.login_failed',

  // User Management
  USER_ROLE_CHANGED: 'user.role_changed',

  // Booking Requests
  BOOKING_REQUEST_CREATED: 'booking_request.created',
  BOOKING_REQUEST_APPROVED: 'booking_request.approved',
  BOOKING_REQUEST_REJECTED: 'booking_request.rejected',

  // Booking Change Requests
  CHANGE_REQUEST_CREATED: 'change_request.created',
  CHANGE_REQUEST_APPROVED: 'change_request.approved',
  CHANGE_REQUEST_REJECTED: 'change_request.rejected',

  // Invoices
  INVOICE_ISSUED: 'invoice.issued',
  INVOICE_PAID: 'invoice.paid',
  INVOICE_CANCELLED: 'invoice.cancelled',

  // Reports
  REPORT_PDF_UPLOADED: 'report_pdf.uploaded',
  REPORT_EMAIL_SENT: 'report_email.sent',

  // Webhooks
  WEBHOOK_CREATED: 'webhook.created',
  WEBHOOK_UPDATED: 'webhook.updated',
  WEBHOOK_DISABLED: 'webhook.disabled',
  WEBHOOK_TEST_SENT: 'webhook.test_sent',

  // Data Exports
  DATA_EXPORTED: 'data.exported',
} as const;
