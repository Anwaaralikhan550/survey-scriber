import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class MediaRemoteDataSource {
  const MediaRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> uploadMedia({
    required String surveyId,
    required File file,
    required String type, // PHOTO, AUDIO, SIGNATURE
  }) async {
    final fileName = p.basename(file.path);
    final mimeType = _getMimeType(fileName);

    final formData = FormData.fromMap({
      'surveyId': surveyId,
      'type': type,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    await _dio.post<dynamic>(
      'media/upload',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  String _getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      case '.wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }
}
