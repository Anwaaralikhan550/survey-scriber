import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// Verbatim-completion emission tests (plan T5) for section E1 (chimneys).
/// Expected strings are copied character-for-character from
/// "Surveyscriber Phrase Bank (1).pdf".
void main() {
  late InspectionPhraseEngine engine;

  setUpAll(() {
    final bank = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    engine = InspectionPhraseEngine(bank);
  });

  String run(Map<String, String> answers) => engine
      .buildPhrases('activity_outside_property_water_proofing', answers)
      .join('\n');

  group('E1 Flashings / Flaunching (waterproofing screen)', () {
    const flashingStem = 'The waterproofing between the chimney stack and the '
        'roof covering (called the flashing) appears to be formed in';
    const flaunchingStem = 'The cement bedding around the base of the chimney '
        'pot (called flaunching) appears to be formed in';

    final flashingOptions = <String, String>{
      'ch1': 'lead',
      'ch_flashing_lead_substitute': 'lead substitute',
      'ch2': 'mortar',
      'ch_flashing_bricks': 'bricks',
      'ch4': 'tiles',
    };
    final flaunchingOptions = <String, String>{
      'ch7': 'mortar',
      'ch_flaunching_bricks': 'bricks',
      'ch_flaunching_concrete': 'concrete',
      'ch9': 'tiles',
    };

    test('every PDF flashing option produces the exact PDF sentence', () {
      flashingOptions.forEach((id, label) {
        final out = run({id: 'true'});
        expect(out, contains('$flashingStem $label.'), reason: id);
        expect(out, isNot(contains('{')), reason: id);
      });
    });

    test('every PDF flaunching option produces the exact PDF sentence', () {
      flaunchingOptions.forEach((id, label) {
        final out = run({id: 'true'});
        expect(out, contains('$flaunchingStem $label.'), reason: id);
        expect(out, isNot(contains('{')), reason: id);
      });
    });

    test('several selections are joined, "Other" uses the typed text', () {
      final out = run({
        'ch1': 'true',
        'ch2': 'true',
        'ch5': 'true',
        'etGroundTypeOther': 'zinc',
      });
      expect(out, contains('$flashingStem lead, mortar and zinc.'));
    });

    test('PDF flashing condition sentence and advisory', () {
      for (final c in ['good', 'reasonable', 'poor', 'defective']) {
        final out = run({
          'ch1': 'true',
          'actv_flashing_condition': c[0].toUpperCase() + c.substring(1),
        });
        expect(
          out,
          contains('Where visible, the flashings appear in $c condition. '
              'Defective flashings may allow water penetration and should be '
              'repaired by an appropriately qualified roofing contractor.'),
          reason: c,
        );
      }
    });

    test('PDF flaunching condition sentence and advisory', () {
      for (final c in ['good', 'reasonable', 'poor', 'defective']) {
        final out = run({
          'ch7': 'true',
          'actv_flaunching_condition': c[0].toUpperCase() + c.substring(1),
        });
        expect(
          out,
          contains('Where visible, the flaunching appears in $c condition. '
              'Defective flaunching may permit water penetration and reduce '
              'the stability of chimney pots. Repairs should be undertaken as '
              'part of routine maintenance or sooner where deterioration is '
              'significant.'),
          reason: c,
        );
      }
    });

    test('flashings and flaunching are independent', () {
      final onlyFlashing = run({'ch1': 'true'});
      expect(onlyFlashing, contains(flashingStem));
      expect(onlyFlashing, isNot(contains(flaunchingStem)));
      final onlyFlaunching = run({'ch7': 'true'});
      expect(onlyFlaunching, contains(flaunchingStem));
      expect(onlyFlaunching, isNot(contains(flashingStem)));
    });

    test('previously saved legacy ids still render', () {
      expect(run({'ch3': 'true'}), contains('$flashingStem lead and mortar.'));
      expect(run({'ch6': 'true'}), contains('$flaunchingStem lead.'));
    });

    test('nothing selected produces nothing', () {
      expect(run({}), isEmpty);
    });
  });
}
