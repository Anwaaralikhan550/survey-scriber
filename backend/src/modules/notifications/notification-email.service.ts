import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { NotificationType, Prisma, RecipientType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { BookingWithRelations } from './events/booking.events';
import { InvoiceWithRelations } from '../invoices/events/invoice.events';

interface EmailRecipient {
  email: string;
  name: string;
  recipientType: RecipientType;
  recipientId?: string;
}

@Injectable()
export class NotificationEmailService {
  private readonly logger = new Logger(NotificationEmailService.name);
  private readonly transporter: nodemailer.Transporter | null;
  private readonly fromAddress: string;
  private readonly appName: string;
  private readonly clientPortalUrl: string;
  private readonly staffAppUrl: string;
  private readonly emailEnabled: boolean;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    // Check if email notifications are enabled
    this.emailEnabled =
      this.configService.get<string>('NOTIFICATION_EMAIL_ENABLED') !== 'false';

    // SMTP configuration from environment
    const host = this.configService.get<string>('SMTP_HOST');
    const port = parseInt(this.configService.get<string>('SMTP_PORT') || '587', 10);
    const secure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    this.fromAddress =
      this.configService.get<string>('SMTP_FROM') || 'noreply@surveyscriber.com';
    this.appName = this.configService.get<string>('APP_NAME') || 'SurveyScriber';
    this.clientPortalUrl =
      this.configService.get<string>('CLIENT_PORTAL_URL') || 'http://localhost:3000/client';
    this.staffAppUrl =
      this.configService.get<string>('FRONTEND_URL') || 'http://localhost:3000';

    // Create transporter only if SMTP is configured
    if (host && user && pass && this.emailEnabled) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass },
      });
      this.logger.log('Notification email service initialized');
    } else {
      this.transporter = null;
      this.logger.warn(
        'Notification emails disabled - SMTP not configured or NOTIFICATION_EMAIL_ENABLED=false',
      );
    }
  }

  // ===========================
  // Booking Email Methods
  // ===========================

  /**
   * Send booking created email to client and surveyor
   */
  async sendBookingCreatedEmails(booking: BookingWithRelations): Promise<void> {
    const clientRecipient = this.getClientRecipient(booking);
    const surveyorRecipient = this.getSurveyorRecipient(booking);

    // Send to client
    if (clientRecipient) {
      await this.sendEmail(
        clientRecipient,
        NotificationType.BOOKING_CREATED,
        `Your survey booking has been scheduled`,
        this.getBookingCreatedClientHtml(booking, clientRecipient.name),
        this.getBookingCreatedClientText(booking, clientRecipient.name),
        booking.id,
      );
    }

    // Send to surveyor
    if (surveyorRecipient) {
      await this.sendEmail(
        surveyorRecipient,
        NotificationType.BOOKING_CREATED,
        `New booking assigned: ${this.formatDate(booking.date)}`,
        this.getBookingCreatedSurveyorHtml(booking),
        this.getBookingCreatedSurveyorText(booking),
        booking.id,
      );
    }
  }

  /**
   * Send booking confirmed email to client
   */
  async sendBookingConfirmedEmail(booking: BookingWithRelations): Promise<void> {
    const clientRecipient = this.getClientRecipient(booking);

    if (clientRecipient) {
      await this.sendEmail(
        clientRecipient,
        NotificationType.BOOKING_CONFIRMED,
        `Your booking for ${this.formatDate(booking.date)} is confirmed`,
        this.getBookingConfirmedHtml(booking, clientRecipient.name),
        this.getBookingConfirmedText(booking, clientRecipient.name),
        booking.id,
      );
    }
  }

  /**
   * Send booking cancelled email to client and surveyor
   */
  async sendBookingCancelledEmails(booking: BookingWithRelations): Promise<void> {
    const clientRecipient = this.getClientRecipient(booking);
    const surveyorRecipient = this.getSurveyorRecipient(booking);

    // Send to client
    if (clientRecipient) {
      await this.sendEmail(
        clientRecipient,
        NotificationType.BOOKING_CANCELLED,
        `Your booking for ${this.formatDate(booking.date)} has been cancelled`,
        this.getBookingCancelledClientHtml(booking, clientRecipient.name),
        this.getBookingCancelledClientText(booking, clientRecipient.name),
        booking.id,
      );
    }

    // Send to surveyor
    if (surveyorRecipient) {
      await this.sendEmail(
        surveyorRecipient,
        NotificationType.BOOKING_CANCELLED,
        `Booking cancelled: ${this.formatDate(booking.date)}`,
        this.getBookingCancelledSurveyorHtml(booking),
        this.getBookingCancelledSurveyorText(booking),
        booking.id,
      );
    }
  }

  /**
   * Send booking completed email to client
   */
  async sendBookingCompletedEmail(booking: BookingWithRelations): Promise<void> {
    const clientRecipient = this.getClientRecipient(booking);

    if (clientRecipient) {
      await this.sendEmail(
        clientRecipient,
        NotificationType.BOOKING_COMPLETED,
        `Your survey has been completed`,
        this.getBookingCompletedHtml(booking, clientRecipient.name),
        this.getBookingCompletedText(booking, clientRecipient.name),
        booking.id,
      );
    }
  }

  // ===========================
  // Invoice Email Methods
  // ===========================

  /**
   * Send invoice issued email to client
   */
  async sendInvoiceIssuedEmail(invoice: InvoiceWithRelations): Promise<void> {
    const clientRecipient = this.getInvoiceClientRecipient(invoice);

    if (clientRecipient) {
      await this.sendInvoiceEmail(
        clientRecipient,
        NotificationType.INVOICE_ISSUED,
        `Invoice ${invoice.invoiceNumber} - ${this.formatCurrency(invoice.total)}`,
        this.getInvoiceIssuedHtml(invoice, clientRecipient.name),
        this.getInvoiceIssuedText(invoice, clientRecipient.name),
        invoice.id,
      );
    }
  }

  /**
   * Send invoice paid confirmation email to client
   */
  async sendInvoicePaidEmail(invoice: InvoiceWithRelations): Promise<void> {
    const clientRecipient = this.getInvoiceClientRecipient(invoice);

    if (clientRecipient) {
      await this.sendInvoiceEmail(
        clientRecipient,
        NotificationType.INVOICE_PAID,
        `Payment Received - Invoice ${invoice.invoiceNumber}`,
        this.getInvoicePaidHtml(invoice, clientRecipient.name),
        this.getInvoicePaidText(invoice, clientRecipient.name),
        invoice.id,
      );
    }
  }

  private getInvoiceClientRecipient(invoice: InvoiceWithRelations): EmailRecipient | null {
    if (!invoice.client) return null;

    return {
      email: invoice.client.email,
      name: invoice.client.firstName || invoice.client.email.split('@')[0],
      recipientType: RecipientType.CLIENT,
      recipientId: invoice.client.id,
    };
  }

  private async sendInvoiceEmail(
    recipient: EmailRecipient,
    type: NotificationType,
    subject: string,
    html: string,
    text: string,
    invoiceId: string,
  ): Promise<void> {
    const fullSubject = `${subject} - ${this.appName}`;

    const logEntry = {
      notificationType: type,
      recipientEmail: recipient.email,
      recipientType: recipient.recipientType,
      recipientId: recipient.recipientId,
      invoiceId,
      subject: fullSubject,
      status: 'PENDING',
    };

    if (!this.transporter) {
      this.logger.log(`[DEV] Invoice email would be sent to: ${recipient.email}`);
      this.logger.log(`[DEV] Subject: ${fullSubject}`);

      await this.prisma.notificationEmailLog.create({
        data: { ...logEntry, status: 'DEV_SKIPPED' },
      });
      return;
    }

    try {
      const info = await this.transporter.sendMail({
        from: `"${this.appName}" <${this.fromAddress}>`,
        to: recipient.email,
        subject: fullSubject,
        html,
        text,
      });

      this.logger.log(`Invoice email sent to ${recipient.email}: ${type} (messageId: ${info.messageId})`);
      await this.prisma.notificationEmailLog.create({
        data: { ...logEntry, status: 'SENT' },
      });
    } catch (error) {
      this.logger.error(`Failed to send invoice email to ${recipient.email}: ${error}`);
      await this.prisma.notificationEmailLog.create({
        data: {
          ...logEntry,
          status: 'FAILED',
          errorMessage: error instanceof Error ? error.message : String(error),
        },
      });
    }
  }

  // Invoice Issued - Client
  private getInvoiceIssuedHtml(
    invoice: InvoiceWithRelations,
    clientName: string,
  ): string {
    const dueDate = invoice.dueDate
      ? this.formatDate(invoice.dueDate)
      : 'Upon receipt';

    const content = `
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        New Invoice
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi ${clientName},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        A new invoice has been issued for your account. Please see the details below:
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse; background-color: #f9f9f9; border-radius: 8px;">
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888; width: 140px;">Invoice Number</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 600;">${invoice.invoiceNumber}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888;">Issue Date</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${invoice.issueDate ? this.formatDate(invoice.issueDate) : 'Today'}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888;">Due Date</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${dueDate}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; color: #888888;">Total Amount</td>
          <td style="padding: 16px 20px; color: #1976d2; font-size: 20px; font-weight: 700;">${this.formatCurrency(invoice.total)}</td>
        </tr>
      </table>
      ${invoice.paymentTerms ? `
      <p style="margin: 20px 0 10px; color: #666666; font-size: 14px; font-weight: 600;">
        Payment Terms:
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 14px; line-height: 1.6;">
        ${invoice.paymentTerms}
      </p>
      ` : ''}
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="${this.clientPortalUrl}/invoices/${invoice.id}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Invoice
            </a>
          </td>
        </tr>
      </table>
      <p style="margin: 20px 0; color: #888888; font-size: 13px; line-height: 1.6; text-align: center;">
        You can download a PDF copy of this invoice from your client portal.
      </p>
    `;
    return this.getEmailWrapper(content);
  }

  private getInvoiceIssuedText(
    invoice: InvoiceWithRelations,
    clientName: string,
  ): string {
    const dueDate = invoice.dueDate
      ? this.formatDate(invoice.dueDate)
      : 'Upon receipt';

    return `
${this.appName} - New Invoice

Hi ${clientName},

A new invoice has been issued for your account:

Invoice Number: ${invoice.invoiceNumber}
Issue Date: ${invoice.issueDate ? this.formatDate(invoice.issueDate) : 'Today'}
Due Date: ${dueDate}
Total Amount: ${this.formatCurrency(invoice.total)}

${invoice.paymentTerms ? `Payment Terms: ${invoice.paymentTerms}` : ''}

View invoice: ${this.clientPortalUrl}/invoices/${invoice.id}

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // Invoice Paid - Client
  private getInvoicePaidHtml(
    invoice: InvoiceWithRelations,
    clientName: string,
  ): string {
    const content = `
      <h2 style="margin: 0 0 20px; color: #4caf50; font-size: 20px; font-weight: 600;">
        Payment Received - Thank You!
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi ${clientName},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        We've received your payment. Thank you for settling your invoice promptly.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse; background-color: #e8f5e9; border-radius: 8px;">
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #2e7d32; width: 140px;">Invoice Number</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #1b5e20; font-weight: 600;">${invoice.invoiceNumber}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #2e7d32;">Payment Date</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #c8e6c9; color: #1b5e20; font-weight: 500;">${invoice.paidDate ? this.formatDate(invoice.paidDate) : 'Today'}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; color: #2e7d32;">Amount Paid</td>
          <td style="padding: 16px 20px; color: #1b5e20; font-size: 20px; font-weight: 700;">${this.formatCurrency(invoice.total)}</td>
        </tr>
      </table>
      <div style="margin: 30px 0; padding: 20px; background-color: #f5f5f5; border-radius: 8px; text-align: center;">
        <span style="display: inline-block; padding: 8px 24px; background-color: #4caf50; color: #ffffff; font-size: 14px; font-weight: 600; border-radius: 20px;">
          PAID IN FULL
        </span>
      </div>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="${this.clientPortalUrl}/invoices/${invoice.id}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Receipt
            </a>
          </td>
        </tr>
      </table>
    `;
    return this.getEmailWrapper(content);
  }

  private getInvoicePaidText(
    invoice: InvoiceWithRelations,
    clientName: string,
  ): string {
    return `
${this.appName} - Payment Received

Hi ${clientName},

Thank you for your payment!

Invoice Number: ${invoice.invoiceNumber}
Payment Date: ${invoice.paidDate ? this.formatDate(invoice.paidDate) : 'Today'}
Amount Paid: ${this.formatCurrency(invoice.total)}

Status: PAID IN FULL

View receipt: ${this.clientPortalUrl}/invoices/${invoice.id}

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  private formatCurrency(pence: number): string {
    const pounds = pence / 100;
    return `£${pounds.toLocaleString('en-GB', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  // ===========================
  // Helper Methods
  // ===========================

  private getClientRecipient(booking: BookingWithRelations): EmailRecipient | null {
    // Prefer linked client, fallback to legacy fields
    if (booking.client) {
      return {
        email: booking.client.email,
        name: booking.client.firstName || booking.client.email.split('@')[0],
        recipientType: RecipientType.CLIENT,
        recipientId: booking.client.id,
      };
    }

    if (booking.clientEmail) {
      return {
        email: booking.clientEmail,
        name: booking.clientName || booking.clientEmail.split('@')[0],
        recipientType: RecipientType.CLIENT,
        recipientId: undefined, // No client record
      };
    }

    return null;
  }

  private getSurveyorRecipient(booking: BookingWithRelations): EmailRecipient | null {
    if (!booking.surveyor?.email) return null;

    return {
      email: booking.surveyor.email,
      name: booking.surveyor.firstName || 'Surveyor',
      recipientType: RecipientType.USER,
      recipientId: booking.surveyor.id,
    };
  }

  private async sendEmail(
    recipient: EmailRecipient,
    type: NotificationType,
    subject: string,
    html: string,
    text: string,
    bookingId: string,
  ): Promise<void> {
    const fullSubject = `${subject} - ${this.appName}`;

    // Log the attempt — typed to match Prisma create input
    const logEntry: Prisma.NotificationEmailLogCreateInput = {
      notificationType: type,
      recipientEmail: recipient.email,
      recipientType: recipient.recipientType,
      recipientId: recipient.recipientId,
      bookingId,
      subject: fullSubject,
      status: 'PENDING',
    };

    if (!this.transporter) {
      // Development mode - log only
      this.logger.log(`[DEV] Email would be sent to: ${recipient.email}`);
      this.logger.log(`[DEV] Subject: ${fullSubject}`);

      await this.prisma.notificationEmailLog.create({
        data: { ...logEntry, status: 'DEV_SKIPPED' },
      });
      return;
    }

    await this.sendWithRetry(recipient.email, fullSubject, html, text, logEntry);
  }

  /**
   * Send an email with exponential backoff retry (up to 3 attempts).
   *
   * On each failure, waits progressively longer before retrying:
   *   Attempt 1: immediate
   *   Attempt 2: 2 second delay
   *   Attempt 3: 4 second delay
   *
   * If all attempts fail, the email is logged as FAILED in the database
   * for manual retry or audit purposes.
   */
  private async sendWithRetry(
    to: string,
    subject: string,
    html: string,
    text: string,
    logEntry: Prisma.NotificationEmailLogCreateInput,
    maxRetries = 3,
  ): Promise<void> {
    let lastError: unknown;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Non-null assertion: sendWithRetry is only called when transporter exists
        const info = await this.transporter!.sendMail({
          from: `"${this.appName}" <${this.fromAddress}>`,
          to,
          subject,
          html,
          text,
        });

        this.logger.log(`Email sent to ${to}: ${subject} (messageId: ${info.messageId})`);
        await this.prisma.notificationEmailLog.create({
          data: { ...logEntry, status: 'SENT' },
        });
        return; // Success — exit retry loop
      } catch (error) {
        lastError = error;
        const errorMsg = error instanceof Error ? error.message : String(error);

        if (attempt < maxRetries) {
          const delayMs = Math.pow(2, attempt) * 1000; // 2s, 4s
          this.logger.warn(
            `Email to ${to} failed (attempt ${attempt}/${maxRetries}): ${errorMsg}. ` +
            `Retrying in ${delayMs}ms...`,
          );
          await new Promise((resolve) => setTimeout(resolve, delayMs));
        } else {
          this.logger.error(
            `Email to ${to} failed after ${maxRetries} attempts: ${errorMsg}`,
          );
        }
      }
    }

    // All retries exhausted — log as FAILED
    await this.prisma.notificationEmailLog.create({
      data: {
        ...logEntry,
        status: 'FAILED',
        errorMessage: lastError instanceof Error ? lastError.message : String(lastError),
      },
    });
  }

  private formatDate(date: Date): string {
    return date.toLocaleDateString('en-GB', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }

  private getSurveyorFullName(booking: BookingWithRelations): string {
    const { firstName, lastName } = booking.surveyor;
    if (firstName && lastName) return `${firstName} ${lastName}`;
    if (firstName) return firstName;
    return 'Your surveyor';
  }

  // ===========================
  // Email Templates
  // ===========================

  private getEmailWrapper(content: string): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td align="center" style="padding: 40px 0;">
        <table role="presentation" style="width: 100%; max-width: 600px; border-collapse: collapse;">
          <!-- Header -->
          <tr>
            <td style="background-color: #1976d2; padding: 30px 40px; border-radius: 8px 8px 0 0;">
              <h1 style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 600;">
                ${this.appName}
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="background-color: #ffffff; padding: 40px;">
              ${content}
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #fafafa; padding: 30px 40px; border-radius: 0 0 8px 8px; border-top: 1px solid #eeeeee;">
              <p style="margin: 0 0 10px; color: #888888; font-size: 13px; text-align: center;">
                This is an automated message from ${this.appName}.
              </p>
              <p style="margin: 0; color: #888888; font-size: 13px; text-align: center;">
                &copy; ${new Date().getFullYear()} ${this.appName}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`.trim();
  }

  // Booking Created - Client
  private getBookingCreatedClientHtml(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    const content = `
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        Booking Confirmation
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi ${clientName},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Your survey booking has been scheduled. Here are the details:
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.formatDate(booking.date)}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.startTime} - ${booking.endTime}</td>
        </tr>
        ${booking.propertyAddress ? `
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Property</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.propertyAddress}</td>
        </tr>
        ` : ''}
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Surveyor</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.getSurveyorFullName(booking)}</td>
        </tr>
      </table>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="${this.clientPortalUrl}/bookings/${booking.id}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Booking
            </a>
          </td>
        </tr>
      </table>
    `;
    return this.getEmailWrapper(content);
  }

  private getBookingCreatedClientText(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    return `
${this.appName} - Booking Confirmation

Hi ${clientName},

Your survey booking has been scheduled:

Date: ${this.formatDate(booking.date)}
Time: ${booking.startTime} - ${booking.endTime}
${booking.propertyAddress ? `Property: ${booking.propertyAddress}` : ''}
Surveyor: ${this.getSurveyorFullName(booking)}

View your booking: ${this.clientPortalUrl}/bookings/${booking.id}

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // Booking Created - Surveyor
  private getBookingCreatedSurveyorHtml(booking: BookingWithRelations): string {
    const clientName = booking.clientName || booking.client?.firstName || 'Client';
    const content = `
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        New Booking Assigned
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        A new survey booking has been assigned to you.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Client</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${clientName}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.formatDate(booking.date)}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.startTime} - ${booking.endTime}</td>
        </tr>
        ${booking.propertyAddress ? `
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Property</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.propertyAddress}</td>
        </tr>
        ` : ''}
      </table>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="${this.staffAppUrl}/scheduling/bookings/${booking.id}"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Booking
            </a>
          </td>
        </tr>
      </table>
    `;
    return this.getEmailWrapper(content);
  }

  private getBookingCreatedSurveyorText(booking: BookingWithRelations): string {
    const clientName = booking.clientName || booking.client?.firstName || 'Client';
    return `
