import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/domain/entities/survey_section.dart';

void main() {
  group('SurveySection', () {
    test('creates section with required fields', () {
      const section = SurveySection(
        id: 'section-1',
        surveyId: 'survey-1',
        sectionType: SectionType.aboutProperty,
        title: 'About Property',
        order: 1,
      );

      expect(section.id, equals('section-1'));
      expect(section.surveyId, equals('survey-1'));
      expect(section.sectionType, equals(SectionType.aboutProperty));
      expect(section.title, equals('About Property'));
      expect(section.order, equals(1));
      expect(section.isCompleted, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      const original = SurveySection(
        id: 'section-1',
        surveyId: 'survey-1',
        sectionType: SectionType.construction,
        title: 'Construction',
        order: 2,
      );

      final updated = original.copyWith(isCompleted: true);

      expect(updated.id, equals(original.id));
      expect(updated.isCompleted, isTrue);
      expect(updated.sectionType, equals(original.sectionType));
    });
  });

  group('SectionType', () {
    test('contains all expected section types', () {
      // 20 total: 13 original + 4 inspection types + 3 valuation types
      expect(SectionType.values.length, equals(20));
      // New inspection section types
      expect(SectionType.values, contains(SectionType.aboutInspection));
      expect(SectionType.values, contains(SectionType.externalItems));
      expect(SectionType.values, contains(SectionType.internalItems));
      expect(SectionType.values, contains(SectionType.issuesAndRisks));
      // New valuation section types
      expect(SectionType.values, contains(SectionType.aboutValuation));
      expect(SectionType.values, contains(SectionType.propertySummary));
      expect(SectionType.values, contains(SectionType.adjustments));
      // Original section types
      expect(SectionType.values, contains(SectionType.aboutProperty));
      expect(SectionType.values, contains(SectionType.construction));
      expect(SectionType.values, contains(SectionType.exterior));
      expect(SectionType.values, contains(SectionType.interior));
      expect(SectionType.values, contains(SectionType.rooms));
      expect(SectionType.values, contains(SectionType.services));
      expect(SectionType.values, contains(SectionType.photos));
      expect(SectionType.values, contains(SectionType.notes));
      expect(SectionType.values, contains(SectionType.signature));
      expect(SectionType.values, contains(SectionType.marketAnalysis));
      expect(SectionType.values, contains(SectionType.comparables));
      expect(SectionType.values, contains(SectionType.valuation));
      expect(SectionType.values, contains(SectionType.summary));
    });
  });

  group('SectionTemplates', () {
    test('getInspectionSections returns correct number of sections', () {
      final templates = SectionTemplates.getInspectionSections();

      // Updated: 11 sections with new inspection sections
      expect(templates.length, equals(11));
      expect(templates.first.$1, equals(SectionType.aboutInspection));
      expect(templates.last.$1, equals(SectionType.signature));
    });

    test('getInspectionSections returns correct titles', () {
      final templates = SectionTemplates.getInspectionSections();

      expect(templates.first.$2, equals('About This Inspection'));
      expect(templates.last.$2, equals('Sign Off'));
    });

    test('getInspectionSections includes new inspection sections', () {
      final templates = SectionTemplates.getInspectionSections();
      final sectionTypes = templates.map((t) => t.$1).toList();

      // New inspection-specific sections
      expect(sectionTypes, contains(SectionType.aboutInspection));
      expect(sectionTypes, contains(SectionType.externalItems));
      expect(sectionTypes, contains(SectionType.internalItems));
      expect(sectionTypes, contains(SectionType.issuesAndRisks));
    });

    test('getLegacyInspectionSections returns backward-compatible sections', () {
      final templates = SectionTemplates.getLegacyInspectionSections();

      expect(templates.length, equals(9));
      expect(templates.first.$1, equals(SectionType.aboutProperty));
      expect(templates.last.$1, equals(SectionType.signature));
    });

    test('getValuationSections returns correct number of sections', () {
      final templates = SectionTemplates.getValuationSections();

      // Enhanced valuation has 9 sections
      expect(templates.length, equals(9));
      expect(templates.first.$1, equals(SectionType.aboutValuation));
      expect(templates.last.$1, equals(SectionType.signature));
    });

    test('getValuationSections includes valuation-specific sections', () {
      final templates = SectionTemplates.getValuationSections();
      final sectionTypes = templates.map((t) => t.$1).toList();

      // New valuation-specific sections
      expect(sectionTypes, contains(SectionType.aboutValuation));
      expect(sectionTypes, contains(SectionType.propertySummary));
      expect(sectionTypes, contains(SectionType.adjustments));
      // Existing sections
      expect(sectionTypes, contains(SectionType.marketAnalysis));
      expect(sectionTypes, contains(SectionType.comparables));
      expect(sectionTypes, contains(SectionType.valuation));
      expect(sectionTypes, contains(SectionType.summary));
    });

    test('getLegacyValuationSections returns backward-compatible sections', () {
      final templates = SectionTemplates.getLegacyValuationSections();

      expect(templates.length, equals(7));
      expect(templates.first.$1, equals(SectionType.aboutProperty));
      expect(templates.last.$1, equals(SectionType.signature));
    });

    test('inspection and valuation have different section counts', () {
      final inspectionTemplates = SectionTemplates.getInspectionSections();
      final valuationTemplates = SectionTemplates.getValuationSections();

      expect(inspectionTemplates.length, isNot(equals(valuationTemplates.length)));
      expect(inspectionTemplates.length, equals(11));
      expect(valuationTemplates.length, equals(9));
    });
  });
}
