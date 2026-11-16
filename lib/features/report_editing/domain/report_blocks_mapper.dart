import 'package:uuid/uuid.dart';

import '../../report_export/domain/models/report_document.dart';

/// Turns the phone's [ReportDocument] into the structured sections and blocks that the browser editor
/// works on (client spec v1.3, section 4), and puts edited blocks back into a document before PDF/Word
/// are generated. One cloud section per report screen, so a surveyor sees one element at a time.
///
/// Ids are derived from the survey id and the screen, so uploading the same report twice gives the same
/// section and block ids (edits made in the browser are never orphaned by a re-upload).
class ReportBlocksMapper {
  const ReportBlocksMapper._();

  static const _uuid = Uuid();
  static const scheduleKey = 'ACCOMMODATION';
  static const scheduleHeaders = <String>[
    'Floor',
    'Living',
    'Beds',
    'Bath/shower',
    'WC',
    'Kitchen',
    'Utility',
    'Conservatory',
    'Other',
  ];

  /// "Condition rating is: 2." with an optional explanation after it.
  static final _ratingPhrase = RegExp(
    r'^condition rating(?: is)?:?\s+(1|2|3|NI)\.?(?:\s+(.+))?$',
    caseSensitive: false,
    dotAll: true,
  );

  static String sectionKeyFor(String sectionKey, String screenId) {
    final key = '$sectionKey/$screenId';
    return key.length <= 100 ? key : key.substring(0, 100);
  }

  /// Sections and blocks as JSON, ready for `PUT /reports/:id/snapshot`.
  static List<Map<String, dynamic>> toSections(ReportDocument doc) {
    final ns = doc.surveyMeta.surveyId;
    final out = <Map<String, dynamic>>[];
    for (final section in doc.sections) {
      for (final screen in section.screens) {
        final blocks = <Map<String, dynamic>>[];
        final key = sectionKeyFor(section.key, screen.screenId);
        for (var i = 0; i < screen.phrases.length; i++) {
          final phrase = screen.phrases[i].trim();
          if (phrase.isEmpty) continue;
          final id = _uuid.v5(ns, 'blk:$key:$i');
          final rating = _ratingPhrase.firstMatch(phrase);
          if (rating != null) {
            blocks.add({
              'id': id,
              'type': 'rating',
              'role': 'rating',
              'required': true,
              'rating': rating.group(1)!.toUpperCase(),
              if ((rating.group(2) ?? '').trim().isNotEmpty) 'text': rating.group(2)!.trim(),
            });
          } else {
            blocks.add({'id': id, 'type': 'paragraph', 'role': 'phrase', 'text': phrase});
          }
        }
        final note = screen.userNote.trim();
        if (note.isNotEmpty) {
          blocks.add({'id': _uuid.v5(ns, 'blk:$key:note'), 'type': 'paragraph', 'role': 'note', 'text': note});
        }
        if (blocks.isEmpty) continue;
        final title = screen.title.trim().isEmpty || screen.title == section.title ? section.title : '${section.title} / ${screen.title}';
        out.add({
          'id': _uuid.v5(ns, 'sec:$key'),
          'key': key,
          'title': title.length <= 255 ? title : title.substring(0, 255),
          'blocks': blocks,
        });
      }
    }
    if (doc.accommodationSchedule.any((r) => r.hasAnyRooms)) {
      out.add({
        'id': _uuid.v5(ns, 'sec:$scheduleKey'),
        'key': scheduleKey,
        'title': 'Accommodation',
        'blocks': [
          {
            'id': _uuid.v5(ns, 'blk:$scheduleKey:table'),
            'type': 'table',
            'role': 'schedule',
            'required': true,
            'table': {
              'headers': scheduleHeaders,
              'rows': [
                for (final r in doc.accommodationSchedule)
                  [r.floor, r.livingRooms, r.bedrooms, r.bathOrShowerRooms, r.separateToilets, r.kitchens, r.utilityRooms, r.conservatories, r.otherRooms],
              ],
            },
          },
        ],
      });
    }
    return out;
  }

  /// The document with the browser's edits in it. Screens the editor does not know about stay as they are.
  static ReportDocument applyEdits(ReportDocument doc, List<Map<String, dynamic>> edited) {
    final byKey = {for (final s in edited) s['key'] as String: s};
    final sections = <ReportSection>[
      for (final section in doc.sections)
        ReportSection(
          key: section.key,
          title: section.title,
          description: section.description,
          displayOrder: section.displayOrder,
          screens: [
            for (final screen in section.screens)
              _applyToScreen(screen, byKey[sectionKeyFor(section.key, screen.screenId)]),
          ],
        ),
    ];
    var schedule = doc.accommodationSchedule;
    final table = _scheduleTable(byKey[scheduleKey]);
    if (table != null) {
      schedule = [
        for (final row in table)
          AccommodationScheduleRow(
            floor: _cell(row, 0),
            livingRooms: _cell(row, 1),
            bedrooms: _cell(row, 2),
            bathOrShowerRooms: _cell(row, 3),
            separateToilets: _cell(row, 4),
            kitchens: _cell(row, 5),
            utilityRooms: _cell(row, 6),
            conservatories: _cell(row, 7),
            otherRooms: _cell(row, 8),
          ),
      ];
    }
    return doc.copyWith(sections: sections, accommodationSchedule: schedule);
  }

  static ReportScreen _applyToScreen(ReportScreen screen, Map<String, dynamic>? edited) {
    if (edited == null) return screen;
    final phrases = <String>[];
    final notes = <String>[];
    String? rating;
    for (final raw in (edited['blocks'] as List? ?? const [])) {
      final b = raw as Map<String, dynamic>;
      final type = b['type'];
      if (type == 'rating') {
        rating = '${b['rating']}';
        final tail = (b['text'] as String? ?? '').trim();
        phrases.add('Condition rating is: $rating.${tail.isEmpty ? '' : ' $tail'}');
      } else if (type == 'paragraph') {
        final text = (b['text'] as String? ?? '').trim();
        if (text.isEmpty) continue;
        if (b['role'] == 'note') {
          notes.add(text);
        } else {
          phrases.add(text);
        }
      }
    }
    final fields = rating == null
        ? screen.fields
        : [
            for (final f in screen.fields)
              f.label.trim().toLowerCase() == 'condition rating'
                  ? ReportField(
                      fieldId: f.fieldId,
                      label: f.label,
                      type: f.type,
                      displayValue: rating,
                      rawValue: rating,
                      options: f.options,
                      isConditional: f.isConditional,
                    )
                  : f,
          ];
    return ReportScreen(
      screenId: screen.screenId,
      title: screen.title,
      fields: fields,
      phrases: phrases,
      userNote: notes.join('\n'),
      parentId: screen.parentId,
      isCompleted: screen.isCompleted,
      isMergedGroup: screen.isMergedGroup,
    );
  }

  static List<List<String>>? _scheduleTable(Map<String, dynamic>? section) {
    if (section == null) return null;
    for (final raw in (section['blocks'] as List? ?? const [])) {
      final b = raw as Map<String, dynamic>;
      if (b['type'] == 'table' && b['table'] is Map) {
        final rows = (b['table'] as Map)['rows'] as List? ?? const [];
        return [for (final r in rows) [for (final c in (r as List)) '$c']];
      }
    }
    return null;
  }

  static String _cell(List<String> row, int i) => i < row.length ? row[i] : '';
}
