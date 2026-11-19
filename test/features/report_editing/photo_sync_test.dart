import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/photo_sync_service.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';
const _r1 = '11111111-1111-4111-8111-111111111111';
const _r2 = '22222222-2222-4222-8222-222222222222';
const _r3 = '33333333-3333-4333-8333-333333333333';

class _Local implements LocalPhotos {
  _Local(this.dir);
  final Directory dir;
  final rows = <String, LocalPhoto>{};
  final removed = <String>[];
  int n = 0;

  @override
  Future<List<LocalPhoto>> forSurvey(String surveyId) async => rows.values.where((r) => r.surveyId == surveyId).toList();
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
    removed.add(id);
    final f = File(rows[id]!.localPath);
    if (f.existsSync()) f.deleteSync();
    rows.remove(id);
  }

  @override
  Future<String> newFilePath(String surveyId, String extension) async => '${dir.path}/photo_${n++}.$extension';

  LocalPhoto add(String id, {String? remote, String section = 'roof', String? caption, int order = 0, bool synced = true, List<dynamic>? drawing}) {
    final f = File('${dir.path}/own_$id.jpg')..writeAsBytesSync([1, 2, 3]);
    return rows[id] = LocalPhoto(id: id, surveyId: _survey, sectionId: section, localPath: f.path, remoteId: remote, caption: caption, sortOrder: order, synced: synced, annotations: drawing);
  }
}

class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());
  List<CloudPhoto> list = [];
  final downloads = <String>[];
  final assigns = <Map<String, dynamic>>[];
  Set<String> failDownloads = {};
  ReportEditingException? assignError;
  int version = 7;
  final drawings = <String, List<dynamic>>{};
  ReportEditingException? drawingError;

  @override
  Future<void> putAnnotations(String surveyId, String remoteId, List<dynamic> elements) async {
    if (drawingError != null) throw drawingError!;
    drawings[remoteId] = elements;
  }

  @override
  Future<CloudPhotos> photos(String surveyId, {bool includeDeleted = false}) async => CloudPhotos(version: version, photos: includeDeleted ? list : list.where((p) => !p.deleted).toList());

  @override
  Future<List<int>> downloadPhoto(String remoteId) async {
    downloads.add(remoteId);
    if (failDownloads.contains(remoteId)) throw const ReportEditingException(code: 'RATE_LIMITED', message: 'x', status: 429);
    return [9, 9, 9, 9];
  }

  @override
  Future<({int version, int changed})> assignPhotos(String surveyId, {required int expectedVersion, required List<Map<String, dynamic>> items}) async {
    if (assignError != null) throw assignError!;
    assigns.add({'expected': expectedVersion, 'items': items});
    return (version: expectedVersion + 1, changed: items.length);
  }
}

CloudPhoto _c(String id, {String? caption, String? section, int order = 0, bool deleted = false, String mime = 'image/jpeg'}) =>
    CloudPhoto(id: id, fileName: '$id.jpg', mimeType: mime, size: 4, caption: caption, sectionKey: section, sortOrder: order, deleted: deleted);

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 16),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [
        ReportSection(key: 'E', title: 'Outside', description: '', displayOrder: 0, screens: [
          ReportScreen(screenId: 'roof', title: 'Roof', fields: [], phrases: ['x']),
          ReportScreen(screenId: 'chimney', title: 'Chimney', fields: [], phrases: ['y']),
        ]),
      ],
    );

