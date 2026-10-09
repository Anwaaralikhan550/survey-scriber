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

  test('room counts are structured data and never temporary prose', () {
    final phrases = engine.buildPhrases(
      'activity_no_of_rooms__ground',
      {'ar_etFirstName': '2', 'ar_etLastName': '3'},
    );

    expect(phrases, isEmpty);
  });


  test('other area without description does not leak a raw option', () {
    expect(
      engine.buildPhrases('activity_property_ground_area', {'ch5': 'true'}),
      isEmpty,
    );
  });

  test('environment status without an identified source is not invented', () {
    expect(
      engine.buildPhrases(
        'activity_property_local_environment',
        {'android_material_design_spinner8': 'Adverse'},
      ),
      isEmpty,
    );
  });





  test('non-numeric wall thickness is suppressed', () {
    final phrase = engine.buildPhrases(
      'activity_outside_property_main_walls_about_wall',
      {
        'e4w_loc_main_building': 'true',
        'et_thickness': 'sample detail',
      },
    ).join(' ');

    expect(phrase, isNot(contains('sample detail mm')));
    expect(phrase, contains('constructed of solid brick'));
  });

  test('repair allowance is narrative, not raw labelled output', () {
    final phrases = engine.buildPhrases(
      'activity_over_all_openion',
      {
        'android_material_design_spinner5': 'Reasonable with repair',
        'android_material_design_spinner': '1500',
        'android_material_design_spinner2': 'Roof repairs',
      },
    );

    expect(phrases, contains(contains('provisional repair allowance')));
    expect(phrases.any((value) => value.startsWith('Potential:')), isFalse);
    expect(phrases.any((value) => value.startsWith('Estimated repair cost:')),
        isFalse);
  });

  test('floor and site plans carry an indicative-use limitation', () {
    final phrase = engine.buildPhrases(
      'activity_capture_floor_site_plan_sketches',
      {'captured': 'true'},
    ).single;

    expect(phrase, contains('indicative rather than measured drawings'));
  });
}
