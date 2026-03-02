import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/sync/v2_sync_helper.dart';
import '../../data/inspection_repository.dart';
import '../../domain/field_phrase_processor.dart';
import '../../domain/models/inspection_models.dart';
import '../../domain/inspection_phrase_engine.dart';

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiClient = ref.watch(apiClientProvider);
  return InspectionRepository(db, apiClient: apiClient);
});

/// Increment to force [inspectionNodesProvider] and
/// [inspectionConditionSummaryProvider] to refetch from the database.
/// This is bumped after [InspectionScreenNotifier.markComplete] so that
/// the overview badge counts and section-page checkmarks update.
final inspectionRefreshProvider = StateProvider<int>((ref) => 0);

final inspectionSectionsProvider =
    FutureProvider<List<InspectionSectionDefinition>>((ref) async {
  final repo = ref.watch(inspectionRepositoryProvider);
  return repo.getSections();
});

final inspectionNodeMapProvider =
    FutureProvider<Map<String, InspectionNodeDefinition>>((ref) async {
  final repo = ref.watch(inspectionRepositoryProvider);
  final tree = await repo.loadTree();
  final map = <String, InspectionNodeDefinition>{};
  for (final section in tree.sections) {
    for (final node in section.nodes) {
      map[node.id] = node;
    }
  }
  return map;
});

final inspectionPhraseTextsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  // Check for admin-edited local override first, fall back to bundled asset.
  String raw;
  try {
    final dir = await getApplicationDocumentsDirectory();
    final localFile = File('${dir.path}/admin/inspection_v2_phrase_texts.json');
    if (await localFile.exists()) {
      raw = await localFile.readAsString();
    } else {
      raw = await rootBundle
          .loadString('assets/property_inspection/phrase_texts.json');
    }
  } catch (e, stack) {
    debugPrint('[inspectionPhraseTextsProvider] Failed to load local override, '
        'falling back to bundled asset: $e\n$stack');
    raw = await rootBundle
        .loadString('assets/property_inspection/phrase_texts.json');
  }
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, value?.toString() ?? ''));
});

final inspectionPhraseEngineProvider = Provider<InspectionPhraseEngine?>((ref) {
  final texts = ref.watch(inspectionPhraseTextsProvider);
  return texts.maybeWhen(
    data: (map) => InspectionPhraseEngine(map),
    orElse: () => null,
  );
});

final inspectionNodesProvider = FutureProvider.family.autoDispose<
    List<InspectionV2Screen>, ({String surveyId, String sectionKey})>(
  (ref, params) async {
    // Re-fetch whenever the refresh counter is bumped (e.g. after markComplete).
    ref.watch(inspectionRefreshProvider);
    final repo = ref.watch(inspectionRepositoryProvider);
    await repo.ensureSurveyInitialized(params.surveyId);
    return repo.getNodesForSection(params.surveyId, params.sectionKey);
  },
);

final inspectionConditionSummaryProvider =
    FutureProvider.family.autoDispose<Map<String, List<String>>, String>(
  (ref, surveyId) async {
    // Re-fetch whenever the refresh counter is bumped (e.g. after markComplete).
    ref.watch(inspectionRefreshProvider);
    final repo = ref.watch(inspectionRepositoryProvider);
    await repo.ensureSurveyInitialized(surveyId);
    return repo.getConditionRatingsBySection(surveyId);
  },
);

final inspectionChildScreensProvider =
    FutureProvider.family.autoDispose<List<InspectionNodeDefinition>, String>(
  (ref, parentId) async {
    final repo = ref.watch(inspectionRepositoryProvider);
    return repo.getChildScreens(parentId);
  },
);

class InspectionScreenState {
  const InspectionScreenState({
    this.isLoading = true,
    this.isSaving = false,
    this.screenDefinition,
    this.screenMeta,
    this.answers = const {},
    this.userNote = '',
    this.editedPhraseText,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final InspectionNodeDefinition? screenDefinition;
  final InspectionV2Screen? screenMeta;
  final Map<String, String> answers;
  final String userNote;

  /// When non-null, the user has manually edited the live preview text.
  /// Auto-generated phrases stop updating until the user taps "Regenerate".
  /// When null, auto-generated phrases are shown and update in real-time.
  final String? editedPhraseText;

  final String? errorMessage;

  /// Whether the preview is showing user-edited text vs auto-generated.
  bool get hasEditedPhrases => editedPhraseText != null;

  InspectionScreenState copyWith({
    bool? isLoading,
    bool? isSaving,
    InspectionNodeDefinition? screenDefinition,
    InspectionV2Screen? screenMeta,
    Map<String, String>? answers,
    String? userNote,
    String? editedPhraseText,
    bool clearEditedPhraseText = false,
    String? errorMessage,
  }) {
    return InspectionScreenState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      screenDefinition: screenDefinition ?? this.screenDefinition,
      screenMeta: screenMeta ?? this.screenMeta,
      answers: answers ?? this.answers,
      userNote: userNote ?? this.userNote,
      editedPhraseText: clearEditedPhraseText
          ? null
          : (editedPhraseText ?? this.editedPhraseText),
      errorMessage: errorMessage,
    );
  }
}

class InspectionScreenNotifier extends StateNotifier<InspectionScreenState> {
  InspectionScreenNotifier(
      this._repo, this._ref, this._surveyId, this._screenId)
      : super(const InspectionScreenState()) {
    _load();
  }

