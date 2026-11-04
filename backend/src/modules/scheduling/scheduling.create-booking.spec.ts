import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { BookingStatus, UserRole } from '@prisma/client';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SchedulingService } from './scheduling.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Client review (1 Nov 2026): a surveyor who never configured working hours
 * could not create any booking ("Surveyor is not available on this date").
 * Bookings are created by the surveyors themselves, so "no schedule" means
 * available; only an explicit schedule/exception can block.
 */
describe('SchedulingService.createBooking - availability', () => {
  let service: SchedulingService;
  const surveyorId = '550e8400-e29b-41d4-a716-446655440000';
  const currentUser = { id: surveyorId, email: 's@x.com', role: UserRole.SURVEYOR } as any;

  const tomorrow = () => {
    const d = new Date();
    d.setDate(d.getDate() + 1);
    return d.toISOString().slice(0, 10);
  };

  const prisma = {
    user: { findUnique: jest.fn() },
    surveyorAvailability: { findUnique: jest.fn() },
    availabilityException: { findUnique: jest.fn() },
    booking: { findMany: jest.fn(), create: jest.fn() },
    survey: { create: jest.fn(async () => ({ id: 's1' })) },
    $transaction: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.user.findUnique.mockResolvedValue({ id: surveyorId });
    prisma.booking.findMany.mockResolvedValue([]);
    prisma.booking.create.mockImplementation(async ({ data }: any) => ({
      id: 'b1',
      ...data,
      status: BookingStatus.PENDING,
      surveyor: { id: surveyorId, firstName: 'S', lastName: 'V', email: 's@x.com' },
      client: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    }));
    prisma.$transaction.mockImplementation(async (fn: any) => fn(prisma));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SchedulingService,
        { provide: PrismaService, useValue: prisma },
        { provide: EventEmitter2, useValue: { emit: jest.fn() } },
      ],
    }).compile();
    service = module.get(SchedulingService);
  });

  const dto = () => ({
    surveyorId,
    date: tomorrow(),
    startTime: '09:00',
    endTime: '10:00',
    clientName: 'George Adam',
  });

  it('creates the booking when the surveyor has no availability configured', async () => {
    prisma.surveyorAvailability.findUnique.mockResolvedValue(null);
    prisma.availabilityException.findUnique.mockResolvedValue(null);

    const result = await service.createBooking(dto() as any, currentUser);

    expect(result).toBeDefined();
    expect(prisma.booking.create).toHaveBeenCalledTimes(1);
  });

  it('still blocks an explicit "not available" exception', async () => {
    prisma.surveyorAvailability.findUnique.mockResolvedValue(null);
    prisma.availabilityException.findUnique.mockResolvedValue({
      isAvailable: false,
      startTime: null,
      endTime: null,
    });

    await expect(service.createBooking(dto() as any, currentUser)).rejects.toThrow(
      BadRequestException,
    );
    expect(prisma.booking.create).not.toHaveBeenCalled();
  });

  it('still blocks an inactive weekday schedule', async () => {
    prisma.surveyorAvailability.findUnique.mockResolvedValue({
      isActive: false,
      startTime: '09:00',
      endTime: '17:00',
    });
    prisma.availabilityException.findUnique.mockResolvedValue(null);

    await expect(service.createBooking(dto() as any, currentUser)).rejects.toThrow(
      'Surveyor is not available on this date',
    );
  });

  it('still enforces working hours when a schedule exists', async () => {
    prisma.surveyorAvailability.findUnique.mockResolvedValue({
      isActive: true,
      startTime: '12:00',
      endTime: '17:00',
    });
    prisma.availabilityException.findUnique.mockResolvedValue(null);

    await expect(service.createBooking(dto() as any, currentUser)).rejects.toThrow(
      /working hours/,
    );
  });
});
