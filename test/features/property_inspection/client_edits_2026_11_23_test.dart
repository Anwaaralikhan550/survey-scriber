// Client edit list, 23 Nov 2026 (Survey Scriber Edit Nov 23 2026.docx).
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
  List<String> phrases(String screen, Map<String, String> answers) => engine.buildPhrases(screen, answers);
  String say(String screen, Map<String, String> answers) => phrases(screen, answers).join(' ');
  List<String> labels(String screen) => nodes[screen]!.fields.map((f) => f.label).toList();

  const wallPrefix = 'activity_outside_property_main_walls_about_wall';
  const wallScreens = [
    wallPrefix,
    '${wallPrefix}__cavity_brick_wall',
    '${wallPrefix}__cavity_block_wall',
    '${wallPrefix}__cavity_stud_wall',
    '${wallPrefix}__other',
    '${wallPrefix}__rendered_masonry',
  ];

  group('1 Main Wall: Wall Finished (rendered wall and pebble dash in one)', () {
    test('Pebble dash masonry is no longer a section of its own; the rendered one carries both names', () {
      expect(nodes.containsKey('${wallPrefix}__pebble_dash_masonry'), isFalse);
      expect(nodes['${wallPrefix}__rendered_masonry']!.title, 'Rendered / pebble dash masonry');
    });
    test('every wall type screen has the five Wall Finished choices and no separate rendered wall tick', () {
      for (final s in wallScreens) {
        final l = labels(s);
        expect(l, isNot(contains('rendered wall')), reason: s);
        final first = l.indexOf('rendered');
        expect(first, greaterThan(-1), reason: s);
        expect(l.sublist(first, first + 4), ['rendered', 'rendered with painted', 'coated with pebble dash', 'installed with mock tudor'], reason: s);
        final f = {for (final x in nodes[s]!.fields) x.id: x};
        expect(f['wf_other']!.label, 'Other', reason: s);
        expect(f['wf_other_text']!.conditionalOn, 'wf_other', reason: s);
        // Wall Finished sits before Condition on the form too
        expect(l.indexOf('Wall finished'), lessThan(l.indexOf('Condition')), reason: s);
      }
    });
    test('each choice prints the client sentence', () {
      const finish = 'Wall Finished: The outer face of the external walls is';
      const choices = {
        'wf_rendered': 'rendered',
        'wf_rendered_painted': 'rendered with painted',
        'wf_pebble_dash': 'coated with pebble dash',
        'wf_mock_tudor': 'installed with mock tudor',
      };
      for (final s in wallScreens) {
        choices.forEach((id, text) {
          expect(say(s, ticks([id])), contains('$finish $text.'), reason: '$s $id');
        });
        expect(say(s, ticks(['wf_pebble_dash', 'wf_mock_tudor'])), contains('$finish coated with pebble dash and installed with mock tudor.'), reason: s);
        expect(say(s, ticks(['wf_other'], {'wf_other_text': 'stone effect'})), contains('$finish stone effect.'), reason: s);
        expect(say(s, {}), isNot(contains('Wall Finished')), reason: s);
        expect(say(s, ticks(['wf_other'])), isNot(contains('Wall Finished')), reason: '$s other with nothing typed');
      }
    });
    test('the report order is Description, Wall Finished, Condition (so Condition covers both)', () {
      for (final s in wallScreens) {
        final out = phrases(s, ticks(['e4w_loc_main_building', 'wf_rendered', 'cb_painted'], {'et_thickness': '280', 'actv_condition': 'Fair', 'other': 'steel frame'}));
        final d = out.indexWhere((p) => p.startsWith('Description:'));
        final w = out.indexWhere((p) => p.startsWith('Wall Finished:'));
        final c = out.indexWhere((p) => p.startsWith('Condition:'));
        expect(d, greaterThanOrEqualTo(0), reason: s);
        expect(w, d + 1, reason: s);
        expect(c, w + 1, reason: s);
      }
    });
    test('the old Rendered Wall sentence is gone from the bank', () {
      expect(phraseTexts.containsKey('{E_MAIN_WALLS}::{E4_RENDERED_WALL}'), isFalse);
      for (final s in wallScreens) {
        expect(say(s, ticks(['cb_rendered_wall'])), isNot(contains('Rendered Wall:')), reason: s);
      }
    });
    test('an older survey with the rendered wall tick prints it as the rendered finish', () {
      for (final s in wallScreens) {
        final m = migrateLegacyAnswers(s, {'cb_rendered_wall': 'true'});
        expect(m['wf_rendered'], 'true', reason: s);
        expect(m.containsKey('cb_rendered_wall'), isFalse, reason: s);
        expect(say(s, m), contains('Wall Finished: The outer face of the external walls is rendered.'), reason: s);
      }
    });
    test('an older survey that used the Pebble dash screen shows on the combined screen as coated with pebble dash', () {
      const rendered = '${wallPrefix}__rendered_masonry';
      final moved = movedAnswers[rendered]!;
      expect(moved.fromScreen, '${wallPrefix}__pebble_dash_masonry');
      final merged = migrateLegacyAnswers(
        rendered,
        mergeMovedAnswers(rendered, {}, {'e4w_loc_main_building': 'true', 'et_thickness': '230', 'actv_condition': 'Poor', 'cb_rendered_wall': 'true'}),
      );
      final out = say(rendered, merged);
      expect(out, contains('constructed of 230 mm rendered masonry'));
      expect(out, contains('Wall Finished: The outer face of the external walls is rendered and coated with pebble dash.'));
      expect(out, contains('appear in poor condition'));
    });
  });

  group('2 Main Wall Lintel: Windows and Door say which opening', () {
    const win = 'activity_outside_property_main_wall_repairs_lintel';
    const door = 'activity_outside_property_main_wall_repairs_lintel__door';
    final base = ticks(['e4l_w_front', 'e4l_w_rear', 'e4l_l_main_building', 'e4l_l_bay_window']);
    test('the Windows screen says window opening', () {
      expect(nodes[win]!.title, 'Windows');
      final out = say(win, base);
      expect(out, contains('Lintel defect: The lintel (the beam supporting the masonry above a window opening), including a brick arch where applicable, in the front and rear wall of the main building and bay window is damaged, cracked, or distorted.'));
      expect(out, isNot(contains('door')));
    });
    test('the Door screen says door opening', () {
      expect(nodes[door]!.title, 'Door');
      final out = say(door, base);
      expect(out, contains('Lintel defect: The lintel (the beam supporting the masonry above a door opening), including a brick arch where applicable, in the front and rear wall of the main building and bay window is damaged, cracked, or distorted.'));
      expect(out, isNot(contains('window opening')));
    });
    test('Minor defects and Significant defect read the same on both screens', () {
      for (final s in [win, door]) {
        final minor = say(s, {...base, 'actv_condition': 'Minor defects'});
        expect(minor, contains('Minor defects: The defects observed are limited and do not require significant repair.'), reason: s);
        expect(minor, contains('integrity of the lintel or brick arch'), reason: s);
        final big = say(s, {...base, 'actv_condition': 'Significant defect'});
        expect(big, contains('Significant defect: The defects observed are significant and have caused, or are likely to cause, movement or damage to the adjoining masonry.'), reason: s);
        expect(big, isNot(contains('Minor defects:')), reason: s);
      }
    });
    test('each screen has its own key; the old one-sentence key is kept only for phones on an older app version', () {
      expect(phraseTexts['{E_MAIN_WALLS}::{E4_LINTEL_WINDOW}'], contains('above a window opening'));
      expect(phraseTexts['{E_MAIN_WALLS}::{E4_LINTEL_DOOR}'], contains('above a door opening'));
      expect(phraseTexts['{E_MAIN_WALLS}::{E4_LINTEL}'], contains('above a door or window opening'));
    });
  });

  group('4 Large Outbuilding: every type has the full set of options', () {
    const base = 'activity_grounds_other_large_outbuildings';
    const types = {
      'large_shed': 'a large shed',
      'workshop': 'a workshop',
      'annex': 'an annex',
      'summer_house': 'a summer house',
      'office': 'an office',
      'studio': 'a studio',
    };
    final screens = [for (final k in [...types.keys, 'other']) '${base}__$k'];
    Map<String, String> full() => ticks(
          ['cb_h2_h2_ob', 'cb_h2_h2_ob_cons', 'h2_ob_cons_0_timber', 'h2_ob_cons_0_steel', 'cb_h2_h2_ob_roof', 'h2_ob_roof_0_pitched', 'h2_ob_roof_1_slates', 'cb_h2_h2_ob_floor', 'h2_ob_floor_0_concrete', 'cb_h2_h2_ob_doors', 'h2_ob_doors_0_aluminium', 'cb_h2_h2_ob_no_defects'],
          {'actv_h2_ob_cond': 'Fair', 'h2_ob_0_other_text': 'games room'},
        );

    test('Large Outbuilding is a group with one screen for each type, in the client order', () {
      expect(nodes.containsKey(base), isFalse);
      final group = nodes['group_large_outbuilding_54']!;
      expect(group.title, 'Large Outbuilding');
      final kids = [for (final s in screens) nodes[s]!];
      expect([for (final k in kids) k.title], ['Large shed', 'Workshop', 'Annex', 'Summer house', 'Office', 'Studio', 'Other outbuilding']);
      for (final k in kids) {
        expect(k.parentId, 'group_large_outbuilding_54');
      }
      final orders = [for (final k in kids) k.order];
      expect(orders, [...orders]..sort());
    });
    test('each type screen has structure, roof, roof cover, floor and doors/windows options, each with Other', () {
      List<String> labelsOf(Map<String, dynamic> f, List<String> ids) => [for (final id in ids) (f[id] as dynamic).label as String];
      for (final s in screens) {
        final f = <String, dynamic>{for (final x in nodes[s]!.fields) x.id: x};
        expect(labelsOf(f, ['h2_ob_cons_0_bricks', 'h2_ob_cons_0_blocks', 'h2_ob_cons_0_timber', 'h2_ob_cons_0_steel', 'h2_ob_cons_0_prefabricated_concrete', 'h2_ob_cons_0_aluminium', 'h2_ob_cons_0_composite_boards']),
            ['bricks', 'blocks', 'timber', 'steel', 'prefabricated concrete', 'aluminium', 'composite boards'], reason: s);
        expect(labelsOf(f, ['h2_ob_roof_0_pitched', 'h2_ob_roof_0_flat', 'h2_ob_roof_0_lean_to']), ['pitched', 'flat', 'lean-to'], reason: s);
        expect(labelsOf(f, ['h2_ob_roof_1_clay_tiles', 'h2_ob_roof_1_concrete_tiles', 'h2_ob_roof_1_slates', 'h2_ob_roof_1_felt', 'h2_ob_roof_1_rubber_membrane', 'h2_ob_roof_1_metal_sheets']),
            ['clay tiles', 'concrete tiles', 'slates', 'felt', 'rubber membrane', 'metal sheets'], reason: s);
        expect(labelsOf(f, ['h2_ob_floor_0_concrete', 'h2_ob_floor_0_suspended_timber', 'h2_ob_floor_0_engineered_timber', 'h2_ob_floor_0_beam_and_block']),
            ['concrete', 'suspended timber', 'engineered timber', 'beam and block'], reason: s);
        expect(labelsOf(f, ['h2_ob_doors_0_timber_upvc', 'h2_ob_doors_0_aluminium', 'h2_ob_doors_0_metal']), ['timber uPVC', 'aluminium', 'metal'], reason: s);
        for (final other in ['h2_ob_cons_0_other', 'h2_ob_roof_0_other', 'h2_ob_roof_1_other', 'h2_ob_floor_0_other', 'h2_ob_doors_0_other']) {
          expect((f[other] as dynamic).label, 'Other', reason: '$s $other');
          expect((f['${other}_text'] as dynamic).conditionalOn, other, reason: '$s $other');
        }
        expect((f['actv_h2_ob_cond'] as dynamic).options, ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'], reason: s);
        expect(f.containsKey('h2_ob_0_workshop'), isFalse, reason: '$s: the type list is gone, the screen is the type');
      }
    });
    test('each type prints its own Outbuilding sentence and the same full set of sentences', () {
      types.forEach((key, word) {
        final out = say('${base}__$key', full());
        expect(out, contains('Outbuilding: The property incorporates $word permanent structure (s).'), reason: key);
        expect(out, contains('Construction: The structure(s) is formed of timber and steel materials.'), reason: key);
        expect(out, contains('Roof: The roof is of pitched construction and is covered with slates material.'), reason: key);
        expect(out, contains('Floor: The floor is constructed of concrete material.'), reason: key);
        expect(out, contains('Doors and windows: The outbuilding(s) are fitted with door(s) and/or window(s) formed of aluminium framed units.'), reason: key);
        expect(out, contains('Condition: Where visible, the building appears in fair condition.'), reason: key);
        expect(out, contains('No defects noted: No significant defects requiring immediate attention were identified unless otherwise stated below.'), reason: key);
        for (final other in types.keys.where((k) => k != key)) {
          expect(out, isNot(contains(types[other]!)), reason: '$key must not name $other');
        }
      });
    });
    test('Other prints the typed name of the outbuilding', () {
      final out = say('${base}__other', full());
      expect(out, contains('Outbuilding: The property incorporates a games room permanent structure (s).'));
      expect(say('${base}__other', {...full(), 'h2_ob_0_other_text': 'office annex'}), contains('incorporates an office annex permanent structure (s).'));
      expect(say('${base}__other', ticks(['cb_h2_h2_ob'])), isNot(contains('Outbuilding:')));
    });
    test('nothing ticked prints nothing on any type screen', () {
      for (final s in screens) {
        expect(say(s, {}), isEmpty, reason: s);
      }
    });
    test('an older survey with several types on the one old screen gets each type its own screen', () {
      final old = <String, String>{
        ...full(),
        'h2_ob_0_workshop': 'true',
        'h2_ob_0_office': 'true',
      };
      String migrated(String key) {
        final s = '${base}__$key';
        return say(s, migrateLegacyAnswers(s, mergeMovedAnswers(s, {}, old)));
      }
      for (final key in ['workshop', 'office']) {
        final out = migrated(key);
        expect(out, contains('Outbuilding: The property incorporates ${key == 'office' ? 'an' : 'a'} $key permanent structure (s).'), reason: key);
        expect(out, contains('Construction: The structure(s) is formed of timber and steel materials.'), reason: key);
        expect(out, contains('Condition: Where visible, the building appears in fair condition.'), reason: key);
      }
      for (final key in ['large_shed', 'annex', 'summer_house', 'studio', 'other']) {
        expect(migrated(key), isEmpty, reason: '$key was not chosen in the old survey');
      }
    });
    test('an older survey that typed an Other outbuilding keeps its name', () {
      final old = {...full(), 'h2_ob_0_other': 'true'};
      final s = '${base}__other';
      final out = say(s, migrateLegacyAnswers(s, mergeMovedAnswers(s, {}, old)));
      expect(out, contains('Outbuilding: The property incorporates a games room permanent structure (s).'));
    });
  });

  group('5 Outside Doors: Description and material on one line, BS EN once', () {
    const doors = 'activity_outside_property_out_side_doors_about_doors';
    test('Description and the material sentence are one paragraph', () {
      final out = phrases(doors, ticks(['e6t_original', 'e6t_front', 'e6m_timber']));
      expect(out.first, 'Description: The property incorporates original and front doors. The external doors are formed of timber material.');
      expect(out.where((p) => p.contains('The external doors are formed of')), hasLength(1));
    });
    test('every list item still prints, joined in the same paragraph', () {
      final out = phrases(doors, ticks(['e6t_rear', 'e6t_patio', 'e6m_pvcu', 'e6m_steel']));
      expect(out.first, 'Description: The property incorporates rear and patio doors. The external doors are formed of PVCu and steel material.');
    });
    test('with no door types ticked the material sentence stands alone, with no door material the Description stands alone', () {
      final materialOnly = phrases(doors, ticks(['e6m_timber']));
      expect(materialOnly, ['The external doors are formed of timber material.']);
      final typesOnly = phrases(doors, ticks(['e6t_old']));
      expect(typesOnly, ['Description: The property incorporates old doors.']);
    });
    test('the material sentence does not move up when something else came between', () {
      final out = phrases(doors, ticks(['e6m_aluminium'], {'actv_condition': 'Fair'}));
      expect(out, contains('The external doors are formed of aluminium material.'));
      expect(out.where((p) => p.contains('formed of aluminium')).single, 'The external doors are formed of aluminium material.');
      expect(out.any((p) => p.startsWith('Condition:')), isTrue);
    });
    test('BS EN noted prints its own sentence once, with no second sentence', () {
      final out = say(doors, {'actv_status': 'BS EN noted'});
      expect(out, startsWith('BS EN noted: Visible British Standard, BS EN, or other permanent safety markings were identified on the accessible glazing.'));
      expect('BS EN noted:'.allMatches(out), hasLength(1));
      expect(out, isNot(contains('No visible')));
      expect(out, isNot(contains('absence of visible markings')));
      expect(out, endsWith('your legal adviser should verify any available certification relating to replacement windows.'));
      expect(phraseTexts['{E_OUTSIDE_DOORS}::{E6_BS_EN_NOTED}'], isNot(contains('No visible')));
    });
    test('No BS EN noted prints its own sentence once', () {
      final out = say(doors, {'actv_status': 'No BS EN noted'});
      expect(out, startsWith('No BS EN noted: No visible British Standard, BS EN, or other permanent safety markings were identified on the accessible glazing.'));
      expect('BS EN noted:'.allMatches(out), hasLength(1));
      expect(out, isNot(contains('Visible British Standard')));
    });
    test('the windows and conservatory BS EN sentences are unchanged', () {
      expect(phraseTexts['{E_WINDOWS}::{E5_BS_EN_NOTED}'], startsWith('BS EN noted: Visible British Standard'));
      expect('BS EN noted:'.allMatches(phraseTexts['{E_CONSERVATORY_PORCHES}::{E7_C_BS_EN_NOTED}']!), hasLength(1));
      expect('BS EN noted:'.allMatches(phraseTexts['{E_CONSERVATORY_PORCHES}::{E7_P_BS_EN_NOTED}']!), hasLength(1));
    });
  });
}
