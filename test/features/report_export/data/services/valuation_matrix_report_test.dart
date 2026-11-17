// Client 17 Nov 2026 (Q10): the FBS Valuation Matrix is a blank, hand-filled comparables table under Valuation,
// in the app and in the desktop browser editor, in the PDF and the Word report. Nothing in it is generated.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_matrix.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_editing/domain/report_blocks_mapper.dart';
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

const _labels = [
  'Address', 'Date of Trans', 'Price', 'Size / Sqm', 'Bedrooms', 'Condition', 'Compare', 'Type', 'Tenure',
  'Price/Sqm', 'Features', 'Adjustment', 'Amount', 'Adjustment', 'Amount', 'Adjustment', 'Amount',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _Paths(Directory.systemTemp.createTempSync('val_matrix_').path);

  final tree = InspectionTreePayload.fromJson(File('assets/property_valuation/valuation_tree.json').readAsStringSync());
  const config = ExportConfig(
      includePhotos: false, includeSignatures: false, includeRecommendations: false, reportCompanyName: 'Francis Blackstone Surveyors');
  Survey survey(SurveyType type) => Survey(
        id: '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10',
        title: '54 Gas Lane, Dartford',
        type: type,
        status: SurveyStatus.completed,
        createdAt: DateTime(2026, 11, 17),
        address: '54 Gas Lane, Dartford, Kent',
        clientName: 'Dan Baker',
        jobRef: 'VL1433',
      );
  ReportDocument build({Map<String, Map<String, String>> more = const {}}) => ReportBuilder(valuationPhraseEngine: ValuationPhraseEngine()).build(
        V2RawReportData(
          survey: survey(SurveyType.valuation),
          tree: tree,
          allAnswers: {
            'valuation': {'et_purchase_price': '400000'},
            ...more,
          },
          screenStates: const {},
          photoFilePaths: const [],
          signatureRows: const [],
        ),
        config,
      );
  String grid(void Function(List<List<String>>) fill) {
    final g = ValuationMatrix.emptyGrid();
    fill(g);
    return ValuationMatrix.encode(g);
  }

  group('the matrix in the report document', () {
    test('a valuation report always has the matrix: 17 named rows, 6 blank cells each', () {
      final doc = build();
      expect(doc.valuationMatrix.length, 17);
      expect([for (final r in doc.valuationMatrix) r.first], _labels);
      for (final row in doc.valuationMatrix) {
        expect(row.length, 7);
        expect(row.skip(1), everyElement(''), reason: row.first);
      }
      expect(ValuationMatrix.headers, ['Best Match', 'Comp 1', 'Comp 2', 'Comp 3', 'Comp 4', 'Comp 5', 'Subject']);
    });
    test('what the surveyor typed is what the table holds, and nothing else is filled in', () {
      final doc = build(more: {
        'valuation_matrix': {
          'et_matrix_grid': grid((g) {
            g[0][0] = '12 High Street';
            g[2][5] = '£460,000';
            g[9][1] = '';
          }),
        },
      });
      expect(doc.valuationMatrix[0][1], '12 High Street');
      expect(doc.valuationMatrix[2][6], '£460,000');
      expect(doc.valuationMatrix[9].skip(1), everyElement(''), reason: 'Price/Sqm is not calculated');
      final typed = doc.valuationMatrix.expand((r) => r.skip(1)).where((c) => c.isNotEmpty).toList();
      expect(typed, ['12 High Street', '£460,000']);
    });
    test('a damaged stored value gives a blank matrix, never an error', () {
      for (final bad in ['not json', '{"a":1}', '[1,2,3]', '[["x"]]', 'null']) {
        final doc = build(more: {'valuation_matrix': {'et_matrix_grid': bad}});
        expect(doc.valuationMatrix.length, 17, reason: bad);
      }
    });
    test('the matrix screen is not an element box of its own', () {
      final doc = build(more: {'valuation_matrix': {'et_matrix_grid': grid((g) => g[0][0] = 'x')}});
      final ids = [for (final s in doc.sections) for (final sc in s.screens) sc.screenId];
      expect(ids, isNot(contains('valuation_matrix')));
      expect(ids, contains('valuation'));
    });
    test('an inspection report has no matrix', () {
      final inspectionTree = InspectionTreePayload.fromJson(File('assets/property_inspection/inspection_tree.json').readAsStringSync());
      final doc = ReportBuilder().build(
        V2RawReportData(
          survey: survey(SurveyType.inspection),
          tree: inspectionTree,
          allAnswers: const {},
          screenStates: const {},
          photoFilePaths: const [],
          signatureRows: const [],
        ),
        config,
      );
      expect(doc.valuationMatrix, isEmpty);
    });
  });

  group('Word', () {
    Future<String> xml(ReportDocument d) async {
      final r = await DocxGeneratorService(config).generateDocx(d);
      return utf8.decode(ZipDecoder().decodeBytes(r.bytes).findFile('word/document.xml')!.content as List<int>);
    }

    test('the table: title, header row, the 17 row names in order, after the Valuation section', () async {
      final x = await xml(build());
      expect(x, contains('<w:t xml:space="preserve">FBS Valuation Matrix</w:t>'));
      var at = x.indexOf('FBS Valuation Matrix');
      expect(at, greaterThan(x.lastIndexOf('>Valuation<')), reason: 'under the Valuation section');
      for (final h in ValuationMatrix.headers) {
        final i = x.indexOf('>$h<', at);
        expect(i, greaterThan(-1), reason: h);
        at = i;
      }
      for (final l in _labels) {
        final i = x.indexOf('>$l<', at);
        expect(i, greaterThan(-1), reason: l);
        at = i;
      }
      expect('<w:tr>'.allMatches(x.substring(x.indexOf('FBS Valuation Matrix'))).length, greaterThanOrEqualTo(17));
    });
    test('typed text appears, special characters are escaped', () async {
      final x = await xml(build(more: {
        'valuation_matrix': {'et_matrix_grid': grid((g) => g[0][5] = 'Flat 3 & Co "A"')},
      }));
      expect(x, contains('Flat 3 &amp; Co &quot;A&quot;'));
      expect(x, isNot(contains('Flat 3 & Co')));
    });
    test('an inspection report has no matrix table', () async {
      final doc = ReportDocument(
        reportType: ReportType.inspection,
        title: 't',
        generatedAt: DateTime(2026, 11, 17),
        surveyMeta: const SurveyMeta(surveyId: 'i', title: 't'),
        sections: const [],
      );
      expect(await xml(doc), isNot(contains('FBS Valuation Matrix')));
    });
  });


  group('Limitations under Restrictions (client Q9)', () {
    test('Restrictions holds Limitations first, then Overall Condition, as the sample', () {
      final doc = build(more: {
        'val_limitations': {'cb_lim_no_restrictions': 'true'},
        'overall_condition': {'actv_overall_condition': 'Reasonable'},
      });
      final restrictions = doc.sections.firstWhere((s) => s.title == 'Restrictions');
      expect([for (final s in restrictions.screens) s.screenId], ['val_limitations', 'overall_condition']);
      expect(restrictions.screens.first.phrases.length, 2);
    });
    test('Word: the Limitations box has the sample wording and the two lead notes in bold', () async {
      final doc = build(more: {'val_limitations': {'cb_lim_no_restrictions': 'true', 'cb_lim_no_rear_access': 'true'}});
      final r = await DocxGeneratorService(config).generateDocx(doc);
      final x = utf8.decode(ZipDecoder().decodeBytes(r.bytes).findFile('word/document.xml')!.content as List<int>);
      expect(x, contains('>Limitations<'));
      expect(x, contains('The inspection of the grounds was visual only.'));
      expect(x, contains('<w:b/><w:sz w:val="18"/></w:rPr><w:t xml:space="preserve">No inspection restrictions: </w:t>'));
      expect(x, contains('<w:b/><w:sz w:val="18"/></w:rPr><w:t xml:space="preserve">Restricted access: </w:t>'));
      expect(x, contains('>There were no unusual restrictions affecting my inspection'));
    });
  });

  test('PDF: the report is produced with the matrix (blank and filled)', () async {
    // The PDF engine downloads its fonts on first use; the test binding blocks real HTTP, so allow it here.
    HttpOverrides.global = null;
    try {
      final sizes = <int>[];
      for (final more in [
        <String, Map<String, String>>{},
        {'valuation_matrix': {'et_matrix_grid': grid((g) => g[1][2] = '03/2026')}},
      ]) {
        final r = await PdfGeneratorService(config).generatePdf(build(more: more));
        expect(r.bytes.length, greaterThan(2000));
        expect(String.fromCharCodes(r.bytes.take(5)), '%PDF-');
        sizes.add(r.bytes.length);
      }
      expect(sizes[0], isNot(sizes[1]), reason: 'typed text must change the file');
    } on StateError catch (e) {
      if (e.message.contains('Unable to download the report fonts')) {
        markTestSkipped('needs network once to download the PDF fonts');
        return;
      }
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  group('the desktop browser editor (blocks)', () {
    test('the matrix is a table block with a stable id, role matrix, header row and 17 rows', () {
      final doc = build();
      final a = ReportBlocksMapper.toSections(doc);
      final b = ReportBlocksMapper.toSections(doc);
      final sec = a.firstWhere((s) => s['key'] == 'VALUATION_MATRIX');
      expect(sec['title'], 'FBS Valuation Matrix');
      final block = (sec['blocks'] as List).single as Map<String, dynamic>;
      expect(block['type'], 'table');
      expect(block['role'], 'matrix');
      final table = block['table'] as Map;
      expect(table['headers'], ValuationMatrix.headers);
      expect((table['rows'] as List).length, 17);
      expect(sec['id'], b.firstWhere((s) => s['key'] == 'VALUATION_MATRIX')['id']);
      expect(block['id'], ((b.firstWhere((s) => s['key'] == 'VALUATION_MATRIX')['blocks'] as List).single as Map)['id']);
    });
    test('what the browser types comes back into the report; row names cannot be changed', () {
      final doc = build();
      final sections = ReportBlocksMapper.toSections(doc);
      final block = ((sections.firstWhere((s) => s['key'] == 'VALUATION_MATRIX')['blocks'] as List).single as Map<String, dynamic>);
      final rows = ((block['table'] as Map)['rows'] as List).map((r) => (r as List).map((c) => '$c').toList()).toList();
      rows[0][1] = '1 Mill Lane';
      rows[2][6] = '£525,000';
      rows[4][0] = 'Renamed by mistake';
      (block['table'] as Map)['rows'] = rows;
      final back = ReportBlocksMapper.applyEdits(doc, sections);
      expect(back.valuationMatrix[0][1], '1 Mill Lane');
      expect(back.valuationMatrix[2][6], '£525,000');
      expect(back.valuationMatrix[4][0], 'Bedrooms');
      expect([for (final r in back.valuationMatrix) r.first], _labels);
    });
    test('a report without the matrix block keeps its matrix; edits are carried into Word', () async {
      final doc = build(more: {'valuation_matrix': {'et_matrix_grid': grid((g) => g[0][0] = 'kept')}});
      expect(ReportBlocksMapper.applyEdits(doc, const []).valuationMatrix[0][1], 'kept');
      final sections = ReportBlocksMapper.toSections(doc);
      final table = ((sections.firstWhere((s) => s['key'] == 'VALUATION_MATRIX')['blocks'] as List).single as Map)['table'] as Map;
      (table['rows'] as List)[7] = ['Type', '', '', '', '', '', 'Terrace'];
      final edited = ReportBlocksMapper.applyEdits(doc, sections);
      final r = await DocxGeneratorService(config).generateDocx(edited);
      final x = utf8.decode(ZipDecoder().decodeBytes(r.bytes).findFile('word/document.xml')!.content as List<int>);
      expect(x, contains('>Terrace<'));
      expect(x, contains('>kept<'));
    });
    test('an inspection report has no matrix section', () {
      final doc = ReportDocument(
        reportType: ReportType.inspection,
        title: 't',
        generatedAt: DateTime(2026, 11, 17),
        surveyMeta: const SurveyMeta(surveyId: 'i', title: 't'),
        sections: const [],
      );
      expect(ReportBlocksMapper.toSections(doc).where((s) => s['key'] == 'VALUATION_MATRIX'), isEmpty);
    });
  });
}
