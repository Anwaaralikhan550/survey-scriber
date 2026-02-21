import '../entities/survey.dart';
import '../entities/survey_section.dart';

/// Pure Dart class for managing survey status transitions.
/// Contains no UI code - only business logic for status management.
class SurveyStatusEngine {
  const SurveyStatusEngine._();

  /// Singleton instance
  static const SurveyStatusEngine instance = SurveyStatusEngine._();

  /// Allowed status transitions map.
  /// Key = current status, Value = list of allowed target statuses.
  static const Map<SurveyStatus, Set<SurveyStatus>> _allowedTransitions = {
    SurveyStatus.draft: {SurveyStatus.inProgress},
    SurveyStatus.inProgress: {SurveyStatus.paused, SurveyStatus.completed},
    SurveyStatus.paused: {SurveyStatus.inProgress},
    SurveyStatus.completed: {SurveyStatus.pendingReview},
    SurveyStatus.pendingReview: {SurveyStatus.approved, SurveyStatus.rejected},
    SurveyStatus.approved: {},
    SurveyStatus.rejected: {SurveyStatus.inProgress},
  };

  /// Check if a status transition is allowed.
  bool canTransition(SurveyStatus from, SurveyStatus to) {
    final allowedTargets = _allowedTransitions[from];
    return allowedTargets?.contains(to) ?? false;
  }

  /// Get the next status when the primary action button is pressed.
  /// Returns null if no automatic transition should occur.
  SurveyStatus? nextStatusOnPrimaryAction(SurveyStatus currentStatus) => switch (currentStatus) {
      SurveyStatus.draft => SurveyStatus.inProgress,
      SurveyStatus.inProgress => null, // User continues working, no status change
      SurveyStatus.paused => SurveyStatus.inProgress,
      SurveyStatus.completed => SurveyStatus.pendingReview,
      SurveyStatus.pendingReview => null, // Awaiting external action
      SurveyStatus.approved => null, // View report, no change
      SurveyStatus.rejected => SurveyStatus.inProgress,
    };

  /// Get the primary action label for a given status.
  /// Optionally includes the next section name for contextual labels.
  String primaryActionLabel(SurveyStatus status, {String? nextSectionName}) => switch (status) {
      SurveyStatus.draft => 'Start Survey',
      SurveyStatus.inProgress => nextSectionName != null
          ? 'Resume: $nextSectionName'
          : 'Continue Survey',
      SurveyStatus.paused => nextSectionName != null
          ? 'Resume: $nextSectionName'
          : 'Resume Survey',
      SurveyStatus.completed => 'Submit for Review',
      SurveyStatus.pendingReview => 'Awaiting Review',
      SurveyStatus.approved => 'View Report',
      SurveyStatus.rejected => 'Revise Survey',
    };

  /// Check if the primary action button should be enabled.
  bool isPrimaryActionEnabled(SurveyStatus status) => switch (status) {
      SurveyStatus.draft => true,
      SurveyStatus.inProgress => true,
      SurveyStatus.paused => true,
      SurveyStatus.completed => true,
      SurveyStatus.pendingReview => false,
      SurveyStatus.approved => true,
      SurveyStatus.rejected => true,
    };

  /// Check if the primary action should navigate to a section.
  bool shouldNavigateToSection(SurveyStatus status) => switch (status) {
      SurveyStatus.draft => true,
      SurveyStatus.inProgress => true,
      SurveyStatus.paused => true,
      SurveyStatus.completed => false,
      SurveyStatus.pendingReview => false,
      SurveyStatus.approved => false,
      SurveyStatus.rejected => true,
    };

  /// Get all allowed transitions from a given status.
  Set<SurveyStatus> getAllowedTransitions(SurveyStatus from) => _allowedTransitions[from] ?? {};
}

/// Service for determining smart resume targets.
/// Implements the logic for finding which section to navigate to.
class SmartResumeService {
  const SmartResumeService._();

  /// Singleton instance
  static const SmartResumeService instance = SmartResumeService._();

  /// Get the target section for resuming a survey.
  ///
  /// Logic:
  /// 1. If there are incomplete sections, return the first one (by order)
  /// 2. If all sections are complete, return the last section
  /// 3. If no sections exist, return null
  SurveySection? getResumeTargetSection(List<SurveySection> sections) {
    if (sections.isEmpty) return null;

    // Sort by order to ensure correct sequence
    final sortedSections = List<SurveySection>.from(sections)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Find first incomplete section
    for (final section in sortedSections) {
      if (!section.isCompleted) {
        return section;
      }
    }

    // All sections complete - return the last one
    return sortedSections.last;
  }

  /// Get the target section ID for resuming a survey.
  String? getResumeTargetSectionId(List<SurveySection> sections) => getResumeTargetSection(sections)?.id;

  /// Get the target section name for display purposes.
  String? getResumeTargetSectionName(List<SurveySection> sections) => getResumeTargetSection(sections)?.title;

  /// Calculate the resume context for UI display.
  ResumeContext getResumeContext(List<SurveySection> sections) {
    if (sections.isEmpty) {
      return const ResumeContext(
        targetSection: null,
        completedCount: 0,
        totalCount: 0,
        isAllComplete: false,
      );
    }

    final sortedSections = List<SurveySection>.from(sections)
      ..sort((a, b) => a.order.compareTo(b.order));

    final completedCount = sections.where((s) => s.isCompleted).length;
    final totalCount = sections.length;
    final isAllComplete = completedCount == totalCount;

    SurveySection? targetSection;
    for (final section in sortedSections) {
      if (!section.isCompleted) {
        targetSection = section;
        break;
      }
    }

    // If all complete, target is the last section
    targetSection ??= sortedSections.last;

    return ResumeContext(
      targetSection: targetSection,
      completedCount: completedCount,
      totalCount: totalCount,
      isAllComplete: isAllComplete,
    );
  }
}

/// Context information for smart resume functionality.
class ResumeContext {
  const ResumeContext({
    required this.targetSection,
    required this.completedCount,
    required this.totalCount,
    required this.isAllComplete,
  });

  /// The section to navigate to
  final SurveySection? targetSection;

  /// Number of completed sections
  final int completedCount;

  /// Total number of sections
  final int totalCount;

  /// Whether all sections are complete
  final bool isAllComplete;

  /// Get the target section ID
  String? get targetSectionId => targetSection?.id;

  /// Get the target section name
  String? get targetSectionName => targetSection?.title;

  /// Progress as a fraction (0.0 to 1.0)
  double get progressFraction =>
      totalCount > 0 ? completedCount / totalCount : 0.0;

  /// Progress as percentage (0 to 100)
  int get progressPercent => (progressFraction * 100).round();
}
