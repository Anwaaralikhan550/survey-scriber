import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// Phase 3 regression suite: Section D handlers must emit the approved
/// phrase-bank sentences, not ad-hoc "Label: value" output (client
/// complaint: "phrases that have not come from the approved database bank").
void main() {
  late InspectionPhraseEngine engine;

  setUpAll(() {
    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    engine = InspectionPhraseEngine(phraseTexts);
  });

  group('D-Construction: approved templates', () {
    test('property construction uses CONSTRUCTION_TYPE_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_property_construction',
        {'ch3': 'true', 'ch4': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The property is believed to be constructed using cavity wall and '
        'timber frame construction.',
      );
    });

    test('roof uses CONSTRUCTION_ROOF_AREA without built-with clause', () {
      final phrases = engine.buildPhrases(
        'activity_property_roof',
        {'ch2': 'true', 'ch8': 'true', 'ch6': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The main roof is of pitched construction. The roof covering is '
        'formed in concrete tiles.',
      );
    });

    test('roof with partial data (type only) emits nothing, not a fragment',
        () {
      final phrases = engine.buildPhrases(
        'activity_property_roof',
        {'ch2': 'true'},
      );
      expect(phrases, isEmpty,
          reason: 'no "covered in ." fragments (client-reported defect)');
    });

    test('external walls use CONSTRUCTION_EXT_WALL_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_extended_wall',
        {'ch2': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The external walls are constructed of cavity brick wall '
        'construction.',
      );
    });

    test('internal walls use CONSTRUCTION_INT_WALL_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_internal_wall',
        {'ch1': 'true', 'ch2': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'Internal walls are formed in stud and solid partitions.',
      );
    });

    test('floors use CONSTRUCTION_FLOOR_AREA with correct grammar', () {
      final phrases = engine.buildPhrases(
        'activity_construction_floor',
        {'ch1': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The floors are mainly of suspended timber construction.',
      );
      expect(phrases.single, isNot(contains('of mainly of')),
          reason: 'client-reported grammar bug must not reappear');
    });

    test('windows use CONSTRUCTION_WINDOWS_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_construction_window',
        {'ch2': 'true', 'ch5': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The windows are fitted with uPVC frames incorporating double '
        'glazing.',
      );
    });
  });

  group('D-Ground: approved garden templates', () {
    test('front garden screen uses GROUND_FRONT_GARDEN + fence sentence', () {
      final phrases = engine.buildPhrases(
        'activity_front_garden',
        {'ch1': 'true', 'ch8': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The front garden is laid to paved. The boundary fences are '
        'formed in timber.',
      );
    });

    test('no-boundary variant uses GARDEN_NO_BOUNDRY_FENCES', () {
      final phrases = engine.buildPhrases(
        'activity_rear_garden',
        {'ch2': 'true', 'ch20': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The rear garden is laid to lawned. There are no boundary '
        'fences installed.',
      );
    });

    test('combined garden screen emits approved sentence per area', () {
      final phrases = engine.buildPhrases(
        'activity_garden',
        {
          'android_material_design_spinner': 'Paved',
          'android_material_design_spinner2': 'Timber',
          'android_material_design_spinner3': 'Lawned',
        },
      );
      expect(phrases, hasLength(2));
      expect(
        phrases.first,
        'The front garden is laid to paved. The boundary fences are '
        'formed in timber.',
      );
      expect(phrases.last, 'The rear garden is laid to lawned.');
    });

    test('topography uses GROUND_TOPOGRAPHY', () {
      final phrases = engine.buildPhrases(
        'activity_topography',
        {'android_material_design_spinner': 'Level'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The property occupies a level site.',
      );
    });
  });

  group('E condition-rating coverage', () {
    test('main walls emits the approved rating and notes wording', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_main_screen',
        {
          'android_material_design_spinner4': '2',
          'ar_etNote': 'Monitor the repaired wall finish.',
        },
      );

      expect(phrases, contains('Condition rating is: 2.'));
      expect(phrases, contains('Notes:'));
      expect(phrases, contains('Monitor the repaired wall finish.'));
    });

    test('windows emits the approved rating and notes wording', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_main_screen',
        {
          'android_material_design_spinner4': '3',
          'ar_etNote': 'Obtain quotations before exchange.',
        },
      );

      expect(phrases, contains('Condition rating is: 3.'));
      expect(phrases, contains('Notes:'));
      expect(phrases, contains('Obtain quotations before exchange.'));
    });
  });
}
