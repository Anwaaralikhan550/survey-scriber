// Client edits 2 Nov 2026 ("Survey Scriber Edit Oct 2026.docx"): the report layout, checked
// on the Word file itself. The PDF renderer's text streams are compressed, so PDF
// output is compared with the client's pictures by eye.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.docs);
  final String docs;
  @override
  Future<String?> getApplicationDocumentsPath() async => docs;
}

ReportDocument _doc({
  ReportType type = ReportType.inspection,
  List<ReportSection>? sections,
}) =>
    ReportDocument(
      reportType: type,
      title: 'Inspection - ref-354',
      generatedAt: DateTime(2026, 11, 2, 12, 29),
      surveyMeta: SurveyMeta(
        surveyId: 's1',
        title: 'Inspection - ref-354',
        address: 'abc street',
        jobRef: 'ref-354',
        clientName: 'jahanzaib',
        inspectionDate: DateTime(2026, 2, 28),
        surveyDuration: const Duration(hours: 6, minutes: 3),
      ),
      sections: sections ??
          const [
            ReportSection(
              key: 'A',
              title: 'About Inspection',
              description: '',
              displayOrder: 0,
              screens: [],
            ),
          ],
    );

Future<String> _xml(ReportDocument doc, [String part = 'word/document.xml']) async {
  final result = await DocxGeneratorService(const ExportConfig()).generateDocx(doc);
  final file = ZipDecoder().decodeBytes(result.bytes).findFile(part)!;
  return utf8.decode(file.content as List<int>);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance =
      _Paths(Directory.systemTemp.createTempSync('docx_format_').path);

  group('first page', () {
    test('banner and details table as in the client picture', () async {
      final xml = await _xml(_doc());
      expect(xml, contains('RICS HomeBuyer Report'));
      expect(xml, contains('Level 2 Home Survey'));
      expect(xml, isNot(contains('Home Survey Inspection Report')));
      expect(xml, contains('w:fill="1461BF"'));
      final order = ['Property Address', 'Client Name', 'Job Reference', 'Inspection Date',
        'Report Generated', 'Survey Duration'];
      var at = 0;
      for (final label in order) {
        final i = xml.indexOf(label, at);
        expect(i, greaterThan(-1), reason: label);
        at = i;
      }
      expect(xml, contains('28 February 2026'));
      expect(xml, contains('6h 03m'));
      expect(xml, isNot(contains('Prepared by:')));
    });

    test('valuation first page is left alone', () async {
      final xml = await _xml(_doc(type: ReportType.valuation));
      expect(xml, contains('Valuation Report'));
      expect(xml, contains('Prepared by:'));
      expect(xml, isNot(contains('RICS HomeBuyer Report')));
    });
  });
}
