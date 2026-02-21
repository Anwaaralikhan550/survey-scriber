import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:survey_scriber/core/feature_flags/feature_flags.dart';

void main() {
  group('FeatureFlagService', () {
    late FeatureFlagService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = FeatureFlagService(prefs);
    });

    test('all features default to enabled', () {
      for (final feature in AiFeature.values) {
        expect(service.isEnabled(feature), isTrue,
            reason: '${feature.name} should default to enabled');
      }
    });

    test('disable then enable a feature', () async {
      await service.setEnabled(AiFeature.reportNarrative, enabled: false);
      expect(service.isEnabled(AiFeature.reportNarrative), isFalse);

      await service.setEnabled(AiFeature.reportNarrative, enabled: true);
      expect(service.isEnabled(AiFeature.reportNarrative), isTrue);
    });

    test('disableAll turns off every feature', () async {
      await service.disableAll();

      for (final feature in AiFeature.values) {
        expect(service.isEnabled(feature), isFalse,
            reason: '${feature.name} should be disabled');
      }
    });

    test('allDisabled reflects kill-switch state', () async {
      expect(service.allDisabled, isFalse);

      await service.disableAll();
      expect(service.allDisabled, isTrue);
    });

    test('resetToDefaults re-enables all features', () async {
      await service.disableAll();
      await service.resetToDefaults();

      for (final feature in AiFeature.values) {
        expect(service.isEnabled(feature), isTrue);
      }
    });

    test('getAll returns map of all features', () {
      final all = service.getAll();

      expect(all.length, AiFeature.values.length);
      for (final entry in all.entries) {
        expect(entry.value, isTrue);
      }
    });

    test('persists settings across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s1 = FeatureFlagService(prefs);

      await s1.setEnabled(AiFeature.consistencyCheck, enabled: false);

      // Simulate a new service reading from the same prefs
      final s2 = FeatureFlagService(prefs);
      expect(s2.isEnabled(AiFeature.consistencyCheck), isFalse);
    });

    test('individual features are independent', () async {
      await service.setEnabled(AiFeature.riskAssessment, enabled: false);

      expect(service.isEnabled(AiFeature.riskAssessment), isFalse);
      expect(service.isEnabled(AiFeature.reportNarrative), isTrue);
      expect(service.isEnabled(AiFeature.consistencyCheck), isTrue);
    });
  });

  group('AiFeature', () {
    test('has display names for all values', () {
      for (final feature in AiFeature.values) {
        expect(feature.displayName, isNotEmpty);
      }
    });

    test('has unique storage keys', () {
      final keys = AiFeature.values.map((f) => f.key).toSet();
      expect(keys.length, AiFeature.values.length);
    });

    test('has 9 features', () {
      expect(AiFeature.values.length, 9);
    });
  });
}
