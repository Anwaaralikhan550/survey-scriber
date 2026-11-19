import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/media_dao.dart';
import 'photo_sync_service.dart';

/// [LocalPhotos] on the app's media table: the same rows the camera and gallery use, so photos that come
/// from the browser show up in the app, and in the PDF and Word reports, like any other.
class MediaDaoPhotos implements LocalPhotos {
  MediaDaoPhotos(this._dao, this._mediaDir);

  final MediaDao _dao;
  final Future<Directory> Function() _mediaDir;

  @override
  Future<List<LocalPhoto>> forSurvey(String surveyId) async {
    final rows = await _dao.getMediaBySurvey(surveyId);
    final out = <LocalPhoto>[];
    for (final r in rows) {
      if (r.mediaType != 'photo') continue;
      List<dynamic>? drawing;
      if (r.hasAnnotations) {
        final a = await _dao.getAnnotation(r.id);
        if (a != null) drawing = jsonDecode(a.elementsJson) as List<dynamic>;
      }
      out.add(
        LocalPhoto(
          id: r.id,
          surveyId: r.surveyId,
          sectionId: r.sectionId,
          localPath: r.localPath,
          remoteId: PhotoSyncService.remoteIdOf(r.remotePath),
          caption: r.caption,
          sortOrder: r.sortOrder,
          synced: r.status == 'synced',
          annotations: drawing,
        ),
      );
    }
    return out;
  }

  @override
  Future<void> insert(LocalPhoto photo, {required int fileSize}) async {
    await _dao.insertMedia(
      MediaItemsCompanion.insert(
        id: photo.id,
        surveyId: photo.surveyId,
        sectionId: photo.sectionId,
        mediaType: 'photo',
        localPath: photo.localPath,
        createdAt: DateTime.now(),
        remotePath: Value(photo.remoteId == null ? null : '/media/${photo.remoteId}/file'),
        caption: Value(photo.caption),
        status: Value(photo.synced ? 'synced' : 'local'),
        fileSize: Value(fileSize),
        sortOrder: Value(photo.sortOrder),
      ),
    );
  }

  @override
  Future<void> update(String id, {String? caption, int? sortOrder, String? sectionId}) async {
    await (_dao.update(_dao.mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        caption: caption == null ? const Value.absent() : Value(caption.isEmpty ? null : caption),
        sortOrder: sortOrder == null ? const Value.absent() : Value(sortOrder),
        sectionId: sectionId == null ? const Value.absent() : Value(sectionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    final row = await _dao.getMediaById(id);
    await _dao.deleteAnnotation(id);
    await _dao.deleteMedia(id);
    if (row != null) {
      final f = File(row.localPath);
      if (await f.exists()) await f.delete();
    }
  }

  @override
  Future<String> newFilePath(String surveyId, String extension) async => photoPathIn(await _mediaDir(), surveyId, extension);
}
