import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G3 Water legacy parity', () {
    const phraseTexts = <String, String>{
      '{G_WATER}::{STOPCOCK_FOUND}': 'stopcock={WATER_STOPCOCK_LOCATION}',
      '{G_WATER}::{STOPCOCK_NOT_FOUND}': 'stopcock-not-found',
      '{G_WATER}::{LEAD_RISING}': 'lead-rising',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('does not emit stopcock-found phrase without a location', () {
      final phrases = engine.buildPhrases(
        'activity_services_water_main_screen',
        const <String, String>{
          'cb_stopcock_found': 'true',
          'cb_lead_rising': 'true',
        },
      );

      expect(phrases.join(' '), isNot(contains('stopcock=')));
      expect(phrases.join(' '), contains('lead-rising'));
    });

    test('emits stopcock-found phrase when location exists', () {
      final phrases = engine.buildPhrases(
        'activity_services_water_main_screen',
        const <String, String>{
          'cb_stopcock_found': 'true',
          'actv_stopcok_location': 'front',
        },
      );

      expect(phrases.join(' '), contains('stopcock=front'));
    });
  });
}
