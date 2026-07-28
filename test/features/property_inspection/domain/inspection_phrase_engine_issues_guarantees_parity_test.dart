import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - I2 Guarantees parity', () {
    const phraseTexts = <String, String>{
      '{ISSUE_GUARANTEES}::{GUARANTEES_GLAZED_SECTION}':
          'glazed={ISSUE_GLAZED_SECTION}',
      '{ISSUE_GUARANTEES}::{GUARANTEES_DPC_TREATMENT}': 'dpc-treatment',
      '{ISSUE_GUARANTEES}::{GUARANTEES_REMOVED_WALL}': 'removed-wall',
      '{ISSUE_GUARANTEES}::{GUARANTEES_BUILDING_WORK}': 'building-work',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('glazed section resolves the selected items', () {
      final phrases = engine.buildPhrases(
        'activity_issues_glazed_sections',
        {'cb_chimney_stack': 'true', 'cb_rainwater_goods': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('glazed=windows and doors'));
    });

    test('DPC treatment, removed wall and building work fire independently',
        () {
      final phrases = engine.buildPhrases(
        'activity_issues_glazed_sections',
        {
          'cb_private_road': 'true',
          'cb_party_walls': 'true',
          'cb_tenanted': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('dpc-treatment'));
      expect(all, contains('removed-wall'));
      expect(all, contains('building-work'));
    });

    test('with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_issues_glazed_sections',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });
  });
}
