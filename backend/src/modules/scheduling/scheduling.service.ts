import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { UserRole, BookingStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  BookingCreatedEvent,
  BookingStatusChangedEvent,
} from '../notifications/events/booking.events';
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
  DaySlotsDto,
  TimeSlotDto,
} from './dto';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@Injectable()
export class SchedulingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  // ===========================
  // AVAILABILITY
  // ===========================

  /**
   * Get weekly availability for a user
   */
  async getAvailability(userId: string): Promise<AvailabilityResponseDto[]> {
    const availability = await this.prisma.surveyorAvailability.findMany({
      where: { userId },
      orderBy: { dayOfWeek: 'asc' },
    });

    return availability.map((a) => ({
      id: a.id,
      userId: a.userId,
      dayOfWeek: a.dayOfWeek,
      startTime: a.startTime,
      endTime: a.endTime,
      isActive: a.isActive,
      createdAt: a.createdAt,
      updatedAt: a.updatedAt,
    }));
  }

  /**
   * Set weekly availability (bulk upsert)
   */
  async setAvailability(
    userId: string,
    dto: SetAvailabilityDto,
    currentUser: AuthenticatedUser,
  ): Promise<AvailabilityResponseDto[]> {
    // RBAC: Surveyors can only update their own availability
    if (currentUser.role === UserRole.SURVEYOR && currentUser.id !== userId) {
      throw new ForbiddenException('You can only update your own availability');
    }

    // Validate time order
    for (const day of dto.availability) {
      if (!this.isTimeOrderValid(day.startTime, day.endTime)) {
        throw new BadRequestException(
          `End time must be after start time for day ${day.dayOfWeek}`,
        );
      }
    }

    // Use transaction for atomic update
    await this.prisma.$transaction(async (tx) => {
      // Delete existing availability for this user
      await tx.surveyorAvailability.deleteMany({ where: { userId } });

      // Create new entries
      for (const day of dto.availability) {
        await tx.surveyorAvailability.create({
          data: {
            userId,
            dayOfWeek: day.dayOfWeek,
            startTime: day.startTime,
            endTime: day.endTime,
            isActive: day.isActive ?? true,
          },
        });
      }
    });

    return this.getAvailability(userId);
  }

  // ===========================
  // EXCEPTIONS
  // ===========================

  /**
   * Get availability exceptions for a user
   */
  async getExceptions(
    userId: string,
    startDate?: string,
    endDate?: string,
  ): Promise<ExceptionResponseDto[]> {
    const where: any = { userId };

    if (startDate || endDate) {
      where.date = {};
      if (startDate) {
        where.date.gte = new Date(startDate);
      }
      if (endDate) {
        where.date.lte = new Date(endDate);
      }
    }

    const exceptions = await this.prisma.availabilityException.findMany({
      where,
      orderBy: { date: 'asc' },
    });

    return exceptions.map((e) => ({
      id: e.id,
      userId: e.userId,
      date: e.date.toISOString().split('T')[0],
      isAvailable: e.isAvailable,
      startTime: e.startTime ?? undefined,
      endTime: e.endTime ?? undefined,
      reason: e.reason ?? undefined,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    }));
  }

  /**
   * Create an availability exception
   */
  async createException(
    userId: string,
    dto: CreateExceptionDto,
    currentUser: AuthenticatedUser,
  ): Promise<ExceptionResponseDto> {
    // RBAC check
    if (currentUser.role === UserRole.SURVEYOR && currentUser.id !== userId) {
      throw new ForbiddenException('You can only create your own exceptions');
    }

    // Validate date is not in the past
    const exceptionDate = new Date(dto.date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (exceptionDate < today) {
      throw new BadRequestException('Cannot create exception for past dates');
    }

    // If available, validate time order
    if (dto.isAvailable && dto.startTime && dto.endTime) {
      if (!this.isTimeOrderValid(dto.startTime, dto.endTime)) {
        throw new BadRequestException('End time must be after start time');
      }
    }

    // Check for existing exception on this date
    const existing = await this.prisma.availabilityException.findUnique({
      where: { userId_date: { userId, date: exceptionDate } },
    });

    if (existing) {
      throw new BadRequestException('Exception already exists for this date');
    }

    const exception = await this.prisma.availabilityException.create({
      data: {
        userId,
        date: exceptionDate,
        isAvailable: dto.isAvailable,
        startTime: dto.startTime,
        endTime: dto.endTime,
        reason: dto.reason,
      },
    });

    return {
      id: exception.id,
      userId: exception.userId,
      date: exception.date.toISOString().split('T')[0],
      isAvailable: exception.isAvailable,
      startTime: exception.startTime ?? undefined,
      endTime: exception.endTime ?? undefined,
      reason: exception.reason ?? undefined,
      createdAt: exception.createdAt,
      updatedAt: exception.updatedAt,
    };
  }

  /**
   * Update an availability exception
   */
  async updateException(
    id: string,
    dto: UpdateExceptionDto,
    currentUser: AuthenticatedUser,
  ): Promise<ExceptionResponseDto> {
    const exception = await this.prisma.availabilityException.findUnique({
      where: { id },
    });

    if (!exception) {
      throw new NotFoundException('Exception not found');
    }

    // RBAC check
    if (
      currentUser.role === UserRole.SURVEYOR &&
      exception.userId !== currentUser.id
    ) {
      throw new ForbiddenException('You can only update your own exceptions');
    }

    // Validate time order if both times are being updated
    const newStartTime = dto.startTime ?? exception.startTime;
    const newEndTime = dto.endTime ?? exception.endTime;
    const newIsAvailable = dto.isAvailable ?? exception.isAvailable;

    if (newIsAvailable && newStartTime && newEndTime) {
      if (!this.isTimeOrderValid(newStartTime, newEndTime)) {
        throw new BadRequestException('End time must be after start time');
      }
    }

    const updated = await this.prisma.availabilityException.update({
      where: { id },
      data: {
        isAvailable: dto.isAvailable,
        startTime: dto.startTime,
        endTime: dto.endTime,
        reason: dto.reason,
      },
    });

    return {
      id: updated.id,
      userId: updated.userId,
      date: updated.date.toISOString().split('T')[0],
      isAvailable: updated.isAvailable,
      startTime: updated.startTime ?? undefined,
      endTime: updated.endTime ?? undefined,
      reason: updated.reason ?? undefined,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
    };
  }

  /**
   * Delete an availability exception
   */
  async deleteException(
    id: string,
    currentUser: AuthenticatedUser,
  ): Promise<{ success: boolean }> {
    const exception = await this.prisma.availabilityException.findUnique({
      where: { id },
    });

    if (!exception) {
      throw new NotFoundException('Exception not found');
    }

    // RBAC check
    if (
      currentUser.role === UserRole.SURVEYOR &&
      exception.userId !== currentUser.id
    ) {
      throw new ForbiddenException('You can only delete your own exceptions');
    }

    await this.prisma.availabilityException.delete({ where: { id } });

    return { success: true };
  }

  // ===========================
  // SLOTS
  // ===========================

  /**
   * Get available slots for a surveyor in a date range
   */
  async getSlots(dto: GetSlotsDto): Promise<SlotsResponseDto> {
    const slotDuration = dto.slotDuration ?? 60;
    const startDate = new Date(dto.startDate);
    const endDate = new Date(dto.endDate);

    // Validate date range
    if (endDate < startDate) {
      throw new BadRequestException('End date must be after start date');
    }

    // Limit range to 31 days
    const daysDiff = Math.ceil(
      (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
    );
    if (daysDiff > 31) {
      throw new BadRequestException('Date range cannot exceed 31 days');
    }

    // Verify surveyor exists
    const surveyor = await this.prisma.user.findUnique({
      where: { id: dto.surveyorId },
    });
    if (!surveyor) {
      throw new NotFoundException('Surveyor not found');
    }

    // Get availability and exceptions
    const availability = await this.prisma.surveyorAvailability.findMany({
      where: { userId: dto.surveyorId, isActive: true },
    });

    const exceptions = await this.prisma.availabilityException.findMany({
      where: {
        userId: dto.surveyorId,
        date: { gte: startDate, lte: endDate },
      },
    });

    // Get existing bookings
    const bookings = await this.prisma.booking.findMany({
      where: {
        surveyorId: dto.surveyorId,
        date: { gte: startDate, lte: endDate },
        status: { not: BookingStatus.CANCELLED },
      },
    });

    // Build exception map for quick lookup
    const exceptionMap = new Map<string, typeof exceptions[0]>();
    for (const exc of exceptions) {
      exceptionMap.set(exc.date.toISOString().split('T')[0], exc);
    }

    // Build booking map by date
    const bookingMap = new Map<string, typeof bookings>();
    for (const booking of bookings) {
      const dateKey = booking.date.toISOString().split('T')[0];
      if (!bookingMap.has(dateKey)) {
        bookingMap.set(dateKey, []);
      }
      bookingMap.get(dateKey)!.push(booking);
    }

    // Generate days
    const days: DaySlotsDto[] = [];
    const currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const dayOfWeek = currentDate.getDay();

      // Check for exception
      const exception = exceptionMap.get(dateStr);

      // Get base availability for this day
      const dayAvailability = availability.find(
        (a) => a.dayOfWeek === dayOfWeek,
      );

      let isWorkingDay = false;
      let workStart: string | null = null;
      let workEnd: string | null = null;
      let exceptionReason: string | undefined;

      if (exception) {
        // Exception overrides base availability
        isWorkingDay = exception.isAvailable;
        workStart = exception.startTime;
        workEnd = exception.endTime;
        exceptionReason = exception.reason ?? undefined;
      } else if (dayAvailability) {
        // Use base availability
        isWorkingDay = true;
        workStart = dayAvailability.startTime;
        workEnd = dayAvailability.endTime;
      }

      // Generate slots for this day
      const slots: TimeSlotDto[] = [];

      if (isWorkingDay && workStart && workEnd) {
        const dayBookings = bookingMap.get(dateStr) ?? [];
        const generatedSlots = this.generateTimeSlots(
          workStart,
          workEnd,
          slotDuration,
        );

        for (const slot of generatedSlots) {
          // Check if slot overlaps with any booking
          const overlappingBooking = dayBookings.find((b) =>
            this.timesOverlap(slot.start, slot.end, b.startTime, b.endTime),
          );

          slots.push({
            date: dateStr,
            startTime: slot.start,
            endTime: slot.end,
            isAvailable: !overlappingBooking,
            bookingId: overlappingBooking?.id,
          });
        }
      }

      days.push({
        date: dateStr,
        dayOfWeek,
        isWorkingDay,
        exceptionReason,
        slots,
      });

      // Move to next day
      currentDate.setDate(currentDate.getDate() + 1);
    }

    return {
      surveyorId: dto.surveyorId,
      startDate: dto.startDate,
      endDate: dto.endDate,
      slotDuration,
      days,
    };
  }

  // ===========================
  // BOOKINGS
  // ===========================

  /**
   * List bookings with filters and pagination
   */
  async listBookings(
    query: ListBookingsDto,
    currentUser: AuthenticatedUser,
  ): Promise<BookingListResponseDto> {
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? 20, 100);
    const skip = (page - 1) * limit;

    const where: any = {};

    // RBAC: Viewers and Surveyors can only see their own bookings
    if (currentUser.role === UserRole.VIEWER) {
      // Viewers can see bookings but with limited access
      // For now, they can view all bookings (read-only enforced at update/delete)
    }

    if (query.surveyorId) {
      where.surveyorId = query.surveyorId;
    }

    if (query.status) {
      where.status = query.status;
    }

    if (query.startDate || query.endDate) {
      where.date = {};
      if (query.startDate) {
        where.date.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        where.date.lte = new Date(query.endDate);
      }
    }

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ date: 'asc' }, { startTime: 'asc' }],
        include: {
          surveyor: {
            select: { id: true, firstName: true, lastName: true, email: true },
          },
        },
      }),
      this.prisma.booking.count({ where }),
    ]);

    return {
      data: bookings.map((b) => this.mapBookingToResponse(b)),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Get bookings for the current user (as surveyor)
   */
  async getMyBookings(
    currentUser: AuthenticatedUser,
    query: ListBookingsDto,
  ): Promise<BookingListResponseDto> {
    return this.listBookings(
      { ...query, surveyorId: currentUser.id },
      currentUser,
    );
  }

  /**
   * Get a single booking by ID
   */
  async getBooking(
    id: string,
    currentUser: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    const booking = await this.prisma.booking.findUnique({
      where: { id },
      include: {
        surveyor: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // RBAC: Surveyors can only view their own assigned bookings
    // ADMIN and MANAGER can view all bookings
    // VIEWER can view all bookings (read-only access)
    if (
      currentUser.role === UserRole.SURVEYOR &&
      booking.surveyorId !== currentUser.id
    ) {
      throw new ForbiddenException(
        'Surveyors can only view bookings assigned to them',
      );
    }

    return this.mapBookingToResponse(booking);
  }

  /**
   * Create a new booking
   */
  async createBooking(
    dto: CreateBookingDto,
    currentUser: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    // Validate surveyor exists
    const surveyor = await this.prisma.user.findUnique({
      where: { id: dto.surveyorId },
    });
    if (!surveyor) {
      throw new NotFoundException('Surveyor not found');
    }

    // Validate time order
    if (!this.isTimeOrderValid(dto.startTime, dto.endTime)) {
      throw new BadRequestException('End time must be after start time');
    }

    // Validate date is not in the past
    const bookingDate = new Date(dto.date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (bookingDate < today) {
      throw new BadRequestException('Cannot create booking for past dates');
    }

    // Check surveyor availability
    const dayOfWeek = bookingDate.getDay();
    const availability = await this.prisma.surveyorAvailability.findUnique({
      where: { userId_dayOfWeek: { userId: dto.surveyorId, dayOfWeek } },
    });

    // Check for exception on this date
    const exception = await this.prisma.availabilityException.findUnique({
      where: { userId_date: { userId: dto.surveyorId, date: bookingDate } },
    });

    let isAvailable = false;
    let workStart: string | null = null;
    let workEnd: string | null = null;

    if (exception) {
      isAvailable = exception.isAvailable;
      workStart = exception.startTime;
      workEnd = exception.endTime;
    } else if (availability && availability.isActive) {
      isAvailable = true;
      workStart = availability.startTime;
      workEnd = availability.endTime;
    }

    if (!isAvailable) {
      throw new BadRequestException('Surveyor is not available on this date');
    }

    // Check if booking time falls within working hours
    // Uses minute-based comparison to avoid string comparison issues
    if (workStart && workEnd) {
      if (!this.isWithinWorkingHours(dto.startTime, dto.endTime, workStart, workEnd)) {
        throw new BadRequestException(
          `Booking must be within working hours (${workStart} - ${workEnd})`,
        );
      }
    }

    // Create booking with race-condition protection
    // Uses SERIALIZABLE transaction + unique constraint as safety net
    let booking;
    try {
      booking = await this.prisma.$transaction(
        async (tx) => {
          // Check for double-booking INSIDE transaction
          const existingBookings = await tx.booking.findMany({
            where: {
              surveyorId: dto.surveyorId,
              date: bookingDate,
              status: { not: BookingStatus.CANCELLED },
            },
          });

          for (const existing of existingBookings) {
            if (
              this.timesOverlap(
                dto.startTime,
                dto.endTime,
                existing.startTime,
                existing.endTime,
              )
            ) {
              throw new BadRequestException(
                `Time slot overlaps with existing booking (${existing.startTime} - ${existing.endTime})`,
              );
            }
          }

          // Create booking INSIDE same transaction
          return tx.booking.create({
            data: {
              surveyorId: dto.surveyorId,
              date: bookingDate,
              startTime: dto.startTime,
              endTime: dto.endTime,
              status: BookingStatus.PENDING,
              clientName: dto.clientName,
              clientPhone: dto.clientPhone,
              clientEmail: dto.clientEmail,
              propertyAddress: dto.propertyAddress,
              notes: dto.notes,
              createdById: currentUser.id,
            },
            include: {
              surveyor: {
                select: { id: true, firstName: true, lastName: true, email: true },
              },
              client: true,
            },
          });
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (error) {
      // Handle unique constraint violation (P2002) - database-level safety net
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'This time slot has just been booked. Please select a different time.',
        );
      }
      // Re-throw other errors (including BadRequestException from overlap check)
      throw error;
    }

    // Emit booking created event for notifications
    const createdByUser = await this.prisma.user.findUnique({
      where: { id: currentUser.id },
    });
    if (createdByUser) {
      this.eventEmitter.emit(
        BookingCreatedEvent.eventName,
        new BookingCreatedEvent(booking as any, createdByUser),
      );
    }

    return this.mapBookingToResponse(booking);
  }

  /**
   * Update a booking
   */
  async updateBooking(
    id: string,
    dto: UpdateBookingDto,
    currentUser: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    const booking = await this.prisma.booking.findUnique({ where: { id } });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // RBAC check - enforce consistent authorization rules
    // Surveyors can ONLY update bookings where they are the assigned surveyor
    // This prevents surveyors from modifying bookings they created for other surveyors
    if (currentUser.role === UserRole.SURVEYOR) {
      if (booking.surveyorId !== currentUser.id) {
        throw new ForbiddenException(
          'Surveyors can only update bookings assigned to them',
        );
      }
    } else if (currentUser.role === UserRole.VIEWER) {
      throw new ForbiddenException('Viewers cannot update bookings');
    }

    // If date or time is being updated, validate
    const newDate = dto.date ? new Date(dto.date) : booking.date;
    const newStartTime = dto.startTime ?? booking.startTime;
    const newEndTime = dto.endTime ?? booking.endTime;

    if (dto.startTime || dto.endTime) {
      if (!this.isTimeOrderValid(newStartTime, newEndTime)) {
        throw new BadRequestException('End time must be after start time');
      }
    }

    // If date or time changed, check for double-booking with transaction protection
    let updated;
    try {
      if (dto.date || dto.startTime || dto.endTime) {
        // Use SERIALIZABLE transaction when time/date changes (race-condition prone)
        updated = await this.prisma.$transaction(
          async (tx) => {
            const existingBookings = await tx.booking.findMany({
              where: {
                surveyorId: booking.surveyorId,
                date: newDate,
                status: { not: BookingStatus.CANCELLED },
                id: { not: id },
              },
            });

            for (const existing of existingBookings) {
              if (
                this.timesOverlap(
                  newStartTime,
                  newEndTime,
                  existing.startTime,
                  existing.endTime,
                )
              ) {
                throw new BadRequestException(
                  `Time slot overlaps with existing booking (${existing.startTime} - ${existing.endTime})`,
                );
              }
            }

            return tx.booking.update({
              where: { id },
              data: {
                date: dto.date ? new Date(dto.date) : undefined,
                startTime: dto.startTime,
                endTime: dto.endTime,
                clientName: dto.clientName,
                clientPhone: dto.clientPhone,
                clientEmail: dto.clientEmail,
                propertyAddress: dto.propertyAddress,
                notes: dto.notes,
              },
              include: {
                surveyor: {
                  select: { id: true, firstName: true, lastName: true, email: true },
                },
              },
            });
          },
          {
            isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
          },
        );
      } else {
        // No time/date change - simple update without transaction overhead
        updated = await this.prisma.booking.update({
          where: { id },
          data: {
            clientName: dto.clientName,
            clientPhone: dto.clientPhone,
            clientEmail: dto.clientEmail,
            propertyAddress: dto.propertyAddress,
            notes: dto.notes,
          },
          include: {
            surveyor: {
              select: { id: true, firstName: true, lastName: true, email: true },
            },
          },
        });
      }
    } catch (error) {
      // Handle unique constraint violation (P2002) - database-level safety net
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'This time slot has just been booked. Please select a different time.',
        );
      }
      throw error;
    }

    return this.mapBookingToResponse(updated);
  }

  /**
   * Valid booking status transitions (state machine)
   * PENDING → CONFIRMED, CANCELLED
   * CONFIRMED → COMPLETED, CANCELLED
   * COMPLETED → (terminal state, no transitions allowed)
   * CANCELLED → (terminal state, no transitions allowed)
   */
  private readonly VALID_BOOKING_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
    [BookingStatus.PENDING]: [BookingStatus.CONFIRMED, BookingStatus.CANCELLED],
    [BookingStatus.CONFIRMED]: [BookingStatus.COMPLETED, BookingStatus.CANCELLED],
    [BookingStatus.COMPLETED]: [], // Terminal state
    [BookingStatus.CANCELLED]: [], // Terminal state
  };

  /**
   * Validate booking status transition
   */
  private validateBookingTransition(
    currentStatus: BookingStatus,
    newStatus: BookingStatus,
  ): void {
    if (currentStatus === newStatus) {
      return; // No-op transition is allowed
    }

    const allowedTransitions = this.VALID_BOOKING_TRANSITIONS[currentStatus];
    if (!allowedTransitions.includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition booking from ${currentStatus} to ${newStatus}. ` +
        `Allowed transitions from ${currentStatus}: ${allowedTransitions.length > 0 ? allowedTransitions.join(', ') : 'none (terminal state)'}`,
      );
    }
  }

  /**
   * Update booking status
   */
  async updateBookingStatus(
    id: string,
    dto: UpdateBookingStatusDto,
    currentUser: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    const booking = await this.prisma.booking.findUnique({ where: { id } });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // RBAC check: Surveyors can only update status of their own assigned bookings
    // ADMIN and MANAGER can update any booking status
    if (currentUser.role === UserRole.SURVEYOR) {
      if (booking.surveyorId !== currentUser.id) {
        throw new ForbiddenException(
          'Surveyors can only update status of bookings assigned to them',
        );
      }
    } else if (currentUser.role === UserRole.VIEWER) {
      throw new ForbiddenException('Viewers cannot update booking status');
    }

    // Validate state transition
    this.validateBookingTransition(booking.status, dto.status);

    const previousStatus = booking.status;
    const updated = await this.prisma.booking.update({
      where: { id },
      data: { status: dto.status },
      include: {
        surveyor: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
        client: true,
      },
    });

    // Emit status change event for notifications
    if (previousStatus !== dto.status) {
      const changedByUser = await this.prisma.user.findUnique({
        where: { id: currentUser.id },
      });
      if (changedByUser) {
        this.eventEmitter.emit(
          BookingStatusChangedEvent.eventName,
          new BookingStatusChangedEvent(
            updated as any,
            previousStatus,
            dto.status,
            changedByUser,
          ),
        );
      }
    }

    return this.mapBookingToResponse(updated);
  }

  /**
   * Cancel a booking (sets status to CANCELLED)
   */
  async cancelBooking(
    id: string,
    currentUser: AuthenticatedUser,
  ): Promise<BookingResponseDto> {
    const booking = await this.prisma.booking.findUnique({ where: { id } });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    // RBAC check
    if (
      currentUser.role !== UserRole.ADMIN &&
      currentUser.role !== UserRole.MANAGER
    ) {
      throw new ForbiddenException('Only admins and managers can cancel bookings');
    }

    // Cannot cancel an already cancelled booking
    if (booking.status === BookingStatus.CANCELLED) {
      throw new BadRequestException('Booking is already cancelled');
    }

    // Validate state transition - only PENDING and CONFIRMED bookings can be cancelled
    this.validateBookingTransition(booking.status, BookingStatus.CANCELLED);

    const previousStatus = booking.status;
    const updated = await this.prisma.booking.update({
      where: { id },
      data: { status: BookingStatus.CANCELLED },
      include: {
        surveyor: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
        client: true,
      },
    });

    // Emit cancellation event for notifications
    const cancelledByUser = await this.prisma.user.findUnique({
      where: { id: currentUser.id },
    });
    if (cancelledByUser) {
      this.eventEmitter.emit(
        BookingStatusChangedEvent.eventName,
        new BookingStatusChangedEvent(
          updated as any,
          previousStatus,
          BookingStatus.CANCELLED,
          cancelledByUser,
        ),
      );
    }

    return this.mapBookingToResponse(updated);
  }

  // ===========================
  // HELPER METHODS
  // ===========================

  /**
   * Convert HH:MM time string to minutes since midnight.
   * Normalizes time format for consistent comparisons.
   */
  private timeToMinutes(time: string): number {
    const parts = time.split(':').map(Number);
    const hours = parts[0] || 0;
    const minutes = parts[1] || 0;
    return hours * 60 + minutes;
  }

  /**
   * Check if end time is after start time
   */
  private isTimeOrderValid(startTime: string, endTime: string): boolean {
    const startMinutes = this.timeToMinutes(startTime);
    const endMinutes = this.timeToMinutes(endTime);
    return endMinutes > startMinutes;
  }

  /**
   * Check if a time range falls within working hours.
   * Uses minute-based comparison for reliability.
   */
  private isWithinWorkingHours(
    bookingStart: string,
    bookingEnd: string,
    workStart: string,
    workEnd: string,
  ): boolean {
    const bookingStartMin = this.timeToMinutes(bookingStart);
    const bookingEndMin = this.timeToMinutes(bookingEnd);
    const workStartMin = this.timeToMinutes(workStart);
    const workEndMin = this.timeToMinutes(workEnd);

    return bookingStartMin >= workStartMin && bookingEndMin <= workEndMin;
  }

  /**
   * Check if two time ranges overlap.
   * Uses minute-based comparison for reliability.
   */
  private timesOverlap(
    start1: string,
    end1: string,
    start2: string,
    end2: string,
  ): boolean {
    const start1Min = this.timeToMinutes(start1);
    const end1Min = this.timeToMinutes(end1);
    const start2Min = this.timeToMinutes(start2);
    const end2Min = this.timeToMinutes(end2);

    // Overlap: (start1 < end2) AND (end1 > start2)
    return start1Min < end2Min && end1Min > start2Min;
  }

  /**
   * Generate time slots within a time range
   */
  private generateTimeSlots(
    startTime: string,
    endTime: string,
    durationMinutes: number,
  ): { start: string; end: string }[] {
    const slots: { start: string; end: string }[] = [];

    const [startHour, startMin] = startTime.split(':').map(Number);
    const [endHour, endMin] = endTime.split(':').map(Number);

    let currentMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;

    while (currentMinutes + durationMinutes <= endMinutes) {
      const slotStart = this.minutesToTime(currentMinutes);
      const slotEnd = this.minutesToTime(currentMinutes + durationMinutes);

      slots.push({ start: slotStart, end: slotEnd });

      currentMinutes += durationMinutes;
    }

    return slots;
  }

  /**
   * Convert minutes since midnight to HH:MM string
   */
  private minutesToTime(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
  }

  /**
   * Map booking entity to response DTO
   */
  private mapBookingToResponse(booking: any): BookingResponseDto {
    return {
      id: booking.id,
      surveyorId: booking.surveyorId,
      date: booking.date.toISOString().split('T')[0],
      startTime: booking.startTime,
      endTime: booking.endTime,
      status: booking.status,
      clientName: booking.clientName ?? undefined,
      clientPhone: booking.clientPhone ?? undefined,
      clientEmail: booking.clientEmail ?? undefined,
      propertyAddress: booking.propertyAddress ?? undefined,
      notes: booking.notes ?? undefined,
      createdById: booking.createdById,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
      surveyor: booking.surveyor
        ? {
            id: booking.surveyor.id,
            firstName: booking.surveyor.firstName ?? '',
            lastName: booking.surveyor.lastName ?? '',
            email: booking.surveyor.email,
          }
        : undefined,
    };
  }
}
