import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/reinspection/domain/entities/comparison_result.dart';
import 'package:survey_scriber/features/reinspection/domain/services/survey_comparison_service.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  late SurveyComparisonService comparisonService;

  setUp(() {
    comparisonService = const SurveyComparisonService();
  });

  group('SurveyComparisonService', () {
    group('compareSurveys', () {
      test('returns unchanged when surveys are identical', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
          _createSection('s2', '1', SectionType.construction, 1),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
          _createSection('s4', '2', SectionType.construction, 1),
        ];

        final previousAnswers = {
          's1': {'propertyType': 'Residential', 'bedrooms': '3'},
          's2': {'roofType': 'Tile', 'condition': 'Good'},
        };
        final currentAnswers = {
          's3': {'propertyType': 'Residential', 'bedrooms': '3'},
          's4': {'roofType': 'Tile', 'condition': 'Good'},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: previousAnswers,
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        expect(result.sectionDiffs.length, 2);
        expect(
          result.sectionDiffs.every((d) => d.changeType == ChangeType.unchanged),
          isTrue,
        );
        expect(result.hasAnyChanges, isFalse);
      });

      test('detects modified answer values', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
        ];

        final previousAnswers = {
          's1': {'propertyType': 'Residential', 'bedrooms': '3'},
        };
        final currentAnswers = {
          's3': {'propertyType': 'Residential', 'bedrooms': '4'},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: previousAnswers,
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        expect(result.sectionDiffs.length, 1);
        final sectionDiff = result.sectionDiffs.first;
        expect(sectionDiff.changeType, ChangeType.modified);

        final bedroomsDiff = sectionDiff.answerDiffs.firstWhere(
          (d) => d.fieldKey == 'bedrooms',
        );
        expect(bedroomsDiff.changeType, ChangeType.modified);
        expect(bedroomsDiff.previousValue, '3');
        expect(bedroomsDiff.currentValue, '4');

        expect(result.hasAnyChanges, isTrue);
        expect(result.totalAnswerChanges, 1);
      });

      test('detects added section', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
          _createSection('s4', '2', SectionType.construction, 1),
        ];

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: {},
          currentAnswers: {},
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        expect(result.sectionDiffs.length, 2);

        final addedSection = result.sectionDiffs.firstWhere(
          (d) => d.displaySection?.sectionType == SectionType.construction,
        );
        expect(addedSection.changeType, ChangeType.added);
        expect(result.addedSections.length, 1);
      });

      test('detects removed section', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
          _createSection('s2', '1', SectionType.construction, 1),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
        ];

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: {},
          currentAnswers: {},
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        expect(result.sectionDiffs.length, 2);

        final removedSection = result.sectionDiffs.firstWhere(
          (d) => d.displaySection?.sectionType == SectionType.construction,
        );
        expect(removedSection.changeType, ChangeType.removed);
        expect(result.removedSections.length, 1);
      });

      test('detects added answer field', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
        ];

        final previousAnswers = {
          's1': {'propertyType': 'Residential'},
        };
        final currentAnswers = {
          's3': {'propertyType': 'Residential', 'newField': 'New Value'},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: previousAnswers,
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        final sectionDiff = result.sectionDiffs.first;
        final addedField = sectionDiff.answerDiffs.firstWhere(
          (d) => d.fieldKey == 'newField',
        );
        expect(addedField.changeType, ChangeType.added);
        expect(addedField.currentValue, 'New Value');
        expect(addedField.previousValue, isNull);
      });

      test('detects removed answer field', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
        ];

        final previousAnswers = {
          's1': {'propertyType': 'Residential', 'oldField': 'Old Value'},
        };
        final currentAnswers = {
          's3': {'propertyType': 'Residential'},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: previousAnswers,
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        final sectionDiff = result.sectionDiffs.first;
        final removedField = sectionDiff.answerDiffs.firstWhere(
          (d) => d.fieldKey == 'oldField',
        );
        expect(removedField.changeType, ChangeType.removed);
        expect(removedField.previousValue, 'Old Value');
        expect(removedField.currentValue, isNull);
      });

      test('handles empty previous survey (edge case)', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
        ];
        final currentAnswers = {
          's3': {'propertyType': 'Residential'},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: [],
          currentSections: currentSections,
          previousAnswers: {},
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        expect(result.sectionDiffs.length, 1);
        expect(result.sectionDiffs.first.changeType, ChangeType.added);
      });

      test('handles whitespace differences correctly', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
        ];

        // Same value with trailing/leading whitespace
        final previousAnswers = {
          's1': {'field1': 'Value'},
        };
        final currentAnswers = {
          's3': {'field1': '  Value  '},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: previousAnswers,
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        // Should be unchanged because whitespace is normalized
        final sectionDiff = result.sectionDiffs.first;
        final fieldDiff = sectionDiff.answerDiffs.first;
        expect(fieldDiff.changeType, ChangeType.unchanged);
      });
    });

    group('ComparisonResult', () {
      test('summary calculates correct totals', () {
        final previousSurvey = _createSurvey('1', 'Test Survey');
        final currentSurvey = _createSurvey('2', 'Test Survey Re-Inspection');

        final previousSections = [
          _createSection('s1', '1', SectionType.aboutProperty, 0),
          _createSection('s2', '1', SectionType.construction, 1),
        ];
        final currentSections = [
          _createSection('s3', '2', SectionType.aboutProperty, 0),
          _createSection('s4', '2', SectionType.construction, 1),
        ];

        final previousAnswers = {
          's1': {'field1': 'A', 'field2': 'B'},
          's2': {'field3': 'C'},
        };
        final currentAnswers = {
          's3': {'field1': 'A Modified', 'field2': 'B'},
          's4': {'field3': 'C Modified'},
        };

        final result = comparisonService.compareSurveys(
          previousSurvey: previousSurvey,
          currentSurvey: currentSurvey,
          previousSections: previousSections,
          currentSections: currentSections,
          previousAnswers: previousAnswers,
          currentAnswers: currentAnswers,
          previousMedia: {},
          currentMedia: {},
          previousSignatures: [],
          currentSignatures: [],
        );

        expect(result.summary.totalSections, 2);
        expect(result.summary.sectionsWithChanges, 2);
        expect(result.summary.totalAnswerChanges, 2);
        expect(result.summary.totalChanges, 2);
      });
    });

    group('AnswerDiff', () {
      test('fieldLabel formats camelCase correctly', () {
        const diff = AnswerDiff(
          fieldKey: 'propertyType',
          changeType: ChangeType.unchanged,
        );
        expect(diff.fieldLabel, 'Property Type');
      });

      test('fieldLabel formats snake_case correctly', () {
        const diff = AnswerDiff(
          fieldKey: 'property_type',
          changeType: ChangeType.unchanged,
        );
        expect(diff.fieldLabel, 'Property Type');
      });
    });

    group('ChangeType', () {
      test('hasChange returns correct values', () {
        expect(ChangeType.added.hasChange, isTrue);
        expect(ChangeType.modified.hasChange, isTrue);
        expect(ChangeType.removed.hasChange, isTrue);
        expect(ChangeType.unchanged.hasChange, isFalse);
      });

      test('label returns correct strings', () {
        expect(ChangeType.added.label, 'Added');
        expect(ChangeType.modified.label, 'Modified');
        expect(ChangeType.removed.label, 'Removed');
        expect(ChangeType.unchanged.label, 'Unchanged');
      });
    });
  });
}

// Helper functions to create test data

Survey _createSurvey(String id, String title) => Survey(
    id: id,
    title: title,
    type: SurveyType.inspection,
    status: SurveyStatus.completed,
    createdAt: DateTime.now(),
  );

SurveySection _createSection(
  String id,
  String surveyId,
  SectionType type,
  int order,
) => SurveySection(
    id: id,
    surveyId: surveyId,
    sectionType: type,
    title: type.name,
    order: order,
  );