void main() {
  late Directory dir;
  late _Local local;
  late _Cloud cloud;
  late PhotoSyncService sync;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('photo_sync_');
    local = _Local(dir);
    cloud = _Cloud();
    sync = PhotoSyncService(api: cloud, local: local, pause: Duration.zero);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('ids and sections', () {
    test('the cloud id is read from the remote path the app already stores', () {
      expect(PhotoSyncService.remoteIdOf('/media/$_r1/file'), _r1);
      expect(PhotoSyncService.remoteIdOf('media/$_r1/file'), _r1);
      expect(PhotoSyncService.remoteIdOf(null), isNull);
      expect(PhotoSyncService.remoteIdOf('/somewhere/else.jpg'), isNull);
    });

    test('a cloud section key maps to the screen id, none to "unassigned"', () {
      expect(PhotoSyncService.sectionIdOf('E/roof'), 'roof');
      expect(PhotoSyncService.sectionIdOf('ACCOMMODATION'), 'ACCOMMODATION');
      expect(PhotoSyncService.sectionIdOf(null), 'unassigned');
      expect(PhotoSyncService.sectionIdOf(''), 'unassigned');
    });
  });

  group('pull (Synchronise)', () {
    test('a photo added in the browser is downloaded and appears like any other photo', () async {
      cloud.list = [_c(_r1, caption: 'Rear slope', section: 'E/roof', order: 2)];
      final s = await sync.pull(_survey);
      expect(s.added, 1);
      expect(cloud.downloads, [_r1]);
      final row = local.rows.values.single;
      expect(row.remoteId, _r1);
      expect(row.sectionId, 'roof');
      expect(row.caption, 'Rear slope');
      expect(row.sortOrder, 2);
      expect(row.synced, isTrue);
      expect(File(row.localPath).readAsBytesSync(), [9, 9, 9, 9]);
      expect(row.localPath, endsWith('.jpg'));
    });

    test('a PNG keeps its extension; a photo with no section is "unassigned"', () async {
      cloud.list = [_c(_r1, mime: 'image/png')];
      await sync.pull(_survey);
      expect(local.rows.values.single.localPath, endsWith('.png'));
      expect(local.rows.values.single.sectionId, 'unassigned');
    });

    test('a second Synchronise changes nothing and downloads nothing again', () async {
      cloud.list = [_c(_r1, caption: 'A', section: 'E/roof')];
      await sync.pull(_survey);
      cloud.downloads.clear();
      final s = await sync.pull(_survey);
      expect(s.changedAnything, isFalse);
      expect(cloud.downloads, isEmpty);
      expect(local.rows, hasLength(1));
    });

    test('caption, order and section changes made in the browser reach photos the phone already has', () async {
      local.add('mine', remote: _r1, section: 'roof', caption: 'Old', order: 0);
      cloud.list = [_c(_r1, caption: 'New caption', section: 'E/chimney', order: 3)];
      final s = await sync.pull(_survey);
      expect(s.updated, 1);
      expect(cloud.downloads, isEmpty);
      expect(local.rows['mine'], isA<LocalPhoto>().having((p) => p.caption, 'caption', 'New caption').having((p) => p.sectionId, 'section', 'chimney').having((p) => p.sortOrder, 'order', 3));
    });

    test('a caption removed in the browser is removed on the phone', () async {
      local.add('mine', remote: _r1, caption: 'Gone soon');
      cloud.list = [_c(_r1, section: 'E/roof')];
      await sync.pull(_survey);
      expect(local.rows['mine']!.caption, isNull);
    });

    test('a photo deleted in the browser is deleted on the phone, with its file', () async {
      final mine = local.add('mine', remote: _r1);
      cloud.list = [_c(_r1, deleted: true)];
      final s = await sync.pull(_survey);
      expect(s.removed, 1);
      expect(local.rows, isEmpty);
      expect(File(mine.localPath).existsSync(), isFalse);
    });

    test('a deleted photo the phone never had is ignored; a replaced photo swaps the picture', () async {
      local.add('old', remote: _r1, caption: 'Chimney', section: 'roof', order: 1);
      cloud.list = [_c(_r1, deleted: true), _c(_r2, caption: 'Chimney', section: 'E/roof', order: 1), _c(_r3, deleted: true)];
      final s = await sync.pull(_survey);
      expect((s.added, s.removed), (1, 1));
      expect(local.rows.values.single.remoteId, _r2);
      expect(local.removed, ['old']);
    });

    test('photos only on the phone (not uploaded yet) are left alone', () async {
      local.add('local-only', synced: false);
      cloud.list = [];
      final s = await sync.pull(_survey);
      expect(s.changedAnything, isFalse);
      expect(local.rows.keys, ['local-only']);
    });

    test('a download that fails is counted, the others still come, and the next Synchronise tries again', () async {
      cloud.list = [_c(_r1), _c(_r2), _c(_r3)];
      cloud.failDownloads = {_r2};
      final s = await sync.pull(_survey);
      expect((s.added, s.failed), (2, 1));
      expect(s.describe(), '2 photos added, 1 could not be downloaded');
      cloud.failDownloads = {};
      final again = await sync.pull(_survey);
      expect(again.added, 1);
      expect(local.rows, hasLength(3));
    });

    test('the summary reads well', () {
      expect(const PhotoSyncSummary(added: 1).describe(), '1 photo added');
      expect(const PhotoSyncSummary(added: 2, updated: 1, removed: 3).describe(), '2 photos added, 1 updated, 3 removed');
    });
  });

  group('push (file the phone\'s photos under report sections)', () {
    test('uploaded photos are filed under the screen they belong to, with caption and order', () {
      final photos = [
        local.add('a', remote: _r1, section: 'roof', caption: '  Ridge ', order: 0),
        local.add('b', remote: _r2, section: 'chimney', order: 1),
        local.add('c', remote: _r3, section: 'unknown-screen', order: 2),
        local.add('d', synced: false), // not uploaded yet: left for later
      ];
      final items = sync.assignmentsFor(_doc(), photos);
      expect(items, [
        {'id': _r1, 'sectionKey': 'E/roof', 'caption': 'Ridge', 'sortOrder': 0},
        {'id': _r2, 'sectionKey': 'E/chimney', 'sortOrder': 1},
        {'id': _r3, 'sortOrder': 2},
      ]);
    });

    test('sends them against the version just uploaded and returns the new one', () async {
      local.add('a', remote: _r1, section: 'roof');
      expect(await sync.push(_survey, _doc(), 4), 5);
      expect(cloud.assigns.single['expected'], 4);
    });

    test('a drawing made on a synced photo is sent with it; photos without one, or not uploaded yet, send nothing', () async {
      final drawing = [
        {'type': 'arrow', 'x1': 0.1, 'y1': 0.2}
      ];
      local.add('a', remote: _r1, section: 'roof', drawing: drawing);
      local.add('b', remote: _r2, section: 'roof');
      local.add('c', synced: false, drawing: drawing);
      await sync.push(_survey, _doc(), 4);
      expect(cloud.drawings.keys, [_r1]);
      expect(cloud.drawings[_r1], drawing);
    });

    test('a drawing that cannot be sent (finalised, newer on a computer, offline) never blocks the report', () async {
      local.add('a', remote: _r1, section: 'roof', drawing: [
        {'type': 'text', 'text': 'x'}
      ]);
      cloud.drawingError = const ReportEditingException(code: 'REPORT_FINALISED', message: 'x', status: 403);
      expect(await sync.push(_survey, _doc(), 4), 5);
      expect(cloud.drawings, isEmpty);
    });

    test('nothing to send means no request', () async {
      local.add('d', synced: false);
      expect(await sync.push(_survey, _doc(), 4), isNull);
      expect(cloud.assigns, isEmpty);
    });

    test('a newer cloud version or no connection is not an error: it is tried again at the next send', () async {
      local.add('a', remote: _r1, section: 'roof');
      cloud.assignError = const ReportEditingException(code: 'VERSION_CONFLICT', message: 'x', status: 409, serverVersion: 9);
      expect(await sync.push(_survey, _doc(), 4), isNull);
      cloud.assignError = const ReportEditingException(code: 'NETWORK', message: 'x');
      expect(await sync.push(_survey, _doc(), 4), isNull);
      cloud.assignError = const ReportEditingException(code: 'FORBIDDEN', message: 'x', status: 403);
      await expectLater(sync.push(_survey, _doc(), 4), throwsA(isA<ReportEditingException>()));
    });
  });
}
