// Remote Editor v1.4 R2, phone side: the first PDF/Word made after the inspection is stored as the ORIGINAL (with the original
// report snapshot), the ones made after finalising as the FINAL of that edit cycle; never twice, never blocking an export.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/report_document_uploader.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';

class _MemoryVault implements LinkVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());

  CloudReportInfo? report;
  int cycle = 1;
  bool offline = false;
  bool fileExists = false;
  final snapshots = <Map<String, dynamic>>[];
  final files = <Map<String, dynamic>>[];

  void _net() {
    if (offline) throw const ReportEditingException(code: 'NETWORK', message: 'offline');
  }

  @override
  Future<CloudReportInfo?> latest(String surveyId) async {
    _net();
    return report;
  }

  @override
  Future<CloudReportInfo> uploadSnapshot(String surveyId, {int? baseVersion, required String reportType, required List<Map<String, dynamic>> sections}) async {
    _net();
    snapshots.add({'reportType': reportType, 'sections': sections});
    return report = CloudReportInfo(version: 1, status: 'DRAFT', updatedAt: DateTime(2026, 11, 19));
  }

  @override
  Future<ReviewInfo> review(String surveyId) async {
    _net();
    return ReviewInfo(status: 'FINALISED', version: report?.version ?? 1, cycle: cycle);
  }

  @override
  Future<StoredReportFile> uploadReportFile(String surveyId, {required String state, required List<int> bytes, required String fileName}) async {
    _net();
    if (fileExists) throw const ReportEditingException(code: 'FILE_EXISTS', message: 'already stored', status: 409);
    files.add({'state': state, 'bytes': bytes.length, 'fileName': fileName});
    return StoredReportFile(id: 'f${files.length}', sha256: 'abc${files.length}', duplicate: false);
  }
}

ReportDocument _doc({bool empty = false, ReportType type = ReportType.inspection}) => ReportDocument(
      reportType: type,
      title: '54 Gas Lane',
      generatedAt: DateTime(2026, 11, 19),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: '54 Gas Lane'),
      sections: empty
          ? const []
          : const [
              ReportSection(key: 'E', title: 'Outside Property', description: '', displayOrder: 0, screens: [
                ReportScreen(screenId: 'roof', title: 'Roof', fields: [], phrases: ['The roof is covered with concrete tiles.']),
              ]),
            ],
    );

void main() {
  late Directory dir;
  late DesktopEditStore store;
  late _Cloud cloud;
  late ReportDocumentUploader uploader;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('doc_uploader_');
    store = DesktopEditStore(directory: () async => dir, vault: _MemoryVault());
    cloud = _Cloud();
    uploader = ReportDocumentUploader(api: cloud, store: store);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String?> run({String format = 'pdf', ReportDocument? doc, int size = 1000}) =>
      uploader.afterExport(surveyId: _survey, document: doc ?? _doc(), bytes: List.filled(size, 1), fileName: 'Report.$format', format: format);

  test('no cloud report yet: the report snapshot goes first, then the original PDF; both marked', () async {
    expect(await run(), 'ORIGINAL');
    expect(cloud.snapshots, hasLength(1));
    expect(cloud.snapshots.single['reportType'], 'L2');
    expect(((cloud.snapshots.single['sections'] as List).single as Map)['key'], 'E/roof');
    expect(cloud.files.single, {'state': 'ORIGINAL', 'bytes': 1000, 'fileName': 'Report.pdf'});
    final r = await store.read(_survey);
    expect(r.files.keys, ['ORIGINAL:pdf:1']);
    expect(r.appVersion, 1);
  });

  test('a valuation is sent as VALUATION', () async {
    await run(doc: _doc(type: ReportType.valuation));
    expect(cloud.snapshots.single['reportType'], 'VALUATION');
  });

  test('the Word file is stored too, the same file is never sent twice', () async {
    await run();
    await run(format: 'docx', size: 2000);
    expect(await run(), isNull);
    expect(await run(format: 'docx'), isNull);
    expect(cloud.files.map((f) => f['bytes']), [1000, 2000]);
    expect(cloud.snapshots, hasLength(1));
    expect((await store.read(_survey)).files.keys.toSet(), {'ORIGINAL:pdf:1', 'ORIGINAL:docx:1'});
  });

  test('a cloud report at version 1 gets only the file, no second snapshot', () async {
    cloud.report = CloudReportInfo(version: 1, status: 'DRAFT', updatedAt: DateTime(2026, 11, 19));
    expect(await run(), 'ORIGINAL');
    expect(cloud.snapshots, isEmpty);
    expect(cloud.files, hasLength(1));
  });

  test('once the cloud report was edited (version above 1) a new export is not the original: nothing is sent', () async {
    cloud.report = CloudReportInfo(version: 4, status: 'EDITING', updatedAt: DateTime(2026, 11, 19));
    expect(await run(), isNull);
    expect(cloud.files, isEmpty);
    expect(cloud.snapshots, isEmpty);
  });

  test('after finalising the files are FINAL, per edit cycle: a new cycle sends again', () async {
    cloud.report = CloudReportInfo(version: 6, status: 'FINALISED', updatedAt: DateTime(2026, 11, 19));
    cloud.cycle = 1;
    expect(await run(), 'FINAL');
    expect(await run(), isNull);
    cloud.cycle = 2;
    expect(await run(), 'FINAL');
    expect(cloud.files.map((f) => f['state']), ['FINAL', 'FINAL']);
    expect((await store.read(_survey)).files.keys.toSet(), {'FINAL:pdf:1', 'FINAL:pdf:2'});
  });

  test('the cloud already holds that original (409 FILE_EXISTS): remembered, no error, nothing more sent', () async {
    cloud.report = CloudReportInfo(version: 1, status: 'DRAFT', updatedAt: DateTime(2026, 11, 19));
    cloud.fileExists = true;
    expect(await run(), 'ORIGINAL');
    cloud.fileExists = false;
    expect(await run(), isNull);
    expect(cloud.files, isEmpty);
  });

  test('offline: nothing is lost or thrown; it is tried again at the next export', () async {
    cloud.offline = true;
    expect(await run(), isNull);
    expect((await store.read(_survey)).files, isEmpty);
    cloud.offline = false;
    expect(await run(), 'ORIGINAL');
    expect(cloud.files, hasLength(1));
  });

  test('an empty report is not sent as an original', () async {
    expect(await run(doc: _doc(empty: true)), isNull);
    expect(cloud.snapshots, isEmpty);
    expect(cloud.files, isEmpty);
  });

  group('the local record', () {
    test('keeps the stored documents through an upload, a synchronise and clearing edits', () async {
      await store.markFileUploaded(_survey, 'ORIGINAL:pdf:1', 'sha');
      await store.saveUploaded(_survey, 3);
      expect((await store.read(_survey)).files, {'ORIGINAL:pdf:1': 'sha'});
      await store.saveSynced(_survey, 4, [
        {'key': 'a'}
      ]);
      final r = await store.read(_survey);
      expect(r.files, {'ORIGINAL:pdf:1': 'sha'});
      expect(r.hasEdits, isTrue);
      await store.clearEdits(_survey);
      expect((await store.read(_survey)).files, {'ORIGINAL:pdf:1': 'sha'});
      await store.forget(_survey);
      expect((await store.read(_survey)).files, isEmpty);
    });
    test('an old record without the field still reads', () async {
      File('${dir.path}/desktop_edit_$_survey.json').writeAsStringSync('{"appVersion":2}');
      final r = await store.read(_survey);
      expect(r.appVersion, 2);
      expect(r.files, isEmpty);
    });
  });
}
