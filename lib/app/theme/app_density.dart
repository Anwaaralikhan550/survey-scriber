import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/preferences_provider.dart';

/// Provider for compact mode state
final compactModeProvider = Provider<bool>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.compactMode;
});

/// Density-aware spacing values that adapt based on compact mode
class AppDensity {
  AppDensity({required this.isCompact});

  final bool isCompact;

  /// Multiplier for compact mode (reduces spacing by 25%)
  double get multiplier => isCompact ? 0.75 : 1.0;

  // Base spacing values (adjusted for compact mode)
  double get xs => (isCompact ? 2 : 4);
  double get sm => (isCompact ? 6 : 8);
  double get md => (isCompact ? 12 : 16);
  double get lg => (isCompact ? 18 : 24);
  double get xl => (isCompact ? 24 : 32);
  double get xxl => (isCompact ? 36 : 48);
  double get xxxl => (isCompact ? 48 : 64);

  // Padding presets
  EdgeInsets get paddingXs => EdgeInsets.all(xs);
  EdgeInsets get paddingSm => EdgeInsets.all(sm);
  EdgeInsets get paddingMd => EdgeInsets.all(md);
  EdgeInsets get paddingLg => EdgeInsets.all(lg);
  EdgeInsets get paddingXl => EdgeInsets.all(xl);

  // Horizontal padding
  EdgeInsets get paddingHorizontalSm => EdgeInsets.symmetric(horizontal: sm);
  EdgeInsets get paddingHorizontalMd => EdgeInsets.symmetric(horizontal: md);
  EdgeInsets get paddingHorizontalLg => EdgeInsets.symmetric(horizontal: lg);

  // Vertical padding
  EdgeInsets get paddingVerticalSm => EdgeInsets.symmetric(vertical: sm);
  EdgeInsets get paddingVerticalMd => EdgeInsets.symmetric(vertical: md);
  EdgeInsets get paddingVerticalLg => EdgeInsets.symmetric(vertical: lg);

  // Screen padding
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: md,
        vertical: sm,
      );

  // Card padding
  EdgeInsets get cardPadding => EdgeInsets.all(md);

  // List item padding
  EdgeInsets get listItemPadding => EdgeInsets.symmetric(
        horizontal: md,
        vertical: isCompact ? 6 : 8,
      );

  // Gaps
  SizedBox get gapXs => SizedBox(width: xs, height: xs);
  SizedBox get gapSm => SizedBox(width: sm, height: sm);
  SizedBox get gapMd => SizedBox(width: md, height: md);
  SizedBox get gapLg => SizedBox(width: lg, height: lg);
  SizedBox get gapXl => SizedBox(width: xl, height: xl);

  // Horizontal gaps
  SizedBox get gapHorizontalXs => SizedBox(width: xs);
  SizedBox get gapHorizontalSm => SizedBox(width: sm);
  SizedBox get gapHorizontalMd => SizedBox(width: md);
  SizedBox get gapHorizontalLg => SizedBox(width: lg);

  // Vertical gaps
  SizedBox get gapVerticalXs => SizedBox(height: xs);
  SizedBox get gapVerticalSm => SizedBox(height: sm);
  SizedBox get gapVerticalMd => SizedBox(height: md);
  SizedBox get gapVerticalLg => SizedBox(height: lg);
  SizedBox get gapVerticalXl => SizedBox(height: xl);
  SizedBox get gapVerticalXxl => SizedBox(height: xxl);

  // List tile height
  double get listTileHeight => isCompact ? 48 : 56;

  // Icon sizes
  double get iconSm => isCompact ? 18 : 20;
  double get iconMd => isCompact ? 22 : 24;
  double get iconLg => isCompact ? 28 : 32;

  // Avatar sizes
  double get avatarSm => isCompact ? 32 : 40;
  double get avatarMd => isCompact ? 40 : 48;
  double get avatarLg => isCompact ? 56 : 64;
}

/// Provider for density-aware spacing
final appDensityProvider = Provider<AppDensity>((ref) {
  final isCompact = ref.watch(compactModeProvider);
  return AppDensity(isCompact: isCompact);
});

/// Extension to easily access density from BuildContext via ProviderScope
extension AppDensityExtension on WidgetRef {
  AppDensity get density => watch(appDensityProvider);
  bool get isCompactMode => watch(compactModeProvider);
}
