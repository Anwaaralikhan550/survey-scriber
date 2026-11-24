// Client edit list, 23 Nov 2026: Valuation Weather has the Inspection list.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/legacy_answer_migration.dart';
import 'package:survey_scriber/features/property_valuation/data/valuation_repository.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

void main() {
  final engine = ValuationPhraseEngine();

  Map<String, dynamic>? findNode(dynamic n, String id) {
    if (n is Map<String, dynamic>) {
      if (n['id'] == id) return n;
      for (final v in n.values) {
        final r = findNode(v, id);
        if (r != null) return r;
      }
    } else if (n is List) {
      for (final v in n) {
        final r = findNode(v, id);
        if (r != null) return r;
      }
    }
    return null;
  }

  final valuation = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync());
  final inspection = jsonDecode(File('assets/property_inspection/inspection_tree.json').readAsStringSync());
  final inspectionWeather = [
    for (final f in findNode(inspection, 'activity_property_weather')!['fields'] as List)
      if ((f as Map)['id'] == 'android_material_design_spinner') ...(f['options'] as List).cast<String>(),
  ];

  group('3 Valuation Weather: the full Inspection list', () {
    test('the options are exactly the Inspection options, in the same order', () {
      final f = findNode(valuation, 'actv_weather')!;
      expect(inspectionWeather, ['Dry', 'Wet', 'Overcast', 'Sunny', 'Cold', 'Windy', 'Rainy', 'Snowing']);
      expect((f['options'] as List).cast<String>(), inspectionWeather);
    });
    test('every option prints in the weather sentence', () {
      for (final w in inspectionWeather) {
        final out = engine.buildPhrases('general_details', {'actv_weather': w}).join(' ');
        expect(out, contains('At the time of my inspection, the weather conditions were ${w.toLowerCase()}. It should be noted that certain defects may be more or less apparent'), reason: w);
      }
    });
    test('an older valuation that chose Snow now reads Snowing', () {
      final m = migrateLegacyAnswers('general_details', {'actv_weather': 'Snow'});
      expect(m['actv_weather'], 'Snowing');
      expect(engine.buildPhrases('general_details', m).join(' '), contains('weather conditions were snowing.'));
      expect(migrateLegacyAnswers('general_details', {'actv_weather': 'Dry'})['actv_weather'], 'Dry');
    });
    test('the bundled valuation tree version moved on so phones take the new list', () {
      expect(ValuationRepository.bundledVersion, 8);
    });
  });
}
