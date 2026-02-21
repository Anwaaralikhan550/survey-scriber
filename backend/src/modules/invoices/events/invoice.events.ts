import { Invoice, InvoiceItem, User, Client, Booking } from '@prisma/client';

/**
 * Extended invoice type with related entities for notifications
 */
export interface InvoiceWithRelations extends Invoice {
  client: Client;
  items: InvoiceItem[];
  createdBy: {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
  };
  booking?: {
    id: string;
    date: Date;
    propertyAddress: string | null;
  } | null;
}

/**
 * Event emitted when an invoice is issued
 */
export class InvoiceIssuedEvent {
  static readonly eventName = 'invoice.issued';

  constructor(
    public readonly invoice: InvoiceWithRelations,
    public readonly issuedBy: User,
  ) {}
}

/**
 * Event emitted when an invoice is marked as paid
 */
export class InvoicePaidEvent {
  static readonly eventName = 'invoice.paid';

  constructor(
    public readonly invoice: InvoiceWithRelations,
    public readonly markedPaidBy: User,
  ) {}
}

/**
 * All invoice event names for easy reference
 */
export const InvoiceEvents = {
  ISSUED: InvoiceIssuedEvent.eventName,
  PAID: InvoicePaidEvent.eventName,
} as const;
