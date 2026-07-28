import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - H4 Boundaries parity', () {
    const phraseTexts = <String, String>{
      '{H_OTHER}::{REPAIR_FENCE}':
          'repair-fence=garden:{OTH_REP_FENCES_GARD}/defect:{OTH_REP_FENCES_DEF}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('fence repair resolves garden and defect', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_repair_fence',
        {
          'cb_front': 'true',
          'cb_leaning': 'true',
          'cb_loose_in_places': 'true',
        },
      );
      expect(
        phrases.single.toLowerCase(),
        contains('repair-fence=garden:front/defect:leaning and loose in places'),
      );
    });

    test('fence repair requires both a garden and a defect', () {
      final missingDefect = engine.buildPhrases(
        'activity_grounds_other_repair_fence',
        {'cb_front': 'true'},
      );
      expect(missingDefect, isEmpty);

      final missingGarden = engine.buildPhrases(
        'activity_grounds_other_repair_fence',
        {'cb_leaning': 'true'},
      );
      expect(missingGarden, isEmpty);
    });

    test('fence repair resolves multiple gardens', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_other_repair_fence',
        {
          'cb_rear': 'true',
          'cb_communal': 'true',
          'cb_broken': 'true',
        },
      );
      expect(
        phrases.single.toLowerCase(),
        contains('repair-fence=garden:rear and communal/defect:broken'),
      );
    });
  });
}
