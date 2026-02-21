import '../entities/survey.dart';
import '../entities/survey_action.dart';
import '../entities/survey_section.dart';
import 'survey_status_engine.dart';

/// UI model representing a resolved survey action with contextual information.
class SurveyActionUiModel {
  const SurveyActionUiModel({
    required this.action,
    required this.label,
    required this.isEnabled,
    this.targetSectionId,
    this.disabledReason,
  });

  /// The underlying action type
  final SurveyAction action;

  /// Contextual label (may include section name, etc.)
  final String label;

  /// Whether the action is currently enabled
  final bool isEnabled;

  /// Target section ID for navigation (if applicable)
  final String? targetSectionId;

  /// Reason why the action is disabled (if applicable)
  final String? disabledReason;

  /// Convenience getters
  bool get requiresConfirmation => action.requiresConfirmation;
  bool get isPrimary => action.isPrimary;
  bool get isSecondary => action.isSecondary;
}

/// Pure Dart service for resolving survey actions based on current state.
/// Integrates with SurveyStatusEngine and SmartResumeService.
class SurveyActionResolver {
  const SurveyActionResolver._();

  /// Singleton instance
  static const SurveyActionResolver instance = SurveyActionResolver._();

  static const _statusEngine = SurveyStatusEngine.instance;
  static const _resumeService = SmartResumeService.instance;

  /// Resolve the primary action for a survey based on its current state.
  /// Returns the most appropriate action to show as the main CTA.
  SurveyActionUiModel? resolvePrimaryAction({
    required Survey survey,
    required List<SurveySection> sections,
  }) {
    final status = survey.status;
    final resumeContext = _resumeService.getResumeContext(sections);

    // Determine primary action based on status
    final action = switch (status) {
      SurveyStatus.draft => SurveyAction.startSurvey,
      SurveyStatus.inProgress => SurveyAction.resumeSurvey,
      SurveyStatus.paused => SurveyAction.resumeSurvey,
      SurveyStatus.completed => SurveyAction.submitForReview,
      SurveyStatus.pendingReview => SurveyAction.approve,
      SurveyStatus.approved => SurveyAction.viewReport,
      SurveyStatus.rejected => SurveyAction.resumeSurvey,
    };

    // Generate contextual label
    final label = getActionLabel(
      action: action,
      status: status,
      sectionName: resumeContext.targetSectionName,
    );

    // Determine if action is enabled
    final isEnabled = isActionEnabled(
      action: action,
      status: status,
      sections: sections,
    );

    return SurveyActionUiModel(
      action: action,
      label: label,
      isEnabled: isEnabled,
      targetSectionId: resumeContext.targetSectionId,
      disabledReason: !isEnabled ? _getDisabledReason(action, status) : null,
    );
  }

  /// Resolve secondary actions available for a survey.
  /// Returns list of supporting actions based on current status.
  List<SurveyActionUiModel> resolveSecondaryActions({
    required Survey survey,
    required List<SurveySection> sections,
  }) {
    final status = survey.status;
    final resumeContext = _resumeService.getResumeContext(sections);
    final secondaryActions = <SurveyActionUiModel>[];

    // Get all secondary actions allowed for this status
    final allowedActions = SurveyAction.values
        .where((action) => action.isSecondary && action.isAllowedFor(status))
        .toList();

    // Add status-specific actions
    for (final action in allowedActions) {
      // Skip markCompleted if not all sections are done
      if (action == SurveyAction.markCompleted && !resumeContext.isAllComplete) {
        continue;
      }

      final label = getActionLabel(
        action: action,
        status: status,
        sectionName: resumeContext.targetSectionName,
      );

      final isEnabled = isActionEnabled(
        action: action,
        status: status,
        sections: sections,
      );

      secondaryActions.add(SurveyActionUiModel(
        action: action,
        label: label,
        isEnabled: isEnabled,
        targetSectionId: resumeContext.targetSectionId,
        disabledReason: !isEnabled ? _getDisabledReason(action, status) : null,
      ),);
    }

    // Add reject action for pending review (it's secondary)
    if (status == SurveyStatus.pendingReview) {
      const rejectAction = SurveyAction.reject;
      secondaryActions.add(SurveyActionUiModel(
        action: rejectAction,
        label: rejectAction.defaultLabel,
        isEnabled: true,
      ),);
    }

    return secondaryActions;
  }

  /// Get a contextual label for an action.
  /// May include section name for resume-type actions.
  String getActionLabel({
    required SurveyAction action,
    required SurveyStatus status,
    String? sectionName,
  }) => switch (action) {
      SurveyAction.startSurvey => 'Start Survey',
      SurveyAction.resumeSurvey => sectionName != null
          ? 'Resume: $sectionName'
          : status == SurveyStatus.rejected
              ? 'Revise Survey'
              : 'Continue Survey',
      SurveyAction.pauseSurvey => 'Pause',
      SurveyAction.markCompleted => 'Mark Complete',
      SurveyAction.submitForReview => 'Submit for Review',
      SurveyAction.approve => 'Approve',
      SurveyAction.reject => 'Reject',
      SurveyAction.exportPdf => 'Export PDF',
      SurveyAction.share => 'Share',
      SurveyAction.delete => 'Delete',
      SurveyAction.viewReport => 'View Report',
    };

