import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F5 Fireplaces, Chimney Breasts and Flues parity', () {
    const phraseTexts = <String, String>{
      '{F_FIREPLACES_AND_CHIMNEYS_NOT_INSPECTED}::{NOT_APPLICABLE}':
          'not-applicable',
      '{F_FIREPLACES_AND_CHIMNEYS_NOT_INSPECTED}::{NO_STACK_FIRE_PLACE}':
          'no-stack-fireplace',
      '{F_FIREPLACES_AND_CHIMNEYS}::{AN_OPEN_FIRE_LOCATION}':
          'open-fire-loc={FAC_FP_AOF_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{AN_OPEN_FIRE_CONDITION}':
          'open-fire-condition={FAC_FP_AOF_CONDITION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{GAS_FIRE_LOCATION}':
          'gas-fire-loc={FAC_FP_GF_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{GAS_FIRE_CONDITION}':
          'gas-fire-condition={FAC_FP_GF_CONDITION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{GAS_FIRE_NOT_TESTED}': 'gas-not-tested',
      '{F_FIREPLACES_AND_CHIMNEYS}::{WOOD_BURNING_STOVE_LOCATION}':
          'wbs-loc={FAC_FP_WBS_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{WOOD_BURNING_STOVE_CONDITION}':
          'wbs-condition={FAC_FP_WBS_CONDITION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{ELECTRIC_FIRE_LOCATION}':
          'electric-loc={FAC_FP_EF_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{ELECTRIC_FIRE_CONDITION}':
          'electric-condition={FAC_FP_EF_CONDITION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{OTHER_LOCATION}':
          'other-loc={FAC_FP_OTH_LOCATION}/{FAC_FP_OTH_NAME}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{OTHER_CONDITION}':
          'other-condition={FAC_FP_OTH_CONDITION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{DAMAGED_GATE}':
          'damaged-grate=floor:{FACR_DG_FLOOR_LOCATION}/loc:{FACR_DG_FIREPLACE_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{DAMAGED_SURROUND}':
          'damaged-surround=floor:{FACR_DS_FLOOR_LOCATION}/loc:{FACR_DS_FIREPLACE_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{BLOCKED_FIREPLACE_UNVENTED}':
          'blocked-unvented=floor:{FAC_BF_UNVENTED_FLOOR_LOCATION}/loc:{FAC_BF_UNVENTED_FIREPLACE_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{BLOCKED_FIREPLACE_VENTED}':
          'blocked-vented=floor:{FAC_BF_VENTED_FLOOR_LOCATION}/loc:{FAC_BF_VENTED_FIREPLACE_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{REMOVED_CB_OK}':
          'removed-cb-ok=floor:{FAC_RCB_OK_FLOOR_LOCATION}/loc:{FAC_RCB_OK_CHIMNEY_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{REMOVED_CB_PROBLEM_NOTED}':
          'removed-cb-problem=floor:{FAC_RCB_PROBLEM_FLOOR_LOCATION}/loc:{FAC_RCB_PROBLEM_CHIMNEY_LOCATION}/defect:{FAC_RCB_PROBLEM_DEFECT}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{BOILER_FLUE_OK}':
          'boiler-flue-ok=loc:{FAC_BOF_LOCATION}/discharge:{FAC_BOF_FLUE_DISCHARGE}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{BOILER_FLUE_OBSTRUCTED}':
          'boiler-flue-obstructed=loc:{FAC_BOF_LOCATION}/discharge:{FAC_BOF_FLUE_DISCHARGE}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{REPAIR_FIREPLACES_SOON}':
          'repair-soon=floor:{FACR_RF_SOON_FLOOR_LOCATION}/loc:{FACR_RF_SOON_FIREPLACE_LOCATION}/defect:{FACR_RF_SOON_DEFECT}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{REPAIR_FIREPLACES_NOW}':
          'repair-now=floor:{FACR_RF_NOW_FLOOR_LOCATION}/loc:{FACR_RF_NOW_FIREPLACE_LOCATION}/defect:{FACR_RF_NOW_DEFECT}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{FLUES_NOT_INSPECTED}': 'flues-not-inspected',
      '{F_FIREPLACES_AND_CHIMNEYS}::{NOT_INSPECTED}':
          '{NOT_APPLICABLE}<br />\\r\\n<br />\\r\\n{NO_STACK_FIRE_PLACE}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{CONDITION_RATING}':
          'rating={FAC_CONDITION_RATING}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{NOTES}': 'notes={FAC_NOTES}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('open fire resolves location and condition as separate phrases', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places',
        {
          'cb_lounge': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('open-fire-loc=lounge'));
      expect(all, contains('open-fire-condition=reasonable'));
    });

    test('gas fire appends the not-tested addendum', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places__gas_fire',
        {
          'cb_kitchen': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('gas-fire-loc=kitchen'));
      expect(all, contains('gas-not-tested'));
    });

    test('wood burning stove resolves location and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places__wood_burning_stove',
        {
          'cb_lounge': 'true',
          'actv_condition': 'Good',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('wbs-loc=lounge'));
      expect(all, contains('wbs-condition=good'));
    });

    test('other fireplace resolves location, custom name and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places__other',
        {
          'cb_lounge': 'true',
          'et_other_405': 'Victorian range',
          'actv_condition': 'Fair',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('other-loc=lounge/victorian range'));
      expect(all, contains('other-condition=fair'));
    });

    test('repair fireplaces soon vs now resolve floor, location and defect', () {
      final soon = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_fire_place',
        {
          'actv_status': 'Repair soon',
          'cb_ground': 'true',
          'cb_lounge': 'true',
          'cb_damaged': 'true',
        },
      );
      expect(soon.single.toLowerCase(),
          contains('repair-soon=floor:ground/loc:lounge/defect:damaged'));

      final now = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_fire_place',
        {
          'actv_status': 'Repair now',
          'cb_ground_76': 'true',
          'cb_lounge_48': 'true',
          'cb_badly_damaged_27': 'true',
        },
      );
      expect(
          now.single.toLowerCase(),
          contains(
              'repair-now=floor:ground/loc:lounge/defect:badly damaged'));
    });

    test('blocked fireplace unvented vs vented', () {
      final unvented = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_blocked_fireplace',
        {
          'actv_status': 'Unvented',
          'cb_ground': 'true',
          'cb_lounge': 'true',
        },
      );
      expect(unvented.single.toLowerCase(), contains('blocked-unvented'));
    });

    test('removed chimney breast - ok vs problem noted', () {
      final ok = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_removed_cb',
        {
          'actv_condition': 'OK',
          'cb_ground': 'true',
          'cb_lounge': 'true',
        },
      );
      expect(ok.single.toLowerCase(), contains('removed-cb-ok'));

      final problem = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_removed_cb',
        {
          'actv_condition': 'Problem noted',
          'cb_ground_75': 'true',
          'cb_lounge_61': 'true',
          'cb_damaged': 'true',
        },
      );
      expect(problem.single.toLowerCase(), contains('removed-cb-problem'));
    });

    test('boiler flue ok vs obstructed', () {
      final ok = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_boiler_flue',
        {
          'actv_condition': 'OK',
          'cb_ground': 'true',
          'actv_flue_discharges_through': 'external wall',
        },
      );
      expect(ok.single.toLowerCase(), contains('boiler-flue-ok'));

      final obstructed = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_boiler_flue',
        {
          'actv_condition': 'Obstructed',
          'cb_ground': 'true',
          'actv_flue_discharges_through': 'external wall',
        },
      );
      expect(obstructed.single.toLowerCase(), contains('boiler-flue-obstructed'));
    });

    test('not inspected combines not-applicable and no-stack sub-phrases', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places_not_inspected',
        {'cb_flues_not_inspected': 'true', 'cb_No_Stack': 'true'},
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('not-applicable'));
      expect(all, contains('no-stack-fireplace'));
    });
  });
}
