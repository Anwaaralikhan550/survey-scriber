import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/logger.dart';

/// Service to manage screen wakelock based on user preferences.
///
/// When enabled, prevents the screen from sleeping during survey work.
/// This is essential for field surveyors who need continuous screen visibility.
class WakelockService {
  WakelockService._();

  static final WakelockService instance = WakelockService._();

  static const String _tag = 'WakelockService';

  bool _isEnabled = false;
  bool _isActive = false;

  /// Whether wakelock is currently enabled in preferences.
  bool get isEnabled => _isEnabled;

  /// Whether wakelock is currently active (screen won't sleep).
  bool get isActive => _isActive;

  /// Enable or disable wakelock based on preference.
  ///
  /// When enabled, the screen will stay on.
  /// When disabled, normal screen timeout behavior resumes.
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;

    _isEnabled = enabled;
    AppLogger.d(_tag, 'Wakelock preference changed: enabled=$enabled');

    if (enabled) {
      await _activate();
    } else {
      await _deactivate();
    }
  }

  /// Activate wakelock (keep screen on).
  ///
  /// Call this when entering a survey or other screen that needs wakelock.
  Future<void> _activate() async {
    if (_isActive) return;

    try {
      await WakelockPlus.enable();
      _isActive = true;
      AppLogger.d(_tag, 'Wakelock activated - screen will stay on');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to enable wakelock: $e');
    }
  }

  /// Deactivate wakelock (allow screen to sleep).
  ///
  /// Call this when leaving survey screens or when preference is disabled.
  Future<void> _deactivate() async {
    if (!_isActive) return;

    try {
      await WakelockPlus.disable();
      _isActive = false;
      AppLogger.d(_tag, 'Wakelock deactivated - screen can sleep');
    } catch (e) {
      AppLogger.e(_tag, 'Failed to disable wakelock: $e');
    }
  }

  /// Temporarily activate wakelock for a specific screen.
  ///
  /// This respects the user's preference - only activates if preference is enabled.
  /// Returns true if wakelock was activated.
  Future<bool> activateIfEnabled() async {
    if (!_isEnabled) {
      AppLogger.d(_tag, 'Wakelock not enabled in preferences, skipping');
      return false;
    }

    await _activate();
    return _isActive;
  }

  /// Check current wakelock state from the system.
  Future<bool> checkIsEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to check wakelock status: $e');
      return false;
    }
  }
}

/// Provider for the wakelock service.
final wakelockServiceProvider = Provider<WakelockService>((ref) => WakelockService.instance);
