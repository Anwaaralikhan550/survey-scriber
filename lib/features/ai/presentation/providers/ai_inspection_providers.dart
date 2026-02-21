import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_observability.dart';
import '../../../../core/ai/pii_redactor.dart';
import '../../../../core/feature_flags/feature_flag_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_inspection/presentation/providers/inspection_providers.dart';
import '../../../property_valuation/presentation/providers/valuation_providers.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../data/services/ai_data_formatter.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/services/ai_client.dart';
import 'ai_providers.dart';

// ── Core providers ────────────────────────────────────────────────

/// PII redactor — stateless, singleton-safe.
final piiRedactorProvider = Provider<PiiRedactor>((ref) => PiiRedactor());

/// data formatter.
final aiDataFormatterProvider = Provider<AiDataFormatter>((ref) {
  return AiDataFormatter(redactor: ref.watch(piiRedactorProvider));
});

/// Observability singleton.
final aiObservabilityProvider = Provider<AiObservability>((ref) {
  return AiObservability.instance;
});

/// The AI client — main entry point for all AI features.
final aiInspectionClientProvider = Provider<AiInspectionClient>((ref) {
  return AiInspectionClient(
    repository: ref.watch(aiRepositoryProvider),
    featureFlags: ref.watch(featureFlagServiceProvider),
    formatter: ref.watch(aiDataFormatterProvider),
    observability: ref.watch(aiObservabilityProvider),
  );
});

/// Metrics snapshot provider (re-reads on demand).
final aiMetricsProvider = Provider<AiMetricsSnapshot>((ref) {
  return ref.watch(aiObservabilityProvider).snapshot;
});

// ── Data loaders for AI features ──────────────────────────────────

/// Loads the survey tree.
final aiInspectionTreeProvider = FutureProvider<InspectionTreePayload>((ref) async {
  final repo = ref.watch(inspectionRepositoryProvider);
  return repo.loadTree();
});

/// Loads ALL screen answers for a survey (for AI features that need full context).
final aiInspectionAllAnswersProvider = FutureProvider.family
    .autoDispose<Map<String, Map<String, String>>, String>(
  (ref, surveyId) async {
    final repo = ref.watch(inspectionRepositoryProvider);
    final tree = await repo.loadTree();
    final result = <String, Map<String, String>>{};
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = await repo.getScreenAnswersMap(surveyId, node.id);
        if (answers.isNotEmpty) {
          result[node.id] = answers;
        }
      }
    }
    return result;
  },
);

/// Loads the valuation survey tree.
final aiValuationTreeProvider = FutureProvider<InspectionTreePayload>((ref) async {
  final repo = ref.watch(valuationRepositoryProvider);
  return repo.loadTree();
});

/// Loads ALL valuation screen answers for a survey.
final aiValuationAllAnswersProvider = FutureProvider.family
    .autoDispose<Map<String, Map<String, String>>, String>(
  (ref, surveyId) async {
    final repo = ref.watch(valuationRepositoryProvider);
    final tree = await repo.loadTree();
    final result = <String, Map<String, String>>{};
    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = await repo.getScreenAnswersMap(surveyId, node.id);
        if (answers.isNotEmpty) {
          result[node.id] = answers;
        }
      }
    }
    return result;
  },
);

// ── Report Narrative ──────────────────────────────────────────────

class AiReportState {
  const AiReportState({
    this.response,
    this.isLoading = false,
    this.error,
    this.redactionMapping = const {},
  });

  final AiReportResponse? response;
  final bool isLoading;
  final String? error;
  final Map<String, String> redactionMapping;

  bool get hasResponse => response != null;
  bool get hasError => error != null;

  AiReportState copyWith({
    AiReportResponse? response,
    bool? isLoading,
    String? error,
    Map<String, String>? redactionMapping,
  }) =>
      AiReportState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        redactionMapping: redactionMapping ?? this.redactionMapping,
      );
}

class AiReportNotifier extends StateNotifier<AiReportState> {
  AiReportNotifier(this._client) : super(const AiReportState());

  final AiInspectionClient _client;

  Future<void> generate({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await _client.generateReport(
        surveyId: surveyId,
        survey: survey,
        tree: tree,
        allAnswers: allAnswers,
      );
      if (mounted) {
        state = AiReportState(
          response: result.response,
          redactionMapping: result.redactionMapping,
        );
      }
    } catch (e) {
      AppLogger.e('AiReport', 'Failed: $e');
      if (mounted) {
        state = AiReportState(error: _friendlyError(e));
      }
    }
  }

  void clear() => state = const AiReportState();
}

final aiInspectionReportProvider =
    StateNotifierProvider.autoDispose<AiReportNotifier, AiReportState>(
  (ref) => AiReportNotifier(ref.watch(aiInspectionClientProvider)),
);

// ── Consistency Check ─────────────────────────────────────────────

class AiConsistencyState {
  const AiConsistencyState({
    this.response,
    this.isLoading = false,
    this.error,
    this.redactionMapping = const {},
  });

  final AiConsistencyResponse? response;
  final bool isLoading;
  final String? error;
  final Map<String, String> redactionMapping;

  bool get hasResponse => response != null;
  bool get hasError => error != null;

