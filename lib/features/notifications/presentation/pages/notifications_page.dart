import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_item.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safely load notifications - provider handles errors internally
      if (mounted) {
        ref.read(notificationsProvider.notifier).loadNotifications(refresh: true);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (state.notifications.any((n) => !n.isRead))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                  ref.read(unreadCountRefreshProvider)();
                },
                icon: Icon(
                  Icons.done_all_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notificationsProvider.notifier)
              .loadNotifications(refresh: true);
          ref.read(unreadCountRefreshProvider)();
        },
        child: _buildBody(state, theme, colorScheme),
      ),
    );
  }

  Widget _buildBody(
    NotificationsState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return _buildErrorState(theme, colorScheme);
    }

    if (state.notifications.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.notifications.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final notification = state.notifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              ref
                  .read(notificationsProvider.notifier)
                  .markAsRead(notification.id);
              ref.read(unreadCountRefreshProvider)();
            }
            // Only navigate if the notification has a valid (non-deleted) booking
            if (notification.hasValidBooking) {
              context.push(Routes.bookingDetailPath(notification.bookingId!));
            }
          },
          // Handle tap on expired/deleted booking notifications
          onExpiredTap: () {
            // Mark as read if not already
            if (!notification.isRead) {
              ref
                  .read(notificationsProvider.notifier)
                  .markAsRead(notification.id);
              ref.read(unreadCountRefreshProvider)();
            }
            // Show informative message - do NOT navigate to booking details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('This booking is no longer available.'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          onMarkAsRead: notification.isRead
              ? null
              : () {
                  ref
                      .read(notificationsProvider.notifier)
                      .markAsRead(notification.id);
                  ref.read(unreadCountRefreshProvider)();
                },
          onDelete: () async {
            final deleted = await ref
                .read(notificationsProvider.notifier)
                .deleteNotification(notification.id);
            if (deleted && context.mounted) {
              ref.read(unreadCountRefreshProvider)();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notification deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref
                  .read(notificationsProvider.notifier)
                  .loadNotifications(refresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No new notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! Check back later for updates.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
}
