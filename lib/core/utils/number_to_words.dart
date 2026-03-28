/// Converts an integer amount to English words.
///
/// Example: `numberToWords(123456)` → `"one hundred and twenty three thousand four hundred and fifty six"`
String numberToWords(int number) {
  if (number == 0) return 'zero';

  final isNegative = number < 0;
  var n = number.abs();

  const ones = [
    '',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];

  const tens = [
    '',
    '',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety',
  ];

  const scales = ['', 'thousand', 'million', 'billion', 'trillion'];

  String twoDigits(int v) {
    if (v < 20) return ones[v];
    final t = v ~/ 10;
    final o = v % 10;
    return o == 0 ? tens[t] : '${tens[t]} ${ones[o]}';
  }

  String threeDigits(int v) {
    final h = v ~/ 100;
    final remainder = v % 100;
    if (h == 0) return twoDigits(remainder);
    if (remainder == 0) return '${ones[h]} hundred';
    return '${ones[h]} hundred and ${twoDigits(remainder)}';
  }

  final groups = <String>[];
  var scaleIndex = 0;

  while (n > 0) {
    final chunk = n % 1000;
    if (chunk != 0) {
      final words = threeDigits(chunk);
      // Guard against numbers exceeding known scales
      final scale = scaleIndex < scales.length ? scales[scaleIndex] : '';
      groups.add(scale.isEmpty ? words : '$words $scale');
    }
    n ~/= 1000;
    scaleIndex++;
  }

  final result = groups.reversed.join(' ');
  return isNegative ? 'minus $result' : result;
}

/// Formats a numeric string as "£123,456 (one hundred and twenty three
/// thousand four hundred and fifty six pounds)".
String formatPriceWithWords(String amount) {
  final cleaned = amount.replaceAll(RegExp(r'[£,\s]'), '');
  final parsed = int.tryParse(cleaned);
  if (parsed == null) return '£$amount';

  // Format with commas.
  final formatted = _addCommas(parsed.abs().toString());
  final prefix = parsed < 0 ? '-' : '';
  final words = numberToWords(parsed);

  return '£$prefix$formatted ($words pounds)';
}

String formatPriceAsWordsOnly(String amount) {
  final cleaned = amount.replaceAll(RegExp(r'[£,\s]'), '');
  if (cleaned.isEmpty) return amount.trim();

  final parsed = int.tryParse(cleaned) ?? double.tryParse(cleaned)?.round();
  if (parsed == null) return amount.trim();

  return '${numberToWords(parsed)} pounds';
}

String _addCommas(String digits) {
  final buffer = StringBuffer();
  var count = 0;
  for (var i = digits.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
    count++;
  }
  return buffer.toString().split('').reversed.join();
}
