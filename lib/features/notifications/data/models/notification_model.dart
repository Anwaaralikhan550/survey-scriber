import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    super.bookingId,
    super.invoiceId,
    super.readAt,
    super.bookingDeleted,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      bookingId: json['bookingId'] as String?,
      invoiceId: json['invoiceId'] as String?,
      isRead: json['isRead'] as bool,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      // Parse bookingDeleted with fallback to false for backward compatibility
      // with older API responses that may not include this field
      bookingDeleted: json['bookingDeleted'] as bool? ?? false,
    );

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'BOOKING_CREATED':
        return NotificationType.bookingCreated;
      case 'BOOKING_CONFIRMED':
        return NotificationType.bookingConfirmed;
      case 'BOOKING_CANCELLED':
        return NotificationType.bookingCancelled;
      case 'BOOKING_COMPLETED':
        return NotificationType.bookingCompleted;
      default:
        return NotificationType.bookingCreated;
    }
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'type': _typeToString(type),
      'title': title,
      'body': body,
      'bookingId': bookingId,
      'invoiceId': invoiceId,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'bookingDeleted': bookingDeleted,
    };

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.bookingCreated:
        return 'BOOKING_CREATED';
      case NotificationType.bookingConfirmed:
        return 'BOOKING_CONFIRMED';
      case NotificationType.bookingCancelled:
        return 'BOOKING_CANCELLED';
      case NotificationType.bookingCompleted:
        return 'BOOKING_COMPLETED';
    }
  }
}

class NotificationsPageModel extends NotificationsPageData {
  const NotificationsPageModel({
    required List<NotificationModel> super.notifications,
    required super.page,
    required super.limit,
    required super.total,
    required super.totalPages,
  });

  factory NotificationsPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return NotificationsPageModel(
      notifications: data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }
}
