import {
  Controller,
  Get,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { BookingChangeRequestsService } from './booking-change-requests.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import {
  StaffBookingChangeRequestsQueryDto,
  ApproveBookingChangeRequestDto,
  RejectBookingChangeRequestDto,
  BookingChangeRequestDto,
  BookingChangeRequestsListResponseDto,
} from './dto';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@ApiTags('Booking Change Requests (Staff)')
@ApiBearerAuth('JWT-auth')
@Controller('booking-changes')
@UseGuards(JwtAuthGuard, RolesGuard)
export class StaffBookingChangeRequestsController {
  constructor(
    private readonly changeRequestsService: BookingChangeRequestsService,
  ) {}

  @Get()
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({
    summary: 'List all booking change requests',
    description:
      'Returns all booking change requests with optional filters. Only ADMIN and MANAGER can access.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of change requests',
    type: BookingChangeRequestsListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async getChangeRequests(
    @Query() query: StaffBookingChangeRequestsQueryDto,
  ): Promise<BookingChangeRequestsListResponseDto> {
    return this.changeRequestsService.getStaffChangeRequests(query);
  }

  @Get(':id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({
    summary: 'Get change request details',
    description: 'Returns details of a specific change request.',
  })
  @ApiParam({
    name: 'id',
    description: 'Change request ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Change request details',
    type: BookingChangeRequestDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Change request not found' })
  async getChangeRequest(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BookingChangeRequestDto> {
    return this.changeRequestsService.getStaffChangeRequest(id);
  }

  @Patch(':id/approve')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Approve a change request',
    description:
      'Approve a pending change request. For reschedule: updates booking date/time. For cancel: sets booking to CANCELLED. Client will be notified.',
  })
  @ApiParam({
    name: 'id',
    description: 'Change request ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Change request approved',
    type: BookingChangeRequestDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Cannot approve - request not in REQUESTED status',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Change request not found' })
  async approveChangeRequest(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ApproveBookingChangeRequestDto,
  ): Promise<BookingChangeRequestDto> {
    return this.changeRequestsService.approveChangeRequest(id, user);
  }

  @Patch(':id/reject')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reject a change request',
    description:
      'Reject a pending change request. Client will be notified.',
  })
  @ApiParam({
    name: 'id',
    description: 'Change request ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Change request rejected',
    type: BookingChangeRequestDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Cannot reject - request not in REQUESTED status',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Change request not found' })
  async rejectChangeRequest(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RejectBookingChangeRequestDto,
  ): Promise<BookingChangeRequestDto> {
    return this.changeRequestsService.rejectChangeRequest(id, user, dto.reason);
  }
}
