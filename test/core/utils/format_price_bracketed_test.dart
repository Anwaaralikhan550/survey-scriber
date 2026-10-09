import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/utils/number_to_words.dart';

void main() {
  test('formats the overall-opinion price like the PDF sample', () {
    expect(
      formatPriceBracketed('390500'),
      '£390,500.00 [Three Hundred and Ninety Thousand Five Hundred Pounds]',
    );
    expect(formatPriceBracketed('£1,250,000'),
        '£1,250,000.00 [One Million Two Hundred and Fifty Thousand Pounds]');
  });

  test('non-numeric input is left unchanged', () {
    expect(formatPriceBracketed('to be agreed'), 'to be agreed');
  });
}
