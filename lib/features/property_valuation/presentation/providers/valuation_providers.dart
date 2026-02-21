import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/sync/v2_sync_helper.dart';
import '../../data/valuation_repository.dart';
import '../../domain/valuation_phrase_engine.dart';
import '../../../property_inspection/domain/field_phrase_processor.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';

final valuationRepositoryProvider = Provider<ValuationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return ValuationRepository(db, apiClient: apiClient);
});

/// Increment to force [valuationNodesProvider] to refetch from the database.
/// Bumped after [ValuationScreenNotifier.markComplete].
final valuationRefreshProvider = StateProvider<int>((ref) => 0);

final valuationSectionsProvider = FutureProvider<List<InspectionSectionDefinition>>((ref) async {
  final repo = ref.watch(valuationRepositoryProvider);
  return repo.getSections();
});

final valuationNodeMapProvider = FutureProvider<Map<String, InspectionNodeDefinition>>((ref) async {
  final repo = ref.watch(valuationRepositoryProvider);
  final tree = await repo.loadTree();
  final map = <String, InspectionNodeDefinition>{};
  for (final section in tree.sections) {
    for (final node in section.nodes) {
      map[node.id] = node;
    }
  }
  return map;
});

final valuationNodesProvider = FutureProvider.family
    .autoDispose<List<InspectionV2Screen>, ({String surveyId, String sectionKey})>(
  (ref, params) async {
    // Re-fetch whenever the refresh counter is bumped (e.g. after markComplete).
    ref.watch(valuationRefreshProvider);
    final repo = ref.watch(valuationRepositoryProvider);
    await repo.ensureSurveyInitialized(params.surveyId);
    return repo.getNodesForSection(params.surveyId, params.sectionKey);
  },
);

final valuationChildScreensProvider = FutureProvider.family
    .autoDispose<List<InspectionNodeDefinition>, String>(
  (ref, parentId) async {
    final repo = ref.watch(valuationRepositoryProvider);
    return repo.getChildScreens(parentId);
  },
);

final valuationPhraseEngineProvider = Provider<ValuationPhraseEngine>((ref) {
  return const ValuationPhraseEngine();
});

class ValuationScreenState {
  const ValuationScreenState({
    this.isLoading = true,
    this.isSaving = false,
    this.screenDefinition,
    this.screenMeta,
    this.answers = const {},
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final InspectionNodeDefinition? screenDefinition;
  final InspectionV2Screen? screenMeta;
  final Map<String, String> answers;
  final String? errorMessage;

  ValuationScreenState copyWith({
    bool? isLoading,
    bool? isSaving,
    InspectionNodeDefinition? screenDefinition,
    InspectionV2Screen? screenMeta,
    Map<String, String>? answers,
    String? errorMessage,
  }) {
    return ValuationScreenState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      screenDefinition: screenDefinition ?? this.screenDefinition,
      screenMeta: screenMeta ?? this.screenMeta,
      answers: answers ?? this.answers,
      errorMessage: errorMessage,
    );
  }
}

class ValuationScreenNotifier extends StateNotifier<ValuationScreenState> {
  ValuationScreenNotifier(this._repo, this._ref, this._surveyId, this._screenId)
      : super(const ValuationScreenState()) {
    _load();
  }

  final ValuationRepository _repo;
  final Ref _ref;
  final String _surveyId;
  final String _screenId;

  /// Answers loaded from Drift at screen open — used to determine
  /// CREATE vs UPDATE when queueing answers for sync.
  Map<String, String> _initialAnswers = {};

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final isFirstInit = await _repo.ensureSurveyInitialized(_surveyId);
      final definition = await _repo.getNodeDefinition(_screenId);
      final screenDefinition =
          definition != null && definition.type == InspectionNodeType.screen ? definition : null;
      final meta = await _repo.getScreen(_surveyId, _screenId);
      final answers = await _repo.getScreenAnswersMap(_surveyId, _screenId);

      _initialAnswers = Map<String, String>.from(answers);

      state = state.copyWith(
        isLoading: false,
        screenDefinition: screenDefinition,
        screenMeta: meta,
        answers: answers,
      );

