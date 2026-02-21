import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_action.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';
import 'package:survey_scriber/shared/domain/services/survey_action_resolver.dart';

void main() {
  const resolver = SurveyActionResolver.instance;

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

  group('SurveyActionResolver', () {
    group('resolvePrimaryAction', () {
      test('returns startSurvey for draft status', () {
        final survey = createSurvey(status: SurveyStatus.draft);
        final sections = createSections();

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.startSurvey));
        expect(result.label, equals('Start Survey'));
        expect(result.isEnabled, isTrue);
        expect(result.isPrimary, isTrue);
      });

      test('returns resumeSurvey for inProgress status', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 1);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.resumeSurvey));
        expect(result.label, contains('Resume'));
        expect(result.label, contains('Section 2')); // First incomplete
        expect(result.isEnabled, isTrue);
      });

      test('returns resumeSurvey for paused status', () {
        final survey = createSurvey(status: SurveyStatus.paused);
        final sections = createSections(completed: 2);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.resumeSurvey));
        expect(result.label, contains('Resume'));
        expect(result.isEnabled, isTrue);
      });

      test('returns submitForReview for completed status', () {
        final survey = createSurvey(status: SurveyStatus.completed);
        final sections = createSections(completed: 3);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.submitForReview));
        expect(result.label, equals('Submit for Review'));
        expect(result.isEnabled, isTrue);
        expect(result.requiresConfirmation, isTrue);
      });

      test('returns approve for pendingReview status', () {
        final survey = createSurvey(status: SurveyStatus.pendingReview);
        final sections = createSections(completed: 3);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.approve));
        expect(result.label, equals('Approve'));
        expect(result.isEnabled, isTrue);
        expect(result.requiresConfirmation, isTrue);
      });

      test('returns viewReport for approved status', () {
        final survey = createSurvey(status: SurveyStatus.approved);
        final sections = createSections(completed: 3);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.viewReport));
        expect(result.label, equals('View Report'));
        expect(result.isEnabled, isTrue);
      });

      test('returns resumeSurvey for rejected status', () {
        final survey = createSurvey(status: SurveyStatus.rejected);
        final sections = createSections(completed: 2);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.resumeSurvey));
        // When there are incomplete sections, it shows the section name
        expect(result.label, contains('Resume'));
        expect(result.label, contains('Section 3'));
        expect(result.isEnabled, isTrue);
      });

      test('returns Revise Survey label for rejected status with empty sections', () {
        final survey = createSurvey(status: SurveyStatus.rejected);
        final sections = <SurveySection>[];

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.action, equals(SurveyAction.resumeSurvey));
        // When there are no sections, it returns 'Revise Survey'
        expect(result.label, equals('Revise Survey'));
        // But it should be disabled because no sections
        expect(result.isEnabled, isFalse);
      });

      test('returns disabled when no sections exist for draft', () {
        final survey = createSurvey(status: SurveyStatus.draft);
        final sections = <SurveySection>[];

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.isEnabled, isFalse);
        expect(result.disabledReason, isNotNull);
      });

      test('includes targetSectionId for navigation actions', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 1);

        final result = resolver.resolvePrimaryAction(
          survey: survey,
          sections: sections,
        );

        expect(result, isNotNull);
        expect(result!.targetSectionId, equals('section-2'));
      });
    });

    group('resolveSecondaryActions', () {
      test('returns pause and share for inProgress', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 1);

        final result = resolver.resolveSecondaryActions(
          survey: survey,
          sections: sections,
        );

        final actionIds = result.map((a) => a.action).toSet();
        expect(actionIds.contains(SurveyAction.pauseSurvey), isTrue);
        expect(actionIds.contains(SurveyAction.share), isTrue);
      });

      test('includes markCompleted only when all sections complete', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final incompleteSections = createSections(completed: 1);
        final completeSections = createSections(completed: 3);

        final incompleteResult = resolver.resolveSecondaryActions(
          survey: survey,
          sections: incompleteSections,
        );

        final completeResult = resolver.resolveSecondaryActions(
          survey: survey,
          sections: completeSections,
        );

        final incompleteActions = incompleteResult.map((a) => a.action).toSet();
        final completeActions = completeResult.map((a) => a.action).toSet();

        expect(incompleteActions.contains(SurveyAction.markCompleted), isFalse);
        expect(completeActions.contains(SurveyAction.markCompleted), isTrue);
      });

      test('includes export PDF for completed/pending/approved', () {
        for (final status in [
          SurveyStatus.completed,
          SurveyStatus.pendingReview,
          SurveyStatus.approved,
        ]) {
          final survey = createSurvey(status: status);
          final sections = createSections(completed: 3);

          final result = resolver.resolveSecondaryActions(
            survey: survey,
            sections: sections,
          );

          final hasExport = result.any((a) => a.action == SurveyAction.exportPdf);
          expect(hasExport, isTrue, reason: 'Expected exportPdf for $status');
        }
      });

      test('includes reject for pendingReview', () {
        final survey = createSurvey(status: SurveyStatus.pendingReview);
        final sections = createSections(completed: 3);

        final result = resolver.resolveSecondaryActions(
          survey: survey,
          sections: sections,
        );

        final hasReject = result.any((a) => a.action == SurveyAction.reject);
        expect(hasReject, isTrue);
      });

      test('includes delete for draft/paused/rejected', () {
        for (final status in [
          SurveyStatus.draft,
          SurveyStatus.paused,
          SurveyStatus.rejected,
        ]) {
          final survey = createSurvey(status: status);
          final sections = createSections();

          final result = resolver.resolveSecondaryActions(
            survey: survey,
            sections: sections,
          );

          final hasDelete = result.any((a) => a.action == SurveyAction.delete);
          expect(hasDelete, isTrue, reason: 'Expected delete for $status');
        }
      });

      test('all returned actions are secondary priority', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections();

        final result = resolver.resolveSecondaryActions(
          survey: survey,
          sections: sections,
        );

        for (final action in result) {
          expect(action.isSecondary, isTrue,
              reason: '${action.action} should be secondary',);
        }
      });
    });

    group('getActionLabel', () {
      test('includes section name for resume actions', () {
        final label = resolver.getActionLabel(
          action: SurveyAction.resumeSurvey,
          status: SurveyStatus.inProgress,
          sectionName: 'Construction Details',
        );

        expect(label, equals('Resume: Construction Details'));
      });

      test('returns Continue Survey when no section name', () {
        final label = resolver.getActionLabel(
          action: SurveyAction.resumeSurvey,
          status: SurveyStatus.inProgress,
        );

        expect(label, equals('Continue Survey'));
      });

      test('returns Revise Survey for rejected status', () {
        final label = resolver.getActionLabel(
          action: SurveyAction.resumeSurvey,
          status: SurveyStatus.rejected,
        );

        expect(label, equals('Revise Survey'));
      });

      test('returns default labels for other actions', () {
        expect(
          resolver.getActionLabel(
            action: SurveyAction.pauseSurvey,
            status: SurveyStatus.inProgress,
          ),
          equals('Pause'),
        );

        expect(
          resolver.getActionLabel(
            action: SurveyAction.submitForReview,
            status: SurveyStatus.completed,
          ),
          equals('Submit for Review'),
        );
      });
    });

    group('isActionEnabled', () {
      test('startSurvey requires sections', () {
        final sections = createSections();
        final emptySections = <SurveySection>[];

        expect(
          resolver.isActionEnabled(
            action: SurveyAction.startSurvey,
            status: SurveyStatus.draft,
            sections: sections,
          ),
          isTrue,
        );

        expect(
          resolver.isActionEnabled(
            action: SurveyAction.startSurvey,
            status: SurveyStatus.draft,
            sections: emptySections,
          ),
          isFalse,
        );
      });

      test('markCompleted requires all sections complete', () {
        final incompleteSections = createSections(completed: 2);
        final completeSections = createSections(completed: 3);

        expect(
          resolver.isActionEnabled(
            action: SurveyAction.markCompleted,
            status: SurveyStatus.inProgress,
            sections: incompleteSections,
          ),
          isFalse,
        );

        expect(
          resolver.isActionEnabled(
            action: SurveyAction.markCompleted,
            status: SurveyStatus.inProgress,
            sections: completeSections,
          ),
          isTrue,
        );
      });

      test('returns false for wrong status', () {
        final sections = createSections();

        expect(
          resolver.isActionEnabled(
            action: SurveyAction.startSurvey,
            status: SurveyStatus.inProgress, // Wrong status
            sections: sections,
          ),
          isFalse,
        );
      });
    });

    group('getNavigationIntent', () {
      test('returns NavigateToSection for start/resume actions', () {
        final survey = createSurvey(status: SurveyStatus.draft);
        final sections = createSections();

        final intent = resolver.getNavigationIntent(
          action: SurveyAction.startSurvey,
          survey: survey,
          sections: sections,
        );

        expect(intent, isA<NavigateToSection>());
        expect((intent as NavigateToSection).sectionId, equals('section-1'));
      });

      test('returns StayOnScreen for status update actions', () {
        final survey = createSurvey(status: SurveyStatus.inProgress);
        final sections = createSections(completed: 3);

        for (final action in [
          SurveyAction.pauseSurvey,
          SurveyAction.markCompleted,
          SurveyAction.submitForReview,
        ]) {
          final intent = resolver.getNavigationIntent(
            action: action,
            survey: survey,
            sections: sections,
          );

          expect(intent, isA<StayOnScreen>(),
              reason: '$action should return StayOnScreen',);
        }
      });

      test('returns StayOnScreen for UI-intercepted actions', () {
        final survey = createSurvey(status: SurveyStatus.completed);
        final sections = createSections(completed: 3);

        // These actions are handled in UI layer before reaching resolver
        for (final action in [
          SurveyAction.exportPdf,
          SurveyAction.share,
          SurveyAction.delete,
          SurveyAction.viewReport,
        ]) {
          final intent = resolver.getNavigationIntent(
            action: action,
            survey: survey,
            sections: sections,
          );

          expect(intent, isA<StayOnScreen>(),
              reason: '$action should return StayOnScreen',);
        }
      });

      test('returns ShowMessage when no sections available', () {
        final survey = createSurvey(status: SurveyStatus.draft);
        final sections = <SurveySection>[];

        final intent = resolver.getNavigationIntent(
          action: SurveyAction.startSurvey,
          survey: survey,
          sections: sections,
        );

        expect(intent, isA<ShowMessage>());
      });
    });

    group('getTargetStatus', () {
      test('returns correct status transitions', () {
        expect(
          resolver.getTargetStatus(SurveyAction.startSurvey, SurveyStatus.draft),
          equals(SurveyStatus.inProgress),
        );

        expect(
          resolver.getTargetStatus(SurveyAction.pauseSurvey, SurveyStatus.inProgress),
          equals(SurveyStatus.paused),
        );

        expect(
          resolver.getTargetStatus(SurveyAction.markCompleted, SurveyStatus.inProgress),
          equals(SurveyStatus.completed),
        );

        expect(
          resolver.getTargetStatus(SurveyAction.submitForReview, SurveyStatus.completed),
          equals(SurveyStatus.pendingReview),
        );

        expect(
          resolver.getTargetStatus(SurveyAction.approve, SurveyStatus.pendingReview),
          equals(SurveyStatus.approved),
        );

        expect(
          resolver.getTargetStatus(SurveyAction.reject, SurveyStatus.pendingReview),
          equals(SurveyStatus.rejected),
        );
      });

      test('returns null for non-status-changing actions', () {
        expect(
          resolver.getTargetStatus(SurveyAction.exportPdf, SurveyStatus.completed),
          isNull,
        );

        expect(
          resolver.getTargetStatus(SurveyAction.share, SurveyStatus.inProgress),
          isNull,
        );

        expect(
          resolver.getTargetStatus(SurveyAction.viewReport, SurveyStatus.approved),
          isNull,
        );
      });

      test('resumeSurvey returns inProgress only from paused/rejected', () {
        expect(
          resolver.getTargetStatus(SurveyAction.resumeSurvey, SurveyStatus.paused),
          equals(SurveyStatus.inProgress),
        );

        expect(
          resolver.getTargetStatus(SurveyAction.resumeSurvey, SurveyStatus.rejected),
          equals(SurveyStatus.inProgress),
        );

        // No status change when already inProgress
        expect(
          resolver.getTargetStatus(SurveyAction.resumeSurvey, SurveyStatus.inProgress),
          isNull,
        );
      });
    });

    group('canExecuteAction', () {
      test('validates status engine transitions', () {
        expect(
          resolver.canExecuteAction(SurveyAction.startSurvey, SurveyStatus.draft),
          isTrue,
        );

        expect(
          resolver.canExecuteAction(SurveyAction.startSurvey, SurveyStatus.inProgress),
          isFalse,
        );

        expect(
          resolver.canExecuteAction(SurveyAction.pauseSurvey, SurveyStatus.inProgress),
          isTrue,
        );

        expect(
          resolver.canExecuteAction(SurveyAction.pauseSurvey, SurveyStatus.draft),
          isFalse,
        );
      });

      test('allows non-status-changing actions if status is valid', () {
        expect(
          resolver.canExecuteAction(SurveyAction.share, SurveyStatus.draft),
          isTrue,
        );

        expect(
          resolver.canExecuteAction(SurveyAction.exportPdf, SurveyStatus.completed),
          isTrue,
        );

        expect(
          resolver.canExecuteAction(SurveyAction.exportPdf, SurveyStatus.draft),
          isFalse, // Not in allowedStatuses
        );
      });
    });

    group('getConfirmationContent', () {
      test('returns content for confirmation-required actions', () {
        final markCompleteContent = resolver.getConfirmationContent(
          SurveyAction.markCompleted,
        );
        expect(markCompleteContent, isNotNull);
        expect(markCompleteContent!.title, contains('Complete'));

        final submitContent = resolver.getConfirmationContent(
          SurveyAction.submitForReview,
        );
        expect(submitContent, isNotNull);
        expect(submitContent!.title, contains('Review'));

        final deleteContent = resolver.getConfirmationContent(
          SurveyAction.delete,
        );
        expect(deleteContent, isNotNull);
        expect(deleteContent!.title, contains('Delete'));
      });

      test('returns null for non-confirmation actions', () {
        expect(
          resolver.getConfirmationContent(SurveyAction.startSurvey),
          isNull,
        );

        expect(
          resolver.getConfirmationContent(SurveyAction.pauseSurvey),
          isNull,
        );

        expect(
          resolver.getConfirmationContent(SurveyAction.share),
          isNull,
        );
      });
    });
  });

  group('SurveyActionUiModel', () {
    test('exposes underlying action properties', () {
      const model = SurveyActionUiModel(
        action: SurveyAction.startSurvey,
        label: 'Start Survey',
        isEnabled: true,
      );

      expect(model.requiresConfirmation, equals(SurveyAction.startSurvey.requiresConfirmation));
      expect(model.isPrimary, equals(SurveyAction.startSurvey.isPrimary));
      expect(model.isSecondary, equals(SurveyAction.startSurvey.isSecondary));
    });

    test('holds optional properties', () {
      const model = SurveyActionUiModel(
        action: SurveyAction.resumeSurvey,
        label: 'Resume: Section 2',
        isEnabled: true,
        targetSectionId: 'section-2',
      );

      expect(model.targetSectionId, equals('section-2'));
      expect(model.disabledReason, isNull);
    });

    test('holds disabled reason when not enabled', () {
      const model = SurveyActionUiModel(
        action: SurveyAction.startSurvey,
        label: 'Start Survey',
        isEnabled: false,
        disabledReason: 'No sections available',
      );

      expect(model.isEnabled, isFalse);
      expect(model.disabledReason, equals('No sections available'));
    });
  });
}
