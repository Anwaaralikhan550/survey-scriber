import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/database/daos/media_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/media_item.dart';

/// Provider for MediaUploadService
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  final dio = ref.watch(dioProvider);
  final mediaDao = ref.watch(mediaDaoProvider);
  return MediaUploadService(dio: dio, mediaDao: mediaDao);
});

/// Result of uploading all pending media
typedef MediaUploadResult = ({int success, int failed});

/// Service for uploading media files to backend using multipart/form-data
class MediaUploadService {
  MediaUploadService({
    required this.dio,
    required this.mediaDao,
  });

  final Dio dio;
  final MediaDao mediaDao;

  /// Upload a single media item to the backend
  /// Returns the server-assigned media ID on success, null on failure
  Future<String?> uploadMedia({
    required String surveyId,
    required String localPath,
    required MediaType type,
    String? caption,
  }) async {
    AppLogger.d('MediaUploadService', 'uploadMedia called: surveyId=$surveyId, path=$localPath, type=${type.name}');

    final file = File(localPath);
    if (!await file.exists()) {
      AppLogger.e('MediaUploadService', 'File does not exist: $localPath');
      return null;
    }

    final fileSize = await file.length();
    AppLogger.d('MediaUploadService', 'File exists, size: $fileSize bytes');

    try {
      final fileName = p.basename(localPath);
      final mimeType = _getMimeType(type, fileName);
      AppLogger.d('MediaUploadService', 'Uploading file: $fileName, mimeType: $mimeType');

      final formData = FormData.fromMap({
        'surveyId': surveyId,
        'type': _mediaTypeToBackend(type),
        'file': await MultipartFile.fromFile(
          localPath,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      AppLogger.d('MediaUploadService', 'Sending POST to media/upload...');

      // Note: Do NOT manually set contentType for FormData!
      // Dio automatically sets the correct multipart/form-data with boundary.
      // Use extended timeout for large files
      final response = await dio.post<Map<String, dynamic>>(
        'media/upload',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      AppLogger.d('MediaUploadService', 'Response status: ${response.statusCode}');
      AppLogger.d('MediaUploadService', 'Response data: ${response.data}');

      if (response.statusCode == 201 && response.data != null) {
        final remoteId = response.data!['id'] as String?;
        AppLogger.d('MediaUploadService', 'Upload successful, remoteId: $remoteId');
        return remoteId;
      }
      AppLogger.e('MediaUploadService', 'Upload failed: unexpected status ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      AppLogger.e('MediaUploadService', 'Media upload DioException: ${e.type}');
      AppLogger.e('MediaUploadService', 'Error message: ${e.message}');
      AppLogger.e('MediaUploadService', 'Response: ${e.response?.data}');
      return null;
    } catch (e) {
      AppLogger.e('MediaUploadService', 'Media upload error: $e');
      return null;
    }
  }

  /// Upload all pending (local-only) media items for a survey
  Future<MediaUploadResult> uploadPendingMedia(String surveyId) async {
    AppLogger.d('MediaUploadService', 'uploadPendingMedia called for survey: $surveyId');
    final pendingItems = await mediaDao.getPendingUploads(surveyId);
    AppLogger.d('MediaUploadService', 'Found ${pendingItems.length} pending items for survey $surveyId');

    var success = 0;
    var failed = 0;

    for (final item in pendingItems) {
      AppLogger.d('MediaUploadService', 'Uploading ${item.mediaType} item: ${item.id}');
      // Mark as uploading
      await mediaDao.updateStatus(item.id, MediaStatus.uploading);

      final mediaType = MediaType.values.firstWhere(
        (t) => t.name == item.mediaType,
        orElse: () => MediaType.photo,
      );

      final remoteId = await uploadMedia(
        surveyId: item.surveyId,
        localPath: item.localPath,
        type: mediaType,
        caption: item.caption,
      );

      if (remoteId != null) {
        AppLogger.d('MediaUploadService', 'Upload successful for ${item.id}, remoteId: $remoteId');
        // Mark as synced with remote path
        await mediaDao.markAsSynced(
          item.id,
          remotePath: '/media/$remoteId/file',
        );
        success++;
      } else {
        AppLogger.e('MediaUploadService', 'Upload failed for ${item.id}');
        // Mark as failed
        await mediaDao.updateStatus(item.id, MediaStatus.failed);
        failed++;
      }
    }

    AppLogger.d('MediaUploadService', 'uploadPendingMedia complete: $success success, $failed failed');
    return (success: success, failed: failed);
  }

  /// Upload ALL pending (local-only) media items across all surveys
  /// This is called during sync to ensure all media gets uploaded
  Future<MediaUploadResult> uploadAllPendingMedia() async {
    AppLogger.d('MediaUploadService', 'uploadAllPendingMedia called');
    final pendingItems = await mediaDao.getAllPendingUploads();
    AppLogger.d('MediaUploadService', 'Found ${pendingItems.length} total pending media items');

    var success = 0;
    var failed = 0;

    for (final item in pendingItems) {
      AppLogger.d('MediaUploadService', 'Uploading ${item.mediaType} item: ${item.id} (survey: ${item.surveyId})');
      // Mark as uploading
      await mediaDao.updateStatus(item.id, MediaStatus.uploading);

      final mediaType = MediaType.values.firstWhere(
        (t) => t.name == item.mediaType,
        orElse: () => MediaType.photo,
      );

      final remoteId = await uploadMedia(
        surveyId: item.surveyId,
        localPath: item.localPath,
        type: mediaType,
        caption: item.caption,
      );

      if (remoteId != null) {
        AppLogger.d('MediaUploadService', 'Upload successful for ${item.id}, remoteId: $remoteId');
        // Mark as synced with remote path
        await mediaDao.markAsSynced(
          item.id,
          remotePath: '/media/$remoteId/file',
        );
        success++;
      } else {
        AppLogger.e('MediaUploadService', 'Upload failed for ${item.id}');
        // Mark as failed
        await mediaDao.updateStatus(item.id, MediaStatus.failed);
        failed++;
      }
    }

    AppLogger.d('MediaUploadService', 'uploadAllPendingMedia complete: $success success, $failed failed');
    return (success: success, failed: failed);
  }

  /// Delete media from server
  Future<bool> deleteMedia(String mediaId) async {
    try {
      final response = await dio.delete<Map<String, dynamic>>(
        'media/$mediaId',
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Convert local MediaType to backend enum value
  String _mediaTypeToBackend(MediaType type) {
    switch (type) {
      case MediaType.photo:
        return 'PHOTO';
      case MediaType.audio:
        return 'AUDIO';
      case MediaType.video:
        // Backend uses SIGNATURE for now, map video appropriately
        // or handle as needed for your use case
        return 'PHOTO';
    }
  }

  /// Get MIME type for file
  String _getMimeType(MediaType type, String fileName) {
    final ext = p.extension(fileName).toLowerCase();

    switch (type) {
      case MediaType.photo:
        switch (ext) {
          case '.jpg':
          case '.jpeg':
            return 'image/jpeg';
          case '.png':
            return 'image/png';
          case '.webp':
            return 'image/webp';
          case '.heic':
            return 'image/heic';
          default:
            return 'image/jpeg';
        }
      case MediaType.audio:
        switch (ext) {
          case '.mp3':
            return 'audio/mpeg';
          case '.wav':
            return 'audio/wav';
          case '.m4a':
            return 'audio/mp4';
          case '.aac':
            return 'audio/aac';
          default:
            return 'audio/mpeg';
        }
      case MediaType.video:
        return 'video/mp4';
    }
  }
}
