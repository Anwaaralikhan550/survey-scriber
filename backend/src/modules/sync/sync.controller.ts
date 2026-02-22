import {
  Controller,
  Post,
  Get,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { UserRole } from '@prisma/client';
import { SyncService } from './sync.service';
import {
  SyncPushDto,
  SyncPullDto,
  SyncPushResponseDto,
  SyncPullResponseDto,
} from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@ApiTags('Sync')
@ApiBearerAuth('JWT-auth')
@Controller('sync')
@UseGuards(JwtAuthGuard, RolesGuard)
// Relaxed rate limits for offline-first sync: the mobile app fires dozens of
// requests when coming back online. These endpoints are already protected by
// JWT + role-based access, so abuse risk is low.
@Throttle({
  short: { limit: 20, ttl: 1000 },
  medium: { limit: 120, ttl: 10000 },
  long: { limit: 600, ttl: 60000 },
})
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Push offline changes to server',
    description:
      'Accepts a batch of operations from the client offline queue. ' +
      'Processes operations transactionally with idempotency support. ' +
      'Duplicate batches (same idempotencyKey) return cached response.',
  })
  @ApiResponse({
    status: 200,
    description: 'Sync push processed successfully',
    type: SyncPushResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid request body' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async push(
    @Body() dto: SyncPushDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SyncPushResponseDto> {
    return this.syncService.push(dto, user);
  }

  @Get('pull')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @ApiOperation({
    summary: 'Pull server changes',
    description:
      'Returns entities that have changed since the provided timestamp. ' +
      'Use the returned serverTimestamp as the since parameter for subsequent pulls. ' +
      'Includes surveys, sections, answers, and media metadata owned by the user.',
  })
  @ApiQuery({
    name: 'since',
    required: false,
    type: String,
    description: 'ISO 8601 timestamp to fetch changes after (exclusive)',
    example: '2024-01-15T10:30:00.000Z',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Maximum number of changes to return (1-500, default 100)',
    example: 100,
  })
  @ApiResponse({
    status: 200,
    description: 'Changes retrieved successfully',
    type: SyncPullResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async pull(
    @Query() dto: SyncPullDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SyncPullResponseDto> {
    return this.syncService.pull(dto, user);
  }
}
