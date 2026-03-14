import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - conservatory/porch routing', () {
    const phraseTexts = <String, String>{
      '{E_CONSERVATORY_PORCHES}::{CP_CONDITION}': 'cp-condition={CP_CONDITION}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_CONDITION}':
          'porch-condition={CP_CONDITION_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_FLOOR}': 'cp-floor={CP_FLOOR_COVERED_IN}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_FLOOR}':
          'porch-floor={CP_FLOOR_COVERED_IN_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_OPEN_TO_BUILDING}': 'cp-open-to-building',
      '{E_CONSERVATORY_PORCHES}::{PORCH_OPEN_TO_BUILDING}':
          'porch-open-to-building',
      '{E_CONSERVATORY_PORCHES}::{CP_POOR_CONDITION}': 'cp-poor-condition',
      '{E_CONSERVATORY_PORCHES}::{PORCH_POOR_CONDITION}':
          'porch-poor-condition',
      '{E_CONSERVATORY_PORCHES}::{CP_SAFETY_GLASS_RATING_NOTED}': 'cp-sg-noted',
      '{E_CONSERVATORY_PORCHES}::{PORCH_SAFETY_GLASS_RATING_NOTED}':
          'porch-sg-noted',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('condition base screen uses conservatory template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_porch_condition',
        {'actv_condition': 'Reasonable'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('cp-condition=reasonable'));
    });

    test('condition suffix screen uses porch template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_porch_condition__condition',
        {'actv_condition': 'Reasonable'},
      );

      expect(phrases, hasLength(1));
      expect(
        phrases.first.toLowerCase(),
        contains('porch-condition=reasonable'),
      );
    });

    test('floor suffix screen stays porch even with stale selector', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_floor__floor',
        {
          'cb_tiles': 'true',
          'actv_conservatory_porch': 'Conservatory',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('porch-floor=tiles'));
    });

    test('floor base screen ignores selector and stays conservatory', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_floor',
        {
          'cb_tiles': 'true',
          'actv_conservatory_porch': 'Porch',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('cp-floor=tiles'));
    });

    test('open-to-building suffix screen ignores stale selector', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_porch_open_to_building__open_to_building',
        {
          'cb_not_inspected': 'true',
          'actv_condition': 'Conservatory',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('porch-open-to-building'));
    });

    test('poor-condition suffix screen ignores stale selector', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_porch_poor_condition__poor_condition',
        {
          'cb_not_inspected': 'true',
          'actv_condition': 'Conservatory',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('porch-poor-condition'));
    });

    test('safety-glass suffix screen ignores stale selector', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating',
        {
          'actv_status': 'Noted',
          'actv_condition': 'Conservatory',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('porch-sg-noted'));
    });
  });
}
