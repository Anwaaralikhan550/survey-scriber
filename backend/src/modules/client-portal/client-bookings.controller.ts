import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { Request as ExpressRequest } from 'express';
import { ClientBookingsService } from './client-bookings.service';
import { ClientJwtGuard } from './guards/client-jwt.guard';
import {
  ClientBookingsQueryDto,
  ClientBookingsResponseDto,
  ClientBookingDto,
} from './dto/client-bookings.dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Bookings')
@Controller('client/bookings')
@UseGuards(ClientJwtGuard)
@ApiBearerAuth()
export class ClientBookingsController {
  constructor(private readonly clientBookingsService: ClientBookingsService) {}

  @Get()
  @ApiOperation({
    summary: 'List client bookings',
    description: 'Returns all bookings for the authenticated client.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of client bookings',
    type: ClientBookingsResponseDto,
  })
  async getBookings(
    @Request() req: ClientRequest,
    @Query() query: ClientBookingsQueryDto,
  ): Promise<ClientBookingsResponseDto> {
    return this.clientBookingsService.getClientBookings(req.user.id, query);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get booking details',
    description: 'Returns details of a specific booking.',
  })
  @ApiParam({
    name: 'id',
    description: 'Booking ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Booking details',
    type: ClientBookingDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Booking not found',
  })
  async getBooking(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ClientBookingDto> {
    return this.clientBookingsService.getClientBooking(req.user.id, id);
  }
}
