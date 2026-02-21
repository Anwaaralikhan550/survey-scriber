import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';
import 'package:survey_scriber/shared/domain/services/survey_status_engine.dart';

void main() {
  group('SurveyStatusEngine', () {
    const engine = SurveyStatusEngine.instance;

    group('canTransition', () {
      test('allows draft to inProgress', () {
        expect(
          engine.canTransition(SurveyStatus.draft, SurveyStatus.inProgress),
          isTrue,
        );
      });

      test('allows inProgress to paused', () {
        expect(
          engine.canTransition(SurveyStatus.inProgress, SurveyStatus.paused),
          isTrue,
        );
      });

      test('allows inProgress to completed', () {
        expect(
          engine.canTransition(SurveyStatus.inProgress, SurveyStatus.completed),
          isTrue,
        );
      });

      test('allows paused to inProgress', () {
        expect(
          engine.canTransition(SurveyStatus.paused, SurveyStatus.inProgress),
          isTrue,
        );
      });

      test('allows completed to pendingReview', () {
        expect(
          engine.canTransition(SurveyStatus.completed, SurveyStatus.pendingReview),
          isTrue,
        );
      });

      test('allows pendingReview to approved', () {
        expect(
          engine.canTransition(SurveyStatus.pendingReview, SurveyStatus.approved),
          isTrue,
        );
      });

      test('allows pendingReview to rejected', () {
        expect(
          engine.canTransition(SurveyStatus.pendingReview, SurveyStatus.rejected),
          isTrue,
        );
      });

      test('allows rejected to inProgress', () {
        expect(
          engine.canTransition(SurveyStatus.rejected, SurveyStatus.inProgress),
          isTrue,
        );
      });

      test('disallows approved to any other status', () {
        for (final status in SurveyStatus.values) {
          expect(
            engine.canTransition(SurveyStatus.approved, status),
            isFalse,
          );
        }
      });

      test('disallows draft to completed directly', () {
        expect(
          engine.canTransition(SurveyStatus.draft, SurveyStatus.completed),
          isFalse,
        );
      });

      test('disallows inProgress to draft', () {
        expect(
          engine.canTransition(SurveyStatus.inProgress, SurveyStatus.draft),
          isFalse,
        );
      });
    });

    group('nextStatusOnPrimaryAction', () {
      test('returns inProgress for draft', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.draft),
          equals(SurveyStatus.inProgress),
        );
      });

      test('returns null for inProgress (user continues working)', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.inProgress),
          isNull,
        );
      });

      test('returns inProgress for paused', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.paused),
          equals(SurveyStatus.inProgress),
        );
      });

      test('returns pendingReview for completed', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.completed),
          equals(SurveyStatus.pendingReview),
        );
      });

      test('returns null for pendingReview (awaiting external action)', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.pendingReview),
          isNull,
        );
      });

      test('returns null for approved (view report only)', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.approved),
          isNull,
        );
      });

      test('returns inProgress for rejected', () {
        expect(
          engine.nextStatusOnPrimaryAction(SurveyStatus.rejected),
          equals(SurveyStatus.inProgress),
        );
      });
    });

    group('primaryActionLabel', () {
      test('returns "Start Survey" for draft', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.draft),
          equals('Start Survey'),
        );
      });

      test('returns "Continue Survey" for inProgress without section name', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.inProgress),
          equals('Continue Survey'),
        );
      });

      test('returns "Resume: {section}" for inProgress with section name', () {
        expect(
          engine.primaryActionLabel(
            SurveyStatus.inProgress,
            nextSectionName: 'Construction',
          ),
          equals('Resume: Construction'),
        );
      });

      test('returns "Resume Survey" for paused without section name', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.paused),
          equals('Resume Survey'),
        );
      });

      test('returns "Resume: {section}" for paused with section name', () {
        expect(
          engine.primaryActionLabel(
            SurveyStatus.paused,
            nextSectionName: 'Exterior',
          ),
          equals('Resume: Exterior'),
        );
      });

      test('returns "Submit for Review" for completed', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.completed),
          equals('Submit for Review'),
        );
      });

      test('returns "Awaiting Review" for pendingReview', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.pendingReview),
          equals('Awaiting Review'),
        );
      });

      test('returns "View Report" for approved', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.approved),
          equals('View Report'),
        );
      });

      test('returns "Revise Survey" for rejected', () {
        expect(
          engine.primaryActionLabel(SurveyStatus.rejected),
          equals('Revise Survey'),
        );
      });
    });

    group('isPrimaryActionEnabled', () {
      test('returns true for draft', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.draft), isTrue);
      });

      test('returns true for inProgress', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.inProgress), isTrue);
      });

      test('returns true for paused', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.paused), isTrue);
      });

      test('returns true for completed', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.completed), isTrue);
      });

      test('returns false for pendingReview', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.pendingReview), isFalse);
      });

      test('returns true for approved', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.approved), isTrue);
      });

      test('returns true for rejected', () {
        expect(engine.isPrimaryActionEnabled(SurveyStatus.rejected), isTrue);
      });
    });

    group('shouldNavigateToSection', () {
      test('returns true for draft', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.draft), isTrue);
      });

      test('returns true for inProgress', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.inProgress), isTrue);
      });

      test('returns true for paused', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.paused), isTrue);
      });

      test('returns false for completed', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.completed), isFalse);
      });

      test('returns false for pendingReview', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.pendingReview), isFalse);
      });

      test('returns false for approved', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.approved), isFalse);
      });

      test('returns true for rejected', () {
        expect(engine.shouldNavigateToSection(SurveyStatus.rejected), isTrue);
      });
    });

    group('getAllowedTransitions', () {
      test('returns correct transitions for draft', () {
        final transitions = engine.getAllowedTransitions(SurveyStatus.draft);
        expect(transitions, contains(SurveyStatus.inProgress));
        expect(transitions.length, equals(1));
      });

      test('returns correct transitions for inProgress', () {
        final transitions = engine.getAllowedTransitions(SurveyStatus.inProgress);
        expect(transitions, contains(SurveyStatus.paused));
        expect(transitions, contains(SurveyStatus.completed));
        expect(transitions.length, equals(2));
      });

      test('returns empty set for approved', () {
        final transitions = engine.getAllowedTransitions(SurveyStatus.approved);
        expect(transitions, isEmpty);
      });
    });
  });

  group('SmartResumeService', () {
    const service = SmartResumeService.instance;

    List<SurveySection> createSections({
      required List<bool> completedStates,
    }) => completedStates.asMap().entries.map((entry) => SurveySection(
          id: 'section-${entry.key + 1}',
          surveyId: 'survey-1',
          sectionType: SectionType.values[entry.key % SectionType.values.length],
          title: 'Section ${entry.key + 1}',
          order: entry.key + 1,
          isCompleted: entry.value,
        ),).toList();

    group('getResumeTargetSection', () {
      test('returns null for empty sections', () {
        expect(service.getResumeTargetSection([]), isNull);
      });

      test('returns first incomplete section', () {
        final sections = createSections(completedStates: [true, false, false]);
        final target = service.getResumeTargetSection(sections);

        expect(target, isNotNull);
        expect(target!.id, equals('section-2'));
      });

      test('returns first section when all incomplete', () {
        final sections = createSections(completedStates: [false, false, false]);
        final target = service.getResumeTargetSection(sections);

        expect(target, isNotNull);
        expect(target!.id, equals('section-1'));
      });

      test('returns last section when all complete', () {
        final sections = createSections(completedStates: [true, true, true]);
        final target = service.getResumeTargetSection(sections);

        expect(target, isNotNull);
        expect(target!.id, equals('section-3'));
      });

      test('handles out-of-order sections correctly', () {
        final sections = [
          const SurveySection(
            id: 'section-3',
            surveyId: 'survey-1',
            sectionType: SectionType.exterior,
            title: 'Exterior',
            order: 3,
          ),
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
        ];

        final target = service.getResumeTargetSection(sections);

        expect(target, isNotNull);
        expect(target!.id, equals('section-2'));
      });
    });

    group('getResumeTargetSectionId', () {
      test('returns null for empty sections', () {
        expect(service.getResumeTargetSectionId([]), isNull);
      });

      test('returns correct ID', () {
        final sections = createSections(completedStates: [true, false, false]);
        expect(service.getResumeTargetSectionId(sections), equals('section-2'));
      });
    });

    group('getResumeTargetSectionName', () {
      test('returns null for empty sections', () {
        expect(service.getResumeTargetSectionName([]), isNull);
      });

      test('returns correct name', () {
        final sections = createSections(completedStates: [true, false, false]);
        expect(service.getResumeTargetSectionName(sections), equals('Section 2'));
      });
    });

    group('getResumeContext', () {
      test('returns empty context for no sections', () {
        final context = service.getResumeContext([]);

        expect(context.targetSection, isNull);
        expect(context.completedCount, equals(0));
        expect(context.totalCount, equals(0));
        expect(context.isAllComplete, isFalse);
        expect(context.progressFraction, equals(0.0));
        expect(context.progressPercent, equals(0));
      });

      test('calculates progress correctly', () {
        final sections = createSections(completedStates: [true, true, false, false]);
        final context = service.getResumeContext(sections);

        expect(context.completedCount, equals(2));
        expect(context.totalCount, equals(4));
        expect(context.isAllComplete, isFalse);
        expect(context.progressFraction, equals(0.5));
        expect(context.progressPercent, equals(50));
      });

      test('identifies all complete correctly', () {
        final sections = createSections(completedStates: [true, true, true]);
        final context = service.getResumeContext(sections);

        expect(context.isAllComplete, isTrue);
        expect(context.progressPercent, equals(100));
      });

      test('targets first incomplete section', () {
        final sections = createSections(completedStates: [true, false, false]);
        final context = service.getResumeContext(sections);

        expect(context.targetSection, isNotNull);
        expect(context.targetSectionId, equals('section-2'));
        expect(context.targetSectionName, equals('Section 2'));
      });

      test('targets last section when all complete', () {
        final sections = createSections(completedStates: [true, true, true]);
        final context = service.getResumeContext(sections);

        expect(context.targetSectionId, equals('section-3'));
      });
    });
  });

  group('ResumeContext', () {
    test('progressFraction handles zero total', () {
      const context = ResumeContext(
        targetSection: null,
        completedCount: 0,
        totalCount: 0,
        isAllComplete: false,
      );

      expect(context.progressFraction, equals(0.0));
      expect(context.progressPercent, equals(0));
    });

    test('progressPercent rounds correctly', () {
      const context = ResumeContext(
        targetSection: null,
        completedCount: 1,
        totalCount: 3,
        isAllComplete: false,
      );

      expect(context.progressPercent, equals(33));
    });
  });
}
