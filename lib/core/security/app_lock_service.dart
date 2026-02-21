import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_service.dart';

/// Service that manages app lock state and lifecycle monitoring.
///
/// This service:
/// - Tracks when the app goes to background
/// - Triggers lock when returning after timeout
/// - Provides lock state for UI to show lock screen
class AppLockService extends WidgetsBindingObserver {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  final BiometricService _biometricService = BiometricService.instance;

  /// Stream controller for lock state changes.
  final _lockStateController = StreamController<bool>.broadcast();

  /// Stream of lock state changes.
  Stream<bool> get lockStateStream => _lockStateController.stream;

  /// Whether the app is currently locked.
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  /// Whether biometric lock is enabled (from preferences).
  bool _biometricEnabled = false;

  /// Auto-lock timeout in minutes (0 = disabled).
  int _autoLockTimeoutMinutes = 5;

  /// Timestamp when app went to background.
  DateTime? _backgroundTimestamp;

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Initialize the service with current preferences.
  void initialize({
    required bool biometricEnabled,
    required int autoLockTimeoutMinutes,
  }) {
    if (!_initialized) {
      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
    }

    _biometricEnabled = biometricEnabled;
    _autoLockTimeoutMinutes = autoLockTimeoutMinutes;
  }

  /// Update settings when preferences change.
  void updateSettings({
    bool? biometricEnabled,
    int? autoLockTimeoutMinutes,
  }) {
    if (biometricEnabled != null) {
      _biometricEnabled = biometricEnabled;
      // If biometric is disabled, unlock immediately
      if (!biometricEnabled && _isLocked) {
        _setLocked(false);
      }
    }
    if (autoLockTimeoutMinutes != null) {
      _autoLockTimeoutMinutes = autoLockTimeoutMinutes;
    }
  }

  /// Lock the app immediately.
  void lock() {
    if (_biometricEnabled) {
      _setLocked(true);
    }
  }

  /// Attempt to unlock using biometrics.
  Future<BiometricResult> unlock() async {
    if (!_isLocked) {
      return BiometricResult.success;
    }

    final result = await _biometricService.authenticate(
      reason: 'Authenticate to unlock SurveyScriber',
    );

    if (result == BiometricResult.success) {
      _setLocked(false);
    }

    return result;
  }

  void _setLocked(bool locked) {
    if (_isLocked != locked) {
      _isLocked = locked;
      _lockStateController.add(locked);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_biometricEnabled) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - record timestamp
        _backgroundTimestamp = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        // App returning to foreground - check if should lock
        _checkAutoLock();
        break;

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App being terminated or hidden
        break;
    }
  }

  void _checkAutoLock() {
    if (!_biometricEnabled || _autoLockTimeoutMinutes == 0) {
      return;
    }

    final backgroundTime = _backgroundTimestamp;
    if (backgroundTime == null) {
      return;
    }

    final elapsed = DateTime.now().difference(backgroundTime);
    final timeoutDuration = Duration(minutes: _autoLockTimeoutMinutes);

    if (elapsed >= timeoutDuration) {
      _setLocked(true);
    }

    _backgroundTimestamp = null;
  }

  /// Clean up resources.
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      _initialized = false;
    }
    _lockStateController.close();
  }
}

/// Provider for the app lock service.
final appLockServiceProvider = Provider<AppLockService>((ref) => AppLockService.instance);

/// Provider for the current lock state.
final isAppLockedProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(appLockServiceProvider);
  // Start with current state, then listen for changes
  return Stream.value(service.isLocked)
      .asyncExpand((_) => service.lockStateStream);
});
