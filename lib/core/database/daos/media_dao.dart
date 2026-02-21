import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/media/domain/entities/media_item.dart';
import '../../../features/media/domain/entities/photo_annotation.dart';
import '../app_database.dart';
import '../tables/media_items_table.dart';

part 'media_dao.g.dart';

@DriftAccessor(tables: [MediaItems, PhotoAnnotations])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.db);

  // ============= Media Items =============

  /// Get all media items for a survey
  Future<List<MediaItemsData>> getMediaBySurvey(String surveyId) => (select(mediaItems)
          ..where((t) => t.surveyId.equals(surveyId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sectionId),
            (t) => OrderingTerm.asc(t.sortOrder),
          ]))
        .get();

  /// Get all media items for a section
  Future<List<MediaItemsData>> getMediaBySection(String sectionId) => (select(mediaItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

  /// Get all photos for a section
  Future<List<MediaItemsData>> getPhotosBySection(String sectionId) => (select(mediaItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..where((t) => t.mediaType.equals('photo'))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

  /// Get all audio items for a section
  Future<List<MediaItemsData>> getAudioBySection(String sectionId) => (select(mediaItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..where((t) => t.mediaType.equals('audio'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

  /// Get all video items for a section
  Future<List<MediaItemsData>> getVideoBySection(String sectionId) => (select(mediaItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..where((t) => t.mediaType.equals('video'))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

  /// Get a single media item by ID
  Future<MediaItemsData?> getMediaById(String id) => (select(mediaItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

  /// Insert a new media item
  Future<int> insertMedia(MediaItemsCompanion media) => into(mediaItems).insert(media);

  /// Update a media item
  Future<bool> updateMedia(MediaItemsCompanion media) => (update(mediaItems)..where((t) => t.id.equals(media.id.value)))
        .write(media)
        .then((rows) => rows > 0);

  /// Delete a media item
  Future<int> deleteMedia(String id) => (delete(mediaItems)..where((t) => t.id.equals(id))).go();

  /// Delete all media for a survey
  Future<int> deleteMediaBySurvey(String surveyId) => (delete(mediaItems)..where((t) => t.surveyId.equals(surveyId))).go();

  /// Delete all media for a section
  Future<int> deleteMediaBySection(String sectionId) => (delete(mediaItems)..where((t) => t.sectionId.equals(sectionId)))
        .go();

  /// Update media caption
  Future<void> updateCaption(String id, String? caption) => (update(mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        caption: Value(caption),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Update media sort order
  Future<void> updateSortOrder(String id, int sortOrder) => (update(mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Update media sync status
  Future<void> updateStatus(String id, MediaStatus status) => (update(mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        status: Value(status.name),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Get all pending (local-only) media items for a survey
  Future<List<MediaItemsData>> getPendingUploads(String surveyId) async => (select(mediaItems)
          ..where((t) => t.surveyId.equals(surveyId))
          ..where((t) => t.status.equals(MediaStatus.local.name)))
        .get();

  /// Get ALL pending (local-only) media items across all surveys
  Future<List<MediaItemsData>> getAllPendingUploads() async => (select(mediaItems)
          ..where((t) => t.status.equals(MediaStatus.local.name)))
        .get();

  /// Mark media as synced with remote path
  Future<void> markAsSynced(String id, {required String remotePath}) => (update(mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(
        status: Value(MediaStatus.synced.name),
        remotePath: Value(remotePath),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Mark photo as having annotations
  Future<void> setHasAnnotations(String photoId, bool hasAnnotations) => (update(mediaItems)..where((t) => t.id.equals(photoId))).write(
      MediaItemsCompanion(
        hasAnnotations: Value(hasAnnotations),
        updatedAt: Value(DateTime.now()),
      ),
    );

  /// Get count of media items by type for a section
  Future<int> getMediaCount(String sectionId, MediaType type) async {
    final query = selectOnly(mediaItems)
      ..addColumns([mediaItems.id.count()])
      ..where(mediaItems.sectionId.equals(sectionId))
      ..where(mediaItems.mediaType.equals(type.name));

    final result = await query.getSingle();
    return result.read(mediaItems.id.count()) ?? 0;
  }

  /// Get total media count for a survey
  Future<({int photos, int audio, int video})> getMediaCountsBySurvey(
      String surveyId,) async {
    final items = await getMediaBySurvey(surveyId);

    return (
      photos: items.where((i) => i.mediaType == 'photo').length,
      audio: items.where((i) => i.mediaType == 'audio').length,
      video: items.where((i) => i.mediaType == 'video').length,
    );
  }

  /// Watch media items for a section
  Stream<List<MediaItemsData>> watchMediaBySection(String sectionId) => (select(mediaItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();

  /// Watch photos for a section
  Stream<List<MediaItemsData>> watchPhotosBySection(String sectionId) => (select(mediaItems)
          ..where((t) => t.sectionId.equals(sectionId))
          ..where((t) => t.mediaType.equals('photo'))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();

  // ============= Photo Annotations =============

  /// Get annotation for a photo
  Future<PhotoAnnotationsData?> getAnnotation(String photoId) => (select(photoAnnotations)
          ..where((t) => t.photoId.equals(photoId)))
        .getSingleOrNull();

  /// Save or update annotation
  Future<void> saveAnnotation({
    required String id,
    required String photoId,
    required List<AnnotationElement> elements,
    String? annotatedImagePath,
  }) async {
    final elementsJson = jsonEncode(elements.map((e) => e.toJson()).toList());

    final existing = await getAnnotation(photoId);

    if (existing != null) {
      await (update(photoAnnotations)
            ..where((t) => t.photoId.equals(photoId)))
          .write(
        PhotoAnnotationsCompanion(
          elementsJson: Value(elementsJson),
          annotatedImagePath: Value(annotatedImagePath),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(photoAnnotations).insert(
        PhotoAnnotationsCompanion.insert(
          id: id,
          photoId: photoId,
          elementsJson: elementsJson,
          annotatedImagePath: Value(annotatedImagePath),
          createdAt: DateTime.now(),
        ),
      );
    }

    // Update the photo's hasAnnotations flag
    await setHasAnnotations(photoId, elements.isNotEmpty);
  }

  /// Delete annotation for a photo
  Future<int> deleteAnnotation(String photoId) async {
    await setHasAnnotations(photoId, false);
    return (delete(photoAnnotations)..where((t) => t.photoId.equals(photoId)))
        .go();
  }

  /// Parse annotation elements from database
  List<AnnotationElement> parseAnnotationElements(String elementsJson) {
    final list = jsonDecode(elementsJson) as List;
    return list
        .map((e) => AnnotationElement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============= Helpers =============

  /// Convert database row to PhotoItem domain entity
  PhotoItem toPhotoItem(MediaItemsData data) => PhotoItem(
      id: data.id,
      surveyId: data.surveyId,
      sectionId: data.sectionId,
      localPath: data.localPath,
      remotePath: data.remotePath,
      caption: data.caption,
      status: MediaStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => MediaStatus.local,
      ),
      createdAt: data.createdAt,
      fileSize: data.fileSize,
      width: data.width,
      height: data.height,
      thumbnailPath: data.thumbnailPath,
      hasAnnotations: data.hasAnnotations,
      sortOrder: data.sortOrder,
    );

  /// Convert database row to AudioItem domain entity
  AudioItem toAudioItem(MediaItemsData data) {
    List<double>? waveform;
    if (data.waveformData != null) {
      final list = jsonDecode(data.waveformData!) as List;
      waveform = list.map((e) => (e as num).toDouble()).toList();
    }

    return AudioItem(
      id: data.id,
      surveyId: data.surveyId,
      sectionId: data.sectionId,
      localPath: data.localPath,
      remotePath: data.remotePath,
      caption: data.caption,
      status: MediaStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => MediaStatus.local,
      ),
      createdAt: data.createdAt,
      fileSize: data.fileSize,
      duration: data.duration,
      waveformData: waveform,
      transcription: data.transcription,
    );
  }

  /// Convert database row to VideoItem domain entity
  VideoItem toVideoItem(MediaItemsData data) => VideoItem(
      id: data.id,
      surveyId: data.surveyId,
      sectionId: data.sectionId,
      localPath: data.localPath,
      remotePath: data.remotePath,
      caption: data.caption,
      status: MediaStatus.values.firstWhere(
        (s) => s.name == data.status,
        orElse: () => MediaStatus.local,
      ),
      createdAt: data.createdAt,
      fileSize: data.fileSize,
      duration: data.duration,
      width: data.width,
      height: data.height,
      thumbnailPath: data.thumbnailPath,
    );
}
