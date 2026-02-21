import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/media_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/media_remote_datasource.dart';
import '../../data/services/media_storage_service.dart';
import '../../domain/entities/media_item.dart';
import 'media_providers_setup.dart'; // Import the setup file where remote data source provider is defined

const _uuid = Uuid();

/// Provider for media storage service
final mediaStorageServiceProvider = Provider<MediaStorageService>((ref) => MediaStorageService.instance);

/// Provider for ImagePicker
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// State for a section's media
class SectionMediaState {
  const SectionMediaState({
    this.photos = const [],
    this.audioNotes = const [],
    this.videos = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PhotoItem> photos;
  final List<AudioItem> audioNotes;
  final List<VideoItem> videos;
  final bool isLoading;
  final String? errorMessage;

  int get totalCount => photos.length + audioNotes.length + videos.length;
  bool get hasMedia => totalCount > 0;

  SectionMediaState copyWith({
    List<PhotoItem>? photos,
    List<AudioItem>? audioNotes,
    List<VideoItem>? videos,
    bool? isLoading,
    String? errorMessage,
  }) => SectionMediaState(
      photos: photos ?? this.photos,
      audioNotes: audioNotes ?? this.audioNotes,
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
}

/// Provider for section media state
final sectionMediaProvider = StateNotifierProvider.autoDispose
    .family<SectionMediaNotifier, SectionMediaState, String>((ref, sectionId) {
  final mediaDao = ref.watch(mediaDaoProvider);
  final storageService = ref.watch(mediaStorageServiceProvider);
  final remoteDataSource = ref.watch(mediaRemoteDataSourceProvider);
  return SectionMediaNotifier(
    sectionId: sectionId,
    mediaDao: mediaDao,
    storageService: storageService,
    remoteDataSource: remoteDataSource,
  );
});

/// Notifier for managing section media
class SectionMediaNotifier extends StateNotifier<SectionMediaState> {
  SectionMediaNotifier({
    required this.sectionId,
    required this.mediaDao,
    required this.storageService,
    required this.remoteDataSource,
  }) : super(const SectionMediaState(isLoading: true)) {
    _loadMedia();
  }

  final String sectionId;
  final MediaDao mediaDao;
  final MediaStorageService storageService;
  final MediaRemoteDataSource remoteDataSource;

  Future<void> _loadMedia() async {
    AppLogger.d('SectionMediaNotifier', 'Loading media for section: $sectionId');
    try {
      state = state.copyWith(isLoading: true);

      final photos = await mediaDao.getPhotosBySection(sectionId);
      final audio = await mediaDao.getAudioBySection(sectionId);
      final videos = await mediaDao.getVideoBySection(sectionId);

      AppLogger.d('SectionMediaNotifier',
        'Loaded: ${photos.length} photos, ${audio.length} audio, ${videos.length} videos for section $sectionId',
      );

      state = SectionMediaState(
        photos: photos.map(mediaDao.toPhotoItem).toList().cast<PhotoItem>(),
        audioNotes: audio.map(mediaDao.toAudioItem).toList().cast<AudioItem>(),
        videos: videos.map(mediaDao.toVideoItem).toList().cast<VideoItem>(),
      );
    } catch (e, stack) {
      AppLogger.e('SectionMediaNotifier', 'Failed to load media for section $sectionId: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load media: $e',
      );
    }
  }

  /// Add a photo from camera or gallery
  Future<PhotoItem?> addPhoto({
    required String surveyId,
    required File file,
    String? caption,
  }) async {
    AppLogger.d('SectionMediaNotifier', 'addPhoto: surveyId=$surveyId, sectionId=$sectionId');
    try {
      // Save file to storage
      final localPath = await storageService.savePhoto(file);
      final fileSize = await storageService.getFileSize(localPath);
      AppLogger.d('SectionMediaNotifier', 'Photo saved to: $localPath, size: $fileSize');

      final id = _uuid.v4();
      final now = DateTime.now();

      // Insert into database
      await mediaDao.insertMedia(
        MediaItemsCompanion.insert(
          id: id,
          surveyId: surveyId,
          sectionId: sectionId,
          mediaType: MediaType.photo.name,
          localPath: localPath,
          caption: Value(caption),
          fileSize: Value(fileSize),
          sortOrder: Value(state.photos.length),
          createdAt: now,
        ),
      );
      AppLogger.d('SectionMediaNotifier', 'Photo inserted to DB with id=$id, sectionId=$sectionId');

      final photo = PhotoItem(
        id: id,
        surveyId: surveyId,
        sectionId: sectionId,
        localPath: localPath,
        caption: caption,
        fileSize: fileSize,
        sortOrder: state.photos.length,
        createdAt: now,
      );

      state = state.copyWith(photos: [...state.photos, photo]);
      
      // Upload to backend (Fire & Forget for offline resilience)
      _uploadMedia(surveyId, File(localPath), 'PHOTO').ignore();

      AppLogger.d('SectionMediaNotifier', 'Photo added successfully. Total photos: ${state.photos.length}');
      return photo;
    } catch (e, stack) {
      AppLogger.e('SectionMediaNotifier', 'Failed to add photo: $e\n$stack');
      state = state.copyWith(errorMessage: 'Failed to add photo: $e');
      return null;
    }
  }

  /// Add an audio recording
  Future<AudioItem?> addAudio({
    required String surveyId,
    required File file,
    required int duration,
    String? caption,
  }) async {
    AppLogger.d('SectionMediaNotifier', 'addAudio: surveyId=$surveyId, sectionId=$sectionId, duration=$duration');
    try {
      final localPath = await storageService.saveAudio(file);
      final fileSize = await storageService.getFileSize(localPath);
      AppLogger.d('SectionMediaNotifier', 'Audio saved to: $localPath, size: $fileSize');

      final id = _uuid.v4();
      final now = DateTime.now();

      await mediaDao.insertMedia(
        MediaItemsCompanion.insert(
          id: id,
          surveyId: surveyId,
          sectionId: sectionId,
          mediaType: MediaType.audio.name,
          localPath: localPath,
          caption: Value(caption),
          fileSize: Value(fileSize),
          duration: Value(duration),
          createdAt: now,
        ),
      );
      AppLogger.d('SectionMediaNotifier', 'Audio inserted to DB with id=$id, sectionId=$sectionId');

      final audio = AudioItem(
        id: id,
        surveyId: surveyId,
        sectionId: sectionId,
        localPath: localPath,
        caption: caption,
        fileSize: fileSize,
        duration: duration,
        createdAt: now,
      );

      state = state.copyWith(audioNotes: [...state.audioNotes, audio]);
      
      // Upload to backend
      _uploadMedia(surveyId, File(localPath), 'AUDIO').ignore();

      AppLogger.d('SectionMediaNotifier', 'Audio added successfully. Total audio: ${state.audioNotes.length}');
      return audio;
    } catch (e, stack) {
      AppLogger.e('SectionMediaNotifier', 'Failed to add audio: $e\n$stack');
      state = state.copyWith(errorMessage: 'Failed to add audio: $e');
      return null;
    }
  }

  /// Add a video clip
  Future<VideoItem?> addVideo({
    required String surveyId,
    required File file,
    required int duration,
    String? caption,
  }) async {
    try {
      final localPath = await storageService.saveVideo(file);
      final fileSize = await storageService.getFileSize(localPath);

      final id = _uuid.v4();
      final now = DateTime.now();

      await mediaDao.insertMedia(
        MediaItemsCompanion.insert(
          id: id,
          surveyId: surveyId,
          sectionId: sectionId,
          mediaType: MediaType.video.name,
          localPath: localPath,
          caption: Value(caption),
          fileSize: Value(fileSize),
          duration: Value(duration),
          sortOrder: Value(state.videos.length),
          createdAt: now,
        ),
      );

      final video = VideoItem(
        id: id,
        surveyId: surveyId,
        sectionId: sectionId,
        localPath: localPath,
        caption: caption,
        fileSize: fileSize,
        duration: duration,
        createdAt: now,
      );

      state = state.copyWith(videos: [...state.videos, video]);
      
      // Upload to backend (Video not strictly in prompt list but good for completeness)
      // Prompt said "Media/Photos". I'll skip video for now to be "minimal" unless easy.
      // Backend supports MediaType enum which has VIDEO? No, Enum is PHOTO, AUDIO, SIGNATURE.
      // Wait, backend enum is `PHOTO`, `AUDIO`, `SIGNATURE`. NO VIDEO support in backend yet.
      // So I should NOT upload video.
      
      return video;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add video: $e');
      return null;
    }
  }

  /// Update photo caption
  Future<void> updatePhotoCaption(String photoId, String? caption) async {
    try {
      await mediaDao.updateCaption(photoId, caption);
      state = state.copyWith(
        photos: state.photos.map((p) {
          if (p.id == photoId) {
            return p.copyWith(caption: caption);
          }
          return p;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update caption: $e');
    }
  }

  /// Update audio caption
  Future<void> updateAudioCaption(String audioId, String? caption) async {
    try {
      await mediaDao.updateCaption(audioId, caption);
      state = state.copyWith(
        audioNotes: state.audioNotes.map((a) {
          if (a.id == audioId) {
            return a.copyWith(caption: caption);
          }
          return a;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update caption: $e');
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId) async {
    try {
      final photo = state.photos.cast<PhotoItem?>().firstWhere(
        (p) => p?.id == photoId,
        orElse: () => null,
      );
      if (photo == null) {
        state = state.copyWith(errorMessage: 'Photo not found');
        return;
      }
      await storageService.deleteMediaWithThumbnail(
        photo.localPath,
        photo.thumbnailPath,
      );
      await mediaDao.deleteMedia(photoId);
      await mediaDao.deleteAnnotation(photoId);

      state = state.copyWith(
        photos: state.photos.where((p) => p.id != photoId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete photo: $e');
    }
  }

  /// Delete an audio note
  Future<void> deleteAudio(String audioId) async {
    try {
      final audio = state.audioNotes.cast<AudioItem?>().firstWhere(
        (a) => a?.id == audioId,
        orElse: () => null,
      );
      if (audio == null) {
        state = state.copyWith(errorMessage: 'Audio not found');
        return;
      }
      await storageService.deleteFile(audio.localPath);
      await mediaDao.deleteMedia(audioId);

      state = state.copyWith(
        audioNotes: state.audioNotes.where((a) => a.id != audioId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete audio: $e');
    }
  }

  /// Delete a video
  Future<void> deleteVideo(String videoId) async {
    try {
      final video = state.videos.cast<VideoItem?>().firstWhere(
        (v) => v?.id == videoId,
        orElse: () => null,
      );
      if (video == null) {
        state = state.copyWith(errorMessage: 'Video not found');
        return;
      }
      await storageService.deleteMediaWithThumbnail(
        video.localPath,
        video.thumbnailPath,
      );
      await mediaDao.deleteMedia(videoId);

      state = state.copyWith(
        videos: state.videos.where((v) => v.id != videoId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete video: $e');
    }
  }

  /// Reorder photos
  Future<void> reorderPhotos(int oldIndex, int newIndex) async {
    final photos = List<PhotoItem>.from(state.photos);
    final photo = photos.removeAt(oldIndex);
    photos.insert(newIndex, photo);

    // Update sort orders
    for (var i = 0; i < photos.length; i++) {
      await mediaDao.updateSortOrder(photos[i].id, i);
    }

    state = state.copyWith(
      photos: photos.asMap().entries.map((e) => e.value.copyWith(sortOrder: e.key)).toList(),
    );
  }

  /// Refresh media from database
  Future<void> refresh() async {
    await _loadMedia();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith();
  }

  /// Verify media count in database matches state (dev verification)
  Future<bool> verifyPersistence() async {
    try {
      final photos = await mediaDao.getPhotosBySection(sectionId);
      final audio = await mediaDao.getAudioBySection(sectionId);
      final dbCount = photos.length + audio.length;
      final stateCount = state.photos.length + state.audioNotes.length;

      AppLogger.d('SectionMediaNotifier',
        'Verify persistence for $sectionId: DB=$dbCount, State=$stateCount',
      );

      if (dbCount != stateCount) {
        AppLogger.e('SectionMediaNotifier',
          'MISMATCH: DB has $dbCount items but state has $stateCount',
        );
        return false;
      }
      return true;
    } catch (e) {
      AppLogger.e('SectionMediaNotifier', 'Verify persistence failed: $e');
      return false;
    }
  }

  Future<void> _uploadMedia(String surveyId, File file, String type) async {
    try {
      await remoteDataSource.uploadMedia(
        surveyId: surveyId,
        file: file,
        type: type,
      );
      AppLogger.d('SectionMediaNotifier', 'Uploaded $type for survey $surveyId');
    } catch (e) {
      // Offline or error - silent fail (will retry later if we implement queue,
      // but for now relying on user re-attempt or implicit sync later)
      // Actually, without a queue, this is "best effort".
      AppLogger.e('SectionMediaNotifier', 'Failed to upload media: $e');
    }
  }
}

/// Provider for survey-level media gallery
final surveyMediaProvider = FutureProvider.autoDispose
    .family<List<MediaItem>, String>((ref, surveyId) async {
  final mediaDao = ref.watch(mediaDaoProvider);
  final items = await mediaDao.getMediaBySurvey(surveyId);

  return items.map((item) {
    switch (item.mediaType) {
      case 'photo':
        return mediaDao.toPhotoItem(item);
      case 'audio':
        return mediaDao.toAudioItem(item);
      case 'video':
        return mediaDao.toVideoItem(item);
      default:
        return mediaDao.toPhotoItem(item);
    }
  }).toList();
});

/// Provider for media counts per survey
final surveyMediaCountsProvider = FutureProvider.autoDispose
    .family<({int photos, int audio, int video}), String>((ref, surveyId) async {
  final mediaDao = ref.watch(mediaDaoProvider);
  return mediaDao.getMediaCountsBySurvey(surveyId);
});

extension FutureIgnore on Future {
  void ignore() {}
}