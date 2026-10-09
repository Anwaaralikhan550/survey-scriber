import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E4 Main walls: PDF sentences that look like option lists to the ledger
/// tool but are fixed prose. Each must appear word for word in the bank.
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .values
      .map((v) => v.toString().replaceAll(RegExp(r'\s+'), ' '))
      .join('\n');

  for (final sentence in const [
    'Your legal adviser should also establish whether there is any history of '
        'subsidence, structural movement, underpinning, monitoring, insurance '
        'claims, or structural repairs affecting the property.',
    'This could result in further investigation, remedial works, additional '
        'costs, and disruption.',
    'It is also possible that evidence of movement, including cracks, may be '
        'concealed by floor coverings, decorations, fitted furniture, or other '
        'obstructions.',
  ]) {
    test('bank holds the PDF sentence: ${sentence.substring(0, 40)}', () {
      expect(bank, contains(sentence));
    });
  }
}
