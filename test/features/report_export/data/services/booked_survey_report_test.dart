// A survey made by a booking through to its report: visit date, company and logo.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
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

Uint8List _png() {
  final bytes = ByteData(24)
    ..setUint32(0, 0x89504E47)
    ..setUint32(16, 200)
    ..setUint32(20, 100);
  return bytes.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance =
      _Paths(Directory.systemTemp.createTempSync('booked_report_').path);

  final tree = InspectionTreePayload.fromJson(
    File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
  );
  final texts = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));

  ReportDocument build(Survey survey, ExportConfig config) => ReportBuilder(
        inspectionPhraseEngine: InspectionPhraseEngine(texts),
        valuationPhraseEngine: null,
      ).build(
        V2RawReportData(
          survey: survey,
          tree: tree,
          allAnswers: const {},
          screenStates: const {},
          photoFilePaths: const [],
          signatureRows: const [],
        ),
        config,
      );

  Future<Map<String, String>> word(ReportDocument doc, ExportConfig config) async {
    final result = await DocxGeneratorService(config).generateDocx(doc);
    final zip = ZipDecoder().decodeBytes(result.bytes);
    String part(String name) => utf8.decode(zip.findFile(name)!.content as List<int>);
    return {
      'document': part('word/document.xml'),
      'header': part('word/header1.xml'),
      'footer': part('word/footer1.xml'),
    };
  }

  final booked = Survey(
    id: 's1',
    title: 'Inspection - UI-200',
    type: SurveyType.inspection,
    status: SurveyStatus.draft,
    createdAt: DateTime(2026, 11, 4),
    inspectionDate: DateTime(2026, 12, 1),
    jobRef: 'UI-200',
    clientName: 'Grace Edited',
    address: '10 Oak Road, LS1 4AB',
  );

  test('the first page prints the visit date, not the day it was booked', () async {
    const config = ExportConfig();
    final doc = build(booked, config);
    expect(doc.surveyMeta.inspectionDate, DateTime(2026, 12, 1));
    final xml = (await word(doc, config))['document']!;
    expect(xml, contains('1 December 2026'));
    expect(xml, isNot(contains('4 November 2026<')));
    expect(xml, contains('Grace Edited'));
    expect(xml, contains('10 Oak Road, LS1 4AB'));
    expect(xml, contains('UI-200'));
  });

  test('a survey made without a booking keeps its creation date', () {
    final doc = build(
      Survey(
        id: 's2',
        title: 'Inspection - OLD',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 2, 28),
      ),
      const ExportConfig(),
    );
    expect(doc.surveyMeta.inspectionDate, DateTime(2026, 2, 28));
  });

  test('company name and logo from Settings reach the booked report', () async {
    final config = ExportConfig(
      reportCompanyName: 'Francis Blackstone Surveyor',
      reportCompanyLogo: _png(),
    );
    final parts = await word(build(booked, config), config);
    expect(parts['document'], contains('Francis Blackstone Surveyor'));
    expect(parts['document'], contains('Home Buyer Report'));
    expect(parts['document'], contains('<wp:anchor '));
    expect(parts['header'], contains('Level 2 Home Survey Report'));
    expect(parts['footer'], contains('Francis Blackstone Surveyor'));
    expect(parts['document'], isNot(contains('RICS HomeBuyer')));
  });

  test('no company saved: no empty row, no stray text', () async {
    const config = ExportConfig();
    final parts = await word(build(booked, config), config);
    expect(parts['document'], isNot(contains('<wp:anchor ')));
    expect(parts['document'], contains('Home Buyer Report'));
    expect(parts['footer'], contains('Generated by SurveyScriber'));
  });

  test('the report level comes from the survey type', () {
    final doc = build(booked, const ExportConfig());
    expect(doc.surveyMeta.reportLevel, SurveyType.inspection.reportLevel);
    expect(doc.surveyMeta.reportLevel, 'Level 2 Home Survey');
  });
}
