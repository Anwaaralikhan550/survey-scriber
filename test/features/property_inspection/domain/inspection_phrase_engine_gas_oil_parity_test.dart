import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G2 Gas and Oil parity', () {
    const phraseTexts = <String, String>{
      '{G_GAS_AND_OIL}::{STANDARD_TEXT}': 'standard-text',
      '{G_GAS_AND_OIL}::{CONDITION_RATING}': 'condition={GAO_CONDITION_RATING}',
      '{G_GAS_AND_OIL}::{NOTES}': 'notes={GAO_NOTE}',
      '{G_GAS_AND_OIL}::{OLD_TANK}': 'old-tank',
      '{G_GAS_AND_OIL}::{MAINS_GAS_CONDITION_OK}':
          'mains-ok=loc:{GAO_MG_METER_LOCATION}/{CONDITION_OK_GAS_SMELL}',
      '{G_GAS_AND_OIL}::{MAINS_GAS_CONDITION_NOT_INSPECTED}':
          'mains-not-inspected',
      '{G_GAS_AND_OIL}::{MAINS_GAS_CONDITION_NO_GAS_INSTALLATION}':
          'no-gas-installation',
      '{G_GAS_AND_OIL}::{GAS_SMELL_NOTED}': 'smell-noted',
      '{G_GAS_AND_OIL}::{GAS_SUPPLY_IS_CAPPED_OFF}': 'capped-off',
      '{G_GAS_AND_OIL}::{CONDITION_OK_GAS_SMELL}': 'no-smell-detected',
      '{G_GAS_AND_OIL}::{OIL_TANK_INSPECTED}':
          'oil=loc:{GAO_O_LOCATION}/made:{GAO_O_OIL_ANK_MADE_OF}',
      '{G_GAS_AND_OIL}::{OIL_TANK_NEAR_WATERCOURSE}': 'oil-watercourse',
      '{G_GAS_AND_OIL}::{GAS_METER_REPAIR}':
          'gas-meter-repair={GAO_REP_GASMETER_DEFECT}',
      '{G_GAS_AND_OIL}::{OIL_STORAGE_TANK_AND_PIPEWORK_REPAIR}':
          'oil-repair=item:{GAO_REP_OILTANK_ITEM}/{IS_ARE}/defect:{GAO_REP_OILTANK_DEFECT}',
      '{G_GAS_AND_OIL}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen resolves standard text, rating and notes', () {
      final phrases = engine.buildPhrases(
        'activity_services_gas_oil_main_screen',
        {
          'android_material_design_spinner4': '1',
          'ar_etNote': 'boiler serviced last month',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('standard-text'));
      expect(all, contains('condition=1'));
      expect(all, contains('notes=boiler serviced last month'));
    });

    test('main screen with nothing answered still emits standard text only',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_gas_oil_main_screen',
        const <String, String>{},
      );
      expect(phrases, hasLength(1));
      expect(phrases.single, 'standard-text');
    });

    test('old tank checkbox fires its own phrase', () {
      final phrases = engine.buildPhrases(
        'activity_services_gas_oil',
        {'cb_old_tank_but_ok': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first, 'old-tank');

      final unchecked = engine.buildPhrases(
        'activity_services_gas_oil',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('mains gas ok resolves location and smell-not-noted clause', () {
      final phrases = engine.buildPhrases(
        'activity_services_main_gas',
        {
          'actv_condition': 'Ok',
          'actv_location': 'is under the stairs',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('mains-ok=loc:under the stairs'));
      expect(all, contains('no-smell-detected'));
    });

    test('mains gas ok with smell noted also fires the smell-noted phrase',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_main_gas',
        {
          'actv_condition': 'Ok',
          'actv_location': 'is in the kitchen',
          'cb_gas_smell_noted': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('mains-ok=loc:in the kitchen'));
      expect(all, contains('smell-noted'));
    });

    test('mains gas not inspected fires the not-inspected phrase', () {
      final phrases = engine.buildPhrases(
        'activity_services_main_gas',
        {'actv_condition': 'Not Inspected'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('mains-not-inspected'));
    });

    test('mains gas no gas installation fires its own phrase', () {
      final phrases = engine.buildPhrases(
        'activity_services_main_gas',
        {'actv_condition': 'No Gas Installation'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('no-gas-installation'));
    });

    test('gas supply capped off checkbox fires independently', () {
      final phrases = engine.buildPhrases(
        'activity_services_main_gas',
        {
          'actv_condition': 'Not Inspected',
          'cb_gas_supply_is_capped_off': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('mains-not-inspected'));
      expect(all, contains('capped-off'));
    });

    test('oil tank inspected resolves location and material', () {
      final phrases = engine.buildPhrases(
        'activity_services_oil',
        {
          'actv_oil_tank_status': 'Inspected',
          'actv_location': 'Rear garden',
          'actv_oil_tank_made_up_of': 'Plastic',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('oil=loc:rear garden/made:plastic'));
      expect(all, isNot(contains('oil-watercourse')));
    });

    test('oil tank near watercourse adds the addendum', () {
      final phrases = engine.buildPhrases(
        'activity_services_oil',
        {
          'actv_oil_tank_status': 'Inspected',
          'actv_location': 'Rear garden',
          'actv_oil_tank_made_up_of': 'Plastic',
          'cb_nearby_watercourse': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('oil-watercourse'));
    });

    test('oil tank not inspected emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_services_oil',
        {'actv_oil_tank_status': 'Not Inspected'},
      );
      expect(phrases, isEmpty);
    });

    test('gas meter repair resolves the defect list', () {
      final phrases = engine.buildPhrases(
        'activity_services_gas_oil_repair_gas_meter',
        {'cb_loose': 'true', 'cb_badly_rusted': 'true'},
      );
      expect(phrases.single.toLowerCase(),
          contains('gas-meter-repair=loose and badly rusted'));
    });

    test('oil storage tank and pipework repair resolves item and defect', () {
      final phrases = engine.buildPhrases(
        'activity_services_gas_oil_repair_storage_tank_pipework',
        {
          'cb_storage_tank': 'true',
          'cb_corroded': 'true',
        },
      );
      expect(
        phrases.single.toLowerCase(),
        contains('oil-repair=item:tank/is/defect:corroded'),
      );
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_services_gas_oil_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_services_gas_oil_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
