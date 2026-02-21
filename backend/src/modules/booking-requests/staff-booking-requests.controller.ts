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
import { BookingRequestsService } from './booking-requests.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import {
  StaffBookingRequestsQueryDto,
  ApproveBookingRequestDto,
  RejectBookingRequestDto,
  BookingRequestDto,
  BookingRequestsListResponseDto,
} from './dto';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@ApiTags('Booking Requests (Staff)')
@ApiBearerAuth('JWT-auth')
@Controller('booking-requests')
@UseGuards(JwtAuthGuard, RolesGuard)
export class StaffBookingRequestsController {
  constructor(
    private readonly bookingRequestsService: BookingRequestsService,
  ) {}

  @Get()
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({
    summary: 'List all booking requests',
    description:
      'Returns all booking requests with optional filters. Only ADMIN and MANAGER can access.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of booking requests',
    type: BookingRequestsListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async getBookingRequests(
    @Query() query: StaffBookingRequestsQueryDto,
  ): Promise<BookingRequestsListResponseDto> {
    return this.bookingRequestsService.getStaffBookingRequests(query);
  }

  @Get(':id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({
    summary: 'Get booking request details',
    description: 'Returns details of a specific booking request.',
  })
  @ApiParam({
    name: 'id',
    description: 'Booking request ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Booking request details',
    type: BookingRequestDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Booking request not found' })
  async getBookingRequest(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BookingRequestDto> {
    return this.bookingRequestsService.getStaffBookingRequest(id);
  }

  @Patch(':id/approve')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Approve a booking request',
    description:
      'Approve a pending booking request. Client will be notified.',
  })
  @ApiParam({
    name: 'id',
    description: 'Booking request ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Booking request approved',
    type: BookingRequestDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Cannot approve - request not in REQUESTED status',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Booking request not found' })
  async approveBookingRequest(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: ApproveBookingRequestDto,
  ): Promise<BookingRequestDto> {
    return this.bookingRequestsService.approveBookingRequest(id, user);
  }

  @Patch(':id/reject')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reject a booking request',
    description:
      'Reject a pending booking request. Client will be notified.',
  })
  @ApiParam({
    name: 'id',
    description: 'Booking request ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Booking request rejected',
    type: BookingRequestDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Cannot reject - request not in REQUESTED status',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Booking request not found' })
  async rejectBookingRequest(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RejectBookingRequestDto,
  ): Promise<BookingRequestDto> {
    return this.bookingRequestsService.rejectBookingRequest(
      id,
      user,
      dto.reason,
    );
  }
}
