import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationType, RecipientType } from '@prisma/client';
import { NotificationsService } from '../notifications.service';
import { NotificationEmailService } from '../notification-email.service';
import {
  InvoiceIssuedEvent,
  InvoicePaidEvent,
  InvoiceEvents,
} from '../../invoices/events/invoice.events';

@Injectable()
export class InvoiceEventHandler {
  private readonly logger = new Logger(InvoiceEventHandler.name);

  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly emailService: NotificationEmailService,
  ) {}

  /**
   * Handle invoice issued event
   * - Create in-app notification for client
   * - Send email notification to client
   */
  @OnEvent(InvoiceEvents.ISSUED)
  async handleInvoiceIssued(event: InvoiceIssuedEvent): Promise<void> {
    this.logger.log(
      `Handling invoice issued event: ${event.invoice.invoiceNumber}`,
    );

    const { invoice, issuedBy } = event;

    // Format invoice total for display
    const formattedTotal = this.formatCurrency(invoice.total);
    const dueDate = invoice.dueDate ? this.formatDate(invoice.dueDate) : 'Not specified';

    // Create notification for client
    await this.notificationsService.createNotification({
      type: NotificationType.INVOICE_ISSUED,
      recipientType: RecipientType.CLIENT,
      recipientId: invoice.clientId,
      title: 'New Invoice',
      body: `Invoice ${invoice.invoiceNumber} for ${formattedTotal} has been issued. Due date: ${dueDate}`,
      invoiceId: invoice.id,
    });

    // Send email to client
    await this.emailService.sendInvoiceIssuedEmail(invoice);

    this.logger.log(
      `Completed handling invoice issued: ${invoice.invoiceNumber}`,
    );
  }

  /**
   * Handle invoice paid event
   * - Create in-app notification for client
   * - Send confirmation email to client
   */
  @OnEvent(InvoiceEvents.PAID)
  async handleInvoicePaid(event: InvoicePaidEvent): Promise<void> {
    this.logger.log(
      `Handling invoice paid event: ${event.invoice.invoiceNumber}`,
    );

    const { invoice, markedPaidBy } = event;

    // Format invoice total for display
    const formattedTotal = this.formatCurrency(invoice.total);

    // Create notification for client
    await this.notificationsService.createNotification({
      type: NotificationType.INVOICE_PAID,
      recipientType: RecipientType.CLIENT,
      recipientId: invoice.clientId,
      title: 'Payment Received',
      body: `Thank you! Payment of ${formattedTotal} for invoice ${invoice.invoiceNumber} has been received.`,
      invoiceId: invoice.id,
    });

    // Send email to client
    await this.emailService.sendInvoicePaidEmail(invoice);

    this.logger.log(
      `Completed handling invoice paid: ${invoice.invoiceNumber}`,
    );
  }

  // ===========================
  // Helper Methods
  // ===========================

  private formatCurrency(pence: number): string {
    const pounds = pence / 100;
    return `£${pounds.toLocaleString('en-GB', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  private formatDate(date: Date): string {
    return new Date(date).toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  }
}
