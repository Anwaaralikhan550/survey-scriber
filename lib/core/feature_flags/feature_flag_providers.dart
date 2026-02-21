import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_service.dart';
import 'feature_flags.dart';

/// Provider for the feature flag service.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService(StorageService.prefs);
});

/// Provider for checking if a specific AI feature is enabled.
/// Usage: ref.watch(aiFeatureEnabledProvider(AiFeature.reportNarrative))
final aiFeatureEnabledProvider = Provider.family<bool, AiFeature>((ref, feature) {
  return ref.watch(featureFlagServiceProvider).isEnabled(feature);
});

/// Provider for getting all feature flag states.
final allAiFeaturesProvider = Provider<Map<AiFeature, bool>>((ref) {
  return ref.watch(featureFlagServiceProvider).getAll();
});
