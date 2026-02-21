import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:survey_scriber/core/error/exceptions.dart';
import 'package:survey_scriber/core/error/failures.dart';
import 'package:survey_scriber/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:survey_scriber/features/notifications/data/models/notification_model.dart';
import 'package:survey_scriber/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:survey_scriber/features/notifications/domain/entities/notification.dart';

class MockNotificationsRemoteDataSource extends Mock
    implements NotificationsRemoteDataSource {}

void main() {
  late MockNotificationsRemoteDataSource mockDataSource;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockNotificationsRemoteDataSource();
    repository = NotificationsRepositoryImpl(mockDataSource);
  });

  group('NotificationsRepositoryImpl', () {
    group('deleteNotification', () {
      test('returns Right(null) when delete succeeds', () async {
        when(() => mockDataSource.deleteNotification(any()))
            .thenAnswer((_) async {});

        final result = await repository.deleteNotification('notif-123');

        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.deleteNotification('notif-123')).called(1);
      });

      test('returns NetworkFailure on network error', () async {
        when(() => mockDataSource.deleteNotification(any()))
            .thenThrow(const NetworkException());

        final result = await repository.deleteNotification('notif-123');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test('returns ServerFailure on server error', () async {
        when(() => mockDataSource.deleteNotification(any()))
            .thenThrow(const ServerException(message: 'Not found'));

        final result = await repository.deleteNotification('notif-123');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect((failure as ServerFailure).message, equals('Not found'));
          },
          (_) => fail('Expected failure'),
        );
      });
    });

    group('getNotifications', () {
      final testNotificationModel = NotificationModel(
        id: 'notif-1',
        type: NotificationType.bookingCreated,
        title: 'Test',
        body: 'Test body',
        isRead: false,
        createdAt: DateTime.now(),
        bookingId: 'booking-123',
        invoiceId: 'invoice-456',
      );

      final testPageModel = NotificationsPageModel(
        notifications: [testNotificationModel],
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );

      test('returns notifications with invoiceId parsed correctly', () async {
        when(() => mockDataSource.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => testPageModel);

        final result = await repository.getNotifications();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected success'),
          (pageData) {
            expect(pageData.notifications.first.invoiceId, equals('invoice-456'));
            expect(pageData.notifications.first.bookingId, equals('booking-123'));
          },
        );
      });

      test('returns notifications with bookingDeleted parsed correctly', () async {
        final expiredNotification = NotificationModel(
          id: 'notif-2',
          type: NotificationType.bookingCancelled,
          title: 'Expired',
          body: 'Booking deleted',
          isRead: false,
          createdAt: DateTime.now(),
          bookingId: 'deleted-booking',
          bookingDeleted: true,
        );

        when(() => mockDataSource.getNotifications(
              page: any(named: 'page'),
              limit: any(named: 'limit'),
              isRead: any(named: 'isRead'),
            ),).thenAnswer((_) async => NotificationsPageModel(
              notifications: [expiredNotification],
              page: 1,
              limit: 20,
              total: 1,
              totalPages: 1,
            ),);

        final result = await repository.getNotifications();

        result.fold(
          (_) => fail('Expected success'),
          (pageData) {
            expect(pageData.notifications.first.bookingDeleted, isTrue);
            expect(pageData.notifications.first.hasValidBooking, isFalse);
          },
        );
      });
    });

    group('markAsRead', () {
      test('returns Right(null) when mark as read succeeds', () async {
        when(() => mockDataSource.markAsRead(any()))
            .thenAnswer((_) async {});

        final result = await repository.markAsRead('notif-123');

        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.markAsRead('notif-123')).called(1);
      });

      test('returns NetworkFailure on network error', () async {
        when(() => mockDataSource.markAsRead(any()))
            .thenThrow(const NetworkException());

        final result = await repository.markAsRead('notif-123');

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected failure'),
        );
      });
    });

    group('markAllAsRead', () {
      test('returns count when mark all succeeds', () async {
        when(() => mockDataSource.markAllAsRead())
            .thenAnswer((_) async => 5);

        final result = await repository.markAllAsRead();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected success'),
          (count) => expect(count, equals(5)),
        );
      });

      test('returns NetworkFailure on network error', () async {
        when(() => mockDataSource.markAllAsRead())
            .thenThrow(const NetworkException());

        final result = await repository.markAllAsRead();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected failure'),
        );
      });
    });

    group('getUnreadCount', () {
      test('returns unread count on success', () async {
        when(() => mockDataSource.getUnreadCount())
            .thenAnswer((_) async => 10);

        final result = await repository.getUnreadCount();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected success'),
          (count) => expect(count, equals(10)),
        );
      });
    });
  });
}
