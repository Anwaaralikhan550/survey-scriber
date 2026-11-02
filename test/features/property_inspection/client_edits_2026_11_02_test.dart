// Client edit list "Survey Scriber Edit Oct 2026.docx" (2 Nov 2026): the app screens.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_breadcrumb.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/legacy_answer_migration.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_breadcrumb_bar.dart';

void main() {
  final tree = InspectionTreePayload.fromJson(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final nodes = {
    for (final s in tree.sections)
      for (final n in s.nodes) n.id: n,
  };

  test('Overall Opinion spelling', () {
    expect(nodes['activity_over_all_openion']!.title, 'Overall Opinion');
  });

  test('Kitchen: the defects list under Repairs is titled Defects', () {
    expect(nodes['activity_in_side_property_built_in_fittings_repair_moulding_noted']!.title, 'Defects');
  });

  test('Solar water heating: only the standalone screen remains', () {
    final about = nodes['activity_services_water_heating_gas_heating']!;
    expect(about.fields.map((f) => f.id), isNot(contains('cb_wh_solar')));
    expect(nodes['activity_services_water_heating_solar_power']!.title, 'Solar water heating');
  });

  test('Listed Building appears once, not inside Construction', () {
    expect(nodes.containsKey('activity_listed_building'), isFalse);
    expect(nodes['activity_listed_building__listed_building']!.parentId, isNull);
  });

  test('Area and its repeated gardens are gone; Location density and the garden screens stay', () {
    for (final id in ['activity_property_ground_area', 'group_area_4', 'activity_garden', 'activity_parking']) {
      expect(nodes.containsKey(id), isFalse, reason: id);
    }
    for (final id in ['activity_property_location', 'activity_front_garden', 'activity_rear_garden',
      'activity_communal_garden', 'activity_parking__parking']) {
      expect(nodes.containsKey(id), isTrue, reason: id);
    }
    expect(kVerbatimRules.where((r) => r.id == 'a4_conservation').single.screen, 'activity_property_location');
  });

  test('Ground tile comes straight after Construction', () {
    final d = tree.sections.firstWhere((s) => s.key == 'D');
    final tiles = d.nodes.where((n) => n.parentId == null).map((n) => n.id).toList();
    expect(tiles.indexOf('group_ground_3'), tiles.indexOf('group_construction_2') + 1);
  });

  group('Garden phrases print from the ticked options', () {
    final engine = InspectionPhraseEngine(
      (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );

    test('Rear Garden boundaries without the heading tick', () {
      final phrases = engine.buildPhrases('activity_rear_garden', {
        'rear_type_0_lawn': 'true',
        'rear_fence_0_timber_fencing': 'true',
        'rear_fence_0_hedging': 'true',
      });
      expect(phrases, contains('Rear garden: The rear garden is laid to lawn.'));
      expect(phrases.join(' '), contains('timber fencing and hedging'));
    });

    test('Communal Garden without the heading tick', () {
      final phrases = engine.buildPhrases('activity_communal_garden', {
        'communal_type_0_paving': 'true',
        'communal_fence_0_brick_wall': 'true',
      });
      expect(phrases.join(' '), contains('The communal garden is laid to paving.'));
      expect(phrases.join(' '), contains('brick wall'));
    });

    test('nothing ticked prints nothing', () {
      expect(engine.buildPhrases('activity_rear_garden', const {}), isEmpty);
      expect(engine.buildPhrases('activity_communal_garden', const {}), isEmpty);
    });
  });

  group('Movement status: multiple selection', () {
    const screen = 'activity_outside_property_main_walls_movements';

    test('options are ticks; follow-up boxes still open', () {
      final fields = nodes[screen]!.fields;
      expect(fields.map((f) => f.id), isNot(contains('actv_movement_status')));
      final ticks = fields.where((f) => f.id.startsWith('mv_'));
      expect(ticks.map((f) => f.label), [
        'Minor subsidence', 'Significant subsidence', 'No structural movement', 'Normal defects',
        'Recent defects', 'Recurring defects', 'Differential thermal movement', 'Restraint steel rods',
      ]);
      expect(ticks.every((f) => f.type == InspectionFieldType.checkbox), isTrue);
      expect(fields.firstWhere((f) => f.id == 'e4m_w_front').conditionalOn, 'mv_recent_defects');
      expect(fields.firstWhere((f) => f.id == 'e4m_r_main_building').conditionalOn, 'mv_recurring_defects');
      expect(fields.firstWhere((f) => f.id == 'e4m_l_other_text').conditionalOn, 'mv_recent_defects&e4m_l_other');
    });

    test('each tick prints its own sentence', () {
      final engine = InspectionPhraseEngine(
        (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
                as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
      final one = engine.buildPhrases(screen, {'mv_minor_subsidence': 'true'});
      final two = engine.buildPhrases(screen, {
        'mv_minor_subsidence': 'true',
        'mv_differential_thermal_movement': 'true',
      });
      expect(one, hasLength(1));
      expect(two, hasLength(2));
      expect(two, contains(one.single));
    });

    test('a value saved before the change becomes its tick', () {
      expect(migrateLegacyAnswers(screen, {'actv_movement_status': 'Recent defects', 'e4m_w_front': 'true'}),
          {'mv_recent_defects': 'true', 'e4m_w_front': 'true'});
    });

    test('the old value does not come back once ticks are saved', () {
      expect(migrateLegacyAnswers(screen, {'actv_movement_status': 'Recent defects', 'mv_recent_defects': 'false'}),
          {'mv_recent_defects': 'false'});
    });

    test('other screens are untouched', () {
      const other = {'actv_movement_status': 'Recent defects'};
      expect(migrateLegacyAnswers('activity_party_disclosure', other), other);
    });
  });

  group('Windows: Sill Projection and Sill Defect are separate', () {
    const projection = 'activity_outside_property_windows_sill_projection';
    const defect = 'activity_outside_property_windows_sill_defect';
    final engine = InspectionPhraseEngine(
      (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );

    test('two screens under Windows, no choice between them', () {
      expect(nodes[projection]!.fields.map((f) => f.id), ['actv_condition']);
      expect(nodes[projection]!.fields.single.conditionalOn, isNull);
      expect(nodes[defect]!.title, 'Sill Defect');
      expect(nodes[defect]!.parentId, 'group_windows_21');
      expect(nodes[defect]!.fields.where((f) => f.conditionalOn != null), isEmpty);
    });

    test('each prints its own sentence, on its own', () {
      final a = engine.buildPhrases(projection, {'actv_condition': 'Properly'});
      final b = engine.buildPhrases(defect, {'e5sd_cracked': 'true'});
      expect(a.single, startsWith('Sill projection:'));
      expect(b.single, startsWith('Sill defect:'));
      expect(b.single, contains('cracked'));
      expect(engine.buildPhrases(projection, const {}), isEmpty);
      expect(engine.buildPhrases(defect, const {}), isEmpty);
    });

    test('defects saved on the old screen show on the new one', () {
      expect(
        mergeMovedAnswers(defect, const {}, {'e5sd_cracked': 'true', 'actv_condition': 'Fairly'}),
        {'e5sd_cracked': 'true'},
      );
      expect(
        mergeMovedAnswers(defect, {'e5sd_cracked': 'false'}, {'e5sd_cracked': 'true'}),
        {'e5sd_cracked': 'false'},
      );
    });
  });

  group('Header shows where the surveyor is', () {
    final nodeMap = {
      for (final sec in tree.sections)
        for (final n in sec.nodes) n.id: n,
    };

    List<String> path(String key, String id) =>
        inspectionBreadcrumb(sectionKey: key, nodeId: id, nodeMap: nodeMap);

    test('every screen has its section, its groups and its own title', () {
      final broken = <String>[];
      for (final sec in tree.sections) {
        for (final n in sec.nodes) {
          final p = path(sec.key, n.id);
          if (p.first != inspectionSectionTitle(sec.key) || p.last.isEmpty || p.length < 2) {
            broken.add(n.id);
          }
          if (n.parentId != null && p.length < 3) broken.add(n.id);
        }
      }
      expect(broken, isEmpty);
    });

    test('Carport roof and Porches roof read differently', () {
      final carport = path('E', 'activity_outside_property_other_other_roof');
      final porch = path('E', 'activity_outside_property_conservatory_porch_roof__roof');
      expect(carport.last, 'Roof');
      expect(porch.last, 'Roof');
      expect(carport.join(), contains('Carport'));
      expect(porch.join(), contains('Porch'));
      expect(carport.first, 'Outside the Property');
    });

    testWidgets('the bar shows the path and a long path does not overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 320,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Roof'),
              bottom: const InspectionBreadcrumbBar(
                path: ['Outside the Property', 'Other Outside Property', 'Repairs', 'External structures', 'Roof'],
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Outside the Property > Other Outside Property > Repairs > External structures > Roof'), findsOneWidget);
    });
  });
}
