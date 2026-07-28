import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F3 Walls and Partitions parity', () {
    const phraseTexts = <String, String>{
      '{F_WALLS_AND_PARTITIONS}':
          '{STANDARD_TEXT}<br />\\r\\n<br />\\r\\n{WALL_TYPE} {WALL_FINISHES} {WALL_CONDITION}<br />\\r\\n<br />\\r\\n{REPAIRS_CONDENSATION}<br />\\r\\n<br />\\r\\n{DAMPNESS_NOTED}<br />\\r\\n<br />\\r\\n{DAMPNESS_CAUSES}<br />\\r\\n<br />\\r\\n{MOVEMENT_CRACKS}<br />\\r\\n<br />\\r\\n{REPAIRS_WALL_REPAIR_SOON}<br />\\r\\n<br />\\r\\n{REPAIRS_WALL_REPAIR_NOW}<br />\\r\\n<br />\\r\\n{IF_HOLLOW_IS_SELECTED}<br />\\r\\n<br />\\r\\n{IF_LATH_AND_PLASTER_IS_SELECTED}<br />\\r\\n<br />\\r\\n{IF_HOLLOW_OVER_LARGE_AREA_IS_SELECTED}<br />\\r\\n<br />\\r\\n{IF_STUD_WALL_AND_CRACKED_OR_BADLY_CRACKED_IS_SELECTED}<br />\\r\\n<br />\\r\\n{REPAIRS_SEALANTS}<br />\\r\\n<br />\\r\\n{REPAIRS_REMOVED_WALL}<br />\\r\\n<br />\\r\\n{IF_TEXTURED_IS_SELECTED}<br />\\r\\n<br />\\r\\n{IF_TILED_IS_SELECTED}<br />\\r\\n<br />\\r\\n{CONDITION_RATING}<br />\\r\\n<br />\\r\\n{NOTES}',
      '{F_WALLS_AND_PARTITIONS}::{WALL_TYPE}': 'type={WAP_WALLS_TYPE}',
      '{F_WALLS_AND_PARTITIONS}::{WALL_FINISHES}':
          'finishes={WAP_WALLS_FINISHES}/{WAP_WALLS_FINISHES_TYPE}',
      '{F_WALLS_AND_PARTITIONS}::{WALL_CONDITION}':
          'condition={WAP_WALLS_CONDITION}',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_CONDENSATION_NONE}':
          'condensation-none',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_CONDENSATION_NOTED}':
          'condensation-noted={WAPR_CONDENSATION_NOTED_LOCATION}',
      '{F_WALLS_AND_PARTITIONS}::{DAMPNESS_NONE}': 'damp-none',
      '{F_WALLS_AND_PARTITIONS}::{DAMPNESS_NOTED}':
          'damp-noted={WAP_DAMP_LOCATION}',
      '{F_WALLS_AND_PARTITIONS}::{CAUSES_KNOWN}':
          'causes-known={WAP_DAMP_KNOWN_CAUSED_BY}',
      '{F_WALLS_AND_PARTITIONS}::{CAUSES_UNKNOWN}': 'causes-unknown',
      '{F_WALLS_AND_PARTITIONS}::{MOVEMENT_CRACKS_NONE}': 'movement-none',
      '{F_WALLS_AND_PARTITIONS}::{MOVEMENT_CRACKS_NORMAL}': 'movement-normal',
      '{F_WALLS_AND_PARTITIONS}::{MOVEMENT_CRACKS_SEVERAL_ELEVATIONS}':
          'movement-several',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_WALL_REPAIR_SOON}':
          'wall-repair-soon=loc:{WAPR_WALL_SOON_LOCATION}/defect:{WAPR_WALL_SOON_DEFECT}',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_WALL_REPAIR_NOW}':
          'wall-repair-now=loc:{WAPR_WALL_NOW_LOCATION}/defect:{WAPR_WALL_NOW_DEFECT}',
      '{F_WALLS_AND_PARTITIONS}::{IF_HOLLOW_IS_SELECTED}': 'hollow',
      '{F_WALLS_AND_PARTITIONS}::{IF_HOLLOW_OVER_LARGE_AREA_IS_SELECTED}':
          'hollow-large',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_SEALANTS}':
          'sealants=loc:{WAPR_SEALANTS_LOCATION}/defect:{WAPR_SEALANTS_DEFECT}',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_REMOVED_WALL_OK}':
          'removed-wall-ok={WAPR_RW_CONDITION_OK}',
      '{F_WALLS_AND_PARTITIONS}::{REPAIRS_REMOVED_WALL_REPAIR}':
          'removed-wall-repair=loc:{WAPR_RW_CONDITION_REPAIR}/defect:{WAPR_RW_CONDITION_REPAIR_DEFECT}',
      '{F_WALLS_AND_PARTITIONS}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about walls emits type, finishes and condition', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_wap_walls',
        {
          'cb_solid': 'true',
          'cb_stud': 'true',
          'actv_finishes': 'true',
          'cb_painted': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('type=solid and stud'));
      expect(all, contains('finishes=a mixture of/painted'));
      expect(all, contains('condition=reasonable'));
    });

    test('about walls with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_wap_walls',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('condensation none vs noted', () {
      final none = engine.buildPhrases(
        'activity_in_side_property_wap_repair_condensation',
        {'actv_status': 'None'},
      );
      expect(none.single.toLowerCase(), contains('condensation-none'));

      final noted = engine.buildPhrases(
        'activity_in_side_property_wap_repair_condensation',
        {'actv_status': 'Noted', 'cb_kitchen': 'true'},
      );
      expect(noted.single.toLowerCase(), contains('condensation-noted=kitchen'));
    });

    test('dampness noted resolves location and known cause', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wap_dampness',
        {
          'damp_status': 'Present',
          'et_location': 'rear wall',
          'actv_status_91': 'Known',
          'cb_leaking_pipes': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('damp-noted=rear wall'));
      expect(all, contains('causes-known=leaking pipes'));
    });

    test('movement cracks none/normal/several-elevations', () {
      expect(
        engine
            .buildPhrases('activity_in_side_property_wap_movement_cracks',
                {'android_material_design_spinner3': 'None'})
            .single
            .toLowerCase(),
        contains('movement-none'),
      );
      expect(
        engine
            .buildPhrases('activity_in_side_property_wap_movement_cracks',
                {'android_material_design_spinner3': 'Normal settlement'})
            .single
            .toLowerCase(),
        contains('movement-normal'),
      );
      expect(
        engine
            .buildPhrases('activity_in_side_property_wap_movement_cracks',
                {'android_material_design_spinner3': 'Multiple elevations'})
            .single
            .toLowerCase(),
        contains('movement-several'),
      );
    });

    test('wall repair now vs soon resolves location and defect', () {
      final now = engine.buildPhrases(
        'activity_in_side_property_wap_repair_wall_repair',
        {
          'actv_repair_type': 'Repair now',
          'cb_lounge': 'true',
          'cb_badly_cracked_17': 'true',
        },
      );
      expect(now.single.toLowerCase(),
          contains('wall-repair-now=loc:lounge/defect:badly cracked'));
    });

    test('sealants resolves location and defect', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wap_repair_sealants',
        {
          'cb_bathtub': 'true',
          'cb_damaged': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('sealants=loc:bathtub/defect:damaged'));
    });

    test('removed wall - forced-ok variant resolves checked locations', () {
      final ok = engine.buildPhrases(
        'activity_in_side_property_wap_removed_wall',
        {'cb_lounge': 'true'},
      );
      expect(ok.single.toLowerCase(), contains('removed-wall-ok=lounge'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_inside_property_wap_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_inside_property_wap_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
