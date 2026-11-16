// AT-13 (client spec v1.3 section 21), the phone half: once the owner has finalised, the PDF and Word reports are made by the
// existing report engine from the final synchronised content, and an earlier wording does not come back.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/report_editing/domain/report_blocks_mapper.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.docs);
  final String docs;
  @override
  Future<String?> getApplicationDocumentsPath() async => docs;
}

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';
const _original = 'The main roof is covered with concrete tiles.';

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
              ],
              phrases: [_original, 'Condition rating is: 2.'],
            ),
          ],
        ),
      ],
    );

/// What the cloud holds after a colleague edited the text and the owner finalised: the phone's sections with one paragraph changed.
List<Map<String, dynamic>> _finalSections(String text) {
  final sections = ReportBlocksMapper.toSections(_doc());
  final blocks = (sections.first['blocks'] as List).cast<Map<String, dynamic>>();
  blocks.firstWhere((b) => b['type'] == 'paragraph')['text'] = text;
  return sections;
}

String _wordXml(List<int> bytes) => utf8.decode(ZipDecoder().decodeBytes(bytes).findFile('word/document.xml')!.content as List<int>);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _Paths(Directory.systemTemp.createTempSync('final_export_').path);
  const config = ExportConfig(includeSignatures: false, includeRecommendations: false, includeAiNarrative: false);

  test('the Word report is made from the final content: the new wording is in, the old is out', () async {
    const finalText = 'The main roof is covered with clay tiles, as approved.';
    final finalDoc = ReportBlocksMapper.applyEdits(_doc(), _finalSections(finalText));
    final xml = _wordXml((await DocxGeneratorService(config).generateDocx(finalDoc)).bytes);
    expect(xml, contains(finalText));
    expect(xml, isNot(contains(_original)));
    expect(xml, contains('Condition rating is: 2'));
  });

  test('the PDF is made from the same final content by the same engine', () async {
    const finalText = 'The main roof is covered with clay tiles, as approved.';
    final finalDoc = ReportBlocksMapper.applyEdits(_doc(), _finalSections(finalText));
    // The PDF engine downloads its fonts on first use. The test binding blocks real HTTP, so allow it here; with no
    // network at all the test says so instead of failing for a reason that has nothing to do with the report.
    HttpOverrides.global = null;
    late final GeneratedFileResult pdf;
    late final GeneratedFileResult plain;
    try {
      pdf = await PdfGeneratorService(config).generatePdf(finalDoc);
      plain = await PdfGeneratorService(config).generatePdf(_doc());
    } on StateError catch (e) {
      if (e.message.contains('Unable to download the report fonts')) {
        markTestSkipped('needs network once to download the PDF fonts');
        return;
      }
      rethrow;
    }
    expect(utf8.decode(pdf.bytes.sublist(0, 5)), '%PDF-');
    expect(pdf.bytes.length, greaterThan(2000));
    expect(pdf.bytes, isNot(equals(plain.bytes)), reason: 'the final wording must change the file');
    expect(pdf.path.toLowerCase(), endsWith('.pdf'));
  });

  test('after a reopen and a second final version, the reports carry the second round only', () async {
    final round1 = ReportBlocksMapper.applyEdits(_doc(), _finalSections('Round one wording.'));
    final round2 = ReportBlocksMapper.applyEdits(_doc(), _finalSections('Round two wording.'));
    final one = _wordXml((await DocxGeneratorService(config).generateDocx(round1)).bytes);
    final two = _wordXml((await DocxGeneratorService(config).generateDocx(round2)).bytes);
    expect(one, contains('Round one wording.'));
    expect(two, contains('Round two wording.'));
    expect(two, isNot(contains('Round one wording.')));
  });

  test('text from the browser is written as text: markup in it is escaped in the Word file, not interpreted', () async {
    const hostile = 'Roof <script>alert(1)</script> & "quotes" <b>bold</b>';
    final doc = ReportBlocksMapper.applyEdits(_doc(), _finalSections(hostile));
    final xml = _wordXml((await DocxGeneratorService(config).generateDocx(doc)).bytes);
    expect(xml, isNot(contains('<script>')));
    expect(xml, isNot(contains('<b>bold</b>')));
    expect(xml, contains('alert(1)'));
  });
}
