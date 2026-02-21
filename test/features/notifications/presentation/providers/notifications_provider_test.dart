import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:survey_scriber/core/error/failures.dart';
import 'package:survey_scriber/features/notifications/domain/entities/notification.dart';
import 'package:survey_scriber/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:survey_scriber/features/notifications/presentation/providers/notifications_provider.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late MockNotificationsRepository mockRepository;
  late NotificationsNotifier notifier;

  final testNotification = AppNotification(
    id: 'notif-1',
    type: NotificationType.bookingCreated,
    title: 'Test Notification',
    body: 'Test body',
    isRead: false,
    createdAt: DateTime.now(),
    bookingId: 'booking-123',
    invoiceId: 'invoice-456',
  );

  final testPageData = NotificationsPageData(
    notifications: [testNotification],
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
  );

  setUp(() {
    mockRepository = MockNotificationsRepository();
    notifier = NotificationsNotifier(mockRepository, true);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('NotificationsNotifier', () {
    group('loadNotifications', () {
      test('sets loading state and fetches notifications', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));

        await notifier.loadNotifications(refresh: true);

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.notifications.length, equals(1));
        expect(notifier.state.notifications.first.id, equals('notif-1'));
      });

      test('handles error gracefully', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => const Left(NetworkFailure()));

        await notifier.loadNotifications(refresh: true);

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.error, isNotNull);
      });

      test('prevents concurrent loading', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return Right(testPageData);
        });

        // Start first load
        final future1 = notifier.loadNotifications(refresh: true);
        // Try to start second load immediately
        final future2 = notifier.loadNotifications(refresh: true);

        await Future.wait([future1, future2]);

        // Should only be called once due to guard
        verify(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).called(1);
      });
    });

    group('loadMore', () {
      test('appends new notifications without duplicates', () async {
        // First load
        when(() => mockRepository.getNotifications(
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));

        await notifier.loadNotifications(refresh: true);

        // Second page with same notification (edge case)
        when(() => mockRepository.getNotifications(
              page: 2,
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(NotificationsPageData(
              notifications: [testNotification], // Same notification
              page: 2,
              limit: 20,
              total: 1,
              totalPages: 2,
            ),),);

        await notifier.loadMore();

        // Should still only have 1 notification (deduplicated)
        expect(notifier.state.notifications.length, equals(1));
      });

      test('does not load more when hasMore is false', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(NotificationsPageData(
              notifications: [testNotification],
              page: 1,
              limit: 20,
              total: 1,
              totalPages: 1, // Only 1 page
            ),),);

        await notifier.loadNotifications(refresh: true);

        expect(notifier.state.hasMore, isFalse);

        await notifier.loadMore();

        // Should only call getNotifications once (for initial load)
        verify(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).called(1);
      });
    });

    group('markAsRead', () {
      test('skips API call when notification already read', () async {
        final readNotification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Test',
          body: 'Test',
          isRead: true, // Already read
          createdAt: DateTime.now(),
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(NotificationsPageData(
              notifications: [readNotification],
              page: 1,
              limit: 20,
              total: 1,
              totalPages: 1,
            ),),);

        await notifier.loadNotifications(refresh: true);
        await notifier.markAsRead('notif-1');

        verifyNever(() => mockRepository.markAsRead(any()));
      });

      test('skips API call when notification does not exist', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));

        await notifier.loadNotifications(refresh: true);
        await notifier.markAsRead('non-existent-id');

        verifyNever(() => mockRepository.markAsRead(any()));
      });

      test('updates local state on success', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));
        when(() => mockRepository.markAsRead(any()))
            .thenAnswer((_) async => const Right(null));

        await notifier.loadNotifications(refresh: true);
        expect(notifier.state.notifications.first.isRead, isFalse);

        await notifier.markAsRead('notif-1');

        expect(notifier.state.notifications.first.isRead, isTrue);
      });
    });

    group('markAllAsRead', () {
      test('skips API call when no unread notifications', () async {
        final readNotification = AppNotification(
          id: 'notif-1',
          type: NotificationType.bookingCreated,
          title: 'Test',
          body: 'Test',
          isRead: true,
          createdAt: DateTime.now(),
        );

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(NotificationsPageData(
              notifications: [readNotification],
              page: 1,
              limit: 20,
              total: 1,
              totalPages: 1,
            ),),);

        await notifier.loadNotifications(refresh: true);
        await notifier.markAllAsRead();

        verifyNever(() => mockRepository.markAllAsRead());
      });
    });

    group('deleteNotification', () {
      test('removes notification from local state optimistically', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));
        when(() => mockRepository.deleteNotification(any()))
            .thenAnswer((_) async => const Right(null));

        await notifier.loadNotifications(refresh: true);
        expect(notifier.state.notifications.length, equals(1));

        final result = await notifier.deleteNotification('notif-1');

        expect(result, isTrue);
        expect(notifier.state.notifications.length, equals(0));
        expect(notifier.state.total, equals(0));
      });

      test('rolls back state on API error', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));
        when(() => mockRepository.deleteNotification(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

        await notifier.loadNotifications(refresh: true);
        expect(notifier.state.notifications.length, equals(1));

        final result = await notifier.deleteNotification('notif-1');

        expect(result, isFalse);
        // State should be rolled back
        expect(notifier.state.notifications.length, equals(1));
        expect(notifier.state.total, equals(1));
      });

      test('returns true for already deleted notification', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(testPageData));

        await notifier.loadNotifications(refresh: true);

        // Try to delete non-existent notification
        final result = await notifier.deleteNotification('non-existent-id');

        expect(result, isTrue); // Considered success - idempotent operation
        verifyNever(() => mockRepository.deleteNotification(any()));
      });

      test('prevents negative total count', () async {
        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(NotificationsPageData(
              notifications: [testNotification],
              page: 1,
              limit: 20,
              total: 0, // Edge case: total already 0
              totalPages: 1,
            ),),);
        when(() => mockRepository.deleteNotification(any()))
            .thenAnswer((_) async => const Right(null));

        await notifier.loadNotifications(refresh: true);
        await notifier.deleteNotification('notif-1');

        expect(notifier.state.total, equals(0)); // Clamped to 0, not -1
      });
    });

    group('unreadCount', () {
      test('computed correctly from notifications', () async {
        final notifications = [
          AppNotification(
            id: 'notif-1',
            type: NotificationType.bookingCreated,
            title: 'Unread 1',
            body: 'Body',
            isRead: false,
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: 'notif-2',
            type: NotificationType.bookingCreated,
            title: 'Read',
            body: 'Body',
            isRead: true,
            createdAt: DateTime.now(),
          ),
          AppNotification(
            id: 'notif-3',
            type: NotificationType.bookingCreated,
            title: 'Unread 2',
            body: 'Body',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => Right(NotificationsPageData(
              notifications: notifications,
              page: 1,
              limit: 20,
              total: 3,
              totalPages: 1,
            ),),);

        await notifier.loadNotifications(refresh: true);

        expect(notifier.state.unreadCount, equals(2));
      });
    });
  });
}
