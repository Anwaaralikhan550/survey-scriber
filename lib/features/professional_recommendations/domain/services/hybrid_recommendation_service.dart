import 'package:uuid/uuid.dart';

import '../../../../core/ai/pii_redactor.dart';
import '../../../ai/domain/services/ai_client.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../models/professional_recommendation.dart';
import 'recommendation_engine.dart';

/// Orchestrates the hybrid professional intelligence engine.
///
/// **Layer 1** — Deterministic rule engine (offline, fast, auditable).
/// **Layer 2** — AI professional narrative engine (online, async, optional).
/// **Control** — Validates AI output, deduplicates, merges into unified result.
///
/// The rule engine ALWAYS runs first. AI is optional and additive — it
/// never overrides rule engine output.
class HybridRecommendationService {
  HybridRecommendationService({
    this.aiClient,
    PiiRedactor? redactor,
  }) : _redactor = redactor ?? PiiRedactor();

  final AiInspectionClient? aiClient;
  final PiiRedactor _redactor;
  static const _uuid = Uuid();

  /// Run the full hybrid analysis pipeline.
  ///
  /// 1. Rule engine runs synchronously (pure function).
  /// 2. If [includeAi] is true and [aiClient] is available, AI analysis
  ///    runs asynchronously and results are merged.
  /// 3. Control layer validates AI output, deduplicates, assigns audit hashes.
  /// 4. Quality scores come from the rule engine (deterministic).
  Future<ProfessionalRecommendationsResult> analyze({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required bool isValuation,
    bool includeAi = false,
  }) async {
    // ── Layer 1: Rule Engine (always runs) ─────────────────────────
    final ruleResult = RecommendationEngine.analyze(
      surveyId: surveyId,
      tree: tree,
      allAnswers: allAnswers,
      isValuation: isValuation,
    );

    if (!includeAi || aiClient == null) {
      return ruleResult;
    }

    // ── Layer 2: AI Analysis (optional, async) ─────────────────────
    List<ProfessionalRecommendation> aiRecs;
    try {
      aiRecs = await _runAiAnalysis(
        surveyId: surveyId,
        tree: tree,
        allAnswers: allAnswers,
        ruleResult: ruleResult,
        isValuation: isValuation,
      );
    } catch (_) {
      // AI failure is non-fatal — return rule results only.
      // Error is already logged by AiObservability.
      return ruleResult;
    }

    // ── Control Layer: Validate + Merge ────────────────────────────
    final validated = _validateAiRecommendations(aiRecs);
    final deduped = _deduplicateAgainstRules(validated, ruleResult.recommendations);

    // Merge: rules first (deterministic), then AI (additive)
    final merged = [...ruleResult.recommendations, ...deduped];
    merged.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    return ruleResult.copyWith(recommendations: merged);
  }

  /// Run AI professional analysis and convert response to domain models.
  Future<List<ProfessionalRecommendation>> _runAiAnalysis({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required ProfessionalRecommendationsResult ruleResult,
    required bool isValuation,
  }) async {
    // Summarise rule results as context for AI (no full details, just keys)
    final ruleContext = ruleResult.recommendations.map((r) => {
          'screenId': r.screenId,
          'category': r.category.name,
          'severity': r.severity.name,
          'reason': r.reason,
        }).toList();

    final aiResult = await aiClient!.analyzeProfessionally(
      surveyId: surveyId,
      tree: tree,
      allAnswers: allAnswers,
      ruleRecommendations: ruleContext,
      isValuation: isValuation,
    );

    // Convert AI response items to domain models
    return aiResult.response.recommendations.map((item) {
      // Restore PII in AI-generated text
      final reason = _redactor.unredact(
        item.reason,
        aiResult.redactionMapping,
      );
      final suggestedText = _redactor.unredact(
        item.suggestedText,
        aiResult.redactionMapping,
      );

      final category = _parseCategory(item.category);
      final severity = _parseSeverity(item.severity);

      final auditHash = ProfessionalRecommendation.computeAuditHash(
        category: category.name,
        severity: severity.name,
        screenId: item.screenId,
        reason: reason,
        suggestedText: suggestedText,
        source: RecommendationSource.ai.key,
      );

      return ProfessionalRecommendation(
        id: _uuid.v4(),
        category: category,
        severity: severity,
        screenId: item.screenId,
        fieldId: item.fieldId,
        reason: reason,
        suggestedText: suggestedText,
        source: RecommendationSource.ai,
        aiModelVersion: aiResult.response.modelVersion,
        confidenceScore: item.confidence,
        internalReasoning: item.reasoning,
        auditHash: auditHash,
      );
    }).toList();
  }

  // ─── Control Layer: Validation ──────────────────────────────────

  /// Validate AI recommendations — reject low confidence, empty text,
  /// and items that fail structural checks.
  List<ProfessionalRecommendation> _validateAiRecommendations(
    List<ProfessionalRecommendation> aiRecs,
  ) {
    return aiRecs.where((rec) {
      // Reject low-confidence recommendations
      if (rec.confidenceScore != null && rec.confidenceScore! < 0.3) {
        return false;
      }

      // Reject empty or trivially short text
      if (rec.reason.trim().length < 10) return false;
      if (rec.suggestedText.trim().length < 10) return false;

      // Reject if screenId is empty (hallucinated reference)
      if (rec.screenId.trim().isEmpty) return false;

      return true;
    }).toList();
  }

  /// Remove AI recommendations that duplicate existing rule engine output.
  ///
  /// A duplicate is defined as matching screenId + category. The rule
  /// engine version always takes precedence (it's deterministic and
  /// legally defensible without AI disclaimers).
  List<ProfessionalRecommendation> _deduplicateAgainstRules(
    List<ProfessionalRecommendation> aiRecs,
    List<ProfessionalRecommendation> ruleRecs,
  ) {
    final ruleKeys = ruleRecs
        .map((r) => '${r.screenId}|${r.category.name}')
        .toSet();

    return aiRecs.where((r) {
      final key = '${r.screenId}|${r.category.name}';
      return !ruleKeys.contains(key);
    }).toList();
  }

  // ─── Helpers ────────────────────────────────────────────────────

  static RecommendationCategory _parseCategory(String value) {
    for (final c in RecommendationCategory.values) {
      if (c.name == value) return c;
    }
    return RecommendationCategory.narrativeStrength;
  }

  static RecommendationSeverity _parseSeverity(String value) {
    for (final s in RecommendationSeverity.values) {
      if (s.name == value) return s;
    }
    return RecommendationSeverity.moderate;
  }
}
