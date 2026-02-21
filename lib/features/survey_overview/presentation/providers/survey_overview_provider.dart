import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_action.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../../shared/domain/services/survey_action_resolver.dart';
import '../../../../shared/domain/services/survey_status_engine.dart';
import '../../../surveys/domain/repositories/survey_repository.dart';
import '../../../surveys/presentation/providers/survey_invalidation.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';

/// State for Survey Overview screen
class SurveyOverviewState {
  const SurveyOverviewState({
    this.survey,
    this.sections = const [],
    this.isLoading = true,
    this.errorMessage,
    this.isUpdatingStatus = false,
  });

  final Survey? survey;
  final List<SurveySection> sections;
  final bool isLoading;
  final String? errorMessage;
  final bool isUpdatingStatus;

  // Engine instances
  static const _statusEngine = SurveyStatusEngine.instance;
  static const _resumeService = SmartResumeService.instance;
  static const _actionResolver = SurveyActionResolver.instance;

  bool get hasError => errorMessage != null;
  bool get hasSurvey => survey != null;

  /// Get resume context for smart navigation
  ResumeContext get resumeContext => _resumeService.getResumeContext(sections);

  /// Get primary action label based on survey status with smart resume
  String get primaryActionLabel {
    if (survey == null) return '';
    final nextSectionName = resumeContext.targetSectionName;
    return _statusEngine.primaryActionLabel(
      survey!.status,
      nextSectionName: nextSectionName,
    );
  }

  /// Check if primary action is enabled
  bool get isPrimaryActionEnabled {
    if (survey == null) return false;
    return _statusEngine.isPrimaryActionEnabled(survey!.status);
  }

  /// Check if primary action should navigate to a section
  bool get shouldNavigateToSection {
    if (survey == null) return false;
    return _statusEngine.shouldNavigateToSection(survey!.status);
  }

  /// Get the target section for navigation (smart resume)
  SurveySection? get targetSection => resumeContext.targetSection;

  /// Get the next status when primary action is tapped
  SurveyStatus? get nextStatusOnPrimaryAction {
    if (survey == null) return null;
    return _statusEngine.nextStatusOnPrimaryAction(survey!.status);
  }

  // ============== Unified Actions System ==============

  /// Get the resolved primary action for the current survey state
  SurveyActionUiModel? get primaryAction {
    if (survey == null) return null;
    return _actionResolver.resolvePrimaryAction(
      survey: survey!,
      sections: sections,
    );
  }

  /// Get all resolved secondary actions for the current survey state
  List<SurveyActionUiModel> get secondaryActions {
    if (survey == null) return [];
    return _actionResolver.resolveSecondaryActions(
      survey: survey!,
      sections: sections,
    );
  }

  /// Check if any actions are available
  bool get hasActions => primaryAction != null || secondaryActions.isNotEmpty;

  SurveyOverviewState copyWith({
    Survey? survey,
    List<SurveySection>? sections,
    bool? isLoading,
    String? errorMessage,
    bool? isUpdatingStatus,
  }) =>
      SurveyOverviewState(
        survey: survey ?? this.survey,
        sections: sections ?? this.sections,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      );
}

/// StateNotifier for Survey Overview
class SurveyOverviewNotifier extends StateNotifier<SurveyOverviewState> {
  SurveyOverviewNotifier(this._repository, this._surveyId, this._ref)
      : super(const SurveyOverviewState()) {
    loadSurveyOverview();
  }

  final SurveyRepository _repository;
  final String _surveyId;
  final Ref _ref;

  static const _statusEngine = SurveyStatusEngine.instance;
  static const _actionResolver = SurveyActionResolver.instance;

  /// Queue a status update for backend sync (offline-first).
  /// Reuses the existing sync queue merge logic — if the survey already has
  /// a pending CREATE, the status field is merged into that payload.
  Future<void> _queueStatusSync(Survey survey, SurveyStatus newStatus) async {
    try {
      await _ref.read(syncStateProvider.notifier).queueSync(
        entityType: SyncEntityType.survey,
        entityId: survey.id,
        action: SyncAction.update,
        payload: {
          'status': newStatus.toBackendString(),
        },
      );
    } catch (_) {
      // Non-fatal: local status is saved, sync will catch up later
    }
  }

