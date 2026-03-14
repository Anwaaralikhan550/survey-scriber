import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - windows parity', () {
    const phraseTexts = <String, String>{
      '{E_WINDOWS}::{WINDOWS_ABOUT}':
          'about={WINDOW_ABOUT_WINDOW_MADE_UP}/{WINDOW_ABOUT_WINDOW_TYPE}/{WINDOW_ABOUT_WINDOW_GLAZING}',
      '{E_WINDOWS}::{WINDOW_WALL_SEALING}': 'wall-sealing={WINDOW_WALL_SEALING}',
      '{E_WINDOWS}::{WINDOW_SILL_PROJECTION}':
          'sill={WINDOW_SILL_PROJECTION_TYPE}/{WINDOW_SILL_PROJECTION_CONDITION}',
      '{WINDOW_VELUX_TYPE}::{WINDOW_VELUX_TYPE_SINGLE}':
          'velux-single={WINDOW_VELUX_LOCATION}/{WINDOW_VELUX_STATUS_TYPE}/{WINDOW_VELUX_GLAZZING}',
      '{WINDOW_VELUX_TYPE}::{WINDOW_VELUX_CONDITION}':
          'velux-condition={WINDOW_VELUX_CONDITION}',
      '{WINDOWS_SAFETY_GLASS_RATING_STATUS}::{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED}':
          'sg_noted {WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED_CONDITION}',
      '{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED}::{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED_CONDITION}':
          'condition={WINDOW_SAFETY_STATUS_NOTED_CONDITION}',
      '{WINDOWS_SAFETY_GLASS_RATING_STATUS}::{WINDOWS_SAFETY_GLASS_RATING_STATUS_NO_SG_RATING}':
          'sg_missing',
      '{E_WINDOWS_REPAIR}::{WINDOWS_REPAIR}':
          'repair {WINDOWS_REPAIR_WINDOW_LOCATION} {WINDOWS_REPAIR_WINDOW_DEFECT}',
      '{RISK_TO_PEOPLE}::{E_WINDOWS_REPAIR_SAFETY_HAZARD}':
          '{WINDOWS_REPAIR_WINDOW_HOW_MANY} of the window(s) {IS_ARE} {WINDOWS_REPAIR_WINDOW_DEFECT} and are a safety hazard.',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('about window screen still emits safety status phrase', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_aboutwindow',
        <String, String>{
          'actv_made_up_of': 'mostly',
          'cb_pvc': 'true',
          'cb_double': 'true',
          'actv_status': 'Noted',
          'actv_condition': 'reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('sg_noted'));
      expect(phrases.join(' ').toLowerCase(), contains('condition=reasonable'));
    });

    test('about window accepts legacy llMainContainer as made-up value', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_aboutwindow',
        <String, String>{
          'llMainContainer': 'mostly',
          'cb_pvc': 'true',
          'cb_double': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('about=mostly/'));
    });

    test('wall sealing accepts legacy llMainContainer value', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_wall_sealing',
        <String, String>{
          'llMainContainer': 'reasonable',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('wall-sealing=reasonable'));
    });

    test('sill projection accepts legacy llMainContainer projection', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_sill_projection',
        <String, String>{
          'llMainContainer': 'projecting',
          'actv_condition': 'good',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('sill=projecting/good'));
    });

    test('velux accepts legacy llMainContainer type', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_velux_window',
        <String, String>{
          'llMainContainer': 'single',
          'cb_loft': 'true',
          'cb_pvc': 'true',
          'cb_double': 'true',
          'actv_condition': 'reasonable',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('velux-single='));
      expect(all, contains('velux-condition=reasonable'));
    });

    test('safety glass rating screen is legacy no-op', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_safety_glass_rating',
        <String, String>{
          'actv_status': 'Noted',
          'actv_condition': 'reasonable',
        },
      );

      expect(phrases, isEmpty);
    });

    test('repair window emits legacy safety-hazard risk text using how many', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_repairs_repair_window',
        <String, String>{
          'cb_ch1': 'true',
          'cb_lounge_791': 'true',
          'cb_have_damaged_locks_63': 'true',
          'cb_safety_hazard': 'true',
        },
      );

      final all = phrases.join(' ');
      expect(all.toLowerCase(), contains('repair property have damaged locks'));
      expect(all, contains('One of the window(s) is'));
      expect(all.toLowerCase(), contains('safety hazard'));
    });
  });
}