  /// Check if an action is enabled for the current state.
  bool isActionEnabled({
    required SurveyAction action,
    required SurveyStatus status,
    required List<SurveySection> sections,
  }) {
    // First check if action is allowed for this status
    if (!action.isAllowedFor(status)) {
      return false;
    }

    // Additional validation for specific actions
    return switch (action) {
      SurveyAction.startSurvey => sections.isNotEmpty,
      SurveyAction.resumeSurvey => sections.isNotEmpty,
      SurveyAction.pauseSurvey => true,
      SurveyAction.markCompleted => _areAllSectionsComplete(sections),
      SurveyAction.submitForReview => true,
      SurveyAction.approve => true,
      SurveyAction.reject => true,
      SurveyAction.exportPdf => true,
      SurveyAction.share => true,
      SurveyAction.delete => true,
      SurveyAction.viewReport => true,
    };
  }

  /// Get the navigation target for an action (e.g., section ID for resume).
  ActionNavigationIntent getNavigationIntent({
    required SurveyAction action,
    required Survey survey,
    required List<SurveySection> sections,
  }) {
    final resumeContext = _resumeService.getResumeContext(sections);

    return switch (action) {
      SurveyAction.startSurvey => resumeContext.targetSectionId != null
          ? NavigateToSection(sectionId: resumeContext.targetSectionId!)
          : const ShowMessage(message: 'No sections available'),
      SurveyAction.resumeSurvey => resumeContext.targetSectionId != null
          ? NavigateToSection(sectionId: resumeContext.targetSectionId!)
          : const ShowMessage(message: 'No sections available'),
      SurveyAction.pauseSurvey => const StayOnScreen(),
      SurveyAction.markCompleted => const StayOnScreen(),
      SurveyAction.submitForReview => const StayOnScreen(),
      SurveyAction.approve => const StayOnScreen(),
      SurveyAction.reject => const StayOnScreen(),
      // These actions are intercepted in UI layer before reaching resolver
      SurveyAction.exportPdf => const StayOnScreen(),
      SurveyAction.share => const StayOnScreen(),
      SurveyAction.delete => const StayOnScreen(),
      SurveyAction.viewReport => const StayOnScreen(),
    };
  }

  /// Get the target status transition for an action.
  /// Returns null if the action doesn't change status.
  SurveyStatus? getTargetStatus(SurveyAction action, SurveyStatus currentStatus) => switch (action) {
      SurveyAction.startSurvey => SurveyStatus.inProgress,
      SurveyAction.resumeSurvey => currentStatus == SurveyStatus.paused ||
              currentStatus == SurveyStatus.rejected
          ? SurveyStatus.inProgress
          : null,
      SurveyAction.pauseSurvey => SurveyStatus.paused,
      SurveyAction.markCompleted => SurveyStatus.completed,
      SurveyAction.submitForReview => SurveyStatus.pendingReview,
      SurveyAction.approve => SurveyStatus.approved,
      SurveyAction.reject => SurveyStatus.rejected,
      SurveyAction.exportPdf => null,
      SurveyAction.share => null,
      SurveyAction.delete => null,
      SurveyAction.viewReport => null,
    };

  /// Check if a status transition is valid using the status engine.
  bool canExecuteAction(SurveyAction action, SurveyStatus currentStatus) {
    final targetStatus = getTargetStatus(action, currentStatus);
    if (targetStatus == null) {
      // Actions that don't change status are always executable if allowed
      return action.isAllowedFor(currentStatus);
    }
    return _statusEngine.canTransition(currentStatus, targetStatus);
  }

  /// Get confirmation dialog content for an action.
  ({String title, String message, String confirmLabel})? getConfirmationContent(
    SurveyAction action,
  ) {
    if (!action.requiresConfirmation) return null;

    return switch (action) {
      SurveyAction.markCompleted => (
          title: 'Mark Survey Complete?',
          message: 'This will mark the survey as complete. '
              'You can still edit sections after marking complete.',
          confirmLabel: 'Mark Complete',
        ),
      SurveyAction.submitForReview => (
          title: 'Submit for Review?',
          message: 'This will submit the survey for manager review. '
              'You will not be able to edit until review is complete.',
          confirmLabel: 'Submit',
        ),
      SurveyAction.approve => (
          title: 'Approve Survey?',
          message: 'This will approve the survey and mark it as final.',
          confirmLabel: 'Approve',
        ),
      SurveyAction.reject => (
          title: 'Reject Survey?',
          message: 'This will reject the survey and return it to the surveyor '
              'for revisions.',
          confirmLabel: 'Reject',
        ),
      SurveyAction.delete => (
          title: 'Delete Survey?',
          message: 'This action cannot be undone. '
              'The survey and all its data will be permanently deleted.',
          confirmLabel: 'Delete',
        ),
      _ => null,
    };
  }

  bool _areAllSectionsComplete(List<SurveySection> sections) {
    if (sections.isEmpty) return false;
    return sections.every((section) => section.isCompleted);
  }

  String? _getDisabledReason(SurveyAction action, SurveyStatus status) {
    if (action.isAllowedFor(status)) {
      return switch (action) {
        SurveyAction.startSurvey => 'No sections available',
        SurveyAction.resumeSurvey => 'No sections available',
        SurveyAction.markCompleted => 'Complete all sections first',
        _ => null,
      };
    }
    return 'Not available in current status';
  }
}
