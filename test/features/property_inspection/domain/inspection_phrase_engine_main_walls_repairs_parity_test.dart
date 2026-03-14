import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - main walls repairs parity', () {
    const phraseTexts = <String, String>{
      '{E_MAIN_WALL_REPAIR}::{WALL_SPALLING_REPAIR_WALLS}':
          'spalling branch={REPAIR_SOON_NOW}; walls={MAIN_WALL_REPAIR_SPALLING_WALLS}; loc={MAIN_WALL_REPAIR_SPALLING_LOCATION}',
      '{WALL_SPALLING_REPAIR_WALLS}::{WALL_SPALLING_REPAIR_SOON}': 'soon',
      '{WALL_SPALLING_REPAIR_WALLS}::{WALL_SPALLING_REPAIR_NOW}': 'now',
      '{E_MAIN_WALL_REPAIR}::{WALL_RENDER_REPAIR_WALLS}':
          'render branch={REPAIR_SOON_NOW}; walls={MAIN_WALL_REPAIR_RENDER_WALLS}; loc={MAIN_WALL_REPAIR_RENDER_LOCATION}; defects={MAIN_WALL_REPAIR_RENDER_DEFECTS}',
      '{WALL_RENDER_REPAIR_WALLS}::{WALL_RENDER_REPAIR_SOON}': 'soon',
      '{WALL_RENDER_REPAIR_WALLS}::{WALL_RENDER_REPAIR_NOW}': 'now',
      '{E_MAIN_WALL_REPAIR}::{WALL_LINTEL_REPAIR}':
          'lintel opening={MAIN_WALL_REPAIR_LINTEL_OPENING_TO}; branch={REPAIR_SOON_NOW}; walls={MAIN_WALL_REPAIR_LINTEL_WALLS}; loc={MAIN_WALL_REPAIR_LINTEL_LOCATION}; defects={MAIN_WALL_REPAIR_LINTEL_DEFECT}',
      '{WALL_LINTEL_REPAIR}::{WALL_LINTEL_REPAIR_SOON}': 'soon',
      '{WALL_LINTEL_REPAIR}::{WALL_LINTEL_REPAIR_NOW}': 'now',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('spalling uses condition branch even when causing-damp is checked', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_wall_repairs_spalling',
        <String, String>{
          'actv_condition': 'Repair soon',
          'cb_causing_damp': 'true',
          'cb_front': 'true',
          'cb_main_building': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('branch=soon'));
    });

    test('render uses condition branch even when causing-damp is checked', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_wall_repairs_render',
        <String, String>{
          'actv_condition': 'Repair soon',
          'cb_causing_damp': 'true',
          'cb_front': 'true',
          'cb_main_building': 'true',
          'cb_cracked_96': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('branch=soon'));
    });

    test('lintel default opening is singular "window" on non-door screen', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_wall_repairs_lintel',
        <String, String>{
          'actv_condition': 'Repair soon',
          'cb_front': 'true',
          'cb_main_building': 'true',
          'cb_eroded': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('opening=window'));
      expect(phrases.first.toLowerCase(), isNot(contains('opening=windows')));
    });

    test('spalling accepts legacy llMainContainer repair type', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_wall_repairs_spalling',
        <String, String>{
          'llMainContainer': 'Repair soon',
          'cb_front': 'true',
          'cb_main_building': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('branch=soon'));
    });

    test('lintel accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_wall_repairs_lintel',
        <String, String>{
          'llMainContainer': 'Repair soon',
          'cb_front': 'true',
          'cb_main_building': 'true',
          'cb_eroded': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('branch=soon'));
    });
  });
}
