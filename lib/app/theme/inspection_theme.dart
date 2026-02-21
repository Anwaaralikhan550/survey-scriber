import 'package:flutter/material.dart';

/// Theme extension for inspection-specific colors.
/// Provides semantic colors for condition ratings and risk levels
/// that adapt to light/dark mode using Material 3 principles.
@immutable
class InspectionTheme extends ThemeExtension<InspectionTheme> {
  const InspectionTheme({
    required this.conditionExcellent,
    required this.conditionGood,
    required this.conditionFair,
    required this.conditionPoor,
    required this.conditionVeryPoor,
    required this.conditionNotInspected,
    required this.onConditionExcellent,
    required this.onConditionGood,
    required this.onConditionFair,
    required this.onConditionPoor,
    required this.onConditionVeryPoor,
    required this.riskLow,
    required this.riskMedium,
    required this.riskHigh,
    required this.riskCritical,
    required this.onRiskLow,
    required this.onRiskMedium,
    required this.onRiskHigh,
    required this.onRiskCritical,
    required this.conditionExcellentContainer,
    required this.conditionGoodContainer,
    required this.conditionFairContainer,
    required this.conditionPoorContainer,
    required this.conditionVeryPoorContainer,
    required this.riskLowContainer,
    required this.riskMediumContainer,
    required this.riskHighContainer,
    required this.riskCriticalContainer,
  });

  // Condition colors (for badges and indicators)
  final Color conditionExcellent;
  final Color conditionGood;
  final Color conditionFair;
  final Color conditionPoor;
  final Color conditionVeryPoor;
  final Color conditionNotInspected;

  // On-colors for text on condition backgrounds
  final Color onConditionExcellent;
  final Color onConditionGood;
  final Color onConditionFair;
  final Color onConditionPoor;
  final Color onConditionVeryPoor;

  // Risk level colors
  final Color riskLow;
  final Color riskMedium;
  final Color riskHigh;
  final Color riskCritical;

  // On-colors for text on risk backgrounds
  final Color onRiskLow;
  final Color onRiskMedium;
  final Color onRiskHigh;
  final Color onRiskCritical;

  // Container colors (lighter backgrounds for cards)
  final Color conditionExcellentContainer;
  final Color conditionGoodContainer;
  final Color conditionFairContainer;
  final Color conditionPoorContainer;
  final Color conditionVeryPoorContainer;

  final Color riskLowContainer;
  final Color riskMediumContainer;
  final Color riskHighContainer;
  final Color riskCriticalContainer;

  /// Light theme inspection colors
  static const light = InspectionTheme(
    // Condition colors - Light theme
    conditionExcellent: Color(0xFF1B5E20),
    conditionGood: Color(0xFF2E7D32),
    conditionFair: Color(0xFFF9A825),
    conditionPoor: Color(0xFFEF6C00),
    conditionVeryPoor: Color(0xFFC62828),
    conditionNotInspected: Color(0xFF757575),
    onConditionExcellent: Color(0xFFFFFFFF),
    onConditionGood: Color(0xFFFFFFFF),
    onConditionFair: Color(0xFF000000),
    onConditionPoor: Color(0xFFFFFFFF),
    onConditionVeryPoor: Color(0xFFFFFFFF),
    // Risk colors - Light theme
    riskLow: Color(0xFF2E7D32),
    riskMedium: Color(0xFFF9A825),
    riskHigh: Color(0xFFE65100),
    riskCritical: Color(0xFFB71C1C),
    onRiskLow: Color(0xFFFFFFFF),
    onRiskMedium: Color(0xFF000000),
    onRiskHigh: Color(0xFFFFFFFF),
    onRiskCritical: Color(0xFFFFFFFF),
    // Container colors - Light theme (semi-transparent backgrounds)
    conditionExcellentContainer: Color(0xFFE8F5E9),
    conditionGoodContainer: Color(0xFFE8F5E9),
    conditionFairContainer: Color(0xFFFFF8E1),
    conditionPoorContainer: Color(0xFFFFF3E0),
    conditionVeryPoorContainer: Color(0xFFFFEBEE),
    riskLowContainer: Color(0xFFE8F5E9),
    riskMediumContainer: Color(0xFFFFF8E1),
    riskHighContainer: Color(0xFFFFF3E0),
    riskCriticalContainer: Color(0xFFFFEBEE),
  );

