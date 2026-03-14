import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - main walls status alias compatibility', () {
    const phraseTexts = <String, String>{
      '{E_MAIN_WALLS}::{WALLS_CLADDING}':
          'cladding={MAIN_WALL_CLADDING_TYPE}/{MAIN_WALL_CLADDING_CLADDED_WITH}',
      '{E_MAIN_WALLS}::{WALLS_DPC_VISIBLE}':
          'dpc-visible={MAIN_WALL_DPC_CONSIST}',
      '{E_MAIN_WALLS}::{WALLS_DAMP_TYPE_NONE}': 'damp-none',
      '{MAIN_WALL_MOVEMENTS_TYPE}::{MAIN_WALL_MOVEMENTS_TYPE_USUAL}':
          'movement-usual',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('cladding accepts legacy llMainContainer type', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_cladding',
        <String, String>{
          'llMainContainer': 'partially',
          'cb_timber': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('cladding=partially/'));
    });

    test('dpc accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_dpc',
        <String, String>{
          'llMainContainer': 'Visible',
          'cb_plastic': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('dpc-visible=plastic'));
    });

    test('damp accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_damp',
        <String, String>{
          'llMainContainer': 'None',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('damp-none'));
    });

    test('movements accepts legacy llMainContainer status', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_movements',
        <String, String>{
          'llMainContainer': 'Usual',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('movement-usual'));
    });
  });
}
