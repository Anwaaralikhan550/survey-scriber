import 'package:flutter/material.dart';

import 'survey.dart';

/// Priority level for survey actions
enum ActionPriority {
  /// Primary action - shown as main CTA button
  primary,

  /// Secondary action - shown as text button or chip
  secondary,
}

/// Defines all possible actions that can be performed on a survey.
/// Each action has metadata for rendering and validation.
enum SurveyAction {
  /// Start a new survey (draft -> inProgress)
  startSurvey(
    id: 'start_survey',
    defaultLabel: 'Start Survey',
    icon: Icons.play_arrow_rounded,
    priority: ActionPriority.primary,
    allowedStatuses: {SurveyStatus.draft},
    requiresConfirmation: false,
  ),

  /// Resume an existing survey (paused/inProgress/rejected -> continue)
  resumeSurvey(
    id: 'resume_survey',
    defaultLabel: 'Resume Survey',
    icon: Icons.play_circle_outline_rounded,
    priority: ActionPriority.primary,
    allowedStatuses: {
      SurveyStatus.inProgress,
      SurveyStatus.paused,
      SurveyStatus.rejected,
    },
    requiresConfirmation: false,
  ),

  /// Pause an in-progress survey (inProgress -> paused)
  pauseSurvey(
    id: 'pause_survey',
    defaultLabel: 'Pause Survey',
    icon: Icons.pause_rounded,
    priority: ActionPriority.secondary,
    allowedStatuses: {SurveyStatus.inProgress},
    requiresConfirmation: false,
  ),

  /// Mark survey as completed (all sections done)
  markCompleted(
    id: 'mark_completed',
    defaultLabel: 'Mark as Complete',
    icon: Icons.check_circle_outline_rounded,
    priority: ActionPriority.secondary,
    allowedStatuses: {SurveyStatus.inProgress},
    requiresConfirmation: true,
  ),

  /// Submit survey for review (completed -> pendingReview)
  submitForReview(
    id: 'submit_for_review',
    defaultLabel: 'Submit for Review',
    icon: Icons.send_rounded,
    priority: ActionPriority.primary,
    allowedStatuses: {SurveyStatus.completed},
    requiresConfirmation: true,
  ),

  /// Approve a submitted survey (pendingReview -> approved)
  approve(
    id: 'approve',
    defaultLabel: 'Approve Survey',
    icon: Icons.thumb_up_rounded,
    priority: ActionPriority.primary,
    allowedStatuses: {SurveyStatus.pendingReview},
    requiresConfirmation: true,
  ),

  /// Reject a submitted survey (pendingReview -> rejected)
  reject(
    id: 'reject',
    defaultLabel: 'Reject Survey',
    icon: Icons.thumb_down_rounded,
    priority: ActionPriority.secondary,
    allowedStatuses: {SurveyStatus.pendingReview},
    requiresConfirmation: true,
  ),

  /// Export survey as PDF (stub)
  exportPdf(
    id: 'export_pdf',
    defaultLabel: 'Export PDF',
    icon: Icons.picture_as_pdf_rounded,
    priority: ActionPriority.secondary,
    allowedStatuses: {
      SurveyStatus.completed,
      SurveyStatus.pendingReview,
      SurveyStatus.approved,
    },
    requiresConfirmation: false,
  ),

  /// Share survey (stub)
  share(
    id: 'share',
    defaultLabel: 'Share',
    icon: Icons.share_rounded,
    priority: ActionPriority.secondary,
    allowedStatuses: {
      SurveyStatus.draft,
      SurveyStatus.inProgress,
      SurveyStatus.paused,
      SurveyStatus.completed,
      SurveyStatus.pendingReview,
      SurveyStatus.approved,
      SurveyStatus.rejected,
    },
    requiresConfirmation: false,
  ),

  /// Delete survey (soft delete, requires confirmation)
  delete(
    id: 'delete',
    defaultLabel: 'Delete Survey',
    icon: Icons.delete_outline_rounded,
    priority: ActionPriority.secondary,
    allowedStatuses: {
      SurveyStatus.draft,
      SurveyStatus.paused,
      SurveyStatus.rejected,
    },
    requiresConfirmation: true,
  ),

  /// View final report (approved surveys only)
  viewReport(
    id: 'view_report',
    defaultLabel: 'View Report',
    icon: Icons.description_outlined,
    priority: ActionPriority.primary,
    allowedStatuses: {SurveyStatus.approved},
    requiresConfirmation: false,
  );

  const SurveyAction({
    required this.id,
    required this.defaultLabel,
    required this.icon,
    required this.priority,
    required this.allowedStatuses,
    required this.requiresConfirmation,
  });

  /// Unique identifier for the action
  final String id;

  /// Default label to display for this action
  final String defaultLabel;

  /// Icon to display for this action
  final IconData icon;

  /// Priority level (primary = main CTA, secondary = supporting action)
  final ActionPriority priority;

  /// Set of survey statuses where this action is allowed
  final Set<SurveyStatus> allowedStatuses;

  /// Whether this action requires user confirmation before executing
  final bool requiresConfirmation;

  /// Check if this action is allowed for a given survey status
  bool isAllowedFor(SurveyStatus status) => allowedStatuses.contains(status);

  /// Check if this is a primary action
  bool get isPrimary => priority == ActionPriority.primary;

  /// Check if this is a secondary action
  bool get isSecondary => priority == ActionPriority.secondary;
}

/// Navigation intent returned after executing an action
sealed class ActionNavigationIntent {
  const ActionNavigationIntent();
}

/// Navigate to a specific section
class NavigateToSection extends ActionNavigationIntent {
  const NavigateToSection({required this.sectionId});
  final String sectionId;
}

/// Stay on the current screen (e.g., after status update)
class StayOnScreen extends ActionNavigationIntent {
  const StayOnScreen();
}

/// Navigate to report view
class NavigateToReport extends ActionNavigationIntent {
  const NavigateToReport({required this.surveyId});
  final String surveyId;
}

/// Show a message/snackbar
class ShowMessage extends ActionNavigationIntent {
  const ShowMessage({required this.message, this.isError = false});
  final String message;
  final bool isError;
}

/// Action is not yet implemented (stub)
class ActionNotImplemented extends ActionNavigationIntent {
  const ActionNotImplemented({required this.actionLabel});
  final String actionLabel;
}
