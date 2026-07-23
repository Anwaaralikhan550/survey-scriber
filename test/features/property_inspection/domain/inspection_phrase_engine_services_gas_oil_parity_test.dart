import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G2 Gas and Oil legacy parity', () {
    const phraseTexts = <String, String>{
      '{G_GAS_AND_OIL}::{MAINS_GAS_CONDITION_OK}':
          'main-gas={GAO_MG_METER_LOCATION} {CONDITION_OK_GAS_SMELL}',
      '{G_GAS_AND_OIL}::{CONDITION_OK_GAS_SMELL}': 'no-smell',
      '{G_GAS_AND_OIL}::{GAS_SMELL_NOTED}': 'smell-noted',
      '{G_GAS_AND_OIL}::{GAS_SUPPLY_IS_CAPPED_OFF}': 'capped-off',
      '{G_GAS_AND_OIL}::{OIL_TANK_INSPECTED}':
          'oil={GAO_O_LOCATION}/{GAO_O_OIL_ANK_MADE_OF}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('mains gas requires valid ok status and location before emitting', () {
      final invalidStatus = engine.buildPhrases(
        'activity_services_main_gas',
        const <String, String>{
          'actv_condition': 'Reasonable',
          'cb_gas_smell_noted': 'true',
        },
      );
      expect(invalidStatus.join(' '), isNot(contains('main-gas=')));
      expect(invalidStatus.join(' '), contains('smell-noted'));

      final missingLocation = engine.buildPhrases(
        'activity_services_main_gas',
        const <String, String>{
          'actv_condition': 'Ok',
        },
      );
      expect(missingLocation, isEmpty);

      // Phase 4d fix: tree dropdown options are pre-worded as full clauses
      // ("is under the stairs") but the bank template already supplies
      // "located in the {LOCATION}" - the handler now strips a redundant
      // leading "is " so the two don't combine into "located in the is
      // under the stairs".
      final valid = engine.buildPhrases(
        'activity_services_main_gas',
        const <String, String>{
          'actv_condition': 'Ok',
          'actv_location': 'is under the stairs',
        },
      );
      expect(valid.join(' '), contains('main-gas=under the stairs'));
    });

    test('oil requires inspected status plus location and made-up-of', () {
      final missingFields = engine.buildPhrases(
        'activity_services_oil',
        const <String, String>{
          'actv_oil_tank_status': 'Inspected',
        },
      );
      expect(missingFields, isEmpty);

      final valid = engine.buildPhrases(
        'activity_services_oil',
        const <String, String>{
          'actv_oil_tank_status': 'Inspected',
          'actv_location': 'rear garden',
          'actv_oil_tank_made_up_of': 'plastic',
        },
      );
      expect(valid.join(' '), contains('oil=rear garden/plastic'));
    });
  });
}