${this.appName} - New Booking Assigned

A new survey booking has been assigned to you:

Client: ${clientName}
Date: ${this.formatDate(booking.date)}
Time: ${booking.startTime} - ${booking.endTime}
${booking.propertyAddress ? `Property: ${booking.propertyAddress}` : ''}

View booking: ${this.staffAppUrl}/scheduling/bookings/${booking.id}

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // Booking Confirmed - Client
  private getBookingConfirmedHtml(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    const content = `
      <h2 style="margin: 0 0 20px; color: #4caf50; font-size: 20px; font-weight: 600;">
        Booking Confirmed
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi ${clientName},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Great news! Your survey booking has been confirmed by your surveyor.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.formatDate(booking.date)}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.startTime} - ${booking.endTime}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Surveyor</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.getSurveyorFullName(booking)}</td>
        </tr>
      </table>
    `;
    return this.getEmailWrapper(content);
  }

  private getBookingConfirmedText(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    return `
${this.appName} - Booking Confirmed

Hi ${clientName},

Great news! Your survey booking has been confirmed.

Date: ${this.formatDate(booking.date)}
Time: ${booking.startTime} - ${booking.endTime}
Surveyor: ${this.getSurveyorFullName(booking)}

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // Booking Cancelled - Client
  private getBookingCancelledClientHtml(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    const content = `
      <h2 style="margin: 0 0 20px; color: #f44336; font-size: 20px; font-weight: 600;">
        Booking Cancelled
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi ${clientName},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        We're sorry to inform you that your survey booking has been cancelled.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.formatDate(booking.date)}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.startTime} - ${booking.endTime}</td>
        </tr>
      </table>
      <p style="margin: 20px 0; color: #555555; font-size: 14px; line-height: 1.6;">
        If you have any questions, please contact us.
      </p>
    `;
    return this.getEmailWrapper(content);
  }

  private getBookingCancelledClientText(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    return `
${this.appName} - Booking Cancelled

Hi ${clientName},

Your survey booking has been cancelled.

Date: ${this.formatDate(booking.date)}
Time: ${booking.startTime} - ${booking.endTime}

If you have any questions, please contact us.

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // Booking Cancelled - Surveyor
  private getBookingCancelledSurveyorHtml(booking: BookingWithRelations): string {
    const clientName = booking.clientName || booking.client?.firstName || 'Client';
    const content = `
      <h2 style="margin: 0 0 20px; color: #f44336; font-size: 20px; font-weight: 600;">
        Booking Cancelled
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        A booking has been cancelled.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Client</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${clientName}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.formatDate(booking.date)}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Time</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${booking.startTime} - ${booking.endTime}</td>
        </tr>
      </table>
    `;
    return this.getEmailWrapper(content);
  }

  private getBookingCancelledSurveyorText(booking: BookingWithRelations): string {
    const clientName = booking.clientName || booking.client?.firstName || 'Client';
    return `
${this.appName} - Booking Cancelled

A booking has been cancelled:

Client: ${clientName}
Date: ${this.formatDate(booking.date)}
Time: ${booking.startTime} - ${booking.endTime}

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // Booking Completed - Client
  private getBookingCompletedHtml(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    const content = `
      <h2 style="margin: 0 0 20px; color: #2196f3; font-size: 20px; font-weight: 600;">
        Survey Completed
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Hi ${clientName},
      </p>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Your survey has been completed. Once the report is finalized and approved, you will be able to access it in your client portal.
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse;">
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888; width: 120px;">Date</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.formatDate(booking.date)}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #888888;">Surveyor</td>
          <td style="padding: 12px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 500;">${this.getSurveyorFullName(booking)}</td>
        </tr>
      </table>
      <table role="presentation" style="margin: 30px 0; width: 100%;">
        <tr>
          <td align="center">
            <a href="${this.clientPortalUrl}/dashboard"
               style="display: inline-block; padding: 14px 32px; background-color: #1976d2; color: #ffffff; text-decoration: none; font-size: 16px; font-weight: 600; border-radius: 8px;">
              View Portal
            </a>
          </td>
        </tr>
      </table>
    `;
    return this.getEmailWrapper(content);
  }

  private getBookingCompletedText(
    booking: BookingWithRelations,
    clientName: string,
  ): string {
    return `
${this.appName} - Survey Completed

Hi ${clientName},

Your survey has been completed.

Date: ${this.formatDate(booking.date)}
Surveyor: ${this.getSurveyorFullName(booking)}

Once the report is finalized and approved, you can access it in your client portal:
${this.clientPortalUrl}/dashboard

---
This is an automated message from ${this.appName}.
    `.trim();
  }

  // ===========================
  // Survey Report Email
  // ===========================

  /**
   * Send a survey report PDF via email.
   * @param recipientEmail - Recipient email address
   * @param surveyTitle - Survey title for subject/body
   * @param pdfBuffer - PDF file content
   * @param senderName - Name of the staff member sending the report
   * @returns true if email was sent (or logged in dev mode)
   */
  async sendSurveyReportEmail(
    recipientEmail: string,
    surveyTitle: string,
    pdfBuffer: Buffer,
    senderName: string,
  ): Promise<boolean> {
    const subject = `Survey Report - ${surveyTitle}`;

    const html = this.getSurveyReportHtml(surveyTitle, senderName);
    const text = this.getSurveyReportText(surveyTitle, senderName);

    const sanitizedTitle = surveyTitle
      .replace(/[^a-zA-Z0-9_\- ]/g, '')
      .replace(/\s+/g, '_')
      .substring(0, 80);
    const filename = `Survey_Report_${sanitizedTitle}.pdf`;

    if (!this.transporter) {
      this.logger.log(
        `[DEV] Survey report email would be sent to: ${recipientEmail}`,
      );
      this.logger.log(`[DEV] Subject: ${subject}`);
      this.logger.log(`[DEV] Attachment: ${filename} (${pdfBuffer.length} bytes)`);

      await this.prisma.notificationEmailLog.create({
        data: {
          notificationType: 'REPORT_SENT' as NotificationType,
          recipientEmail,
          recipientType: RecipientType.CLIENT,
          subject,
          status: 'DEV_SKIPPED',
        },
      });
      return true;
    }

    try {
      const info = await this.transporter.sendMail({
        from: `"${this.appName}" <${this.fromAddress}>`,
        to: recipientEmail,
        subject,
        html,
        text,
        attachments: [
          {
            filename,
            content: pdfBuffer,
            contentType: 'application/pdf',
          },
        ],
      });

      this.logger.log(`Survey report email sent to ${recipientEmail} (messageId: ${info.messageId})`);

      await this.prisma.notificationEmailLog.create({
        data: {
          notificationType: 'REPORT_SENT' as NotificationType,
          recipientEmail,
          recipientType: RecipientType.CLIENT,
          subject,
          status: 'SENT',
        },
      });
      return true;
    } catch (error) {
      this.logger.error(
        `Failed to send survey report email to ${recipientEmail}: ${error}`,
      );

      await this.prisma.notificationEmailLog.create({
        data: {
          notificationType: 'REPORT_SENT' as NotificationType,
          recipientEmail,
          recipientType: RecipientType.CLIENT,
          subject,
          status: 'FAILED',
          errorMessage:
            error instanceof Error ? error.message : String(error),
        },
      });
      return false;
    }
  }

  private getSurveyReportHtml(
    surveyTitle: string,
    senderName: string,
  ): string {
    const content = `
      <h2 style="margin: 0 0 20px; color: #333333; font-size: 20px; font-weight: 600;">
        Survey Report
      </h2>
      <p style="margin: 0 0 20px; color: #555555; font-size: 16px; line-height: 1.6;">
        Please find attached the survey report for:
      </p>
      <table style="width: 100%; margin: 20px 0; border-collapse: collapse; background-color: #f9f9f9; border-radius: 8px;">
        <tr>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #888888; width: 140px;">Survey</td>
          <td style="padding: 16px 20px; border-bottom: 1px solid #eeeeee; color: #333333; font-weight: 600;">${surveyTitle}</td>
        </tr>
        <tr>
          <td style="padding: 16px 20px; color: #888888;">Sent By</td>
          <td style="padding: 16px 20px; color: #333333; font-weight: 500;">${senderName}</td>
        </tr>
      </table>
      <p style="margin: 20px 0 0; color: #555555; font-size: 14px; line-height: 1.6;">
        The PDF report is attached to this email.
      </p>
    `;
    return this.getEmailWrapper(content);
  }

  private getSurveyReportText(
    surveyTitle: string,
    senderName: string,
  ): string {
    return `
${this.appName} - Survey Report

Please find attached the survey report for:

Survey: ${surveyTitle}
Sent By: ${senderName}

The PDF report is attached to this email.

---
This is an automated message from ${this.appName}.
    `.trim();
  }
}
