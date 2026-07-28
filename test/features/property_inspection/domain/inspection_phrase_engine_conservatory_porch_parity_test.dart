import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - conservatory/porch parity', () {
    const phraseTexts = <String, String>{
      '{E_CONSERVATORY_PORCHES}::{LOCATION_CONSTRUCTION}':
          'desc-conservatory={CP_LC_LOCATION}/{CP_LC_CONSTRUCTION}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_LOCATION_CONSTRUCTION}':
          'desc-porch={CP_LC_LOCATION_PORCH}/{CP_LC_CONSTRUCTION_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_ROOF}': 'roof-conservatory={CP_ROOF_MATERIAL}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_ROOF}': 'roof-porch={CP_ROOF_MATERIAL_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_ROOF_FLOOR_ABOVE}': 'roof-floor-above-conservatory',
      '{E_CONSERVATORY_PORCHES}::{PORCH_ROOF_FLOOR_ABOVE}': 'roof-floor-above-porch',
      '{E_CONSERVATORY_PORCHES}::{CP_DOORS}':
          'doors-conservatory={CP_DOORS_INCORPORATES}/{CP_DOORS_GLAZZING}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_DOORS}':
          'doors-porch={CP_DOORS_INCORPORATES_PORCH}/{CP_DOORS_GLAZZING_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_DOORS_INCORPORATES_IF_DOUBLE_SELECTED}':
          'fensa-conservatory',
      '{E_CONSERVATORY_PORCHES}::{PORCH_DOORS_INCORPORATES_IF_DOUBLE_SELECTED}':
          'fensa-porch',
      '{E_CONSERVATORY_PORCHES}::{CP_WINDOWS}':
          'windows-conservatory={CP_WINDOWS_INCORPORATES}/{CP_WINDOWS_GLAZZING}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_WINDOWS}':
          'windows-porch={CP_WINDOWS_INCORPORATES_PORCH}/{CP_WINDOWS_GLAZZING_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_FLOOR}': 'floor-conservatory={CP_FLOOR_COVERED_IN}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_FLOOR}': 'floor-porch={CP_FLOOR_COVERED_IN_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_CONDITION}': 'condition-conservatory={CP_CONDITION}',
      '{E_CONSERVATORY_PORCHES}::{PORCH_CONDITION}': 'condition-porch={CP_CONDITION_PORCH}',
      '{E_CONSERVATORY_PORCHES}::{CP_SAFETY_GLASS_RATING_NOTED}': 'sg-noted-conservatory',
      '{E_CONSERVATORY_PORCHES}::{CP_SAFETY_GLASS_RATING_NO_SG_RATING}':
          'sg-missing-conservatory',
      '{E_CONSERVATORY_PORCHES}::{PORCH_SAFETY_GLASS_RATING_NOTED}': 'sg-noted-porch',
      '{E_CONSERVATORY_PORCHES}::{PORCH_SAFETY_GLASS_RATING_NO_SG_RATING}':
          'sg-missing-porch',
      '{E_CONSERVATORY_PORCHES}::{ROOF_FLASHING_WITH_WALL}':
          'no-defects junction={ROOF_FLASHING}/{CONDITION}',
      '{E_CONSERVATORY_PORCHES}::{MAIN_BUILDING_JUNCTIONS_DEFECTS}':
          'defects-noted junction={ROOF_FLASHING}/{CONDITION}',
      '{E_CONSERVATORY_PORCHES}::{DOOR_REPAIR}':
          '{CP_REPAIR_SOON}\n\n{CP_REPAIR_NOW}',
      '{E_CONSERVATORY_PORCHES}::{WALLS_REPAIR}':
          '{CP_REPAIR_SOON}\n\n{CP_REPAIR_NOW}',
      '{E_CONSERVATORY_PORCHES}::{CP_REPAIR_SOON}':
          'loc={CP_LOCATION};isare={IS_ARE};def={CP_DEFECT_SOON};soon',
      '{E_CONSERVATORY_PORCHES}::{CP_REPAIR_NOW}':
          'loc={CP_LOCATION};isare={IS_ARE};def={CP_DEFECT_NOW};now',
      '{E_CONSERVATORY_PORCHES}::{CP_DEFECT_IF_IN_DISREPAIR}': 'disrepair-addendum',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('conservatory location/construction uses unsuffixed template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_location_construction',
        {
          'actv_location': 'Rear',
          'cb_brick_walls': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('desc-conservatory=rear/brick walls'));
    });

    test('porch location/construction uses porch-suffixed template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_location_construction__location_and_construction',
        {
          'actv_location': 'Front',
          'cb_pvc_double_glazed_sections': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(),
          contains('desc-porch=front/pvc double glazed sections'));
    });

    test('conservatory roof with floor-above and no material routes to floor-above template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_roof',
        {'cb_floor_above': 'true'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('roof-floor-above-conservatory'));
    });

    test('porch doors emit FENSA note when double glazing selected', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_doors__doors',
        {
          'cb_double': 'true',
          'cb_pvc': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('doors-porch=double/pvc'));
      expect(all, contains('fensa-porch'));
    });

    test('conservatory windows use conservatory template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_windows',
        {
          'cb_single': 'true',
          'cb_timber': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('windows-conservatory=single/timber'));
    });

    test('porch floor uses porch template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_floor__floor',
        {'cb_tiles': 'true'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('floor-porch=tiles'));
    });

    test('conservatory condition uses conservatory template', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_porch_condition',
        {'actv_condition': 'Reasonable'},
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('condition-conservatory=reasonable'));
    });

    test('porch safety glass rating routes to porch templates', () {
      final noted = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating',
        {'actv_status': 'Noted'},
      );
      expect(noted, hasLength(1));
      expect(noted.first.toLowerCase(), contains('sg-noted-porch'));

      final missing = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating',
        {'actv_status': 'No SG Rating'},
      );
      expect(missing, hasLength(1));
      expect(missing.first.toLowerCase(), contains('sg-missing-porch'));
    });

    test('reasonable flashing condition routes to no-defects junction template', () {
      final phrases = engine.buildPhrases(
        'outside_property_conservatory_porch_flashing_layout',
        {
          'cb_lead': 'true',
          'actv_condition': 'Reasonable',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('no-defects junction=lead/reasonable'));
    });

    test('unsatisfactory and poor flashing condition routes to defects-noted junction template', () {
      final phrases = engine.buildPhrases(
        'outside_property_conservatory_porch_flashing_layout',
        {
          'cb_tiles': 'true',
          'actv_condition': 'Unsatisfactory and Poor',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('defects-noted junction=tiles/unsatisfactory and poor'));
    });

    test('repair now adds the comprehensive-repair disrepair addendum', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_repairs',
        {
          'actv_condition': 'Repair now',
          'cb_damaged_22': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains(';now'));
      expect(all, contains('disrepair-addendum'));
    });

    test('repair soon does not add the disrepair addendum', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_repairs',
        {
          'actv_condition': 'Repair soon',
          'cb_damaged': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains(';soon'));
      expect(all, isNot(contains('disrepair-addendum')));
    });

    test('walls repair screen routes to the walls repair wrapper', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_conservatory_porch_repairs__walls',
        {
          'actv_condition': 'Repair soon',
          'cb_cracked': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('loc=walls'));
    });
  });
}