  /// Load survey and sections
  Future<void> loadSurveyOverview() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final survey = await _repository.getSurveyById(_surveyId);
      if (!mounted) return;
      if (survey == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Survey not found',
        );
        return;
      }

      final sections = await _repository.getSectionsForSurvey(_surveyId);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        survey: survey,
        sections: sections,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load survey',
      );
    }
  }

  /// Ensure the survey is at least inProgress before entering any section.
  /// This is the single entry-point guard that prevents a survey from
  /// reaching 100% completion while still in draft status.
  /// Idempotent: no-op if already inProgress or beyond.
  Future<void> ensureSurveyStarted() async {
    final survey = state.survey;
    if (survey == null) return;
    if (survey.status != SurveyStatus.draft) return;

    const nextStatus = SurveyStatus.inProgress;
    if (!_statusEngine.canTransition(survey.status, nextStatus)) return;

    try {
      await _repository.updateSurveyStatus(_surveyId, nextStatus);
      await _queueStatusSync(survey, nextStatus);
      if (!mounted) return;

      state = state.copyWith(
        survey: survey.copyWith(status: nextStatus),
      );

      SurveyInvalidation.afterSurveyMutation(_ref, _surveyId);
    } catch (_) {
      // Non-fatal: section navigation should still proceed
    }
  }

  /// Handle primary action button tap.
  /// Updates status if needed and returns the target section ID for navigation.
  Future<String?> handlePrimaryAction() async {
    final survey = state.survey;
    if (survey == null) return null;

    // Check if we should navigate to a section
    if (!state.shouldNavigateToSection) {
      return null;
    }

    // Get the next status (if any)
    final nextStatus = _statusEngine.nextStatusOnPrimaryAction(survey.status);

    // If there's a status transition, update it
    if (nextStatus != null && _statusEngine.canTransition(survey.status, nextStatus)) {
      state = state.copyWith(isUpdatingStatus: true);

      try {
        await _repository.updateSurveyStatus(_surveyId, nextStatus);
        await _queueStatusSync(survey, nextStatus);
        if (!mounted) return null;

        // Update local state with new status
        final updatedSurvey = survey.copyWith(status: nextStatus);
        state = state.copyWith(
          survey: updatedSurvey,
          isUpdatingStatus: false,
        );

        // Invalidate dependent providers for reactive UI updates
        SurveyInvalidation.afterSurveyMutation(_ref, _surveyId);
      } catch (e) {
        if (!mounted) return null;
        state = state.copyWith(isUpdatingStatus: false);
        // Continue anyway - navigation is more important than status update
      }
    }

    // Return the target section ID for navigation
    return state.targetSection?.id;
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadSurveyOverview();
  }

  // ============== Unified Actions System ==============

  /// Handle a survey action.
  /// Returns the navigation intent after executing the action.
  Future<ActionNavigationIntent> handleAction(SurveyAction action) async {
    final survey = state.survey;
    if (survey == null) {
      return const ShowMessage(message: 'Survey not found', isError: true);
    }

    // Check if action can be executed
    if (!_actionResolver.canExecuteAction(action, survey.status)) {
      return ShowMessage(
        message: 'Cannot ${action.defaultLabel.toLowerCase()} in current status',
        isError: true,
      );
    }

    // Get target status (if any)
    final targetStatus = _actionResolver.getTargetStatus(action, survey.status);

    // Execute status transition if needed
    if (targetStatus != null) {
      state = state.copyWith(isUpdatingStatus: true);

      try {
        await _repository.updateSurveyStatus(_surveyId, targetStatus);
        await _queueStatusSync(survey, targetStatus);
        if (!mounted) {
          return const ShowMessage(message: 'Survey view closed', isError: false);
        }

        // Update local state with new status
        final updatedSurvey = survey.copyWith(
          status: targetStatus,
          updatedAt: DateTime.now(),
          completedAt: targetStatus == SurveyStatus.completed
              ? DateTime.now()
              : survey.completedAt,
        );
        state = state.copyWith(
          survey: updatedSurvey,
          isUpdatingStatus: false,
        );

        // Invalidate dependent providers for reactive UI updates
        SurveyInvalidation.afterSurveyMutation(_ref, _surveyId);
      } catch (e) {
        if (!mounted) {
          return const ShowMessage(message: 'Survey view closed', isError: false);
        }
        state = state.copyWith(isUpdatingStatus: false);
        return const ShowMessage(
          message: 'Failed to update survey status',
          isError: true,
        );
      }
    }

    // Return navigation intent
    return _actionResolver.getNavigationIntent(
      action: action,
      survey: state.survey!,
      sections: state.sections,
    );
  }

  /// Handle pause action specifically (convenience method)
  Future<ActionNavigationIntent> pauseSurvey() async => handleAction(SurveyAction.pauseSurvey);

  /// Handle mark complete action specifically (convenience method)
  Future<ActionNavigationIntent> markComplete() async => handleAction(SurveyAction.markCompleted);

  /// Handle submit for review action specifically (convenience method)
  Future<ActionNavigationIntent> submitForReview() async => handleAction(SurveyAction.submitForReview);

  /// Update survey details (title, clientName, address, jobRef)
  Future<bool> updateSurveyDetails({
    String? title,
    String? clientName,
    String? address,
    String? jobRef,
  }) async {
    final survey = state.survey;
    if (survey == null) return false;

    try {
      final updatedSurvey = survey.copyWith(
        title: title ?? survey.title,
        clientName: clientName,
        address: address,
        jobRef: jobRef,
        updatedAt: DateTime.now(),
      );

      await _repository.updateSurvey(updatedSurvey);
      if (!mounted) return false;

      state = state.copyWith(survey: updatedSurvey);

      // Invalidate dependent providers for reactive UI updates
      SurveyInvalidation.afterSurveyMutation(_ref, _surveyId);

      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: 'Failed to update survey: $e');
      return false;
    }
  }
}

/// Provider for SurveyOverviewNotifier
final surveyOverviewProvider = StateNotifierProvider.autoDispose
    .family<SurveyOverviewNotifier, SurveyOverviewState, String>(
  (ref, surveyId) {
    final repository = ref.watch(localSurveyRepositoryProvider);
    return SurveyOverviewNotifier(repository, surveyId, ref);
  },
);