      // Queue V2 section CREATEs on first survey initialization so the
      // backend has parent Section records before any answers arrive.
      if (isFirstInit) {
        await _queueV2SectionsForSync();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load screen: $e',
      );
    }
  }

  void setAnswer(String fieldKey, String value) {
    final updated = Map<String, String>.from(state.answers);
    updated[fieldKey] = value;
    state = state.copyWith(answers: updated);
  }

  Future<bool> saveDraft() async {
    if (state.screenDefinition == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: state.answers,
      );
      await _persistPhraseOutput();
      await _queueAnswersForSync();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save: $e');
      return false;
    }
  }

  Future<bool> markComplete() async {
    if (state.screenDefinition == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: state.answers,
      );
      await _persistPhraseOutput();
      await _queueAnswersForSync();
      await _repo.setScreenCompleted(
        surveyId: _surveyId,
        screenId: _screenId,
        isCompleted: true,
      );
      state = state.copyWith(isSaving: false);

      // Bump the refresh counter so that valuationNodesProvider (overview
      // badge counts + section-page checkmarks) refetches from the database.
      _ref.read(valuationRefreshProvider.notifier).state++;

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to complete: $e');
      return false;
    }
  }

  // ─── Phrase Persistence ──────────────────────────────────────────

  /// Generate phrase engine output and persist to local Drift + queue
  /// a section UPDATE for sync so the backend receives the phrases.
  Future<void> _persistPhraseOutput() async {
    if (state.screenDefinition == null) return;
    try {
      final phraseEngine = _ref.read(valuationPhraseEngineProvider);
      final enginePhrases = phraseEngine.buildPhrases(_screenId, state.answers);
      final fieldPhrases =
          FieldPhraseProcessor.buildFieldPhrases(state.screenDefinition!.fields, state.answers);
      final phrases = [...enginePhrases, ...fieldPhrases];

      final phraseJson = jsonEncode(phrases);
      await _repo.savePhraseOutput(
        surveyId: _surveyId,
        screenId: _screenId,
        phraseJson: phraseJson,
      );

      // Queue aggregated section phrase output for sync.
      await _queuePhraseOutputForSync();
    } catch (e) {
      // Non-fatal: phrase persistence should not block screen save.
      debugPrint('[ValuationSync] Failed to persist phrase output: $e');
    }
  }

  /// Queue a section UPDATE with aggregated phraseOutput from all
  /// screens in this screen's section.
  Future<void> _queuePhraseOutputForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sectionKey = await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;

      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);
      final aggregatedJson = await _repo.getAggregatedPhraseOutput(_surveyId, sectionKey);

      await syncManager.queueSync(
        entityType: SyncEntityType.section,
        entityId: sectionId,
        action: SyncAction.update,
        payload: {
          'phraseOutput': aggregatedJson,
        },
      );
    } catch (e) {
      debugPrint('[ValuationSync] Failed to queue phrase output: $e');
    }
  }

  // ─── Sync Helpers ────────────────────────────────────────────────

  /// Queue V2 section CREATE entries so the backend has parent Section
  /// records before any answers arrive (TIER 2 → TIER 3 dependency).
  Future<void> _queueV2SectionsForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sections = await _repo.getV2SectionMeta();

      for (final section in sections) {
        final sectionId = V2SyncHelper.sectionSyncId(_surveyId, section.key);
        await syncManager.queueSync(
          entityType: SyncEntityType.section,
          entityId: sectionId,
          action: SyncAction.create,
          payload: {
            'surveyId': _surveyId,
            'title': section.title,
            'order': section.order,
            'sectionTypeKey': section.key,
          },
        );
      }
      debugPrint('[ValuationSync] Queued ${sections.length} V2 sections for survey $_surveyId');
    } catch (e) {
      // Non-fatal: local data is already saved, sync will be retried.
      debugPrint('[ValuationSync] Failed to queue sections: $e');
    }
  }

  /// Queue answer sync entries for changed/new answers on this screen.
  Future<void> _queueAnswersForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);

      // Resolve sectionKey → deterministic section UUID for the FK.
      final sectionKey = await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;
      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);

      for (final entry in state.answers.entries) {
        final fieldKey = entry.key;
        final value = entry.value;

        // Skip empty values — backend rejects with @IsNotEmpty().
        if (value.trim().isEmpty) continue;

        // Skip unchanged answers — no need to re-queue.
        if (_initialAnswers[fieldKey] == value) continue;

        final isNew = !_initialAnswers.containsKey(fieldKey);
        final answerId = V2SyncHelper.answerSyncId(_surveyId, _screenId, fieldKey);

        await syncManager.queueSync(
          entityType: SyncEntityType.answer,
          entityId: answerId,
          action: isNew ? SyncAction.create : SyncAction.update,
          payload: {
            'sectionId': sectionId,
            'questionKey': fieldKey,
            'value': value,
          },
        );
      }

      // Update initial answers so subsequent saves detect the right diff.
      _initialAnswers = Map<String, String>.from(state.answers);
    } catch (e) {
      // Non-fatal: local data is already saved, sync will be retried.
      debugPrint('[ValuationSync] Failed to queue answers: $e');
    }
  }
}

final valuationScreenProvider = StateNotifierProvider.autoDispose.family
    <ValuationScreenNotifier, ValuationScreenState, ({String surveyId, String screenId})>(
  (ref, params) {
    final repo = ref.watch(valuationRepositoryProvider);
    return ValuationScreenNotifier(repo, ref, params.surveyId, params.screenId);
  },
);