  /// Dark theme inspection colors
  static const dark = InspectionTheme(
    // Condition colors - Dark theme (brighter for visibility)
    conditionExcellent: Color(0xFF81C784),
    conditionGood: Color(0xFF81C784),
    conditionFair: Color(0xFFFFD54F),
    conditionPoor: Color(0xFFFFB74D),
    conditionVeryPoor: Color(0xFFEF5350),
    conditionNotInspected: Color(0xFF9E9E9E),
    onConditionExcellent: Color(0xFF1B5E20),
    onConditionGood: Color(0xFF1B5E20),
    onConditionFair: Color(0xFF000000),
    onConditionPoor: Color(0xFF000000),
    onConditionVeryPoor: Color(0xFF000000),
    // Risk colors - Dark theme
    riskLow: Color(0xFF81C784),
    riskMedium: Color(0xFFFFD54F),
    riskHigh: Color(0xFFFFB74D),
    riskCritical: Color(0xFFEF5350),
    onRiskLow: Color(0xFF1B5E20),
    onRiskMedium: Color(0xFF000000),
    onRiskHigh: Color(0xFF000000),
    onRiskCritical: Color(0xFF000000),
    // Container colors - Dark theme (darker backgrounds)
    conditionExcellentContainer: Color(0xFF1B3D1F),
    conditionGoodContainer: Color(0xFF1B3D1F),
    conditionFairContainer: Color(0xFF3D3514),
    conditionPoorContainer: Color(0xFF3D2A14),
    conditionVeryPoorContainer: Color(0xFF3D1A1A),
    riskLowContainer: Color(0xFF1B3D1F),
    riskMediumContainer: Color(0xFF3D3514),
    riskHighContainer: Color(0xFF3D2A14),
    riskCriticalContainer: Color(0xFF3D1A1A),
  );

  @override
  InspectionTheme copyWith({
    Color? conditionExcellent,
    Color? conditionGood,
    Color? conditionFair,
    Color? conditionPoor,
    Color? conditionVeryPoor,
    Color? conditionNotInspected,
    Color? onConditionExcellent,
    Color? onConditionGood,
    Color? onConditionFair,
    Color? onConditionPoor,
    Color? onConditionVeryPoor,
    Color? riskLow,
    Color? riskMedium,
    Color? riskHigh,
    Color? riskCritical,
    Color? onRiskLow,
    Color? onRiskMedium,
    Color? onRiskHigh,
    Color? onRiskCritical,
    Color? conditionExcellentContainer,
    Color? conditionGoodContainer,
    Color? conditionFairContainer,
    Color? conditionPoorContainer,
    Color? conditionVeryPoorContainer,
    Color? riskLowContainer,
    Color? riskMediumContainer,
    Color? riskHighContainer,
    Color? riskCriticalContainer,
  }) => InspectionTheme(
      conditionExcellent: conditionExcellent ?? this.conditionExcellent,
      conditionGood: conditionGood ?? this.conditionGood,
      conditionFair: conditionFair ?? this.conditionFair,
      conditionPoor: conditionPoor ?? this.conditionPoor,
      conditionVeryPoor: conditionVeryPoor ?? this.conditionVeryPoor,
      conditionNotInspected: conditionNotInspected ?? this.conditionNotInspected,
      onConditionExcellent: onConditionExcellent ?? this.onConditionExcellent,
      onConditionGood: onConditionGood ?? this.onConditionGood,
      onConditionFair: onConditionFair ?? this.onConditionFair,
      onConditionPoor: onConditionPoor ?? this.onConditionPoor,
      onConditionVeryPoor: onConditionVeryPoor ?? this.onConditionVeryPoor,
      riskLow: riskLow ?? this.riskLow,
      riskMedium: riskMedium ?? this.riskMedium,
      riskHigh: riskHigh ?? this.riskHigh,
      riskCritical: riskCritical ?? this.riskCritical,
      onRiskLow: onRiskLow ?? this.onRiskLow,
      onRiskMedium: onRiskMedium ?? this.onRiskMedium,
      onRiskHigh: onRiskHigh ?? this.onRiskHigh,
      onRiskCritical: onRiskCritical ?? this.onRiskCritical,
      conditionExcellentContainer: conditionExcellentContainer ?? this.conditionExcellentContainer,
      conditionGoodContainer: conditionGoodContainer ?? this.conditionGoodContainer,
      conditionFairContainer: conditionFairContainer ?? this.conditionFairContainer,
      conditionPoorContainer: conditionPoorContainer ?? this.conditionPoorContainer,
      conditionVeryPoorContainer: conditionVeryPoorContainer ?? this.conditionVeryPoorContainer,
      riskLowContainer: riskLowContainer ?? this.riskLowContainer,
      riskMediumContainer: riskMediumContainer ?? this.riskMediumContainer,
      riskHighContainer: riskHighContainer ?? this.riskHighContainer,
      riskCriticalContainer: riskCriticalContainer ?? this.riskCriticalContainer,
    );

