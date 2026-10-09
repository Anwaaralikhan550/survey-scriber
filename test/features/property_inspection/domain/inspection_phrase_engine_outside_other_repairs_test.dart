import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - outside other repairs parity', () {
    const phraseTexts = <String, String>{
      '{OTHER_REPAIR}::{OTHER_REPAIR_DRAINS}':
          'Area={OTHER_EXTERNAL_AREA}; Defect={DRAINS_DEFECT}.',
      '{OTHER_REPAIR}::{OTHER_REPAIR_STEPS_LANDING}':
          'Location={STEPS_LANDING}; Defect={STEPS_LANDING_DEFECT}.',
      '{OTHER_REPAIR}::{OTHER_REPAIR_PERISHED_DECORATIONS}':
          'Location={PERISHED_DECORATIONS_LOCATION}; Defect={PERISHED_DECORATIONS_DEFECT}.',
      '{OTHER_REPAIR}::{OTHER_REPAIR_HANDRAILS}':
          'Area={OTHER_EXTERNAL_AREA}; Defect={HANDRAILS_DEFECT}.',
      '{OTHER_REPAIR}::{OTHER_REPAIR_ROOF}':
          'Area={OTHER_EXTERNAL_AREA}; Defect={OTHER_REPAIR_ROOF_DEFECT}.',
      '{E_OTHER}::{COMMUNAL_AREA_INSPECTED}':
          'Communal inspected: {OTHER_COMMUNAL_AREA_EXTERNAL}.',
      '{E_OTHER}::{COMMUNAL_AREA_NOT_INSPECTED}':
          'Communal not inspected because {OTHER_COMMUNAL_AREA_BECAUSE}.',
      '{E_OTHER}::{COMMUNAL_AREA_CONDITION}':
          'Communal condition: {OTHER_COMMUNAL_AREA_CONDITION}.',
      '{OTHER_EXTERNAL_AREA}::{OTHER_HANDRAILS}':
          'Area={OTHER_EXTERNAL_AREA}; Type={HANDRAILS_TYPE}.',
      '{OTHER_EXTERNAL_AREA}::{OTHER_FLOOR}':
          'Area={OTHER_EXTERNAL_AREA}; Floors={FLOORS}.',
      '{OTHER_EXTERNAL_AREA}::{OTHER_ROOF}':
          'Area={OTHER_EXTERNAL_AREA}; Roof={ROOF_TYPE}; Covered={ROOF_COVERED_IN}.',
      '{OTHER_EXTERNAL_AREA}::{OTHER_CONDITION}':
          'Condition={OTHER_CONDITION}.',
      '{E_OTHER_JOINERY_AND_FINISHES}::{ABOUT_OTHER_JOINERY_AND_FINISHES}':
          'About item={OJAF_ABOUT_EXTERNAL_WORK_INCLUDES}; material={OJAF_ABOUT_MATERIAL}.',
      '{E_OTHER_JOINERY_AND_FINISHES}::{CONDITION}':
          'Joinery condition={OJAF_CONDITION}.',
      '{E_OTHER_JOINERY_AND_FINISHES}::{CONTAIN_ASBESTOS}':
          'Contains asbestos.',
      '{E_OTHER_JOINERY_AND_FINISHES}::{CONDITION_RATING}':
          'Rating={OJAF_CONDITION_RATING}.',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test(
        'joinery condition accepts legacy llMainContainer value (Phase 2G-mini fix)',
        () {
      // Routed to the numeric-rating handler now (Phase 2G-mini) instead
      // of the descriptive handler this screen never actually matched -
      // the llMainContainer fallback is preserved for old persisted data.
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_finishes_condition',
        {
          'llMainContainer': 'good',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('rating=good'));
    });

    test('joinery condition typo screen id is also supported', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_fininshes_condition',
        {
          'llMainContainer': 'good',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('rating=good'));
    });
  });
}
