import '../../../core/database/app_database.dart';

/// Whether a group (e.g. "Ground", "Construction", "Roof Covering") shows the
/// completed tick.
///
/// Many screens inside a group do not apply to a given property (no communal
/// garden, no gated community, no parapet wall), so "every screen completed"
/// never ticks. Client review (1 Nov 2026): a group is complete when at least
/// one of its screens is complete and none of the screens the surveyor has
/// touched is still open. Untouched screens never block.
bool isGroupComplete(String groupId, List<InspectionV2Screen> nodes) {
  final byParent = <String, List<InspectionV2Screen>>{};
  for (final n in nodes) {
    byParent.putIfAbsent(n.parentId ?? '', () => []).add(n);
  }
  var anyDone = false;
  final stack = <String>[groupId];
  while (stack.isNotEmpty) {
    for (final child in byParent[stack.removeLast()] ?? const []) {
      if (child.nodeType == 'group') {
        stack.add(child.screenId);
        continue;
      }
      if (child.isCompleted) {
        anyDone = true;
        continue;
      }
      final touched = child.updatedAt != null ||
          child.phraseOutput != null ||
          child.userNote != null;
      if (touched) return false;
    }
  }
  return anyDone;
}
