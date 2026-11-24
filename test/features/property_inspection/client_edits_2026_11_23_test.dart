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
    test('the old one-sentence key for both openings is gone', () {
      expect(phraseTexts['{E_MAIN_WALLS}::{E4_LINTEL}'], isNot(contains('door or window')));
      expect(phraseTexts['{E_MAIN_WALLS}::{E4_LINTEL_DOOR}'], contains('above a door opening'));
    });
  });
}
