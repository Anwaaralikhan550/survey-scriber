import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_action.dart';

void main() {
  group('SurveyAction', () {
    group('enum properties', () {
      test('startSurvey has correct properties', () {
        const action = SurveyAction.startSurvey;
        expect(action.id, equals('start_survey'));
        expect(action.defaultLabel, equals('Start Survey'));
        expect(action.priority, equals(ActionPriority.primary));
        expect(action.allowedStatuses, equals({SurveyStatus.draft}));
        expect(action.requiresConfirmation, isFalse);
        expect(action.isPrimary, isTrue);
        expect(action.isSecondary, isFalse);
      });

      test('resumeSurvey has correct properties', () {
        const action = SurveyAction.resumeSurvey;
        expect(action.id, equals('resume_survey'));
        expect(action.defaultLabel, equals('Resume Survey'));
        expect(action.priority, equals(ActionPriority.primary));
        expect(action.allowedStatuses, equals({
          SurveyStatus.inProgress,
          SurveyStatus.paused,
          SurveyStatus.rejected,
        }),);
        expect(action.requiresConfirmation, isFalse);
        expect(action.isPrimary, isTrue);
      });

      test('pauseSurvey has correct properties', () {
        const action = SurveyAction.pauseSurvey;
        expect(action.id, equals('pause_survey'));
        expect(action.priority, equals(ActionPriority.secondary));
        expect(action.allowedStatuses, equals({SurveyStatus.inProgress}));
        expect(action.requiresConfirmation, isFalse);
        expect(action.isSecondary, isTrue);
      });

      test('markCompleted requires confirmation', () {
        const action = SurveyAction.markCompleted;
        expect(action.requiresConfirmation, isTrue);
        expect(action.priority, equals(ActionPriority.secondary));
      });

      test('submitForReview requires confirmation', () {
        const action = SurveyAction.submitForReview;
        expect(action.requiresConfirmation, isTrue);
        expect(action.priority, equals(ActionPriority.primary));
        expect(action.allowedStatuses, equals({SurveyStatus.completed}));
      });

      test('approve requires confirmation', () {
        const action = SurveyAction.approve;
        expect(action.requiresConfirmation, isTrue);
        expect(action.allowedStatuses, equals({SurveyStatus.pendingReview}));
      });

      test('reject requires confirmation', () {
        const action = SurveyAction.reject;
        expect(action.requiresConfirmation, isTrue);
        expect(action.priority, equals(ActionPriority.secondary));
      });

      test('exportPdf has correct allowed statuses', () {
        const action = SurveyAction.exportPdf;
        expect(action.allowedStatuses, equals({
          SurveyStatus.completed,
          SurveyStatus.pendingReview,
          SurveyStatus.approved,
        }),);
        expect(action.requiresConfirmation, isFalse);
      });

      test('share is allowed for all statuses', () {
        const action = SurveyAction.share;
        expect(action.allowedStatuses.length, equals(7));
        for (final status in SurveyStatus.values) {
          expect(action.isAllowedFor(status), isTrue,
              reason: 'share should be allowed for $status',);
        }
      });

      test('delete requires confirmation and has limited statuses', () {
        const action = SurveyAction.delete;
        expect(action.requiresConfirmation, isTrue);
        expect(action.allowedStatuses, equals({
          SurveyStatus.draft,
          SurveyStatus.paused,
          SurveyStatus.rejected,
        }),);
      });

      test('viewReport is only for approved surveys', () {
        const action = SurveyAction.viewReport;
        expect(action.allowedStatuses, equals({SurveyStatus.approved}));
        expect(action.priority, equals(ActionPriority.primary));
      });
    });

    group('isAllowedFor', () {
      test('startSurvey is only allowed for draft', () {
        const action = SurveyAction.startSurvey;
        expect(action.isAllowedFor(SurveyStatus.draft), isTrue);
        expect(action.isAllowedFor(SurveyStatus.inProgress), isFalse);
        expect(action.isAllowedFor(SurveyStatus.paused), isFalse);
        expect(action.isAllowedFor(SurveyStatus.completed), isFalse);
        expect(action.isAllowedFor(SurveyStatus.pendingReview), isFalse);
        expect(action.isAllowedFor(SurveyStatus.approved), isFalse);
        expect(action.isAllowedFor(SurveyStatus.rejected), isFalse);
      });

      test('pauseSurvey is only allowed for inProgress', () {
        const action = SurveyAction.pauseSurvey;
        expect(action.isAllowedFor(SurveyStatus.inProgress), isTrue);
        expect(action.isAllowedFor(SurveyStatus.draft), isFalse);
        expect(action.isAllowedFor(SurveyStatus.paused), isFalse);
      });
    });
  });

  group('ActionNavigationIntent', () {
    test('NavigateToSection holds section ID', () {
      const intent = NavigateToSection(sectionId: 'section-123');
      expect(intent.sectionId, equals('section-123'));
    });

    test('StayOnScreen is a singleton-like constant', () {
      const intent1 = StayOnScreen();
      const intent2 = StayOnScreen();
      expect(identical(intent1, intent2), isTrue);
    });

    test('NavigateToReport holds survey ID', () {
      const intent = NavigateToReport(surveyId: 'survey-456');
      expect(intent.surveyId, equals('survey-456'));
    });

    test('ShowMessage holds message and error state', () {
      const intent = ShowMessage(message: 'Test message', isError: true);
      expect(intent.message, equals('Test message'));
      expect(intent.isError, isTrue);
    });

    test('ShowMessage defaults to non-error', () {
      const intent = ShowMessage(message: 'Info message');
      expect(intent.isError, isFalse);
    });

    test('ActionNotImplemented holds action label', () {
      const intent = ActionNotImplemented(actionLabel: 'Export PDF');
      expect(intent.actionLabel, equals('Export PDF'));
    });
  });

  group('ActionPriority', () {
    test('primary and secondary are distinct', () {
      expect(ActionPriority.primary, isNot(equals(ActionPriority.secondary)));
    });

    test('all primary actions have primary priority', () {
      final primaryActions = SurveyAction.values
          .where((a) => a.isPrimary)
          .toList();

      expect(primaryActions, isNotEmpty);
      for (final action in primaryActions) {
        expect(action.priority, equals(ActionPriority.primary));
      }
    });

    test('all secondary actions have secondary priority', () {
      final secondaryActions = SurveyAction.values
          .where((a) => a.isSecondary)
          .toList();

      expect(secondaryActions, isNotEmpty);
      for (final action in secondaryActions) {
        expect(action.priority, equals(ActionPriority.secondary));
      }
    });
  });
}
