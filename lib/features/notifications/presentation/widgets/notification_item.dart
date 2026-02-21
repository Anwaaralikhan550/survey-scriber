import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/notification.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onExpiredTap,
    this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  /// Called when user taps an expired/deleted booking notification.
  /// Use this to show a message like "This booking is no longer available."
  final VoidCallback? onExpiredTap;
  /// Called when user swipes to delete this notification.
  final VoidCallback? onDelete;

  /// Whether this notification's booking has been deleted.
  bool get _isExpired => notification.bookingDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Apply visual treatment for expired notifications
    final opacity = _isExpired ? 0.5 : 1.0;

    final Widget itemContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          // Disable tap for expired notifications, or call onExpiredTap
          onTap: _isExpired ? onExpiredTap : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: opacity,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isExpired
                    ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
                    : notification.isRead
                        ? colorScheme.surface
                        : colorScheme.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isExpired
                      ? colorScheme.outlineVariant.withOpacity(0.3)
                      : notification.isRead
                          ? colorScheme.outlineVariant.withOpacity(0.5)
                          : colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  color: _isExpired
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (!notification.isRead && !_isExpired)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _formatTime(notification.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                            // Show "Expired" badge for deleted booking notifications
                            if (_isExpired) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Expired',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead && onMarkAsRead != null && !_isExpired) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      onPressed: onMarkAsRead,
                      tooltip: 'Mark as read',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-delete if onDelete is provided
    if (onDelete != null) {
      return Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete!(),
        confirmDismiss: (_) async {
          // Optionally show confirmation
          return true;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.onError,
            size: 24,
          ),
        ),
        child: itemContent,
      );
    }

    return itemContent;
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    // For expired notifications, use a muted icon
    if (_isExpired) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.event_busy_rounded,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          size: 22,
        ),
      );
    }

    switch (notification.type) {
      case NotificationType.bookingCreated:
        iconData = Icons.event_available_rounded;
        iconColor = colorScheme.primary;
        break;
      case NotificationType.bookingConfirmed:
        iconData = Icons.check_circle_rounded;
        iconColor = colorScheme.primary;
        break;
      case NotificationType.bookingCancelled:
        iconData = Icons.cancel_rounded;
        iconColor = colorScheme.error;
        break;
      case NotificationType.bookingCompleted:
        iconData = Icons.task_alt_rounded;
        iconColor = colorScheme.secondary;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