  final InspectionRepository _repo;
  final Ref _ref;
  final String _surveyId;
  final String _screenId;
  static const String _environmentImpactScreenId =
      'activity_energy_environment_impect';
  static const String _otherServiceScreenId = 'activity_other_service';
  static const String _propertyLocationScreenId = 'activity_property_location';

  /// Answers loaded from Drift at screen open — used to determine
  /// CREATE vs UPDATE when queueing answers for sync.
  Map<String, String> _initialAnswers = {};

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final isFirstInit = await _repo.ensureSurveyInitialized(_surveyId);
      final definition = await _repo.getNodeDefinition(_screenId);
      final screenDefinition =
          definition != null && definition.type == InspectionNodeType.screen
              ? definition
              : null;
      final meta = await _repo.getScreen(_surveyId, _screenId);
      final answers = await _repo.getScreenAnswersMap(_surveyId, _screenId);

      _initialAnswers = Map<String, String>.from(answers);

      // If there are previously persisted phrases, load them as the
      // edited text so the user sees exactly what they saved last time.
      String? loadedPhraseText;
      if (meta?.phraseOutput != null && meta!.phraseOutput!.isNotEmpty) {
        try {
          final decoded = jsonDecode(meta.phraseOutput!) as List<dynamic>;
          final phrases = decoded.cast<String>();
          if (phrases.isNotEmpty) {
            loadedPhraseText = phrases.join('\n\n');
          }
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        screenDefinition: screenDefinition,
        screenMeta: meta,
        answers: answers,
        userNote: meta?.userNote ?? '',
        editedPhraseText: loadedPhraseText,
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
    // Clear previously-loaded phrase text so the live preview regenerates
    // from the phrase engine with the latest answers (e.g. price-in-words).
    state = state.copyWith(answers: updated, clearEditedPhraseText: true);
  }

  void setUserNote(String note) {
    state = state.copyWith(userNote: note);
  }

  /// Called when the user manually edits the live preview text.
  void setEditedPhrases(String text) {
    state = state.copyWith(editedPhraseText: text);
  }

  /// Reset to auto-generated phrases (clears user edits).
  void resetPhrases() {
    state = state.copyWith(clearEditedPhraseText: true);
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
      await _persistUserNote();
      await _queueAnswersForSync();

      // Auto-mark as completed when there is at least one non-empty answer.
      // Legacy parity exception: Property Location density requires all
      // mandatory fields before the screen can be considered complete.
      final hasData = _screenId == _propertyLocationScreenId
          ? _isPropertyLocationComplete()
          : state.answers.values.any((v) => v.trim().isNotEmpty);
      if (hasData) {
        final wasCompleted = state.screenMeta?.isCompleted ?? false;
        await _repo.setScreenCompleted(
          surveyId: _surveyId,
          screenId: _screenId,
          isCompleted: true,
        );
        if (!wasCompleted) {
          _ref.read(inspectionRefreshProvider.notifier).state++;
        }
        final currentMeta = state.screenMeta;
        if (currentMeta != null && !currentMeta.isCompleted) {
          state = state.copyWith(
            screenMeta: currentMeta.copyWith(isCompleted: true),
          );
        }
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state =
          state.copyWith(isSaving: false, errorMessage: 'Failed to save: $e');
      return false;
    }
  }

  Future<bool> markComplete() async {
    if (state.screenDefinition == null) return false;
    if (_screenId == _environmentImpactScreenId) {
      final current =
          (state.answers['android_material_design_spinner'] ?? '').trim();
      final potential =
          (state.answers['android_material_design_spinner2'] ?? '').trim();
      if (current.isEmpty || potential.isEmpty) {
        state = state.copyWith(
          errorMessage:
              'Current and Potential are required for Environmental Impact.',
        );
        return false;
      }
    }
    if (_screenId == _otherServiceScreenId) {
      final hasSolarElectricity =
          (state.answers['ch1'] ?? '').trim().toLowerCase() == 'true';
      final hasSolarHotWater =
          (state.answers['ch2'] ?? '').trim().toLowerCase() == 'true';
      if (!hasSolarElectricity && !hasSolarHotWater) {
        state = state.copyWith(
          errorMessage: 'Select at least one Other Service option.',
        );
        return false;
      }
    }
    if (_screenId == _propertyLocationScreenId &&
        !_isPropertyLocationComplete()) {
      state = state.copyWith(
        errorMessage:
            'Established Area, Location Density From, and To are required.',
      );
      return false;
    }
    state = state.copyWith(isSaving: true);
    try {
      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: state.answers,
      );
      await _persistPhraseOutput();
      await _persistUserNote();
      await _queueAnswersForSync();
      await _repo.setScreenCompleted(
        surveyId: _surveyId,
        screenId: _screenId,
        isCompleted: true,
      );
      state = state.copyWith(isSaving: false);

      // Bump the refresh counter so that inspectionNodesProvider (overview
      // badge counts + section-page checkmarks) and
      // inspectionConditionSummaryProvider refetch from the database.
      _ref.read(inspectionRefreshProvider.notifier).state++;

      return true;
    } catch (e) {
      state = state.copyWith(
          isSaving: false, errorMessage: 'Failed to complete: $e');
      return false;
    }
  }

