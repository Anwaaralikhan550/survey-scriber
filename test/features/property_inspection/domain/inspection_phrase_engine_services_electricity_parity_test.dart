import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G1 Electricity legacy parity', () {
    const phraseTexts = <String, String>{
      '{G_ELECTRICITY}::{DATED_ELECTRICAL_SYSTEM}': 'dated-system',
      '{G_ELECTRICITY}::{DATED_ELECTRICAL_SYSTEM_SAFETY_HAZARD}':
          'dated-hazard',
      '{G_ELECTRICITY}::{REPAIR_ELECTRICAL_HAZARD}':
          'repair-hazard={ELE_REP_ELE_HZRD_BECAUSE_OF}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test(
        'mains electricity ignores legacy-hidden electric hazard controls on the about screen',
        () {
      final phrases = engine.buildPhrases(
        'activity_service_about_electricity',
        <String, String>{
          'cb_dated_electrical_system': 'true',
          'cb_dated_electrical_system_electrical_hazard': 'true',
          'cb_dated_electrical_system_exposed_wires': 'true',
          'cb_dated_electrical_system_damaged_fittings': 'true',
        },
      );

      expect(phrases, contains('dated-system'));
      expect(phrases.join(' '), isNot(contains('dated-hazard')));
      expect(phrases.join(' '), isNot(contains('repair-hazard=')));
    });

    test('electrical hazard repair screen still emits the repair phrase', () {
      final phrases = engine.buildPhrases(
        'activity_services_electricity_repair_electrical_hazard',
        <String, String>{
          'cb_exposed_wires': 'true',
          'cb_damaged_fittings': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('repair-hazard='));
    });
  });
}
