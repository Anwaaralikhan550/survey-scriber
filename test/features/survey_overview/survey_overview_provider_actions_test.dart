import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/survey_overview/presentation/providers/survey_overview_provider.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_action.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  // Helper to create test surveys
  Survey createSurvey({
    required SurveyStatus status,
    String id = 'survey-1',
  }) =>
      Survey(
        id: id,
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: status,
        createdAt: DateTime(2024, 1, 15),
      );

  // Helper to create test sections
  List<SurveySection> createSections({
    int total = 3,
    int completed = 0,
  }) =>
      List.generate(total, (i) => SurveySection(
          id: 'section-${i + 1}',
          surveyId: 'survey-1',
          sectionType: SectionType.aboutProperty,
          title: 'Section ${i + 1}',
          order: i + 1,
          isCompleted: i < completed,
        ),);

  group('SurveyOverviewState actions', () {
    group('primaryAction', () {
      test('returns null when no survey', () {
        const state = SurveyOverviewState();
        expect(state.primaryAction, isNull);
      });

      test('returns startSurvey for draft survey', () {
        final survey = createSurvey(status: SurveyStatus.draft);
        final sections = createSections();

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.primaryAction, isNotNull);
        expect(state.primaryAction!.action, equals(SurveyAction.startSurvey));
        expect(state.primaryAction!.isEnabled, isTrue);
      });

      test('returns resumeSurvey for inProgress survey', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 1);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.primaryAction, isNotNull);
        expect(state.primaryAction!.action, equals(SurveyAction.resumeSurvey));
        expect(state.primaryAction!.label, contains('Section 2'));
      });

      test('returns submitForReview for completed survey', () {
        final survey = createSurvey(status: SurveyStatus.completed);
        final sections = createSections(completed: 3);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.primaryAction, isNotNull);
        expect(state.primaryAction!.action, equals(SurveyAction.submitForReview));
        expect(state.primaryAction!.requiresConfirmation, isTrue);
      });

      test('returns approve for pendingReview survey', () {
        final survey = createSurvey(status: SurveyStatus.pendingReview);
        final sections = createSections(completed: 3);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.primaryAction, isNotNull);
        expect(state.primaryAction!.action, equals(SurveyAction.approve));
      });

      test('returns viewReport for approved survey', () {
        final survey = createSurvey(status: SurveyStatus.approved);
        final sections = createSections(completed: 3);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.primaryAction, isNotNull);
        expect(state.primaryAction!.action, equals(SurveyAction.viewReport));
      });

      test('returns resumeSurvey (Revise) for rejected survey', () {
        final survey = createSurvey(status: SurveyStatus.rejected);
        final sections = createSections(completed: 2);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.primaryAction, isNotNull);
        expect(state.primaryAction!.action, equals(SurveyAction.resumeSurvey));
      });
    });

    group('secondaryActions', () {
      test('returns empty list when no survey', () {
        const state = SurveyOverviewState();
        expect(state.secondaryActions, isEmpty);
      });

      test('includes pause for inProgress survey', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections();

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        final hasPause = state.secondaryActions
            .any((a) => a.action == SurveyAction.pauseSurvey);
        expect(hasPause, isTrue);
      });

      test('includes share for all statuses', () {
        for (final status in SurveyStatus.values) {
          final survey = createSurvey(status: status);
          final sections = createSections(completed: 3);

          final state = SurveyOverviewState(
            survey: survey,
            sections: sections,
            isLoading: false,
          );

          final hasShare = state.secondaryActions
              .any((a) => a.action == SurveyAction.share);
          expect(hasShare, isTrue, reason: 'Expected share for $status');
        }
      });

      test('excludes markCompleted when sections incomplete', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 1);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        final hasMarkComplete = state.secondaryActions
            .any((a) => a.action == SurveyAction.markCompleted);
        expect(hasMarkComplete, isFalse);
      });

      test('includes markCompleted when all sections complete', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 3);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        final hasMarkComplete = state.secondaryActions
            .any((a) => a.action == SurveyAction.markCompleted);
        expect(hasMarkComplete, isTrue);
      });

      test('includes reject for pendingReview', () {
        final survey = createSurvey(status: SurveyStatus.pendingReview);
        final sections = createSections(completed: 3);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        final hasReject = state.secondaryActions
            .any((a) => a.action == SurveyAction.reject);
        expect(hasReject, isTrue);
      });

      test('includes exportPdf for completed surveys', () {
        final survey = createSurvey(status: SurveyStatus.completed);
        final sections = createSections(completed: 3);

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        final hasExport = state.secondaryActions
            .any((a) => a.action == SurveyAction.exportPdf);
        expect(hasExport, isTrue);
      });

      test('includes delete for draft/paused/rejected', () {
        for (final status in [
          SurveyStatus.draft,
          SurveyStatus.paused,
          SurveyStatus.rejected,
        ]) {
          final survey = createSurvey(status: status);
          final sections = createSections();

          final state = SurveyOverviewState(
            survey: survey,
            sections: sections,
            isLoading: false,
          );

          final hasDelete = state.secondaryActions
              .any((a) => a.action == SurveyAction.delete);
          expect(hasDelete, isTrue, reason: 'Expected delete for $status');
        }
      });

      test('excludes delete for inProgress/completed/pendingReview/approved', () {
        for (final status in [
          SurveyStatus.inProgress,
          SurveyStatus.completed,
          SurveyStatus.pendingReview,
          SurveyStatus.approved,
        ]) {
          final survey = createSurvey(status: status);
          final sections = createSections(completed: 3);

          final state = SurveyOverviewState(
            survey: survey,
            sections: sections,
            isLoading: false,
          );

          final hasDelete = state.secondaryActions
              .any((a) => a.action == SurveyAction.delete);
          expect(hasDelete, isFalse, reason: 'Should not have delete for $status');
        }
      });
    });

    group('hasActions', () {
      test('returns false when no survey', () {
        const state = SurveyOverviewState();
        expect(state.hasActions, isFalse);
      });

      test('returns true when survey exists', () {
        final survey = createSurvey(status: SurveyStatus.draft);
        final sections = createSections();

        final state = SurveyOverviewState(
          survey: survey,
          sections: sections,
          isLoading: false,
        );

        expect(state.hasActions, isTrue);
      });
    });
  });

  group('Action state transitions by status', () {
    test('draft status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.draft);
      final sections = createSections();

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: startSurvey
      expect(state.primaryAction!.action, equals(SurveyAction.startSurvey));

      // Secondary: share, delete
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.delete), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.pauseSurvey), isFalse);
    });

    test('inProgress status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.inProgress);
      final sections = createSections(completed: 1);

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: resumeSurvey
      expect(state.primaryAction!.action, equals(SurveyAction.resumeSurvey));

      // Secondary: pause, share (no markCompleted since not all done)
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.pauseSurvey), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.markCompleted), isFalse);
    });

    test('paused status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.paused);
      final sections = createSections(completed: 2);

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: resumeSurvey
      expect(state.primaryAction!.action, equals(SurveyAction.resumeSurvey));

      // Secondary: share, delete
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.delete), isTrue);
    });

    test('completed status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.completed);
      final sections = createSections(completed: 3);

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: submitForReview
      expect(state.primaryAction!.action, equals(SurveyAction.submitForReview));

      // Secondary: exportPdf, share
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.exportPdf), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
    });

    test('pendingReview status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.pendingReview);
      final sections = createSections(completed: 3);

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: approve
      expect(state.primaryAction!.action, equals(SurveyAction.approve));

      // Secondary: reject, exportPdf, share
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.reject), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.exportPdf), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
    });

    test('approved status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.approved);
      final sections = createSections(completed: 3);

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: viewReport
      expect(state.primaryAction!.action, equals(SurveyAction.viewReport));

      // Secondary: exportPdf, share
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.exportPdf), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
    });

    test('rejected status has correct primary/secondary split', () {
      final survey = createSurvey(status: SurveyStatus.rejected);
      final sections = createSections(completed: 2);

      final state = SurveyOverviewState(
        survey: survey,
        sections: sections,
        isLoading: false,
      );

      // Primary: resumeSurvey (Revise)
      expect(state.primaryAction!.action, equals(SurveyAction.resumeSurvey));

      // Secondary: share, delete
      final secondaryActionTypes = state.secondaryActions.map((a) => a.action).toSet();
      expect(secondaryActionTypes.contains(SurveyAction.share), isTrue);
      expect(secondaryActionTypes.contains(SurveyAction.delete), isTrue);
    });
  });
}
