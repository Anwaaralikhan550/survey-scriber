import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, NotificationsPageData>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  });

  Future<Either<Failure, int>> getUnreadCount();

  Future<Either<Failure, void>> markAsRead(String notificationId);

  Future<Either<Failure, int>> markAllAsRead();

  Future<Either<Failure, void>> deleteNotification(String notificationId);
}
