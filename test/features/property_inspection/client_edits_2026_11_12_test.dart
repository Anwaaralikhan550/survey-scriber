// Client file (6), 12 Nov 2026: the clear items.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/legacy_answer_migration.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';

void main() {
  final phraseTexts = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final engine = InspectionPhraseEngine(phraseTexts);
  final tree = InspectionTreePayload.fromJson(File('assets/property_inspection/inspection_tree.json').readAsStringSync());
  final nodes = {for (final s in tree.sections) for (final n in s.nodes) n.id: n};

  Map<String, String> ticks(List<String> ids, [Map<String, String> extra = const {}]) =>
      {for (final i in ids) i: 'true', ...extra};
  String say(String screen, Map<String, String> answers) => engine.buildPhrases(screen, answers).join(' ');
  List<String> labels(String screen) => nodes[screen]!.fields.map((f) => f.label).toList();

  group('N1 Property Type: house and flat', () {
    test('two new ticks at the end, before Other', () {
      final l = labels('activity_property_type');
      expect(l.indexOf('house'), l.indexOf('cottage') + 1);
      expect(l.indexOf('flat'), l.indexOf('house') + 1);
      expect(l.indexOf('Other'), l.indexOf('flat') + 1);
    });
    test('they print in the sentence', () {
      final out = say('activity_property_type', ticks(['cb_a2_type', 'a2t_house'], {'actv_a2_bedrooms': 'Three'}));
      expect(out, contains('The property is a house'));
      final both = say('activity_property_type', ticks(['cb_a2_type', 'a2t_detached', 'a2t_flat'], {'actv_a2_bedrooms': 'Two'}));
      expect(both, contains('detached and flat'));
    });
  });
  group('N2 Flat: Other floor and Other number of storeys, typed', () {
    const screen = 'activity_property_flate';
    test('both dropdowns end with Other and each has its text box', () {
      final f = {for (final x in nodes[screen]!.fields) x.id: x};
      expect(f['actv_a2_floor']!.options!.last, 'Other');
      expect(f['actv_a2_storeys']!.options!.last, 'Other');
      expect(f['actv_a2_floor_other_text']!.conditionalOn, 'actv_a2_floor=Other');
      expect(f['actv_a2_storeys_other_text']!.conditionalOn, 'actv_a2_storeys=Other');
    });
    test('typed words print', () {
      final out = say(screen, {
        'cb_a2_flat': 'true',
        'actv_a2_floor': 'Other',
        'actv_a2_floor_other_text': 'sixth floor',
        'actv_a2_storeys': 'Other',
        'actv_a2_storeys_other_text': 'seven',
        'actv_a2_access': 'Private door',
        'actv_a2_elevation': 'Rear',
      });
      expect(out, contains('The property is located on the sixth floor of a seven storey building.'));
    });
    test('listed choices are unchanged, Other with nothing typed prints nothing', () {
      expect(
        say(screen, {'cb_a2_flat': 'true', 'actv_a2_floor': 'Second floor', 'actv_a2_storeys': 'Three', 'actv_a2_access': 'Communal door', 'actv_a2_elevation': 'Front'}),
        contains('located on the second floor of a three storey building'),
      );
      expect(
        say(screen, {'cb_a2_flat': 'true', 'actv_a2_floor': 'Other', 'actv_a2_storeys': 'Three', 'actv_a2_access': 'Communal door', 'actv_a2_elevation': 'Front'}),
        isNot(contains('located on')),
      );
    });
  });
  group('N3 Roof cover: natural slates, artificial slates', () {
    test('labels and sentence', () {
      final l = labels('activity_property_roof');
      expect(l, containsAll(['natural slates', 'artificial slates', 'fibre cement slates']));
      expect(l, isNot(contains('natural slate')));
      final out = say('activity_property_roof', ticks(['a3_roof_cover_0_natural_slate', 'a3_roof_cover_0_artificial_slate']));
      expect(out, contains('formed in natural slates and artificial slates'));
    });
  });
  group('N4 Chimney pots: header "Pot condition"', () {
    test('the report label is Pot condition, the sentence is unchanged', () {
      final out = say('activity_outside_property_water_proofing', ticks(['pc_cracked', 'pc_damaged']));
      expect(out, contains('Pot condition: The chimney pots appear cracked and damaged. Damaged or insecure chimney pots should be repaired or replaced'));
      expect(phraseTexts.values.where((v) => v.contains('Damaged chimney pots:')), isEmpty);
      expect(phraseTexts['{E_CHIMNEY_MULTI_STACK}::{POTS_CONDITION}'], startsWith('Pot condition: '));
    });
  });
  group('N5 Lower Ground rooms: the second "Name of other" reads Number', () {
    test('only that field changes', () {
      final f = {for (final x in nodes['activity_no_of_rooms']!.fields) x.id: x.label};
      expect(f['etNoOfRoomsOther'], 'Number');
      expect(f['ar_etNote'], 'Name of other');
      expect(nodes['activity_no_of_rooms__ground']!.fields.firstWhere((x) => x.id == 'etNoOfRoomsOther').label, 'No.of room for other');
    });
    test('the count still prints as before', () {
      final out = say('activity_no_of_rooms', {'etNoOfRoomsOther': '2', 'ar_etNote': 'studies'});
      expect(out, isNot(contains('{')));
    });
  });

  group('N6 Drainage "Partially visible", External structures "Stair/Steps Decoration"', () {
    test('the tick and the heading', () {
      expect(labels('activity_services_drainage'), contains('Partially visible'));
      expect(labels('activity_services_drainage'), isNot(contains('Visible / partially visible')));
      final out = say('activity_services_drainage', ticks(['cb_dr_svp_visible', 'g6sv_roof_space']));
      expect(out, contains('Partially Visible: The soil and vent pipe is fully concealed or concealed within the building, with only limited sections visible in the roof space.'));
      expect(out, isNot(contains('Visible/Partially Visible')));
    });
    test('the screen is renamed, its sentence is untouched', () {
      expect(nodes['activity_outside_property_other_repairs_decorations']!.title, 'Stair/Steps Decoration');
      expect(nodes.values.where((n) => n.title == 'Perished Decorations'), isEmpty);
    });
  });
  group('N7 Boiler location reads "the ..."', () {
    const screen = 'activity_services_heating_about_heating';
    test('ticks and sentence', () {
      expect(labels(screen), containsAll(['the kitchen', 'the utility room', 'the bedroom', 'under the stairs', 'the garage', 'the airing cupboard']));
      final out = say(screen, ticks(['cb_boiler_present', 'g4b_combination_boiler', 'g4l_airing_cupboard']));
      expect(out, contains('that is installed in the airing cupboard.'));
      final two = say(screen, ticks(['cb_boiler_present', 'g4b_combination_boiler', 'g4l_kitchen', 'g4l_under_the_stairs']));
      expect(two, contains('installed in the kitchen and under the stairs.'));
    });
  });

  group('N8 Heat pumps: heading once', () {
    const screen = 'activity_services_heating_about_heating';
    test('air source and ground source', () {
      final air = say(screen, ticks(['cb_air_source_heat_pump', 'g4ai_kitchen', 'g4ae_rear']));
      expect(air, startsWith('Air Source Heat Pump: The property is heated by an air source heat pump'));
      expect(air, isNot(contains('Air Source Heat Pump: Air Source')));
      final ground = say(screen, ticks(['cb_ground_source_heat_pump', 'g4gi_kitchen']));
      expect(ground, startsWith('Ground Source Heat Pump: The property is heated by a ground source heat pump'));
      expect(ground, isNot(contains('Ground Source Heat Pump: Ground Source')));
    });
  });
  group('N9 Walls condensation: no "area(s)" at the end', () {
    test('the sentence ends with the places', () {
      final out = say('activity_in_side_property_wap_repair_condensation', ticks(['f3c_lounge', 'f3c_bedrooms']));
      expect(out, contains('on wall surfaces, ceilings or window reveals, in the lounge and bedrooms. Condensation is commonly associated'));
      expect(out, isNot(contains('area(s)')));
    });
  });
  group('N10 Balcony: only the Balcony sentence, no Juliet or hardcoded lists', () {
    test('Balcony construction prints the selection only', () {
      final out = say('activity_outside_property_other_other_external__construction__3', ticks(['e93c_steel', 'e93c_timber']));
      expect(out, 'Balcony: The property incorporates a timber and steel balcony(s).');
      expect(out, isNot(contains('Juliet')));
      expect(out, isNot(contains('aluminium')));
    });
    test('Juliet balcony still prints its own selection', () {
      final out = say('activity_outside_property_other_other_external__construction__4', ticks(['e94c_steel', 'e94c_glass']));
      expect(out, 'Juliet Balcony: The property incorporates Juliet balcony(s) formed in steel and glass materials.');
    });
  });
  group('N11 / C13 Floor tiles: each option prints its own phrase', () {
    const screen = 'activity_in_side_property_floors_tiles';
    test('Cracked tiles prints only the cracked-tiles sentence, no condition line', () {
      final out = say(screen, ticks(['f4t_kitchen', 'f4td_cracked'], {'actv_tiles': 'Cracked tiles', 'actv_tile_condition': 'Fair'}));
      expect(out, contains('Cracked Tiles: Localised cracked floor tiles in the kitchen areas were observed.'));
      expect(out, isNot(contains('floor tiles appear in')));
      expect(out, isNot(contains('No evidence')));
    });
    test('No cracked tiles prints the condition, and the condition shows only for it', () {
      final out = say(screen, ticks(['f4t_kitchen'], {'actv_tiles': 'No cracked tiles', 'actv_tile_condition': 'Good'}));
      expect(out, startsWith('No Cracked Tiles: The floor tiles appear in good condition.'));
      final f = nodes[screen]!.fields.firstWhere((x) => x.id == 'actv_tile_condition');
      expect(f.conditionalOn, 'actv_tiles=No cracked tiles');
    });
  });
  group('N12 Repair Tiles: Leaking is its own tick', () {
    const screen = 'activity_outside_property_roof_repair_tiles';
    test('dropdown has soon/now only, Leaking is a tick', () {
      final f = {for (final x in nodes[screen]!.fields) x.id: x};
      expect(f['actv_condition']!.options, ['Repair soon', 'Repair now']);
      expect(f['rc_rt_leaking']!.label, 'Leaking');
      expect(f['rc_rt_leaking']!.conditionalOn, isNull);
    });
    test('the tick prints its own sentence, alone or with a repair', () {
      final alone = say(screen, ticks(['rc_rt_leaking']));
      expect(alone, startsWith('Leaking: The roof covering has extensive defects that are likely to allow water penetration'));
      final both = say(screen, ticks(['rc_rt_leaking', 'rc_rt_loose'], {'actv_condition': 'Repair soon'}));
      expect(both, contains('Repair soon: One or more tiles, slates, are loose.'));
      expect(both, contains('Leaking: The roof covering has extensive defects'));
    });
    test('a survey saved with the old dropdown value still prints it', () {
      expect(say(screen, {'actv_condition': 'Leaking'}), startsWith('Leaking: The roof covering has extensive defects'));
    });
  });
  group('N13 Roof Ventilation: Condensation is its own tick', () {
    const screen = 'activity_inside_property_roof_ventilation';
    test('dropdown has no Condensation; a tick prints the existing sentence', () {
      final f = {for (final x in nodes[screen]!.fields) x.id: x};
      expect(f['actv_ventilation']!.options, ['No ventilation', 'Ventilation noted']);
      expect(f['cb_roof_condensation']!.label, 'Condensation noted');
      expect(f['cb_roof_condensation']!.conditionalOn, isNull);
      expect(say(screen, ticks(['cb_roof_condensation'])), startsWith('Condensation noted: The roof space has no or insufficient ventilation'));
    });
    test('together with a ventilation choice, both sentences print; the old saved value still prints', () {
      final both = say(screen, ticks(['cb_roof_condensation'], {'actv_ventilation': 'Ventilation noted', 'actv_vent_level': 'Limited'}));
      expect(both, contains('Ventilation noted:'));
      expect(both, contains('Condensation noted:'));
      expect(say(screen, {'actv_ventilation': 'Condensation noted'}), startsWith('Condensation noted: The roof space'));
    });
  });

  group('N14 Roof Insulation: no Insulation Outcome', () {
    const screen = 'activity_inside_property_roof_insulation';
    test('the field and its two sentences are gone, the Insulation choices stay', () {
      expect(nodes[screen]!.fields.map((f) => f.id), isNot(contains('actv_insulation_outcome')));
      expect(labels(screen), containsAll(['adequate', 'limited', 'insufficient', 'poorly fitted', 'Other']));
      final out = say(screen, ticks(['f1i_adequate'], {'actv_insulation_outcome': 'Adequate insulation'}));
      expect(out, startsWith('Thermal Insulation:'));
      expect(out, isNot(contains('Adequate insulation:')));
      expect(out, isNot(contains('270')));
    });
  });
  group('N15 Outside doors: replacement is its own option, not in the Description', () {
    const screen = 'activity_outside_property_out_side_doors_about_doors';
    test('the tick sits under its own label, after the door types', () {
      final ids = nodes[screen]!.fields.map((f) => f.id).toList();
      expect(ids.indexOf('label_door_replacement'), greaterThan(ids.indexOf('et_other_179')));
      expect(ids.indexOf('e6t_replacement'), ids.indexOf('label_door_replacement') + 1);
      expect(ids.indexOf('e6t_replacement'), lessThan(ids.indexOf('label_door_materials')));
    });
    test('Description no longer says replacement, the separate sentence prints', () {
      final out = say(screen, ticks(['e6t_replacement', 'e6t_front', 'e6t_rear']));
      expect(out, contains('Description: The property incorporates front and rear doors.'));
      expect(out, isNot(contains('replacement, ')));
      expect(out, contains('The doors appear to have been fully replaced or partially replaced.'));
    });
    test('replacement alone still prints its own sentence', () {
      expect(say(screen, ticks(['e6t_replacement'])), startsWith('The doors appear to have been fully replaced or partially replaced.'));
    });
  });
  group('N16 Door Repair (door operation): no hardcoded "No defects noted"', () {
    const screen = 'activity_in_side_property_wood_work_door_sampling';
    test('Freely prints only the operation sentence', () {
      expect(say(screen, {'actv_door_operation': 'Freely'}), 'Door operation: The internal doors selected for operation opened and closed freely.');
    });
    test('With resistance / difficulty print the operation and the matching comment, not "No defects"', () {
      for (final v in ['With resistance', 'With difficulty']) {
        final out = say(screen, {'actv_door_operation': v});
        expect(out, startsWith('Door operation: The internal doors selected for operation opened and closed ${v.toLowerCase()}.'));
        expect(out, contains('One or more internal doors do not close properly or operate with resistance.'));
        expect(out, isNot(contains('No defects noted')));
      }
    });
  });
  group('N17 Garage screen: Converted garage after No defects noted', () {
    const screen = 'activity_grounds_garage';
    test('order and nothing lost', () {
      final ids = nodes[screen]!.fields.map((f) => f.id).toList();
      expect(ids.length, 76);
      expect(ids.take(3), ['cb_h1_no_garage', 'cb_h1_not_inspected', 'cb_shared_access']);
      expect(ids.sublist(ids.length - 8), [
        'cb_h1_no_defects',
        'cb_h1_converted',
        'label_h1_converted_to',
        'h1cv_habitable_accommodation',
        'h1cv_an_office',
        'h1cv_a_workshop',
        'h1cv_other',
        'h1cv_other_text',
      ]);
    });
    test('the converted-garage sentence still prints', () {
      final out = say(screen, ticks(['cb_h1_converted', 'h1cv_an_office']));
      expect(out, contains('office'));
    });
  });
  group('N18 Shared Access: only the Shared areas capture is left', () {
    const screen = 'activity_grounds_shared_access';
    test('fields', () {
      final ids = nodes[screen]!.fields.map((f) => f.id).toList();
      expect(ids.first, 'cb_h2_h2_shared_areas');
      expect(ids, ['cb_h2_h2_shared_areas', 'label_h2_shared_areas', 'h2_shared_areas_0_shared_driveway', 'h2_shared_areas_0_shared_garden',
        'h2_shared_areas_0_communal_parking', 'h2_shared_areas_0_communal_gardens', 'h2_shared_areas_0_shared_pathways',
        'h2_shared_areas_0_other', 'h2_shared_areas_0_other_text', 'actv_h2_shared_cond']);
    });
    test('only the Shared Areas wording is generated', () {
      final out = engine.buildPhrases(screen, ticks(['cb_h2_h2_shared_areas', 'h2_shared_areas_0_shared_driveway', 'h2_shared_areas_0_communal_parking'], {'actv_h2_shared_cond': 'Good'}));
      expect(out.first, 'Shared Areas: The property benefits from a shared driveway and communal parking access.');
      expect(out.length, 2);
      expect(out.join(' '), isNot(contains('garage')));
    });
    test('answers saved for the removed fields print nothing now', () {
      final out = say(screen, ticks(['cb_h2_h2_shared_garden', 'cb_h2_h2_comm_surface', 'h2_comm_surface_0_paved', 'cb_h2_h2_comm_no_fence'], {'actv_h2_comm_cond': 'Good'}));
      expect(out, isEmpty);
    });
  });
  group('N19 Nearby Trees: effects and defects print from their ticks', () {
    const screen = 'activity_other_repair_nearby_trees';
    test('ticks alone (dropdown left empty) print the defects sentence', () {
      final out = say(screen, ticks(['h2ta_property', 'h2ta_fencing', 'cb_significant_cracks']));
      expect(out, contains('Detrimental effects on the property and fencing were noted that include significant cracks.'));
      expect(out, contains('Nearby Trees: One or more trees are located close to the property.'));
    });
    test('with the dropdown set it still prints, and No defects is unchanged', () {
      final defects = say(screen, ticks(['h2ta_outbuilding', 'cb_subsidence_movement'], {'actv_condition': 'Defects noted'}));
      expect(defects, contains('Detrimental effects on the outbuilding were noted that include subsidence movement.'));
      final none = say(screen, {'actv_condition': 'No defects'});
      expect(none, contains('No defects: No significant detrimental effects on the property were noted to date'));
      expect(none, isNot(contains('Detrimental effects on the')));
    });
    test('nothing ticked and nothing chosen prints nothing', () {
      expect(say(screen, {}), isEmpty);
    });
  });
  group('C1 C2 C3 C4 C10 (client answers 13 Nov)', () {
    test('C1 Slope Gradient and Tree size labels carry no (J2 ...) text', () {
      final all = jsonEncode(tree.sections.map((s) => s.nodes.map((n) => n.fields.map((f) => f.label).toList()).toList()).toList());
      expect(all, isNot(contains('(J2')));
      expect(labels('activity_grounds_other_grounds'), contains('Slope Gradient'));
    });
    test('C10 level prints on its own, sloping only with a gradient', () {
      const s = 'activity_grounds_other_grounds';
      expect(say(s, {'actv_type': 'Level'}), contains('Grounds: The subject property is set within level grounds.'));
      expect(say(s, {'actv_type': 'Sloping'}), isNot(contains('set within')));
      expect(say(s, {'actv_j2_slope': 'Gently'}), isNot(contains('set within')));
      expect(say(s, {'actv_type': 'Sloping', 'actv_j2_slope': 'Gently'}), contains('Grounds: The subject property is set within gently sloping grounds.'));
      expect(say(s, {'actv_type': 'Hilly', 'actv_j2_slope': 'Steeply'}), contains('set within steeply hilly grounds.'));
    });
    test('C2 Good and Fair print the price, Poor does not', () {
      const s = 'activity_over_all_openion';
      for (final r in ['Good', 'Fair']) {
        expect(say(s, {'android_material_design_spinner5': r, 'android_material_design_spinner': '£400,000'}),
            contains('$r: I am pleased to advise you that this property is believed to be a ${r.toLowerCase()} proposition for purchase at £400,000.'));
      }
      expect(say(s, {'android_material_design_spinner5': 'Poor', 'android_material_design_spinner': '£400,000'}), isNot(contains('I am pleased')));
    });
    test('C3 Leaning Chimney location', () {
      const s = 'activity_outside_property_leaning_chimney';
      expect(labels(s), containsAll(['front', 'rear', 'side', 'centre', 'Other']));
      expect(say(s, ticks(['cl_front', 'cl_rear'])), contains('Leaning chimney location: The leaning chimney stack is located to the front and rear.'));
      expect(say(s, ticks(['cl_other'], {'cl_other_text': 'gable end'})), contains('located to the gable end.'));
      expect(say(s, {}), isNot(contains('Leaning chimney location')));
    });
    test('C4 aerial and satellite heading names only what is ticked', () {
      const s = 'activity_outside_property_chimney_aerials';
      expect(say(s, ticks(['ca_aerial'])), contains('Aerial: An aerial is attached to the chimney stack. Where secure, no action is currently required.'));
      expect(say(s, ticks(['ca_satellite'])), contains('Satellite dish: A satellite dish is attached to the chimney stack.'));
      expect(say(s, ticks(['ca_aerial', 'ca_satellite'])), contains('Aerials and satellite dishes: An aerial and a satellite dish are attached to the chimney stack.'));
    });
    test('C4 repair aerial and repair satellite dish are separate sentences', () {
      expect(say('activity_outside_property_repair_chimney_dish_aerial', ticks(['cb_e1l_ae_def', 'e1l_ae_d_loose'])), contains('Repair aerial: The aerial attached to the property is loose.'));
      expect(say('activity_outside_property_repair_chimney_dish_aerial__satellite', ticks(['cb_e1l_sa_def', 'e1l_sa_d_rusted'])), contains('Repair satellite dish: The satellite dish attached to the property is rusted.'));
    });
  });
  group('C5 Electricity landing: the duplicate Dated tick is gone', () {
    test('landing has no Dated tick, Mains Electricity keeps its own', () {
      expect(labels('activity_services_electricity_main_screen'), isNot(contains('Dated electrical system')));
      expect(labels('activity_service_about_electricity'), contains('Dated or old installation'));
      expect(say('activity_service_about_electricity', ticks(['cb_dated_electrical_system'])), contains('Dated or Old: The installation appears'));
    });
  });
  group('C6 Inspection Chamber wording', () {
    const s = 'activity_services_drainage';
    test('tick, finding and sentence follow the client wording', () {
      expect(labels(s), containsAll(['Inspection chamber is inspected', 'No blockage']));
      expect(say(s, ticks(['cb_dr_chamber', 'g6cf_blockage'])), contains('Inspection chamber is inspected: The inspection chamber cover(s) were lifted where possible. No blockage was noted.'));
      expect(say(s, ticks(['cb_dr_chamber', 'g6cf_recent_blockage'])), contains('recent blockage was noted.'));
    });
    test('not inspected heading', () {
      expect(say(s, ticks(['cb_dr_not_inspected'])), contains('Inspection chamber not inspected: The inspection chamber cover(s) could not be lifted'));
    });
  });
  group('C7 Roof insulation: No insulation tick', () {
    const s = 'activity_inside_property_roof_insulation';
    test('prints the client sentence word for word', () {
      expect(labels(s), contains('No insulation'));
      expect(say(s, ticks(['cb_f1i_none'])), 'No insulation: The loft floor is insulated. This can lead to heat loss, higher heating costs, and an increased risk of condensation and mould. I recommend upgrading the insulation to current standard of 270–300 mm, ensuring roof ventilation is not obstructed.');
      expect(say(s, {}), isNot(contains('No insulation')));
    });
  });
  group('C8 Floor Vibration locations', () {
    const s = 'activity_in_side_property_floors_repair_floor_vibration';
    test('prints the client sentence with the ticked locations', () {
      expect(labels(s), containsAll(['lounge', 'dining room', 'bedroom', 'kitchen', 'bathroom', 'Other']));
      expect(say(s, ticks(['cb_floor_vibration_excessive', 'fv_lounge', 'fv_bedroom'])), 'Floor Vibration: The floor was found to vibrate excessively underfoot in lounge and bedroom. Thus, suggesting inadequate support and/or deterioration of the timber structure, such as fungal decay or wood-boring insect attack.');
      expect(say(s, ticks(['cb_floor_vibration_excessive', 'fv_other'], {'fv_other_text': 'hallway'})), contains('underfoot in hallway.'));
    });
  });
  group('C9 Movement Cracks: separate ticks', () {
    const s = 'activity_in_side_property_wap_movement_cracks';
    test('three ticks, each prints its own sentence and several can be ticked', () {
      expect(labels(s), containsAll(['Minor cracking', 'Significant cracking', 'Structural Movement']));
      final out = say(s, ticks(['cb_f3_minor', 'cb_f3_significant']));
      expect(out, contains('Minor cracking: Minor shrinkage or settlement cracking was observed'));
      expect(out, contains('Significant cracking: Significant cracking was observed on some of the walls.'));
      expect(out, isNot(contains('Structural Movement')));
      expect(say(s, ticks(['cb_f3_structural', 'f3mv_historic'])), contains('Structural Movement: Evidence of historic movement was observed.'));
    });
    test('an older survey with the dropdown value still prints', () {
      final migrated = migrateLegacyAnswers(s, {'android_material_design_spinner3': 'Significant cracking'});
      expect(migrated['cb_f3_significant'], 'true');
      expect(say(s, migrated), contains('Significant cracking: Significant cracking was observed'));
    });
  });
}
