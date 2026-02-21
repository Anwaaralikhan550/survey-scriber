import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin for StateNotifiers that need automatic background refresh.
///
/// Usage:
/// ```dart
/// class MyNotifier extends StateNotifier<MyState> with AutoRefreshMixin {
///   MyNotifier() : super(MyState()) {
///     startAutoRefresh(
///       interval: const Duration(seconds: 30),
///       onRefresh: _silentRefresh,
///     );
///   }
///
///   Future<void> _silentRefresh() async {
///     // Fetch data without setting isLoading = true
///     final data = await _repository.getData();
///     state = state.copyWith(data: data);
///   }
/// }
/// ```
mixin AutoRefreshMixin<T> on StateNotifier<T> {
  Timer? _refreshTimer;
  bool _isPaused = false;

  /// Starts automatic background refresh.
  ///
  /// [interval] - How often to refresh (default: 30 seconds)
  /// [onRefresh] - Async callback that performs the silent refresh
  /// [immediate] - If true, triggers refresh immediately (default: false)
  @protected
  void startAutoRefresh({
    Duration interval = const Duration(seconds: 30),
    required Future<void> Function() onRefresh,
    bool immediate = false,
  }) {
    stopAutoRefresh();

    if (immediate) {
      _safeRefresh(onRefresh);
    }

    _refreshTimer = Timer.periodic(interval, (_) {
      if (!_isPaused && mounted) {
        _safeRefresh(onRefresh);
      }
    });
  }

  /// Performs refresh with error handling to prevent crashes.
  Future<void> _safeRefresh(Future<void> Function() onRefresh) async {
    try {
      await onRefresh();
    } catch (e) {
      // Silent failure - don't crash the app for background refresh errors
      if (kDebugMode) {
        debugPrint('AutoRefresh error: $e');
      }
    }
  }

  /// Pauses auto-refresh (e.g., when app goes to background).
  @protected
  void pauseAutoRefresh() {
    _isPaused = true;
  }

  /// Resumes auto-refresh (e.g., when app returns to foreground).
  @protected
  void resumeAutoRefresh() {
    _isPaused = false;
  }

  /// Stops and cancels the auto-refresh timer.
  @protected
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Whether auto-refresh is currently active.
  bool get isAutoRefreshActive => _refreshTimer?.isActive ?? false;

  /// Whether auto-refresh is paused.
  bool get isAutoRefreshPaused => _isPaused;

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
