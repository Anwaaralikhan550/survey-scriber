import 'package:equatable/equatable.dart';

enum NotificationType {
  bookingCreated,
  bookingConfirmed,
  bookingCancelled,
  bookingCompleted,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
    this.invoiceId,
    this.readAt,
    this.bookingDeleted = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? bookingId;
  final String? invoiceId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  /// Whether the referenced booking has been deleted.
  /// When true, the notification should be displayed as disabled/expired
  /// and tapping it should NOT navigate to the booking detail page.
  final bool bookingDeleted;

  /// Returns true if this notification has a valid, navigable booking reference.
  /// Used to determine if tap should navigate to booking details.
  bool get hasValidBooking => bookingId != null && !bookingDeleted;

  /// Returns true if this notification has a navigable invoice reference.
  bool get hasInvoice => invoiceId != null;

  @override
  List<Object?> get props => [id, type, title, body, bookingId, invoiceId, isRead, readAt, createdAt, bookingDeleted];
}

class NotificationsPageData extends Equatable {
  const NotificationsPageData({
    required this.notifications,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AppNotification> notifications;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [notifications, page, limit, total, totalPages];
}
