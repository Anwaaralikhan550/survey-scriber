import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// E4/E5 section intros and PDF sentences the ledger tool mistakes for option lists.
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
  final engine = InspectionPhraseEngine(bank);
  final flat = bank.values.map((v) => v.replaceAll(RegExp(r'\s+'), ' ')).join('\n');

  test('Windows intro prints once a condition rating is chosen', () {
    final out = engine.buildPhrases(
        'activity_outside_property_windows_main_screen',
        {'android_material_design_spinner4': '2'}).join(' ');
    expect(out, contains('Not every part of the windows was inspected in detail.'));
    expect(out, contains('Windows obscured by curtains, blinds, shutters, furniture, stored items, or fitted security devices could not be fully inspected.'));
    expect(out, contains('Double-glazed units cannot be assessed for thermal performance during a visual inspection.'));
  });

  test('Windows intro is silent without a rating', () {
    expect(
        engine.buildPhrases('activity_outside_property_windows_main_screen', {}),
        isEmpty);
  });

  test('Main walls intro prints once a condition rating is chosen', () {
    final out = engine.buildPhrases(
        'activity_outside_property_main_walls_main_screen',
        {'android_material_design_spinner4': '1'}).join(' ');
    expect(out, contains('The external walls have been inspected visually and by touch from the outside and internally where exposed.'));
  });

  test('bank holds the fixed PDF sentence about moving parts', () {
    expect(
        flat,
        contains('Moving parts, hinges, locks, and drainage channels should be cleaned, lubricated, and adjusted where necessary.'));
  });
}
