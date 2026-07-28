import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - outside doors parity', () {
    const phraseTexts = <String, String>{
      '{E_OUTSIDE_DOORS}::{PVC}':
          '{DOOR_LOCATION}|{DOOR_SG_RATING_STATUS}|{DOOR_CONDITION}|{WALL_SEALING}',
      '{E_OUTSIDE_DOORS}::{OTHER}':
          '{DOOR_LOCATION}|{DOOR_SG_RATING_STATUS}|{DOOR_CONDITION}|{WALL_SEALING}',
      '{E_OUTSIDE_DOORS}::{TIMBER}':
          '{DOOR_LOCATION}|{DOOR_SG_RATING_STATUS}|{DOOR_CONDITION}|{WALL_SEALING}',
      '{E_OUTSIDE_DOORS}::{DOOR_LOCATION}':
          '{DOOR_LOCATION}/{REPLACEMENT}/{DOOR_MATERIAL}',
      '{E_OUTSIDE_DOORS}::{DOOR_GLAZING}': 'glazing={DOOR_GLAZZING}',
      '{E_OUTSIDE_DOORS}::{DOOR_SG_RATING_NOTED}': 'sg noted',
      '{E_OUTSIDE_DOORS}::{DOOR_SG_RATING_NO_SG_RATING}': 'sg missing',
      '{E_OUTSIDE_DOORS}::{DOOR_CONDITION}': 'condition={DOOR_CONDITION}',
      '{E_OUTSIDE_DOORS}::{WALL_SEALING}':
          'seal={DOOR_SEALING_CONDITION};sec={SECURITY_OFFERED}',
      '{E_OUTSIDE_DOORS}::{INADEQUATE_LOCK_SELECTED}':
          'inadequate-lock={DOOR_LOCATION}',
      '{E_OUTSIDE_DOORS}::{IF_REPLACEMENT}': 'replacement guidance',
      '{E_OUTSIDE_DOORS}::{TIMBER_DOORS_NOTE}': 'timber-doors-note',
      '{E_OUTSIDE_DOORS}::{PATIO_FRENCH_DOORS_NOTE}': 'patio-french-note',
      '{E_OUTSIDE_DOORS}::{MAIN_DOOR_REPAIR}':
          '{DOOR_REPAIR_SOON}\n\n{DOOR_REPAIR_NOW}',
      '{E_OUTSIDE_DOORS}::{OTHER_DOOR_REPAIR}':
          '{DOOR_REPAIR_SOON}\n\n{DOOR_REPAIR_NOW}',
      '{E_OUTSIDE_DOORS}::{DOOR_REPAIR_SOON}':
          'loc={DOOR_LOCATION};def={DOOR_DEFECT};soon',
      '{E_OUTSIDE_DOORS}::{DOOR_REPAIR_NOW}':
          'loc={DOOR_LOCATION};def={DOOR_DEFECT};now',
      '{E_OUTSIDE_DOORS}::{DAMAGED_STOCK_LOCK_SELECTED}':
          'lock={DOOR_LOCATION}',
      '{E_OUTSIDE_DOORS}::{DOORS_DEFECT_IF_IN_DISREPAIR}':
          'disrepair-addendum',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('PVC screen uses legacy screen material mapping', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors',
        {
          'cb_main': 'true',
          'cb_double': 'true',
          'actv_status': 'Noted',
          'actv_condition': 'Reasonable',
          'actv_status_security': 'Properly',
          'actv_seciruty_offered': 'Reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('/pvc'));
      expect(phrases.first.toLowerCase(), contains('glazing=double'));
    });

    test('outside doors about screen emits nothing on default empty state', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors',
        const <String, String>{},
      );

      expect(phrases, isEmpty);
    });

    test('outside doors about screen does not leak unresolved tokens', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors',
        {
          'actv_condition': 'Reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first, isNot(contains('{')));
      expect(phrases.first, isNot(contains('}')));
    });

    test('Other screen uses typed other door type for material', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors__other',
        {
          'cb_rear': 'true',
          'cb_single': 'true',
          'other': 'Composite',
          'actv_status': 'Noted',
          'actv_condition': 'Reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('/composite'));
      expect(phrases.first.toLowerCase(), contains('glazing=single'));
    });

    test('Other screen falls back to "other" when type text is empty', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors__other',
        {
          'cb_side': 'true',
          'cb_single': 'true',
          'actv_status': 'Noted',
          'actv_condition': 'Reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('/other'));
      expect(phrases.first.toLowerCase(), contains('glazing=single'));
    });

    test('repair soon accepts migrated alias "other" text field', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_repairs_repair_out_side_doors',
        {
          'actv_repair_type': 'Repair soon',
          'cb_other_337': 'true',
          'other': 'hinge worn',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('loc=main'));
      expect(phrases.first.toLowerCase(), contains('def=hinge worn'));
    });

    test('repair soon accepts legacy llMainContainer repair type', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_repairs_repair_out_side_doors',
        {
          'llMainContainer': 'Repair soon',
          'cb_poorly_secured': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('loc=main'));
      expect(phrases.first.toLowerCase(), contains('def=poorly secured'));
    });

    test('legacy safety-glass screen uses llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_safety_glass_rating',
        {
          'llMainContainer': 'Noted',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('sg noted'));
    });

    test('legacy wall-sealing screen uses llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_wall_sealing',
        {
          'llMainContainer': 'properly sealed',
          'actv_seciruty_offered': 'reasonable',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('seal=properly sealed'));
      expect(phrases.first.toLowerCase(), contains('sec=reasonable'));
    });

    test('other-door repair uses typed door name as location', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__other_door',
        {
          'other': 'French',
          'actv_repair_type': 'Repair soon',
          'cb_poorly_secured': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('loc=french'));
    });

    test('failed glazing location screen is legacy no-op', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_repairs_failed_glazing_location',
        {
          'cb_main_63': 'true',
          'cb_has_failed_glazing_45': 'true',
        },
      );

      expect(phrases, isEmpty);
    });

    test('inadequate lock location screen is legacy no-op', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_repairs_inadequate_lock_location',
        {
          'cb_main_63': 'true',
          'cb_has_inadequate_lock_89': 'true',
        },
      );

      expect(phrases, isEmpty);
    });

    test('inadequate security level adds the inadequate-lock sentence', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors',
        {
          'cb_main': 'true',
          'actv_status_security': 'Poorly',
          'actv_seciruty_offered': 'Inadequate',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('sec=inadequate'));
      expect(all, contains('inadequate-lock=main'));
    });

    test('timber material adds the timber-doors maintenance note', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors__timber',
        {
          'cb_main': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('timber-doors-note'));
    });

    test('patio location adds the patio-and-french-doors note', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_about_doors',
        {
          'cb_patio': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('patio-french-note'));
    });

    test('repair now adds the comprehensive-repair disrepair addendum', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_out_side_doors_repairs_repair_out_side_doors',
        {
          'actv_repair_type': 'Repair now',
          'cb_damaged': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('disrepair-addendum'));
    });
  });
}
