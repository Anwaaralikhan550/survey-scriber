import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  group('Survey', () {
    test('progressPercent calculates correctly when sections exist', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.inProgress,
        createdAt: DateTime.now(),
        totalSections: 10,
        completedSections: 5,
      );

      expect(survey.progressPercent, equals(50));
    });

    test('progressPercent returns 0 when no sections exist', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.inspection,
        status: SurveyStatus.draft,
        createdAt: DateTime.now(),
      );

      expect(survey.progressPercent, equals(0));
    });

    test('progressPercent returns 100 when all sections completed', () {
      final survey = Survey(
        id: 'test-id',
        title: 'Test Survey',
        type: SurveyType.valuation,
        status: SurveyStatus.completed,
        createdAt: DateTime.now(),
        totalSections: 7,
        completedSections: 7,
      );

      expect(survey.progressPercent, equals(100));
    });

    test('copyWith creates new instance with updated values', () {
      final original = Survey(
        id: 'test-id',
        title: 'Original',
        type: SurveyType.inspection,
        status: SurveyStatus.draft,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        title: 'Updated',
        status: SurveyStatus.inProgress,
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated'));
      expect(updated.status, equals(SurveyStatus.inProgress));
      expect(updated.type, equals(original.type));
    });
  });

  group('SurveyStatus', () {
    test('contains all expected statuses', () {
      expect(SurveyStatus.values.length, equals(7));
      expect(SurveyStatus.values, contains(SurveyStatus.draft));
      expect(SurveyStatus.values, contains(SurveyStatus.inProgress));
      expect(SurveyStatus.values, contains(SurveyStatus.paused));
      expect(SurveyStatus.values, contains(SurveyStatus.completed));
      expect(SurveyStatus.values, contains(SurveyStatus.pendingReview));
      expect(SurveyStatus.values, contains(SurveyStatus.approved));
      expect(SurveyStatus.values, contains(SurveyStatus.rejected));
    });
  });

  group('SurveyType', () {
    test('contains all expected types', () {
      expect(SurveyType.values.length, equals(4));
      expect(SurveyType.values, contains(SurveyType.inspection));
      expect(SurveyType.values, contains(SurveyType.valuation));
      expect(SurveyType.values, contains(SurveyType.reinspection));
      expect(SurveyType.values, contains(SurveyType.other));
    });

    test('SNAGGING backend string maps to inspection', () {
      expect(SurveyType.fromBackendString('SNAGGING'), SurveyType.inspection);
    });
  });
}
