import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// Hand tests for E3 Rainwater goods items that are plain checkboxes (no rule).
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
  final engine = InspectionPhraseEngine(bank);

  test('Blocked Gutters prints the PDF paragraph', () {
    final out = engine.buildPhrases(
        'activity_outside_property_rwg_blocked_rwg', {'cb_blocked_rwg': 'true'});
    expect(
      out.join(' '),
      'Blocked Gutters: Vegetation, moss, leaves, or other debris were '
      'observed within sections of the guttering. The gutters should be '
      'cleared as part of routine maintenance to maintain effective '
      'rainwater disposal.',
    );
  });

  test('General Maintenance prints the PDF paragraph', () {
    final out = engine.buildPhrases('activity_outside_property_rwg_about',
        {'actv_condition': 'Good'}).join(' ');
    expect(
      out,
      contains('General Maintenance: Rainwater goods should be inspected and '
          'cleared at regular intervals, particularly during the autumn and '
          'following severe weather. Routine maintenance will assist in '
          'preventing blockages, overflow, water penetration, and premature '
          'deterioration.'),
    );
  });
}
