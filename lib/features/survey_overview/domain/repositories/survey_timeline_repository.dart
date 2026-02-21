import '../../../../shared/domain/entities/timeline_event.dart';

/// Repository interface for survey timeline (READ-ONLY).
///
/// This repository aggregates events from various sources to build
/// a chronological audit feed for a survey.
abstract class SurveyTimelineRepository {
  /// Get all timeline events for a survey, sorted by timestamp descending.
  ///
  /// Returns an empty list if no events are found.
  /// Never returns null - returns empty list on error.
  Future<List<TimelineEvent>> getTimelineEvents(String surveyId);
}
