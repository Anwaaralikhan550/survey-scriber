// Temporary probe for the valuation Nov-13 work: builds the real PDF + DOCX and a text dump
// from tmp/client-edits-2026-11-13/<ANSWERS>.json. Run:
//   ANSWERS=answers_base OUT=baseline flutter test test/_scratch_valuation_nov13.dart
// Delete this file at V18.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _Paths();
  test('valuation probe', () async {
    final answersName = Platform.environment['ANSWERS'] ?? 'answers_base';
    final outName = Platform.environment['OUT'] ?? 'baseline';
    const root = 'tmp/client-edits-2026-11-13';
    final out = Directory('$root/out')..createSync(recursive: true);
    final answers = (jsonDecode(File('$root/$answersName.json').readAsStringSync())
            as Map<String, dynamic>)
        .map((k, v) => MapEntry(
            k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, '$b'))));
    final tree = InspectionTreePayload.fromJson(
        File('assets/property_valuation/valuation_tree.json').readAsStringSync());
    final catalog = ValuationPhraseCatalog.fromRawJson(
        File('assets/property_valuation/phrase_texts.json').readAsStringSync());
    final survey = Survey(
      id: 'val-probe',
      title: '54 Gas Lane, Dartford, Dartford, Kent, DA2 5TT',
      type: SurveyType.valuation,
      status: SurveyStatus.completed,
      createdAt: DateTime(2026, 11, 11),
      address: '54 Gas Lane, Dartford, Dartford, Kent, DA2 5TT',
      clientName: 'Dan Baker',
      jobRef: 'VL1433',
    );
    final raw = V2RawReportData(
      survey: survey,
      tree: tree,
      allAnswers: answers,
      screenStates: const {},
      photoFilePaths: const [],
      signatureRows: const [],
    );
    const config = ExportConfig(
        includePhotos: false, includeSignatures: false, includeRecommendations: false, reportCompanyName: 'Francis Blackstone Surveyors');
    final doc = ReportBuilder(
            valuationPhraseEngine: ValuationPhraseEngine.catalog(catalog))
        .build(raw, config);
    final b = StringBuffer();
    for (final s in doc.sections) {
      b.writeln('## ${s.title}');
      for (final sc in s.screens) {
        b.writeln('### ${sc.title}');
        for (final p in sc.phrases) {
          b.writeln(p);
        }
        for (final f in sc.fields) {
          if (sc.phrases.isEmpty) b.writeln('  [field] ${f.label}: ${f.displayValue}');
        }
      }
    }
    b.writeln('## ACCOMMODATION ROWS: ${doc.accommodationSchedule.length}');
    File('${out.path}/$outName.txt').writeAsStringSync(b.toString());
    final pdf = await PdfGeneratorService(config).generatePdf(doc);
    final docx = await DocxGeneratorService(config).generateDocx(doc);
    File('${out.path}/$outName.pdf').writeAsBytesSync(pdf.bytes);
    File('${out.path}/$outName.docx').writeAsBytesSync(docx.bytes);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

class _Paths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      'E:/survey-scriber/tmp/valuation_export_app_documents';
}
