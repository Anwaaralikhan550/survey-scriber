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

  test('previously strengthened roof has a dedicated professional narrative', () {
    final phrases = engine.buildPhrases(
      'activity_outside_property_roof_spreading_repair',
      {'actv_status': 'Previously strengthened'},
    );

    expect(phrases.single, contains('previously have required strengthening'));
    expect(phrases.single, contains('No repair is currently required'));
  });

  test('poor-fitting water tank lid has a dedicated repair narrative', () {
    final phrases = engine.buildPhrases(
      'activity_inside_property_water_tank',
      {'cb_poor_fitting_cover': 'true'},
    );

    expect(phrases, contains(contains('close-fitting lid')));
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

  test('porch below accommodation is not described as a roof covering', () {
    final phrases = engine.buildPhrases(
      'activity_outside_property_conservatory_porch_roof__roof',
      {'cb_floor_above': 'true'},
    );

    expect(phrases.single, contains('formed by the floor above'));
    expect(phrases.single, isNot(contains('covered in floor above')));
  });

  test('floor-above conflict is excluded when roof coverings are selected', () {
    final phrases = engine.buildPhrases(
      'activity_outside_property_conservatory_porch_roof__roof',
      {
        'actv_roof_type': 'Pitched',
        'cb_floor_above': 'true',
        'cb_concrete_tiles': 'true',
      },
    );

    expect(phrases.single, contains('formed in concrete tiles'));
    expect(phrases.single, isNot(contains('floor above')));
  });
}
