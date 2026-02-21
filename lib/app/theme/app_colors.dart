import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light Theme Colors
  static const Color primary = Color(0xFF1E3A5F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD6E3F7);
  static const Color onPrimaryContainer = Color(0xFF0A1929);

  static const Color secondary = Color(0xFF4A6572);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCDE5F5);
  static const Color onSecondaryContainer = Color(0xFF05212C);

  static const Color tertiary = Color(0xFF6B5778);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF3DAFF);
  static const Color onTertiaryContainer = Color(0xFF251432);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color background = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF191C1E);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceVariant = Color(0xFFE7E8EC);
  static const Color onSurfaceVariant = Color(0xFF44474E);

  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);

  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  static const Color inverseSurface = Color(0xFF2E3133);
  static const Color inverseOnSurface = Color(0xFFF0F0F3);
  static const Color inversePrimary = Color(0xFFA8C8F0);

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFFA8C8F0);
  static const Color onPrimaryDark = Color(0xFF0A2240);
  static const Color primaryContainerDark = Color(0xFF1E3A5F);
  static const Color onPrimaryContainerDark = Color(0xFFD6E3F7);

  static const Color secondaryDark = Color(0xFFB1C9D8);
  static const Color onSecondaryDark = Color(0xFF1C3641);
  static const Color secondaryContainerDark = Color(0xFF334C59);
  static const Color onSecondaryContainerDark = Color(0xFFCDE5F5);

  static const Color tertiaryDark = Color(0xFFD7BEE4);
  static const Color onTertiaryDark = Color(0xFF3B2948);
  static const Color tertiaryContainerDark = Color(0xFF533F5F);
  static const Color onTertiaryContainerDark = Color(0xFFF3DAFF);

  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);

  static const Color backgroundDark = Color(0xFF111418);
  static const Color onBackgroundDark = Color(0xFFE1E2E5);

  static const Color surfaceDark = Color(0xFF191C20);
  static const Color onSurfaceDark = Color(0xFFE1E2E5);
  static const Color surfaceVariantDark = Color(0xFF44474E);
  static const Color onSurfaceVariantDark = Color(0xFFC4C6CF);

  static const Color outlineDark = Color(0xFF8E9099);
  static const Color outlineVariantDark = Color(0xFF44474E);

  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color onWarning = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFFE1F5FE);
  static const Color onInfo = Color(0xFFFFFFFF);

  // Survey Status Colors
  static const Color statusDraft = Color(0xFF9E9E9E);
  static const Color statusInProgress = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusPendingReview = Color(0xFFFF9800);
  static const Color statusApproved = Color(0xFF00897B);
  static const Color statusRejected = Color(0xFFF44336);
}
