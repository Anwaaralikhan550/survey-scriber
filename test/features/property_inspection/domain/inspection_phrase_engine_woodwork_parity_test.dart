import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F7 Woodwork parity', () {
    const phraseTexts = <String, String>{
      '{F_WOOD_WORK}::{DOOR_SAMPLING_OK}':
          'door-sampling-ok={WW_DOOR_SAMPLING_CONDITION}',
      '{F_WOOD_WORK}::{OUT_OF_SQUARE_DOORS}': 'out-of-square-doors',
      '{F_WOOD_WORK}::{GLAZED_INTERNAL_DOORS}': 'glazed-internal-doors',
      '{F_WOOD_WORK}::{CREAKING_STAIRS}': 'creaking-stairs',
      '{F_WOOD_WORK}::{ROCKING_STAIR_HANDRAILS}': 'rocking-handrails',
      '{F_WOOD_WORK}::{NO_STAIRS_HANDRAILS}': 'no-stairs-handrails',
      '{F_WOOD_WORK}::{OPEN_STAIR_THREADS}': 'open-stair-threads',
      '{F_WOOD_WORK}::{WOOD_WORK}':
          'woodwork=items:{WW_WW_MADE_UP}/condition:{WW_WW_CONDITION}',
      '{F_WOOD_WORK}::{FITTED_BUILTIN_CUPBOARDS}':
          'cupboards={WW_FBC_CONDITION}',
      '{F_WOOD_WORK}::{DOOR_REPAIR}':
          'door-repair=loc:{WWR_DR_LOCATION}/defect:{WWR_DR_DEFECT}',
      '{F_WOOD_WORK}::{IF_NOT_CLOSING_WELL_IS_SELECTED}': 'not-closing-well',
      '{F_WOOD_WORK}::{REPAIR_DAMAGED_LOCK}':
          'damaged-lock=door:{WWR_DL_DAMAGED_LOCK}/defect:{WWR_DL_DEFECT}',
      '{F_WOOD_WORK}::{WOOD_WORK_REPAIR_SOON}':
          'repair-soon=loc:{WWR_WWR_SOON_LOCATION}/defect:{WWR_WWR_SOON_DEFECT}',
      '{F_WOOD_WORK}::{WOOD_WORK_REPAIR_NOW}':
          'repair-now=loc:{WWR_WWR_NOW_LOCATION}/defect:{WWR_WWR_NOW_DEFECT}',
      '{F_WOOD_WORK}::{REPAIR_BALUSTERS}': 'balusters={WWR_BALUSTERS_DEFECT}',
      '{F_WOOD_WORK}::{REPAIR_INFESTATION_MAJOR}':
          'infestation-major=part:{WWR_INFESTATION_PART_OF}/loc:{WWR_INFESTATION_LOCATION}',
      '{F_WOOD_WORK}::{REPAIR_INFESTATION_MINOR}':
          'infestation-minor=part:{WWR_INFESTATION_PART_OF}/loc:{WWR_INFESTATION_LOCATION}',
      '{F_WOOD_WORK}::{REPAIR_DAMP_TIMBER}':
          'damp-timber=component:{WWR_DT_COMPONENT}/loc:{WWR_DT_LOCATION}/defect:{WWR_DT_DEFECT}',
      '{F_WOOD_WORK}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen combines only the checked defect sub-phrases', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wood_work',
        {
          'cb_creaking_stairs': 'true',
          'cb_no_stairs_handrails': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('creaking-stairs'));
      expect(all, contains('no-stairs-handrails'));
      expect(all, isNot(contains('rocking-handrails')));
      expect(all, isNot(contains('open-stair-threads')));
    });

    test('door sampling ok includes the sampled condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wood_work',
        {'cb_Door_sampling': 'true', 'actv_condition': 'Reasonable'},
      );
      expect(phrases.single.toLowerCase(),
          contains('door-sampling-ok=reasonable'));
    });

    test('woodwork details resolves items and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wood_work_second',
        {
          'cb_doors': 'true',
          'cb_skirting_boards': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('items:doors and skirting boards'));
      expect(all, contains('condition:reasonable'));
    });

    test('door sampling repair screen resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wood_work_door_sampling',
        {
          'cb_lounge': 'true',
          'cb_not_closing_well_53': 'true',
          'cb_door_not_closing_well': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('door-repair=loc:lounge/defect:not closing well'));
      expect(all, contains('not-closing-well'));
    });

    test('repair balusters resolves the checked defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wood_work_repair_balusters',
        {'cb_too_far_apart_93': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
          phrases.first.toLowerCase(), contains('balusters=too far apart'));
    });

    test('repair infestation major vs minor', () {
      final major = engine.buildPhrases(
        'activity_in_side_property_wood_work_repair_infestation',
        {
          'actv_condition': 'Major',
          'cb_staircase': 'true',
          'cb_plastic': 'true',
        },
      );
      expect(major.single.toLowerCase(),
          contains('infestation-major=part:staircase/loc:lounge'));

      final minor = engine.buildPhrases(
        'activity_in_side_property_wood_work_repair_infestation',
        {
          'actv_condition': 'Minor',
          'cb_staircase': 'true',
          'cb_plastic': 'true',
        },
      );
      expect(minor.single.toLowerCase(),
          contains('infestation-minor=part:staircase/loc:lounge'));
    });

    test('repair damp timber resolves component, location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wood_work_repair_damp_timber',
        {
          'cb_skirting': 'true',
          'cb_kitchen_72': 'true',
          'cb_rotten': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.first.toLowerCase(),
        contains('damp-timber=component:skirting/loc:kitchen/defect:rotten'),
      );
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_in_side_property_wood_work_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_in_side_property_wood_work_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
