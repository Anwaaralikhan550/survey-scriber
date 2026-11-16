// Real round trip: the phone's real valuation report -> the real backend -> a colleague edits in the browser
// API -> the phone synchronises -> the Word file has the edited wording.
// Needs a running test backend. Skipped unless REAL_BACKEND_URL, REAL_BACKEND_TOKEN and REAL_SURVEY_ID are set
// (tmp/desktop-editing/mk_survey.js prints the token and survey id).
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_editing/domain/report_blocks_mapper.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_controller.dart';
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

/// The API allows 3 requests a second per address, so the test spaces its calls (the app itself sends few).
class _Spacer extends QueuedInterceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Future<void>.delayed(const Duration(milliseconds: 450)).then((_) => handler.next(options));
  }
}

Dio _client(String url, {Map<String, dynamic>? headers}) =>
    Dio(BaseOptions(baseUrl: '$url/api/v1/', headers: headers, validateStatus: (_) => true))..interceptors.add(_Spacer());

class _MemoryVault implements LinkVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

void main() {
  final url = Platform.environment['REAL_BACKEND_URL'];
  final token = Platform.environment['REAL_BACKEND_TOKEN'];
  final surveyId = Platform.environment['REAL_SURVEY_ID'];
  final enabled = url != null && token != null && surveyId != null;

  test('phone -> cloud -> browser edit -> synchronise -> Word', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null; // flutter test blocks real HTTP by default
    PathProviderPlatform.instance = _Paths(Directory.systemTemp.createTempSync('real_docs_').path);

    final tree = InspectionTreePayload.fromJson(File('assets/property_valuation/valuation_tree.json').readAsStringSync());
    final answers = (jsonDecode(File('tmp/client-edits-2026-11-13/answers_cur.json').readAsStringSync()) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, '$b'))));
    final survey = Survey(
      id: surveyId!,
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
          V2RawReportData(survey: survey, tree: tree, allAnswers: answers, screenStates: const {}, photoFilePaths: const [], signatureRows: const []),
          config,
        );
    final original = build();

    final dio = _client(url!, headers: {'Authorization': 'Bearer $token'});
    final api = ReportEditingApi(dio);
    final dir = Directory.systemTemp.createTempSync('real_store_');
    final vault = _MemoryVault();
    final store = DesktopEditStore(directory: () async => dir, vault: vault);
    final c = DesktopEditingController(surveyId: surveyId, reportType: 'VALUATION', api: api, store: store, buildDocument: () async => build());

    // 1. Generate link: uploads the real report, makes the link.
    await c.refresh();
    expect(c.state.hasCloudReport, isFalse);
    await c.generateLink();
    expect(c.state.error, isNull, reason: c.state.error);
    expect(c.state.linkActive, isTrue);
    expect(c.state.linkUrl, contains('/open/'));
    expect(c.state.cloudVersion, 1);
    final sections = ReportBlocksMapper.toSections(original);
    expect(sections, isNotEmpty);

    // 2. A colleague opens the link and edits one real paragraph (the browser editor's own API).
    final raw = Uri.parse(c.state.linkUrl!).pathSegments.last;
    final open = await _client(url!).post<Map<String, dynamic>>('editor/open', data: {'token': raw});
    expect(open.statusCode, 200);
    final cookie = open.headers['set-cookie']!.first.split(';').first;
    final csrf = open.data!['csrfToken'] as String;
    final editor = _client(url, headers: {'Cookie': cookie, 'X-CSRF-Token': csrf});
    final read = await editor.get<Map<String, dynamic>>('editor/reports/$surveyId');
    final cloudSections = (read.data!['content'] as List).cast<Map<String, dynamic>>();
    final target = cloudSections.firstWhere((s) => (s['blocks'] as List).any((b) => (b as Map)['type'] == 'paragraph' && (b['text'] as String).isNotEmpty));
    final block = (target['blocks'] as List).cast<Map<String, dynamic>>().firstWhere((b) => b['type'] == 'paragraph' && (b['text'] as String).isNotEmpty);
    final oldText = block['text'] as String;
    const newText = 'EDITED IN THE BROWSER: the surveyor reviewed this paragraph on a computer.';
    final save = await editor.patch<Map<String, dynamic>>('editor/reports/$surveyId', data: {
      'baseVersion': 1,
      'changes': [
        {'op': 'updateBlock', 'sectionId': target['id'], 'blockId': block['id'], 'fields': {'text': newText}},
      ],
    });
    expect(save.statusCode, 200, reason: '${save.data}');

    // 3. The app sees the newer version; Synchronise takes it.
    await c.refresh();
    expect(c.state.updateAvailable, isTrue);
    expect(c.state.cloudVersion, 2);
    await c.synchronise();
    expect(c.state.error, isNull, reason: c.state.error);
    expect(c.state.appVersion, 2);
    expect(c.state.hasEdits, isTrue);

    // 4. The Word report built from the synced edits has the new wording and no longer the old.
    final record = await store.read(surveyId);
    final edited = ReportBlocksMapper.applyEdits(build(), record.syncedSections!);
    final result = await DocxGeneratorService(config).generateDocx(edited);
    final xml = utf8.decode(ZipDecoder().decodeBytes(result.bytes).findFile('word/document.xml')!.content as List<int>);
    expect(xml, contains('EDITED IN THE BROWSER'));
    expect(xml, isNot(contains(oldText.replaceAll('&', '&amp;'))));
    final plain = await DocxGeneratorService(config).generateDocx(original);
    final plainXml = utf8.decode(ZipDecoder().decodeBytes(plain.bytes).findFile('word/document.xml')!.content as List<int>);
    expect(plainXml, isNot(contains('EDITED IN THE BROWSER')));
    // everything else is the same: the edited document differs from the original in that one paragraph only
    final a = original.sections.expand((s) => s.screens).expand((s) => s.phrases).toList();
    final b = edited.sections.expand((s) => s.screens).expand((s) => s.phrases).toList();
    expect(b.length, a.length);
    expect([for (var i = 0; i < a.length; i++) if (a[i] != b[i]) b[i]], [newText]);

    // 5. Stale phone content cannot overwrite the cloud: the phone is at 2, a colleague saves 3, the phone uploads.
    final save2 = await editor.patch<Map<String, dynamic>>('editor/reports/$surveyId', data: {
      'baseVersion': 2,
      'changes': [
        {'op': 'updateBlock', 'sectionId': target['id'], 'blockId': block['id'], 'fields': {'text': 'Second browser edit.'}},
      ],
    });
    expect(save2.statusCode, 200);
    final stale = await dio.put<Map<String, dynamic>>('reports/$surveyId/snapshot', data: {'baseVersion': 2, 'reportType': 'VALUATION', 'content': sections});
    expect(stale.statusCode, 409);
    expect(stale.data!['error'], 'VERSION_CONFLICT');
    await c.updateCloudCopy();
    expect(c.state.error, contains('Synchronise first'));
    final still = await editor.get<Map<String, dynamic>>('editor/reports/$surveyId');
    final texts = [for (final s in still.data!['content'] as List) for (final b in (s as Map)['blocks'] as List) (b as Map)['text']];
    expect(texts, contains('Second browser edit.'));

    // 6. Cancel: the link stops at once.
    await c.synchronise();
    await c.cancelLink();
    expect(c.state.linkActive, isFalse);
    final after = await editor.get<Map<String, dynamic>>('editor/reports/$surveyId');
    expect(after.statusCode, anyOf(404, 410));
    c.dispose();
    dir.deleteSync(recursive: true);
  }, skip: enabled ? false : 'needs REAL_BACKEND_URL, REAL_BACKEND_TOKEN, REAL_SURVEY_ID', timeout: const Timeout(Duration(minutes: 3)));
}
