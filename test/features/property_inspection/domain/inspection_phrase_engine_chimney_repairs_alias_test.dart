import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - chimney repairs alias compatibility', () {
    const phraseTexts = <String, String>{
      '{E_CHIMNEY_FLAUNCHING_REPAIR}::{FLAUNCHING_REPAIR_SOON}':
          'flaunching-soon {CS_FLAUNCHING_REPAIR_STACKS} {CS_FLAUNCHING_REPAIR_ISSUE}',
      '{E_CHIMNEY_POTS_REPAIR}::{CHIMNEY_POTS_REPAIR_SOON}':
          'pots-soon {CS_POTS_REPAIR_STACKS} {CS_POTS_REPAIR_ISSUE}',
      '{E_CHIMNEY_REPOINTING_REPAIR}::{CHIMNEY_REPOINTING_REPAIR_SOON}':
          'repointing-soon {CS_REPOINTING_REPAIR_STACKS} {CS_REPOINTING_REPAIR_ISSUES}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('flaunching accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_chimney_repair_flaunching',
        {
          'llMainContainer': 'Repair soon',
          'cb_main_building_56': 'true',
          'cb_cracked': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('flaunching-soon'));
    });

    test('pots accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_repair_chimney_pots',
        {
          'llMainContainer': 'Repair soon',
          'cb_main_building_71': 'true',
          'cb_cracked': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('pots-soon'));
    });

    test('repointing accepts legacy llMainContainer condition', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_repair_chimney_repointing',
        {
          'llMainContainer': 'Repair soon',
          'cb_main_building_25': 'true',
          'cb_has_eroded': 'true',
        },
      );

      expect(phrases, isNotEmpty);
      expect(phrases.join(' ').toLowerCase(), contains('repointing-soon'));
    });
  });
}
