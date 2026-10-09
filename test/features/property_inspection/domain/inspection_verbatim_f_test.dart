import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// Section F (inside the property): section intros and fixed PDF prose that the
/// ledger tool mistakes for option lists. One group per section.
void main() {
  final bank = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v.toString()));
  final engine = InspectionPhraseEngine(bank);
  final flat = bank.values.map((v) => v.replaceAll(RegExp(r'\s+'), ' ')).join('\n');

  String intro(String screen) => engine
      .buildPhrases(screen, {'android_material_design_spinner4': '2'})
      .join(' ');

  group('F3 Walls and partitions', () {
    test('intro prints once a condition rating is chosen', () {
      expect(
        intro('activity_inside_property_walls_and_partitions_main_screen'),
        contains('My inspection was limited by fixed furniture, kitchen units, bathroom fittings, large appliances, stored items, tiled finishes, decorative wall coverings, and fitted cupboards, which prevented full inspection of the concealed areas.'),
      );
    });
    test('condensation paragraph sentence', () {
      expect(flat, contains('Condensation is commonly associated with occupancy patterns, heating, insulation, and ventilation.'));
    });
  });
}
