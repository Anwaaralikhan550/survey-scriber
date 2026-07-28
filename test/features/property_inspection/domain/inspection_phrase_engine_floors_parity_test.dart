import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F4 Floors parity', () {
    const phraseTexts = <String, String>{
      '{F_FLOORS}':
          '{STANDARD_TEXT}<br />\\r\\n<br />\\r\\n{FLOOR_CONSTRUCTION} {FLOOR_COVERING} {FLOOR_CONDITION}<br />\\r\\n<br />\\r\\n{CREAKING}<br />\\r\\n<br />\\r\\n{TILES_CONDITION_OK}<br />\\r\\n<br />\\r\\n{TILES_CONDITION_CRACKED}<br />\\r\\n<br />\\r\\n{LOOSE_FLOORBOARDS}<br />\\r\\n<br />\\r\\n{TIMBER_DECAY}<br />\\r\\n<br />\\r\\n{TIMBER_INFESTAION}<br />\\r\\n<br />\\r\\n{DAMPNESS}<br />\\r\\n<br />\\r\\n{FLOOR_VENTILATION}<br />\\r\\n<br />\\r\\n{TIMBER_FLOOR_OLDER_PROPERTIES}<br />\\r\\n<br />\\r\\n{FLOOR_REPAIR_SOON}<br />\\r\\n<br />\\r\\n{FLOOR_REPAIR_NOW}<br />\\r\\n<br />\\r\\n{REPAIR_LAMINATE}<br />\\r\\n<br />\\r\\n{REPAIR_FLOOR_VIBRATION}<br />\\r\\n<br />\\r\\n{REPAIR_SLOPING_FLOOR}<br />\\r\\n<br />\\r\\n{REPAIR_UNEVEN_FLOOR}<br />\\r\\n<br />\\r\\n{STANDARD_TEXT_2}<br />\\r\\n<br />\\r\\n{CONDITION_RATING}<br />\\r\\n<br />\\r\\n{NOTES}',
      '{F_FLOORS}::{FLOOR_CONSTRUCTION_ALL_SOLID}': 'construction=all-solid',
      '{F_FLOORS}::{FLOOR_CONSTRUCTION_ALL_SUSPENDED}':
          'construction=all-suspended',
      '{F_FLOORS}::{FLOOR_CONSTRUCTION_MIXTURE_OF}':
          'construction=mixture:{FL_AF_MIXTURE_OF}',
      '{F_FLOORS}::{FLOOR_COVERING}':
          'covering=with:{FL_AF_COVERED_WITH}/includes:{FL_AF_COVERING_INCLUDES}',
      '{F_FLOORS}::{FLOOR_CONDITION}': 'condition={FL_AF_CONDITION}',
      '{F_FLOORS}::{CREAKING_NONE}': 'creaking-none',
      '{F_FLOORS}::{CREAKING_NOTED}': 'creaking-noted={FL_CR_STATUS_NOTED}',
      '{F_FLOORS}::{TILES_CONDITION_OK}': 'tiles-ok={FL_TILES_OK_LOCATION}',
      '{F_FLOORS}::{TILES_CONDITION_CRACKED}':
          'tiles-cracked={FL_TILES_CRACKED_LOCATION}',
      '{F_FLOORS}::{LOOSE_FLOORBOARDS}': 'loose-floorboards',
      '{F_FLOORS}::{TIMBER_DECAY_NONE}': 'decay-none',
      '{F_FLOORS}::{TIMBER_DECAY_INVESTIGATE}':
          'decay-investigate={FL_TD_INVESTIGATE_LOCATION}',
      '{F_FLOORS}::{TIMBER_INFESTAION_NONE}': 'infestation-none',
      '{F_FLOORS}::{TIMBER_INFESTAION_INVESTIGATE}':
          'infestation-investigate={FL_TI_INVESTIGATE_LOCATION}',
      '{F_FLOORS}::{DAMPNESS_KNOWN_CAUSE}':
          'damp-known=loc:{FL_DAMP_LOCATION}/cause:{FL_DAMP_CAUSED_BY}',
      '{F_FLOORS}::{DAMPNESS_UNKNOWN_CAUSE}': 'damp-unknown',
      '{F_FLOORS}::{FLOOR_VENTILATION_OK}': 'ventilation-ok',
      '{F_FLOORS}::{FLOOR_VENTILATION_POOR}':
          'ventilation-poor={FL_FV_POOR_PROBLEM}',
      '{F_FLOORS}::{FLOOR_REPAIR_NOW}':
          'floor-repair-now=loc:{FLR_FR_NOW_LOCATION}/defect:{FLR_FR_NOW_DEFECT}',
      '{F_FLOORS}::{FLOOR_REPAIR_SOON}':
          'floor-repair-soon=loc:{FLR_FR_SOON_LOCATION}/defect:{FLR_FR_SOON_DEFECT}',
      '{F_FLOORS}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about floor: all-solid construction with covering and condition', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_floors_about_floor',
        {
          'actv_construction': 'All solid',
          'actv_covered_with': 'a',
          'cb_carpets': 'true',
          'actv_condition': 'Reasonable',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('construction=all-solid'));
      expect(all, contains('covering=with:a/includes:carpets'));
      expect(all, contains('condition=reasonable'));
    });

    test('about floor: mixture construction resolves checked types', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_floors_about_floor',
        {
          'actv_construction': 'A mixture of',
          'cb_solid': 'true',
          'cb_suspended_timber': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('construction=mixture:solid and suspended timber'));
    });

    test('about floor with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_floors_about_floor',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('creaking none vs noted', () {
      expect(
        engine
            .buildPhrases('activity_in_side_property_floors_creaking',
                {'actv_status': 'None'})
            .single
            .toLowerCase(),
        contains('creaking-none'),
      );
      final noted = engine.buildPhrases(
        'activity_in_side_property_floors_creaking',
        {'actv_status': 'Noted', 'cb_lounge': 'true'},
      );
      expect(noted.single.toLowerCase(),
          contains('creaking-noted=to parts of the floors'));
    });

    test('tiles ok and cracked resolve their own locations independently', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_floors_tiles',
        {
          'cb_ok': 'true',
          'cb_kitchen': 'true',
          'cb_cracked': 'true',
          'cb_bathroom_s_41': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('tiles-ok=kitchen'));
      expect(all, contains('tiles-cracked=bathroom'));
    });

    test('timber decay none vs investigate', () {
      expect(
        engine
            .buildPhrases('activity_in_side_property_floors_timber_decay',
                {'actv_status': 'None'})
            .single
            .toLowerCase(),
        contains('decay-none'),
      );
      final investigate = engine.buildPhrases(
        'activity_in_side_property_floors_timber_decay',
        {'actv_status': 'Investigate', 'cb_staircase_timber': 'true'},
      );
      expect(investigate.single.toLowerCase(),
          contains('decay-investigate=staircase timber'));
    });

    test('timber infestation none vs investigate', () {
      expect(
        engine
            .buildPhrases(
                'activity_in_side_property_floors_timber_infection',
                {'actv_status': 'None'})
            .single
            .toLowerCase(),
        contains('infestation-none'),
      );
    });

    test('dampness known cause resolves location and cause', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_floors_dampness',
        {
          'actv_status': 'Known cause',
          'cb_kitchen': 'true',
          'cb_faulty_plumbing': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(),
          contains('damp-known=loc:kitchen/cause:faulty plumbing'));
    });

    test('ventilation ok vs poor', () {
      expect(
        engine
            .buildPhrases('activity_in_side_property_floors_floor_ventilation',
                {'actv_condition': 'OK'})
            .single
            .toLowerCase(),
        contains('ventilation-ok'),
      );
      final poor = engine.buildPhrases(
        'activity_in_side_property_floors_floor_ventilation',
        {'actv_condition': 'Poor', 'et_describe_problem': 'blocked airbrick'},
      );
      expect(
          poor.single.toLowerCase(), contains('ventilation-poor=blocked airbrick'));
    });

    test('floor repair now vs soon resolves location and defect', () {
      final now = engine.buildPhrases(
        'activity_in_side_property_floors_repair_floor_repair',
        {
          'actv_repair_type': 'Repair now',
          'cb_lounge': 'true',
          'cb_rotten': 'true',
        },
      );
      expect(now.single.toLowerCase(),
          contains('floor-repair-now=loc:lounge/defect:rotten'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_in_side_property_floors_repair_not_inspetcted',
        {'cb_not_inspetcted': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));
    });
  });
}
