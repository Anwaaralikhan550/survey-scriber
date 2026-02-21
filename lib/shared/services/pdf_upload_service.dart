import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';

/// Exception thrown when a survey is not found on the server during PDF upload.
/// This indicates the survey needs to be synced before the PDF can be uploaded.
class SurveyNotFoundOnServerException implements Exception {
  const SurveyNotFoundOnServerException(this.surveyId);

  final String surveyId;

  @override
  String toString() =>
      'SurveyNotFoundOnServerException: Survey $surveyId not found on server. '
      'The survey must be synced before uploading the PDF.';
}

/// Exception thrown when PDF upload fails due to network issues.
/// This includes: no internet, connection timeout, host unreachable, etc.
/// These are transient errors that should be retried.
class PdfUploadNetworkException implements Exception {
  const PdfUploadNetworkException({
    required this.surveyId,
    required this.message,
    this.isOffline = false,
  });

  final String surveyId;
  final String message;
  final bool isOffline;

  @override
  String toString() => 'PdfUploadNetworkException: $message (survey: $surveyId)';
}

/// Service to upload generated report PDFs to the backend.
/// This makes the PDF available for client portal downloads.
class PdfUploadService {
  const PdfUploadService(this._apiClient);

  final ApiClient _apiClient;

  /// Upload a generated PDF for a survey to the backend.
  /// Returns true if upload was successful.
  Future<bool> uploadReportPdf({
    required String surveyId,
    required String pdfPath,
  }) async {
    try {
      final trimmedSurveyId = surveyId.trim();
      if (trimmedSurveyId.isEmpty) {
        throw ArgumentError('surveyId is required to upload a report PDF');
      }

      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found at path: $pdfPath');
      }

      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'report.pdf',
          contentType: DioMediaType('application', 'pdf'),
        ),
      });

      await _apiClient.post(
        'surveys/$trimmedSurveyId/report-pdf',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return true;
    } on NotFoundException catch (e) {
      // 404 - Survey not found on server
      // This is the key case that triggers Force Dirty -> Sync -> Retry
      AppLogger.w('PdfUploadService',
        'Survey $surveyId not found on server (404). '
        'Caller should sync and retry. Message: ${e.message}',
      );
      throw SurveyNotFoundOnServerException(surveyId);

    } on NetworkException catch (e) {
      // Network errors (timeout, no connection, etc.) - should retry
      AppLogger.w('PdfUploadService',
        'Network error uploading PDF for survey $surveyId: ${e.message}',
      );
      throw PdfUploadNetworkException(
        surveyId: surveyId,
        message: e.message,
        isOffline: e.message.contains('No internet') ||
                   e.message.contains('timed out'),
      );

    } on ValidationException catch (e) {
      // 400 validation errors (e.g., status restriction) - NOT retryable.
      // Surface the server message so the user understands why.
      AppLogger.w('PdfUploadService',
        'Validation error uploading PDF for survey $surveyId: ${e.message}',
      );
      return false;

    } on ServerException catch (e) {
      // 5xx server errors - transient, should retry
      AppLogger.w('PdfUploadService',
        'Server error uploading PDF for survey $surveyId: ${e.message} (${e.statusCode})',
      );
      throw PdfUploadNetworkException(
        surveyId: surveyId,
        message: e.message ?? 'Server error: ${e.statusCode}',
      );

    } on DioException catch (e) {
      // Raw DioException (bypassed ApiClient wrapper) - classify it
      AppLogger.e('PdfUploadService',
        'DioException uploading PDF for survey $surveyId: ${e.message}',
      );

      if (_isNetworkError(e)) {
        throw PdfUploadNetworkException(
          surveyId: surveyId,
          message: e.message ?? 'Network error',
          isOffline: e.type == DioExceptionType.connectionError,
        );
      }

      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        throw SurveyNotFoundOnServerException(surveyId);
      }
      if (statusCode != null && statusCode >= 500) {
        throw PdfUploadNetworkException(
          surveyId: surveyId,
          message: 'Server error: $statusCode',
        );
      }

      // Other client errors - non-retryable
      return false;

    } catch (e) {
      // Unexpected errors
      AppLogger.e('PdfUploadService',
        'Unexpected error uploading PDF for survey $surveyId: $e',
      );
      return false;
    }
  }

  /// Send a survey report PDF via email through the backend.
  /// The backend retrieves the already-uploaded PDF and sends it.
  /// Returns a success message string on success.
  ///
  /// Throws [SurveyNotFoundOnServerException] if the survey hasn't been
  /// synced to the server yet — caller should sync first, then retry.
  Future<String> sendReportEmail({
    required String surveyId,
    required String recipientEmail,
    String format = 'pdf',
  }) async {
    final trimmedSurveyId = surveyId.trim();
    if (trimmedSurveyId.isEmpty) {
      throw ArgumentError('surveyId is required to send a report email');
    }

    try {
      final response = await _apiClient.post(
        'surveys/$trimmedSurveyId/send-report',
        data: {
          'email': recipientEmail,
          'format': format,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      return data?['message'] as String? ?? 'Report sent successfully';
    } on NotFoundException {
      AppLogger.w('PdfUploadService',
        'Survey $surveyId not found on server when sending report. '
        'Survey may not be synced yet.',
      );
      throw SurveyNotFoundOnServerException(surveyId);
    }
  }

  /// Check if the DioException is a network-related error (transient, should retry)
  bool _isNetworkError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.unknown:
        // Check for common network error messages
        final message = e.message?.toLowerCase() ?? '';
        return message.contains('no route to host') ||
               message.contains('network is unreachable') ||
               message.contains('connection refused') ||
               message.contains('no internet') ||
               message.contains('socket') ||
               message.contains('failed host lookup');
      default:
        return false;
    }
  }
}
