import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - inside screen id aliases', () {
    const phraseTexts = <String, String>{
      '{F_BUILT_IN_FITTINGS}::{CONDITION_RATING}':
          'bif-rating={BIF_CONDITION_RATING}',
      '{F_BUILT_IN_FITTINGS}::{NOTES}': 'bif-notes={BIF_NOTES}',
      '{F_WOOD_WORK}::{CONDITION_RATING}': 'wood-rating={WW_CONDITION_RATING}',
      '{F_WOOD_WORK}::{NOTES}': 'wood-notes={WW_NOTES}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('legacy other_fittings main screen routes to built-in main handler', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_other_fittings_main_screen',
        <String, String>{
          'android_material_design_spinner4': '2',
          'ar_etNote': 'legacy built in note',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('bif-rating=2'));
      expect(all, contains('bif-notes=legacy built in note'));
    });

    test('legacy wood_work main screen routes to woodwork main handler', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_wood_work_main_screen',
        <String, String>{
          'android_material_design_spinner4': '1',
          'ar_etNote': 'legacy wood note',
        },
      );

      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('wood-rating=1'));
      expect(all, contains('wood-notes=legacy wood note'));
    });
  });
}