  bool _isPropertyLocationComplete() {
    final wellNewly =
        (state.answers['android_material_design_spinner'] ?? '').trim();
    final from =
        (state.answers['android_material_design_spinner2'] ?? '').trim();
    final to =
        (state.answers['android_material_design_spinner20'] ?? '').trim();
    return wellNewly.isNotEmpty && from.isNotEmpty && to.isNotEmpty;
  }

  /// Legacy parity helper for Environmental Impact screen reset.
  ///
  /// Clears all non-label field values on the current screen, clears edited
  /// phrases and user note, persists immediately, and marks screen incomplete.
  Future<bool> resetCurrentScreen() async {
    if (state.screenDefinition == null) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final cleared = <String, String>{};
      for (final field in state.screenDefinition!.fields) {
        if (field.type == InspectionFieldType.label) continue;
        cleared[field.id] = '';
      }

      await _repo.saveScreenAnswers(
        surveyId: _surveyId,
        screenId: _screenId,
        answers: cleared,
      );
      await _repo.savePhraseOutput(
        surveyId: _surveyId,
        screenId: _screenId,
        phraseJson: '[]',
      );
      await _repo.saveUserNote(
        surveyId: _surveyId,
        screenId: _screenId,
        note: '',
      );
      await _repo.setScreenCompleted(
        surveyId: _surveyId,
        screenId: _screenId,
        isCompleted: false,
      );

      // Keep sync payloads aligned with local reset state.
      state = state.copyWith(
        answers: cleared,
        userNote: '',
        clearEditedPhraseText: true,
      );
      await _queuePhraseOutputForSync();
      await _queueUserNoteForSync();
      await _queueAnswersForSync();

      _ref.read(inspectionRefreshProvider.notifier).state++;
      state = state.copyWith(isSaving: false, errorMessage: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to reset screen: $e',
      );
      return false;
    }
  }

  // ─── Phrase Persistence ──────────────────────────────────────────

  /// Persist phrase output — uses user-edited text when available,
  /// otherwise auto-generates from the phrase engine.
  Future<void> _persistPhraseOutput() async {
    if (state.screenDefinition == null) return;
    try {
      final List<String> phrases;
      if (state.editedPhraseText != null) {
        // User has manually edited the preview — persist their text.
        // Split by double-newline (paragraph breaks) to keep the
        // List<String> format that the export pipeline expects.
        phrases = state.editedPhraseText!
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
      } else {
        // Auto-generate from phrase engine (original behaviour).
        final phraseEngine = _ref.read(inspectionPhraseEngineProvider);
        final enginePhrases =
            phraseEngine?.buildPhrases(_screenId, state.answers) ??
                const <String>[];
        final fieldPhrases = FieldPhraseProcessor.buildFieldPhrases(
            state.screenDefinition!.fields, state.answers);
        phrases = [...enginePhrases, ...fieldPhrases];
      }

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
      debugPrint('[InspectionSync] Failed to persist phrase output: $e');
    }
  }

