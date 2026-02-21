import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// All AI features that can be individually toggled.
///
/// Feature flags allow disabling AI features without code changes —
/// useful for gradual rollout, A/B testing, or emergency kill-switches.
enum AiFeature {
  /// AI-generated report narratives (executive summary + section narratives)
  reportNarrative('ai_report_narrative', 'AI Report Narrative'),

  /// AI consistency check (finds contradictions across screens)
  consistencyCheck('ai_consistency_check', 'AI Consistency Check'),

  /// AI risk assessment (summarizes defects and urgency)
  riskAssessment('ai_risk_assessment', 'AI Risk Assessment'),

  /// AI repair/maintenance recommendations
  recommendations('ai_recommendations', 'AI Recommendations'),

  /// AI photo auto-tagging
  photoTags('ai_photo_tags', 'AI Photo Tags'),

  /// AI condition rating assistant (suggests dropdown values)
  conditionAssistant('ai_condition_assistant', 'AI Condition Assistant'),

  /// AI-enhanced export (optional AI narrative in PDF/DOCX)
  aiEnhancedExport('ai_enhanced_export', 'AI Enhanced Export'),

  /// Local rule-based professional recommendations (RICS standards)
  professionalRecommendations(
      'professional_recommendations', 'Professional Recommendations'),

  /// AI professional narrative analysis (hybrid Layer 2 — Gemini-powered)
  aiProfessionalAnalysis(
      'ai_professional_analysis', 'AI Professional Analysis');

  const AiFeature(this.key, this.displayName);

  /// Storage key used in SharedPreferences.
  final String key;

  /// Human-readable name for settings UI.
  final String displayName;
}

/// Service for reading and writing AI feature flags.
///
/// Flags are stored in SharedPreferences for simplicity.
/// All flags default to enabled (true) — this is an opt-out system
/// so new features are available immediately.
///
/// In the future this could be extended to read from a backend
/// config endpoint for server-controlled rollout.
class FeatureFlagService {
  const FeatureFlagService(this._prefs);

  final SharedPreferences _prefs;
  static const _tag = 'FeatureFlags';
  static const _prefix = 'feature_flag_';

  /// Check if a specific AI feature is enabled.
  bool isEnabled(AiFeature feature) {
    return _prefs.getBool('$_prefix${feature.key}') ?? true;
  }

  /// Enable or disable a specific AI feature.
  Future<void> setEnabled(AiFeature feature, {required bool enabled}) async {
    await _prefs.setBool('$_prefix${feature.key}', enabled);
    AppLogger.d(_tag, '${feature.displayName}: ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if ALL AI features are disabled (master kill-switch).
  bool get allDisabled {
    return AiFeature.values.every((f) => !isEnabled(f));
  }

  /// Get a map of all feature flags and their current state.
  Map<AiFeature, bool> getAll() {
    return {for (final f in AiFeature.values) f: isEnabled(f)};
  }

  /// Disable all AI features (emergency kill-switch).
  Future<void> disableAll() async {
    for (final feature in AiFeature.values) {
      await _prefs.setBool('$_prefix${feature.key}', false);
    }
    AppLogger.w(_tag, 'All AI features disabled');
  }

  /// Reset all AI features to defaults (all enabled).
  Future<void> resetToDefaults() async {
    for (final feature in AiFeature.values) {
      await _prefs.remove('$_prefix${feature.key}');
    }
    AppLogger.d(_tag, 'All AI features reset to defaults');
  }
}
