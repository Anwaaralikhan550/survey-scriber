import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// E8 Other joinery and finishes: intro paragraph and PDF prose the ledger tool mistakes for a list.
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
  final engine = InspectionPhraseEngine(bank);

  test('Inspected paragraph prints once a condition rating is chosen', () {
    final out = engine.buildPhrases(
        'activity_outside_property_other_joinery_and_finishes_main_screen',
        {'actv_condition': '2'}).join(' ');
    expect(out, contains('Inspected: Inspection was carried out from ground level and other reasonably accessible positions.'));
    expect(out, contains('This section relates to external joinery and finishes not covered elsewhere within this report, including fascias, soffits, bargeboards, eaves joinery, verge clips, cladding, decorative timberwork, or other associated external finishes.'));
  });
}
