import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  final texts = (jsonDecode(File('assets/property_inspection/phrase_texts.json')
      .readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final e = InspectionPhraseEngine(texts);
  test('E1 chimney probe', () {
    void show(String id, Map<String, String> a) {
      print('--- $id ---');
      for (final p in e.buildPhrases(id, a)) print(p);
    }
    show('activity_outside_property_stacks', {'android_material_design_spinner3': 'Single', 'android_material_design_spinner2': '2'});
    show('activity_outside_property_location', {'android_material_design_spinner': 'Front'});
    show('activity_outside_property_rendering', {'android_material_design_spinner': 'Fully'});
    show('activity_outside_property_water_proofing', {'android_material_design_spinner': 'Lead', 'android_material_design_spinner2': 'Mortar'});
    show('activity_outside_property_condition', {'android_material_design_spinner4': 'Reasonable'});
    show('activity_outside_property_shared_chimney', {'ch1': 'true'});
    show('activity_outside_property_leaning_chimney', {'ch2': 'true', 'android_material_design_spinner4': 'Ok'});
    show('activity_outside_property_repair_flashing', {'actv_condition': 'Repair now', 'cb_main_building_28':'true','cb_badly_cracked':'true'});
    show('activity_outside_property_chimney_repair_flaunching', {'actv_condition': 'Repair soon', 'cb_main_building_56':'true','cb_cracked':'true'});
    show('activity_outside_property_repair_chimney_pots', {'actv_condition': 'Repair now', 'cb_main_building_91':'true','cb_badly_broken':'true','cb_is_safety_hazard':'true'});
    show('activity_outside_property_repair_chimney_repointing', {'actv_condition': 'Repair soon', 'cb_main_building_25':'true','cb_has_eroded':'true'});
    show('activity_outside_property_repair_chimney_disrepair', {'cb_repair_soon_70':'true','cb_main_building_21':'true'});
    show('activity_outside_property_repair_chimney_dish_aerial', {'actv_type':'Aerial','actv_condition':'Repair now','cb_very_loose':'true','cb_is_safety_hazard':'true'});
    show('activity_outside_property_chimney_not_inspected', {'cb_Not_applicable':'true'});
    show('activity_outside_property_chimney_partial_view', {'cb_Partial_view':'true'});
    show('activity_outside_property_chimney_removed_chimney_stack', {'cb_Removed_chimney_stack':'true','cb_front_74':'true'});
    show('activity_outside_property_chimney_removed_pots', {'cb_Removed_pots':'true','cb_front_88':'true'});
    show('activity_outside_property_chimney_main_screen', {'android_material_design_spinner4':'2'});
  });
}
