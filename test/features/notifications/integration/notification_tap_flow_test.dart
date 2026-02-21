import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/notifications/domain/entities/notification.dart';

/// Integration tests for notification tap behavior.
///
/// These tests verify that:
/// 1. Tapping a notification with valid booking navigates to booking details
/// 2. Tapping a notification with deleted booking does NOT navigate
/// 3. The hasValidBooking getter correctly determines navigation eligibility
void main() {
  group('Notification Tap Flow Integration', () {
    group('Navigation Decision Logic', () {
      test('notification with valid booking should allow navigation', () {
        final notification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'New Booking',
          body: 'Booking created',
          isRead: false,
          createdAt: DateTime(2024),
          bookingId: 'booking-123',
        );

        // This is the condition used in NotificationsPage.onTap
        final shouldNavigate = notification.hasValidBooking;

        expect(shouldNavigate, isTrue);
        expect(notification.bookingId, isNotNull);
      });

      test('notification with deleted booking should NOT allow navigation', () {
        final notification = AppNotification(
          id: 'notif-2',
          type: NotificationType.bookingCreated,
          title: 'Old Booking',
          body: 'This booking was deleted',
          isRead: false,
          createdAt: DateTime(2024),
          bookingId: 'booking-deleted-456',
          bookingDeleted: true, // Key: booking was deleted
        );

        // This is the condition used in NotificationsPage.onTap
        final shouldNavigate = notification.hasValidBooking;

        expect(shouldNavigate, isFalse);
        // Even though bookingId exists, we should not navigate
        expect(notification.bookingId, isNotNull);
        expect(notification.bookingDeleted, isTrue);
      });

      test('notification without bookingId should NOT allow navigation', () {
        final notification = AppNotification(
          id: 'notif-3',
          type: NotificationType.bookingCreated,
          title: 'System Notification',
          body: 'This has no associated booking',
          isRead: false,
          createdAt: DateTime(2024),
        );

        final shouldNavigate = notification.hasValidBooking;

        expect(shouldNavigate, isFalse);
      });
    });

    group('Booking API Call Prevention', () {
      test('deleted booking notification prevents unnecessary API call', () {
        // Simulates the scenario where user taps an orphaned notification
        final orphanedNotification = AppNotification(
          id: 'orphan-notif',
          type: NotificationType.bookingConfirmed,
          title: 'Booking Confirmed',
          body: 'Your booking has been confirmed',
          isRead: false,
          createdAt: DateTime(2024),
          bookingId: 'deleted-booking-id',
          bookingDeleted: true,
        );

        // In the real code, this check prevents:
        // context.push(Routes.bookingDetailPath(notification.bookingId!));
        // Which would trigger: GET /api/v1/scheduling/bookings/{deleted-booking-id}
        // And receive 404 response

        final wouldCallApi = orphanedNotification.hasValidBooking;

        expect(
          wouldCallApi,
          isFalse,
          reason: 'Should NOT call booking API when bookingDeleted=true',
        );
      });

      test('valid booking notification allows API call', () {
        final validNotification = AppNotification(
          id: 'valid-notif',
          type: NotificationType.bookingConfirmed,
          title: 'Booking Confirmed',
          body: 'Your booking has been confirmed',
          isRead: false,
          createdAt: DateTime(2024),
          bookingId: 'existing-booking-id',
        );

        final wouldCallApi = validNotification.hasValidBooking;

        expect(
          wouldCallApi,
          isTrue,
          reason: 'Should call booking API when bookingDeleted=false',
        );
      });
    });

    group('Edge Cases', () {
      test('handles both bookingId null and bookingDeleted true', () {
        final edgeCaseNotification = AppNotification(
          id: 'edge-case',
          type: NotificationType.bookingCancelled,
          title: 'Booking Cancelled',
          body: 'Something happened',
          isRead: true,
          createdAt: DateTime(2024),
          bookingDeleted: true,
        );

        expect(edgeCaseNotification.hasValidBooking, isFalse);
      });

      test('read notification with deleted booking still shows expired state', () {
        final readExpiredNotification = AppNotification(
          id: 'read-expired',
          type: NotificationType.bookingCompleted,
          title: 'Booking Completed',
          body: 'Your booking was completed',
          isRead: true, // Already read
          createdAt: DateTime(2024),
          bookingId: 'old-booking',
          bookingDeleted: true, // But booking was later deleted
        );

        // Even though it's read, it should still be marked as expired
        expect(readExpiredNotification.bookingDeleted, isTrue);
        expect(readExpiredNotification.hasValidBooking, isFalse);
      });
    });
  });
}
