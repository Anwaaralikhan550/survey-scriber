import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { SchedulingService } from './scheduling.service';
import {
  SetAvailabilityDto,
  AvailabilityResponseDto,
  CreateExceptionDto,
  UpdateExceptionDto,
  ExceptionResponseDto,
  CreateBookingDto,
  UpdateBookingDto,
  UpdateBookingStatusDto,
  ListBookingsDto,
  BookingResponseDto,
  BookingListResponseDto,
  GetSlotsDto,
  SlotsResponseDto,
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

@ApiTags('Scheduling')
@ApiBearerAuth('JWT-auth')
@Controller('scheduling')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SchedulingController {
  constructor(private readonly schedulingService: SchedulingService) {}

  // ===========================
  // AVAILABILITY ENDPOINTS
  // ===========================
  // NOTE: Static routes (e.g., 'availability/exceptions') MUST come before
  // parameterized routes (e.g., 'availability/:userId') to prevent NestJS
  // from matching 'exceptions' as a userId parameter.

  @Get('availability')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Get current user\'s weekly availability' })
  @ApiResponse({
    status: 200,
    description: 'Weekly availability retrieved successfully',
    type: [AvailabilityResponseDto],
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMyAvailability(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AvailabilityResponseDto[]> {
    return this.schedulingService.getAvailability(user.id);
  }

  @Put('availability')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Set/update current user\'s weekly availability' })
  @ApiResponse({
    status: 200,
    description: 'Availability updated successfully',
    type: [AvailabilityResponseDto],
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async setMyAvailability(
    @Body() dto: SetAvailabilityDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AvailabilityResponseDto[]> {
    return this.schedulingService.setAvailability(user.id, dto, user);
  }

  // ===========================
  // EXCEPTION ENDPOINTS
  // ===========================
  // These must be declared BEFORE 'availability/:userId' routes

  @Get('availability/exceptions')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Get current user\'s availability exceptions' })
  @ApiQuery({
    name: 'startDate',
    required: false,
    type: String,
    description: 'Filter from this date (ISO 8601)',
    example: '2025-01-01',
  })
  @ApiQuery({
    name: 'endDate',
    required: false,
    type: String,
    description: 'Filter until this date (ISO 8601)',
    example: '2025-12-31',
  })
  @ApiResponse({
    status: 200,
    description: 'Exceptions retrieved successfully',
    type: [ExceptionResponseDto],
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMyExceptions(
    @CurrentUser() user: AuthenticatedUser,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ): Promise<ExceptionResponseDto[]> {
    return this.schedulingService.getExceptions(user.id, startDate, endDate);
  }

  @Get('availability/exceptions/:userId')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({ summary: 'Get specific surveyor\'s availability exceptions' })
  @ApiParam({
    name: 'userId',
    description: 'Surveyor user ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiQuery({
    name: 'startDate',
    required: false,
    type: String,
    description: 'Filter from this date',
    example: '2025-01-01',
  })
  @ApiQuery({
    name: 'endDate',
    required: false,
    type: String,
    description: 'Filter until this date',
    example: '2025-12-31',
  })
  @ApiResponse({
    status: 200,
    description: 'Exceptions retrieved successfully',
    type: [ExceptionResponseDto],
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async getExceptions(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ): Promise<ExceptionResponseDto[]> {
    return this.schedulingService.getExceptions(userId, startDate, endDate);
  }

  @Post('availability/exceptions')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create availability exception for current user' })
  @ApiResponse({
    status: 201,
    description: 'Exception created successfully',
    type: ExceptionResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error or duplicate date' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async createMyException(
    @Body() dto: CreateExceptionDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ExceptionResponseDto> {
    return this.schedulingService.createException(user.id, dto, user);
  }

  @Post('availability/exceptions/:userId')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create availability exception for specific surveyor' })
  @ApiParam({
    name: 'userId',
    description: 'Surveyor user ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 201,
    description: 'Exception created successfully',
    type: ExceptionResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error or duplicate date' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async createException(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() dto: CreateExceptionDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ExceptionResponseDto> {
    return this.schedulingService.createException(userId, dto, user);
  }

  @Put('availability/exceptions/item/:id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Update an availability exception' })
  @ApiParam({
    name: 'id',
    description: 'Exception ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Exception updated successfully',
    type: ExceptionResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Exception not found' })
  async updateException(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateExceptionDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ExceptionResponseDto> {
    return this.schedulingService.updateException(id, dto, user);
  }

  @Delete('availability/exceptions/item/:id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Delete an availability exception' })
  @ApiParam({
    name: 'id',
    description: 'Exception ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Exception deleted successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Exception not found' })
  async deleteException(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ success: boolean }> {
    return this.schedulingService.deleteException(id, user);
  }

  // ===========================
  // AVAILABILITY BY USER ID (parameterized routes - must come AFTER static routes)
  // ===========================

  @Get('availability/:userId')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({ summary: 'Get specific surveyor\'s weekly availability' })
  @ApiParam({
    name: 'userId',
    description: 'Surveyor user ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Weekly availability retrieved successfully',
    type: [AvailabilityResponseDto],
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async getAvailability(
    @Param('userId', ParseUUIDPipe) userId: string,
  ): Promise<AvailabilityResponseDto[]> {
    return this.schedulingService.getAvailability(userId);
  }

  @Put('availability/:userId')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({ summary: 'Set/update specific surveyor\'s weekly availability' })
  @ApiParam({
    name: 'userId',
    description: 'Surveyor user ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Availability updated successfully',
    type: [AvailabilityResponseDto],
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async setAvailability(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Body() dto: SetAvailabilityDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AvailabilityResponseDto[]> {
    return this.schedulingService.setAvailability(userId, dto, user);
  }

  // ===========================
  // SLOTS ENDPOINTS
  // ===========================

  @Get('slots')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR, UserRole.VIEWER)
  @ApiOperation({ summary: 'Get available time slots for a surveyor' })
  @ApiQuery({
    name: 'surveyorId',
    required: true,
    type: String,
    description: 'Surveyor user ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiQuery({
    name: 'startDate',
    required: true,
    type: String,
    description: 'Start date (ISO 8601)',
    example: '2025-01-15',
  })
  @ApiQuery({
    name: 'endDate',
    required: true,
    type: String,
    description: 'End date (ISO 8601)',
    example: '2025-01-21',
  })
  @ApiQuery({
    name: 'slotDuration',
    required: false,
    type: Number,
    description: 'Slot duration in minutes (15-480)',
    example: 60,
  })
  @ApiResponse({
    status: 200,
    description: 'Available slots retrieved successfully',
    type: SlotsResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Surveyor not found' })
  async getSlots(@Query() query: GetSlotsDto): Promise<SlotsResponseDto> {
    return this.schedulingService.getSlots(query);
  }

  // ===========================
  // BOOKING ENDPOINTS
  // ===========================

  @Get('bookings')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR, UserRole.VIEWER)
  @ApiOperation({ summary: 'List bookings with filters and pagination' })
  @ApiQuery({
    name: 'surveyorId',
    required: false,
    type: String,
    description: 'Filter by surveyor ID',
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'],
    description: 'Filter by status',
  })
  @ApiQuery({
    name: 'startDate',
    required: false,
    type: String,
    description: 'Filter from this date',
    example: '2025-01-01',
  })
  @ApiQuery({
    name: 'endDate',
    required: false,
    type: String,
    description: 'Filter until this date',
    example: '2025-01-31',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number (1-based)',
    example: 1,
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page (max 100)',
    example: 20,
  })
  @ApiResponse({
    status: 200,
    description: 'Bookings retrieved successfully',
    type: BookingListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async listBookings(
    @Query() query: ListBookingsDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingListResponseDto> {
    return this.schedulingService.listBookings(query, user);
  }

  @Get('bookings/my')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Get current user\'s bookings as surveyor' })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'],
    description: 'Filter by status',
  })
  @ApiQuery({
    name: 'startDate',
    required: false,
    type: String,
    description: 'Filter from this date',
  })
  @ApiQuery({
    name: 'endDate',
    required: false,
    type: String,
    description: 'Filter until this date',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page',
  })
  @ApiResponse({
    status: 200,
    description: 'My bookings retrieved successfully',
    type: BookingListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMyBookings(
    @Query() query: ListBookingsDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingListResponseDto> {
    return this.schedulingService.getMyBookings(user, query);
  }

  @Get('bookings/:id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR, UserRole.VIEWER)
  @ApiOperation({ summary: 'Get booking details by ID' })
  @ApiParam({
    name: 'id',
    description: 'Booking ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Booking retrieved successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async getBooking(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    return this.schedulingService.getBooking(id, user);
  }

  @Post('bookings')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new booking' })
  @ApiResponse({
    status: 201,
    description: 'Booking created successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error or double-booking' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Surveyor not found' })
  async createBooking(
    @Body() dto: CreateBookingDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    return this.schedulingService.createBooking(dto, user);
  }

  @Put('bookings/:id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Update a booking' })
  @ApiParam({
    name: 'id',
    description: 'Booking ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Booking updated successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error or double-booking' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async updateBooking(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBookingDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    return this.schedulingService.updateBooking(id, dto, user);
  }

  @Patch('bookings/:id/status')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Update booking status' })
  @ApiParam({
    name: 'id',
    description: 'Booking ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Booking status updated successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async updateBookingStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBookingStatusDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    return this.schedulingService.updateBookingStatus(id, dto, user);
  }

  @Delete('bookings/:id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER)
  @ApiOperation({ summary: 'Cancel a booking (sets status to CANCELLED)' })
  @ApiParam({
    name: 'id',
    description: 'Booking ID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Booking cancelled successfully',
    type: BookingResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  async cancelBooking(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    return this.schedulingService.cancelBooking(id, user);
  }
}
