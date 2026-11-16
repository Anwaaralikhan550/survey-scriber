import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/domain/report_blocks_mapper.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: '54 Gas Lane',
      generatedAt: DateTime(2026, 11, 16),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: '54 Gas Lane'),
      sections: const [
        ReportSection(
          key: 'E',
          title: 'Outside Property',
          description: '',
          displayOrder: 0,
          screens: [
            ReportScreen(
              screenId: 'roof',
              title: 'Roof',
              fields: [
                ReportField(fieldId: 'actv_condition_rating', label: 'Condition Rating', type: ReportFieldType.dropdown, displayValue: '2', rawValue: '2', options: ['1', '2', '3']),
                ReportField(fieldId: 'f2', label: 'Covering', type: ReportFieldType.dropdown, displayValue: 'Tiles', rawValue: 'tiles'),
              ],
              phrases: [
                'The main roof is covered with concrete tiles.',
                'Condition rating is: 2. Some slipped tiles were seen.',
                'The chimney is brick.',
              ],
              userNote: 'Check the rear slope again.',
            ),
            ReportScreen(screenId: 'empty', title: 'Nothing here', fields: [], phrases: []),
          ],
        ),
      ],
      accommodationSchedule: const [
        AccommodationScheduleRow(floor: 'Ground', livingRooms: '2', kitchens: '1'),
        AccommodationScheduleRow(floor: 'First', bedrooms: '3', bathOrShowerRooms: '1'),
      ],
    );

void main() {
  group('toSections', () {
    final sections = ReportBlocksMapper.toSections(_doc());

    test('one cloud section per screen that has content, plus the accommodation table', () {
      expect(sections.map((s) => s['key']), ['E/roof', 'ACCOMMODATION']);
      expect(sections[0]['title'], 'Outside Property / Roof');
      expect(sections[1]['title'], 'Accommodation');
    });

    test('phrases become paragraph blocks, the rating line a required rating block, the note a note block', () {
      final blocks = (sections[0]['blocks'] as List).cast<Map<String, dynamic>>();
      expect(blocks.map((b) => [b['type'], b['role']]), [
        ['paragraph', 'phrase'],
        ['rating', 'rating'],
        ['paragraph', 'phrase'],
        ['paragraph', 'note'],
      ]);
      expect(blocks[1]['rating'], '2');
      expect(blocks[1]['required'], true);
      expect(blocks[1]['text'], 'Some slipped tiles were seen.');
      expect(blocks[3]['text'], 'Check the rear slope again.');
    });

    test('ids are stable UUIDs: the same report gives the same ids every time', () {
      final again = ReportBlocksMapper.toSections(_doc());
      expect(again, sections);
      final ids = <String>[
        for (final s in sections) s['id'] as String,
        for (final s in sections) for (final b in (s['blocks'] as List)) (b as Map)['id'] as String,
      ];
      expect(ids.toSet().length, ids.length);
      final uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(ids.every(uuid.hasMatch), isTrue);
    });

    test('the accommodation table keeps every column and row', () {
      final table = ((sections[1]['blocks'] as List).first as Map)['table'] as Map;
      expect(table['headers'], ReportBlocksMapper.scheduleHeaders);
      expect(table['rows'], [
        ['Ground', '2', '', '', '', '1', '', '', ''],
        ['First', '', '3', '1', '', '', '', '', ''],
      ]);
    });

    test('a long screen id is cut so the key stays within the server limit', () {
      expect(ReportBlocksMapper.sectionKeyFor('E', 'x' * 200).length, 100);
    });
  });

  group('applyEdits', () {
    List<Map<String, dynamic>> edited() => ReportBlocksMapper.toSections(_doc());

    test('unchanged blocks give back the same report text', () {
      final doc = _doc();
      final back = ReportBlocksMapper.applyEdits(doc, edited());
      final a = doc.sections.first.screens.first;
      final b = back.sections.first.screens.first;
      expect(b.phrases, a.phrases);
      expect(b.userNote, a.userNote);
      expect(back.accommodationSchedule.map((r) => r.floor), ['Ground', 'First']);
    });

    test('edited, added, deleted and re-ordered paragraphs, a new rating and note reach the report', () {
      final e = edited();
      final blocks = (e[0]['blocks'] as List).cast<Map<String, dynamic>>();
      blocks[0]['text'] = 'The main roof is covered with natural slate.';
      blocks[1]['rating'] = '3';
      blocks.removeAt(2); // delete the chimney paragraph
      blocks.insert(1, {'id': 'a1111111-1111-4111-8111-111111111111', 'type': 'paragraph', 'text': 'Added in the browser.'});
      blocks.last['text'] = 'Rear slope checked.';
      final back = ReportBlocksMapper.applyEdits(_doc(), e);
      final s = back.sections.first.screens.first;
      expect(s.phrases, [
        'The main roof is covered with natural slate.',
        'Added in the browser.',
        'Condition rating is: 3. Some slipped tiles were seen.',
      ]);
      expect(s.userNote, 'Rear slope checked.');
      expect(s.fields.firstWhere((f) => f.label == 'Condition Rating').displayValue, '3');
      expect(s.fields.firstWhere((f) => f.label == 'Covering').displayValue, 'Tiles');
    });

    test('empty paragraphs are dropped and an emptied note clears the note', () {
      final e = edited();
      final blocks = (e[0]['blocks'] as List).cast<Map<String, dynamic>>();
      blocks[0]['text'] = '   ';
      blocks.last['text'] = '';
      final s = ReportBlocksMapper.applyEdits(_doc(), e).sections.first.screens.first;
      expect(s.phrases.first, startsWith('Condition rating is: 2.'));
      expect(s.userNote, '');
    });

    test('a screen that was not edited, and sections the editor does not know, stay untouched', () {
      final e = edited();
      e.add({'id': 'b2222222-2222-4222-8222-222222222222', 'key': 'Z/unknown', 'title': 'Unknown', 'blocks': []});
      final back = ReportBlocksMapper.applyEdits(_doc(), e);
      expect(back.sections.first.screens.length, 2);
      expect(back.sections.first.screens[1].screenId, 'empty');
    });

    test('accommodation table edits come back as schedule rows', () {
      final e = edited();
      final table = ((e[1]['blocks'] as List).first as Map)['table'] as Map;
      ((table['rows'] as List)[0] as List)[2] = '9';
      (table['rows'] as List).add(['Second', '', '2', '', '', '', '', '', '1 Study']);
      final back = ReportBlocksMapper.applyEdits(_doc(), e);
      expect(back.accommodationSchedule.map((r) => r.floor), ['Ground', 'First', 'Second']);
      expect(back.accommodationSchedule.first.bedrooms, '9');
      expect(back.accommodationSchedule.last.otherRooms, '1 Study');
    });

    test('a rating of NI is kept', () {
      final e = edited();
      ((e[0]['blocks'] as List)[1] as Map)['rating'] = 'NI';
      final s = ReportBlocksMapper.applyEdits(_doc(), e).sections.first.screens.first;
      expect(s.phrases[1], startsWith('Condition rating is: NI.'));
    });
  });
}
