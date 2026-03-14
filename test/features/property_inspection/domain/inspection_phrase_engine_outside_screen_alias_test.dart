import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - outside screen id aliases', () {
    const phraseTexts = <String, String>{
      '{E_ROOF_COVERING_REPAIR}::{ROOF_FIT_FOR_PURPOSE}': 'roof-fit',
      '{E_ROOF_COVERING_REPAIR}::{END_OF_USEFUL_LIFE}': 'roof-eoul',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_BLOCKED}': 'rwg-blocked',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_BLOCKED_GULLIES}':
          'rwg-blocked-gullies',
      '{E_RAINWATER_GOODS_ABOUT}::{RWG_OPEN_RUNOFFS}': 'rwg-open-runoffs',
      '{E_RAINWATER_GOODS_ABOUT}::{RAINWATER_GOODS_SHARED}': 'rwg-shared',
      '{E_WINDOWS}::{WINDOWS_RANDOM_SAMPLING}': 'windows-random-sampling',
      '{E_WINDOWS}::{WINDOWS_IN_POOR_CONDITION}': 'windows-poor-condition',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('legacy roof covering screen routes to roof covering summary handler',
        () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_roof_covering',
        <String, String>{
          'cb_roof_fit_for_pupose': 'true',
          'cb_end_of_useful_life': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('roof-fit'));
      expect(all, contains('roof-eoul'));
    });

    test('legacy rainwater goods screen emits blocked/open/shared phrases', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_rainwater_goods',
        <String, String>{
          'cb_blocked_rwg': 'true',
          'cb_blocked_gullies': 'true',
          'cb_open_runoffs': 'true',
          'cb_Shared_RWG': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('rwg-blocked'));
      expect(all, contains('rwg-blocked-gullies'));
      expect(all, contains('rwg-open-runoffs'));
      expect(all, contains('rwg-shared'));
    });

    test('legacy windows screen routes to windows main screen handler', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows',
        <String, String>{
          'cb_window_random_sampling': 'true',
          'cb_window_in_poor_condition': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('windows-random-sampling'));
      expect(all, contains('windows-poor-condition'));
    });
  });
}
