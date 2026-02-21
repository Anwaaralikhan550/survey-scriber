import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/report_export/domain/models/generated_report.dart';

void main() {
  GeneratedReport _makeReport({
    String format = 'pdf',
    String moduleType = 'inspection',
    int sizeBytes = 0,
    String? remoteUrl,
    String checksum = '',
  }) {
    return GeneratedReport(
      id: 'report-1',
      surveyId: 'survey-1',
      surveyTitle: 'Test Survey',
      filePath: '/tmp/report.pdf',
      fileName: 'report.pdf',
      sizeBytes: sizeBytes,
      generatedAt: DateTime(2026, 2, 15),
      format: format,
      moduleType: moduleType,
      remoteUrl: remoteUrl,
      checksum: checksum,
    );
  }

  group('GeneratedReport', () {
    test('isPdf returns true for pdf format', () {
      expect(_makeReport(format: 'pdf').isPdf, isTrue);
    });

    test('isPdf returns false for docx format', () {
      expect(_makeReport(format: 'docx').isPdf, isFalse);
    });

    group('formattedSize', () {
      test('shows bytes for small files', () {
        expect(_makeReport(sizeBytes: 500).formattedSize, '500 B');
      });

      test('shows KB for kilobyte-range files', () {
        expect(_makeReport(sizeBytes: 2048).formattedSize, '2.0 KB');
      });

      test('shows MB for megabyte-range files', () {
        expect(_makeReport(sizeBytes: 5 * 1024 * 1024).formattedSize, '5.0 MB');
      });

      test('shows fractional KB', () {
        expect(_makeReport(sizeBytes: 1536).formattedSize, '1.5 KB');
      });

      test('shows zero bytes', () {
        expect(_makeReport(sizeBytes: 0).formattedSize, '0 B');
      });
    });

    test('equatable props include format', () {
      final a = _makeReport(format: 'pdf');
      final b = _makeReport(format: 'pdf');
      final c = _makeReport(format: 'docx');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('defaults are correct', () {
      final report = _makeReport();
      expect(report.moduleType, 'inspection');
      expect(report.format, 'pdf');
      expect(report.remoteUrl, isNull);
      expect(report.checksum, '');
    });

    test('remoteUrl can be set', () {
      final report = _makeReport(remoteUrl: 'https://example.com/report.pdf');
      expect(report.remoteUrl, 'https://example.com/report.pdf');
    });
  });
}
