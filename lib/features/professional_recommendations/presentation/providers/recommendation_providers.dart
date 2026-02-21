import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/database/daos/survey_quality_scores_dao.dart';
import '../../../../core/database/daos/survey_recommendations_dao.dart';
import '../../../../core/utils/logger.dart';
import '../../../ai/domain/services/ai_client.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../domain/models/professional_recommendation.dart';
import '../../domain/services/hybrid_recommendation_service.dart';
import '../../domain/services/recommendation_compute.dart';

/// Immutable state for the recommendation analysis.
class RecommendationState {
  const RecommendationState({
    this.result,
    this.isLoading = false,
    this.isAiLoading = false,
    this.error,
  });

  final ProfessionalRecommendationsResult? result;
  final bool isLoading;
  /// True when AI layer is loading (rule results already available).
  final bool isAiLoading;
  final String? error;

  bool get hasResult => result != null;
  bool get hasError => error != null;

  RecommendationState copyWith({
    ProfessionalRecommendationsResult? result,
    bool? isLoading,
    bool? isAiLoading,
    String? error,
  }) {
    return RecommendationState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      error: error,
    );
  }
}

/// StateNotifier that orchestrates the hybrid recommendation engine.
///
/// Phase 1: Rule engine runs in a background isolate (fast, offline).
/// Phase 2 (optional): AI analysis runs asynchronously and merges in.
/// All results are persisted to the database with audit metadata.
class RecommendationNotifier extends StateNotifier<RecommendationState> {
  RecommendationNotifier({
    required SurveyRecommendationsDao recommendationsDao,
    required SurveyQualityScoresDao scoresDao,
    this.aiClient,
  })  : _recsDao = recommendationsDao,
        _scoresDao = scoresDao,
        super(const RecommendationState());

  final SurveyRecommendationsDao _recsDao;
  final SurveyQualityScoresDao _scoresDao;
  final AiInspectionClient? aiClient;
  static const _tag = 'Recommendations';

  /// Run the hybrid recommendation engine.
  ///
  /// - Always runs the rule engine first (background isolate, <3s).
  /// - If [includeAi] is true and AI client is available, fires AI
  ///   asynchronously — rule results display immediately while AI loads.
  Future<void> analyze({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required bool isValuation,
    bool includeAi = false,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      // ── Phase 1: Rule engine (isolate) ─────────────────────────
      final ruleResult = await compute(
        runRecommendationEngine,
        RecommendationEngineInput(
          surveyId: surveyId,
          tree: tree,
          allAnswers: allAnswers,
          isValuation: isValuation,
        ),
      );

      // Persist rule results + scores to DB
      await _persistResult(ruleResult);

      if (mounted) {
        state = RecommendationState(
          result: await _applyDbAcceptedState(ruleResult),
          isAiLoading: includeAi && aiClient != null,
        );
      }

      AppLogger.d(
        _tag,
        'Rule engine: ${ruleResult.recommendations.length} recommendations, '
        'scores: ${ruleResult.scores?.overallScore ?? 0}%',
      );

      // ── Phase 2: AI analysis (async, optional) ─────────────────
      if (includeAi && aiClient != null) {
        try {
          final hybridService = HybridRecommendationService(
            aiClient: aiClient,
          );
          final hybridResult = await hybridService.analyze(
            surveyId: surveyId,
            tree: tree,
            allAnswers: allAnswers,
            isValuation: isValuation,
            includeAi: true,
          );

          await _persistResult(hybridResult);

          if (mounted) {
            state = RecommendationState(
              result: await _applyDbAcceptedState(hybridResult),
            );
          }

          AppLogger.d(
            _tag,
            'Hybrid result: ${hybridResult.recommendations.length} total '
            '(${hybridResult.ruleCount} rule, ${hybridResult.aiCount} AI)',
          );
        } catch (e) {
          // AI failure is non-fatal — keep rule results
          AppLogger.w(_tag, 'AI analysis failed (rule results kept): $e');
          if (mounted) {
            state = state.copyWith(isAiLoading: false);
          }
        }
      }
    } catch (e) {
      AppLogger.e(_tag, 'Analysis failed: $e');
      if (mounted) {
        state = RecommendationState(error: 'Analysis failed: $e');
      }
    }
  }

  /// Toggle a recommendation's accepted state.
  Future<void> setAccepted(
    String recommendationId, {
    required bool accepted,
  }) async {
    try {
      await _recsDao.setAccepted(recommendationId, accepted: accepted);

      if (state.result != null && mounted) {
        final updated = state.result!.recommendations.map((r) {
          return r.id == recommendationId
              ? r.copyWith(accepted: accepted)
              : r;
        }).toList();
        state = RecommendationState(
          result: state.result!.copyWith(recommendations: updated),
        );
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to update accepted state: $e');
    }
  }

  void clear() => state = const RecommendationState();

  // ─── Persistence ──────────────────────────────────────────────

  /// Persist recommendations + quality scores to the database.
  Future<void> _persistResult(ProfessionalRecommendationsResult result) async {
    final now = result.generatedAt;

    // Build companions with full v17 audit metadata
    final companions = result.recommendations
        .map((r) => SurveyRecommendationsCompanion.insert(
              id: r.id,
              surveyId: result.surveyId,
              category: r.category.name,
              severity: r.severity.name,
              screenId: r.screenId,
              fieldId: Value(r.fieldId),
              reason: r.reason,
              suggestedText: r.suggestedText,
              createdAt: now,
              sourceType: Value(r.source.key),
              ruleVersion: Value(r.ruleVersion),
              aiModelVersion: Value(r.aiModelVersion),
              confidenceScore: Value(r.confidenceScore),
              generationTimestamp: Value(now.millisecondsSinceEpoch),
              internalReasoning: Value(r.internalReasoning),
              auditHash: Value(r.auditHash),
            ))
        .toList();

    await _recsDao.replaceForSurvey(result.surveyId, companions);

    // Persist quality scores
    if (result.scores != null) {
      final scores = result.scores!;
      await _scoresDao.upsert(SurveyQualityScoresCompanion.insert(
        id: '${result.surveyId}_${now.millisecondsSinceEpoch}',
        surveyId: result.surveyId,
        complianceScore: scores.complianceScore,
        narrativeScore: scores.narrativeScore,
        riskScore: scores.riskScore,
        overallScore: scores.overallScore,
        generatedAt: now,
        engineVersion: result.engineVersion,
      ));
    }
  }

  /// Re-read accepted state from DB and apply to result.
  Future<ProfessionalRecommendationsResult> _applyDbAcceptedState(
    ProfessionalRecommendationsResult result,
  ) async {
    final dbRows = await _recsDao.getBySurvey(result.surveyId);
    final acceptedIds = <String>{};
    for (final row in dbRows) {
      if (row.accepted) acceptedIds.add(row.id);
    }

    final updatedRecs = result.recommendations.map((r) {
      return acceptedIds.contains(r.id) ? r.copyWith(accepted: true) : r;
    }).toList();

    return result.copyWith(recommendations: updatedRecs);
  }
}

/// Provider for the recommendation notifier.
final recommendationProvider = StateNotifierProvider.autoDispose<
    RecommendationNotifier, RecommendationState>(
  (ref) => RecommendationNotifier(
    recommendationsDao: ref.watch(surveyRecommendationsDaoProvider),
    scoresDao: ref.watch(surveyQualityScoresDaoProvider),
    // AI client is optional — passed when available
    // aiClient: ref.watch(aiInspectionClientProvider),
  ),
);
