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
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

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
        }
      }
      expect(broken, isEmpty);
    });

    test('a landing and its inner group with one name appear once', () {
      expect(path('E', 'activity_outside_property_windows_sill_defect'),
          ['Outside the Property', 'Windows', 'Sill Defect']);
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

  group('Shed and Ceiling repairs', () {
    final engine = InspectionPhraseEngine(
      (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );

    test('Shed is in the garden area, Repairs has Shed Repair', () {
      expect(nodes['activity_grounds_other_repair_shed']!.parentId, 'group_other_53');
      final repair = nodes['activity_grounds_other_repair_shed_repair']!;
      expect(repair.title, 'Shed Repair');
      expect(repair.parentId, 'group_repairs_54');
    });

    test('Shed Repair prints its approved sentence', () {
      expect(
        engine.buildPhrases('activity_grounds_other_repair_shed_repair', {
          'h2rs_timber': 'true',
          'h2rs_damaged': 'true',
        }),
        ['The timber shed is damaged. This should be repaired or replaced soon.'],
      );
      expect(engine.buildPhrases('activity_grounds_other_repair_shed_repair', const {}), isEmpty);
    });

    test('Ceiling repairs are more than ornamental plaster', () {
      final repairs = [
        for (final n in nodes.values)
          if (n.parentId == 'group_repairs_62') n.title,
      ];
      expect(repairs, ['Repair Ceilings', 'Ornamental Plaster']);
    });

    test('Repair Ceilings prints repair soon and repair now', () {
      const screen = 'activity_inside_property_ceilings_repairs_ceilings';
      expect(
        engine.buildPhrases(screen, {
          'actv_status': 'Repair soon',
          'f2r_soon_lounge': 'true',
          'f2r_soon_uneven': 'true',
        }),
        ['The ceilings to the lounge are uneven. This should be repaired soon.'],
      );
      expect(
        engine.buildPhrases(screen, {
          'actv_status': 'Repair now',
          'f2r_now_kitchen': 'true',
          'f2r_now_badly_cracked': 'true',
        }).single,
        startsWith('The ceilings to the kitchen are badly cracked'),
      );
    });
  });

  test('Cellar screens in the client order; "Used as" only holds the use', () {
    expect(nodes['group_cellar_83']!.title, 'Cellar');
    final titles = tree.sections
        .firstWhere((s) => s.key == 'F')
        .nodes
        .where((n) => n.parentId == 'group_cellar_83')
        .map((n) => n.title)
        .toList();
    expect(titles, ['Not inspected', 'Walls', 'Floor', 'Condition', 'Used as', 'Unsuitable', 'Flooded', 'Damp', 'Timber decay']);
    final usedAs = nodes['activity_inside_property_other_celler_inspected']!;
    expect(usedAs.fields.map((f) => f.id), ['actv_used_as']);
    expect(usedAs.fields.single.options, ['Not in use', 'In use']);
  });

  // Client file (3), 10 Nov 2026: the Heating screen's own copies of these
  // controls were removed; the Heating screen (About Heating content) asks them.
  group('Heating screen', () {
    final fields = sanitizeInspectionFieldsForScreen(
      'activity_services_heating_about_heating',
      nodes['activity_services_heating_about_heating']!.fields,
    );

    test('Location: multiple selection with Airing cupboard and Other text', () {
      final labels = fields.where((f) => f.id.startsWith('g4l_')).map((f) => f.label).toList();
      // Client file 6 (12 Nov 2026): the locations read "the kitchen" ... in the sentence.
      expect(labels, ['the kitchen', 'the utility room', 'the bedroom', 'under the stairs', 'the garage', 'the airing cupboard', 'Other', 'Other']);
      expect(fields.firstWhere((f) => f.id == 'g4l_airing_cupboard').type, InspectionFieldType.checkbox);
      final otherText = fields.firstWhere((f) => f.id == 'g4l_other_text');
      expect(otherText.type, InspectionFieldType.text);
      expect(shouldShowInspectionField(otherText, const {'g4l_other': 'true'}), isTrue);
      expect(shouldShowInspectionField(otherText, const {}), isFalse);
    });

    test('Connected heat emitters: multiple selection', () {
      final ticks = fields.where((f) => f.id.startsWith('g4e_') && f.type == InspectionFieldType.checkbox);
      expect(ticks.map((f) => f.label), ['radiators', 'underfloor heating pipes', 'ceiling vents', 'wall vents', 'Other']);
    });

    test('rating screen keeps only rating and note', () {
      final rating = sanitizeInspectionFieldsForScreen(
        'activity_services_heating_main_screen',
        nodes['activity_services_heating_main_screen']!.fields,
      );
      expect(rating.map((f) => f.id), ['android_material_design_spinner4', 'ar_etNote']);
    });

    test('values saved before the change become ticks', () {
      expect(
        migrateLegacyAnswers('activity_services_heating_main_screen',
            {'actv_location': 'Kitchen', 'actv_connected_heat': 'Radiators', 'actv_boiler': 'Other'}),
        {'g4b_kitchen': 'true', 'g4he_radiators': 'true', 'actv_boiler': 'Other'},
      );
    });
  });

  group('Gas meter comment', () {
    final engine = InspectionPhraseEngine(
      (jsonDecode(File('assets/property_inspection/phrase_texts.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
    const screen = 'activity_services_main_gas';

    test('with a location: the approved sentence', () {
      expect(
        engine.buildPhrases(screen, {'actv_condition': 'Metre', 'g2m_in_the_kitchen': 'true'}).single,
        startsWith('Metre: There is a mains gas connection to the property, and the meter unit is located in the kitchen.'),
      );
    });

    test('without a location: still printed, without the location clause', () {
      final phrase = engine.buildPhrases(screen, {'actv_condition': 'Metre'}).single;
      expect(phrase, startsWith('Metre: There is a mains gas connection to the property.'));
      expect(phrase, isNot(contains('{')));
    });

    test('Metre not found keeps its own sentence; nothing chosen prints nothing', () {
      expect(engine.buildPhrases(screen, {'actv_condition': 'Metre not found'}).single, startsWith('Metre not found:'));
      expect(engine.buildPhrases(screen, const {}), isEmpty);
    });
  });
}
