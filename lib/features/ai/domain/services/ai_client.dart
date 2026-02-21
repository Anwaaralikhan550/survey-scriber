import 'dart:async';

import '../../../../core/ai/ai_observability.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../data/services/ai_data_formatter.dart';
import '../entities/ai_response.dart';
import '../repositories/ai_repository.dart';

/// Client-side safety timeout — last-resort catch for hung requests.
/// Must exceed the Dio + backend timeouts (120s each).
const _safetyTimeout = Duration(seconds: 150);

/// High-level AI client for surveys.
///
/// Wraps the existing [AiRepository] with:
/// - **Feature flags**: checks [FeatureFlagService] before every call
/// - **PII redaction**: strips addresses/emails/phones via [PiiRedactor]
/// - **Observability**: logs latency, token usage, errors via [AiObservability]
/// - **Timeout safety**: client-side catch for hung connections
///
/// AI NEVER overwrites user text silently — this client returns data
/// that the UI must present in a preview + Apply flow.
class AiInspectionClient {
  AiInspectionClient({
    required AiRepository repository,
    required FeatureFlagService featureFlags,
    AiDataFormatter? formatter,
    AiObservability? observability,
  })  : _repo = repository,
        _flags = featureFlags,
        _formatter = formatter ?? AiDataFormatter(),
        _obs = observability ?? AiObservability.instance;

  final AiRepository _repo;
  final FeatureFlagService _flags;
  final AiDataFormatter _formatter;
  final AiObservability _obs;

  // ── Public API ──────────────────────────────────────────────────

  /// Check AI service availability and quota.
  Future<AiStatus> getStatus() => _repo.getStatus();

