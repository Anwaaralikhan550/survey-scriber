import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - main walls about routing parity', () {
    const phraseTexts = <String, String>{
      '{E_MAIN_WALLS}::{WALL}':
          'Wall={WALL}; Location={WALL_LOCATION}; Thickness={WALL_THICKNESS}.',
      '{E_MAIN_WALLS}::{FINISHES}':
          'Finishes={WALL_FINISHES}; Rendered={WALL_RENDERED}; Type={WALL_FINISHES_TYPE}.',
      '{E_MAIN_WALLS}::{WEATHERED_WALL}': 'Weathered.',
      '{E_MAIN_WALLS}::{WALL_CONDITION}': 'Condition={CONDITION}.',
      '{E_MAIN_WALLS}::{SOLID_BOUNDED_BRICK_WALL}':
          'SOLID [{WALL}] [{FINISHES}] [{WEATHERED_WALL}] [{WALL_CONDITION}]',
      '{E_MAIN_WALLS}::{CAVITY_BRICK_WALL}':
          'CAVITY_BRICK [{WALL}] [{FINISHES}] [{WEATHERED_WALL}] [{WALL_CONDITION}]',
      '{E_MAIN_WALLS}::{CAVITY_BLOCK_WALL}':
          'CAVITY_BLOCK [{WALL}] [{FINISHES}] [{WEATHERED_WALL}] [{WALL_CONDITION}]',
      '{E_MAIN_WALLS}::{CAVITY_STUD_WALL}':
          'CAVITY_STUD [{WALL}] [{FINISHES}] [{WEATHERED_WALL}] [{WALL_CONDITION}]',
      '{E_MAIN_WALLS}::{OTHER_WALL}':
          'OTHER [{WALL}] [{FINISHES}] [{WEATHERED_WALL}] [{WALL_CONDITION}]',
      '{E_MAIN_WALLS}::{WALLLS_REMOVED_WALL_DEFECTS}':
          'REMOVED_DEFECTS Location={MAIN_WALL_REMOVED_LOCATION}; Defect={MAIN_WALL_REMOVED_DEFECT}.',
      '{E_MAIN_WALLS}::{REMOVED_WALL_LOCATION}':
          'REMOVED_LOCATION Location={MAIN_WALL_REMOVED_LOCATION}.',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    Map<String, String> buildBaseAnswers() => <String, String>{
          'cb_main_building': 'true',
          'et_thickness': '225',
          'actv_finishes': 'fully',
          'actv_rendered': 'rendered',
          'cb_painted': 'true',
          'actv_condition': 'Reasonable',
        };

    test('solid wall phrase resolves on base about-wall screen', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall',
        buildBaseAnswers(),
      );

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('SOLID'));
      expect(phrases.first.toLowerCase(), contains('solid brick wall'));
    });

    test('solid wall still emits phrase when thickness is missing', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall',
        <String, String>{
          'cb_main_building': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('solid brick wall'));
      expect(phrases.first.toLowerCase(), contains('main building'));
    });

    test('solid wall emits phrase when only thickness is entered', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall',
        <String, String>{
          'et_thickness': '225',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('solid brick wall'));
      expect(phrases.first, contains('Thickness=225'));
    });

    test('finishes phrase emits from dropdowns even without finishes type', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall',
        <String, String>{
          'actv_finishes': 'fully',
          'actv_rendered': 'roughcast',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('Finishes=fully'));
      expect(phrases.first, contains('Rendered=roughcast'));
    });

    test('finishes type emits phrase even without finishes dropdown values',
        () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall',
        <String, String>{
          'cb_main_building': 'true',
          'cb_painted': 'true',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('painted'));
    });

    test(
        'cavity brick phrase resolves from screen suffix without wall checkbox',
        () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall__cavity_brick_wall',
        buildBaseAnswers(),
      );

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('CAVITY_BRICK'));
      expect(phrases.first.toLowerCase(), contains('cavity brick wall'));
    });

    test('other wall phrase resolves from typed wall name on __other screen',
        () {
      final answers = buildBaseAnswers()
        ..['other'] = 'Stone wall'
        ..['cb_is_weathered'] = 'true';

      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_about_wall__other',
        answers,
      );

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('OTHER'));
      expect(phrases.first.toLowerCase(), contains('stone wall'));
      expect(phrases.first, contains('Weathered.'));
    });

    test(
        'removed wall falls back to location phrase when defects-noted has no selected defects',
        () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_removed_wall',
        <String, String>{
          'cb_lounge': 'true',
          'cb_defects_noted': 'true',
          'EtDescribeDefect': 'free text should be ignored',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('REMOVED_LOCATION'));
      expect(phrases.first.toLowerCase(), contains('lounge'));
    });

    test('removed wall ignores EtDescribeDefect in defects phrase', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_removed_wall',
        <String, String>{
          'cb_lounge': 'true',
          'cb_defects_noted': 'true',
          'cb_cracked': 'true',
          'EtDescribeDefect': 'free text should be ignored',
        },
      );

      expect(phrases, hasLength(1));
      expect(phrases.first, contains('REMOVED_DEFECTS'));
      expect(phrases.first.toLowerCase(), contains('cracked'));
      expect(phrases.first.toLowerCase(),
          isNot(contains('free text should be ignored')));
    });
  });
}
