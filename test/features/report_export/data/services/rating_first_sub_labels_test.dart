// Client feedback on the sample report, 3 Nov 2026: the condition rating sits at
// the top of every element, and the sub-headings inside an element print bold.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/client_paragraph_rules.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_shared_utils.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.docs);
  final String docs;
  @override
  Future<String?> getApplicationDocumentsPath() async => docs;
}

List<String> _labels(String text) => [
      for (final r in PdfSharedUtils.subLabelRanges(text))
        text.substring(r.start, r.end),
    ];

Map<String, String> _bank() => (jsonDecode(
            File('assets/property_inspection/phrase_texts.json')
                .readAsStringSync()) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v?.toString() ?? ''));

/// Fills every screen and picks [rating] on every condition rating dropdown.
ReportDocument _report(String rating) {
  final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync());
  final answers = <String, Map<String, String>>{};
  final states = <String, bool>{};
  for (final section in tree.sections) {
    for (final node in section.nodes) {
      if (node.type != InspectionNodeType.screen) continue;
      final out = <String, String>{};
      for (final f in node.fields) {
        switch (f.type) {
          case InspectionFieldType.checkbox:
            out[f.id] = 'true';
          case InspectionFieldType.dropdown:
            final options = f.options ?? const <String>[];
            if (options.isEmpty) break;
            out[f.id] = f.label.toLowerCase().contains('condition rating') &&
                    options.contains(rating)
                ? rating
                : options.first;
          case InspectionFieldType.number:
            out[f.id] = '2';
          case InspectionFieldType.text:
            out[f.id] = 'Surveyor note';
          default:
            break;
        }
      }
      answers[node.id] = out;
      states[node.id] = true;
    }
  }
  return ReportBuilder(
    inspectionPhraseEngine: InspectionPhraseEngine(_bank()),
    valuationPhraseEngine: null,
  ).build(
    V2RawReportData(
      survey: Survey(
        id: 's1',
        title: 'Inspection - ref-354',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 11, 3),
      ),
      tree: tree,
      allAnswers: answers,
      screenStates: states,
      photoFilePaths: const [],
      signatureRows: const [],
    ),
    const ExportConfig(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('condition rating first', () {
    const explanation = 'The element(s) are performing their intended function.';

    test('rating and its explanation move up, everything else keeps its order', () {
      expect(
        conditionRatingFirst(
          [
            'Description: Brick.',
            'Condition rating is: 1.',
            explanation,
            'Surveyor note',
            'General maintenance: Keep clean.',
          ],
          {explanation},
        ),
        [
          'Condition rating is: 1.',
          explanation,
          'Description: Brick.',
          'Surveyor note',
          'General maintenance: Keep clean.',
        ],
      );
    });

    test('a note joined to the explanation moves with it', () {
      expect(
        conditionRatingFirst(
          ['Description: Brick.', 'Condition rating is: 1.', '$explanation My note'],
          {explanation},
        ),
        ['Condition rating is: 1.', '$explanation My note', 'Description: Brick.'],
      );
    });

    test('a note after the rating is not treated as its explanation', () {
      expect(
        conditionRatingFirst(
          ['Description: Brick.', 'Condition rating is: 2.', 'Surveyor note'],
          {explanation},
        ),
        ['Condition rating is: 2.', 'Description: Brick.', 'Surveyor note'],
      );
    });

    test('the rating goes above the first sub-heading', () {
      expect(
        conditionRatingFirst(
          ['[[SUBHEADING]] Garage', 'Condition rating is: 1.', 'Surveyor note'],
          const {},
        ),
        ['Condition rating is: 1.', '[[SUBHEADING]] Garage', 'Surveyor note'],
      );
    });

    test('an element with no rating is left alone', () {
      final phrases = ['Description: Brick.', 'Condition ratings assume this.'];
      expect(conditionRatingFirst(phrases, const {}), same(phrases));
    });

    for (final rating in ['1', '2', '3']) {
      test('rating $rating: first line of each of the 28 elements, once', () {
        final doc = _report(rating);
        var rated = 0;
        for (final section in doc.sections) {
          for (final screen in section.screens) {
            final lines = [
              for (final (i, p) in screen.phrases.indexed)
                if (PdfSharedUtils.conditionRatingLine.hasMatch(p.trim())) i,
            ];
            if (lines.isEmpty) continue;
            rated++;
            expect(lines, [0], reason: screen.title);
          }
        }
        expect(rated, 28);
      });
    }

    test('the five elements with an explanation keep it right below the rating', () {
      final bank = _bank();
      for (final rating in ['1', '2', '3']) {
        final explanations = {
          for (final e in bank.entries)
            if (e.key.endsWith('::{CONDITION_RATING_$rating}')) e.value.trim(),
        };
        expect(explanations, hasLength(1));
        final withExplanation = [
          for (final section in _report(rating).sections)
            for (final screen in section.screens)
              if (screen.phrases.length > 1 &&
                  screen.phrases[1].startsWith(explanations.single))
                screen.screenId,
        ];
        expect(
          withExplanation,
          unorderedEquals(const [
            'group_e1_chimney_5',
            'group_e2_roof_covering_9',
            'group_e3_rain_water_goods_13',
            'group_e4_main_walls_15',
            'group_e5_windows_20',
          ]),
        );
      }
    });
  });

  group('sub-heading labels', () {
    test('the client example from Windows', () {
      expect(_labels('Description: The windows are formed of timber.'),
          ['Description:']);
      expect(_labels('Glazing: The glazing comprises double glazing.'), ['Glazing:']);
      expect(_labels('No BS EN: No visible British Standard.'), ['No BS EN:']);
      expect(_labels('No defects noted: No significant defects.'),
          ['No defects noted:']);
    });

    test('a label followed by another label, or later in the paragraph', () {
      expect(_labels('Roof Velux Windows: Type: The property has roof windows.'),
          ['Roof Velux Windows:', 'Type:']);
      expect(
        _labels('Door operation: The doors opened. No defects noted: None were seen.'),
        ['Door operation:', 'No defects noted:'],
      );
    });

    test('a label with no colon in the approved text', () {
      expect(_labels('Defective Joinery One or more defects were observed, including: rot.'),
          ['Defective Joinery']);
      expect(_labels('Defective Operation One or more windows were found to: stick.'),
          ['Defective Operation']);
    });

    test('a Main Walls note running into General Maintenance leaves the note plain', () {
      expect(_labels('Surveyor note General Maintenance: Walls should be inspected.'),
          ['General Maintenance:']);
    });

    test('plain text and the rating line are not labels', () {
      for (final text in [
        'Condition rating is: 1.',
        'Surveyor note',
        'The inspection was limited by the following restrictions: stored items.',
        'The walls were inspected at 12:30 from the ground.',
        'Please check. Before committing to the purchase, you should: ask a solicitor.',
      ]) {
        expect(_labels(text), isEmpty, reason: text);
      }
    });

    test('every approved sentence outside About Inspection and About Property', () {
      final refused = <String>{};
      final accepted = <String>{};
      for (final entry in _bank().entries) {
        if (entry.key.startsWith('{A_') || entry.key.startsWith('{D_')) continue;
        final colon = RegExp(r'^([^:]{1,70}):\s').firstMatch(entry.value);
        if (colon == null) continue;
        // A heading filled in from the answers ({CS_ATTACHED_HEADING}) is checked below.
        if (colon.group(1)!.startsWith('{')) continue;
        final found = _labels(entry.value);
        if (found.isNotEmpty && found.first.startsWith(colon.group(1)!)) {
          accepted.add(colon.group(1)!);
        } else {
          refused.add(colon.group(1)!);
        }
      }
      expect(accepted, hasLength(greaterThan(400)));
      // The rating prints fully bold; the "Defective" sentences bold only their name.
      expect(refused, {
        'Condition rating is',
        'Defective Joinery One or more defects were observed, including',
        'Defective Operation One or more external doors were found to',
        'Defective Operation One or more windows were found to',
      });
    });

    test('only the home survey sections after About Property print bold labels', () {
      expect(PdfSharedUtils.printsSubLabels(true, 'A'), isFalse);
      expect(PdfSharedUtils.printsSubLabels(true, 'D'), isFalse);
      for (final key in ['E', 'F', 'G', 'H', 'I', 'J', 'K']) {
        expect(PdfSharedUtils.printsSubLabels(true, key), isTrue, reason: key);
      }
      expect(PdfSharedUtils.printsSubLabels(false, 'E'), isFalse);
    });
  });

  group('Word file', () {
    Future<String> xml(ReportType type, String sectionKey) async {
      PathProviderPlatform.instance =
          _Paths('E:/survey-scriber/tmp/valuation_export_app_documents');
      final doc = ReportDocument(
        reportType: type,
        title: 'Inspection - ref-354',
        generatedAt: DateTime(2026, 11, 3, 17, 40),
        surveyMeta: const SurveyMeta(surveyId: 's1', title: 'Inspection - ref-354'),
        sections: [
          ReportSection(
            key: sectionKey,
            title: 'Section',
            description: '',
            displayOrder: 0,
            screens: const [
              ReportScreen(
                screenId: 'group',
                title: 'Windows',
                fields: [],
                isMergedGroup: true,
                phrases: [
                  'Condition rating is: 1.',
                  'Glazing: The glazing is double & sealed.',
                  'Roof Velux Windows: Type: Timber. No defects noted: None.',
                ],
              ),
            ],
          ),
        ],
      );
      final result = await DocxGeneratorService(const ExportConfig()).generateDocx(doc);
      final file = ZipDecoder()
          .decodeBytes(result.bytes)
          .files
          .firstWhere((f) => f.name == 'word/document.xml');
      return utf8.decode(file.content as List<int>);
    }

    const bold = '<w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">Glazing:</w:t></w:r>';

    test('the label is a bold run and its sentence stays plain', () async {
      final out = await xml(ReportType.inspection, 'E');
      expect(out, contains(bold));
      expect(
        out,
        contains(
          '$bold<w:r><w:t xml:space="preserve"> </w:t></w:r>'
          '<w:r><w:t xml:space="preserve">The glazing is double &amp; sealed.</w:t></w:r>',
        ),
      );
    });

    test('Word keeps the spaces between labels and text', () async {
      final out = await xml(ReportType.inspection, 'E');
      final paragraph = RegExp(r'<w:p>((?:(?!</w:p>).)*Roof Velux(?:(?!</w:p>).)*)</w:p>')
          .firstMatch(out)!
          .group(1)!;
      final text = RegExp(r'<w:t[^>]*>([^<]*)</w:t>')
          .allMatches(paragraph)
          .map((m) => m.group(1))
          .join();
      expect(text, 'Roof Velux Windows: Type: Timber. No defects noted: None.');
    });

    test('About Inspection and the valuation report are unchanged', () async {
      for (final out in [
        await xml(ReportType.inspection, 'A'),
        await xml(ReportType.inspection, 'D'),
        await xml(ReportType.valuation, 'E'),
      ]) {
        expect(out, isNot(contains(bold)));
        expect(out, contains('Glazing: The glazing is double &amp; sealed.'));
      }
    });
  });
}
