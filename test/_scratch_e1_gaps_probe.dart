import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json')
      .readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final e = InspectionPhraseEngine(texts);
  test('E1 gap-closing probe', () {
    void show(String id, Map<String, String> a) {
      print('--- $id ---');
      for (final p in e.buildPhrases(id, a)) print(p);
    }
    show('activity_outside_property_chimney_not_inspected', {'cb_not_inspected_access': 'true'});
    show('activity_outside_property_chimney_not_inspected', {'cb_dummy_chimney_breast': 'true'});
    show('activity_outside_property_repair_flashing', {
      'android_material_design_spinner4': 'Repair now',
      'ch1': 'true', 'ch8': 'true', 'cb_is_causing_dump': 'true',
    });
  });
}
