import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';

void main() {
  group('PdfGeneratorService.sanitize', () {
    test('strips HTML <br> tags and replaces with newlines', () {
      expect(
        PdfGeneratorService.sanitize('Line 1<br>Line 2<br />Line 3'),
        'Line 1\nLine 2\nLine 3',
      );
    });

    test('strips other HTML tags', () {
      expect(
        PdfGeneratorService.sanitize('<strong>Bold</strong> and <em>italic</em>'),
        'Bold and italic',
      );
    });

    test('converts literal backslash-r-backslash-n to newlines', () {
      expect(
        PdfGeneratorService.sanitize(r'Hello\r\nWorld'),
        'Hello\nWorld',
      );
    });

    test('converts literal backslash-n to newline', () {
      expect(
        PdfGeneratorService.sanitize(r'Hello\nWorld'),
        'Hello\nWorld',
      );
    });

    test('converts literal backslash-r to newline', () {
      expect(
        PdfGeneratorService.sanitize(r'Hello\rWorld'),
        'Hello\nWorld',
      );
    });

    test('converts literal backslash-t to space', () {
      expect(
        PdfGeneratorService.sanitize(r'Col1\tCol2'),
        'Col1 Col2',
      );
    });

    test('decodes HTML entities', () {
      expect(
        PdfGeneratorService.sanitize('&amp; &lt; &gt; &quot; &#39; &nbsp;'),
        '& < > " \'',
      );
    });

    test('collapses 3+ newlines to double newline', () {
      expect(
        PdfGeneratorService.sanitize('A\n\n\n\nB'),
        'A\n\nB',
      );
    });

    test('trims whitespace from each line', () {
      expect(
        PdfGeneratorService.sanitize('  hello  \n  world  '),
        'hello\nworld',
      );
    });

    test('handles combined HTML + literal escapes from phrase templates', () {
      // This is the pattern that caused "nnnnnn" artifacts in the PDF:
      // phrase_texts.json contains strings like: "text<br />\r\nmore text"
      // where \r\n are literal two-character sequences, not real newlines
      final input = r'The roof is in good condition.<br />\r\n<br />\r\nNo repair needed.';
      final result = PdfGeneratorService.sanitize(input);
      expect(result, 'The roof is in good condition.\n\nNo repair needed.');
    });

    test('returns empty string for empty input', () {
      expect(PdfGeneratorService.sanitize(''), '');
    });

    test('passes through clean text unchanged', () {
      expect(
        PdfGeneratorService.sanitize('Clean text with no issues.'),
        'Clean text with no issues.',
      );
    });
  });
}
