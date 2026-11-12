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
}
