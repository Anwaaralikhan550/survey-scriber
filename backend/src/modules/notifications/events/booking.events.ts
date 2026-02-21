import { BookingStatus, User, Client, Booking } from '@prisma/client';

/**
 * Extended booking type with related entities for notifications
 */
export interface BookingWithRelations extends Booking {
  surveyor: {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
  };
  client?: Client | null;
}

/**
 * Event emitted when a new booking is created
 */
export class BookingCreatedEvent {
  static readonly eventName = 'booking.created';

  constructor(
    public readonly booking: BookingWithRelations,
    public readonly createdBy: User,
  ) {}
}

/**
 * Event emitted when a booking status changes
 */
export class BookingStatusChangedEvent {
  static readonly eventName = 'booking.status.changed';

  constructor(
    public readonly booking: BookingWithRelations,
    public readonly previousStatus: BookingStatus,
    public readonly newStatus: BookingStatus,
    public readonly changedBy: User,
  ) {}
}

/**
 * All booking event names for easy reference
 */
export const BookingEvents = {
  CREATED: BookingCreatedEvent.eventName,
  STATUS_CHANGED: BookingStatusChangedEvent.eventName,
} as const;
