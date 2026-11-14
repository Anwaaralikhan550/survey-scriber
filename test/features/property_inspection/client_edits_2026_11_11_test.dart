// Client file (5), 11 Nov 2026: Sill Defect words, Other Garden, Cellar and Basement as two elements.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/client_paragraph_rules.dart';

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

  group('Windows Sill Defect: inadequate, poorly installed, poorly drained', () {
    const screen = 'activity_outside_property_windows_sill_defect';

    test('the three boxes read as the client asked, the rest unchanged', () {
      expect(nodes[screen]!.fields.where((f) => f.type.name == 'checkbox').map((f) => f.label), [
        'inadequate',
        'poorly installed',
        'poorly drained',
        'cracked',
        'defective',
      ]);
    });

    test('the existing sentence prints with the new words', () {
      final out = engine.buildPhrases(screen, ticks(['e5sd_adequate', 'e5sd_properly_installed', 'e5sd_properly_drained'])).join(' ');
      expect(
        out,
        contains(
          'Sill defect: The windowsill projection beyond the face of the wall does not appear to be inadequate, poorly installed and poorly drained.',
        ),
      );
      expect(out, contains('This is allowing water ingress to adjoining walls'));
    });

    test('cracked and defective are unchanged', () {
      final out = engine.buildPhrases(screen, ticks(['e5sd_cracked', 'e5sd_defective'])).join(' ');
      expect(out, contains('does not appear to be cracked and defective.'));
    });
  });

  group('Other Garden between Rear Garden and Communal Garden', () {
    const screen = 'activity_other_garden';

    test('a tile after Rear Garden and before Communal Garden, with a place to type the location', () {
      final ground = tree.sections.expand((s) => s.nodes).where((n) => n.parentId == 'group_ground_3').map((n) => n.title).toList();
      expect(ground, ['Topography', 'Front Garden', 'Rear Garden', 'Other Garden', 'Communal Garden', 'Parking', 'Gated Community']);
      final fields = nodes[screen]!.fields;
      expect(fields.first.id, 'og_location');
      expect(fields.first.type.name, 'text');
      // The same finishes and boundaries as Rear Garden.
      final rear = nodes['activity_rear_garden']!.fields.map((f) => f.label).where((l) => !l.startsWith('Rear')).toList();
      final other = fields.skip(1).map((f) => f.label).where((l) => !l.startsWith('Other garden')).toList();
      expect(other, rear);
    });

    test('Side Garden: the typed place heads the sentence, finishes and boundaries print', () {
      final out = engine.buildPhrases(
        screen,
        ticks(['cb_other_garden_type', 'og_type_0_lawn', 'og_type_0_paving', 'cb_other_garden_fence', 'og_fence_0_hedging'],
            {'og_location': 'Side Garden'}),
      );
      expect(out, [
        'Side garden: The side garden is laid to lawn and paving.',
        'Fencing: Boundaries are formed by hedging.',
      ]);
    });

    test('nothing typed: it reads Other garden, nothing is lost', () {
      final out = engine.buildPhrases(screen, ticks(['cb_other_garden_type', 'og_type_0_gravel']));
      expect(out, ['Other garden: The other garden is laid to gravel.']);
    });

    test('Other finishes typed by the surveyor print too', () {
      final out = engine.buildPhrases(
        screen,
        ticks(['cb_other_garden_type', 'og_type_0_other'], {'og_location': 'Rooftop garden', 'og_type_0_other_text': 'wild flowers'}),
      );
      expect(out, ['Rooftop garden: The rooftop garden is laid to wild flowers.']);
    });

    test('Rear and Communal gardens print as before', () {
      expect(
        engine.buildPhrases('activity_rear_garden', ticks(['cb_rear_type', 'rear_type_0_lawn'])),
        ['Rear garden: The rear garden is laid to lawn.'],
      );
      expect(
        engine.buildPhrases('activity_communal_garden', ticks(['cb_communal_type', 'communal_type_0_lawn'])),
        ['Communal garden: The communal garden is laid to lawn.'],
      );
    });
  });

  group('Cellar and Basement are two elements', () {
    List<String> titlesUnder(String group) =>
        tree.sections.expand((s) => s.nodes).where((n) => n.parentId == group).map((n) => n.title).toList();

    test('two groups, the same nine screens each, own ids', () {
      expect(nodes['group_cellar_83']!.title, 'Cellar');
      expect(nodes['group_basement_84']!.title, 'Basement');
      expect(nodes['group_basement_84']!.parentId, nodes['group_cellar_83']!.parentId);
      const same = ['Not inspected', 'Walls', 'Floor', 'Condition', 'Used as', 'Unsuitable', 'Flooded', 'Damp', 'Timber decay'];
      expect(titlesUnder('group_cellar_83'), same);
      expect(titlesUnder('group_basement_84'), same);
      final cellar = [for (final n in nodes.values) if (n.parentId == 'group_cellar_83') n];
      final basement = [for (final n in nodes.values) if (n.parentId == 'group_basement_84') n];
      for (var i = 0; i < cellar.length; i++) {
        expect(basement[i].fields.length, cellar[i].fields.length, reason: cellar[i].title);
        for (final f in basement[i].fields) {
          expect(f.label.toLowerCase(), isNot(contains('cellar')), reason: '${basement[i].title}: ${f.label}');
        }
      }
      final cellarIds = {for (final n in cellar) for (final f in n.fields) if (f.type.name == 'checkbox') f.id};
      final basementIds = {for (final n in basement) for (final f in n.fields) if (f.type.name == 'checkbox') f.id};
      expect(cellarIds.intersection(basementIds), isEmpty);
    });

    test('Basement sentences say basement, in the Cellar sentences words', () {
      final unused =
          engine.buildPhrases('activity_inside_property_other_basement_inspected', {'actv_used_as': 'Not in use'}).join(' ');
      expect(
        unused,
        'Not in use: The property has a basement which is currently unused. No significant defects were apparent from the limited inspection. Routine maintenance is recommended.',
      );
      final walls =
          engine.buildPhrases('activity_inside_property_other_basement_walls', ticks(['f9bcw_bricks', 'f9bcw_concrete'])).join(' ');
      expect(walls, 'Walls: The property incorporates a basement and the walls are formed in bricks and concrete materials.');
      final cond = engine.buildPhrases('activity_inside_property_other_basement_condition', {'actv_condition': 'Fair'}).join(' ');
      expect(cond, startsWith('Condition: Where visible, the basement appears in fair condition.'));
      final damp = engine
          .buildPhrases('activity_inside_property_other_basement_damp', ticks(['f9bdm_throughout_the_basement', 'cb_serious_dump_b']))
          .join(' ');
      expect(damp, contains('Damp: Dampness was noted on the throughout the basement.'));
      expect(damp, contains('Waterproofing failure:'));
      final notInspected =
          engine.buildPhrases('activity_inside_property_other_basement_no_access', ticks(['f9bna_no_access'])).join(' ');
      expect(notInspected, startsWith('Basement Not inspected: The property has a basement, but it could not be inspected due to no access.'));
    });

    test('Cellar sentences are exactly as before', () {
      final walls = engine.buildPhrases('activity_inside_property_other_celler_walls', ticks(['f9cw_bricks'])).join(' ');
      expect(walls, 'Walls: The property incorporates a cellar and the walls are formed in bricks materials.');
    });

    test('the report prints Cellar, then Basement, each with its own heading and paragraphs', () {
      expect(
        applyClientParagraphRules(
          'group_f9_other_81',
          [
            'Description: Internal communal parts to the property comprise a hallway.',
            'Cellar/Basement Not inspected: The property has a cellar or basement, but it could not be inspected due to no access.',
            'General Maintenance: Ancillary internal areas should be inspected periodically.',
          ],
          basement: [
            'Walls: The property incorporates a basement and the walls are formed in bricks materials.',
            'Condition: Where visible, the basement appears in good condition. Minor dampness may be expected. '
                'No defects noted: No significant defects requiring immediate attention were identified unless '
                'otherwise stated below. Routine maintenance is recommended.',
          ],
        ),
        [
          'Description: Internal communal parts to the property comprise a hallway.',
          '[[SUBHEADING]] Cellar',
          'Not inspected: The property has a cellar or basement, but it could not be inspected due to no access.',
          '[[SUBHEADING]] Basement',
          'Walls: The property incorporates a basement and the walls are formed in bricks materials.',
          'Condition: Where visible, the basement appears in good condition. Minor dampness may be expected.',
          'No defects noted: No significant defects requiring immediate attention were identified unless otherwise stated below. Routine maintenance is recommended.',
          'General Maintenance: Ancillary internal areas should be inspected periodically.',
        ],
      );
    });

    test('Basement only: it still gets its own heading, before General Maintenance', () {
      expect(
        applyClientParagraphRules(
          'group_f9_other_81',
          ['General Maintenance: Ancillary internal areas should be inspected periodically.'],
          basement: ['Basement Not inspected: The property has a basement, but it could not be inspected due to no access.'],
        ),
        [
          '[[SUBHEADING]] Basement',
          'Not inspected: The property has a basement, but it could not be inspected due to no access.',
          'General Maintenance: Ancillary internal areas should be inspected periodically.',
        ],
      );
    });
  });
}
