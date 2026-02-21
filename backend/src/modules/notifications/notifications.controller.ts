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
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import {
  NotificationsQueryDto,
  NotificationsResponseDto,
  UnreadCountDto,
  MarkReadResponseDto,
} from './dto/notification.dto';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  /**
   * Get notifications for the current user (staff)
   */
  @Get()
  @ApiOperation({ summary: 'Get my notifications' })
  @ApiResponse({
    status: 200,
    description: 'List of notifications',
    type: NotificationsResponseDto,
  })
  async getNotifications(
    @Request() req: any,
    @Query() query: NotificationsQueryDto,
  ): Promise<NotificationsResponseDto> {
    return this.notificationsService.getUserNotifications(req.user.id, query);
  }

  /**
   * Get unread notification count for the current user
   */
  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  @ApiResponse({
    status: 200,
    description: 'Unread count',
    type: UnreadCountDto,
  })
  async getUnreadCount(@Request() req: any): Promise<UnreadCountDto> {
    const count = await this.notificationsService.getUserUnreadCount(
      req.user.id,
    );
    return { count };
  }

  /**
   * Mark a single notification as read
   */
  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark notification as read' })
  @ApiParam({ name: 'id', description: 'Notification ID' })
  @ApiResponse({
    status: 200,
    description: 'Notification marked as read',
    type: MarkReadResponseDto,
  })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async markAsRead(
    @Request() req: any,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<MarkReadResponseDto> {
    await this.notificationsService.markUserNotificationRead(req.user.id, id);
    return { success: true };
  }

  /**
   * Mark all notifications as read
   */
  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiResponse({
    status: 200,
    description: 'All notifications marked as read',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean' },
        count: { type: 'number', description: 'Number of notifications marked as read' },
      },
    },
  })
  async markAllAsRead(
    @Request() req: any,
  ): Promise<{ success: boolean; count: number }> {
    const count = await this.notificationsService.markAllUserNotificationsRead(
      req.user.id,
    );
    return { success: true, count };
  }
}
