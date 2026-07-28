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

  test('mixed roof selections produce a coherent composite description', () {
    final phrases = engine.buildPhrases(
      'activity_property_roof',
      {
        'ch1': 'true',
        'ch2': 'true',
        'ch8': 'true',
        'ch9': 'true',
        'ch6': 'true',
        'ch7': 'true',
      },
    );

    expect(phrases.single, contains('combination of flat and pitched'));
    expect(phrases.single, contains('coverings comprise concrete and clay'));
    expect(phrases.single, isNot(contains('concrete and clay tiles and sheets')));
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

  test('negative private-road status becomes professional legal prose', () {
    final phrase = engine.buildPhrases(
      'activity_property_private_road',
      {'android_material_design_spinner3': 'No'},
    ).join(' ');

    expect(phrase, contains('maintained at public expense'));
    expect(phrase, contains('legal adviser'));
    expect(phrase, isNot(startsWith('Status:')));
  });

  test('source-less noise status gives proportionate inspection advice', () {
    final phrase = engine.buildPhrases(
      'activity_property_is_noisy_area',
      {'android_material_design_spinner4': 'Yes'},
    ).join(' ');

    expect(phrase, contains('External noise was apparent'));
    expect(phrase, contains('revisit the area at different times'));
  });

  test('not-listed response uses qualified wording', () {
    final phrase = engine.buildPhrases(
      'activity_listed_building',
      {'android_material_design_spinner': 'No'},
    ).single;

    expect(phrase, 'The property is not understood to be a listed building.');
  });

  test('poor ceiling condition never says no repair is needed', () {
    final phrase = engine.buildPhrases(
      'inside_property_ceilings_about_ceilings',
      {
        'actv_made_up': 'Mainly of',
        'cb_plasterboard': 'true',
        'cb_painted': 'true',
        'actv_condition': 'Poor',
      },
    ).single;

    expect(phrase, contains('unsatisfactory condition'));
    expect(phrase, contains('repairs or renewal'));
    expect(phrase, isNot(contains('No repair is currently needed')));
  });

  test('poor internal-wall condition never says no repair is needed', () {
    final phrase = engine.buildPhrases(
      'activity_inside_property_wap_walls',
      {
        'cb_solid': 'true',
        'cb_painted': 'true',
        'actv_condition': 'Poor',
      },
    ).join(' ');

    expect(phrase, contains('unsatisfactory condition'));
    expect(phrase, isNot(contains('No repair is currently needed')));
  });

  test('poor floor condition never says no repair is needed', () {
    final phrase = engine.buildPhrases(
      'activity_in_side_property_floors_about_floor',
      {
        'actv_construction': 'All solid',
        'actv_covered_with': 'Mainly',
        'cb_carpets': 'true',
        'actv_condition': 'Poor',
      },
    ).join(' ');

    expect(phrase, contains('unsatisfactory condition'));
    expect(phrase, isNot(contains('No repair is currently needed')));
  });

  test('roof structure grammar is normalised', () {
    final phrase = engine.buildPhrases(
      'activity_inside_property_about_roof_structure',
      {
        'actv_construction': 'Factory made trusses',
        'actv_underlining': 'Underlining',
        'cb_sacking_felt': 'true',
        'actv_roof_structure_condition': 'Reasonable',
      },
    ).single;

    expect(phrase, contains('factory-made roof truss'));
    expect(phrase, isNot(contains('trusses')));
  });

  test('non-numeric wall thickness is suppressed', () {
    final phrase = engine.buildPhrases(
      'activity_outside_property_main_walls_about_wall',
      {
        'cb_main_building': 'true',
        'et_thickness': 'sample detail',
        'actv_finishes': 'Fully',
        'actv_rendered': 'Smooth',
        'cb_painted': 'true',
        'actv_condition': 'Reasonable',
      },
    ).single;

    expect(phrase, isNot(contains('sample detail mm')));
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
