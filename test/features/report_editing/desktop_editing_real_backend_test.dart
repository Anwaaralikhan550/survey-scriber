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
import 'package:survey_scriber/features/report_editing/data/photo_sync_service.dart';
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

class _LocalPhotos implements LocalPhotos {
  _LocalPhotos(this.dir);
  final Directory dir;
  final rows = <String, LocalPhoto>{};
  int n = 0;
  @override
  Future<List<LocalPhoto>> forSurvey(String surveyId) async => rows.values.toList();
  @override
  Future<void> insert(LocalPhoto photo, {required int fileSize}) async => rows[photo.id] = photo;
  @override
  Future<void> update(String id, {String? caption, int? sortOrder, String? sectionId}) async {
    final o = rows[id]!;
    rows[id] = LocalPhoto(
      id: o.id,
      surveyId: o.surveyId,
      sectionId: sectionId ?? o.sectionId,
      localPath: o.localPath,
      remoteId: o.remoteId,
      caption: caption == null ? o.caption : (caption.isEmpty ? null : caption),
      sortOrder: sortOrder ?? o.sortOrder,
      synced: o.synced,
    );
  }

  @override
  Future<void> delete(String id) async {
    final f = File(rows[id]!.localPath);
    if (f.existsSync() && !f.path.contains('fixtures')) f.deleteSync();
    rows.remove(id);
  }

  @override
  Future<String> newFilePath(String surveyId, String extension) async => '${dir.path}/photo_${n++}.$extension';
}

