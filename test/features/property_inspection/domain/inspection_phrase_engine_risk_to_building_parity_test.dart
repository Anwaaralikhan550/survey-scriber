import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - J1 Risk to Building parity', () {
    const phraseTexts = <String, String>{
      '{RISK_TO_BUILDING}::{BUILDING_MOVEMENTS_STATUS_NONE}': 'movement-none',
      '{RISK_TO_BUILDING}::{BUILDING_MOVEMENTS_STATUS_NOTED}':
          'movement-noted',
      '{RISK_TO_BUILDING}::{BUILDING_MOVEMENTS_STATUS_INVESTIGATE}':
          'movement-investigate',
      '{RISK_TO_BUILDING}::{BUILDING_SUBSIDENCE_STATUS_NONE}':
          'subsidence-none',
      '{RISK_TO_BUILDING}::{BUILDING_SUBSIDENCE_STATUS_NOTED}':
          'subsidence-noted around {RTB_SUBSIDENCE_INVESTIGATE_LOCATION}.',
      '{RISK_TO_BUILDING}::{BUILDING_SUBSIDENCE_STATUS_INVESTIGATE}':
          'subsidence-investigate around {RTB_SUBSIDENCE_INVESTIGATE_LOCATION}.',
      '{RISK_TO_BUILDING}::{BUILDING_DAMPNESS_STATUS_NONE}': 'dampness-none',
      '{RISK_TO_BUILDING}::{BUILDING_DAMPNESS_STATUS_IMPLEMENT_ACTION}':
          'dampness-implement-action',
      '{RISK_TO_BUILDING}::{BUILDING_DAMPNESS_STATUS_INVESTIGATE}':
          'dampness-investigate',
      '{RISK_TO_BUILDING}::{BUILDING_TIMBER_DEFECT_STATUS_NONE}':
          'timber-none',
      '{RISK_TO_BUILDING}::{BUILDING_TIMBER_DEFECT_STATUS_NOTED}':
          'timber-noted',
      '{RISK_TO_BUILDING}::{BUILDING_NEAR_BY_TREES}': 'nearby-trees',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('movement status resolves none/noted/investigate', () {
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_movement_status': 'None'}),
        contains('movement-none'),
      );
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_movement_status': 'Noted'}),
        contains('movement-noted'),
      );
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_movement_status': 'Investigate'}),
        contains('movement-investigate'),
      );
    });

    test('subsidence noted resolves the location, investigate drops it when empty',
        () {
      final noted = engine.buildPhrases(
        'activity_risks_risk_to_building_',
        {
          'actv_subsidence_status': 'Noted',
          'cb_bay_windows': 'true',
        },
      );
      expect(noted.join(' ').toLowerCase(),
          contains('subsidence-noted around bay windows'));

      final investigateNoLocation = engine.buildPhrases(
        'activity_risks_risk_to_building_',
        {'actv_subsidence_status': 'Investigate'},
      );
      final all = investigateNoLocation.join(' ').toLowerCase();
      expect(all, contains('subsidence-investigate.'));
      expect(all, isNot(contains('around')));
      expect(all, isNot(contains('{')));
    });

    test('dampness status remaps NOTED to the implement-action key', () {
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_dampness_status': 'None'}),
        contains('dampness-none'),
      );
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_dampness_status': 'Implement action'}),
        contains('dampness-implement-action'),
      );
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_dampness_status': 'Investigate'}),
        contains('dampness-investigate'),
      );
    });

    test('timber defect status has no investigate tier, remaps to noted', () {
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_timber_sefect_status': 'None'}),
        contains('timber-none'),
      );
      expect(
        engine.buildPhrases('activity_risks_risk_to_building_',
            {'actv_timber_sefect_status': 'Noted'}),
        contains('timber-noted'),
      );
    });

    test('nearby trees is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_risks_risk_to_building_',
        {'cb_near_by_tree': 'true'},
      );
      expect(checked, contains('nearby-trees'));

      final unchecked = engine.buildPhrases(
        'activity_risks_risk_to_building_',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
