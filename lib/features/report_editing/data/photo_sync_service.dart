import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../report_export/domain/models/report_document.dart';
import '../domain/report_blocks_mapper.dart';
import 'report_editing_api.dart';

/// A photo as the phone keeps it.
class LocalPhoto {
  const LocalPhoto({
    required this.id,
    required this.surveyId,
    required this.sectionId,
    required this.localPath,
    this.remoteId,
    this.caption,
    this.sortOrder = 0,
    this.synced = false,
    this.annotations,
  });

  final String id;
  final String surveyId;
  final String sectionId;
  final String localPath;

  /// The id of the same photo in the cloud, once it has been uploaded or downloaded.
  final String? remoteId;
  final String? caption;
  final int sortOrder;
  final bool synced;

  /// The drawing made on the photo (the elements as plain data), when there is one.
  final List<dynamic>? annotations;
}

/// The phone's photo records and files, as the photo sync needs them (backed by the media table in the app).
abstract class LocalPhotos {
  Future<List<LocalPhoto>> forSurvey(String surveyId);
  Future<void> insert(LocalPhoto photo, {required int fileSize});
  Future<void> update(String id, {String? caption, int? sortOrder, String? sectionId});

  /// Removes the record, its annotations and the file.
  Future<void> delete(String id);
  Future<String> newFilePath(String surveyId, String extension);
}

class PhotoSyncSummary {
  const PhotoSyncSummary({this.added = 0, this.updated = 0, this.removed = 0, this.failed = 0});
  final int added;
  final int updated;
  final int removed;

  /// Photos that could not be downloaded (they are tried again at the next Synchronise).
  final int failed;

  bool get changedAnything => added + updated + removed > 0;

  String describe() {
    final parts = <String>[
      if (added > 0) '$added photo${added == 1 ? '' : 's'} added',
      if (updated > 0) '$updated updated',
      if (removed > 0) '$removed removed',
      if (failed > 0) '$failed could not be downloaded',
    ];
    return parts.join(', ');
  }
}

/// Keeps the phone's photos and the cloud's in step (spec section 9): photos added, replaced, captioned,
/// re-ordered or deleted in the browser reach the phone at Synchronise, and the phone files its own photos
/// under report sections when it sends the report.
class PhotoSyncService {
  PhotoSyncService({required this.api, required this.local, this.pause = const Duration(milliseconds: 400)});

  final ReportEditingApi api;
  final LocalPhotos local;

  /// The API allows a few requests a second; photo downloads are spaced out.
  final Duration pause;

  static const unassigned = 'unassigned';
  static const _uuid = Uuid();
  static final _remoteIdPattern = RegExp(r'/?media/([0-9a-fA-F-]{36})/file');

  /// `/media/<id>/file` is how the app remembers where an uploaded photo lives in the cloud.
  static String? remoteIdOf(String? remotePath) => remotePath == null ? null : _remoteIdPattern.firstMatch(remotePath)?.group(1);

  /// The report screen id a cloud section key stands for (`E/roof` -> `roof`).
  static String sectionIdOf(String? sectionKey) {
    if (sectionKey == null || sectionKey.isEmpty) return unassigned;
    final at = sectionKey.indexOf('/');
    return at < 0 ? sectionKey : sectionKey.substring(at + 1);
  }

  /// Take the cloud's photos: download new ones, apply caption/order/section changes, remove deleted ones.
  Future<PhotoSyncSummary> pull(String surveyId) async {
    final cloud = await api.photos(surveyId, includeDeleted: true);
    final mine = await local.forSurvey(surveyId);
    final byRemote = {for (final m in mine) if (m.remoteId != null) m.remoteId!: m};
    var added = 0, updated = 0, removed = 0, failed = 0;
    for (final c in cloud.photos) {
      final have = byRemote[c.id];
      if (c.deleted) {
        if (have != null) {
          await local.delete(have.id);
          removed++;
        }
        continue;
      }
      final section = sectionIdOf(c.sectionKey);
      if (have != null) {
        final changed = (have.caption ?? '') != (c.caption ?? '') || have.sortOrder != c.sortOrder || have.sectionId != section;
        if (changed) {
          await local.update(have.id, caption: c.caption ?? '', sortOrder: c.sortOrder, sectionId: section);
          updated++;
        }
        continue;
      }
      try {
        if (added + failed > 0) await Future<void>.delayed(pause);
        final bytes = await api.downloadPhoto(c.id);
        final path = await local.newFilePath(surveyId, c.mimeType == 'image/png' ? 'png' : 'jpg');
        await File(path).writeAsBytes(bytes, flush: true);
        await local.insert(
          LocalPhoto(
            id: _uuid.v4(),
            surveyId: surveyId,
            sectionId: section,
            localPath: path,
            remoteId: c.id,
            caption: c.caption,
            sortOrder: c.sortOrder,
            synced: true,
          ),
          fileSize: bytes.length,
        );
        added++;
      } on ReportEditingException {
        failed++;
      } on FileSystemException {
        failed++;
      }
    }
    return PhotoSyncSummary(added: added, updated: updated, removed: removed, failed: failed);
  }

  /// The phone's uploaded photos filed under the report screens they were taken for.
  List<Map<String, dynamic>> assignmentsFor(ReportDocument doc, List<LocalPhoto> photos) {
    final keyByScreen = <String, String>{
      for (final s in doc.sections) for (final sc in s.screens) sc.screenId: ReportBlocksMapper.sectionKeyFor(s.key, sc.screenId),
    };
    return [
      for (final ph in photos)
        if (ph.synced && ph.remoteId != null)
          {
            'id': ph.remoteId,
            if (keyByScreen[ph.sectionId] != null) 'sectionKey': keyByScreen[ph.sectionId],
            if ((ph.caption ?? '').trim().isNotEmpty) 'caption': ph.caption!.trim(),
            'sortOrder': ph.sortOrder,
          },
    ];
  }

  /// The drawings made on photos are kept in the cloud with the photo. A failure never blocks the report: the next send tries again.
  Future<void> pushAnnotations(String surveyId, List<LocalPhoto> photos) async {
    for (final ph in photos) {
      final drawing = ph.annotations;
      if (!ph.synced || ph.remoteId == null || drawing == null || drawing.isEmpty) continue;
      try {
        await api.putAnnotations(surveyId, ph.remoteId!, drawing);
      } on ReportEditingException {
        // finalised, newer on a computer, or offline: left for the next send
      }
    }
  }

  /// After the report is sent: file the phone's photos under sections. Returns the new cloud version, or null
  /// when there was nothing to do or the cloud moved meanwhile (the next send tries again).
  Future<int?> push(String surveyId, ReportDocument doc, int expectedVersion) async {
    final photos = await local.forSurvey(surveyId);
    await pushAnnotations(surveyId, photos);
    final items = assignmentsFor(doc, photos);
    if (items.isEmpty) return null;
    try {
      final r = await api.assignPhotos(surveyId, expectedVersion: expectedVersion, items: items);
      return r.changed > 0 ? r.version : null;
    } on ReportEditingException catch (e) {
      if (e.isConflict || e.isNetwork) return null;
      rethrow;
    }
  }
}

/// Where a downloaded photo is written, next to the others the app keeps.
Future<String> photoPathIn(Directory mediaDir, String surveyId, String extension) async {
  final dir = Directory(p.join(mediaDir.path, surveyId));
  if (!await dir.exists()) await dir.create(recursive: true);
  return p.join(dir.path, 'photo_${const Uuid().v4()}.$extension');
}

/// Size check for tests and callers that hold bytes.
int sizeOf(Uint8List bytes) => bytes.length;
