import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { BookingStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  ClientBookingsQueryDto,
  ClientBookingsResponseDto,
  ClientBookingDto,
} from './dto/client-bookings.dto';

@Injectable()
export class ClientBookingsService {
  private readonly logger = new Logger(ClientBookingsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get all bookings for a client.
   * SECURITY: Always filters by clientId to prevent data leakage.
   */
  async getClientBookings(
    clientId: string,
    query: ClientBookingsQueryDto,
  ): Promise<ClientBookingsResponseDto> {
    const { status, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where = {
      clientId,
      ...(status && { status }),
    };

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          surveyor: {
            select: {
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
        },
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.booking.count({ where }),
    ]);

    const data: ClientBookingDto[] = bookings.map((booking) => ({
      id: booking.id,
      date: booking.date.toISOString().split('T')[0],
      startTime: booking.startTime,
      endTime: booking.endTime,
      status: booking.status,
      propertyAddress: booking.propertyAddress ?? undefined,
      notes: booking.notes ?? undefined,
      surveyor: {
        firstName: booking.surveyor.firstName ?? '',
        lastName: booking.surveyor.lastName ?? '',
        // Only show phone for confirmed/completed bookings
        phone: (booking.status === BookingStatus.CONFIRMED || booking.status === BookingStatus.COMPLETED)
          ? booking.surveyor.phone ?? undefined
          : undefined,
      },
      createdAt: booking.createdAt,
    }));

    return {
      data,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a single booking by ID.
   * SECURITY: Validates booking belongs to client.
   */
  async getClientBooking(
    clientId: string,
    bookingId: string,
  ): Promise<ClientBookingDto> {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: bookingId,
        clientId, // SECURITY: Ensure booking belongs to this client
      },
      include: {
        surveyor: {
          select: {
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    return {
      id: booking.id,
      date: booking.date.toISOString().split('T')[0],
      startTime: booking.startTime,
      endTime: booking.endTime,
      status: booking.status,
      propertyAddress: booking.propertyAddress ?? undefined,
      notes: booking.notes ?? undefined,
      surveyor: {
        firstName: booking.surveyor.firstName ?? '',
        lastName: booking.surveyor.lastName ?? '',
        phone: (booking.status === BookingStatus.CONFIRMED || booking.status === BookingStatus.COMPLETED)
          ? booking.surveyor.phone ?? undefined
          : undefined,
      },
      createdAt: booking.createdAt,
    };
  }
}
