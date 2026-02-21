import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/notifications/domain/entities/notification.dart';

void main() {
  group('AppNotification', () {
    group('hasValidBooking', () {
      test('returns true when bookingId is present and bookingDeleted is false', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime.now(),
          bookingId: 'booking-123',
        );

        expect(notification.hasValidBooking, isTrue);
      });

      test('returns false when bookingId is present but bookingDeleted is true', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024),
          bookingId: 'booking-123',
          bookingDeleted: true, // Booking was deleted
        );

        expect(notification.hasValidBooking, isFalse);
      });

      test('returns false when bookingId is null', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024),
        );

        expect(notification.hasValidBooking, isFalse);
      });

      test('returns false when bookingId is null and bookingDeleted is true', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024),
          bookingDeleted: true,
        );

        expect(notification.hasValidBooking, isFalse);
      });
    });

    group('bookingDeleted default value', () {
      test('defaults to false when not specified', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime.now(),
        );

        expect(notification.bookingDeleted, isFalse);
      });
    });

    group('hasInvoice', () {
      test('returns true when invoiceId is present', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Invoice Issued',
          body: 'An invoice was issued',
          isRead: false,
          createdAt: DateTime.now(),
          invoiceId: 'invoice-123',
        );

        expect(notification.hasInvoice, isTrue);
      });

      test('returns false when invoiceId is null', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Booking Created',
          body: 'A booking was created',
          isRead: false,
          createdAt: DateTime.now(),
        );

        expect(notification.hasInvoice, isFalse);
      });
    });

    group('invoiceId support', () {
      test('notification can have both bookingId and invoiceId', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Booking Created',
          body: 'A booking was created',
          isRead: false,
          createdAt: DateTime.now(),
          bookingId: 'booking-123',
          invoiceId: 'invoice-456',
        );

        expect(notification.hasValidBooking, isTrue);
        expect(notification.hasInvoice, isTrue);
      });

      test('invoiceId is included in equality props', () {
        final notification1 = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Test',
          body: 'Test',
          isRead: false,
          createdAt: DateTime(2024, 1, 15),
          invoiceId: 'invoice-123',
        );

        final notification2 = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Test',
          body: 'Test',
          isRead: false,
          createdAt: DateTime(2024, 1, 15),
          invoiceId: 'invoice-456', // Different invoiceId
        );

        expect(notification1, isNot(equals(notification2)));
      });
    });

    group('equality', () {
      test('two notifications with same bookingDeleted are equal', () {
        final notification1 = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024, 1, 15),
          bookingId: 'booking-123',
          bookingDeleted: true,
        );

        final notification2 = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024, 1, 15),
          bookingId: 'booking-123',
          bookingDeleted: true,
        );

        expect(notification1, equals(notification2));
      });

      test('two notifications with different bookingDeleted are not equal', () {
        final notification1 = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024, 1, 15),
          bookingId: 'booking-123',
        );

        final notification2 = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          isRead: false,
          createdAt: DateTime(2024, 1, 15),
          bookingId: 'booking-123',
          bookingDeleted: true,
        );

        expect(notification1, isNot(equals(notification2)));
      });
    });
  });
}
