// Every screen through sanitizeInspectionFieldsForScreen (1 Nov 2026 sweep).
//
// The Chrome sweep found Inside > Walls and Partitions > Removed Wall opening
// with "No fields defined for this screen yet.": a hard-coded override still
// named the screen's old field ids. The same override function feeds the report
// builder, so a stale override also drops text from the report. This checks all
// screens: none may come out blank, and no field that a PDF-verbatim rule reads
// may be hidden by an override.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

void main() {
  final tree = InspectionTreePayload.fromJson(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final screens = [
    for (final s in tree.sections)
      for (final n in s.nodes)
        if (n.type == InspectionNodeType.screen) n,
  ];

  // Fields each screen's PDF-verbatim rules read.
  final specFields = <String, Set<String>>{};
  for (final rule in kVerbatimRules) {
    final ids = specFields.putIfAbsent(rule.screen, () => <String>{});
    for (final t in rule.tokens) {
      ids.addAll(t.options.keys);
      for (final id in [t.otherCheckbox, t.otherText, t.dropdown, t.text]) {
        if (id != null) ids.add(id);
      }
    }
    if (rule.whenField != null) ids.add(rule.whenField!);
    for (final pair in rule.whenAny) {
      ids.add(pair.first);
    }
  }

  final blank = <String>[];
  final hidden = <String>[];
  for (final n in screens) {
    final answerable = n.fields.where((f) => f.type != InspectionFieldType.label).toList();
    final shown = sanitizeInspectionFieldsForScreen(n.id, n.fields);
    final shownIds = {for (final f in shown) f.id};
    if (answerable.isNotEmpty && !shown.any((f) => f.type != InspectionFieldType.label)) {
      blank.add('${n.id} "${n.title}"');
    }
    final treeIds = {for (final f in n.fields) f.id};
    final dropped = (specFields[n.id] ?? const <String>{})
        .where((id) => treeIds.contains(id) && !shownIds.contains(id))
        .toList()
      ..sort();
    if (dropped.isNotEmpty) hidden.add('${n.id} "${n.title}": $dropped');
  }

  test('no screen comes out blank', () {
    expect(blank, isEmpty);
  });

  test('no field read by a PDF-verbatim rule is hidden by a screen override', () {
    expect(hidden, isEmpty);
  });
}
