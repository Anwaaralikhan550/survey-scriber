import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - inside llMainContainer parity', () {
    const phraseTexts = <String, String>{
      '{F_ROOF_STRUCTURE}::{WEATHER_CONDITION_WET}': 'roof-weather-wet',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TIMBER_STRUCTURE_NOW}':
          'roof-timber-now={RSR_RTS_STATUS_NOW_DEFECT}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_INSECT_INFESTATION_MINOR}':
          'roof-insect-minor',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_REMOVED_CHIMNEY_BREAST_NOT_INSPECTED}':
          'removed-cb-not-inspected',
      '{F_CEILINGS}::{REPAIRS_CELLINGS_NOW}':
          'ceilings-now={CER_RC_NOW_LOCATION}/{CER_RC_NOW_DEFECT}',
      '{F_FLOORS}::{FLOOR_REPAIR_NOW}':
          'floors-now={FLR_FR_NOW_LOCATION}/{FLR_FR_NOW_DEFECT}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{OTHER_LOCATION}':
          'fire-other={FAC_FP_OTH_NAME}@{FAC_FP_OTH_LOCATION}',
      '{F_FIREPLACES_AND_CHIMNEYS}::{REPAIR_FIREPLACES_NOW}':
          'fire-now={FACR_RF_NOW_FLOOR_LOCATION}/{FACR_RF_NOW_FIREPLACE_LOCATION}/{FACR_RF_NOW_DEFECT}',
      '{F_BUILT_IN_FITTINGS}::{REPAIR_FITTING_NOW}':
          'bif-now={BIFR_RF_NOW_LOCATION}/{BIFR_RF_NOW_DEFECT}',
      '{F_BATHROOM_FITTINGS}::{BATHROOM_FITTINGS_REPAIR_NOW}':
          'bath-now={BFR_NOW_LOCATION}/{BFR_NOW_DEFECT}/{IS_ARE}',
      '{F_BATHROOM_FITTINGS}::{EXTRACTOR_FAN_INSTALLED_OK}':
          'bath-fan-ok={BF_EF_EFI_OK_LOCATION}/{BF_EF_EFI_OK_TESTED}',
      '{F_BATHROOM_FITTINGS}::{EXTRACTOR_FAN_CONDENSATION_NOTED}':
          'bath-fan-no-installed={BF_EF_NEFI_LOCATION}',
      '{F_OTHER}::{COMMUNAL_AREA_NOT_INSPECTED}':
          'other-communal-not-inspected={OTH_CA_NOT_INSPECTED_BECAUSE}',
      '{F_OTHER}::{CELLAR_IN_USE}':
          'cellar-in-use={OTH_CELLAR_UA}/{OTH_CELLAR_UA_CONDITION}',
      '{F_OTHER}::{CELLAR_FLOODED}': 'cellar-flooded={OTH_CELLAR_FLOODED}',
      '{F_OTHER}::{OTHER_REPAIR_NOW}':
          'other-repair-now={OTHR_NOW_LOCATION}/{OTHR_NOW_DEFECT}',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_CONDENSATION_NONE}':
          'wap-condensation-none',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_WALL_REPAIR_NOW}':
          'wap-repair-now={WAPR_WALL_NOW_LOCATION}/{WAPR_WALL_NOW_DEFECT}',
      '{F_WOOD_WORK}::{WOOD_WORK_REPAIR_NOW}':
          'wood-repair-now={WWR_WWR_NOW_LOCATION}/{WWR_WWR_NOW_DEFECT}',
      '{F_WOOD_WORK}::{REPAIR_INFESTATION_MAJOR}':
          'wood-infest-major={WWR_INFESTATION_PART_OF}/{WWR_INFESTATION_LOCATION}',
      '{F_WOOD_WORK}::{REPAIR_INFESTATION_MINOR}':
          'wood-infest-minor={WWR_INFESTATION_PART_OF}/{WWR_INFESTATION_LOCATION}',
      '{F_WOOD_WORK}::{FITTED_BUILTIN_CUPBOARDS}':
          'wood-cupboards={WW_FBC_CONDITION}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('floors repair uses llMainContainer repair type', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_floors_repair_floor_repair',
        <String, String>{
          'llMainContainer': 'Now',
          'cb_lounge': 'true',
          'cb_uneven': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('floors-now='));
    });

    test('fireplaces other type reads llMainContainer', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places__other',
        <String, String>{
          'cb_lounge': 'true',
          'llMainContainer': 'Bioethanol',
        },
      );
      expect(
          phrases.join(' ').toLowerCase(), contains('fire-other=bioethanol'));
    });

    test('fireplaces other type requires a name before emitting location', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places__other',
        <String, String>{
          'cb_lounge': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      expect(phrases.join(' ').toLowerCase(), isNot(contains('fire-other=')));
    });

    test('fireplaces repair reads llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_fire_places_repair_fire_place',
        <String, String>{
          'llMainContainer': 'Repair now',
          'cb_ground_76': 'true',
          'cb_lounge_48': 'true',
          'cb_badly_damaged_27': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('fire-now='));
    });

    test('built-in repair reads llMainContainer repair type', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_built_in_fittings_repair_fittings',
        <String, String>{
          'llMainContainer': 'Repair now',
          'cb_kitchen': 'true',
          'cb_badly_worn_16': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('bif-now='));
    });

    test('bathroom repair reads llMainContainer repair type', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_repair',
        <String, String>{
          'llMainContainer': 'Repair now',
          'cb_bathtub_52': 'true',
          'cb_badly_leaking_38': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('bath-now='));
    });

    test('bathroom extractor fan ok matches legacy or-gating', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_extractor_fan',
        <String, String>{
          'actv_status': 'OK',
          'cb_was_switched_on_and_it_was_35': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('bath-fan-ok=/'));
    });

    test('bathroom extractor fan no-installed uses exact legacy status', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_bathroom_fittings_extractor_fan__no_extractor_fan_installed',
        <String, String>{
          'actv_status_new': 'Condensation noted',
          'cb_bathroom_56_wef': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('bath-fan-no-installed=bathroom'));
    });

    test('inside other screens read llMainContainer values', () {
      final communal = engine.buildPhrases(
        'activity_in_side_property_other_communal_area',
        <String, String>{
          'llMainContainer': 'Not inspected',
          'cb_the_door_is_locked': 'true',
        },
      );
      expect(communal.join(' ').toLowerCase(),
          contains('other-communal-not-inspected='));

      final usedAs = engine.buildPhrases(
        'activity_inside_property_other_celler_inspected',
        <String, String>{
          'llMainContainer': 'storage',
          'actv_condition': 'good',
        },
      );
      expect(usedAs.join(' ').toLowerCase(), contains('cellar-in-use=storage'));

      final flooded = engine.buildPhrases(
        'activity_inside_property_other_celler_flooded',
        <String, String>{'llMainContainer': 'possible'},
      );
      expect(
          flooded.join(' ').toLowerCase(), contains('cellar-flooded=possible'));

      final repair = engine.buildPhrases(
        'activity_in_side_property_other_repair',
        <String, String>{
          'llMainContainer': 'Now',
          'cb_stairs_54': 'true',
          'cb_severely_damaged_62': 'true',
        },
      );
      expect(repair.join(' ').toLowerCase(), contains('other-repair-now='));
    });

  });
}
