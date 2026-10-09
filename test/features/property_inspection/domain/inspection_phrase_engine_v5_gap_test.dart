import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  late InspectionPhraseEngine engine;

  setUpAll(() {
    final texts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value.toString()));
    engine = InspectionPhraseEngine(texts);
  });


  test('oil tank paragraph carries the PDF secondary-containment and OFTEC wording', () {
    final phrases = engine.buildPhrases(
      'activity_services_oil',
      {
        'g2t_plastic': 'true',
        'g2l_rear_garden': 'true',
      },
    );

    expect(phrases, contains(contains('secondary containment (a bund)')));
    expect(phrases, contains(contains('OFTEC-registered engineer')));
  });

  test('garage access limitation identifies who did not provide keys', () {
    final phrases = engine.buildPhrases(
      'activity_grounds_garage_not_inspected',
      {
        'cb_not_inspected': 'true',
        'actv_access_keys_not_provided_by': 'Estate agent',
      },
    );

    expect(phrases.single, contains('estate agent'));
    expect(phrases.single, contains('unable to inspect the garage'));
  });


}
