/// Paragraph breaks the client marked on the report (edit list, 2 Nov 2026).
///
/// Only the elements he named are affected. Inside them every labelled item
/// ("Condition:", "No repair required:", "Painted Walls:") starts a new
/// paragraph, including a second label inside one approved sentence. The approved
/// phrase bank is not changed; this runs on the finished text of the element.
library;

import 'pdf_shared_utils.dart';

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

List<String> applyClientParagraphRules(
  String groupId,
  List<String> phrases, {
  List<String> basement = const [],
}) {
  if (groupId == _insideOtherGroup) return _cellarParagraphs(phrases, basement);
  if (!clientParagraphGroups.contains(groupId)) return phrases;
  final items = [
    for (final p in phrases)
      for (final item in p.split(_labelStart)) ..._splitRating(item),
  ];
  return groupId == _chimneyGroup ? _chimneyParagraphs(items) : items;
}

/// An element's condition rating sits directly under its heading (client, 3 Nov
/// 2026). The rating's fixed explanation, when it has one, stays right below it.
List<String> conditionRatingFirst(
  List<String> phrases,
  Set<String> explanations,
) {
  final top = <String>[];
  final rest = <String>[];
  for (var i = 0; i < phrases.length; i++) {
    if (!PdfSharedUtils.conditionRatingLine.hasMatch(phrases[i].trim())) {
      rest.add(phrases[i]);
      continue;
    }
    top.add(phrases[i]);
    // A note with no paragraph of its own can follow the explanation in one line.
    if (i + 1 < phrases.length &&
        explanations.any(phrases[i + 1].trimLeft().startsWith)) {
      top.add(phrases[++i]);
    }
  }
  return top.isEmpty ? phrases : [...top, ...rest];
}

// Cellar and Basement are two elements (client, 11 Nov 2026): each has his heading, then
// his paragraphs in his order. Basement follows Cellar.
const _insideOtherGroup = 'group_f9_other_81';
const _cellarHeading = '[[SUBHEADING]] Cellar';
const _basementHeading = '[[SUBHEADING]] Basement';
const _basementNotInspectedBank = 'Basement Not inspected: ';
const _basementConditionStart = 'Condition: Where visible, the basement appears';
const _cellarNotInspectedBank = 'Cellar/Basement Not inspected: ';
const _cellarConditionStart = 'Condition: Where visible, the cellar appears';
const _noDefectsLabel = ' No defects noted: ';
const _generalMaintenanceStart = 'General Maintenance: Ancillary internal areas';
const _cellarStarts = <String>[
  'Not inspected: The property has a cellar',
  'Walls: The property incorporates a cellar',
  'Floor: The floor is constructed of',
  _cellarConditionStart,
  'No defects noted: No significant defects requiring immediate attention were identified unless otherwise stated below. Routine maintenance is recommended.',
  'Not in use: The property has a cellar',
  'In use: The cellar or basement',
  'Unsuitable: The cellar or basement',
  'Flooded: The cellar or basement',
  'Damp: Dampness was noted on the',
  'Waterproofing failure: The extent of dampness',
  'Timber decay: Decay was noted',
];

/// The paragraphs of one element: the bank's label on the not-inspected sentence becomes
/// "Not inspected:", and the Condition sentence gives "No defects noted:" its own paragraph.
List<String> _elementItems(
  List<String> phrases,
  String notInspectedBank,
  String conditionStart,
) {
  final items = <String>[];
  for (final raw in phrases) {
    var phrase = raw;
    if (phrase.startsWith(notInspectedBank)) {
      phrase = 'Not inspected: ${phrase.substring(notInspectedBank.length)}';
    }
    final split =
        phrase.startsWith(conditionStart) ? phrase.indexOf(_noDefectsLabel) : -1;
    if (split > 0) {
      items
        ..add(phrase.substring(0, split))
        ..add(phrase.substring(split + 1));
    } else {
      items.add(phrase);
    }
  }
  return items;
}

List<String> _cellarParagraphs(List<String> phrases, List<String> basement) {
  final items =
      _elementItems(phrases, _cellarNotInspectedBank, _cellarConditionStart);
  final basementItems =
      _elementItems(basement, _basementNotInspectedBank, _basementConditionStart);
  final basementBlock = basementItems.isEmpty
      ? const <String>[]
      : [_basementHeading, ...basementItems];

  bool isCellar(String p) => _cellarStarts.any(p.startsWith);
  final first = items.indexWhere(isCellar);
  final general = items.indexWhere((p) => p.startsWith(_generalMaintenanceStart));
  if (first < 0) {
    if (basementBlock.isEmpty) return items;
    // No Cellar text: Basement goes before General Maintenance, or at the end.
    final at = general >= 0 ? general : items.length;
    return [...items.sublist(0, at), ...basementBlock, ...items.sublist(at)];
  }
  final last = items.lastIndexWhere(isCellar);

  final out = <String>[
    for (var i = 0; i < first; i++)
      if (i != general) items[i],
    _cellarHeading,
    for (var i = first; i <= last; i++)
      if (i != general) items[i],
    ...basementBlock,
    if (general >= 0) items[general],
    for (var i = last + 1; i < items.length; i++)
      if (i != general) items[i],
  ];
  return out;
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
