/// Paragraph breaks the client marked on the report (edit list, 2 Nov 2026).
///
/// Only the elements he named are affected. Inside them every labelled item
/// ("Condition:", "No repair required:", "Painted Walls:") starts a new
/// paragraph, including a second label inside one approved sentence. The approved
/// phrase bank is not changed; this runs on the finished text of the element.
library;

const _chimneyGroup = 'group_e1_chimney_5';

const clientParagraphGroups = <String>{
  _chimneyGroup,
  'group_e3_rain_water_goods_13',
  'group_e4_main_walls_15',
  'group_e5_windows_20',
  'group_e7_conservatory_and_porches_26',
  'group_e8_other_joinery_and_finishes_31',
};

final _labelStart =
    RegExp(r"(?<=[.!?)])\s+(?=[A-Z][A-Za-z0-9&/'() -]{0,48}:\s)");

List<String> applyClientParagraphRules(String groupId, List<String> phrases) {
  if (!clientParagraphGroups.contains(groupId)) return phrases;
  final items = [
    for (final p in phrases)
      for (final item in p.split(_labelStart)) ..._splitRating(item),
  ];
  return groupId == _chimneyGroup ? _chimneyParagraphs(items) : items;
}

// "Condition rating is: 1." stands alone (it prints bold), its explanation follows.
final _ratingThenText = RegExp(r'^(Condition rating is: [^.]+\.)\s+(.+)$', dotAll: true);

List<String> _splitRating(String item) {
  final match = _ratingThenText.firstMatch(item);
  return match == null ? [item] : [match.group(1)!, match.group(2)!];
}

// Chimney Description reads as one paragraph without the inner titles, and the
// flashing and flaunching condition sentences stay with the item they describe.
final _descriptionTitle = RegExp(r'^(Pots|Number|Location): ');
final _waterproofingCondition =
    RegExp(r'^Condition: (?=Where visible, the (flashings|flaunching) )');

List<String> _chimneyParagraphs(List<String> items) {
  final out = <String>[];
  int? descriptionAt;
  for (final raw in items) {
    final item = raw.replaceAll('stacks(s)', 'stack(s)');

    final isDescription = item.startsWith('Description: ');
    if (isDescription || _descriptionTitle.hasMatch(item)) {
      final sentence = item.replaceFirst(_descriptionTitle, '');
      if (descriptionAt == null) {
        descriptionAt = out.length;
        out.add(sentence);
      } else {
        out[descriptionAt] = _joinDescription(out[descriptionAt], sentence);
      }
      continue;
    }

    if (_waterproofingCondition.hasMatch(item)) {
      final sentence = item.replaceFirst(_waterproofingCondition, '');
      final parent = out.isEmpty ? '' : out.last;
      if (parent.startsWith('Flashings: ') || parent.startsWith('Flaunching: ')) {
        out.last = '$parent $sentence';
      } else {
        out.add(sentence);
      }
      continue;
    }

    out.add(item);
  }
  return out;
}

/// "The property has two stack(s)" and "The chimney stack(s) are located ..."
/// become one sentence, as in the client's corrected text.
String _joinDescription(String current, String next) {
  const located = 'The chimney stack(s) are located';
  if (next.startsWith(located) && current.endsWith('stack(s).')) {
    final number = current.substring(0, current.length - 1);
    return '$number, and the${next.substring(3)}';
  }
  return '$current $next';
}
