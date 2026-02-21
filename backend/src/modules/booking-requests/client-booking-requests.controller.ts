import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
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
import { SkipThrottle } from '@nestjs/throttler';
import { Request as ExpressRequest } from 'express';
import { BookingRequestsService } from './booking-requests.service';
import { ClientJwtGuard } from '../client-portal/guards/client-jwt.guard';
import { BookingRequestRateLimitGuard } from '../../common/guards/rate-limit.guard';
import {
  CreateBookingRequestDto,
  ClientBookingRequestsQueryDto,
  BookingRequestDto,
  BookingRequestsListResponseDto,
} from './dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Booking Requests')
@Controller('client/booking-requests')
@UseGuards(ClientJwtGuard)
@ApiBearerAuth()
export class ClientBookingRequestsController {
  constructor(
    private readonly bookingRequestsService: BookingRequestsService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @SkipThrottle() // Use custom rate limiter instead of global throttler
  @UseGuards(BookingRequestRateLimitGuard)
  @ApiOperation({
    summary: 'Create a booking request',
    description:
      'Submit a new booking request. Staff will review and approve/reject. ' +
      'Rate limited to 10 requests per 60 minutes per client.',
  })
  @ApiResponse({
    status: 201,
    description: 'Booking request created successfully',
    type: BookingRequestDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 429, description: 'Rate limit exceeded' })
  async createBookingRequest(
    @Request() req: ClientRequest,
    @Body() dto: CreateBookingRequestDto,
  ): Promise<BookingRequestDto> {
    return this.bookingRequestsService.createBookingRequest(req.user.id, dto);
  }

  @Get()
  @ApiOperation({
    summary: 'List my booking requests',
    description: 'Returns all booking requests for the authenticated client.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of booking requests',
    type: BookingRequestsListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMyBookingRequests(
    @Request() req: ClientRequest,
    @Query() query: ClientBookingRequestsQueryDto,
  ): Promise<BookingRequestsListResponseDto> {
    return this.bookingRequestsService.getClientBookingRequests(
      req.user.id,
      query,
    );
  }

  @Get(':id')
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
  @ApiResponse({ status: 404, description: 'Booking request not found' })
  async getBookingRequest(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BookingRequestDto> {
    return this.bookingRequestsService.getClientBookingRequest(req.user.id, id);
  }
}
