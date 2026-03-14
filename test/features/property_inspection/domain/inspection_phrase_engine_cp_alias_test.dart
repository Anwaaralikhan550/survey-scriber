import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - conservatory/porch alias compatibility', () {
    const phraseTexts = <String, String>{
      '{E_CONSERVATORY_PORCHES}::{CP_SAFETY_GLASS_RATING_NOTED}':
          'cp-sg-noted',
      '{E_CONSERVATORY_PORCHES}::{CP_SAFETY_GLASS_RATING_NO_SG_RATING}':
          'cp-sg-missing',
      '{E_CONSERVATORY_PORCHES}::{CP_CONDITION}':
          'cp-condition={CP_CONDITION}',
      '{E_CONSERVATORY_PORCHES}::{WALLS_REPAIR}':
          '{CP_REPAIR_SOON}\n\n{CP_REPAIR_NOW}',
      '{E_CONSERVATORY_PORCHES}::{CP_REPAIR_SOON}':
          'cp-repair-soon {CP_LOCATION} {CP_DEFECT_SOON}',
      '{E_CONSERVATORY_PORCHES}::{CP_REPAIR_NOW}':
          'cp-repair-now {CP_LOCATION} {CP_DEFECT_NOW}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('safety glass accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_safety_glass_rating',
        {
          'llMainContainer': 'Noted',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('cp-sg-noted'));
    });

    test('porch condition accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_porch_condition',
        {
          'llMainContainer': 'Reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('cp-condition=reasonable'));
    });

    test('repairs accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_repairs__walls',
        {
          'llMainContainer': 'Repair soon',
          'cb_cracked': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('cp-repair-soon'));
    });
  });
}
