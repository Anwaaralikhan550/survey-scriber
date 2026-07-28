import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G4 Heating parity', () {
    const phraseTexts = <String, String>{
      '{G_HEATING}::{STANDARD_TEXT}': 'standard-text',
      '{G_HEATING}::{CONDITION_RATING}': 'condition={HEAT_COND_RATING}',
      '{G_HEATING}::{NOTES}': 'notes={HEAT_NOTES}',
      '{G_HEATING}::{NOT_INSPECTED}': 'not-inspected',
      '{G_HEATING}::{ABOUT_HEATING_NOT_INSPECTED}': 'about-not-inspected',
      '{G_HEATING}::{ABOUT_HEATING_INSPECTED}':
          'about=[no-heating:{ABOUT_NO_HEATING}][communal:{ABOUT_COMMUNAL_HEATING}][other:{ABOUT_OTHER_HEATING}][inspected:{ABOUT_INSPECTED}][flue:{ABOUT_BOILER_FLUE_CONNECTED_TO}][radiators:{ABOUT_CONNECTED_TO_RADIATOR_UNDERFLOOR_PIPES}][old:{ABOUT_OLD_BOILER}]',
      '{G_HEATING}::{ABOUT_NO_HEATING}': 'no-heating',
      '{G_HEATING}::{ABOUT_COMMUNAL_HEATING}': 'communal-heating',
      '{G_HEATING}::{ABOUT_OTHER_HEATING}':
          'other-heating={HEAT_OTHER_HEATING}',
      '{G_HEATING}::{ABOUT_INSPECTED}':
          'boiler={HEAT_HEATED_BY_BOILER}/loc:{HEAT_BOILER_LOCATION}',
      '{G_HEATING}::{ABOUT_BOILER_FLUE_CONNECTED_TO}':
          'flue=loc:{HEAT_BOILER_FLUE_CONN_LOC}/cond:{HEAT_BOILER_FLUE_CONN_COND}',
      '{G_HEATING}::{ABOUT_CONNECTED_TO_RADIATOR_UNDERFLOOR_PIPES}':
          'radiators={HEAT_CONNECTED_TO}',
      '{G_HEATING}::{ABOUT_OLD_BOILER}': 'old-boiler',
      '{G_HEATING}::{REPAIR_MINOR_LEAKS}':
          'repair-minor=item:{HEAT_REP_ITEM}/loc:{HEAT_REP_LOCATION}/{IS_ARE}',
      '{G_HEATING}::{REPAIR_MAJOR_LEAKS}':
          'repair-major=item:{HEAT_REP_ITEM}/loc:{HEAT_REP_LOCATION}/{IS_ARE}',
      '{G_WATER_HEATING}::{STANDARD_TEXT}': 'wh-standard-text',
      '{G_WATER_HEATING}::{CONDITION_RATING}': 'wh-condition={WH_COND_RATING}',
      '{G_WATER_HEATING}::{NOTES}': 'wh-notes={WH_NOTES}',
      '{G_WATER_HEATING}::{NOT_INSPECTED}': 'wh-not-inspected',
      '{G_WATER_HEATING}::{COMMUNAL_HOT_WATER}': 'communal-hot-water',
      '{G_WATER_HEATING}::{GAS_WATER_HEATING_COMBI_BOILER}':
          'gas-combi=loc:{WH_GWH_CYLI_LOCATION}',
      '{G_WATER_HEATING}::{GAS_WATER_HEATING_CONVENTIONAL}':
          'gas-conventional=loc:{WH_GWH_CYLI_LOCATION}',
      '{G_WATER_HEATING}::{GAS_WATER_HEATING_OTHER}':
          'gas-other=loc:{WH_GWH_CYLI_LOCATION}',
      '{G_WATER_HEATING}::{POOR_CYLINDER_CONDITION}': 'gas-poor-cylinder',
      '{G_WATER_HEATING}::{ELECTRIC_WATER_HEATING_IMMERSION}':
          'electric-immersion=loc:{WH_EWH_CYLI_LOCATION}',
      '{G_WATER_HEATING}::{ELECTRIC_WATER_HEATING_POINT_OF_USE}':
          'electric-point-of-use',
      '{G_WATER_HEATING}::{ELECTRIC_WATER_HEATING_OTHER}': 'electric-other',
      '{G_WATER_HEATING}::{ELECTRIC_POOR_CYLINDER_CONDITION}':
          'electric-poor-cylinder',
      '{G_WATER_HEATING}::{SOLAR_WATER_HEATING}': 'solar-water-heating',
      '{G_WATER_HEATING}::{REPAIR_LEAKING_CYLINDER}':
          'repair-leaking-cylinder={WH_REPAIR_LEAK_CYLI_DEFECTS}',
      '{G_WATER_HEATING}::{REPAIR_LOOSE_SOLAR_PANELS}':
          'repair-loose-panels={WH_REPAIR_LOOS_SOL_PANEL_DEFECTS}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen resolves standard text, rating and notes', () {
      final phrases = engine.buildPhrases(
        'activity_services_heating_main_screen',
        {
          'android_material_design_spinner4': '2',
          'ar_etNote': 'boiler due for service',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('standard-text'));
      expect(all, contains('condition=2'));
      expect(all, contains('notes=boiler due for service'));
    });

    test('about-heating not-inspected checkbox short-circuits everything else',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_heating_about_heating',
        {
          'cb_not_inspected': 'true',
          'cb_no_heating': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first, 'about-not-inspected');
    });

    test('about-heating resolves boiler, location and flue', () {
      final phrases = engine.buildPhrases(
        'activity_services_heating_about_heating',
        {
          'actv_boiler': 'Combination boiler',
          'actv_location': 'Kitchen',
          'actv_location_new': 'Sidewall',
          'actv_condition': 'Reasonable',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('boiler=combination boiler/loc:kitchen'));
      expect(all, contains('flue=loc:sidewall/cond:reasonable'));
    });

    test('about-heating resolves no-heating, communal and other-heating branches',
        () {
      final noHeating = engine.buildPhrases(
        'activity_services_heating_about_heating',
        {'cb_no_heating': 'true'},
      );
      expect(noHeating.join(' ').toLowerCase(), contains('no-heating'));

      final communal = engine.buildPhrases(
        'activity_services_heating_about_heating',
        {'cb_communal_heating': 'true'},
      );
      expect(
          communal.join(' ').toLowerCase(), contains('communal-heating'));

      final other = engine.buildPhrases(
        'activity_services_heating_about_heating',
        {'cb_oil_filled': 'true', 'cb_convector': 'true'},
      );
      expect(other.join(' ').toLowerCase(),
          contains('other-heating=oil filled and convector'));
    });

    test('about-heating resolves radiators/underfloor and old boiler', () {
      final phrases = engine.buildPhrases(
        'activity_services_heating_about_heating',
        {
          'actv_connected_heat': 'Radiators',
          'cb_old_boiler': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('radiators=radiators'));
      expect(all, contains('old-boiler'));
    });

    test('heating repair resolves minor vs major leaks', () {
      final minor = engine.buildPhrases(
        'activity_services_heating_repair_main_screen',
        {
          'actv_leaks': 'Minor Leaks',
          'cb_radiator': 'true',
          'cb_lounge': 'true',
        },
      );
      expect(minor.single.toLowerCase(),
          contains('repair-minor=item:radiator/loc:lounge/is'));

      final major = engine.buildPhrases(
        'activity_services_heating_repair_main_screen',
        {
          'actv_leaks': 'Major Leaks',
          'cb_radiator': 'true',
          'cb_pipework': 'true',
          'cb_bedroom': 'true',
        },
      );
      expect(
        major.single.toLowerCase(),
        contains('repair-major=item:radiator and pipework/loc:bedroom/are'),
      );
    });

    test('heating not inspected is gated on no-heating or boiler-not-inspected',
        () {
      final noHeating = engine.buildPhrases(
        'activity_services_heating_not_inspected',
        {'cb_no_heating': 'true'},
      );
      expect(noHeating, hasLength(1));
      expect(noHeating.first, 'not-inspected');

      final boilerNotInspected = engine.buildPhrases(
        'activity_services_heating_not_inspected',
        {'cb_boiler_unit_not_inspected': 'true'},
      );
      expect(boilerNotInspected.single, 'not-inspected');

      final neither = engine.buildPhrases(
        'activity_services_heating_not_inspected',
        const <String, String>{},
      );
      expect(neither, isEmpty);
    });

    test('water heating main screen resolves standard text, rating and notes',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_water_heating_main_screen',
        {
          'android_material_design_spinner4': '1',
          'ar_etNote': 'cylinder replaced 2020',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('wh-standard-text'));
      expect(all, contains('wh-condition=1'));
      expect(all, contains('wh-notes=cylinder replaced 2020'));
    });

    test('communal hot water is gated on its checkbox', () {
      final phrases = engine.buildPhrases(
        'activity_water_heating_communal_hot_water',
        {'cb_communal_hot_water': 'true'},
      );
      expect(phrases.single, 'communal-hot-water');

      final unchecked = engine.buildPhrases(
        'activity_water_heating_communal_hot_water',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('gas water heating resolves combi, conventional and other branches',
        () {
      final combi = engine.buildPhrases(
        'activity_services_water_heating_gas_heating',
        {'actv_type': 'Combi Boiler', 'actv_location': 'Kitchen'},
      );
      expect(combi.join(' ').toLowerCase(),
          contains('gas-combi=loc:kitchen'));

      final conventional = engine.buildPhrases(
        'activity_services_water_heating_gas_heating',
        {'actv_type': 'Conventional', 'actv_location': 'Garage'},
      );
      expect(conventional.join(' ').toLowerCase(),
          contains('gas-conventional=loc:garage'));

      final other = engine.buildPhrases(
        'activity_services_water_heating_gas_heating',
        {'actv_type': 'Other', 'actv_location': 'Airing cupboard'},
      );
      expect(other.join(' ').toLowerCase(),
          contains('gas-other=loc:airing cupboard'));
    });

    test('gas water heating poor cylinder condition fires independently', () {
      final phrases = engine.buildPhrases(
        'activity_services_water_heating_gas_heating',
        {'cb_poor_cylinder_condition': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(), contains('gas-poor-cylinder'));
    });

    test(
        'electric water heating resolves immersion, point-of-use and other branches',
        () {
      final immersion = engine.buildPhrases(
        'activity_services_water_heating_electric_heating',
        {'actv_type': 'Immersion', 'actv_location': 'Airing cupboard'},
      );
      expect(immersion.join(' ').toLowerCase(),
          contains('electric-immersion=loc:airing cupboard'));

      final pointOfUse = engine.buildPhrases(
        'activity_services_water_heating_electric_heating',
        {'actv_type': 'Point-of-use'},
      );
      expect(pointOfUse.join(' ').toLowerCase(),
          contains('electric-point-of-use'));

      final other = engine.buildPhrases(
        'activity_services_water_heating_electric_heating',
        {'actv_type': 'Other'},
      );
      expect(other.join(' ').toLowerCase(), contains('electric-other'));
    });

    test('solar water heating is gated on its checkbox', () {
      final phrases = engine.buildPhrases(
        'activity_services_water_heating_solar_power',
        {'cb_solar_power': 'true'},
      );
      expect(phrases.single, 'solar-water-heating');

      final unchecked = engine.buildPhrases(
        'activity_services_water_heating_solar_power',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('water heating repair resolves leaking cylinder and loose panels',
        () {
      final cylinder = engine.buildPhrases(
        'activity_services_water_heating_repair_leaking_cylinder',
        {'actv_defect': 'Is leaking badly'},
      );
      expect(cylinder.single.toLowerCase(),
          contains('repair-leaking-cylinder=is leaking badly'));

      final panels = engine.buildPhrases(
        'activity_services_water_heating_repair_loose_panels',
        {'actv_defect': 'Not Secure'},
      );
      expect(panels.single.toLowerCase(),
          contains('repair-loose-panels=not secure'));
    });

    test('water heating not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_services_water_heating_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first, 'wh-not-inspected');

      final unchecked = engine.buildPhrases(
        'activity_services_water_heating_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