  @override
  InspectionTheme lerp(ThemeExtension<InspectionTheme>? other, double t) {
    if (other is! InspectionTheme) return this;
    return InspectionTheme(
      conditionExcellent: Color.lerp(conditionExcellent, other.conditionExcellent, t)!,
      conditionGood: Color.lerp(conditionGood, other.conditionGood, t)!,
      conditionFair: Color.lerp(conditionFair, other.conditionFair, t)!,
      conditionPoor: Color.lerp(conditionPoor, other.conditionPoor, t)!,
      conditionVeryPoor: Color.lerp(conditionVeryPoor, other.conditionVeryPoor, t)!,
      conditionNotInspected: Color.lerp(conditionNotInspected, other.conditionNotInspected, t)!,
      onConditionExcellent: Color.lerp(onConditionExcellent, other.onConditionExcellent, t)!,
      onConditionGood: Color.lerp(onConditionGood, other.onConditionGood, t)!,
      onConditionFair: Color.lerp(onConditionFair, other.onConditionFair, t)!,
      onConditionPoor: Color.lerp(onConditionPoor, other.onConditionPoor, t)!,
      onConditionVeryPoor: Color.lerp(onConditionVeryPoor, other.onConditionVeryPoor, t)!,
      riskLow: Color.lerp(riskLow, other.riskLow, t)!,
      riskMedium: Color.lerp(riskMedium, other.riskMedium, t)!,
      riskHigh: Color.lerp(riskHigh, other.riskHigh, t)!,
      riskCritical: Color.lerp(riskCritical, other.riskCritical, t)!,
      onRiskLow: Color.lerp(onRiskLow, other.onRiskLow, t)!,
      onRiskMedium: Color.lerp(onRiskMedium, other.onRiskMedium, t)!,
      onRiskHigh: Color.lerp(onRiskHigh, other.onRiskHigh, t)!,
      onRiskCritical: Color.lerp(onRiskCritical, other.onRiskCritical, t)!,
      conditionExcellentContainer: Color.lerp(conditionExcellentContainer, other.conditionExcellentContainer, t)!,
      conditionGoodContainer: Color.lerp(conditionGoodContainer, other.conditionGoodContainer, t)!,
      conditionFairContainer: Color.lerp(conditionFairContainer, other.conditionFairContainer, t)!,
      conditionPoorContainer: Color.lerp(conditionPoorContainer, other.conditionPoorContainer, t)!,
      conditionVeryPoorContainer: Color.lerp(conditionVeryPoorContainer, other.conditionVeryPoorContainer, t)!,
      riskLowContainer: Color.lerp(riskLowContainer, other.riskLowContainer, t)!,
      riskMediumContainer: Color.lerp(riskMediumContainer, other.riskMediumContainer, t)!,
      riskHighContainer: Color.lerp(riskHighContainer, other.riskHighContainer, t)!,
      riskCriticalContainer: Color.lerp(riskCriticalContainer, other.riskCriticalContainer, t)!,
    );
  }

  /// Get color for a condition string value
  Color getConditionColor(String? condition) => switch (condition?.toLowerCase()) {
      'excellent' => conditionExcellent,
      'good' => conditionGood,
      'fair' => conditionFair,
      'poor' => conditionPoor,
      'very poor' || 'verypoor' || 'very_poor' => conditionVeryPoor,
      'not inspected' || 'notinspected' || 'not_inspected' || 'n/a' => conditionNotInspected,
      _ => conditionNotInspected,
    };

  /// Get on-color for a condition string value
  Color getOnConditionColor(String? condition) => switch (condition?.toLowerCase()) {
      'excellent' => onConditionExcellent,
      'good' => onConditionGood,
      'fair' => onConditionFair,
      'poor' => onConditionPoor,
      'very poor' || 'verypoor' || 'very_poor' => onConditionVeryPoor,
      _ => onConditionGood,
    };

  /// Get container color for a condition string value
  Color getConditionContainerColor(String? condition) => switch (condition?.toLowerCase()) {
      'excellent' => conditionExcellentContainer,
      'good' => conditionGoodContainer,
      'fair' => conditionFairContainer,
      'poor' => conditionPoorContainer,
      'very poor' || 'verypoor' || 'very_poor' => conditionVeryPoorContainer,
      _ => conditionGoodContainer,
    };

  /// Get color for a risk level string value
  Color getRiskColor(String? risk) => switch (risk?.toLowerCase()) {
      'low' => riskLow,
      'medium' => riskMedium,
      'high' => riskHigh,
      'critical' => riskCritical,
      _ => riskLow,
    };

  /// Get on-color for a risk level string value
  Color getOnRiskColor(String? risk) => switch (risk?.toLowerCase()) {
      'low' => onRiskLow,
      'medium' => onRiskMedium,
      'high' => onRiskHigh,
      'critical' => onRiskCritical,
      _ => onRiskLow,
    };

  /// Get container color for a risk level string value
  Color getRiskContainerColor(String? risk) => switch (risk?.toLowerCase()) {
      'low' => riskLowContainer,
      'medium' => riskMediumContainer,
      'high' => riskHighContainer,
      'critical' => riskCriticalContainer,
      _ => riskLowContainer,
    };
}

/// Extension to easily access InspectionTheme from context
extension InspectionThemeExtension on BuildContext {
  InspectionTheme get inspectionTheme => Theme.of(this).extension<InspectionTheme>() ?? InspectionTheme.light;
}
