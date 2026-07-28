import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - other joinery and finishes parity', () {
    const phraseTexts = <String, String>{
      '{E_OTHER_JOINERY_AND_FINISHES}::{NOT_INSPECTED}': 'not-inspected',
      '{E_OTHER_JOINERY_AND_FINISHES}::{ABOUT_OTHER_JOINERY_AND_FINISHES}':
          'about={OJAF_ABOUT_EXTERNAL_WORK_INCLUDES}/{OJAF_ABOUT_MATERIAL}',
      '{E_OTHER_JOINERY_AND_FINISHES}::{CONDITION}': 'condition={OJAF_CONDITION}',
      '{E_OTHER_JOINERY_AND_FINISHES}::{CONTAIN_ASBESTOS}': 'asbestos-note',
      '{E_OTHER_JOINERY_AND_FINISHES}::{REPAIR_SOON}':
          'repair loc={OJAF_REPAIR_LOCATION};item={OJAF_REPAIR_ITEM};def={OJAF_REPAIR_DEFECT}',
      '{E_OTHER_JOINERY_AND_FINISHES}::{REPAIR_SAFETY_HAZARD}': 'safety-hazard',
      '{E_OTHER_JOINERY_AND_FINISHES}::{REPAIR_REDECORATE}': 'timber-weathering-note',
      '{E_OTHER_JOINERY_AND_FINISHES}::{CONDITION_RATING}':
          'rating={OJAF_CONDITION_RATING}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about screen emits items+material and stays empty without data', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_about_joinery_and_finishes',
        {
          'cb_facias': 'true',
          'cb_soffits': 'true',
          'cb_timber': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(),
          contains('about=facias and soffits/timber'));

      final empty = engine.buildPhrases(
        'activity_outside_property_other_about_joinery_and_finishes',
        const <String, String>{},
      );
      expect(empty, isEmpty);
    });

    test('about screen appends redecorate note when checked', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_about_joinery_and_finishes',
        {
          'cb_facias': 'true',
          'cb_timber': 'true',
          'cb_Redecorate': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('timber-weathering-note'));
    });

    test('about screen appends asbestos note when checked', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_about_joinery_and_finishes',
        {
          'cb_bargeboards': 'true',
          'cb_slates': 'true',
          'cb_open_runoffs': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('asbestos-note'));
    });

    test(
        'condition screen emits the numeric condition-rating template (Phase 2G-mini fix)',
        () {
      // This screen's actv_condition field is a numeric 1/2/3 dropdown in
      // the real tree, not a descriptive word - it was previously routed
      // to the descriptive _otherJoineryCondition handler, producing
      // nonsense like "appear in 2 condition". Fixed to route to the same
      // numeric-rating handler the main E8 screen correctly uses.
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_finishes_condition',
        {'actv_condition': '2'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('rating=2'));
    });

    test('condition screen accepts the misspelled tree variant id', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_fininshes_condition',
        {'actv_condition': '3'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('rating=3'));
    });

    test('repair screen emits repair text and safety-hazard addendum', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_and_finishes_repairs',
        {
          'cb_facias': 'true',
          'cb_main_building_86': 'true',
          'cb_rotted': 'true',
          'cb_safety_hazard': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('loc=main building'));
      expect(all, contains('item=facias'));
      expect(all, contains('def=rotted'));
      expect(all, contains('safety-hazard'));
    });

    test('not inspected screen is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_outside_property_other_joinery_finishes_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_outside_property_other_joinery_finishes_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('main screen emits about content AND the condition rating', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_and_finishes_main_screen',
        {
          'cb_facias': 'true',
          'cb_timber': 'true',
          'actv_condition': '2',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('about=facias/timber'));
      expect(all, contains('rating=2'));
    });

    test('main screen emits nothing extra when rating is unanswered', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_joinery_and_finishes_main_screen',
        {
          'cb_facias': 'true',
          'cb_timber': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), isNot(contains('rating=')));
    });
  });
}
