import '../entities/survey.dart';
import '../entities/survey_section.dart';
import '../entities/timeline_event.dart';

/// Pure Dart service for generating timeline events from survey data.
/// Contains no UI code - only business logic for event generation.
class TimelineEventService {
  const TimelineEventService._();

  /// Singleton instance
  static const TimelineEventService instance = TimelineEventService._();

  /// Event title mappings for each event type
  static const Map<TimelineEventType, String> _eventTitles = {
    TimelineEventType.created: 'Survey Created',
    TimelineEventType.sectionCompleted: 'Section Completed',
    TimelineEventType.paused: 'Survey Paused',
    TimelineEventType.resumed: 'Survey Resumed',
    TimelineEventType.completed: 'Survey Completed',
    TimelineEventType.submittedForReview: 'Submitted for Review',
    TimelineEventType.approved: 'Survey Approved',
    TimelineEventType.rejected: 'Survey Rejected',
  };

  /// Get the default title for an event type
  String getDefaultTitle(TimelineEventType type) => _eventTitles[type] ?? 'Unknown Event';

  /// Generate all timeline events for a survey by aggregating different sources.
  ///
  /// Sources:
  /// - Survey creation date → created event
  /// - Survey completion date → completed event
  /// - Survey status → appropriate status event
  /// - Section completion dates → sectionCompleted events
  ///
  /// Events are sorted descending by timestamp (most recent first).
  List<TimelineEvent> generateTimelineEvents({
    required Survey survey,
    required List<SurveySection> sections,
  }) {
    final events = <TimelineEvent>[];

    // 1. Survey created event
    events.add(_createSurveyCreatedEvent(survey));

    // 2. Section completed events
    for (final section in sections) {
      if (section.isCompleted && section.updatedAt != null) {
        events.add(_createSectionCompletedEvent(survey.id, section));
      }
    }

    // 3. Status-based events (inferred from current status and dates)
    events.addAll(_generateStatusEvents(survey));

    // Sort by timestamp descending (most recent first)
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return events;
  }

  /// Create a "Survey Created" event
  TimelineEvent _createSurveyCreatedEvent(Survey survey) => TimelineEvent(
      id: '${survey.id}_created',
      surveyId: survey.id,
      type: TimelineEventType.created,
      title: getDefaultTitle(TimelineEventType.created),
      description: 'Survey "${survey.title}" was created',
      timestamp: survey.createdAt,
    );

  /// Create a "Section Completed" event
  TimelineEvent _createSectionCompletedEvent(
    String surveyId,
    SurveySection section,
  ) => TimelineEvent(
      id: '${surveyId}_section_${section.id}_completed',
      surveyId: surveyId,
      type: TimelineEventType.sectionCompleted,
      title: getDefaultTitle(TimelineEventType.sectionCompleted),
      description: section.title,
      timestamp: section.updatedAt!,
    );

  /// Generate status-related events based on current status and timestamps.
  ///
  /// This infers events from the current state since we don't have a
  /// full status history table yet.
  List<TimelineEvent> _generateStatusEvents(Survey survey) {
    final events = <TimelineEvent>[];

    switch (survey.status) {
      case SurveyStatus.draft:
        // No additional events for draft
        break;

      case SurveyStatus.inProgress:
        // Survey was started (resumed from draft)
        if (survey.updatedAt != null &&
            survey.updatedAt!.isAfter(survey.createdAt)) {
          events.add(TimelineEvent(
            id: '${survey.id}_resumed',
            surveyId: survey.id,
            type: TimelineEventType.resumed,
            title: getDefaultTitle(TimelineEventType.resumed),
            description: 'Work on the survey has begun',
            timestamp: survey.updatedAt!,
          ),);
        }
        break;

      case SurveyStatus.paused:
        if (survey.updatedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_paused',
            surveyId: survey.id,
            type: TimelineEventType.paused,
            title: getDefaultTitle(TimelineEventType.paused),
            description: 'Survey work was paused',
            timestamp: survey.updatedAt!,
          ),);
        }
        break;

      case SurveyStatus.completed:
        if (survey.completedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_completed',
            surveyId: survey.id,
            type: TimelineEventType.completed,
            title: getDefaultTitle(TimelineEventType.completed),
            description: 'All sections have been completed',
            timestamp: survey.completedAt!,
          ),);
        }
        break;

      case SurveyStatus.pendingReview:
        if (survey.updatedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_submitted',
            surveyId: survey.id,
            type: TimelineEventType.submittedForReview,
            title: getDefaultTitle(TimelineEventType.submittedForReview),
            description: 'Survey has been submitted for review',
            timestamp: survey.updatedAt!,
          ),);
        }
        // Also add completed event if we have completedAt
        if (survey.completedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_completed',
            surveyId: survey.id,
            type: TimelineEventType.completed,
            title: getDefaultTitle(TimelineEventType.completed),
            description: 'All sections have been completed',
            timestamp: survey.completedAt!,
          ),);
        }
        break;

      case SurveyStatus.approved:
        if (survey.updatedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_approved',
            surveyId: survey.id,
            type: TimelineEventType.approved,
            title: getDefaultTitle(TimelineEventType.approved),
            description: 'Survey has been approved',
            timestamp: survey.updatedAt!,
          ),);
        }
        // Add submitted event (estimated before approval)
        if (survey.completedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_submitted',
            surveyId: survey.id,
            type: TimelineEventType.submittedForReview,
            title: getDefaultTitle(TimelineEventType.submittedForReview),
            description: 'Survey has been submitted for review',
            timestamp: survey.completedAt!,
          ),);
          events.add(TimelineEvent(
            id: '${survey.id}_completed',
            surveyId: survey.id,
            type: TimelineEventType.completed,
            title: getDefaultTitle(TimelineEventType.completed),
            description: 'All sections have been completed',
            timestamp: survey.completedAt!,
          ),);
        }
        break;

      case SurveyStatus.rejected:
        if (survey.updatedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_rejected',
            surveyId: survey.id,
            type: TimelineEventType.rejected,
            title: getDefaultTitle(TimelineEventType.rejected),
            description: 'Survey was rejected and needs revision',
            timestamp: survey.updatedAt!,
          ),);
        }
        // Add submitted event (estimated before rejection)
        if (survey.completedAt != null) {
          events.add(TimelineEvent(
            id: '${survey.id}_submitted',
            surveyId: survey.id,
            type: TimelineEventType.submittedForReview,
            title: getDefaultTitle(TimelineEventType.submittedForReview),
            description: 'Survey has been submitted for review',
            timestamp: survey.completedAt!,
          ),);
          events.add(TimelineEvent(
            id: '${survey.id}_completed',
            surveyId: survey.id,
            type: TimelineEventType.completed,
            title: getDefaultTitle(TimelineEventType.completed),
            description: 'All sections have been completed',
            timestamp: survey.completedAt!,
          ),);
        }
        break;
    }

    return events;
  }

  /// Maps an event type to its semantic meaning for accessibility.
  String getEventSemanticLabel(TimelineEvent event) {
    final dateStr = _formatDateForAccessibility(event.timestamp);
    return '${event.title}. ${event.description ?? ''}. $dateStr';
  }

  String _formatDateForAccessibility(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
