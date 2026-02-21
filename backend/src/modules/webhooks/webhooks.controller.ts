import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
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
import { UserRole } from '@prisma/client';
import { WebhooksService } from './webhooks.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import {
  CreateWebhookDto,
  UpdateWebhookDto,
  WebhookResponseDto,
  WebhookCreatedResponseDto,
  WebhookDeliveryQueryDto,
  WebhookDeliveryListResponseDto,
  WebhookListResponseDto,
  SendTestEventDto,
  TestEventResponseDto,
} from './dto/webhook.dto';
import { WebhookDispatcherService } from './webhook-dispatcher.service';
import { AuditService, AuditActions } from '../audit/audit.service';
import { ActorType, AuditEntityType } from '@prisma/client';

@ApiTags('Webhooks')
@ApiBearerAuth('JWT-auth')
@Controller('webhooks')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MANAGER)
export class WebhooksController {
  constructor(
    private readonly webhooksService: WebhooksService,
    private readonly webhookDispatcher: WebhookDispatcherService,
    private readonly auditService: AuditService,
  ) {}

  @Post()
  @ApiOperation({
    summary: 'Register a new webhook',
    description:
      'Creates a new webhook endpoint. The secret is returned only once in the response - save it securely!',
  })
  @ApiResponse({
    status: 201,
    description: 'Webhook created successfully. Secret is included in response.',
    type: WebhookCreatedResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid request data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  async createWebhook(
    @Body() dto: CreateWebhookDto,
    @CurrentUser() user: { id: string; email: string },
  ): Promise<WebhookCreatedResponseDto> {
    return this.webhooksService.createWebhook(dto, user);
  }

  @Get()
  @ApiOperation({
    summary: 'List all webhooks',
    description: 'Returns all registered webhooks (secrets are not included)',
  })
  @ApiResponse({
    status: 200,
    description: 'List of webhooks',
    type: WebhookListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  async getWebhooks(): Promise<WebhookListResponseDto> {
    return this.webhooksService.getWebhooks();
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get a specific webhook',
    description: 'Returns webhook details (secret is not included)',
  })
  @ApiParam({ name: 'id', description: 'Webhook ID' })
  @ApiResponse({
    status: 200,
    description: 'Webhook details',
    type: WebhookResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  @ApiResponse({ status: 404, description: 'Webhook not found' })
  async getWebhook(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<WebhookResponseDto> {
    return this.webhooksService.getWebhookById(id);
  }

  @Put(':id')
  @ApiOperation({
    summary: 'Update a webhook',
    description: 'Updates webhook URL, events, or active status. Secret cannot be changed.',
  })
  @ApiParam({ name: 'id', description: 'Webhook ID' })
  @ApiResponse({
    status: 200,
    description: 'Webhook updated successfully',
    type: WebhookResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid request data' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  @ApiResponse({ status: 404, description: 'Webhook not found' })
  async updateWebhook(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateWebhookDto,
    @CurrentUser() user: { id: string; email: string },
  ): Promise<WebhookResponseDto> {
    return this.webhooksService.updateWebhook(id, dto, user);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({
    summary: 'Disable a webhook',
    description: 'Disables a webhook (soft delete). The webhook will no longer receive events.',
  })
  @ApiParam({ name: 'id', description: 'Webhook ID' })
  @ApiResponse({ status: 204, description: 'Webhook disabled successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  @ApiResponse({ status: 404, description: 'Webhook not found' })
  async disableWebhook(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: { id: string; email: string },
  ): Promise<void> {
    return this.webhooksService.disableWebhook(id, user);
  }

  @Get(':id/deliveries')
  @ApiOperation({
    summary: 'Get webhook delivery logs',
    description: 'Returns paginated delivery logs for a specific webhook',
  })
  @ApiParam({ name: 'id', description: 'Webhook ID' })
  @ApiResponse({
    status: 200,
    description: 'Delivery logs',
    type: WebhookDeliveryListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  @ApiResponse({ status: 404, description: 'Webhook not found' })
  async getWebhookDeliveries(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: WebhookDeliveryQueryDto,
  ): Promise<WebhookDeliveryListResponseDto> {
    return this.webhooksService.getWebhookDeliveries(id, query);
  }

  @Post(':id/test')
  @ApiOperation({
    summary: 'Send a test webhook event',
    description:
      'Dispatches a test event to the webhook to verify configuration. Useful for Zapier/Make setup.',
  })
  @ApiParam({ name: 'id', description: 'Webhook ID' })
  @ApiResponse({
    status: 200,
    description: 'Test event dispatched',
    type: TestEventResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid event type or webhook disabled' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN/MANAGER role required' })
  @ApiResponse({ status: 404, description: 'Webhook not found' })
  async sendTestEvent(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SendTestEventDto,
    @CurrentUser() user: { id: string; email: string },
  ): Promise<TestEventResponseDto> {
    const result = await this.webhookDispatcher.dispatchTestEvent(id, dto.event);

    // Audit log the test event
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.WEBHOOK_TEST_SENT,
      entityType: AuditEntityType.WEBHOOK,
      entityId: id,
      metadata: { event: dto.event, eventId: result.eventId, success: result.success },
    });

    return result;
  }
}
