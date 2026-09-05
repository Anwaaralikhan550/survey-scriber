import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

/// RICS L2 Master Phrase Library — "Accommodation summary" element.
///
/// The spec requires the schedule table to be introduced/closed by:
///   "The accommodation comprises: <floors>. The accommodation schedule
///    contained within this report is provided for identification purposes
///    only."
///
/// The PDF renderer already emits this (pdf_generator_service.dart, the
/// `includeL2Intro` branch); this suite locks the DOCX renderer to the same
/// behaviour — inspection reports get the sentence, valuation reports keep the
/// table-only layout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProvider();

  const config = ExportConfig(
    format: ExportFormat.docx,
    includePhotos: false,
    includeSignatures: false,
    includeRecommendations: false,
  );

  const outroSentence =
      'The accommodation schedule contained within this report is provided '
      'for identification purposes only.';

  test('inspection DOCX emits the L2 accommodation intro + outro sentence',
      () async {
    final doc = _buildDoc(
      type: ReportType.inspection,
      sectionKey: 'D',
      screenId: 'group_construction_2',
      rows: const [
        AccommodationScheduleRow(floor: 'Ground', livingRooms: '2'),
        AccommodationScheduleRow(floor: 'First', bedrooms: '3'),
      ],
    );

    final result = await DocxGeneratorService(config).generateDocx(doc);
    final xml = _documentXml(result.bytes);

    expect(xml, contains('The accommodation comprises: Ground and First.'));
    expect(xml, contains(outroSentence));
  });

  test('multi-floor list matches the PDF renderer ("A, B and C")', () async {
    final doc = _buildDoc(
      type: ReportType.inspection,
      sectionKey: 'D',
      screenId: 'group_construction_2',
      rows: const [
        AccommodationScheduleRow(floor: 'Ground', livingRooms: '2'),
        AccommodationScheduleRow(floor: 'First', bedrooms: '3'),
        AccommodationScheduleRow(floor: 'Second', bedrooms: '1'),
      ],
    );

    final xml = _documentXml(
      (await DocxGeneratorService(config).generateDocx(doc)).bytes,
    );

    expect(
      xml,
      contains('The accommodation comprises: Ground, First and Second.'),
    );
  });

  test('single-floor list renders the bare floor name', () async {
    final doc = _buildDoc(
      type: ReportType.inspection,
      sectionKey: 'D',
      screenId: 'group_construction_2',
      rows: const [
        AccommodationScheduleRow(floor: 'Ground', livingRooms: '2'),
      ],
    );

    final xml = _documentXml(
      (await DocxGeneratorService(config).generateDocx(doc)).bytes,
    );

    expect(xml, contains('The accommodation comprises: Ground.'));
  });

  test('valuation DOCX keeps the table WITHOUT the L2 intro sentence',
      () async {
    final doc = _buildDoc(
      type: ReportType.valuation,
      sectionKey: 'property_assessment',
      screenId: 'no_of_rooms',
      rows: const [
        AccommodationScheduleRow(floor: 'Ground', livingRooms: '2'),
      ],
    );

    final xml = _documentXml(
      (await DocxGeneratorService(config).generateDocx(doc)).bytes,
    );

    // Table still renders (heading present) but the L2-only sentence must not.
    expect(xml, contains('Accommodation'));
    expect(xml, isNot(contains(outroSentence)));
  });
}

ReportDocument _buildDoc({
  required ReportType type,
  required String sectionKey,
  required String screenId,
  required List<AccommodationScheduleRow> rows,
}) {
  return ReportDocument(
    reportType: type,
    title: 'Accommodation Intro Test',
    generatedAt: DateTime(2026, 9, 3),
    surveyMeta: const SurveyMeta(surveyId: 's1', title: 'Test Survey'),
    sections: [
      ReportSection(
        key: sectionKey,
        title: sectionKey,
        description: '',
        displayOrder: 0,
        screens: [
          ReportScreen(screenId: screenId, title: 'Screen', fields: const []),
        ],
      ),
    ],
    accommodationSchedule: rows,
  );
}

String _documentXml(Uint8List docxBytes) {
  final archive = ZipDecoder().decodeBytes(docxBytes);
  final entry =
      archive.files.firstWhere((f) => f.name == 'word/document.xml');
  return utf8.decode(entry.content as List<int>);
}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      '${Directory.systemTemp.path}/ss_docx_accom_intro_test';
}
