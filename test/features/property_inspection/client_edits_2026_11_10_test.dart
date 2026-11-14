// Client edit list "Survey Scriber Edit Oct 2026 (3).docx" (10 Nov 2026).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_breadcrumb.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

void main() {
  final phraseTexts = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final engine = InspectionPhraseEngine(phraseTexts);

  Map<String, String> ticks(List<String> ids, [Map<String, String> extra = const {}]) =>
      {for (final i in ids) i: 'true', ...extra};

  group('A ticked choice counts as its gate (Garage, Drainage, Cylinder, G7)', () {
    test('Garage: choices without the section boxes still print', () {
      final out = engine.buildPhrases(
        'activity_grounds_garage',
        ticks(['h1w_cavity_brick', 'h1rt_pitched', 'h1rc_concrete_tiles', 'h1f_concrete']),
      ).join('\n');
      expect(out, contains('Walls: The garage is constructed of cavity brick'));
      expect(out, contains('Roof: The roof is of pitched construction'));
      expect(out, contains('Garage Floor: The garage floor is constructed of concrete'));
    });

    test('Drainage: chamber, soil pipe and repairs print from their choices', () {
      final main = engine.buildPhrases(
        'activity_services_drainage',
        ticks(['g6cf_blockage', 'g6sl_front', 'cb_material_plastic_pipe', 'g6sv_roof_space']),
      ).join('\n');
      expect(main, contains('Inspection chamber is inspected: The inspection chamber cover(s) were lifted'));
      expect(main, contains('Soil and Vent Pipe: The soil and vent pipe is visible at the front'));
      expect(main, contains('Partially Visible:'));
      final repair = engine.buildPhrases(
        'activity_services_drainage_repair_chamber_cover',
        ticks(['g6cv_broken', 'g6cw_cracked', 'g6gu_partly_blocked']),
      ).join('\n');
      expect(repair, contains('Inspection Chamber Cover: The inspection chamber cover(s) are broken'));
      expect(repair, contains('Inspection Chamber Walls: The inspection chamber walls are cracked'));
      expect(repair, contains('Gullies:'));
    });

    test('Water heating: cylinder location prints without the immersion box', () {
      final out = engine.buildPhrases(
        'activity_services_water_heating_gas_heating',
        ticks(['g5c_airing_cupboard']),
      ).join('\n');
      expect(out, contains('insulated cylinder located in the airing cupboard'));
    });

    test('G7 Common services: services without the Communal box print', () {
      final out = engine.buildPhrases(
        'activity_services_shared_services',
        ticks(['g7s_lifts', 'g7s_cleaning']),
      ).join('\n');
      expect(out, contains('Communal services and installations, including cleaning and lifts'));
    });

    test('nothing ticked still prints nothing', () {
      expect(engine.buildPhrases('activity_grounds_garage', const {}), isEmpty);
      expect(engine.buildPhrases('activity_services_drainage_repair_chamber_cover', const {}), isEmpty);
    });

    test('gate plus choices prints exactly as before (no duplicate)', () {
      final withGate = engine.buildPhrases(
        'activity_grounds_garage',
        ticks(['cb_h1_walls', 'h1w_cavity_brick']),
      );
      final withoutGate = engine.buildPhrases(
        'activity_grounds_garage',
        ticks(['h1w_cavity_brick']),
      );
      expect(withoutGate, withGate);
      expect(withGate.where((p) => p.startsWith('Walls:')).length, 1);
    });
  });

  group('A5 Windows description: no "and" between age and material', () {
    String desc(List<String> ids) => engine
        .buildPhrases('activity_outside_property_windows_aboutwindow', ticks(ids))
        .firstWhere((p) => p.startsWith('Description:'));

    test('client example', () {
      expect(desc(['e5t_replacement', 'e5t_pvcu']),
          startsWith('Description: The windows are formed of replacement PVCu framed units.'));
    });
    test('two materials still joined', () {
      expect(desc(['e5t_replacement', 'e5t_pvcu', 'e5t_timber']),
          startsWith('Description: The windows are formed of replacement PVCu and timber framed units.'));
    });
    test('age word alone or material alone unchanged', () {
      expect(desc(['e5t_original']), startsWith('Description: The windows are formed of original framed units.'));
      expect(desc(['e5t_pvcu']), startsWith('Description: The windows are formed of PVCu framed units.'));
    });
  });

  test('A6 Other Joinery: Description first, Inspected text is not the not-inspected text', () {
    final out = engine.buildPhrases(
      'activity_outside_property_other_joinery_and_finishes_main_screen',
      ticks(['e8m_timber', 'e8m_pvcu'], {
        'actv_condition': '1',
        'actv_decorations': 'Reasonable',
        'actv_joinery_condition': 'Reasonable',
      }),
    );
    final body = out.where((p) => !p.startsWith('Condition rating')).toList();
    expect(body.first, startsWith('Description: The external eaves-level joinery comprises timber and PVCu'));
    final order = ['Description:', 'Decorations:', 'Condition:', 'Inspected:']
        .map((l) => body.indexWhere((p) => p.startsWith(l)))
        .toList();
    expect(order.every((i) => i >= 0), isTrue, reason: '$body');
    expect(order, [...order]..sort());
    final joined = out.join('\n');
    expect(joined, isNot(contains('could not be inspected due to the height')));
    expect(RegExp('Inspected:').allMatches(joined).length, 1);
    // Not inspected still prints its own text.
    final ni = engine.buildPhrases(
      'activity_outside_property_other_joinery_finishes_not_inspected',
      {'cb_not_inspected': 'true'},
    ).join('\n');
    expect(ni, contains('Not Inspected: The usual external works at eaves level'));
  });

  test('D5 Porch joint defects talk about the porch; conservatory unchanged', () {
    final porch = engine.buildPhrases(
      'activity_outside_property_porch_open_to_building__open_to_building',
      {'cb_not_inspected': 'true'},
    ).join('\n');
    expect(porch, contains('junction between the porch and the main building'));
    expect(porch, isNot(contains('conservatory')));
    expect(phraseTexts['{E_CONSERVATORY_PORCHES}::{E7_C_JOINT_DEFECTS}'],
        contains('junction between the conservatory and the main building'));
  });

  group('D6 Poor condition and Unstable structure are separate', () {
    const cPoor = 'activity_outside_property_porch_poor_condition';
    const pPoor = 'activity_outside_property_porch_poor_condition__poor_condition';
    const cUnst = 'activity_outside_property_porch_unstable_structure';
    const pUnst = 'activity_outside_property_porch_unstable_structure__unstable_structure';

    test('Poor condition prints the poor-condition text', () {
      expect(engine.buildPhrases(pPoor, {'cb_e7_poor_condition': 'true'}).join(' '),
          startsWith('Porches that are in poor condition or in disrepair will require comprehensive repair.'));
      expect(engine.buildPhrases(cPoor, {'cb_e7_poor_condition': 'true'}).join(' '),
          startsWith('Conservatories that are in poor condition or in disrepair'));
    });

    test('Unstable structure has its own screen and text (client wording)', () {
      expect(engine.buildPhrases(pUnst, {'cb_e7_unstable': 'true'}).join(' '),
          startsWith('Unstable Structure: Evidence of movement, distortion, or deflection was observed.'));
      expect(engine.buildPhrases(cUnst, {'cb_e7_unstable': 'true'}).join(' '),
          startsWith('Unstable Structure: Evidence of movement, distortion, or deflection was observed.'));
    });

    test('surveys saved before the change keep their Unstable text', () {
      expect(engine.buildPhrases(pPoor, {'cb_not_inspected': 'true'}).join(' '),
          startsWith('Unstable Structure:'));
    });

    test('tree: Unstable structure tile comes right after Poor condition', () {
      final tree = jsonDecode(File('assets/property_inspection/inspection_tree.json').readAsStringSync())
          as Map<String, dynamic>;
      final ids = [
        for (final s in tree['sections'] as List)
          for (final n in (s as Map)['nodes'] as List) (n as Map)['id'] as String,
      ];
      expect(ids.indexOf(cUnst), ids.indexOf(cPoor) + 1);
      expect(ids.indexOf(pUnst), ids.indexOf(pPoor) + 1);
    });
  });

  test('D12 Water: stopcock asked once (Main Water), and it prints', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final nodes = {
      for (final s in tree.sections)
        for (final n in s.nodes) n.id: n,
    };
    final water = sanitizeInspectionFieldsForScreen(
      'activity_services_water_main_screen',
      nodes['activity_services_water_main_screen']!.fields,
    ).map((f) => f.id).toList();
    expect(water, ['android_material_design_spinner4', 'ar_etNote']);
    final out = engine.buildPhrases('activity_services_water_main_water', {
      'actv_g3_stopcock': 'Stopcock found',
      'g3s_under_the_kitchen_sink': 'true',
    }).join(' ');
    expect(out, contains('located under the kitchen sink'));
  });

  test('A3 a group page is titled with the group (Carport), top level with the section', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final nodeMap = {
      for (final s in tree.sections)
        for (final n in s.nodes) n.id: n,
    };
    expect(
      inspectionGroupPageTitle(sectionKey: 'E', parentNodeId: 'group_carport_35', nodeMap: nodeMap),
      'Carport',
    );
    expect(
      inspectionGroupPageTitle(sectionKey: 'E', parentNodeId: null, nodeMap: nodeMap),
      'Outside the Property',
    );
    expect(
      inspectionGroupPageTitle(sectionKey: 'E', parentNodeId: 'no_such_node', nodeMap: nodeMap),
      'Outside the Property',
    );
  });

  test('D13 Heating: one Heating screen with the About Heating content, no extra header', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final g = tree.sections.firstWhere((s) => s.key == 'G').nodes;
    final under = g.where((n) => n.parentId == 'group_g4_heating_92').toList();
    expect(under.map((n) => n.title), containsAll(['Heating', 'Repairs']));
    expect(g.any((n) => n.id == 'group_heating_101'), isFalse);
    expect(g.any((n) => n.title == 'About Heating System'), isFalse);
    final heating = g.firstWhere((n) => n.id == 'activity_services_heating_about_heating');
    expect(heating.title, 'Heating');
    expect(heating.parentId, 'group_g4_heating_92');
    final rating = g.firstWhere((n) => n.id == 'activity_services_heating_main_screen');
    expect(rating.parentId, 'group_g4_heating_92');
    expect(rating.inlinePosition, 'header');
  });

  test('D1 D4 D8 D10 renamed tiles and labels', () {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final nodes = {
      for (final s in tree.sections)
        for (final n in s.nodes) n.id: n,
    };
    String label(String screen, String field) =>
        nodes[screen]!.fields.firstWhere((f) => f.id == field).label;
    expect(nodes['activity_property_private_road']!.title, 'Road');
    expect(nodes['activity_grounds_other_private_road']!.title, 'Private Road'); // H2: really a private road
    expect(nodes['activity_outside_property_porch_open_to_building']!.title, 'Building joint defects');
    expect(nodes['activity_outside_property_porch_open_to_building__open_to_building']!.title, 'Building joint defects');
    final slope = nodes.values
        .expand((n) => n.fields)
        .firstWhere((f) => f.id == 'actv_j2_slope');
    expect(slope.label, 'Slope Gradient'); // client file 6 (13 Nov 2026): no (J2 ...)
    expect(label('activity_in_side_property_wap_removed_wall', 'actv_ia_outcome'), 'Condition');
  });

  test('A8 Garden condition talks about the garden, not the garage', () {
    final out = engine.buildPhrases(
      'activity_grounds_other_front_garden',
      {'actv_h2_garden_cond': 'Reasonable'},
    ).join('\n');
    expect(out, contains('Condition: Where visible, the garden appears in reasonable condition.'));
    expect(out, isNot(contains('garage')));
    // The garage screen keeps its own garage sentence.
    final garage = engine.buildPhrases('activity_grounds_garage', {'actv_condition': 'Reasonable'}).join('\n');
    expect(garage, contains('the garage appears to be in reasonable condition'));
  });
}
