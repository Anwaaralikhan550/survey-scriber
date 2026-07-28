import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G1 Electricity parity', () {
    const phraseTexts = <String, String>{
      '{G_ELECTRICITY}::{STANDARD_TEXT}': 'standard-text',
      '{G_ELECTRICITY}::{CONDITION_RATING}': 'condition={ELE_CON_RT}',
      '{G_ELECTRICITY}::{NOTES}': 'notes={ELE_NOTES}',
      '{G_ELECTRICITY}::{MAINS_ELECTRICITY_INSPECTED}':
          'mains-inspected=meter:{ELE_ME_METER_LOC}',
      '{G_ELECTRICITY}::{MAINS_ELECTRICITY_NOT_INSPECTED}':
          'mains-not-inspected',
      '{G_ELECTRICITY}::{FUSE_INSPECTED}': 'fuse-inspected=loc:{ELE_ME_FUSE_BOX_LOC}',
      '{G_ELECTRICITY}::{FUSE_NOT_INSPECTED}': 'fuse-not-inspected',
      '{G_ELECTRICITY}::{DATED_ELECTRICAL_SYSTEM}': 'dated-system',
      '{G_ELECTRICITY}::{SOLAR_POWER_INSTALLED_LOCATION}':
          'solar-pv=loc:{ELE_SO_PV_INST_LOC}',
      '{G_ELECTRICITY}::{SOLAR_POWER_RESONABLE_CONDITION}': 'solar-ok',
      '{G_ELECTRICITY}::{SOLAR_POWER_BATTERIES_LOCATION}':
          'solar-battery=loc:{ELE_SO_BATTERY_LOCATION}',
      '{G_ELECTRICITY}::{IF_SOLAR_POWER_IS_SELECTED}': 'solar-selected',
      '{G_ELECTRICITY}::{REPAIR_LOOSE_SOLAR_PANELS}':
          'repair-loose-panels={ELE_REP_LOOS_SOL_PANE_DEFECT}',
      '{G_ELECTRICITY}::{REPAIR_ELECTRICAL_HAZARD}':
          'repair-hazard={ELE_REP_ELE_HZRD_BECAUSE_OF}',
      '{G_ELECTRICITY}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen resolves standard text, rating and notes', () {
      final phrases = engine.buildPhrases(
        'activity_services_electricity_main_screen',
        {
          'android_material_design_spinner4': '2',
          'ar_etNote': 'checked by client last year',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('standard-text'));
      expect(all, contains('condition=2'));
      expect(all, contains('notes=checked by client last year'));
    });

    test('main screen with nothing answered still emits standard text only',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_electricity_main_screen',
        const <String, String>{},
      );
      expect(phrases, hasLength(1));
      expect(phrases.single, 'standard-text');
    });

    test('mains electricity inspected resolves meter location', () {
      final phrases = engine.buildPhrases(
        'activity_service_about_electricity',
        {'cb_under_the_stairs_40': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('mains-inspected=meter:under the stairs'));
    });

    test('mains electricity not inspected fires the not-inspected phrase',
        () {
      final phrases = engine.buildPhrases(
        'activity_service_about_electricity',
        {'cb_electricity_not_inspected': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('mains-not-inspected'));
    });

    test('fuse inspected resolves fuse box location', () {
      final phrases = engine.buildPhrases(
        'activity_service_about_electricity',
        {'cb_in_an_outside_box_54': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('fuse-inspected=loc:in an outside box'));
    });

    test('fuse not inspected fires the not-inspected phrase', () {
      final phrases = engine.buildPhrases(
        'activity_service_about_electricity',
        {'cb_fuse_not_inspected': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('fuse-not-inspected'));
    });

    test('dated electrical system checkbox fires its own phrase', () {
      final phrases = engine.buildPhrases(
        'activity_service_about_electricity',
        {
          'cb_electricity_not_inspected': 'true',
          'cb_fuse_not_inspected': 'true',
          'cb_dated_electrical_system': 'true',
        },
      );
      expect(phrases.join(' ').toLowerCase(), contains('dated-system'));
    });

    test('solar power resolves pv location, condition and battery location',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_solar_power',
        {
          'cb_front': 'true',
          'cb_reasonable_condition': 'true',
          'cb_loft': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('solar-pv=loc:front'));
      expect(all, contains('solar-ok'));
      expect(all, contains('solar-battery=loc:loft'));
      expect(all, contains('solar-selected'));
    });

    test('solar power with nothing selected emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_services_solar_power',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });

    test('repair loose panels resolves the defect', () {
      final phrases = engine.buildPhrases(
        'activity_services_electricity_repair_loose_panels',
        {'actv_defect': 'Not Secure'},
      );
      expect(phrases.single.toLowerCase(),
          contains('repair-loose-panels=not secure'));
    });

    test('repair electrical hazard resolves the defect list', () {
      final phrases = engine.buildPhrases(
        'activity_services_electricity_repair_electrical_hazard',
        {'cb_exposed_wires': 'true', 'cb_damaged_fittings': 'true'},
      );
      expect(phrases.single.toLowerCase(),
          contains('repair-hazard=exposed wires and damaged fittings'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_services_electricity_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_services_electricity_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