  /// Generate report narratives for a survey.
  ///
  /// Returns an [AiResult] containing the AI response and the
  /// redaction mapping needed to restore PII in the narratives.
  Future<AiResult<AiReportResponse>> generateReport({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    _assertFeature(AiFeature.reportNarrative);

    final formatted = _formatter.formatForReport(
      surveyId: surveyId,
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
    );

    final response = await _timed(
      'report',
      () => _repo.generateReport(formatted.request),
    );

    _obs.recordSuccess(
      feature: 'report',
      latency: response.latency,
      inputTokens: response.value.usage.inputTokens,
      outputTokens: response.value.usage.outputTokens,
      fromCache: response.value.fromCache,
    );

    return AiResult(
      response: response.value,
      redactionMapping: formatted.redactionMapping,
    );
  }

  /// Run a consistency check across all screens.
  Future<AiResult<AiConsistencyResponse>> checkConsistency({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    _assertFeature(AiFeature.consistencyCheck);

    final formatted = _formatter.formatForConsistency(
      surveyId: surveyId,
      tree: tree,
      allAnswers: allAnswers,
    );

    final response = await _timed(
      'consistency',
      () => _repo.checkConsistency(formatted.request),
    );

    _obs.recordSuccess(
      feature: 'consistency',
      latency: response.latency,
      inputTokens: response.value.usage.inputTokens,
      outputTokens: response.value.usage.outputTokens,
      fromCache: response.value.fromCache,
    );

    return AiResult(
      response: response.value,
      redactionMapping: formatted.redactionMapping,
    );
  }

  /// Generate a risk assessment for a survey.
  Future<AiResult<AiRiskSummaryResponse>> generateRiskSummary({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    _assertFeature(AiFeature.riskAssessment);

    final formatted = _formatter.formatForRiskSummary(
      surveyId: surveyId,
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
    );

    final response = await _timed(
      'risk-summary',
      () => _repo.generateRiskSummary(formatted.request),
    );

    _obs.recordSuccess(
      feature: 'risk-summary',
      latency: response.latency,
      inputTokens: response.value.usage.inputTokens,
      outputTokens: response.value.usage.outputTokens,
      fromCache: response.value.fromCache,
    );

    return AiResult(
      response: response.value,
      redactionMapping: formatted.redactionMapping,
    );
  }

  /// Generate repair/maintenance recommendations.
  Future<AiResult<AiRecommendationsResponse>> generateRecommendations({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    _assertFeature(AiFeature.recommendations);

    final formatted = _formatter.formatForRecommendations(
      surveyId: surveyId,
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
    );

    final response = await _timed(
      'recommendations',
      () => _repo.generateRecommendations(formatted.request),
    );

    _obs.recordSuccess(
      feature: 'recommendations',
      latency: response.latency,
      inputTokens: response.value.usage.inputTokens,
      outputTokens: response.value.usage.outputTokens,
      fromCache: response.value.fromCache,
    );

    return AiResult(
      response: response.value,
      redactionMapping: formatted.redactionMapping,
    );
  }

  /// Run professional narrative analysis (hybrid Layer 2).
  ///
  /// Sends survey data plus existing rule engine recommendations to the
  /// backend AI, which returns complementary professional insights.
  Future<AiResult<AiProfessionalAnalysisResponse>> analyzeProfessionally({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required List<Map<String, String>> ruleRecommendations,
    required bool isValuation,
  }) async {
    _assertFeature(AiFeature.aiProfessionalAnalysis);

    final formatted = _formatter.formatForProfessionalAnalysis(
      surveyId: surveyId,
      tree: tree,
      allAnswers: allAnswers,
      ruleRecommendations: ruleRecommendations,
      isValuation: isValuation,
    );

    final response = await _timed(
      'professional-analysis',
      () => _repo.analyzeProfessionally(formatted.request),
    );

    _obs.recordSuccess(
      feature: 'professional-analysis',
      latency: response.latency,
      inputTokens: response.value.usage.inputTokens,
      outputTokens: response.value.usage.outputTokens,
      fromCache: response.value.fromCache,
    );

    return AiResult(
      response: response.value,
      redactionMapping: formatted.redactionMapping,
    );
  }

  /// Generate photo tags for a survey photo.
  Future<AiPhotoTagsResponse> generatePhotoTags({
    required String surveyId,
    required String photoId,
    required String imageData,
    String? sectionContext,
  }) async {
    _assertFeature(AiFeature.photoTags);

    final request = PhotoTagsRequest(
      surveyId: surveyId,
      photoId: photoId,
      imageData: imageData,
      sectionContext: sectionContext,
    );

    final response = await _timed(
      'photo-tags',
      () => _repo.generatePhotoTags(request),
    );

    _obs.recordSuccess(
      feature: 'photo-tags',
      latency: response.latency,
      inputTokens: response.value.usage.inputTokens,
      outputTokens: response.value.usage.outputTokens,
      fromCache: response.value.fromCache,
    );

    return response.value;
  }

  // ── Helpers ─────────────────────────────────────────────────────

  /// Throws if the feature flag is disabled.
  void _assertFeature(AiFeature feature) {
    if (!_flags.isEnabled(feature)) {
      throw AiFeatureDisabledException(feature);
    }
  }

  /// Execute an AI call with timeout and latency measurement.
  Future<_TimedResult<T>> _timed<T>(
    String label,
    Future<T> Function() call,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final value = await call().timeout(
        _safetyTimeout,
        onTimeout: () => throw TimeoutException(
          'AI $label timed out after ${_safetyTimeout.inSeconds}s',
        ),
      );
      sw.stop();
      return _TimedResult(value: value, latency: sw.elapsed);
    } catch (e) {
      sw.stop();
      _obs.recordError(
        feature: label,
        latency: sw.elapsed,
        error: e,
      );
      rethrow;
    }
  }
}

/// Result from the AI client containing the response and redaction mapping.
class AiResult<T> {
  const AiResult({
    required this.response,
    required this.redactionMapping,
  });

  final T response;

  /// PII redaction mapping: token → original value.
  /// Use [PiiRedactor.unredact] to restore AI response text.
  final Map<String, String> redactionMapping;
}

/// Thrown when a feature flag is disabled.
class AiFeatureDisabledException implements Exception {
  const AiFeatureDisabledException(this.feature);

  final AiFeature feature;

  @override
  String toString() =>
      'AI feature "${feature.displayName}" is currently disabled';
}

class _TimedResult<T> {
  const _TimedResult({required this.value, required this.latency});

  final T value;
  final Duration latency;
}
