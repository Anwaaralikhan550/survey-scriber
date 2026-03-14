import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - WAP dampness parity', () {
    const phraseTexts = <String, String>{
      '{F_WALLS_AND_PARTITIONS}::{DAMPNESS_NONE}': 'damp-none',
      '{F_WALLS_AND_PARTITIONS}::{DAMPNESS_NOTED}':
          'damp-present={WAP_DAMP_LOCATION}',
      '{F_WALLS_AND_PARTITIONS}::{CAUSES_KNOWN}':
          'damp-known={WAP_DAMP_KNOWN_CAUSED_BY}',
      '{F_WALLS_AND_PARTITIONS}::{CAUSES_UNKNOWN}': 'damp-unknown',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('unknown cause emits the legacy unknown phrase', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wap_dampness',
        <String, String>{
          'damp_status': 'Present',
          'et_location': 'lower walls in the kitchen',
          'actv_status_91': 'Unknown',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('damp-present=lower walls in the kitchen'));
      expect(all, contains('damp-unknown'));
      expect(all, isNot(contains('damp-known=')));
    });

    test('known cause emits only the legacy known phrase', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_wap_dampness',
        <String, String>{
          'damp_status': 'Present',
          'et_location': 'hall wall',
          'actv_status_91': 'Known',
          'cb_leaking_pipes': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('damp-present=hall wall'));
      expect(all, contains('damp-known=leaking pipes'));
      expect(all, isNot(contains('damp-unknown')));
    });
  });
}
