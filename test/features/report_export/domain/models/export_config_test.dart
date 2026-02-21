import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';

void main() {
  group('ExportConfig', () {
    test('defaults are sensible', () {
      const config = ExportConfig();

      expect(config.format, ExportFormat.pdf);
      expect(config.includePhotos, isTrue);
      expect(config.includeSignatures, isTrue);
      expect(config.includeEmptyScreens, isFalse);
      expect(config.includePhrases, isTrue);
      expect(config.includeAiNarrative, isFalse);
      expect(config.showPageNumbers, isTrue);
      expect(config.showTableOfContents, isTrue);
      expect(config.companyName, 'SurveyScriber');
    });

    test('copyWith updates includeAiNarrative', () {
      const config = ExportConfig();
      final updated = config.copyWith(includeAiNarrative: true);

      expect(updated.includeAiNarrative, isTrue);
      // Other fields unchanged
      expect(updated.format, ExportFormat.pdf);
      expect(updated.includePhotos, isTrue);
    });

    test('copyWith updates format', () {
      const config = ExportConfig();
      final updated = config.copyWith(
        format: ExportFormat.docx,
      );

      expect(updated.format, ExportFormat.docx);
    });

    test('copyWith preserves all fields when none specified', () {
      const config = ExportConfig(
        format: ExportFormat.docx,
        includePhotos: false,
        includeAiNarrative: true,
        companyName: 'TestCo',
      );

      final copy = config.copyWith();

      expect(copy.format, ExportFormat.docx);
      expect(copy.includePhotos, isFalse);
      expect(copy.includeAiNarrative, isTrue);
      expect(copy.companyName, 'TestCo');
    });
  });

  group('ExportProgress', () {
    test('holds stage, percent, message', () {
      const p = ExportProgress(
        stage: 'AI',
        percent: 0.35,
        message: 'Generating AI narrative...',
      );

      expect(p.stage, 'AI');
      expect(p.percent, 0.35);
      expect(p.message, 'Generating AI narrative...');
    });
  });

  group('ExportResult', () {
    test('defaults uploadedToBackend to false', () {
      const r = ExportResult(
        reportId: 'abc-123',
        surveyId: 'survey-1',
        outputPath: '/path/to/report.pdf',
        format: ExportFormat.pdf,
      );

      expect(r.reportId, 'abc-123');
      expect(r.surveyId, 'survey-1');
      expect(r.uploadedToBackend, isFalse);
      expect(r.remoteUrl, isNull);
      expect(r.warningMessage, isNull);
    });

    test('holds remoteUrl when uploaded', () {
      const r = ExportResult(
        reportId: 'abc-123',
        surveyId: 'survey-1',
        outputPath: '/path/to/report.pdf',
        format: ExportFormat.pdf,
        uploadedToBackend: true,
        remoteUrl: 'surveys/survey-1/report-pdf',
      );

      expect(r.uploadedToBackend, isTrue);
      expect(r.remoteUrl, 'surveys/survey-1/report-pdf');
    });
  });
}
