import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/survey_overview/presentation/providers/survey_timeline_provider.dart';
import 'package:survey_scriber/shared/domain/entities/timeline_event.dart';

void main() {
  group('SurveyTimelineState', () {
    test('initial state has correct defaults', () {
      const state = SurveyTimelineState();

      expect(state.events, isEmpty);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);
      expect(state.hasError, isFalse);
      expect(state.isEmpty, isFalse); // isLoading is true, so isEmpty is false
      expect(state.hasEvents, isFalse);
      expect(state.eventCount, equals(0));
    });

    test('hasError returns true when errorMessage is set', () {
      const state = SurveyTimelineState(
        isLoading: false,
        errorMessage: 'Test error',
      );

      expect(state.hasError, isTrue);
    });

    test('isEmpty returns true when loaded with no events', () {
      const state = SurveyTimelineState(
        isLoading: false,
      );

      expect(state.isEmpty, isTrue);
      expect(state.hasEvents, isFalse);
    });

    test('hasEvents returns true when loaded with events', () {
      final events = [
        TimelineEvent(
          id: 'event-1',
          surveyId: 'survey-1',
          type: TimelineEventType.created,
          title: 'Survey Created',
          timestamp: DateTime.now(),
        ),
      ];

      final state = SurveyTimelineState(
        events: events,
        isLoading: false,
      );

      expect(state.hasEvents, isTrue);
      expect(state.isEmpty, isFalse);
      expect(state.eventCount, equals(1));
    });

    test('isEmpty returns false when loading', () {
      const state = SurveyTimelineState(
        
      );

      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when error', () {
      const state = SurveyTimelineState(
        isLoading: false,
        errorMessage: 'Error occurred',
      );

      expect(state.isEmpty, isFalse);
    });

    test('eventCount returns correct count', () {
      final events = [
        TimelineEvent(
          id: 'event-1',
          surveyId: 'survey-1',
          type: TimelineEventType.created,
          title: 'Survey Created',
          timestamp: DateTime.now(),
        ),
        TimelineEvent(
          id: 'event-2',
          surveyId: 'survey-1',
          type: TimelineEventType.resumed,
          title: 'Survey Resumed',
          timestamp: DateTime.now(),
        ),
        TimelineEvent(
          id: 'event-3',
          surveyId: 'survey-1',
          type: TimelineEventType.sectionCompleted,
          title: 'Section Completed',
          timestamp: DateTime.now(),
        ),
      ];

      final state = SurveyTimelineState(
        events: events,
        isLoading: false,
      );

      expect(state.eventCount, equals(3));
    });

    test('copyWith creates new state with updated values', () {
      const original = SurveyTimelineState();

      final updated = original.copyWith(
        isLoading: false,
        errorMessage: 'Test error',
      );

      expect(updated.isLoading, isFalse);
      expect(updated.errorMessage, equals('Test error'));
      expect(updated.hasError, isTrue);
    });

    test('copyWith preserves events when not overridden', () {
      final events = [
        TimelineEvent(
          id: 'event-1',
          surveyId: 'survey-1',
          type: TimelineEventType.created,
          title: 'Survey Created',
          timestamp: DateTime.now(),
        ),
      ];

      final original = SurveyTimelineState(
        events: events,
        isLoading: false,
      );

      final updated = original.copyWith(isLoading: true);

      expect(updated.events, equals(events));
      expect(updated.eventCount, equals(1));
    });

    test('copyWith clears error when not specified', () {
      const original = SurveyTimelineState(
        isLoading: false,
        errorMessage: 'Previous error',
      );

      final updated = original.copyWith(isLoading: true);

      // errorMessage is not explicitly set, so it becomes null
      expect(updated.errorMessage, isNull);
      expect(updated.hasError, isFalse);
    });
  });
}
