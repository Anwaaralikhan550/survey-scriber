import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationType, RecipientType, BookingStatus } from '@prisma/client';
import { NotificationsService } from '../notifications.service';
import { NotificationEmailService } from '../notification-email.service';
import {
  BookingCreatedEvent,
  BookingStatusChangedEvent,
  BookingEvents,
} from '../events/booking.events';

@Injectable()
export class BookingEventHandler {
  private readonly logger = new Logger(BookingEventHandler.name);

  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly emailService: NotificationEmailService,
  ) {}

  /**
   * Handle booking created event
   * - Create in-app notifications for surveyor and client
   * - Send confirmation emails
   */
  @OnEvent(BookingEvents.CREATED)
  async handleBookingCreated(event: BookingCreatedEvent): Promise<void> {
    this.logger.log(`Handling booking created event: ${event.booking.id}`);

    const { booking, createdBy } = event;
    const bookingDate = this.formatDate(booking.date);
    const bookingTime = `${booking.startTime} - ${booking.endTime}`;
    const address = booking.propertyAddress || 'Address not specified';

    // Create notification for surveyor
    await this.notificationsService.createNotification({
      type: NotificationType.BOOKING_CREATED,
      recipientType: RecipientType.USER,
      recipientId: booking.surveyorId,
      title: 'New Booking Assigned',
      body: `You have been assigned a new booking for ${bookingDate} at ${bookingTime}. Address: ${address}`,
      bookingId: booking.id,
    });

    // Create notification for client (if exists)
    if (booking.clientId) {
      await this.notificationsService.createNotification({
        type: NotificationType.BOOKING_CREATED,
        recipientType: RecipientType.CLIENT,
        recipientId: booking.clientId,
        title: 'Booking Confirmation',
        body: `Your booking has been scheduled for ${bookingDate} at ${bookingTime}. Address: ${address}`,
        bookingId: booking.id,
      });
    }

    // Send emails
    await this.emailService.sendBookingCreatedEmails(booking);

    this.logger.log(`Completed handling booking created: ${booking.id}`);
  }

  /**
   * Handle booking status changed event
   * Route to appropriate handler based on new status
   */
  @OnEvent(BookingEvents.STATUS_CHANGED)
  async handleBookingStatusChanged(
    event: BookingStatusChangedEvent,
  ): Promise<void> {
    this.logger.log(
      `Handling booking status change: ${event.booking.id} from ${event.previousStatus} to ${event.newStatus}`,
    );

    const { booking, previousStatus, newStatus, changedBy } = event;

    switch (newStatus) {
      case BookingStatus.CONFIRMED:
        await this.handleBookingConfirmed(booking);
        break;
      case BookingStatus.CANCELLED:
        await this.handleBookingCancelled(booking, previousStatus);
        break;
      case BookingStatus.COMPLETED:
        await this.handleBookingCompleted(booking);
        break;
      default:
        this.logger.debug(
          `No notification handler for status transition to ${newStatus}`,
        );
    }
  }

  /**
   * Handle booking confirmed
   */
  private async handleBookingConfirmed(
    booking: BookingCreatedEvent['booking'],
  ): Promise<void> {
    const bookingDate = this.formatDate(booking.date);
    const bookingTime = `${booking.startTime} - ${booking.endTime}`;
    const address = booking.propertyAddress || 'Address not specified';

    // Notification for surveyor
    await this.notificationsService.createNotification({
      type: NotificationType.BOOKING_CONFIRMED,
      recipientType: RecipientType.USER,
      recipientId: booking.surveyorId,
      title: 'Booking Confirmed',
      body: `Booking for ${bookingDate} at ${bookingTime} has been confirmed. Address: ${address}`,
      bookingId: booking.id,
    });

    // Notification for client
    if (booking.clientId) {
      await this.notificationsService.createNotification({
        type: NotificationType.BOOKING_CONFIRMED,
        recipientType: RecipientType.CLIENT,
        recipientId: booking.clientId,
        title: 'Booking Confirmed',
        body: `Your booking for ${bookingDate} at ${bookingTime} has been confirmed. Address: ${address}`,
        bookingId: booking.id,
      });
    }

    // Send confirmation email to client
    await this.emailService.sendBookingConfirmedEmail(booking);

    this.logger.log(`Completed handling booking confirmed: ${booking.id}`);
  }

  /**
   * Handle booking cancelled
   */
  private async handleBookingCancelled(
    booking: BookingCreatedEvent['booking'],
    previousStatus: BookingStatus,
  ): Promise<void> {
    const bookingDate = this.formatDate(booking.date);
    const bookingTime = `${booking.startTime} - ${booking.endTime}`;

    // Notification for surveyor
    await this.notificationsService.createNotification({
      type: NotificationType.BOOKING_CANCELLED,
      recipientType: RecipientType.USER,
      recipientId: booking.surveyorId,
      title: 'Booking Cancelled',
      body: `The booking scheduled for ${bookingDate} at ${bookingTime} has been cancelled.`,
      bookingId: booking.id,
    });

    // Notification for client
    if (booking.clientId) {
      await this.notificationsService.createNotification({
        type: NotificationType.BOOKING_CANCELLED,
        recipientType: RecipientType.CLIENT,
        recipientId: booking.clientId,
        title: 'Booking Cancelled',
        body: `Your booking scheduled for ${bookingDate} at ${bookingTime} has been cancelled.`,
        bookingId: booking.id,
      });
    }

    // Send cancellation emails
    await this.emailService.sendBookingCancelledEmails(booking);

    this.logger.log(`Completed handling booking cancelled: ${booking.id}`);
  }

  /**
   * Handle booking completed
   */
  private async handleBookingCompleted(
    booking: BookingCreatedEvent['booking'],
  ): Promise<void> {
    const bookingDate = this.formatDate(booking.date);

    // Notification for surveyor
    await this.notificationsService.createNotification({
      type: NotificationType.BOOKING_COMPLETED,
      recipientType: RecipientType.USER,
      recipientId: booking.surveyorId,
      title: 'Booking Completed',
      body: `The booking from ${bookingDate} has been marked as completed.`,
      bookingId: booking.id,
    });

    // Notification for client
    if (booking.clientId) {
      await this.notificationsService.createNotification({
        type: NotificationType.BOOKING_COMPLETED,
        recipientType: RecipientType.CLIENT,
        recipientId: booking.clientId,
        title: 'Booking Completed',
        body: `Your booking from ${bookingDate} has been completed. Thank you for choosing our service!`,
        bookingId: booking.id,
      });
    }

    // Send completion email to client
    await this.emailService.sendBookingCompletedEmail(booking);

    this.logger.log(`Completed handling booking completed: ${booking.id}`);
  }

  // ===========================
  // Helper Methods
  // ===========================

  private formatDate(date: Date): string {
    return new Date(date).toLocaleDateString('en-GB', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }
}
