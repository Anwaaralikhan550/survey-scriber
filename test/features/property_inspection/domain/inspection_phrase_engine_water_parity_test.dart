import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - G3 Water parity', () {
    const phraseTexts = <String, String>{
      '{G_WATER}::{STANDARD_TEXT}': 'standard-text',
      '{G_WATER}::{STANDARD_TEXT_2}': 'standard-text-2',
      '{G_WATER}::{CONDITION_RATING}': 'condition={WATER_CONDITION_RATING}',
      '{G_WATER}::{NOTES}': 'notes={WATER_NOTES}',
      '{G_WATER}::{STOPCOCK_FOUND}': 'stopcock-found=loc:{WATER_STOPCOCK_LOCATION}',
      '{G_WATER}::{STOPCOCK_NOT_FOUND}': 'stopcock-not-found',
      '{G_WATER}::{LEAD_RISING}': 'lead-rising',
      '{G_WATER}::{NOT_INSPECTED}': 'not-inspected',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('main screen resolves standard text, rating and notes', () {
      final phrases = engine.buildPhrases(
        'activity_services_water_main_screen',
        {
          'android_material_design_spinner4': '1',
          'ar_etNote': 'pressure tested fine',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('standard-text'));
      expect(all, isNot(contains('standard-text-2')));
      expect(all, contains('condition=1'));
      expect(all, contains('notes=pressure tested fine'));
    });

    test('main screen with nothing answered still emits standard text only',
        () {
      final phrases = engine.buildPhrases(
        'activity_services_water_main_screen',
        const <String, String>{},
      );
      expect(phrases, hasLength(1));
      expect(phrases.single, 'standard-text');
    });

    test(
        'main screen resolves stopcock and lead-rising (legacy parity fields shown on main screen)',
        () {
      final found = engine.buildPhrases(
        'activity_services_water_main_screen',
        {
          'cb_stopcock_found': 'true',
          'actv_stopcok_location': 'Under the kitchen sink',
        },
      );
      expect(found.join(' ').toLowerCase(),
          contains('stopcock-found=loc:under the kitchen sink'));

      final notFound = engine.buildPhrases(
        'activity_services_water_main_screen',
        {'cb_stopcock_found': 'false'},
      );
      expect(
          notFound.join(' ').toLowerCase(), contains('stopcock-not-found'));

      final leadRising = engine.buildPhrases(
        'activity_services_water_main_screen',
        {'cb_lead_rising': 'true'},
      );
      expect(leadRising.join(' ').toLowerCase(), contains('lead-rising'));
    });

    test('main water screen resolves stopcock and lead-rising directly', () {
      final found = engine.buildPhrases(
        'activity_services_water_main_water',
        {
          'cb_stopcock_found': 'true',
          'actv_stopcok_location': 'In the garage',
        },
      );
      final all = found.join(' ').toLowerCase();
      expect(all, contains('stopcock-found=loc:in the garage'));
      expect(all, contains('standard-text-2'));

      final notFound = engine.buildPhrases(
        'activity_services_water_main_water',
        const <String, String>{},
      );
      expect(
          notFound.join(' ').toLowerCase(), contains('stopcock-not-found'));
    });

    test('not inspected is gated on its checkbox', () {
      final checked = engine.buildPhrases(
        'activity_services_water_not_inspected',
        {'cb_not_inspected': 'true'},
      );
      expect(checked, hasLength(1));
      expect(checked.first.toLowerCase(), contains('not-inspected'));

      final unchecked = engine.buildPhrases(
        'activity_services_water_not_inspected',
        const <String, String>{},
      );
      expect(unchecked, isEmpty);
    });
  });
}
