import 'package:equatable/equatable.dart';

/// Types of events that can appear in the survey activity timeline.
enum TimelineEventType {
  /// Survey was created
  created,

  /// A section was completed
  sectionCompleted,

  /// Survey was paused
  paused,

  /// Survey was resumed (from paused or draft)
  resumed,

  /// Survey was marked as completed
  completed,

  /// Survey was submitted for review
  submittedForReview,

  /// Survey was approved
  approved,

  /// Survey was rejected
  rejected,
}

/// Represents an event in the survey activity timeline.
///
/// This is a read-only entity used for displaying audit/activity history.
/// Events are aggregated from various sources (survey, sections, status changes).
class TimelineEvent extends Equatable {
  const TimelineEvent({
    required this.id,
    required this.surveyId,
    required this.type,
    required this.title,
    required this.timestamp,
    this.description,
  });

  /// Unique identifier for this event
  final String id;

  /// The survey this event belongs to
  final String surveyId;

  /// The type of event
  final TimelineEventType type;

  /// Human-readable title for the event
  final String title;

  /// Optional description with additional details
  final String? description;

  /// When this event occurred
  final DateTime timestamp;

  /// Whether this event has a description
  bool get hasDescription => description != null && description!.isNotEmpty;

  TimelineEvent copyWith({
    String? id,
    String? surveyId,
    TimelineEventType? type,
    String? title,
    String? description,
    DateTime? timestamp,
  }) =>
      TimelineEvent(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        type: type ?? this.type,
        title: title ?? this.title,
        description: description ?? this.description,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  List<Object?> get props => [
        id,
        surveyId,
        type,
        title,
        description,
        timestamp,
      ];
}
