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
import { BookingChangeRequestsService } from './booking-change-requests.service';
import { ClientJwtGuard } from '../client-portal/guards/client-jwt.guard';
import { ChangeRequestRateLimitGuard } from '../../common/guards/rate-limit.guard';
import {
  CreateBookingChangeRequestDto,
  ClientBookingChangeRequestsQueryDto,
  BookingChangeRequestDto,
  BookingChangeRequestsListResponseDto,
} from './dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Booking Change Requests')
@Controller('client/booking-changes')
@UseGuards(ClientJwtGuard)
@ApiBearerAuth()
export class ClientBookingChangeRequestsController {
  constructor(
    private readonly changeRequestsService: BookingChangeRequestsService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @SkipThrottle() // Use custom rate limiter instead of global throttler
  @UseGuards(ChangeRequestRateLimitGuard)
  @ApiOperation({
    summary: 'Create a booking change request',
    description:
      'Submit a request to reschedule or cancel an existing booking. Staff will review and approve/reject. ' +
      'Rate limited to 5 requests per 60 minutes per client.',
  })
  @ApiResponse({
    status: 201,
    description: 'Change request created successfully',
    type: BookingChangeRequestDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error or invalid request' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Booking not found' })
  @ApiResponse({ status: 429, description: 'Rate limit exceeded' })
  async createChangeRequest(
    @Request() req: ClientRequest,
    @Body() dto: CreateBookingChangeRequestDto,
  ): Promise<BookingChangeRequestDto> {
    return this.changeRequestsService.createChangeRequest(req.user.id, dto);
  }

  @Get()
  @ApiOperation({
    summary: 'List my change requests',
    description: 'Returns all booking change requests for the authenticated client.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of change requests',
    type: BookingChangeRequestsListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getMyChangeRequests(
    @Request() req: ClientRequest,
    @Query() query: ClientBookingChangeRequestsQueryDto,
  ): Promise<BookingChangeRequestsListResponseDto> {
    return this.changeRequestsService.getClientChangeRequests(
      req.user.id,
      query,
    );
  }

  @Get(':id')
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
  @ApiResponse({ status: 404, description: 'Change request not found' })
  async getChangeRequest(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<BookingChangeRequestDto> {
    return this.changeRequestsService.getClientChangeRequest(req.user.id, id);
  }
}
