import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json')
      .readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final e = InspectionPhraseEngine(texts);
  test('2A batch4 probe', () {
    void show(String id, Map<String, String> a) {
      print('--- $id ---');
      for (final p in e.buildPhrases(id, a)) print(p);
    }
    show('activity_property_roof', {'ch2': 'true', 'ch8': 'true', 'ch6': 'true'});
    show('activity_extended_wall', {'ch2': 'true'});
    show('activity_internal_wall', {'ch1': 'true', 'ch2': 'true'});
    show('activity_construction_floor', {'ch1': 'true'});
    show('activity_construction_window', {'ch2': 'true', 'ch5': 'true'});
    show('activity_front_garden', {'ch1': 'true', 'ch8': 'true'});
    show('activity_rear_garden', {'ch2': 'true', 'ch20': 'true'});
    show('activity_garden', {
      'android_material_design_spinner': 'Paved',
      'android_material_design_spinner2': 'Timber',
      'android_material_design_spinner3': 'Lawned',
    });
    show('activity_topography', {'android_material_design_spinner': 'Level'});
    show('activity_property_flate', {
      'android_material_design_spinner': '2', 'android_material_design_spinner2': '4',
      'android_material_design_spinner3': 'private door', 'android_material_design_spinner4': 'front'
    });
  });
}
