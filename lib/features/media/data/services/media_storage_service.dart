import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for managing media file storage on device.
class MediaStorageService {
  MediaStorageService._();

  static final instance = MediaStorageService._();

  static const _uuid = Uuid();

  Directory? _mediaDir;
  Directory? _thumbnailDir;

  /// Initialize storage directories
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDir = Directory(p.join(appDir.path, 'media'));
    _thumbnailDir = Directory(p.join(appDir.path, 'thumbnails'));

    if (!await _mediaDir!.exists()) {
      await _mediaDir!.create(recursive: true);
    }
    if (!await _thumbnailDir!.exists()) {
      await _thumbnailDir!.create(recursive: true);
    }
  }

  /// Get the media directory
  Directory get mediaDir {
    if (_mediaDir == null) {
      throw StateError('MediaStorageService not initialized. Call init() first.');
    }
    return _mediaDir!;
  }

  /// Get the thumbnail directory
  Directory get thumbnailDir {
    if (_thumbnailDir == null) {
      throw StateError('MediaStorageService not initialized. Call init() first.');
    }
    return _thumbnailDir!;
  }

  /// Generate a unique filename for a photo
  String generatePhotoFilename() {
    final id = _uuid.v4();
    return 'photo_$id.jpg';
  }

  /// Generate a unique filename for audio
  String generateAudioFilename() {
    final id = _uuid.v4();
    return 'audio_$id.m4a';
  }

  /// Generate a unique filename for video
  String generateVideoFilename() {
    final id = _uuid.v4();
    return 'video_$id.mp4';
  }

  /// Generate a unique filename for a thumbnail
  String generateThumbnailFilename(String mediaId) => 'thumb_$mediaId.jpg';

  /// Generate a unique filename for annotated image
  String generateAnnotatedFilename(String photoId) => 'annotated_$photoId.png';

  /// Get full path for a photo
  String getPhotoPath(String filename) => p.join(mediaDir.path, filename);

  /// Get full path for audio
  String getAudioPath(String filename) => p.join(mediaDir.path, filename);

  /// Get full path for video
  String getVideoPath(String filename) => p.join(mediaDir.path, filename);

  /// Get full path for a thumbnail
  String getThumbnailPath(String filename) => p.join(thumbnailDir.path, filename);

  /// Save a file to media directory
  Future<String> savePhoto(File sourceFile) async {
    final filename = generatePhotoFilename();
    final destPath = getPhotoPath(filename);
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Save audio to media directory
  Future<String> saveAudio(File sourceFile) async {
    final filename = generateAudioFilename();
    final destPath = getAudioPath(filename);
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Save video to media directory
  Future<String> saveVideo(File sourceFile) async {
    final filename = generateVideoFilename();
    final destPath = getVideoPath(filename);
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Delete a media file
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Delete a media file and its thumbnail
  Future<void> deleteMediaWithThumbnail(String mediaPath, String? thumbnailPath) async {
    await deleteFile(mediaPath);
    if (thumbnailPath != null) {
      await deleteFile(thumbnailPath);
    }
  }

  /// Get file size in bytes
  Future<int?> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return null;
  }

  /// Check if file exists
  Future<bool> fileExists(String path) async => File(path).exists();

  /// Get all media files for a survey (for cleanup)
  Future<List<File>> getMediaFilesForSurvey(List<String> paths) async {
    final files = <File>[];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        files.add(file);
      }
    }
    return files;
  }

  /// Get total storage used by media
  Future<int> getTotalStorageUsed() async {
    var total = 0;

    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }

    if (await thumbnailDir.exists()) {
      await for (final entity in thumbnailDir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }

    return total;
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
