import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { NotificationType, RecipientType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  NotificationsQueryDto,
  NotificationsResponseDto,
  NotificationDto,
  CreateNotificationDto,
} from './dto/notification.dto';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new in-app notification
   */
  async createNotification(dto: CreateNotificationDto): Promise<void> {
    try {
      await this.prisma.notification.create({
        data: {
          type: dto.type,
          recipientType: dto.recipientType,
          recipientId: dto.recipientId,
          title: dto.title,
          body: dto.body,
          bookingId: dto.bookingId,
          invoiceId: dto.invoiceId,
        },
      });
      this.logger.log(
        `Created ${dto.type} notification for ${dto.recipientType}:${dto.recipientId}`,
      );
    } catch (error) {
      this.logger.error(`Failed to create notification: ${error}`);
      // Don't throw - notifications should not break main flow
    }
  }

  /**
   * Get notifications for a user (staff)
   */
  async getUserNotifications(
    userId: string,
    query: NotificationsQueryDto,
  ): Promise<NotificationsResponseDto> {
    return this.getNotifications(RecipientType.USER, userId, query);
  }

  /**
   * Get notifications for a client
   */
  async getClientNotifications(
    clientId: string,
    query: NotificationsQueryDto,
  ): Promise<NotificationsResponseDto> {
    return this.getNotifications(RecipientType.CLIENT, clientId, query);
  }

  /**
   * Get unread count for a user (staff)
   */
  async getUserUnreadCount(userId: string): Promise<number> {
    return this.getUnreadCount(RecipientType.USER, userId);
  }

  /**
   * Get unread count for a client
   */
  async getClientUnreadCount(clientId: string): Promise<number> {
    return this.getUnreadCount(RecipientType.CLIENT, clientId);
  }

  /**
   * Mark a single notification as read (user)
   */
  async markUserNotificationRead(
    userId: string,
    notificationId: string,
  ): Promise<void> {
    await this.markAsRead(RecipientType.USER, userId, notificationId);
  }

  /**
   * Mark a single notification as read (client)
   */
  async markClientNotificationRead(
    clientId: string,
    notificationId: string,
  ): Promise<void> {
    await this.markAsRead(RecipientType.CLIENT, clientId, notificationId);
  }

  /**
   * Mark all notifications as read (user)
   */
  async markAllUserNotificationsRead(userId: string): Promise<number> {
    return this.markAllAsRead(RecipientType.USER, userId);
  }

  /**
   * Mark all notifications as read (client)
   */
  async markAllClientNotificationsRead(clientId: string): Promise<number> {
    return this.markAllAsRead(RecipientType.CLIENT, clientId);
  }

  // ===========================
  // Private Methods
  // ===========================

  private async getNotifications(
    recipientType: RecipientType,
    recipientId: string,
    query: NotificationsQueryDto,
  ): Promise<NotificationsResponseDto> {
    const { page = 1, limit = 20, isRead } = query;
    const skip = (page - 1) * limit;

    const where = {
      recipientType,
      recipientId,
      ...(isRead !== undefined && { isRead }),
    };

    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
    ]);

    const data: NotificationDto[] = notifications.map((n) => ({
      id: n.id,
      type: n.type,
      title: n.title,
      body: n.body,
      bookingId: n.bookingId ?? undefined,
      invoiceId: n.invoiceId ?? undefined,
      isRead: n.isRead,
      readAt: n.readAt ?? undefined,
      createdAt: n.createdAt,
    }));

    return {
      data,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  private async getUnreadCount(
    recipientType: RecipientType,
    recipientId: string,
  ): Promise<number> {
    return this.prisma.notification.count({
      where: {
        recipientType,
        recipientId,
        isRead: false,
      },
    });
  }

  private async markAsRead(
    recipientType: RecipientType,
    recipientId: string,
    notificationId: string,
  ): Promise<void> {
    const notification = await this.prisma.notification.findFirst({
      where: {
        id: notificationId,
        recipientType,
        recipientId,
      },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    if (!notification.isRead) {
      await this.prisma.notification.update({
        where: { id: notificationId },
        data: {
          isRead: true,
          readAt: new Date(),
        },
      });
    }
  }

  private async markAllAsRead(
    recipientType: RecipientType,
    recipientId: string,
  ): Promise<number> {
    const result = await this.prisma.notification.updateMany({
      where: {
        recipientType,
        recipientId,
        isRead: false,
      },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });

    return result.count;
  }

  // ===========================
  // Cleanup Job (90 days retention)
  // ===========================

  /**
   * Delete notifications older than 90 days
   * Runs daily at 3:00 AM
   */
  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async cleanupOldNotifications(): Promise<void> {
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    try {
      const result = await this.prisma.notification.deleteMany({
        where: {
          createdAt: { lt: ninetyDaysAgo },
        },
      });

      if (result.count > 0) {
        this.logger.log(
          `Cleaned up ${result.count} notifications older than 90 days`,
        );
      }
    } catch (error) {
      this.logger.error(`Failed to cleanup old notifications: ${error}`);
    }
  }
}
