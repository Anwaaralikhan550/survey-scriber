import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsUrl,
  IsBoolean,
  IsEnum,
  IsArray,
  IsOptional,
  IsInt,
  IsUUID,
  Min,
  Max,
  ArrayMinSize,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { WebhookEventType, WebhookDeliveryStatus } from '@prisma/client';

/**
 * DTO for creating a new webhook
 */
export class CreateWebhookDto {
  @ApiProperty({
    description: 'The URL to send webhook events to',
    example: 'https://example.com/webhooks/surveyscriber',
  })
  @IsUrl({ require_protocol: true, protocols: ['https'] }, { message: 'URL must be a valid HTTPS URL' })
  url: string;

  @ApiProperty({
    description: 'Event types this webhook should receive',
    enum: WebhookEventType,
    isArray: true,
    example: ['BOOKING_CREATED', 'INVOICE_ISSUED'],
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'At least one event type must be specified' })
  @IsEnum(WebhookEventType, { each: true })
  events: WebhookEventType[];
}

/**
 * DTO for updating an existing webhook
 */
export class UpdateWebhookDto {
  @ApiPropertyOptional({
    description: 'The URL to send webhook events to',
    example: 'https://example.com/webhooks/surveyscriber',
  })
  @IsOptional()
  @IsUrl({ require_protocol: true, protocols: ['https'] }, { message: 'URL must be a valid HTTPS URL' })
  url?: string;

  @ApiPropertyOptional({
    description: 'Event types this webhook should receive',
    enum: WebhookEventType,
    isArray: true,
    example: ['BOOKING_CREATED', 'INVOICE_ISSUED'],
  })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1, { message: 'At least one event type must be specified' })
  @IsEnum(WebhookEventType, { each: true })
  events?: WebhookEventType[];

  @ApiPropertyOptional({
    description: 'Whether the webhook is active',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/**
 * DTO for webhook response (excludes secret)
 */
export class WebhookResponseDto {
  @ApiProperty({ description: 'Webhook ID' })
  id: string;

  @ApiProperty({ description: 'Webhook URL' })
  url: string;

  @ApiProperty({ description: 'Whether the webhook is active' })
  isActive: boolean;

  @ApiProperty({
    description: 'Event types this webhook receives',
    enum: WebhookEventType,
    isArray: true,
  })
  events: WebhookEventType[];

  @ApiProperty({ description: 'Creation timestamp' })
  createdAt: Date;

  @ApiProperty({ description: 'Last update timestamp' })
  updatedAt: Date;
}

/**
 * DTO for webhook creation response (includes secret - shown only once)
 */
export class WebhookCreatedResponseDto extends WebhookResponseDto {
  @ApiProperty({
    description: 'Webhook secret - SAVE THIS! Only shown once at creation time.',
    example: 'whsec_abc123...',
  })
  secret: string;
}

/**
 * DTO for webhook delivery log
 */
export class WebhookDeliveryDto {
  @ApiProperty({ description: 'Delivery ID' })
  id: string;

  @ApiProperty({ description: 'Webhook ID' })
  webhookId: string;

  @ApiProperty({
    description: 'Event type',
    enum: WebhookEventType,
  })
  event: WebhookEventType;

  @ApiPropertyOptional({ description: 'Unique event ID (evt_<uuid>)' })
  eventId?: string;

  @ApiProperty({ description: 'Payload sent to webhook' })
  payload: object;

  @ApiProperty({
    description: 'Delivery status',
    enum: WebhookDeliveryStatus,
  })
  status: WebhookDeliveryStatus;

  @ApiPropertyOptional({ description: 'HTTP response status code' })
  responseStatusCode?: number;

  @ApiPropertyOptional({ description: 'HTTP response body (truncated)' })
  responseBody?: string;

  @ApiProperty({ description: 'Number of delivery attempts' })
  attempts: number;

  @ApiPropertyOptional({ description: 'Last attempt timestamp' })
  lastAttemptAt?: Date;

  @ApiPropertyOptional({ description: 'Next retry attempt scheduled at' })
  nextAttemptAt?: Date;

  @ApiPropertyOptional({ description: 'Last error message' })
  lastError?: string;

  @ApiProperty({ description: 'Whether this is a test event' })
  isTest: boolean;

  @ApiProperty({ description: 'Delivery timestamp' })
  createdAt: Date;
}

/**
 * DTO for sending a test webhook event
 */
export class SendTestEventDto {
  @ApiProperty({
    description: 'Event type to test',
    enum: WebhookEventType,
    example: 'BOOKING_CREATED',
  })
  @IsEnum(WebhookEventType)
  event: WebhookEventType;
}

/**
 * Response DTO for test event
 */
export class TestEventResponseDto {
  @ApiProperty({ description: 'Whether the test was successful' })
  success: boolean;

  @ApiProperty({ description: 'The event ID that was dispatched' })
  eventId: string;
}

/**
 * DTO for querying webhook delivery logs
 */
export class WebhookDeliveryQueryDto {
  @ApiPropertyOptional({ description: 'Page number', default: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  page?: number = 1;

  @ApiPropertyOptional({ description: 'Items per page', default: 20 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  @Type(() => Number)
  limit?: number = 20;

  @ApiPropertyOptional({
    description: 'Filter by event type',
    enum: WebhookEventType,
  })
  @IsOptional()
  @IsEnum(WebhookEventType)
  event?: WebhookEventType;

  @ApiPropertyOptional({
    description: 'Filter by status',
    enum: WebhookDeliveryStatus,
  })
  @IsOptional()
  @IsEnum(WebhookDeliveryStatus)
  status?: WebhookDeliveryStatus;

  @ApiPropertyOptional({
    description: 'Filter by test deliveries (true = only test, false = only real, omit = all)',
  })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => {
    if (value === 'true') return true;
    if (value === 'false') return false;
    return value;
  })
  isTest?: boolean;
}

/**
 * DTO for paginated delivery logs response
 */
export class WebhookDeliveryListResponseDto {
  @ApiProperty({ type: [WebhookDeliveryDto] })
  data: WebhookDeliveryDto[];

  @ApiProperty()
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

/**
 * DTO for list of webhooks
 */
export class WebhookListResponseDto {
  @ApiProperty({ type: [WebhookResponseDto] })
  data: WebhookResponseDto[];
}
