import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { BookingStatus, UserRole } from '@prisma/client';
import { SchedulingService } from './scheduling.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventEmitter2 } from '@nestjs/event-emitter';

/**
 * Booking State Transition Tests
 * Validates that booking status transitions follow the defined state machine:
 * - PENDING → CONFIRMED, CANCELLED
 * - CONFIRMED → COMPLETED, CANCELLED
 * - COMPLETED → (terminal)
 * - CANCELLED → (terminal)
 */
describe('SchedulingService - Booking State Transitions', () => {
  let service: SchedulingService;
  let mockPrismaService: {
    booking: {
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    user: {
      findUnique: jest.Mock;
    };
  };

  const mockAdminUser = {
    id: 'admin-123',
    email: 'admin@example.com',
    role: UserRole.ADMIN,
  };

  const mockManagerUser = {
    id: 'manager-123',
    email: 'manager@example.com',
    role: UserRole.MANAGER,
  };

  const createMockBooking = (status: BookingStatus, id = 'booking-123') => ({
    id,
    surveyorId: 'surveyor-123',
    date: new Date(),
    startTime: '09:00',
    endTime: '10:00',
    status,
    clientName: 'Test Client',
    clientPhone: null,
    clientEmail: null,
    propertyAddress: null,
    notes: null,
    createdById: 'admin-123',
    createdAt: new Date(),
    updatedAt: new Date(),
    surveyor: { id: 'surveyor-123', firstName: 'John', lastName: 'Doe', email: 'john@example.com' },
  });

  beforeEach(async () => {
    mockPrismaService = {
      booking: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      user: {
        findUnique: jest.fn(),
      },
    };

    const mockEventEmitter = {
      emit: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SchedulingService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<SchedulingService>(SchedulingService);
  });

  describe('updateBookingStatus - Valid Transitions', () => {
    it('should allow PENDING → CONFIRMED', async () => {
      const booking = createMockBooking(BookingStatus.PENDING);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);
      mockPrismaService.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.CONFIRMED });

      const result = await service.updateBookingStatus(
        booking.id,
        { status: BookingStatus.CONFIRMED },
        mockAdminUser,
      );

      expect(result.status).toBe(BookingStatus.CONFIRMED);
    });

    it('should allow PENDING → CANCELLED', async () => {
      const booking = createMockBooking(BookingStatus.PENDING);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);
      mockPrismaService.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.CANCELLED });

      const result = await service.updateBookingStatus(
        booking.id,
        { status: BookingStatus.CANCELLED },
        mockAdminUser,
      );

      expect(result.status).toBe(BookingStatus.CANCELLED);
    });

    it('should allow CONFIRMED → COMPLETED', async () => {
      const booking = createMockBooking(BookingStatus.CONFIRMED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);
      mockPrismaService.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.COMPLETED });

      const result = await service.updateBookingStatus(
        booking.id,
        { status: BookingStatus.COMPLETED },
        mockAdminUser,
      );

      expect(result.status).toBe(BookingStatus.COMPLETED);
    });

    it('should allow CONFIRMED → CANCELLED', async () => {
      const booking = createMockBooking(BookingStatus.CONFIRMED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);
      mockPrismaService.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.CANCELLED });

      const result = await service.updateBookingStatus(
        booking.id,
        { status: BookingStatus.CANCELLED },
        mockAdminUser,
      );

      expect(result.status).toBe(BookingStatus.CANCELLED);
    });
  });

  describe('updateBookingStatus - Invalid Transitions', () => {
    it('should reject COMPLETED → CANCELLED (terminal state)', async () => {
      const booking = createMockBooking(BookingStatus.COMPLETED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.updateBookingStatus(
          booking.id,
          { status: BookingStatus.CANCELLED },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject COMPLETED → PENDING (terminal state)', async () => {
      const booking = createMockBooking(BookingStatus.COMPLETED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.updateBookingStatus(
          booking.id,
          { status: BookingStatus.PENDING },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject CANCELLED → PENDING (terminal state)', async () => {
      const booking = createMockBooking(BookingStatus.CANCELLED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.updateBookingStatus(
          booking.id,
          { status: BookingStatus.PENDING },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject CANCELLED → COMPLETED (terminal state)', async () => {
      const booking = createMockBooking(BookingStatus.CANCELLED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.updateBookingStatus(
          booking.id,
          { status: BookingStatus.COMPLETED },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject PENDING → COMPLETED (must go through CONFIRMED)', async () => {
      const booking = createMockBooking(BookingStatus.PENDING);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.updateBookingStatus(
          booking.id,
          { status: BookingStatus.COMPLETED },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('cancelBooking - State Validation', () => {
    it('should allow cancelling PENDING booking', async () => {
      const booking = createMockBooking(BookingStatus.PENDING);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);
      mockPrismaService.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.CANCELLED });
      mockPrismaService.user.findUnique.mockResolvedValue({ id: mockManagerUser.id } as any);

      const result = await service.cancelBooking(booking.id, mockManagerUser);

      expect(result.status).toBe(BookingStatus.CANCELLED);
    });

    it('should allow cancelling CONFIRMED booking', async () => {
      const booking = createMockBooking(BookingStatus.CONFIRMED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);
      mockPrismaService.booking.update.mockResolvedValue({ ...booking, status: BookingStatus.CANCELLED });
      mockPrismaService.user.findUnique.mockResolvedValue({ id: mockManagerUser.id } as any);

      const result = await service.cancelBooking(booking.id, mockManagerUser);

      expect(result.status).toBe(BookingStatus.CANCELLED);
    });

    it('should reject cancelling COMPLETED booking', async () => {
      const booking = createMockBooking(BookingStatus.COMPLETED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.cancelBooking(booking.id, mockManagerUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject cancelling already CANCELLED booking', async () => {
      const booking = createMockBooking(BookingStatus.CANCELLED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      await expect(
        service.cancelBooking(booking.id, mockManagerUser),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('Error Messages', () => {
    it('should provide clear error message for invalid transition', async () => {
      const booking = createMockBooking(BookingStatus.COMPLETED);
      mockPrismaService.booking.findUnique.mockResolvedValue(booking);

      try {
        await service.updateBookingStatus(
          booking.id,
          { status: BookingStatus.PENDING },
          mockAdminUser,
        );
        fail('Expected BadRequestException');
      } catch (error) {
        expect(error).toBeInstanceOf(BadRequestException);
        expect(error.message).toContain('Cannot transition booking from COMPLETED to PENDING');
        expect(error.message).toContain('none (terminal state)');
      }
    });
  });
});
