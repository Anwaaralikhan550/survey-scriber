import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/survey_overview/presentation/providers/survey_overview_provider.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  group('SurveyOverviewState', () {
    test('initial state has correct defaults', () {
      const state = SurveyOverviewState();

      expect(state.survey, isNull);
      expect(state.sections, isEmpty);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);
      expect(state.hasError, isFalse);
      expect(state.hasSurvey, isFalse);
      expect(state.isUpdatingStatus, isFalse);
    });

    test('primaryActionLabel returns correct label for draft status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.draft,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.primaryActionLabel, equals('Start Survey'));
    });

    test('primaryActionLabel returns section name for inProgress status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.inProgress,
        createdAt: DateTime.now(),
      );

      final sections = [
        const SurveySection(
          id: 'section-1',
          surveyId: 'test-id',
          sectionType: SectionType.aboutProperty,
          title: 'About Property',
          order: 1,
          isCompleted: true,
        ),
        const SurveySection(
          id: 'section-2',
          surveyId: 'test-id',
          sectionType: SectionType.construction,
          title: 'Construction',
          order: 2,
        ),
      ];

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      expect(state.primaryActionLabel, equals('Resume: Construction'));
    });

    test('primaryActionLabel returns generic resume for inProgress with no sections', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.inProgress,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.primaryActionLabel, equals('Continue Survey'));
    });

    test('primaryActionLabel returns correct label for paused status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.paused,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.primaryActionLabel, equals('Resume Survey'));
    });

    test('primaryActionLabel returns correct label for completed status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.primaryActionLabel, equals('Submit for Review'));
    });

    test('isPrimaryActionEnabled is true for actionable statuses', () {
      final draftSurvey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.draft,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: draftSurvey,
        isLoading: false,
      );

      expect(state.isPrimaryActionEnabled, isTrue);
    });

    test('isPrimaryActionEnabled is false for pendingReview status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.pendingReview,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.isPrimaryActionEnabled, isFalse);
    });

    test('targetSection returns first incomplete section', () {
      final sections = [
        const SurveySection(
          id: 'section-1',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'About Property',
          order: 1,
          isCompleted: true,
        ),
        const SurveySection(
          id: 'section-2',
          surveyId: 'survey-1',
          sectionType: SectionType.construction,
          title: 'Construction',
          order: 2,
        ),
        const SurveySection(
          id: 'section-3',
          surveyId: 'survey-1',
          sectionType: SectionType.exterior,
          title: 'Exterior',
          order: 3,
        ),
      ];

      final state = SurveyOverviewState(
        sections: sections,
        isLoading: false,
      );

      expect(state.targetSection, isNotNull);
      expect(state.targetSection!.id, equals('section-2'));
    });

    test('targetSection returns last section when all completed', () {
      final sections = [
        const SurveySection(
          id: 'section-1',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'About Property',
          order: 1,
          isCompleted: true,
        ),
        const SurveySection(
          id: 'section-2',
          surveyId: 'survey-1',
          sectionType: SectionType.construction,
          title: 'Construction',
          order: 2,
          isCompleted: true,
        ),
      ];

      final state = SurveyOverviewState(
        sections: sections,
        isLoading: false,
      );

      expect(state.targetSection, isNotNull);
      expect(state.targetSection!.id, equals('section-2'));
    });

    test('shouldNavigateToSection is true for draft status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.draft,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.shouldNavigateToSection, isTrue);
    });

    test('shouldNavigateToSection is false for completed status', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.completed,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.shouldNavigateToSection, isFalse);
    });

    test('nextStatusOnPrimaryAction returns inProgress for draft', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.draft,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.nextStatusOnPrimaryAction, equals(SurveyStatus.inProgress));
    });

    test('nextStatusOnPrimaryAction returns null for inProgress', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.inProgress,
        createdAt: DateTime.now(),
      );

      final state = SurveyOverviewState(
        survey: survey,
        isLoading: false,
      );

      expect(state.nextStatusOnPrimaryAction, isNull);
    });

    test('copyWith creates new state with updated values', () {
      const original = SurveyOverviewState();

      final updated = original.copyWith(
        isLoading: false,
        errorMessage: 'Test error',
        isUpdatingStatus: true,
      );

      expect(updated.isLoading, isFalse);
      expect(updated.errorMessage, equals('Test error'));
      expect(updated.hasError, isTrue);
      expect(updated.isUpdatingStatus, isTrue);
    });

    test('resumeContext provides correct progress information', () {
      final sections = [
        const SurveySection(
          id: 'section-1',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'About Property',
          order: 1,
          isCompleted: true,
        ),
        const SurveySection(
          id: 'section-2',
          surveyId: 'survey-1',
          sectionType: SectionType.construction,
          title: 'Construction',
          order: 2,
        ),
        const SurveySection(
          id: 'section-3',
          surveyId: 'survey-1',
          sectionType: SectionType.exterior,
          title: 'Exterior',
          order: 3,
        ),
      ];

      final state = SurveyOverviewState(
        sections: sections,
        isLoading: false,
      );

      final context = state.resumeContext;
      expect(context.completedCount, equals(1));
      expect(context.totalCount, equals(3));
      expect(context.isAllComplete, isFalse);
      expect(context.progressPercent, equals(33));
    });
  });
}
