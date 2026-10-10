import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E7 Conservatory and porches: fixed PDF prose the ledger tool mistakes for option lists.
void main() {
  final flat = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .values
      .map((v) => v.toString().replaceAll(RegExp(r'\s+'), ' '))
      .join('\n');

  for (final s in const [
    'Glazing, roof coverings, sealants, rainwater goods, and external decorations should be inspected periodically and repaired where necessary to maintain weather resistance and serviceability.',
    'Unstable Structure: Evidence of movement, distortion, or deflection was observed.',
    'Unstable Structure: Evidence of movement, distortion, deflection was observed.',
  ]) {
    test('bank holds: ${s.substring(0, 40)}', () => expect(flat, contains(s)));
  }
}
