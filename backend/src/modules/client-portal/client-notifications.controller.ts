import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { Request as ExpressRequest } from 'express';
import { ClientJwtGuard } from './guards/client-jwt.guard';
import { NotificationsService } from '../notifications/notifications.service';
import {
  NotificationsQueryDto,
  NotificationsResponseDto,
  UnreadCountDto,
  MarkReadResponseDto,
} from '../notifications/dto/notification.dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Notifications')
@Controller('client/notifications')
@UseGuards(ClientJwtGuard)
@ApiBearerAuth()
export class ClientNotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /**
   * Get notifications for the authenticated client
   */
  @Get()
  @ApiOperation({
    summary: 'Get client notifications',
    description: 'Returns all notifications for the authenticated client.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of notifications',
    type: NotificationsResponseDto,
  })
  async getNotifications(
    @Request() req: ClientRequest,
    @Query() query: NotificationsQueryDto,
  ): Promise<NotificationsResponseDto> {
    return this.notificationsService.getClientNotifications(req.user.id, query);
  }

  /**
   * Get unread notification count for the client
   */
  @Get('unread-count')
  @ApiOperation({
    summary: 'Get unread notification count',
    description: 'Returns the number of unread notifications.',
  })
  @ApiResponse({
    status: 200,
    description: 'Unread count',
    type: UnreadCountDto,
  })
  async getUnreadCount(@Request() req: ClientRequest): Promise<UnreadCountDto> {
    const count = await this.notificationsService.getClientUnreadCount(
      req.user.id,
    );
    return { count };
  }

  /**
   * Mark a single notification as read
   */
  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Mark notification as read',
    description: 'Marks a specific notification as read.',
  })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiResponse({
    status: 200,
    description: 'Notification marked as read',
    type: MarkReadResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async markAsRead(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<MarkReadResponseDto> {
    await this.notificationsService.markClientNotificationRead(req.user.id, id);
    return { success: true };
  }

  /**
   * Mark all notifications as read
   */
  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Mark all notifications as read',
    description: 'Marks all unread notifications as read.',
  })
  @ApiResponse({
    status: 200,
    description: 'All notifications marked as read',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean' },
        count: {
          type: 'number',
          description: 'Number of notifications marked as read',
        },
      },
    },
  })
  async markAllAsRead(
    @Request() req: ClientRequest,
  ): Promise<{ success: boolean; count: number }> {
    const count =
      await this.notificationsService.markAllClientNotificationsRead(
        req.user.id,
      );
    return { success: true, count };
  }
}
