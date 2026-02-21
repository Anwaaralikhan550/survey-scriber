import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/preferences_provider.dart';

/// Service to provide haptic feedback based on user preferences.
///
/// Use this service instead of directly calling [HapticFeedback] to respect
/// the user's preference for haptic feedback.
class HapticService {
  HapticService._();

  static final HapticService instance = HapticService._();

  bool _isEnabled = true;

  /// Whether haptic feedback is enabled.
  bool get isEnabled => _isEnabled;

  /// Update the enabled state.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Light haptic feedback for selections and toggles.
  void selectionClick() {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Medium haptic feedback for confirmations.
  void mediumImpact() {
    if (!_isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback for important actions.
  void heavyImpact() {
    if (!_isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Light haptic feedback for UI interactions.
  void lightImpact() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Vibrate feedback for errors or warnings.
  void vibrate() {
    if (!_isEnabled) return;
    HapticFeedback.vibrate();
  }
}

/// Provider for the haptic service.
final hapticServiceProvider = Provider<HapticService>((ref) {
  final prefs = ref.watch(preferencesProvider);
  HapticService.instance.setEnabled(prefs.enableHapticFeedback);
  return HapticService.instance;
});

/// Extension to easily trigger haptic feedback from WidgetRef.
extension HapticRefExtension on WidgetRef {
  /// Get the haptic service and trigger selection click.
  void hapticSelectionClick() {
    read(hapticServiceProvider).selectionClick();
  }

  /// Get the haptic service and trigger medium impact.
  void hapticMediumImpact() {
    read(hapticServiceProvider).mediumImpact();
  }

  /// Get the haptic service and trigger light impact.
  void hapticLightImpact() {
    read(hapticServiceProvider).lightImpact();
  }
}
