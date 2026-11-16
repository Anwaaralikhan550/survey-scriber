import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/photo_sync_service.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_controller.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';
const _remote = '11111111-1111-4111-8111-111111111111';

class _Vault implements LinkVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

class _Local implements LocalPhotos {
  _Local(this.dir);
  final Directory dir;
  final rows = <String, LocalPhoto>{};
  @override
  Future<List<LocalPhoto>> forSurvey(String surveyId) async => rows.values.toList();
  @override
  Future<void> insert(LocalPhoto photo, {required int fileSize}) async => rows[photo.id] = photo;
  @override
  Future<void> update(String id, {String? caption, int? sortOrder, String? sectionId}) async {}
  @override
  Future<void> delete(String id) async => rows.remove(id);
  @override
  Future<String> newFilePath(String surveyId, String extension) async => '${dir.path}/p_${rows.length}.$extension';
}

class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());
  int? version;
  String? linkId;
  List<CloudPhoto> photoList = [];
  int assignBump = 1;
  final assigned = <List<Map<String, dynamic>>>[];

  @override
  Future<CloudReportInfo> uploadSnapshot(String surveyId, {int? baseVersion, required String reportType, required List<Map<String, dynamic>> sections}) async {
    version = (version ?? 0) + 1;
    return CloudReportInfo(version: version!, status: 'DRAFT', updatedAt: DateTime(2026, 11, 16));
  }

  @override
  Future<EditLinkInfo> createLink(String surveyId) async {
    linkId = 'l1';
    return EditLinkInfo(linkId: 'l1', url: 'https://e/open/t', expiresAt: DateTime.now().add(const Duration(hours: 72)));
  }

  @override
  Future<CurrentLink> currentLink(String surveyId) async => CurrentLink(active: linkId != null, linkId: linkId, expiresAt: DateTime.now().add(const Duration(hours: 70)));
  @override
  Future<CloudReportInfo?> latest(String surveyId) async => version == null ? null : CloudReportInfo(version: version!, status: 'DRAFT', updatedAt: DateTime(2026, 11, 16));
  @override
  Future<SyncedReport> sync(String surveyId) async => SyncedReport(version: version!, status: 'DRAFT', sections: const []);
  @override
  Future<CloudPhotos> photos(String surveyId, {bool includeDeleted = false}) async => CloudPhotos(version: version!, photos: photoList);
  @override
  Future<List<int>> downloadPhoto(String remoteId) async => [1, 2, 3];
  @override
  Future<({int version, int changed})> assignPhotos(String surveyId, {required int expectedVersion, required List<Map<String, dynamic>> items}) async {
    assigned.add(items);
    version = expectedVersion + assignBump;
    return (version: version!, changed: items.length);
  }
}

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 16),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [
        ReportSection(key: 'E', title: 'Outside', description: '', displayOrder: 0, screens: [
          ReportScreen(screenId: 'roof', title: 'Roof', fields: [], phrases: ['The roof is tiled.']),
        ]),
      ],
    );

void main() {
  late Directory dir;
  late _Cloud cloud;
  late _Local local;
  late DesktopEditStore store;
  late DesktopEditingController c;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('desk_photos_ctl_');
    cloud = _Cloud();
    local = _Local(dir);
    store = DesktopEditStore(directory: () async => dir, vault: _Vault());
    c = DesktopEditingController(
      surveyId: _survey,
      reportType: 'L2',
      api: cloud,
      store: store,
      buildDocument: () async => _doc(),
      photos: PhotoSyncService(api: cloud, local: local, pause: Duration.zero),
    );
  });
  tearDown(() async {
    c.dispose();
    await dir.delete(recursive: true);
  });

  test('Generate link also files the phone\'s uploaded photos, and the phone keeps the version that includes it', () async {
    local.rows['a'] = const LocalPhoto(id: 'a', surveyId: _survey, sectionId: 'roof', localPath: 'x', remoteId: _remote, caption: 'Ridge', synced: true);
    await c.refresh();
    await c.generateLink();
    expect(c.state.error, isNull);
    expect(cloud.assigned.single.single, {'id': _remote, 'sectionKey': 'E/roof', 'caption': 'Ridge', 'sortOrder': 0});
    expect(cloud.version, 2); // the report upload (1) and the photo filing (2)
    expect(c.state.cloudVersion, 2);
    expect(c.state.appVersion, 2);
    expect(c.state.updateAvailable, isFalse);
    expect((await store.read(_survey)).appVersion, 2);
  });

  test('with no uploaded photos the version stays what the report upload made it', () async {
    await c.refresh();
    await c.generateLink();
    expect(cloud.assigned, isEmpty);
    expect(c.state.appVersion, 1);
  });

  test('Synchronise brings the browser\'s photos and says so', () async {
    await c.refresh();
    await c.generateLink();
    cloud.photoList = [
      CloudPhoto(id: _remote, fileName: 'a.jpg', mimeType: 'image/jpeg', size: 3, caption: 'New', sectionKey: 'E/roof', sortOrder: 0, deleted: false),
    ];
    await c.synchronise();
    expect(local.rows.values.single.remoteId, _remote);
    expect(c.state.notice, contains('Photos: 1 photo added'));
    expect(c.state.error, isNull);
  });

  test('Synchronise with no photo changes keeps the normal message', () async {
    await c.refresh();
    await c.generateLink();
    await c.synchronise();
    expect(c.state.notice, 'Synchronised. Your PDF and Word reports now use the edited wording.');
  });
}
