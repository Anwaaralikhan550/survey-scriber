import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';
import 'package:survey_scriber/shared/domain/entities/timeline_event.dart';
import 'package:survey_scriber/shared/domain/services/timeline_event_service.dart';

void main() {
  const service = TimelineEventService.instance;

  group('TimelineEventService', () {
    group('getDefaultTitle', () {
      test('returns correct title for created', () {
        expect(
          service.getDefaultTitle(TimelineEventType.created),
          equals('Survey Created'),
        );
      });

      test('returns correct title for sectionCompleted', () {
        expect(
          service.getDefaultTitle(TimelineEventType.sectionCompleted),
          equals('Section Completed'),
        );
      });

      test('returns correct title for paused', () {
        expect(
          service.getDefaultTitle(TimelineEventType.paused),
          equals('Survey Paused'),
        );
      });

      test('returns correct title for resumed', () {
        expect(
          service.getDefaultTitle(TimelineEventType.resumed),
          equals('Survey Resumed'),
        );
      });

      test('returns correct title for completed', () {
        expect(
          service.getDefaultTitle(TimelineEventType.completed),
          equals('Survey Completed'),
        );
      });

      test('returns correct title for submittedForReview', () {
        expect(
          service.getDefaultTitle(TimelineEventType.submittedForReview),
          equals('Submitted for Review'),
        );
      });

      test('returns correct title for approved', () {
        expect(
          service.getDefaultTitle(TimelineEventType.approved),
          equals('Survey Approved'),
        );
      });

      test('returns correct title for rejected', () {
        expect(
          service.getDefaultTitle(TimelineEventType.rejected),
          equals('Survey Rejected'),
        );
      });
    });

    group('generateTimelineEvents', () {
      test('creates survey created event', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.draft,
          createdAt: DateTime(2024, 1, 15, 10),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        expect(events.length, equals(1));
        expect(events.first.type, equals(TimelineEventType.created));
        expect(events.first.surveyId, equals('survey-1'));
        expect(events.first.timestamp, equals(DateTime(2024, 1, 15, 10)));
      });

      test('creates section completed events for completed sections', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.inProgress,
          createdAt: DateTime(2024, 1, 15, 10),
          updatedAt: DateTime(2024, 1, 15, 11),
        );

        final sections = [
          SurveySection(
            id: 'section-1',
            surveyId: 'survey-1',
            sectionType: SectionType.aboutProperty,
            title: 'About Property',
            order: 1,
            isCompleted: true,
            updatedAt: DateTime(2024, 1, 15, 10, 30),
          ),
          const SurveySection(
            id: 'section-2',
            surveyId: 'survey-1',
            sectionType: SectionType.construction,
            title: 'Construction',
            order: 2,
          ),
        ];

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: sections,
        );

        final sectionEvents = events
            .where((e) => e.type == TimelineEventType.sectionCompleted)
            .toList();

        expect(sectionEvents.length, equals(1));
        expect(sectionEvents.first.description, equals('About Property'));
      });

      test('does not create section completed events for incomplete sections', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.draft,
          createdAt: DateTime(2024, 1, 15, 10),
        );

        final sections = [
          const SurveySection(
            id: 'section-1',
            surveyId: 'survey-1',
            sectionType: SectionType.aboutProperty,
            title: 'About Property',
            order: 1,
          ),
        ];

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: sections,
        );

        final sectionEvents = events
            .where((e) => e.type == TimelineEventType.sectionCompleted)
            .toList();

        expect(sectionEvents, isEmpty);
      });

      test('creates resumed event for inProgress status', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.inProgress,
          createdAt: DateTime(2024, 1, 15, 10),
          updatedAt: DateTime(2024, 1, 15, 11),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        final resumedEvents = events
            .where((e) => e.type == TimelineEventType.resumed)
            .toList();

        expect(resumedEvents.length, equals(1));
      });

      test('creates paused event for paused status', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.paused,
          createdAt: DateTime(2024, 1, 15, 10),
          updatedAt: DateTime(2024, 1, 15, 12),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        final pausedEvents = events
            .where((e) => e.type == TimelineEventType.paused)
            .toList();

        expect(pausedEvents.length, equals(1));
      });

      test('creates completed event for completed status', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.completed,
          createdAt: DateTime(2024, 1, 15, 10),
          completedAt: DateTime(2024, 1, 15, 14),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        final completedEvents = events
            .where((e) => e.type == TimelineEventType.completed)
            .toList();

        expect(completedEvents.length, equals(1));
      });

      test('creates submitted event for pendingReview status', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.pendingReview,
          createdAt: DateTime(2024, 1, 15, 10),
          completedAt: DateTime(2024, 1, 15, 14),
          updatedAt: DateTime(2024, 1, 15, 15),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        final submittedEvents = events
            .where((e) => e.type == TimelineEventType.submittedForReview)
            .toList();

        expect(submittedEvents.length, equals(1));
      });

      test('creates approved event for approved status', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.approved,
          createdAt: DateTime(2024, 1, 15, 10),
          completedAt: DateTime(2024, 1, 15, 14),
          updatedAt: DateTime(2024, 1, 15, 16),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        final approvedEvents = events
            .where((e) => e.type == TimelineEventType.approved)
            .toList();

        expect(approvedEvents.length, equals(1));
      });

      test('creates rejected event for rejected status', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.rejected,
          createdAt: DateTime(2024, 1, 15, 10),
          completedAt: DateTime(2024, 1, 15, 14),
          updatedAt: DateTime(2024, 1, 15, 16),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        final rejectedEvents = events
            .where((e) => e.type == TimelineEventType.rejected)
            .toList();

        expect(rejectedEvents.length, equals(1));
      });

      test('sorts events descending by timestamp', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.completed,
          createdAt: DateTime(2024, 1, 15, 10),
          completedAt: DateTime(2024, 1, 15, 14),
        );

        final sections = [
          SurveySection(
            id: 'section-1',
            surveyId: 'survey-1',
            sectionType: SectionType.aboutProperty,
            title: 'About Property',
            order: 1,
            isCompleted: true,
            updatedAt: DateTime(2024, 1, 15, 11),
          ),
          SurveySection(
            id: 'section-2',
            surveyId: 'survey-1',
            sectionType: SectionType.construction,
            title: 'Construction',
            order: 2,
            isCompleted: true,
            updatedAt: DateTime(2024, 1, 15, 12),
          ),
        ];

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: sections,
        );

        // Verify events are sorted descending (most recent first)
        for (var i = 0; i < events.length - 1; i++) {
          expect(
            events[i].timestamp.isAfter(events[i + 1].timestamp) ||
                events[i].timestamp.isAtSameMomentAs(events[i + 1].timestamp),
            isTrue,
            reason: 'Event at index $i should be after or at same time as event at index ${i + 1}',
          );
        }
      });

      test('handles survey with no updatedAt gracefully', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.draft,
          createdAt: DateTime(2024, 1, 15, 10),
        );

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: [],
        );

        // Should still have the created event
        expect(events.length, equals(1));
        expect(events.first.type, equals(TimelineEventType.created));
      });

      test('generates unique IDs for events', () {
        final survey = Survey(
          id: 'survey-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.completed,
          createdAt: DateTime(2024, 1, 15, 10),
          completedAt: DateTime(2024, 1, 15, 14),
        );

        final sections = [
          SurveySection(
            id: 'section-1',
            surveyId: 'survey-1',
            sectionType: SectionType.aboutProperty,
            title: 'About Property',
            order: 1,
            isCompleted: true,
            updatedAt: DateTime(2024, 1, 15, 11),
          ),
        ];

        final events = service.generateTimelineEvents(
          survey: survey,
          sections: sections,
        );

        final ids = events.map((e) => e.id).toSet();
        expect(ids.length, equals(events.length), reason: 'All event IDs should be unique');
      });
    });

    group('getEventSemanticLabel', () {
      test('includes title and description in semantic label', () {
        final event = TimelineEvent(
          id: 'event-1',
          surveyId: 'survey-1',
          type: TimelineEventType.sectionCompleted,
          title: 'Section Completed',
          description: 'About Property',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        );

        final label = service.getEventSemanticLabel(event);

        expect(label, contains('Section Completed'));
        expect(label, contains('About Property'));
      });

      test('handles missing description', () {
        final event = TimelineEvent(
          id: 'event-1',
          surveyId: 'survey-1',
          type: TimelineEventType.created,
          title: 'Survey Created',
          timestamp: DateTime.now(),
        );

        final label = service.getEventSemanticLabel(event);

        expect(label, contains('Survey Created'));
      });
    });
  });
}
