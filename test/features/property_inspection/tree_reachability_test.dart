// Whole-tree walk (1 Nov 2026 sweep): start at every section's top page and
// follow the tiles exactly as InspectionSectionPage shows them
// (visibleSectionNodes), so screens a surveyor can never open and pages that
// show "No screens yet." are caught for ALL sections, not only where the
// client happened to look.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/database/app_database.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/domain/section_visibility.dart';

/// Screens opened by ticking a checkbox on Ground > Area (legacy flow in
/// InspectionScreenPage), not by a tile.
const _openedFromAreaCheckboxes = {'activity_garden', 'activity_parking'};

void main() {
  final tree = InspectionTreePayload.fromJson(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final nodeMap = <String, InspectionNodeDefinition>{
    for (final s in tree.sections)
      for (final n in s.nodes) n.id: n,
  };
  final sectionOf = <String, String>{
    for (final s in tree.sections)
      for (final n in s.nodes) n.id: s.key,
  };
  List<InspectionV2Screen> rowsFor(InspectionSectionDefinition s) => [
        for (var i = 0; i < s.nodes.length; i++)
          InspectionV2Screen(
            id: 's_${s.nodes[i].id}',
            surveyId: 's',
            sectionKey: s.key,
            screenId: s.nodes[i].id,
            title: s.nodes[i].title,
            nodeType: s.nodes[i].type.name,
            parentId: s.nodes[i].parentId,
            displayOrder: i,
            isCompleted: false,
            phraseEditedManually: false,
            createdAt: DateTime(2026),
          ),
      ];

  String pathOf(String id) {
    final parts = <String>[];
    String? cur = id;
    while (cur != null && nodeMap[cur] != null) {
      parts.insert(0, nodeMap[cur]!.title);
      cur = nodeMap[cur]!.parentId;
    }
    return '${sectionOf[id]}: ${parts.join(' > ')}';
  }

  final reached = <String>{};
  final emptyPages = <String>[];
  for (final section in tree.sections) {
    final rows = rowsFor(section);
    void visit(String? parentId) {
      final tiles = visibleSectionNodes(
        sectionKey: section.key,
        parentNodeId: parentId,
        nodes: rows,
        nodeMap: nodeMap,
      );
      final headers = parentId == null
          ? const <InspectionNodeDefinition>[]
          : section.nodes
              .where((n) => n.parentId == parentId && n.inlinePosition == 'header')
              .toList();
      for (final h in headers) {
        reached.add(h.id);
      }
      if (parentId != null && tiles.isEmpty && headers.isEmpty) {
        emptyPages.add(pathOf(parentId));
      }
      for (final t in tiles) {
        reached.add(t.screenId);
        if (t.nodeType == 'group') visit(t.screenId);
        if (t.screenId == 'activity_property_ground_area') {
          reached.addAll(_openedFromAreaCheckboxes);
        }
      }
    }

    visit(null);
  }

  final unreachableScreens = [
    for (final s in tree.sections)
      for (final n in s.nodes)
        if (n.type == InspectionNodeType.screen && !reached.contains(n.id)) pathOf(n.id),
  ];

  test('every screen can be opened, except the deliberately hidden ones', () {
    // Legacy parity (see section_visibility.dart): Carport, Roof Terrace and
    // Balcony do not offer "Wall Construction".
    expect(
      unreachableScreens,
      unorderedEquals([
        'E: E9 Other Outside Property > Other Area > Other External Area > Carport > Wall Construction',
        'E: E9 Other Outside Property > Other Area > Other External Area > Roof Terrace > Wall Construction',
        'E: E9 Other Outside Property > Other Area > Other External Area > Balcony > Wall Construction',
      ]),
    );
  });

  test('no page opens blank ("No screens yet.")', () {
    expect(emptyPages, isEmpty);
  });

  test('every "field=A|B" style condition names fields that exist on the screen', () {
    // The app splits conditions on "|" first, so "status=A|B" reads "B" as a
    // field name and hides the follow-up boxes when B is chosen.
    final broken = <String>[];
    for (final n in nodeMap.values) {
      final ids = {for (final f in n.fields) f.id};
      for (final f in n.fields) {
        final expr = f.conditionalOn;
        if (expr == null || expr.isEmpty) continue;
        for (final token in expr.split(RegExp(r'[|&]'))) {
          final key = token.trim().replaceFirst('!', '').split('=').first.trim();
          if (key.isNotEmpty && !ids.contains(key)) broken.add('${n.id}/${f.id}: $expr');
        }
      }
    }
    expect(broken, isEmpty);
  });
}
