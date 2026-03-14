import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - roof covering alias compatibility', () {
    const phraseTexts = <String, String>{
      '{E_RC_WEATHER_CONDITION}::{CONDITION_WET}': 'roof-weather-wet',
      '{E_RC_WEATHER_CONDITION}::{CONDITION_DRY}': 'roof-weather-dry',
      '{E_ROOF_COVERING}::{E_RC_FLASHING}': 'roof-flashing {RC_FLASHING}',
      '{E_ROOF_COVERING}::{E_RC_FLASHING_CONDITION}':
          'roof-flashing-condition {RC_FLASHING_CONDITION}',
      '{E_RC_DEFLECTION_STATUS}::{DEFLECTION_SIGNIFICANT}':
          'deflection-significant {RC_DEFLECTION_STATUS_LOCATION}',
      '{E_ROOF_COVERING}::{E_RC_DEFLECTION_CAUSED_BY}':
          'deflection-caused-by {RC_DEFLECTION_CAUSED_BY_LOCATION} / {RC_DEFLECTION_CAUSED_BY_REASON}',
      '{E_ROOF_COVERING_ROOF_CONDITION}::{RC_ROOF_CONDITION_OK}':
          'roof-structure-ok',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('roof weather accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'outside_property_roof_covering_weather_layout',
        {
          'llMainContainer': 'Wet',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('roof-weather-wet'));
    });

    test('roof flashing accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'outside_property_roof_covering_flashing_layout',
        {
          'cb_lead': 'true',
          'llMainContainer': 'Reasonable',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('roof-flashing'));
      expect(all, contains('roof-flashing-condition reasonable'));
    });

    test('roof deflection accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'outside_property_roof_covering_deflection_layout',
        {
          'llMainContainer': 'Significant',
          'cb_front_45': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(
          phrases.join(' ').toLowerCase(), contains('deflection-significant'));
    });

    test('roof deflection emits caused-by phrase without status', () {
      final phrases = engine.buildPhrases(
        'outside_property_roof_covering_deflection_layout',
        {
          'cb_front_45': 'true',
          'cb_damaged_roof_timber': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('deflection-caused-by front / damaged roof timber'));
    });

    test('roof deflection supports legacy caused-by location ids', () {
      final phrases = engine.buildPhrases(
        'outside_property_roof_covering_deflection_layout',
        {
          'cb_front_77': 'true',
          'cb_heavy_replacement_covering': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all,
          contains('deflection-caused-by front / heavy replacement covering'));
    });

    test('roof structure accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'outside_property_roof_covering_roof_structure_layout',
        {
          'llMainContainer': 'OK',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('roof-structure-ok'));
    });
  });
}
