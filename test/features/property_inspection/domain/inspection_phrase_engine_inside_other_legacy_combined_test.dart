import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - inside other legacy combined screens', () {
    const phraseTexts = <String, String>{
      '{F_OTHER}::{BASEMENT_NOT_IN_USE}': 'basement-not-in-use',
      '{F_OTHER}::{CELLAR_IN_USE}':
          'cellar-in-use={OTH_CELLAR_UA}/{OTH_CELLAR_UA_CONDITION}',
      '{F_OTHER}::{CELLAR_DAMP}': 'cellar-damp={OTH_CELLAR_DAMP}',
      '{F_OTHER}::{BASEMENT_NOT_HABITABLE}':
          'basement-not-habitable={OTH_BASEMENT_NH_BECAUSE}',
      '{F_OTHER}::{CELLAR_FLOODED}': 'cellar-flooded={OTH_CELLAR_FLOODED}',
      '{F_OTHER}::{CELLAR_NO_ACCESS}':
          'cellar-no-access={OTH_CELLAR_NA_BECAUSE}',
      '{F_OTHER}::{CELLAR_SERIOUS_DAMP}': 'cellar-serious-damp',
      '{F_OTHER}::{CELLAR_JOINT_DECAY}': 'cellar-joists-decay',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('legacy basement status "Not in use" emits not-in-use phrase', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_basement',
        <String, String>{
          'llMainContainer': 'Not in use',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('basement-not-in-use'));
    });

    test('legacy cellar "used as" emits in-use phrase', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_cellar',
        <String, String>{
          'actv_used_as': 'Storage',
          'actv_condition': 'Fair',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('cellar-in-use=storage/fair'));
    });

    test('legacy cellar damp ids map to current damp phrase fields', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_cellar',
        <String, String>{
          'cb_to_the_lower_walls_of_24': 'true',
          'cb_is_serious_damp': 'true',
          'cb_is_joists_decay': 'true',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('cellar-damp=to the lower walls of'));
      expect(all, contains('cellar-serious-damp'));
      expect(all, contains('cellar-joists-decay'));
    });

    test('legacy basement not-habitable dropdown emits direct reason', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_basement',
        <String, String>{
          'actv_area_should_not_use_because_of_61': 'Ceiling too low',
        },
      );

      expect(
          phrases.join(' ').toLowerCase(), contains('basement-not-habitable=ceiling too low'));
    });

    test('legacy cellar no-access/flooded fields still emit phrases', () {
      final phrases = engine.buildPhrases(
        'activity_in_side_property_other_cellar',
        <String, String>{
          'cb_restricted_access': 'true',
          'actv_possible_flooded': 'Possible',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('cellar-no-access=restricted access'));
      expect(all, contains('cellar-flooded=possible'));
    });
  });
}
