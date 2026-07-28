import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - I1 Regulations parity', () {
    const phraseTexts = <String, String>{
      '{ISSUE_REGULATIONS}::{REGULATIONS_BUILDING_REGULATION}':
          'building-reg={BUILDING_REGULATION}',
      '{ISSUE_REGULATIONS}::{REGULATIONS_PLANNING_PERMISSION}':
          'planning={PLANNING_PERMISSION}',
      '{ISSUE_REGULATIONS}::{REGULATIONS_GLAZED_SECTIONS}':
          'glazed={GLAZED_SECTIONS}',
      '{ISSUE_REGULATIONS}::{REGULATIONS_NEW_BUILD}': 'new-build',
      '{ISSUE_REGULATIONS}::{REGULATIONS_CONVERSION_STATUS_KNOW}':
          'conversion-known=built-as:{REG_CONV_STATUS_KNOWN_ORI_BUILT}',
      '{ISSUE_REGULATIONS}::{REGULATIONS_CONVERSION_STATUS_UNKNOW}':
          'conversion-unknown',
      '{ISSUE_REGULATIONS}::{REGULATIONS_CONSERVATION}': 'conservation',
      '{ISSUE_REGULATIONS}::{REGULATIONS_LISTED_BUILDING}': 'listed-building',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('building regulation resolves the removed items', () {
      final phrases = engine.buildPhrases(
        'activity_issues_regulation',
        {'cb_removed_wall': 'true', 'cb_conservatory': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('building-reg=wall and conservatory'));
    });

    test('planning permission resolves the selected items', () {
      final phrases = engine.buildPhrases(
        'activity_issues_regulation',
        {'cb_kitchen_extension': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('planning=kitchen extension'));
    });

    test('glazed sections resolves the selected items', () {
      final phrases = engine.buildPhrases(
        'activity_issues_regulation',
        {'cb_windows': 'true', 'cb_doors': 'true'},
      );
      expect(phrases.join(' ').toLowerCase(),
          contains('glazed=windows and doors'));
    });

    test('new build is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_issues_regulation',
        {'cb_new_build': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first, 'new-build');

      final unchecked = engine.buildPhrases(
        'activity_issues_regulation',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('converted building resolves known vs unknown original build type',
        () {
      final known = engine.buildPhrases(
        'activity_issues_regulation',
        {
          'cb_converted_building': 'true',
          'actv_before_built_as': 'A semi detached house',
        },
      );
      expect(
        known.join(' ').toLowerCase(),
        contains('conversion-known=built-as:a semi detached house'),
      );

      final unknown = engine.buildPhrases(
        'activity_issues_regulation',
        {'cb_converted_building': 'true'},
      );
      expect(unknown.join(' ').toLowerCase(),
          contains('conversion-unknown'));
    });

    test('conservation area and listed building fire independently', () {
      final phrases = engine.buildPhrases(
        'activity_issues_regulation',
        {'cb_conservation': 'true', 'cb_listed_building': 'true'},
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('conservation'));
      expect(all, contains('listed-building'));
    });
  });
}
