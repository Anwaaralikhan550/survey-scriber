import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/auto_refresh_mixin.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';

// State for notifications list
class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.total = 0,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final bool hasMore;
  final int total;

  /// Computed unread count from local state for immediate UI sync
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    bool? hasMore,
    int? total,
  }) => NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
}

// Notifications list notifier with auto-refresh
class NotificationsNotifier extends StateNotifier<NotificationsState>
    with AutoRefreshMixin<NotificationsState> {
  NotificationsNotifier(this._repository, this._isAuthenticated) : super(const NotificationsState()) {
    // Only start auto-refresh if user is authenticated
    if (_isAuthenticated) {
      startAutoRefresh(
        onRefresh: _silentRefresh,
      );
    }
  }

  final NotificationsRepository _repository;
  bool _isAuthenticated;

  /// Called when auth state changes - stops polling if user logs out
  void onAuthStateChanged(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (!isAuthenticated) {
      // User logged out - stop polling immediately to prevent 401 errors
      stopAutoRefresh();
      // Reset state to prevent stale data on next login
      state = const NotificationsState();
    } else if (!isAutoRefreshActive) {
      // User logged in - start polling
      startAutoRefresh(onRefresh: _silentRefresh);
    }
  }

  /// Silent refresh - updates state without showing loading indicator.
  Future<void> _silentRefresh() async {
    // CRITICAL: Don't make API calls if user is not authenticated
    // This prevents 401 errors after logout
    if (!_isAuthenticated) {
      return;
    }

    final result = await _repository.getNotifications();

    // Edge case: Check if notifier is still mounted before updating state
    if (!mounted) return;

    result.fold(
      (_) {}, // Silent failure on background refresh
      (page) => state = state.copyWith(
        notifications: page.notifications,
        page: page.page,
        hasMore: page.hasMore,
        total: page.total,
      ),
    );
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;

    if (refresh) {
      state = state.copyWith(isLoading: true);
    }

    final result = await _repository.getNotifications();

    // Edge case: Check if notifier is still mounted before updating state
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (page) => state = state.copyWith(
        notifications: page.notifications,
        isLoading: false,
        page: page.page,
        hasMore: page.hasMore,
        total: page.total,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _repository.getNotifications(
      page: state.page + 1,
    );

    // Edge case: Check if notifier is still mounted before updating state
    if (!mounted) return;

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      ),
      (page) {
        // Edge case: Deduplicate notifications to prevent duplicates from server
        final existingIds = state.notifications.map((n) => n.id).toSet();
        final newNotifications = page.notifications
            .where((n) => !existingIds.contains(n.id))
            .toList();

        state = state.copyWith(
          notifications: [...state.notifications, ...newNotifications],
          isLoadingMore: false,
          page: page.page,
          hasMore: page.hasMore,
          total: page.total,
        );
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    // Edge case: Check if notification exists and is unread
    final notification = state.notifications.where((n) => n.id == notificationId).firstOrNull;
    if (notification == null || notification.isRead) {
      return; // Already read or doesn't exist - skip API call
    }

    final result = await _repository.markAsRead(notificationId);

    // Edge case: Check if notifier is still mounted before updating state
    if (!mounted) return;

    result.fold(
      (failure) {}, // Silently fail - notification will still appear unread
      (_) {
        // Update local state
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == notificationId) {
            return AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              bookingId: n.bookingId,
              invoiceId: n.invoiceId,
              isRead: true,
              readAt: n.readAt ?? DateTime.now(),
              createdAt: n.createdAt,
              bookingDeleted: n.bookingDeleted,
            );
          }
          return n;
        }).toList();

        state = state.copyWith(notifications: updatedNotifications);
      },
    );
  }

  Future<void> markAllAsRead() async {
    // Edge case: Skip if no unread notifications
    final hasUnread = state.notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    final result = await _repository.markAllAsRead();

    // Edge case: Check if notifier is still mounted before updating state
    if (!mounted) return;

    result.fold(
      (failure) {},
      (_) {
        // Update local state - mark all as read
        final updatedNotifications = state.notifications.map((n) => AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            bookingId: n.bookingId,
            invoiceId: n.invoiceId,
            isRead: true,
            readAt: n.readAt ?? DateTime.now(),
            createdAt: n.createdAt,
            bookingDeleted: n.bookingDeleted,
          ),).toList();

        state = state.copyWith(notifications: updatedNotifications);
      },
    );
  }

  Future<bool> deleteNotification(String notificationId) async {
    // Edge case: Check if notification exists
    final notificationIndex = state.notifications.indexWhere((n) => n.id == notificationId);
    if (notificationIndex == -1) {
      return true; // Already deleted - consider success
    }

    // Store original state for rollback
    final originalNotifications = List<AppNotification>.from(state.notifications);
    final originalTotal = state.total;
    final deletedNotification = state.notifications[notificationIndex];

    // Optimistic UI update - remove immediately for responsive UX
    final updatedNotifications = state.notifications
        .where((n) => n.id != notificationId)
        .toList();
    state = state.copyWith(
      notifications: updatedNotifications,
      total: (state.total - 1).clamp(0, state.total), // Edge case: Prevent negative total
    );

    final result = await _repository.deleteNotification(notificationId);

    // Edge case: Check if notifier is still mounted before updating state
    if (!mounted) return true;

    return result.fold(
      (failure) {
        // Rollback on error - restore original state
        state = state.copyWith(
          notifications: originalNotifications,
          total: originalTotal,
        );
        return false;
      },
      (_) => true, // Already removed optimistically
    );
  }
}

// Provider for notifications list
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;

    final notifier = NotificationsNotifier(
      ref.watch(notificationsRepositoryProvider),
      isAuthenticated,
    );

    // Listen to auth state changes and update notifier accordingly
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final wasAuthenticated = previous?.status == AuthStatus.authenticated;
      final nowAuthenticated = next.status == AuthStatus.authenticated;

      // Only trigger if auth state actually changed
      if (wasAuthenticated != nowAuthenticated) {
        notifier.onAuthStateChanged(nowAuthenticated);
      }
    });

    return notifier;
  },
);

// Provider for unread count (used in badge)
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  // CRITICAL: Don't fetch unread count if user is not authenticated
  final authState = ref.watch(authNotifierProvider);
  if (authState.status != AuthStatus.authenticated) {
    return 0;
  }

  final repository = ref.watch(notificationsRepositoryProvider);
  final result = await repository.getUnreadCount();
  return result.fold(
    (failure) => 0,
    (count) => count,
  );
});

// Provider to refresh unread count
final unreadCountRefreshProvider = Provider<void Function()>((ref) => () => ref.invalidate(unreadCountProvider));

/// Provider for local unread count (syncs immediately with mark-as-read operations)
/// Use this for badge display to avoid API timing issues
final localUnreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.unreadCount;
});
