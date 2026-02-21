import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/timeline_event.dart';

void main() {
  group('TimelineEventType', () {
    test('contains all expected event types', () {
      expect(TimelineEventType.values.length, equals(8));
      expect(TimelineEventType.values, contains(TimelineEventType.created));
      expect(TimelineEventType.values, contains(TimelineEventType.sectionCompleted));
      expect(TimelineEventType.values, contains(TimelineEventType.paused));
      expect(TimelineEventType.values, contains(TimelineEventType.resumed));
      expect(TimelineEventType.values, contains(TimelineEventType.completed));
      expect(TimelineEventType.values, contains(TimelineEventType.submittedForReview));
      expect(TimelineEventType.values, contains(TimelineEventType.approved));
      expect(TimelineEventType.values, contains(TimelineEventType.rejected));
    });
  });

  group('TimelineEvent', () {
    test('creates event with required fields', () {
      final event = TimelineEvent(
        id: 'event-1',
        surveyId: 'survey-1',
        type: TimelineEventType.created,
        title: 'Survey Created',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      expect(event.id, equals('event-1'));
      expect(event.surveyId, equals('survey-1'));
      expect(event.type, equals(TimelineEventType.created));
      expect(event.title, equals('Survey Created'));
      expect(event.timestamp, equals(DateTime(2024, 1, 15, 10, 30)));
      expect(event.description, isNull);
      expect(event.hasDescription, isFalse);
    });

    test('creates event with optional description', () {
      final event = TimelineEvent(
        id: 'event-2',
        surveyId: 'survey-1',
        type: TimelineEventType.sectionCompleted,
        title: 'Section Completed',
        description: 'About Property section completed',
        timestamp: DateTime(2024, 1, 15, 11),
      );

      expect(event.description, equals('About Property section completed'));
      expect(event.hasDescription, isTrue);
    });

    test('hasDescription returns false for empty string', () {
      final event = TimelineEvent(
        id: 'event-3',
        surveyId: 'survey-1',
        type: TimelineEventType.paused,
        title: 'Survey Paused',
        description: '',
        timestamp: DateTime(2024, 1, 15, 12),
      );

      expect(event.hasDescription, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      final original = TimelineEvent(
        id: 'event-1',
        surveyId: 'survey-1',
        type: TimelineEventType.created,
        title: 'Survey Created',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        description: 'New description',
      );

      expect(updated.id, equals('event-1'));
      expect(updated.surveyId, equals('survey-1'));
      expect(updated.type, equals(TimelineEventType.created));
      expect(updated.title, equals('Updated Title'));
      expect(updated.description, equals('New description'));
      expect(updated.timestamp, equals(DateTime(2024, 1, 15, 10, 30)));
    });

    test('copyWith preserves original values when not overridden', () {
      final original = TimelineEvent(
        id: 'event-1',
        surveyId: 'survey-1',
        type: TimelineEventType.created,
        title: 'Survey Created',
        description: 'Original description',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final updated = original.copyWith(title: 'New Title');

      expect(updated.description, equals('Original description'));
    });

    test('equality works correctly', () {
      final event1 = TimelineEvent(
        id: 'event-1',
        surveyId: 'survey-1',
        type: TimelineEventType.created,
        title: 'Survey Created',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final event2 = TimelineEvent(
        id: 'event-1',
        surveyId: 'survey-1',
        type: TimelineEventType.created,
        title: 'Survey Created',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final event3 = TimelineEvent(
        id: 'event-2',
        surveyId: 'survey-1',
        type: TimelineEventType.created,
        title: 'Survey Created',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });
  });
}
