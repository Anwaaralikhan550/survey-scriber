import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { BookingStatus, SurveyStatus, SurveyType, UserRole } from '@prisma/client';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SchedulingService } from './scheduling.service';
import { surveyFieldsFromBooking } from './booking-survey';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Client edit (4 Nov 2026): every booking has an inspection the surveyor can open,
 * and a booking stays editable at every status.
 */
describe('Booking and its inspection', () => {
  let service: SchedulingService;
  const surveyorId = '550e8400-e29b-41d4-a716-446655440000';
  const currentUser = { id: surveyorId, email: 's@x.com', role: UserRole.SURVEYOR } as any;
  const bookingDate = new Date('2099-03-10T00:00:00.000Z');

  const prisma = {
    user: { findUnique: jest.fn() },
    surveyorAvailability: { findUnique: jest.fn() },
    availabilityException: { findUnique: jest.fn() },
    booking: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      findUniqueOrThrow: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    survey: {
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      findUnique: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const stored = (over: Record<string, unknown> = {}) => ({
    id: 'b1',
    surveyId: 's1',
    surveyorId,
    date: bookingDate,
    startTime: '09:00',
    endTime: '10:00',
    status: BookingStatus.CONFIRMED,
    surveyType: 'home_survey',
    jobRef: 'REF-1',
    clientName: 'George Adam',
    postcode: 'SW1A 1AA',
    propertyAddress: '1 High St',
    createdById: surveyorId,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...over,
  });

  const draftSurvey = (over: Record<string, unknown> = {}) => ({
    id: 's1',
    status: SurveyStatus.DRAFT,
    deletedAt: null,
    sections: [],
    ...over,
  });

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.user.findUnique.mockResolvedValue({ id: surveyorId });
    prisma.surveyorAvailability.findUnique.mockResolvedValue(null);
    prisma.availabilityException.findUnique.mockResolvedValue(null);
    prisma.booking.findMany.mockResolvedValue([]);
    prisma.survey.create.mockResolvedValue({ id: 's1' });
    prisma.booking.create.mockImplementation(async ({ data }: any) => ({
      ...stored(),
      ...data,
    }));
    prisma.booking.update.mockImplementation(async ({ data }: any) => ({
      ...stored(),
      ...Object.fromEntries(Object.entries(data).filter(([, v]) => v !== undefined)),
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

  describe('creating a booking', () => {
    const dto = (over: Record<string, unknown> = {}) => ({
      surveyorId,
      date: '2099-03-10',
      startTime: '09:00',
      endTime: '10:00',
      jobRef: 'REF-1',
      clientName: 'George Adam',
      propertyAddress: '1 High St',
      ...over,
    });

    it('creates the inspection for the surveyor and links it', async () => {
      const result = await service.createBooking(dto() as any, currentUser);

      expect(prisma.survey.create).toHaveBeenCalledWith({
        data: {
          title: 'Inspection - REF-1',
          propertyAddress: '1 High St',
          type: SurveyType.INSPECTION,
          jobRef: 'REF-1',
          clientName: 'George Adam',
          inspectionDate: new Date('2099-03-10'),
          status: SurveyStatus.DRAFT,
          userId: surveyorId,
        },
      });
      expect(prisma.booking.create.mock.calls[0][0].data.surveyId).toBe('s1');
      expect(result.surveyId).toBe('s1');
    });

    it('a valuation booking creates a valuation', async () => {
      await service.createBooking(dto({ surveyType: 'valuation' }) as any, currentUser);
      const { data } = prisma.survey.create.mock.calls[0][0];
      expect(data.type).toBe(SurveyType.VALUATION);
      expect(data.title).toBe('Valuation - REF-1');
    });

    it('a booking refused for its slot creates no inspection', async () => {
      prisma.booking.findMany.mockResolvedValue([{ startTime: '09:30', endTime: '10:30' }]);
      await expect(service.createBooking(dto() as any, currentUser)).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.survey.create).not.toHaveBeenCalled();
    });
  });

  describe('inspection title', () => {
    const fields = (over: Record<string, unknown>) =>
      surveyFieldsFromBooking({
        surveyType: 'home_survey',
        jobRef: null,
        clientName: null,
        postcode: null,
        propertyAddress: null,
        date: bookingDate,
        ...over,
      } as any);

    it('falls back from job ref to client, postcode and date', () => {
      expect(fields({ jobRef: 'R1', clientName: 'A' }).title).toBe('Inspection - R1');
      expect(fields({ jobRef: '  ', clientName: 'A' }).title).toBe('Inspection - A');
      expect(fields({ postcode: 'SW1A 1AA' }).title).toBe('Inspection - SW1A 1AA');
      expect(fields({}).title).toBe('Inspection - 10 Mar 2099');
    });

    it('a booking with no address still makes a valid inspection', () => {
      expect(fields({}).propertyAddress).toBe('');
    });
  });

  describe('editing a booking', () => {
    it.each([
      BookingStatus.PENDING,
      BookingStatus.CONFIRMED,
      BookingStatus.COMPLETED,
      BookingStatus.CANCELLED,
    ])('works when the booking is %s', async (status) => {
      prisma.booking.findUnique.mockResolvedValue(stored({ status }));
      prisma.survey.findUnique.mockResolvedValue(draftSurvey());
      const result = await service.updateBooking('b1', { clientName: 'New' } as any, currentUser);
      expect(result.clientName).toBe('New');
    });

    it('saves every field of the form and can clear one', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(draftSurvey());
      await service.updateBooking(
        'b1',
        {
          jobRef: 'REF-2',
          propertyType: 'Flat',
          yearBuilt: '1990',
          addressLine: '2 Low St',
          city: 'Leeds',
          town: 'Roundhay',
          postcode: 'LS8 1AA',
          county: 'West Yorkshire',
          accessType: 'collect_keys',
          estateAgentName: 'Agent',
          estateAgentPhone: '0113',
          estateAgentAddress: 'A\nB',
          estateAgentNotes: 'Keys at desk',
          clientEmail: null,
        } as any,
        currentUser,
      );
      expect(prisma.booking.update.mock.calls[0][0].data).toMatchObject({
        jobRef: 'REF-2',
        propertyType: 'Flat',
        yearBuilt: '1990',
        addressLine: '2 Low St',
        city: 'Leeds',
        town: 'Roundhay',
        postcode: 'LS8 1AA',
        county: 'West Yorkshire',
        accessType: 'collect_keys',
        estateAgentName: 'Agent',
        estateAgentPhone: '0113',
        estateAgentAddress: 'A\nB',
        estateAgentNotes: 'Keys at desk',
        clientEmail: null,
      });
    });

    it('the inspection shows the new details and date', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(draftSurvey());
      await service.updateBooking(
        'b1',
        {
          date: '2099-04-01',
          jobRef: 'REF-2',
          clientName: 'New Client',
          propertyAddress: '2 Low St',
        } as any,
        currentUser,
      );
      expect(prisma.survey.update).toHaveBeenCalledWith({
        where: { id: 's1' },
        data: {
          title: 'Inspection - REF-2',
          propertyAddress: '2 Low St',
          type: SurveyType.INSPECTION,
          jobRef: 'REF-2',
          clientName: 'New Client',
          inspectionDate: new Date('2099-04-01'),
        },
      });
    });

    it('a deleted inspection is left alone', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(draftSurvey({ deletedAt: new Date() }));
      await service.updateBooking('b1', { clientName: 'New' } as any, currentUser);
      expect(prisma.survey.update).not.toHaveBeenCalled();
    });

    it('survey type cannot change once the inspection has started', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(
        draftSurvey({ status: SurveyStatus.IN_PROGRESS }),
      );
      await expect(
        service.updateBooking('b1', { surveyType: 'valuation' } as any, currentUser),
      ).rejects.toThrow('The survey type cannot change once the inspection has started');
      expect(prisma.booking.update).not.toHaveBeenCalled();
    });

    it('survey type can change before the inspection starts', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(draftSurvey());
      await service.updateBooking('b1', { surveyType: 'valuation' } as any, currentUser);
      expect(prisma.survey.update.mock.calls[0][0].data.type).toBe(SurveyType.VALUATION);
    });

    it('saving without moving the slot skips the overlap check', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(draftSurvey());
      await service.updateBooking(
        'b1',
        { date: '2099-03-10', startTime: '09:00', endTime: '10:00', notes: 'x' } as any,
        currentUser,
      );
      expect(prisma.booking.findMany).not.toHaveBeenCalled();
    });

    it('moving onto another booking is refused', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      prisma.survey.findUnique.mockResolvedValue(draftSurvey());
      prisma.booking.findMany.mockResolvedValue([{ startTime: '11:00', endTime: '12:00' }]);
      await expect(
        service.updateBooking('b1', { startTime: '11:30', endTime: '12:30' } as any, currentUser),
      ).rejects.toThrow('Time slot overlaps');
    });
  });

  describe('cancelling a booking', () => {
    it('retires only an inspection nobody has started', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored());
      await service.updateBookingStatus('b1', { status: BookingStatus.CANCELLED } as any, currentUser);
      expect(prisma.survey.updateMany).toHaveBeenCalledWith({
        where: {
          id: 's1',
          status: SurveyStatus.DRAFT,
          deletedAt: null,
          sections: { none: { answers: { some: {} } } },
        },
        data: { deletedAt: expect.any(Date) },
      });
    });

    it('confirming a booking leaves the inspection alone', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored({ status: BookingStatus.PENDING }));
      await service.updateBookingStatus('b1', { status: BookingStatus.CONFIRMED } as any, currentUser);
      expect(prisma.survey.updateMany).not.toHaveBeenCalled();
    });
  });

  describe('starting an inspection from a booking', () => {
    it('creates one when the booking has none', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored({ surveyId: null }));
      prisma.booking.findUniqueOrThrow.mockResolvedValue(stored({ surveyId: null }));
      const result = await service.ensureBookingSurvey('b1', currentUser);
      expect(prisma.survey.create).toHaveBeenCalledTimes(1);
      expect(result.surveyId).toBe('s1');
    });

    it('returns the existing one otherwise', async () => {
      prisma.booking.findUnique.mockResolvedValue(stored({ surveyId: 's9' }));
      prisma.booking.findUniqueOrThrow.mockResolvedValue(stored({ surveyId: 's9' }));
      const result = await service.ensureBookingSurvey('b1', currentUser);
      expect(prisma.survey.create).not.toHaveBeenCalled();
      expect(result.surveyId).toBe('s9');
    });

    it('a cancelled booking cannot start one', async () => {
      prisma.booking.findUnique.mockResolvedValue(
        stored({ surveyId: null, status: BookingStatus.CANCELLED }),
      );
      await expect(service.ensureBookingSurvey('b1', currentUser)).rejects.toThrow(
        'This booking has been cancelled',
      );
    });

    it("another surveyor's booking is refused", async () => {
      prisma.booking.findUnique.mockResolvedValue(stored({ surveyorId: 'someone-else' }));
      await expect(service.ensureBookingSurvey('b1', currentUser)).rejects.toThrow(
        'Surveyors can only start inspections for their own bookings',
      );
    });
  });
});
