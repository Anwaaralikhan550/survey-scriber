import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_export/data/services/report_narrative_policy.dart';

void main() {
  group('ReportNarrativePolicy', () {
    test('limits executive summary to 180 words', () {
      final input = List.generate(240, (index) => 'word$index').join(' ');

      final output = ReportNarrativePolicy.conciseExecutiveSummary(input);

      expect(output.split(RegExp(r'\s+')), hasLength(180));
      expect(output, endsWith('...'));
    });

    test('keeps at most three summary paragraphs', () {
      const input =
          'First finding.\n\nSecond finding.\n\nThird finding.\n\nFourth finding.';

      final output = ReportNarrativePolicy.conciseExecutiveSummary(input);

      expect(output, 'First finding.\n\nSecond finding.\n\nThird finding.');
    });

    test('preserves a concise summary', () {
      const input = 'The property requires routine maintenance only.';

      expect(ReportNarrativePolicy.conciseExecutiveSummary(input), input);
    });
  });
}