  AiConsistencyState copyWith({
    AiConsistencyResponse? response,
    bool? isLoading,
    String? error,
    Map<String, String>? redactionMapping,
  }) =>
      AiConsistencyState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        redactionMapping: redactionMapping ?? this.redactionMapping,
      );
}

class AiConsistencyNotifier extends StateNotifier<AiConsistencyState> {
  AiConsistencyNotifier(this._client) : super(const AiConsistencyState());

  final AiInspectionClient _client;

  Future<void> check({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await _client.checkConsistency(
        surveyId: surveyId,
        tree: tree,
        allAnswers: allAnswers,
      );
      if (mounted) {
        state = AiConsistencyState(
          response: result.response,
          redactionMapping: result.redactionMapping,
        );
      }
    } catch (e) {
      AppLogger.e('AiConsistency', 'Failed: $e');
      if (mounted) {
        state = AiConsistencyState(error: _friendlyError(e));
      }
    }
  }

  void clear() => state = const AiConsistencyState();
}

final aiInspectionConsistencyProvider = StateNotifierProvider.autoDispose<
    AiConsistencyNotifier, AiConsistencyState>(
  (ref) => AiConsistencyNotifier(ref.watch(aiInspectionClientProvider)),
);

// ── Risk Assessment ───────────────────────────────────────────────

class AiRiskState {
  const AiRiskState({
    this.response,
    this.isLoading = false,
    this.error,
    this.redactionMapping = const {},
  });

  final AiRiskSummaryResponse? response;
  final bool isLoading;
  final String? error;
  final Map<String, String> redactionMapping;

  bool get hasResponse => response != null;
  bool get hasError => error != null;

  AiRiskState copyWith({
    AiRiskSummaryResponse? response,
    bool? isLoading,
    String? error,
    Map<String, String>? redactionMapping,
  }) =>
      AiRiskState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        redactionMapping: redactionMapping ?? this.redactionMapping,
      );
}

class AiRiskNotifier extends StateNotifier<AiRiskState> {
  AiRiskNotifier(this._client) : super(const AiRiskState());

  final AiInspectionClient _client;

  Future<void> generate({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await _client.generateRiskSummary(
        surveyId: surveyId,
        survey: survey,
        tree: tree,
        allAnswers: allAnswers,
      );
      if (mounted) {
        state = AiRiskState(
          response: result.response,
          redactionMapping: result.redactionMapping,
        );
      }
    } catch (e) {
      AppLogger.e('AiRisk', 'Failed: $e');
      if (mounted) {
        state = AiRiskState(error: _friendlyError(e));
      }
    }
  }

  void clear() => state = const AiRiskState();
}

final aiInspectionRiskProvider =
    StateNotifierProvider.autoDispose<AiRiskNotifier, AiRiskState>(
  (ref) => AiRiskNotifier(ref.watch(aiInspectionClientProvider)),
);

// ── Recommendations ──────────────────────────────────────────────

class AiRecommendationsState {
  const AiRecommendationsState({
    this.response,
    this.isLoading = false,
    this.error,
    this.redactionMapping = const {},
  });

  final AiRecommendationsResponse? response;
  final bool isLoading;
  final String? error;
  final Map<String, String> redactionMapping;

  bool get hasResponse => response != null;
  bool get hasError => error != null;

  AiRecommendationsState copyWith({
    AiRecommendationsResponse? response,
    bool? isLoading,
    String? error,
    Map<String, String>? redactionMapping,
  }) =>
      AiRecommendationsState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        redactionMapping: redactionMapping ?? this.redactionMapping,
      );
}

class AiRecommendationsNotifier
    extends StateNotifier<AiRecommendationsState> {
  AiRecommendationsNotifier(this._client)
      : super(const AiRecommendationsState());

  final AiInspectionClient _client;

  Future<void> generate({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    try {
      final result = await _client.generateRecommendations(
        surveyId: surveyId,
        survey: survey,
        tree: tree,
        allAnswers: allAnswers,
      );
      if (mounted) {
        state = AiRecommendationsState(
          response: result.response,
          redactionMapping: result.redactionMapping,
        );
      }
    } catch (e) {
      AppLogger.e('AiRecommendations', 'Failed: $e');
      if (mounted) {
        state = AiRecommendationsState(error: _friendlyError(e));
      }
    }
  }

  void clear() => state = const AiRecommendationsState();
}

final aiInspectionRecommendationsProvider = StateNotifierProvider.autoDispose<
    AiRecommendationsNotifier, AiRecommendationsState>(
  (ref) => AiRecommendationsNotifier(ref.watch(aiInspectionClientProvider)),
);

// ── Helpers ───────────────────────────────────────────────────────

/// Convert exceptions into user-friendly error messages.
String _friendlyError(Object e) {
  if (e is AiFeatureDisabledException) {
    return '${e.feature.displayName} is currently disabled.';
  }
  if (e is TimeoutException) {
    return 'AI request timed out. Please try again.';
  }
  final msg = e.toString().toLowerCase();
  if (msg.contains('503') || msg.contains('service unavailable')) {
    return 'AI service is temporarily unavailable.';
  }
  if (msg.contains('429') || msg.contains('rate limit')) {
    return 'Too many AI requests. Please wait a moment.';
  }
  if (msg.contains('no internet') || msg.contains('network')) {
    return 'No internet connection. Please check your network.';
  }
  return 'Failed to generate AI response. Please try again.';
}
