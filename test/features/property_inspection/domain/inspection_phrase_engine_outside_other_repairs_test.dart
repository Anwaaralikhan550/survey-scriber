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
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('decorations location does not accept cb_other_344 as location', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_decorations',
        {
          'cb_other_344': 'true',
          'cb_perished': 'true',
          'et_other_639': 'custom defect',
        },
      );

      expect(phrases, isEmpty);
    });

    test('decorations uses typed other value for defect only', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_decorations',
        {
          'cb_stairway': 'true',
          'cb_other_344': 'true',
          'et_other_639': 'custom defect',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('location=stairway'));
      expect(phrases.first.toLowerCase(), contains('defect=custom defect'));
    });

    test('drains uses legacy fallback "poorly drained" for other option', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_drains',
        {
          'cb_other_642': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('poorly drained'));
    });

    test('steps/landing uses legacy fallback "rusted" for other option', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_steps_landing',
        {
          'actv_location': 'front steps',
          'cb_other_1046': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('rusted'));
    });

    test('steps/landing accepts legacy llMainContainer location', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_steps_landing',
        {
          'llMainContainer': 'front steps',
          'cb_cracked': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('location=front steps'));
    });

    test('handrails ignores non-legacy duplicate checkbox ids', () {
      final ignoredOnly = engine.buildPhrases(
        'activity_outside_property_other_repairs_hand_rails',
        {
          'cb_not_strong_enough': 'true',
        },
      );
      expect(ignoredOnly, isEmpty);

      final legacyOnly = engine.buildPhrases(
        'activity_outside_property_other_repairs_hand_rails',
        {
          'cb_not_strong_enough_51': 'true',
        },
      );
      expect(legacyOnly, hasLength(1));
      expect(legacyOnly.first.toLowerCase(), contains('not strong enough'));
    });

    test('roof defect wording keeps legacy "is ..." tokens', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_roof',
        {
          'cb_is_in_disrepair': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('is in disrepair'));
    });

    test('communal area treats "Not inspected" as not inspected', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_communal_area',
        {
          'actv_status': 'Not inspected',
          'cb_the_area_is_not_accessible': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('not inspected'));
      expect(phrases.first.toLowerCase(), contains('not accessible'));
    });

    test('communal area accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_communal_area',
        {
          'llMainContainer': 'Not inspected',
          'cb_the_area_is_not_accessible': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('not inspected'));
    });

    test('other handrails ignores non-legacy concrete/extra fields', () {
      final ignored = engine.buildPhrases(
        'activity_outside_property_other_handrails',
        {
          'cb_concrete': 'true',
        },
      );
      expect(ignored, isEmpty);

      final legacy = engine.buildPhrases(
        'activity_outside_property_other_handrails',
        {
          'cb_bricks': 'true',
        },
      );
      expect(legacy, hasLength(1));
      expect(legacy.first.toLowerCase(), contains('type=steel'));
    });

    test('other handrails accepts legacy llMainContainer area', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_handrails',
        {
          'llMainContainer': 'balcony',
          'cb_bricks': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('area=balcony'));
    });

    test('other floors accepts legacy llMainContainer area', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_floors',
        {
          'llMainContainer': 'carport',
          'cb_timber': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('area=carport'));
      expect(phrases.first.toLowerCase(), contains('floors=concrete'));
    });

    test('other roof accepts legacy llMainContainer roof type', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_other_roof',
        {
          'llMainContainer': 'pitched',
          'actv_roof_location': 'rear',
          'actv_covered_in': 'tiles',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('roof=pitched'));
    });

    test('other condition accepts legacy llMainContainer value', () {
      final phrases = engine.buildPhrases(
        'activity_out_side_other_external_area_condition',
        {
          'llMainContainer': 'good',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('condition=good'));
    });

    test('joinery asbestos phrase supports legacy checkbox id alias', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_about_joinery_and_finishes',
        {
          'cb_facias': 'true',
          'cb_timber': 'true',
          'cb_Is_Contain_Asbestos': 'true',
        },
      );

      expect(phrases, hasLength(2));
      expect(phrases[1].toLowerCase(), contains('contains asbestos'));
    });

    test('joinery asbestos phrase supports current checkbox id', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_about_joinery_and_finishes',
        {
          'cb_facias': 'true',
          'cb_timber': 'true',
          'cb_open_runoffs': 'true',
        },
      );

      expect(phrases, hasLength(2));
      expect(phrases[1].toLowerCase(), contains('contains asbestos'));
    });

    test('joinery condition accepts legacy llMainContainer value', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_finishes_condition',
        {
          'llMainContainer': 'good',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('joinery condition=good'));
    });

    test('joinery condition typo screen id is also supported', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_fininshes_condition',
        {
          'llMainContainer': 'good',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('joinery condition=good'));
    });
  });
}
