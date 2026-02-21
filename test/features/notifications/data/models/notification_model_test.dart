import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/notifications/data/models/notification_model.dart';
import 'package:survey_scriber/features/notifications/domain/entities/notification.dart';

void main() {
  group('NotificationModel', () {
    group('fromJson', () {
      test('parses bookingDeleted when present and true', () {
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_CREATED',
          'title': 'New Booking',
          'body': 'A new booking was created',
          'bookingId': 'booking-123',
          'isRead': false,
          'readAt': null,
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': true, // Key field being tested
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.bookingDeleted, isTrue);
        expect(notification.hasValidBooking, isFalse);
      });

      test('parses bookingDeleted when present and false', () {
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_CONFIRMED',
          'title': 'Booking Confirmed',
          'body': 'Your booking has been confirmed',
          'bookingId': 'booking-456',
          'isRead': true,
          'readAt': '2024-01-15T11:00:00.000Z',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': false,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.bookingDeleted, isFalse);
        expect(notification.hasValidBooking, isTrue);
      });

      test('defaults bookingDeleted to false when not present (backward compatibility)', () {
        // Simulates API response from older backend version without bookingDeleted field
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_CANCELLED',
          'title': 'Booking Cancelled',
          'body': 'Your booking has been cancelled',
          'bookingId': 'booking-789',
          'isRead': false,
          'readAt': null,
          'createdAt': '2024-01-15T10:30:00.000Z',
          // Note: bookingDeleted is NOT present
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.bookingDeleted, isFalse);
        expect(notification.hasValidBooking, isTrue);
      });

      test('handles null bookingDeleted gracefully (backward compatibility)', () {
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_COMPLETED',
          'title': 'Booking Completed',
          'body': 'Your booking has been completed',
          'bookingId': 'booking-101',
          'isRead': true,
          'readAt': '2024-01-15T12:00:00.000Z',
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': null, // Explicitly null
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.bookingDeleted, isFalse);
        expect(notification.hasValidBooking, isTrue);
      });

      test('parses notification without bookingId correctly', () {
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_CREATED',
          'title': 'System Notification',
          'body': 'This is a general notification',
          'bookingId': null,
          'isRead': false,
          'readAt': null,
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': false,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.bookingId, isNull);
        expect(notification.bookingDeleted, isFalse);
        expect(notification.hasValidBooking, isFalse);
      });

      test('parses invoiceId when present', () {
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_CREATED',
          'title': 'Invoice Issued',
          'body': 'An invoice has been issued',
          'bookingId': 'booking-123',
          'invoiceId': 'invoice-456',
          'isRead': false,
          'readAt': null,
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': false,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.invoiceId, equals('invoice-456'));
        expect(notification.hasInvoice, isTrue);
      });

      test('parses invoiceId as null when not present', () {
        final json = {
          'id': 'notif-1',
          'type': 'BOOKING_CREATED',
          'title': 'New Booking',
          'body': 'A booking was created',
          'bookingId': 'booking-123',
          'isRead': false,
          'readAt': null,
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': false,
        };

        final notification = NotificationModel.fromJson(json);

        expect(notification.invoiceId, isNull);
        expect(notification.hasInvoice, isFalse);
      });
    });

    group('toJson', () {
      test('includes bookingDeleted in serialized output', () {
        final notification = NotificationModel(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'A new booking was created',
          bookingId: 'booking-123',
          isRead: false,
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          bookingDeleted: true,
        );

        final json = notification.toJson();

        expect(json['bookingDeleted'], isTrue);
      });

      test('includes invoiceId in serialized output', () {
        final notification = NotificationModel(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Invoice Issued',
          body: 'An invoice was issued',
          bookingId: 'booking-123',
          invoiceId: 'invoice-456',
          isRead: false,
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final json = notification.toJson();

        expect(json['invoiceId'], equals('invoice-456'));
      });

      test('round-trip serialization preserves bookingDeleted', () {
        final originalJson = {
          'id': 'notif-1',
          'type': 'BOOKING_CREATED',
          'title': 'New Booking',
          'body': 'A new booking was created',
          'bookingId': 'booking-123',
          'isRead': false,
          'readAt': null,
          'createdAt': '2024-01-15T10:30:00.000Z',
          'bookingDeleted': true,
        };

        final notification = NotificationModel.fromJson(originalJson);
        final serializedJson = notification.toJson();

        expect(serializedJson['bookingDeleted'], equals(originalJson['bookingDeleted']));
      });
    });
  });
}
