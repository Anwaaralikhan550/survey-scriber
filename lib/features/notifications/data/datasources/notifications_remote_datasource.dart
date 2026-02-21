import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
  (ref) => NotificationsRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

abstract class NotificationsRemoteDataSource {
  Future<NotificationsPageModel> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  });

  Future<int> getUnreadCount();

  Future<void> markAsRead(String notificationId);

  Future<int> markAllAsRead();

  Future<void> deleteNotification(String notificationId);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<NotificationsPageModel> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (isRead != null) {
      queryParams['isRead'] = isRead;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      'notifications',
      queryParameters: queryParams,
    );

    return NotificationsPageModel.fromJson(response.data!);
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'notifications/unread-count',
    );

    return response.data!['count'] as int;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.post<Map<String, dynamic>>(
      'notifications/$notificationId/read',
    );
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'notifications/read-all',
    );

    return response.data!['count'] as int;
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _apiClient.post<Map<String, dynamic>>(
      'notifications/$notificationId/delete',
    );
  }
}
