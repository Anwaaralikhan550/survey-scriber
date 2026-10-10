import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json')
      .readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final e = InspectionPhraseEngine(texts);
  test('E3 rainwater goods probe', () {
    void show(String id, Map<String, String> a) {
      print('--- $id ---');
      for (final p in e.buildPhrases(id, a)) print(p);
    }
    show('activity_outside_property_rwg_about', {
      'actv_rainwater_goods_are_made_up': 'Mainly of', 'cb_plastic': 'true', 'actv_condition': 'Reasonable',
    });
    show('activity_outside_property_rwg_about', {'cb_Shared': 'true'});
    show('activity_outside_property_rwg_about', {'cb_asbestos_cement': 'true'});
    show('activity_outside_property_rwg__repair_pipes_gutters', {
      'actv_condition': 'Repair soon', 'cb_pipes_101': 'true', 'cb_are_leaking_78': 'true',
    });
    show('activity_outside_property_rwg__repair_pipes_gutters', {
      'actv_condition': 'Repair now - if causing damp', 'cb_gutters_59': 'true', 'cb_are_rusted_18': 'true',
    });
    show('activity_outside_property_rwg__repair_pipes_gutters', {
      'actv_condition': 'Repair soon', 'cb_pipes_101': 'true', 'cb_do_not_have_sufficient_slope_53': 'true',
    });
    show('activity_outside_property_rwg_blocked_rwg', {'cb_blocked_rwg': 'true'});
    show('activity_outside_property_rwg_blocked_gullies', {'cb_blocked_gullies': 'true'});
    show('activity_outside_property_rwg_open_runoffs', {'cb_open_runoffs': 'true'});
    show('activity_outside_property_rain_water_goods_not_inspected', {'cb_not_inspected': 'true'});
    show('activity_outside_property_rainwater_goods_main_screen', {'actv_condition_rating': '2'});
  });
}
