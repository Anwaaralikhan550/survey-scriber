import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - E9 Other (external structures) parity', () {
    const phraseTexts = <String, String>{
      '{E_OTHER}::{OTHER_NOT_APPLICABLE}': 'not-applicable',
      '{E_OTHER}::{COMMUNAL_AREA_INSPECTED}':
          'communal=inspected/{OTHER_COMMUNAL_AREA_EXTERNAL}',
      '{E_OTHER}::{COMMUNAL_AREA_NOT_INSPECTED}':
          'communal=not-inspected/{OTHER_COMMUNAL_AREA_BECAUSE}',
      '{E_OTHER}::{COMMUNAL_AREA_CONDITION}':
          'communal-condition={OTHER_COMMUNAL_AREA_CONDITION}',
      '{OTHER_EXTERNAL_AREA}::{OTHER_CONSTRUCTION}':
          'construction={OTHER_EXTERNAL_AREA}/{CONSTRUCTION}',
      '{OTHER_EXTERNAL_AREA}::{OTHER_ROOF}':
          'roof={OTHER_EXTERNAL_AREA}/{ROOF_TYPE}/{ROOF_COVERED_IN}',
      '{OTHER_EXTERNAL_AREA}::{OTHER_FLOOR}': 'floor={FLOORS}',
      '{OTHER_EXTERNAL_AREA}::{OTHER_DRAINS}':
          'drains={OTHER_EXTERNAL_AREA}/{DRAINS_LAID_WITH}',
      '{OTHER_EXTERNAL_AREA}::{OTHER_HANDRAILS}': 'handrails={HANDRAILS_TYPE}',
      '{OTHER_EXTERNAL_AREA}::{OTHER_CONDITION}':
          'condition={OTHER_CONDITION}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_WALL}':
          'repair-wall={OTHER_EXTERNAL_AREA}/{WALL_DEFECT}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_ROOF}':
          'repair-roof={OTHER_EXTERNAL_AREA}/{OTHER_REPAIR_ROOF_DEFECT}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_FLOOR}':
          'repair-floor={OTHER_EXTERNAL_AREA}/{FLOOR_DEFECT}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_DRAINS}':
          'repair-drains={OTHER_EXTERNAL_AREA}/{DRAINS_DEFECT}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_HANDRAILS}':
          'repair-handrails={OTHER_EXTERNAL_AREA}/{HANDRAILS_DEFECT}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_STEPS_LANDING}':
          'repair-steps={STEPS_LANDING}/{STEPS_LANDING_DEFECT}',
      '{OTHER_REPAIR}::{OTHER_REPAIR_PERISHED_DECORATIONS}':
          'repair-decorations={PERISHED_DECORATIONS_LOCATION}/{PERISHED_DECORATIONS_DEFECT}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('communal area inspected branch lists selected facilities', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_communal_area',
        {
          'actv_status': 'Inspected',
          'cb_cctv': 'true',
          'cb_car_park': 'true',
          'actv_condition': 'Reasonable',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('communal=inspected/cctv and car park'));
      expect(all, contains('communal-condition=reasonable'));
    });

    test('communal area not-inspected branch gives a reason', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_communal_area',
        {
          'actv_status': 'Not Inspected',
          'cb_of_limited_access': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('communal=not-inspected/of limited access'));
    });

    test('construction for the base (carport) screen uses the carport area', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_other_external',
        {'cb_timber': 'true'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('construction=carport/timber'));
    });

    test('construction for the __3 suffix screen resolves to balcony', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_other_external__3',
        {'cb_timber': 'true'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('construction=balcony/timber'));
    });

    test('roof screen emits roof text for the resolved area', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_other_roof__2',
        {
          'actv_roof_type': 'Pitched',
          'actv_covered_in': 'Tiles',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('roof=roof terrace/pitched/tiles'));
    });

    test('condition screen emits the (fixed) condition template', () {
      final phrases = engine.buildPhrases(
        'activity_out_side_other_external_area_condition__condition__4',
        {'actv_weather_condition': 'Reasonable'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('condition=reasonable'));
    });

    test('repair wall screen resolves area from screen suffix', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_wall__5',
        {'cb_cracked': 'true'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('repair-wall=external stairs/cracked'));
    });

    test('repair handrails screen emits the defect text', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_hand_rails__3',
        {'cb_partly_rotten_65': 'true'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('repair-handrails=balcony/partly rotten'));
    });

    test('repair steps/landing screen uses the typed location', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_other_repairs_steps_landing__2',
        {
          'actv_location': 'Roof terrace steps',
          'cb_cracked': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('repair-steps=roof terrace steps/split'));
    });

    test('not inspected screen is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_outside_property_other_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-applicable'));

      final unchecked = engine.buildPhrases(
        'activity_outside_property_other_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