  /// Queue a section UPDATE with aggregated phraseOutput from all
  /// screens in this screen's section.
  ///
  /// CRITICAL: Payload includes full section metadata (surveyId, title,
  /// order, sectionTypeKey) so the upsert fallback in SyncManager can
  /// create the section if the server returns 404. V2 sections are virtual
  /// entities (deterministic UUIDs) that don't exist in the survey_sections
  /// table — without enriched payloads, the fallback has nothing to work with.
  Future<void> _queuePhraseOutputForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sectionKey =
          await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;

      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);
      final aggregatedJson =
          await _repo.getAggregatedPhraseOutput(_surveyId, sectionKey);
      final sectionMeta = await _getSectionMeta(sectionKey);

      await syncManager.queueSync(
        entityType: SyncEntityType.section,
        entityId: sectionId,
        action: SyncAction.update,
        payload: {
          'surveyId': _surveyId,
          'title': sectionMeta?.title ?? sectionKey,
          'order': sectionMeta?.order ?? 0,
          'sectionTypeKey': sectionKey,
          'phraseOutput': aggregatedJson,
        },
      );
    } catch (e) {
      debugPrint('[InspectionSync] Failed to queue phrase output: $e');
    }
  }

  // ─── User Note Persistence ──────────────────────────────────────

  /// Persist the surveyor's custom note for this screen and queue for sync.
  Future<void> _persistUserNote() async {
    try {
      await _repo.saveUserNote(
        surveyId: _surveyId,
        screenId: _screenId,
        note: state.userNote.trim(),
      );
      await _queueUserNoteForSync();
    } catch (e) {
      // Non-fatal: note persistence should not block screen save.
      debugPrint('[InspectionSync] Failed to persist user note: $e');
    }
  }

  /// Queue a section UPDATE with aggregated userNotes from all
  /// screens in this screen's section.
  ///
  /// CRITICAL: Payload includes full section metadata — see
  /// [_queuePhraseOutputForSync] for rationale.
  Future<void> _queueUserNoteForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);
      final sectionKey =
          await _repo.getSectionKeyForScreen(_surveyId, _screenId);
      if (sectionKey == null) return;

      final sectionId = V2SyncHelper.sectionSyncId(_surveyId, sectionKey);
      final aggregatedJson =
          await _repo.getAggregatedUserNotes(_surveyId, sectionKey);
      final sectionMeta = await _getSectionMeta(sectionKey);

      await syncManager.queueSync(
        entityType: SyncEntityType.section,
        entityId: sectionId,
        action: SyncAction.update,
        payload: {
          'surveyId': _surveyId,
          'title': sectionMeta?.title ?? sectionKey,
          'order': sectionMeta?.order ?? 0,
          'sectionTypeKey': sectionKey,
          'userNotes': aggregatedJson,
        },
      );
    } catch (e) {
      debugPrint('[InspectionSync] Failed to queue user notes: $e');
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
      debugPrint(
          '[InspectionSync] Queued ${sections.length} V2 sections for survey $_surveyId');
    } catch (e) {
      // Non-fatal: local data is already saved, sync will be retried.
      debugPrint('[InspectionSync] Failed to queue sections: $e');
    }
  }

  /// Look up V2 section metadata (title, order) by sectionKey from the tree.
  Future<({String title, int order})?> _getSectionMeta(
      String sectionKey) async {
    try {
      final sections = await _repo.getV2SectionMeta();
      final match = sections.where((s) => s.key == sectionKey).firstOrNull;
      return match != null ? (title: match.title, order: match.order) : null;
    } catch (_) {
      return null;
    }
  }

  /// Queue answer sync entries for changed/new answers on this screen.
  Future<void> _queueAnswersForSync() async {
    try {
      final syncManager = _ref.read(syncManagerProvider);

      // Resolve sectionKey → deterministic section UUID for the FK.
      final sectionKey =
          await _repo.getSectionKeyForScreen(_surveyId, _screenId);
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
        final answerId =
            V2SyncHelper.answerSyncId(_surveyId, _screenId, fieldKey);

        await syncManager.queueSync(
          entityType: SyncEntityType.answer,
          entityId: answerId,
          action: isNew ? SyncAction.create : SyncAction.update,
          payload: {
            'sectionId': sectionId,
            'surveyId': _surveyId,
            'questionKey': fieldKey,
            'value': value,
          },
        );
      }

      // Update initial answers so subsequent saves detect the right diff.
      _initialAnswers = Map<String, String>.from(state.answers);
    } catch (e) {
      // Non-fatal: local data is already saved, sync will be retried.
      debugPrint('[InspectionSync] Failed to queue answers: $e');
    }
  }
}

final inspectionScreenProvider = StateNotifierProvider.autoDispose.family<
    InspectionScreenNotifier,
    InspectionScreenState,
    ({String surveyId, String screenId})>(
  (ref, params) {
    final repo = ref.watch(inspectionRepositoryProvider);
    return InspectionScreenNotifier(
        repo, ref, params.surveyId, params.screenId);
  },
);
