import 'models/inspection_models.dart';

/// Section names as the app shows them.
String inspectionSectionTitle(String key) => switch (key) {
      'A' => 'About Inspection',
      'D' => 'About the Property',
      'E' => 'Outside the Property',
      'F' => 'Inside the Property',
      'G' => 'Services',
      'H' => 'Grounds',
      'I' => 'Issues for Legal Advisers',
      'J' => 'Risks',
      'K' => 'Floor/Site Plan Sketches',
      'R' => 'Room Details',
      'O' => 'Overall Opinion',
      _ => 'Section $key',
    };

final _legacyPrefix = RegExp(r'^\s*[A-Za-z]\d+\s+');

/// Where the surveyor is, for example
/// ['Outside the Property', 'Porches', 'Roof'] (client edit list, 2 Nov 2026).
List<String> inspectionBreadcrumb({
  required String sectionKey,
  required String nodeId,
  required Map<String, InspectionNodeDefinition> nodeMap,
}) {
  final titles = <String>[];
  final seen = <String>{};
  String? id = nodeId;
  while (id != null && seen.add(id)) {
    final node = nodeMap[id];
    if (node == null) break;
    titles.insert(0, node.title.replaceFirst(_legacyPrefix, '').trim());
    id = node.parentId;
  }
  return [inspectionSectionTitle(sectionKey), ...titles];
}
