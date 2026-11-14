// Client list "Valuation Feed back November 13" + sample "FBS_Valuation_Report_Section_Bars_Aligned":
// the valuation report's sections, colours, element boxes, cover, header and footer, checked on the
// Word file itself. The PDF is generated too (its text streams are compressed, so it is compared by eye).
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _Paths(Directory.systemTemp.createTempSync('val_nov13_').path);

  final tree = InspectionTreePayload.fromJson(File('assets/property_valuation/valuation_tree.json').readAsStringSync());
  final answers = (jsonDecode(File('tmp/client-edits-2026-11-13/answers_cur.json').readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, '$b'))));
  final survey = Survey(
    id: 'v',
    title: '54 Gas Lane, Dartford',
    type: SurveyType.valuation,
    status: SurveyStatus.completed,
    createdAt: DateTime(2026, 11, 11),
    address: '54 Gas Lane, Dartford, Kent',
    clientName: 'Dan Baker',
    jobRef: 'VL1433',
  );
  const config = ExportConfig(includePhotos: false, includeSignatures: false, includeRecommendations: false, reportCompanyName: 'Francis Blackstone Surveyors');
  ReportDocument build() => ReportBuilder(valuationPhraseEngine: ValuationPhraseEngine()).build(
        V2RawReportData(
          survey: survey,
          tree: tree,
          allAnswers: answers,
          screenStates: const {},
          photoFilePaths: const [],
          signatureRows: const [],
        ),
        config,
      );
  Future<String> xml(ReportDocument d, [String part = 'word/document.xml']) async {
    final r = await DocxGeneratorService(config).generateDocx(d);
    return utf8.decode(ZipDecoder().decodeBytes(r.bytes).findFile(part)!.content as List<int>);
  }

  test('the report reads in the sample order, with the sample section names', () {
    final doc = build();
    expect([for (final s in doc.sections) s.title],
        ['About Inspection', 'About Property', 'Outside Property', 'F Inside Property', 'G Services', 'Restrictions', 'Significant Valuation Consideration', 'Valuation']);
    expect([for (final s in doc.sections) s.key], ['A', 'D', 'E', 'F', 'G', 'H', 'S', 'valuation_completion']);
  });

  test('elements land in the right section, Windows under Outside, Services apart', () {
    final doc = build();
    List<String> ids(String key) => [for (final s in doc.sections.where((s) => s.key == key)) for (final sc in s.screens) sc.screenId];
    expect(ids('E'), containsAll(['val_pitched_roof', 'val_rainwater_goods', 'val_chimney_stacks', 'val_walls_type', 'val_external_joinery', 'val_decorations_ext', 'val_floor_ext', 'val_garage', 'val_outbuildings']));
    expect(ids('F'), containsAll(['val_roof_space', 'val_walls_internal', 'val_kitchen', 'val_bathroom', 'val_damp_meter']));
    expect(ids('F'), isNot(contains('val_external_joinery')));
    expect(ids('G'), containsAll(['val_electric_material', 'val_gas', 'val_water', 'val_hot_water_central_heating']));
    expect(ids('H'), ['overall_condition']);
    expect(ids('S'), ['val_sv_roof', 'val_sv_damp', 'val_sv_other']); // the ones with answers
    expect(ids('valuation_completion'), ['valuation']);
    final outside = doc.sections.firstWhere((s) => s.key == 'E').screens;
    expect(outside.map((s) => s.title), contains('Roof'));
    expect(outside.map((s) => s.title), contains('External Decorations/finishes'));
  });

  test('Word: each section bar has the sample colour', () async {
    final x = await xml(build());
    for (final entry in {
      'About Inspection': '38474F',
      'About Property': '1466BF',
      'Outside Property': '2E7D33',
      'F Inside Property': '9C26B0',
      'G Services': 'FF7000',
      'Restrictions': '00786B',
      'Significant Valuation Consideration': 'D42E2E',
      'Valuation': '24566A',
    }.entries) {
      final bar = RegExp('w:fill="([0-9A-F]{6})"/></w:tcPr><w:p><w:pPr><w:pStyle w:val="Heading1"/>.{0,200}?<w:t xml:space="preserve">${entry.key}</w:t>')
          .firstMatch(x);
      expect(bar, isNotNull, reason: entry.key);
      expect(bar!.group(1), entry.value, reason: entry.key);
    }
  });

  test('Word: every element is a two-column box with the name in a shaded left cell', () async {
    final x = await xml(build());
    expect('w:fill="EAF1F4"'.allMatches(x).length, greaterThan(15));
    expect(x, contains('<w:color w:val="24566A"/>'));
    expect(x, contains('<w:vAlign w:val="center"/>'));
    expect(x, contains('<w:t xml:space="preserve">General Details</w:t>'));
    expect(x, contains('<w:t xml:space="preserve">Rainwater Goods</w:t>'));
    expect(x, contains('The rainwater goods comprise PVC, gutters and downpipes.'));
  });

  test('Word: the sections flow on without a page break between them', () async {
    final x = await xml(build());
    expect('<w:pageBreakBefore/>'.allMatches(x), isEmpty);
  });

  test('Word: cover, running header and footer as in the sample', () async {
    final d = build();
    final x = await xml(d);
    expect(x, contains('Francis Blackstone Surveyors'));
    expect(x, contains('Property Valuation Report'));
    expect(x, isNot(contains('Mortgage Valuation Report')));
    expect(x, isNot(contains('Professional property valuation report')));
    expect(x, isNot(contains('54 Gas Lane, Dartford</w:t>'))); // no title line under the bar
    final header = await xml(d, 'word/header1.xml');
    expect(header, contains('Property Valuation Report'));
    expect(header, contains('Valuation - VL1433'));
    final footer = await xml(d, 'word/footer1.xml');
    expect(footer.indexOf('Francis Blackstone Surveyors'), greaterThan(footer.indexOf('Generated by SurveyScriber')));
  });

  test('Word: the Accommodation table sits under About Property', () async {
    final x = await xml(build());
    expect(x.indexOf('Property total'), greaterThan(x.indexOf('About Property')));
    expect(x.indexOf('Property total'), lessThan(x.indexOf('Outside Property')));
  });

  test('the removed sections are not in the report', () async {
    final x = await xml(build());
    for (final gone in ['Location &amp; Amenities', 'New Build', 'Energy Performance', 'Other Matters', 'Estate']) {
      expect(x, isNot(contains(gone)), reason: gone);
    }
  });

  test('Word: the Signatures bar is 24566A in the valuation report', () async {
    final base = build();
    final doc = ReportDocument(
      reportType: base.reportType,
      title: base.title,
      generatedAt: base.generatedAt,
      surveyMeta: base.surveyMeta,
      sections: const [],
      signatures: [
        ReportSignature(signerName: 'Izuka Soligbo', signerRole: 'Surveyor', filePath: '', signedAt: DateTime(2026, 11, 12)),
      ],
    );
    const withSignatures = ExportConfig(includePhotos: false, includeSignatures: true, includeRecommendations: false);
    final r = await DocxGeneratorService(withSignatures).generateDocx(doc);
    final x = utf8.decode(ZipDecoder().decodeBytes(r.bytes).findFile('word/document.xml')!.content as List<int>);
    final bar = RegExp('w:fill="([0-9A-F]{6})"/></w:tcPr><w:p><w:pPr><w:pStyle w:val="Heading1"/>.{0,200}?<w:t xml:space="preserve">Signatures</w:t>').firstMatch(x);
    expect(bar, isNotNull);
    expect(bar!.group(1), '24566A');
    expect(x, contains('Izuka Soligbo (Surveyor) - 12 November 2026'));
  });

  test('the PDF builds with the same document (needs the cached fonts, skipped without them)', () async {
    final fonts = Directory('tmp/valuation_export_app_documents/fonts');
    if (!fonts.existsSync()) return;
    final before = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(Directory('tmp/valuation_export_app_documents').absolute.path);
    try {
      final pdf = await PdfGeneratorService(config).generatePdf(build());
      expect(pdf.bytes.length, greaterThan(5000));
      expect(String.fromCharCodes(pdf.bytes.take(5)), '%PDF-');
    } finally {
      PathProviderPlatform.instance = before;
    }
  });
}
