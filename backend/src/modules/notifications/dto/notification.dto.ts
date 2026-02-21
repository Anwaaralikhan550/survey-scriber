import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsOptional,
  IsInt,
  Min,
  Max,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NotificationType, RecipientType } from '@prisma/client';

// ===========================
// Query DTOs
// ===========================

export class NotificationsQueryDto {
  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Items per page', default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;

  @ApiPropertyOptional({ description: 'Filter by read status' })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isRead?: boolean;
}

// ===========================
// Response DTOs
// ===========================

export class NotificationDto {
  @ApiProperty({ description: 'Notification ID' })
  id: string;

  @ApiProperty({ enum: NotificationType, description: 'Notification type' })
  type: NotificationType;

  @ApiProperty({ description: 'Notification title' })
  title: string;

  @ApiProperty({ description: 'Notification body' })
  body: string;

  @ApiPropertyOptional({ description: 'Related booking ID' })
  bookingId?: string;

  @ApiPropertyOptional({ description: 'Related invoice ID' })
  invoiceId?: string;

  @ApiProperty({ description: 'Whether notification has been read' })
  isRead: boolean;

  @ApiPropertyOptional({ description: 'When notification was read' })
  readAt?: Date;

  @ApiProperty({ description: 'When notification was created' })
  createdAt: Date;
}

export class PaginationDto {
  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;

  @ApiProperty()
  total: number;

  @ApiProperty()
  totalPages: number;
}

export class NotificationsResponseDto {
  @ApiProperty({ type: [NotificationDto] })
  data: NotificationDto[];

  @ApiProperty({ type: PaginationDto })
  pagination: PaginationDto;
}

export class UnreadCountDto {
  @ApiProperty({ description: 'Number of unread notifications' })
  count: number;
}

export class MarkReadResponseDto {
  @ApiProperty({ description: 'Whether operation succeeded' })
  success: boolean;
}

// ===========================
// Internal DTOs (for service)
// ===========================

export interface CreateNotificationDto {
  type: NotificationType;
  recipientType: RecipientType;
  recipientId: string;
  title: string;
  body: string;
  bookingId?: string;
  invoiceId?: string;
}
