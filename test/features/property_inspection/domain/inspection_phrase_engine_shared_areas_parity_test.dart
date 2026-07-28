import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - H5 Shared Areas parity', () {
    const phraseTexts = <String, String>{
      '{H_OTHER}::{SHARED_ACCESS_KNOWN}': 'shared-known=loc:{SA_LOCATION}',
      '{H_OTHER}::{SHARED_ACCESS_UNKNOWN}': 'shared-unknown=loc:{SA_LOCATION}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('shared status resolves known vs unknown', () {
      final known = engine.buildPhrases(
        'activity_grounds_shared_access',
        {
          'cb_front': 'true',
          'actv_shared_status': 'Shared Access',
        },
      );
      expect(known.single.toLowerCase(), contains('shared-known=loc:front'));

      final unknown = engine.buildPhrases(
        'activity_grounds_shared_access',
        {
          'cb_rear': 'true',
          'actv_shared_status': 'Unknown Access Status',
        },
      );
      expect(
          unknown.single.toLowerCase(), contains('shared-unknown=loc:rear'));
    });

    test('resolves multiple locations', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_shared_access',
        {
          'cb_front': 'true',
          'cb_communal': 'true',
          'actv_shared_status': 'Shared Access',
        },
      );
      expect(phrases.single.toLowerCase(),
          contains('shared-known=loc:front and communal'));
    });

    test('requires at least one location before emitting', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_shared_access',
        {'actv_shared_status': 'Shared Access'},
      );
      expect(phrases, isEmpty);
    });

    test('with nothing answered emits nothing', () {
      final phrases = engine.buildPhrases(
        'activity_grounds_shared_access',
        const <String, String>{},
      );
      expect(phrases, isEmpty);
    });
  });
}
