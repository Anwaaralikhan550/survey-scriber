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


  test('oil tank near a watercourse explains secondary containment', () {
    final phrases = engine.buildPhrases(
      'activity_services_oil',
      {
        'actv_oil_tank_status': 'Inspected',
        'actv_location': 'Rear garden',
        'actv_oil_tank_made_up_of': 'Plastic',
        'cb_nearby_watercourse': 'true',
      },
    );

    expect(phrases, contains(contains('secondary containment')));
    expect(phrases, contains(contains('OFTEC-registered technician')));
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
