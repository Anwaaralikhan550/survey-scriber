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

  group('Overall opinion: revised-spec rating (reasonable/good/fair/poor)', () {
    List<String> opinion(String rating) => engine.buildPhrases(
          'activity_over_all_openion',
          {'android_material_design_spinner5': rating},
        );

    test('reasonable keeps the favourable opener and reads "reasonable"', () {
      final phrases = opinion('Reasonable');
      expect(phrases, hasLength(1));
      final text = phrases.single;
      expect(text, contains('I am pleased to advise'));
      expect(text,
          contains('the property represents a reasonable proposition'));
      expect(text, isNot(contains('{')));
    });

    test('good/fair/poor substitute the adjective and drop the opener', () {
      for (final rating in ['Good', 'Fair', 'Poor']) {
        final phrases = opinion(rating);
        expect(phrases, isNotEmpty, reason: '$rating should emit text');
        final text = phrases.join(' ');
        expect(
          text,
          contains(
              'the property represents a ${rating.toLowerCase()} proposition'),
          reason: '$rating adjective must be substituted',
        );
        // The favourable "pleased to advise" opener is only for a reasonable
        // verdict — never shown for good/fair/poor.
        expect(text, isNot(contains('I am pleased to advise')),
            reason: '$rating must not carry the favourable opener');
        expect(text, startsWith('In my opinion,'));
        // No placeholder or rating token leaks into the report.
        expect(text, isNot(contains('{')), reason: '$rating: no token leak');
      }
    });

    test('"reasonable with repair" still routes to the repair narrative', () {
      final phrases = engine.buildPhrases(
        'activity_over_all_openion',
        {
          'android_material_design_spinner5': 'Reasonable with repair',
          'android_material_design_spinner': '1500',
          'android_material_design_spinner2': 'Roof repairs',
        },
      );
      expect(phrases, contains(contains('provisional repair allowance')));
      expect(phrases.join(' '), isNot(contains('{')));
    });
  });

  group('F1 Roof Structure: revised-spec additions', () {
    List<String> about(Map<String, String> answers) =>
        engine.buildPhrases('activity_inside_property_about_roof_structure',
            answers);

    test('spray foam checkbox emits the spray-foam advisory', () {
      final phrases = about({'cb_spray_foam': 'true'});
      expect(phrases, hasLength(1));
      expect(phrases.single, startsWith('Spray foam insulation:'));
      expect(phrases.single, contains('mortgageability, insurability'));
      expect(phrases.single, isNot(contains('{')));
    });

    test('water-penetration checkbox emits the water-penetration advisory', () {
      final phrases = about({'cb_water_penetration': 'true'});
      expect(phrases, hasLength(1));
      expect(phrases.single, startsWith('Evidence of Water Penetration:'));
      expect(phrases.single, contains('Water staining or dampness'));
    });

    test('capped soil-vent-pipe checkbox emits its advisory', () {
      final phrases = about({'cb_capped_soil_vent_pipe': 'true'});
      expect(phrases, hasLength(1));
      expect(phrases.single, startsWith('Capped Soil Vent Pipe:'));
      expect(phrases.single, contains('terminating within the roof space'));
    });

    test('the three advisories can combine with the construction sentence', () {
      final phrases = about({
        'f1d_traditional_cut_timber': 'true',
        'cb_spray_foam': 'true',
        'cb_water_penetration': 'true',
        'cb_capped_soil_vent_pipe': 'true',
      });
      expect(phrases.any((p) => p.startsWith('Description:')), isTrue);
      expect(phrases.any((p) => p.startsWith('Spray foam insulation:')), isTrue);
      expect(
          phrases.any((p) => p.startsWith('Evidence of Water Penetration:')),
          isTrue);
      expect(phrases.any((p) => p.startsWith('Capped Soil Vent Pipe:')), isTrue);
      expect(phrases.join(' '), isNot(contains('{')));
    });

    test('no roof-structure advisory when nothing is selected', () {
      expect(about(const {}), isEmpty);
    });
  });
}
