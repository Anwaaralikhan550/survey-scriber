import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E6 Outside doors: fixed PDF prose the ledger tool mistakes for option lists.
void main() {
  final flat = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .values
      .map((v) => v.toString().replaceAll(RegExp(r'\s+'), ' '))
      .join('\n');

  for (final s in const [
    'Moving parts, hinges, locks, and drainage channels should be cleaned, lubricated, and adjusted where necessary.',
    'Moving parts, hinges, locks, handles, and seals should be cleaned, lubricated, and adjusted where necessary.',
  ]) {
    test('bank holds: ${s.substring(0, 40)}', () => expect(flat, contains(s)));
  }
}
