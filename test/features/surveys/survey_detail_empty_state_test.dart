import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/survey_detail_provider.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  group('SurveyType.isInspection getter', () {
    test('level2 is inspection', () {
      expect(SurveyType.inspection.isInspection, isTrue);
    });

    test('level3 is inspection', () {
      expect(SurveyType.inspection.isInspection, isTrue);
    });

    test('SNAGGING backend value maps to inspection', () {
      expect(SurveyType.fromBackendString('SNAGGING').isInspection, isTrue);
    });

    test('reinspection is inspection', () {
      expect(SurveyType.reinspection.isInspection, isTrue);
    });

    test('valuation is NOT inspection', () {
      expect(SurveyType.valuation.isInspection, isFalse);
    });

    test('other is NOT inspection', () {
      expect(SurveyType.other.isInspection, isFalse);
    });
  });

  group('SurveyType.isValuation getter', () {
    test('valuation is valuation', () {
      expect(SurveyType.valuation.isValuation, isTrue);
    });

    test('level2 is NOT valuation', () {
      expect(SurveyType.inspection.isValuation, isFalse);
    });

    test('other is NOT valuation', () {
      expect(SurveyType.other.isValuation, isFalse);
    });
  });

  group('SurveyDetailState empty sections', () {
    test('sections list is empty by default', () {
      const state = SurveyDetailState();
      expect(state.sections, isEmpty);
    });

    test('completedSectionsCount is 0 when sections are empty', () {
      const state = SurveyDetailState();
      expect(state.completedSectionsCount, 0);
    });

    test('progressPercent is 0 when sections are empty', () {
      const state = SurveyDetailState();
      expect(state.progressPercent, 0.0);
    });

    test('sections.isEmpty is true when no sections provided', () {
      final state = SurveyDetailState(
        isLoading: false,
        survey: Survey(
          id: 'test-1',
          title: 'Test Survey',
          type: SurveyType.inspection,
          status: SurveyStatus.draft,
          createdAt: DateTime(2024),
        ),
      );
      // This is the condition used in the UI to show the empty state
      expect(state.sections.isEmpty, isTrue);
    });

    test('sections.isEmpty is false when sections are provided', () {
      final state = SurveyDetailState(
        isLoading: false,
        sections: [
          SurveySection(
            id: 'sec-1',
            surveyId: 'test-1',
            sectionType: SectionType.aboutProperty,
            title: 'About Property',
            order: 0,
            createdAt: DateTime(2024),
          ),
        ],
      );
      expect(state.sections.isEmpty, isFalse);
    });
  });
}
