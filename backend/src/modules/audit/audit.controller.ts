import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { AuditService, AuditLogQueryParams } from './audit.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { AuditLogQueryDto, AuditLogListResponseDto } from './dto/audit-log.dto';

@ApiTags('Audit Logs')
@ApiBearerAuth('JWT-auth')
@Controller('audit-logs')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Get()
  @Roles(UserRole.ADMIN)
  @ApiOperation({
    summary: 'List audit logs',
    description:
      'Returns paginated audit logs with optional filters. ADMIN role required.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of audit logs',
    type: AuditLogListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - ADMIN role required' })
  async getAuditLogs(
    @Query() query: AuditLogQueryDto,
  ): Promise<AuditLogListResponseDto> {
    const params: AuditLogQueryParams = {
      page: query.page,
      limit: query.limit,
      actorType: query.actorType,
      actorId: query.actorId,
      entityType: query.entityType,
      entityId: query.entityId,
      action: query.action,
      startDate: query.startDate ? new Date(query.startDate) : undefined,
      endDate: query.endDate ? new Date(query.endDate) : undefined,
    };

    return this.auditService.query(params);
  }
}
