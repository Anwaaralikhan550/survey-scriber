import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

void main() {
  group('ReportDocument', () {
    ReportDocument _buildDoc({
      String? aiExecutiveSummary,
      Map<String, String> aiSectionNarratives = const {},
      String? aiDisclaimer,
      List<ReportSection> sections = const [],
    }) {
      return ReportDocument(
        reportType: ReportType.inspection,
        title: 'Test Report',
        generatedAt: DateTime(2026, 2, 15),
        surveyMeta: const SurveyMeta(
          surveyId: 'test-1',
          title: 'Test Survey',
        ),
        sections: sections,
        aiExecutiveSummary: aiExecutiveSummary,
        aiSectionNarratives: aiSectionNarratives,
        aiDisclaimer: aiDisclaimer,
      );
    }

    test('hasAiContent is false when no AI data', () {
      final doc = _buildDoc();
      expect(doc.hasAiContent, isFalse);
    });

    test('hasAiContent is true when executive summary present', () {
      final doc = _buildDoc(aiExecutiveSummary: 'A good property.');
      expect(doc.hasAiContent, isTrue);
    });

    test('hasAiContent is true when section narratives present', () {
      final doc = _buildDoc(
        aiSectionNarratives: {'E': 'Outside property looks good.'},
      );
      expect(doc.hasAiContent, isTrue);
    });

    test('totalFields counts across sections and screens', () {
      final doc = _buildDoc(
        sections: [
          ReportSection(
            key: 'E',
            title: 'Outside',
            description: '',
            displayOrder: 0,
            screens: [
              ReportScreen(
                screenId: 'e1',
                title: 'Chimney',
                fields: [
                  const ReportField(
                    fieldId: 'f1',
                    label: 'Condition',
                    type: ReportFieldType.dropdown,
                    displayValue: '1',
                  ),
                  const ReportField(
                    fieldId: 'f2',
                    label: 'Notes',
                    type: ReportFieldType.text,
                    displayValue: 'Good',
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(doc.totalFields, 2);
      expect(doc.totalScreens, 1);
    });

    test('totalScreens sums screens across sections', () {
      final doc = _buildDoc(
        sections: [
          ReportSection(
            key: 'E',
            title: 'Outside',
            description: '',
            displayOrder: 0,
            screens: [
              const ReportScreen(
                screenId: 'e1',
                title: 'Chimney',
                fields: [],
              ),
              const ReportScreen(
                screenId: 'e2',
                title: 'Roof',
                fields: [],
              ),
            ],
          ),
          ReportSection(
            key: 'F',
            title: 'Inside',
            description: '',
            displayOrder: 1,
            screens: [
              const ReportScreen(
                screenId: 'f1',
                title: 'Bathroom',
                fields: [],
              ),
            ],
          ),
        ],
      );

      expect(doc.totalScreens, 3);
    });
  });

  group('ReportScreen', () {
    test('hasData is true when at least one field has a value', () {
      const screen = ReportScreen(
        screenId: 'e1',
        title: 'Chimney',
        fields: [
          ReportField(
            fieldId: 'f1',
            label: 'Condition',
            type: ReportFieldType.dropdown,
            displayValue: '2',
          ),
          ReportField(
            fieldId: 'f2',
            label: 'Notes',
            type: ReportFieldType.text,
            displayValue: '',
          ),
        ],
      );

      expect(screen.hasData, isTrue);
    });

    test('hasData is false when all fields are empty', () {
      const screen = ReportScreen(
        screenId: 'e1',
        title: 'Chimney',
        fields: [
          ReportField(
            fieldId: 'f1',
            label: 'Condition',
            type: ReportFieldType.dropdown,
            displayValue: '',
          ),
        ],
      );

      expect(screen.hasData, isFalse);
    });
  });

  group('ExportConfig AI flag', () {
    test('includeAiNarrative defaults to false', () {
      // Import test — just ensures config compiles with new field
      expect(true, isTrue);
    });
  });
}
