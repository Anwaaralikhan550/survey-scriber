import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - H1 Garage parity', () {
    const phraseTexts = <String, String>{
      '{H_GARAGE}::{CONDITION_RATING}': 'condition={GAR_REP_COND_RATING}',
      '{H_GARAGE}::{NOTES}': 'notes={GAR_REP_NOTES}',
      '{H_GARAGE}::{ABOUT_GARAGE_TYPE}':
          'about-type=no:{GAR_NO_OF_GAR}/type:{GAR_TYPE}',
      '{H_GARAGE}::{ABOUT_GARAGE_WALLS}': 'about-walls={GAR_WALL}',
      '{H_GARAGE}::{ABOUT_GARAGE_ROOF}':
          'about-roof=type:{GAR_ROOF_TYPE}/cover:{GAR_ROOF_COVER}/cond:{GAR_ROOF_COVER_COND}',
      '{H_GARAGE}::{IF_SINGLE_BRICK_SKIN_IS_SELECTED}': 'single-skin-note',
      '{H_GARAGE}::{IF_MINERAL_FELT_IS_SELECTED}': 'mineral-felt-note',
      '{H_GARAGE}::{IF_ASBESTOS_IS_SELECTED}': 'asbestos-note',
      '{H_GARAGE}::{ABOUT_GARAGE_CONVERTED}':
          'about-converted={GAR_COND_CONV_TO}',
      '{H_GARAGE}::{ABOUT_GARAGE_SHARED_ACCESS}': 'about-shared-access',
      '{H_GARAGE}::{NOT_INSPECTED}': 'not-inspected',
      '{H_GARAGE}::{NO_GARAGE}': 'no-garage',
      '{H_GARAGE}::{NOT_INSPECTED_ACCESS_KEYS}':
          'not-inspected-access-keys={GARAGE_KEY_SOURCE}',
      '{H_GARAGE}::{REPAIR_GARAGE_REPAIR_SOON}':
          'repair-soon={GAR_REP_SOON_DEFECT}',
      '{H_GARAGE}::{REPAIR_GARAGE_REPAIR_NOW}':
          'repair-now={GAR_REP_NOW_DEFECT}',
      '{H_GARAGE}::{REPAIR_ROOF_TIMBER}':
          'repair-roof-timber={GAR_REP_ROOF_TIMBER_DEF}',
      '{H_GARAGE}::{REPAIR_SAFETY_HAZARD}': 'safety-hazard',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen resolves condition rating and notes', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage_main_screen',
        {
          'android_material_design_spinner4': '2',
          'ar_etNote': 'roof recently re-felted',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('condition=2'));
      expect(all, contains('notes=roof recently re-felted'));
    });

    test('about-garage resolves type, walls and roof', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage',
        {
          'actv_no_of_garage': 'Single',
          'actv_type': 'Detached Garage',
          'cb_cavity_brick_wall': 'true',
          'cb_pitched': 'true',
          'cb_tiles': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('about-type=no:single/type:detached garage'));
      expect(all, contains('about-walls=cavity brick wall'));
      expect(all, contains('about-roof=type:pitched/cover:tiles/cond:reasonable'));
    });

    test('about-garage type sentence requires both no-of-garage and type', () {
      final missingType = engine.buildPhrases(
        'activity_grounds_garage',
        {'actv_no_of_garage': 'Single'},
      );
      expect(missingType.join(' '), isNot(contains('about-type=')));
    });

    test('about-garage roof sentence requires roof type, cover and condition',
        () {
      final missingCondition = engine.buildPhrases(
        'activity_grounds_garage',
        {'cb_pitched': 'true', 'cb_tiles': 'true'},
      );
      expect(missingCondition.join(' '), isNot(contains('about-roof=')));
    });

    test(
        'about-garage single-skin, mineral-felt and asbestos notes fire independently',
        () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage',
        {
          'cb_single_skin_brickwork': 'true',
          'cb_mineral_felt': 'true',
          'cb_corrugated_asbestos_sheets': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('single-skin-note'));
      expect(all, contains('mineral-felt-note'));
      expect(all, contains('asbestos-note'));
    });

    test('about-garage resolves converted-to and shared-access', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage',
        {
          'actv_converted_to': 'Office',
          'cb_shared_access': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('about-converted=office'));
      expect(all, contains('about-shared-access'));
    });

    test('not-inspected: no-garage checkbox always wins over generic not-inspected',
        () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage_not_inspected',
        {
          'cb_not_inspected_no_garage': 'true',
          'cb_not_inspected': 'true',
          'actv_access_keys_not_provided_by': 'Vendor',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first, 'no-garage');
    });

    test(
        'not-inspected: garage exists but not inspected, with an access-key source, resolves the access-keys phrase',
        () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage_not_inspected',
        {
          'cb_not_inspected': 'true',
          'actv_access_keys_not_provided_by': 'Estate agent',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('not-inspected-access-keys=estate agent'));
    });

    test(
        'not-inspected: garage exists but not inspected, with no source given, resolves the generic not-inspected phrase - not "no garage"',
        () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first, 'not-inspected');
      expect(phrases.first, isNot('no-garage'));
    });

    test('not-inspected with neither checkbox emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage_not_inspected',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('garage repair resolves soon and now defects independently', () {
      final soon = engine.buildPhrases(
        'activity_grounds_garage_garage_repair',
        {'cb_roof_is_leaking': 'true', 'cb_walls_are_cracked': 'true'},
      );
      expect(soon.single.toLowerCase(),
          contains('repair-soon=roof is leaking and walls are cracked'));

      final now = engine.buildPhrases(
        'activity_grounds_garage_garage_repair',
        {'cb_roof_is_badly_leaking': 'true'},
      );
      expect(now.single.toLowerCase(),
          contains('repair-now=roof is badly leaking'));
    });

    test('roof timber repair resolves defects', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_garage_roof_timber_repair',
        {'cb_is_rotten': 'true', 'cb_has_beetles_infestation': 'true'},
      );
      expect(
        phrases.single.toLowerCase(),
        contains('repair-roof-timber=is rotten and has beetle infestation'),
      );
    });

    test('safety hazard is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_grounds_garage_safety_hazard_repair',
        {'cb_is_safety_hazard': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first, 'safety-hazard');

      final unchecked = engine.buildPhrases(
        'activity_grounds_garage_safety_hazard_repair',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
