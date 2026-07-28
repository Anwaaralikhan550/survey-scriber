import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - I3 Other Matters parity', () {
    const phraseTexts = <String, String>{
      '{ISSUE_OTHER_MATTERS}::{OTHER_MATTERS_FREEHOLD}': 'freehold',
      '{ISSUE_OTHER_MATTERS}::{OTHER_MATTERS_LEASEHOLD}': 'leasehold',
      '{ISSUE_OTHER_MATTERS}::{OTHER_MATTERS_RIGHT_OF_WAY}': 'right-of-way',
      '{ISSUE_OTHER_MATTERS}::{OTHER_SHARED_STACKS_AND_RWG}':
          'shared-stacks={SHARED_STACKS_AND_RWG}',
      '{ISSUE_OTHER_MATTERS}::{OTHER_MATTERS_PRIVATE_ROAD}':
          'private-road-desc. This is in {OM_PRIVATE_ROAD_CONDITION} '
              'condition. private-road-end',
      '{ISSUE_OTHER_MATTERS}::{OTHER_MATTERS_PARTY_WALLS}': 'party-walls',
      '{ISSUE_OTHER_MATTERS}::{OTHER_MATTERS_TENANTED}': 'tenanted',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('freehold and leasehold fire independently', () {
      final freehold = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_freehold': 'true'},
      );
      expect(freehold, contains('freehold'));

      final leasehold = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_leasehold': 'true'},
      );
      expect(leasehold, contains('leasehold'));
    });

    test('right of way is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_right_of_way': 'true'},
      );
      expect(checked, contains('right-of-way'));

      final unchecked = engine.buildPhrases(
        'activity_issues_other_matters',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });

    test('shared stacks and rainwater goods resolves the selected items', () {
      final phrases = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_chimney_stack': 'true', 'cb_rainwater_goods': 'true'},
      );
      expect(
        phrases.join(' ').toLowerCase(),
        contains('shared-stacks=chimney stack(s) and rainwater goods'),
      );
    });

    test('private road resolves condition when answered, drops the clause otherwise',
        () {
      final withCondition = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_private_road': 'true', 'actv_condition': 'Poor'},
      );
      expect(withCondition.join(' ').toLowerCase(),
          contains('this is in poor condition'));

      final withoutCondition = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_private_road': 'true'},
      );
      expect(withoutCondition, isNotEmpty);
      final withoutAll = withoutCondition.join(' ').toLowerCase();
      expect(withoutAll, isNot(contains('this is in')));
      expect(withoutAll, isNot(contains('{')));
      expect(withoutAll, contains('private-road-desc'));
      expect(withoutAll, contains('private-road-end'));
    });

    test('party walls and tenanted fire independently', () {
      final phrases = engine.buildPhrases(
        'activity_issues_other_matters',
        {'cb_party_walls': 'true', 'cb_tenanted': 'true'},
      );
      expect(phrases, containsAll(['party-walls', 'tenanted']));
    });
  });
}
