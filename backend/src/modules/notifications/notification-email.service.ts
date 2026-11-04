import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { NotificationType, Prisma, RecipientType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { BookingWithRelations } from './events/booking.events';
import { InvoiceWithRelations } from '../invoices/events/invoice.events';
import { EmailContent, paymentTermsHtml, propertyRowHtml } from '../email-templates/email-template.helpers';
import { EmailTemplatesService } from '../email-templates/email-templates.service';

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
  private readonly clientPortalUrl: string;
  private readonly staffAppUrl: string;
  private readonly emailEnabled: boolean;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly templates: EmailTemplatesService,
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
        await this.renderBooking('booking_created_client', booking, clientRecipient.name),
        booking.id,
      );
    }

    // Send to surveyor
    if (surveyorRecipient) {
      await this.sendEmail(
        surveyorRecipient,
        NotificationType.BOOKING_CREATED,
        await this.renderBooking('booking_created_surveyor', booking, this.clientNameForSurveyor(booking)),
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
        await this.renderBooking('booking_confirmed', booking, clientRecipient.name),
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
        await this.renderBooking('booking_cancelled_client', booking, clientRecipient.name),
        booking.id,
      );
    }

    // Send to surveyor
    if (surveyorRecipient) {
      await this.sendEmail(
        surveyorRecipient,
        NotificationType.BOOKING_CANCELLED,
        await this.renderBooking('booking_cancelled_surveyor', booking, this.clientNameForSurveyor(booking)),
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
        await this.renderBooking('booking_completed', booking, clientRecipient.name),
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
        await this.renderInvoice('invoice_issued', invoice, clientRecipient.name),
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
        await this.renderInvoice('invoice_paid', invoice, clientRecipient.name),
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
    content: EmailContent,
    invoiceId: string,
  ): Promise<void> {
    const { subject: fullSubject, html, text } = content;

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
        ...(await this.templates.sender(this.fromAddress)),
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

  private renderInvoice(key: string, invoice: InvoiceWithRelations, clientName: string): Promise<EmailContent> {
    return this.templates.render(
      key,
      {
        clientName,
        invoiceNumber: invoice.invoiceNumber,
        issueDate: invoice.issueDate ? this.formatDate(invoice.issueDate) : 'Today',
        dueDate: invoice.dueDate ? this.formatDate(invoice.dueDate) : 'Upon receipt',
        paidDate: invoice.paidDate ? this.formatDate(invoice.paidDate) : 'Today',
        total: this.formatCurrency(invoice.total),
        paymentTermsLine: invoice.paymentTerms ? `Payment Terms: ${invoice.paymentTerms}` : '',
        invoiceLink: `${this.clientPortalUrl}/invoices/${invoice.id}`,
      },
      { paymentTermsBlock: paymentTermsHtml(invoice.paymentTerms) },
    );
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
    content: EmailContent,
    bookingId: string,
  ): Promise<void> {
    const { subject: fullSubject, html, text } = content;

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
          ...(await this.templates.sender(this.fromAddress)),
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

  private clientNameForSurveyor(booking: BookingWithRelations): string {
    return booking.clientName || booking.client?.firstName || 'Client';
  }

  private renderBooking(key: string, booking: BookingWithRelations, clientName: string): Promise<EmailContent> {
    return this.templates.render(
      key,
      {
        clientName,
        bookingDate: this.formatDate(booking.date),
        startTime: booking.startTime,
        endTime: booking.endTime,
        surveyorName: this.getSurveyorFullName(booking),
        propertyLine: booking.propertyAddress ? `Property: ${booking.propertyAddress}` : '',
        bookingLink: `${this.clientPortalUrl}/bookings/${booking.id}`,
        staffBookingLink: `${this.staffAppUrl}/scheduling/bookings/${booking.id}`,
        portalLink: `${this.clientPortalUrl}/dashboard`,
      },
      { propertyRow: propertyRowHtml(booking.propertyAddress) },
    );
  }

  private getSurveyorFullName(booking: BookingWithRelations): string {
    const { firstName, lastName } = booking.surveyor;
    if (firstName && lastName) return `${firstName} ${lastName}`;
    if (firstName) return firstName;
    return 'Your surveyor';
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
    const { subject, html, text } = await this.templates.render('survey_report', { surveyTitle, senderName });

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
        ...(await this.templates.sender(this.fromAddress)),
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

}
