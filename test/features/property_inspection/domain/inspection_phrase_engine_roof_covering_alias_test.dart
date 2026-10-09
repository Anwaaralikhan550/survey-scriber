import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - roof covering alias compatibility', () {
    const phraseTexts = <String, String>{
      '{E_RC_WEATHER_CONDITION}::{CONDITION_WET}': 'roof-weather-wet',
      '{E_RC_WEATHER_CONDITION}::{CONDITION_DRY}': 'roof-weather-dry',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

  });
}
