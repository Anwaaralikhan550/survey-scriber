import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/repositories/ai_repository.dart';

/// Remote datasource for AI API calls
class AiRemoteDataSource {
  const AiRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;
  static const _basePath = 'ai';
  static const _tag = 'AiRemote';
  static const _uuid = Uuid();

  /// Extended timeout for AI generation requests.
  /// AI models (like Gemini 2.5 Pro) can take 30-60+ seconds to generate responses.
  static const _aiGenerationTimeout = Duration(seconds: 120);

  /// Build options with correlation ID for request tracing and extended timeout.
  Options _aiOptions(String correlationId) => Options(
    receiveTimeout: _aiGenerationTimeout,
    headers: {'X-Correlation-ID': correlationId},
  );

  /// Get AI service status
  Future<AiStatus> getStatus() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/status',
    );
    return AiStatus.fromJson(response.data ?? {});
  }

  /// Generate report narratives
  ///
  /// Uses extended timeout as AI model generation can take 30-60+ seconds.
  Future<AiReportResponse> generateReport(GenerateReportRequest request) async {
    final correlationId = _uuid.v4();
    AppLogger.d(_tag, 'POST /ai/report [cid=$correlationId] '
        'survey=${request.surveyId}');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/report',
      data: request.toJson(),
      options: _aiOptions(correlationId),
    );

    AppLogger.d(_tag, 'POST /ai/report [cid=$correlationId] => OK');
    return AiReportResponse.fromJson(response.data ?? {});
  }

  /// Generate recommendations
  ///
  /// Uses extended timeout as AI model generation can take 30-60+ seconds.
  Future<AiRecommendationsResponse> generateRecommendations(
    GenerateRecommendationsRequest request,
  ) async {
    final correlationId = _uuid.v4();
    AppLogger.d(_tag, 'POST /ai/recommendations [cid=$correlationId] '
        'survey=${request.surveyId}');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/recommendations',
      data: request.toJson(),
      options: _aiOptions(correlationId),
    );

    AppLogger.d(_tag, 'POST /ai/recommendations [cid=$correlationId] => OK');
    return AiRecommendationsResponse.fromJson(response.data ?? {});
  }

  /// Generate risk summary
  ///
  /// Uses extended timeout as AI model generation can take 30-60+ seconds.
  Future<AiRiskSummaryResponse> generateRiskSummary(
    GenerateRiskSummaryRequest request,
  ) async {
    final correlationId = _uuid.v4();
    AppLogger.d(_tag, 'POST /ai/risk-summary [cid=$correlationId] '
        'survey=${request.surveyId}');

    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/risk-summary',
      data: request.toJson(),
      options: _aiOptions(correlationId),
    );

    AppLogger.d(_tag, 'POST /ai/risk-summary [cid=$correlationId] => OK');
    return AiRiskSummaryResponse.fromJson(response.data ?? {});
  }

  /// Check consistency
  ///
  /// Uses extended timeout as AI model generation can take 30-60+ seconds.
  Future<AiConsistencyResponse> checkConsistency(
    ConsistencyCheckRequest request,
  ) async {
    final correlationId = _uuid.v4();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/consistency-check',
      data: request.toJson(),
      options: _aiOptions(correlationId),
    );
    return AiConsistencyResponse.fromJson(response.data ?? {});
  }

  /// Professional narrative analysis (hybrid Layer 2).
  ///
  /// Uses extended timeout as AI model generation can take 30-60+ seconds.
  Future<AiProfessionalAnalysisResponse> analyzeProfessionally(
    ProfessionalAnalysisRequest request,
  ) async {
    final correlationId = _uuid.v4();
    AppLogger.d(
      _tag,
      'POST /ai/professional-analysis [cid=$correlationId] '
      'survey=${request.surveyId}',
    );

    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/professional-analysis',
      data: request.toJson(),
      options: _aiOptions(correlationId),
    );

    AppLogger.d(
      _tag,
      'POST /ai/professional-analysis [cid=$correlationId] => OK',
    );
    return AiProfessionalAnalysisResponse.fromJson(response.data ?? {});
  }

  /// Generate photo tags
  ///
  /// Uses extended timeout as AI model generation can take 30-60+ seconds.
  Future<AiPhotoTagsResponse> generatePhotoTags(
    PhotoTagsRequest request,
  ) async {
    final correlationId = _uuid.v4();
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/photo-tags',
      data: request.toJson(),
      options: _aiOptions(correlationId),
    );
    return AiPhotoTagsResponse.fromJson(response.data ?? {});
  }
}
