// Client file (6), 12 Nov 2026: the clear items.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
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
}
