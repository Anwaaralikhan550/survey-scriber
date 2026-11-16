import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';

/// Answers each request from a table, so no network is needed.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final (int, Map<String, dynamic>) Function(RequestOptions o) respond;
  final calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    final (status, body) = respond(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryVault implements LinkVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

ReportEditingApi _api(_Adapter a) => ReportEditingApi(Dio(BaseOptions(baseUrl: 'http://test/api/v1/'))..httpClientAdapter = a);

void main() {
  group('ReportEditingApi', () {
    test('uploads the snapshot to the right address with the base version', () async {
      final a = _Adapter((o) => (200, {'reportId': 'r', 'version': 4, 'updatedAt': '2026-11-16T10:00:00.000Z'}));
      final info = await _api(a).uploadSnapshot('s1', baseVersion: 3, reportType: 'L2', sections: const []);
      expect(info.version, 4);
      final call = a.calls.single;
      expect(call.method, 'PUT');
      expect(call.uri.path, '/api/v1/reports/s1/snapshot');
      expect(call.data, {'baseVersion': 3, 'reportType': 'L2', 'content': <dynamic>[]});
    });

    test('the first upload sends no base version', () async {
      final a = _Adapter((o) => (200, {'version': 1, 'updatedAt': '2026-11-16T10:00:00.000Z'}));
      await _api(a).uploadSnapshot('s1', reportType: 'VALUATION', sections: const []);
      expect((a.calls.single.data as Map).containsKey('baseVersion'), isFalse);
    });

    test('a version conflict carries the code and the cloud version', () async {
      final a = _Adapter((o) => (409, {'error': 'VERSION_CONFLICT', 'message': 'newer', 'details': {'serverVersion': 7}}));
      await expectLater(
        _api(a).uploadSnapshot('s1', baseVersion: 3, reportType: 'L2', sections: const []),
        throwsA(isA<ReportEditingException>().having((e) => e.isConflict, 'conflict', true).having((e) => e.serverVersion, 'version', 7)),
      );
    });

    test('creates a link and reads its address and expiry', () async {
      final a = _Adapter((o) => (201, {'linkId': 'l1', 'url': 'https://editor.example/open/abc', 'expiresAt': '2026-11-19T10:00:00.000Z', 'policy': 'single-live-link'}));
      final link = await _api(a).createLink('s1');
      expect(link.url, 'https://editor.example/open/abc');
      expect(link.expiresAt, DateTime.utc(2026, 11, 19, 10));
      expect(a.calls.single.uri.path, '/api/v1/reports/s1/edit-links');
    });

    test('an active link already live is reported by its code', () async {
      final a = _Adapter((o) => (409, {'error': 'ACTIVE_LINK_EXISTS', 'message': 'live'}));
      await expectLater(_api(a).createLink('s1'), throwsA(isA<ReportEditingException>().having((e) => e.code, 'code', 'ACTIVE_LINK_EXISTS')));
    });

    test('current link: none, and live', () async {
      expect((await _api(_Adapter((o) => (200, {'active': false}))).currentLink('s1')).active, isFalse);
      final live = await _api(_Adapter((o) => (200, {'active': true, 'linkId': 'l', 'expiresAt': '2026-11-19T10:00:00.000Z'}))).currentLink('s1');
      expect(live.active, isTrue);
      expect(live.linkId, 'l');
    });

    test('cancel sends DELETE for that link', () async {
      final a = _Adapter((o) => (200, {'linkId': 'l9', 'status': 'CANCELLED'}));
      await _api(a).cancelLink('s1', 'l9');
      expect(a.calls.single.method, 'DELETE');
      expect(a.calls.single.uri.path, '/api/v1/reports/s1/edit-links/l9');
    });

    test('latest is null when the survey has no cloud report yet', () async {
      final a = _Adapter((o) => (404, {'error': 'NOT_FOUND', 'message': 'Report not found'}));
      expect(await _api(a).latest('s1'), isNull);
      final b = _Adapter((o) => (200, {'reportId': 's1', 'version': 5, 'status': 'DRAFT', 'updatedAt': '2026-11-16T10:00:00.000Z'}));
      expect((await _api(b).latest('s1'))!.version, 5);
    });

    test('sync returns the version and the sections', () async {
      final a = _Adapter((o) => (200, {'version': 6, 'status': 'DRAFT', 'content': [{'id': 'x', 'key': 'E/roof', 'title': 'Roof', 'blocks': []}]}));
      final s = await _api(a).sync('s1');
      expect(s.version, 6);
      expect(s.sections.single['key'], 'E/roof');
      expect(a.calls.single.method, 'POST');
    });

    test('a dropped connection is NETWORK, a 401 is UNAUTHORIZED', () async {
      final dead = ReportEditingApi(Dio(BaseOptions(baseUrl: 'http://127.0.0.1:1/api/v1/', connectTimeout: const Duration(milliseconds: 300))));
      await expectLater(dead.latest('s1'), throwsA(isA<ReportEditingException>().having((e) => e.isNetwork, 'network', true)));
      final a = _Adapter((o) => (401, {'message': 'Invalid access token'}));
      await expectLater(_api(a).sync('s1'), throwsA(isA<ReportEditingException>().having((e) => e.code, 'code', 'UNAUTHORIZED')));
    });
  });

  group('DesktopEditStore', () {
    late Directory dir;
    late _MemoryVault vault;
    late DesktopEditStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('desk_edit_');
      vault = _MemoryVault();
      store = DesktopEditStore(directory: () async => dir, vault: vault);
    });
    tearDown(() => dir.delete(recursive: true));

    test('nothing stored yet', () async {
      final r = await store.read('s1');
      expect(r.appVersion, isNull);
      expect(r.hasEdits, isFalse);
    });

    test('upload remembers the version; sync adds the edits; a later upload keeps them', () async {
      await store.saveUploaded('s1', 1);
      expect((await store.read('s1')).appVersion, 1);
      await store.saveSynced('s1', 4, [{'key': 'E/roof', 'blocks': []}]);
      var r = await store.read('s1');
      expect(r.appVersion, 4);
      expect(r.syncedSections!.single['key'], 'E/roof');
      await store.saveUploaded('s1', 5);
      r = await store.read('s1');
      expect(r.appVersion, 5);
      expect(r.hasEdits, isTrue);
    });

    test('clearing the edits keeps the version', () async {
      await store.saveSynced('s1', 4, [{'key': 'a'}]);
      await store.clearEdits('s1');
      final r = await store.read('s1');
      expect(r.appVersion, 4);
      expect(r.hasEdits, isFalse);
    });

    test('surveys do not share state', () async {
      await store.saveUploaded('s1', 2);
      expect((await store.read('s2')).appVersion, isNull);
    });

    test('a damaged file reads as empty instead of crashing', () async {
      await File('${dir.path}/desktop_edit_s1.json').writeAsString('{not json');
      expect((await store.read('s1')).appVersion, isNull);
    });

    test('forget removes the file and the saved link', () async {
      await store.saveUploaded('s1', 2);
      await vault.write('s1', 'https://x/open/y');
      await store.forget('s1');
      expect((await store.read('s1')).appVersion, isNull);
      expect(await vault.read('s1'), isNull);
    });

    test('no half-written temp file is left behind', () async {
      await store.saveUploaded('s1', 2);
      expect(dir.listSync().where((e) => e.path.endsWith('.tmp')), isEmpty);
    });
  });
}
