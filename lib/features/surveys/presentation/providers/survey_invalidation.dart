import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../forms/presentation/providers/forms_provider.dart';
import '../../../survey_overview/presentation/providers/survey_overview_provider.dart';
import 'survey_detail_provider.dart';

/// Centralized invalidation helper for survey-related state.
///
/// This ensures all dependent providers are refreshed after mutations,
/// maintaining reactive UI updates across the app.
///
/// Usage:
/// ```dart
/// SurveyInvalidation.afterSectionMutation(ref, surveyId);
/// SurveyInvalidation.afterSurveyMutation(ref, surveyId);
/// ```
abstract final class SurveyInvalidation {
  /// Invalidate all providers affected by a section mutation.
  /// Call after: saving answers, completing sections, etc.
  static void afterSectionMutation(Ref ref, String surveyId) {
    // Survey detail shows section list and progress
    ref.invalidate(surveyDetailProvider(surveyId));

    // Survey overview shows progress and actions
    ref.invalidate(surveyOverviewProvider(surveyId));

    // Dashboard shows aggregate stats
    ref.invalidate(dashboardProvider);

    // Forms list shows survey progress
    ref.invalidate(formsProvider);
  }

  /// Invalidate all providers affected by a survey mutation.
  /// Call after: status changes, survey updates, deletions, etc.
  static void afterSurveyMutation(
    Ref ref,
    String surveyId, {
    bool invalidateSurveyDetail = true,
  }) {
    // Skip invalidating the currently running surveyDetailProvider to avoid
    // Riverpod self-dependency assertions during notifier methods.
    if (invalidateSurveyDetail) {
      ref.invalidate(surveyDetailProvider(surveyId));
    }

    // Survey overview shows survey data and status-dependent actions
    ref.invalidate(surveyOverviewProvider(surveyId));

    // Dashboard shows aggregate stats and recent surveys
    ref.invalidate(dashboardProvider);

    // Forms list shows survey list with status filters
    ref.invalidate(formsProvider);
  }

  /// Invalidate list-level providers only (no specific survey).
  /// Call after: bulk operations, deletions without specific surveyId.
  static void afterBulkMutation(Ref ref) {
    ref.invalidate(dashboardProvider);
    ref.invalidate(formsProvider);
  }

  /// Invalidate all survey-related providers for a specific survey.
  /// Use when unsure which providers are affected.
  static void all(Ref ref, String surveyId) {
    afterSurveyMutation(ref, surveyId);
  }
}