void main() {
  final url = Platform.environment['REAL_BACKEND_URL'];
  final token = Platform.environment['REAL_BACKEND_TOKEN'];
  final surveyId = Platform.environment['REAL_SURVEY_ID'];
  final surveyId2 = Platform.environment['REAL_SURVEY_ID_2'];
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

  test('photos: phone photo -> filed under its screen -> browser adds, captions, deletes -> Synchronise brings it all back', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    PathProviderPlatform.instance = _Paths(Directory.systemTemp.createTempSync('real_docs2_').path);
    final sid = surveyId2!;
    final tree = InspectionTreePayload.fromJson(File('assets/property_valuation/valuation_tree.json').readAsStringSync());
    final answers = (jsonDecode(File('tmp/client-edits-2026-11-13/answers_cur.json').readAsStringSync()) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((a, b) => MapEntry(a, '$b'))));
    final survey = Survey(id: sid, title: '12 Photo Lane', type: SurveyType.valuation, status: SurveyStatus.completed, createdAt: DateTime(2026, 11, 11), address: '12 Photo Lane, Dartford', jobRef: 'VL1434');
    const config = ExportConfig(includePhotos: false, includeSignatures: false, includeRecommendations: false);
    ReportDocument build() => ReportBuilder(valuationPhraseEngine: ValuationPhraseEngine()).build(
          V2RawReportData(survey: survey, tree: tree, allAnswers: answers, screenStates: const {}, photoFilePaths: const [], signatureRows: const []),
          config,
        );
    final doc = build();
    final screen = doc.sections.expand((s) => s.screens.map((sc) => (s.key, sc))).firstWhere((e) => e.$2.phrases.isNotEmpty);
    final cloudKey = '${screen.$1}/${screen.$2.screenId}';

    final dio = _client(url!, headers: {'Authorization': 'Bearer $token'});
    // 1. The phone uploads a photo the way the app does (multipart to /media/upload). The file has GPS in it.
    final fixture = File('tmp/desktop-editing/fixtures/roof_front.jpg');
    expect(fixture.existsSync(), isTrue, reason: 'run tmp/desktop-editing/p21_photos.js once to create the fixtures');
    final up = await dio.post<Map<String, dynamic>>(
      'media/upload',
      data: FormData.fromMap({'surveyId': sid, 'type': 'PHOTO', 'file': await MultipartFile.fromFile(fixture.path, filename: 'IMG_1.jpg', contentType: DioMediaType('image', 'jpeg'))}),
    );
    expect(up.statusCode, 201, reason: '${up.data}');
    final remote = up.data!['id'] as String;

    final dir = Directory.systemTemp.createTempSync('real_photos_');
    final localPhotos = _LocalPhotos(dir);
    localPhotos.rows['phone-1'] = LocalPhoto(id: 'phone-1', surveyId: sid, sectionId: screen.$2.screenId, localPath: fixture.path, remoteId: remote, caption: 'Phone caption', synced: true);
    final api = ReportEditingApi(dio);
    final store = DesktopEditStore(directory: () async => dir, vault: _MemoryVault());
    final c = DesktopEditingController(
      surveyId: sid,
      reportType: 'VALUATION',
      api: api,
      store: store,
      buildDocument: () async => build(),
      photos: PhotoSyncService(api: api, local: localPhotos, pause: const Duration(milliseconds: 450)),
    );

    // 2. Generate link: report uploaded, the phone photo filed under its screen with its caption.
    await c.refresh();
    await c.generateLink();
    expect(c.state.error, isNull, reason: c.state.error);
    expect(c.state.appVersion, c.state.cloudVersion);
    final raw = Uri.parse(c.state.linkUrl!).pathSegments.last;
    final open = await _client(url).post<Map<String, dynamic>>('editor/open', data: {'token': raw});
    final cookie = open.headers['set-cookie']!.first.split(';').first;
    final editor = _client(url, headers: {'Cookie': cookie, 'X-CSRF-Token': open.data!['csrfToken'] as String});
    final list = await editor.get<Map<String, dynamic>>('editor/reports/$sid/photos');
    final phonePhoto = (list.data!['photos'] as List).single as Map;
    expect(phonePhoto['id'], remote);
    expect(phonePhoto['caption'], 'Phone caption');
    expect(phonePhoto['sectionKey'], cloudKey);
    var version = list.data!['version'] as int;
    expect(version, c.state.cloudVersion);

    // 3. In the browser: add a photo (with GPS), re-caption the phone photo.
    final added = await editor.post<Map<String, dynamic>>(
      'editor/reports/$sid/photos',
      data: FormData.fromMap({
        'expectedReportVersion': '$version',
        'sectionKey': cloudKey,
        'caption': 'Added in the browser',
        'file': await MultipartFile.fromFile('tmp/desktop-editing/fixtures/roof_rear.jpg', filename: 'rear.jpg', contentType: DioMediaType('image', 'jpeg')),
      }),
    );
    expect(added.statusCode, 201, reason: '${added.data}');
    version = added.data!['version'] as int;
    final recap = await editor.put<Map<String, dynamic>>('editor/reports/$sid/photos/$remote', data: {'expectedReportVersion': version, 'caption': 'Re-captioned in the browser'});
    expect(recap.statusCode, 200, reason: '${recap.data}');

    // 4. Synchronise: the new photo is downloaded, the caption changes, nothing else is touched.
    await c.synchronise();
    expect(c.state.error, isNull, reason: c.state.error);
    expect(c.state.notice, contains('Photos: 1 photo added, 1 updated'));
    expect(localPhotos.rows, hasLength(2));
    expect(localPhotos.rows['phone-1']!.caption, 'Re-captioned in the browser');
    final fresh = localPhotos.rows.values.firstWhere((r) => r.id != 'phone-1');
    expect(fresh.caption, 'Added in the browser');
    expect(fresh.sectionId, screen.$2.screenId);
    final bytes = File(fresh.localPath).readAsBytesSync();
    expect(bytes.sublist(0, 3), [0xff, 0xd8, 0xff]);
    expect(String.fromCharCodes(bytes).contains('GPS'), isFalse);

    // The Word report built from the phone's photos now carries the browser's photo too (current picture, current order).
    final ordered = localPhotos.rows.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final withPhotos = await DocxGeneratorService(const ExportConfig(includeSignatures: false, includeRecommendations: false)).generateDocx(build().copyWith(photoFilePaths: [for (final r in ordered) r.localPath]));
    final media = ZipDecoder().decodeBytes(withPhotos.bytes).files.where((f) => f.name.startsWith('word/media/') && f.isFile).toList();
    expect(media, hasLength(2));

    // 5. The browser deletes the phone's photo; the next Synchronise removes it from the phone.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final cur = await editor.get<Map<String, dynamic>>('editor/reports/$sid/photos');
    final gone = await editor.delete<Map<String, dynamic>>('editor/reports/$sid/photos/$remote', queryParameters: {'expectedReportVersion': cur.data!['version']});
    expect(gone.statusCode, 200, reason: '${gone.data}');
    await c.synchronise();
    expect(c.state.notice, contains('1 removed'));
    expect(localPhotos.rows.values.map((r) => r.caption), ['Added in the browser']);

    // 6. A second Synchronise changes nothing.
    await c.synchronise();
    expect(c.state.notice, 'Synchronised. Your PDF and Word reports now use the edited wording.');
    c.dispose();
    dir.deleteSync(recursive: true);
  }, skip: enabled && surveyId2 != null ? false : 'needs REAL_BACKEND_URL, REAL_BACKEND_TOKEN, REAL_SURVEY_ID, REAL_SURVEY_ID_2', timeout: const Timeout(Duration(minutes: 4)));
}
