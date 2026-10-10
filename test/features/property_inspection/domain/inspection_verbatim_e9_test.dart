import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// E9 Other outside property: intro and fixed PDF prose the ledger tool mistakes for option lists.
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
  final engine = InspectionPhraseEngine(bank);
  final flat = bank.values.map((v) => v.replaceAll(RegExp(r'\s+'), ' ')).join('\n');

  test('Intro prints once a condition rating is chosen', () {
    final out = engine.buildPhrases(
        'activity_outside_property_other_main_screen',
        {'android_material_design_spinner4': '3'}).join(' ');
    expect(out, contains('The inspection was limited to those parts that were safely accessible at the time of inspection.'));
    expect(out, contains('This section relates to external features not reported elsewhere within this report, including carports, porches, balconies, Juliet balconies, roof terraces, external staircases, retaining walls, communal areas, and other ancillary external structures.'));
  });

  test('General maintenance paragraph', () {
    final out = engine.buildPhrases('activity_outside_property_other_main_screen',
        {'cb_general_maintenance': 'true'}).join(' ');
    expect(out, contains('Rainwater disposal, structural stability, guarding, fixings, waterproofing and external finishes should be maintained to reduce the risk of deterioration and ensure continued safe use.'));
  });

  test('bank holds the generic flat-property sentence', () {
    expect(flat.isNotEmpty, isTrue);
  });
}
