// Client edit list "Survey Scriber Edit Oct 2026 (3).docx" (10 Nov 2026).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  final phraseTexts = (jsonDecode(
    File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
  ) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v?.toString() ?? ''));
  final engine = InspectionPhraseEngine(phraseTexts);

  Map<String, String> ticks(List<String> ids, [Map<String, String> extra = const {}]) =>
      {for (final i in ids) i: 'true', ...extra};

  group('A ticked choice counts as its gate (Garage, Drainage, Cylinder, G7)', () {
    test('Garage: choices without the section boxes still print', () {
      final out = engine.buildPhrases(
        'activity_grounds_garage',
        ticks(['h1w_cavity_brick', 'h1rt_pitched', 'h1rc_concrete_tiles', 'h1f_concrete']),
      ).join('\n');
      expect(out, contains('Walls: The garage is constructed of cavity brick'));
      expect(out, contains('Roof: The roof is of pitched construction'));
      expect(out, contains('Garage Floor: The garage floor is constructed of concrete'));
    });

    test('Drainage: chamber, soil pipe and repairs print from their choices', () {
      final main = engine.buildPhrases(
        'activity_services_drainage',
        ticks(['g6cf_blockage', 'g6sl_front', 'cb_material_plastic_pipe', 'g6sv_roof_space']),
      ).join('\n');
      expect(main, contains('Inspection Chamber: The inspection chamber cover(s) were lifted'));
      expect(main, contains('Soil and Vent Pipe: The soil and vent pipe is visible at the front'));
      expect(main, contains('Visible/Partially Visible:'));
      final repair = engine.buildPhrases(
        'activity_services_drainage_repair_chamber_cover',
        ticks(['g6cv_broken', 'g6cw_cracked', 'g6gu_partly_blocked']),
      ).join('\n');
      expect(repair, contains('Inspection Chamber Cover: The inspection chamber cover(s) are broken'));
      expect(repair, contains('Inspection Chamber Walls: The inspection chamber walls are cracked'));
      expect(repair, contains('Gullies:'));
    });

    test('Water heating: cylinder location prints without the immersion box', () {
      final out = engine.buildPhrases(
        'activity_services_water_heating_gas_heating',
        ticks(['g5c_airing_cupboard']),
      ).join('\n');
      expect(out, contains('insulated cylinder located in the airing cupboard'));
    });

    test('G7 Common services: services without the Communal box print', () {
      final out = engine.buildPhrases(
        'activity_services_shared_services',
        ticks(['g7s_lifts', 'g7s_cleaning']),
      ).join('\n');
      expect(out, contains('Communal services and installations, including cleaning and lifts'));
    });

    test('nothing ticked still prints nothing', () {
      expect(engine.buildPhrases('activity_grounds_garage', const {}), isEmpty);
      expect(engine.buildPhrases('activity_services_drainage_repair_chamber_cover', const {}), isEmpty);
    });

    test('gate plus choices prints exactly as before (no duplicate)', () {
      final withGate = engine.buildPhrases(
        'activity_grounds_garage',
        ticks(['cb_h1_walls', 'h1w_cavity_brick']),
      );
      final withoutGate = engine.buildPhrases(
        'activity_grounds_garage',
        ticks(['h1w_cavity_brick']),
      );
      expect(withoutGate, withGate);
      expect(withGate.where((p) => p.startsWith('Walls:')).length, 1);
    });
  });
}
