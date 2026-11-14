// Client edit list "Survey Scriber Edit Oct 2026 (3).docx" (10 Nov 2026): Valuation.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/option_labels.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

void main() {
  final engine = ValuationPhraseEngine();

  test('C6 Building movement None does not claim movement was noted', () {
    final none = engine.buildPhrases('val_walls_type', {'actv_building_movement': 'None'}).join(' ');
    expect(none, contains('A careful examination was made of all accessible wall surfaces'));
    expect(none, isNot(contains('movement was noted')));
    expect(none, isNot(contains('the movement appears')));
    final found = engine
        .buildPhrases('val_walls_type', {'actv_building_movement': 'Structural Movement'})
        .join(' ');
    expect(found, contains('Evidence of building movement was noted: structural movement.'));
  });

  group('C4 C12 field removals', () {
    final tree = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync())
        as Map<String, dynamic>;
    final fields = {
      for (final s in tree['sections'] as List)
        for (final n in (s as Map)['nodes'] as List)
          (n as Map)['id'] as String: {
            for (final f in (n['fields'] as List? ?? const [])) (f as Map)['id'] as String: f['label'],
          },
    };

    test('C4 Flat Roof has no Roof Ventilation', () {
      expect(fields['val_flat_roof']!.keys, isNot(contains('actv_roof_ventilation_fr')));
      expect(
        engine.buildPhrases('val_flat_roof', {'actv_roof_ventilation_fr': 'Sufficient'}).join(' '),
        isNot(contains('Roof ventilation')),
      );
      // Pitched roof keeps its own ventilation.
      expect(fields['val_pitched_roof']!.keys.any((k) => k.contains('ventilation')), isTrue);
    });

    test('C12 Hot Water: no Full/Part (old ticks replaced by the client lists on 13 Nov)', () {
      final hw = fields['val_hot_water_central_heating']!;
      expect(hw.keys, isNot(contains('cb_full')));
      expect(hw.keys, isNot(contains('cb_part')));
      // 13 Nov 2026: the client's own Heating / Water Heating lists replaced these ticks.
      expect(hw.keys, isNot(contains('cb_none_hw')));
      expect(hw.keys, isNot(contains('cb_solid_hw')));
    });

    test('C12 the remaining answers still print', () {
      expect(
        engine.buildPhrases('val_hot_water_central_heating', {'cb_gas_hw': 'true', 'cb_solid_hw': 'true'}).join(' '),
        contains('fuelled by gas and solid fuel'),
      );
      expect(
        engine.buildPhrases('val_hot_water_central_heating', {'cb_none_hw': 'true'}).join(' '),
        contains('No central heating system is installed'),
      );
    });
  });

  group('A4 "Other" in a dropdown has a text box, and the typed words print', () {
    test('every valuation dropdown with Other has its text box', () {
      final tree = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync())
          as Map<String, dynamic>;
      final missing = <String>[];
      for (final s in tree['sections'] as List) {
        for (final n in (s as Map)['nodes'] as List) {
          final fields = ((n as Map)['fields'] as List? ?? const []).cast<Map>();
          for (final f in fields) {
            final options = (f['options'] as List? ?? const []).map((o) => '$o'.toLowerCase());
            if (f['type'] != 'dropdown' || !options.contains('other')) continue;
            final hasText = fields.any((g) =>
                g['type'] == 'text' && '${g['conditionalOn'] ?? ''}'.startsWith('${f['id']}='));
            if (!hasText) missing.add('${n['id']}/${f['id']}');
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('Valuation reason: typed words print; Other with nothing typed prints nothing', () {
      expect(
        engine.buildPhrases('general_details', {
          'actv_vl_reason': 'Other',
          'actv_vl_reason_other_text': 'probate',
        }).join(' '),
        contains('The purpose of this valuation is for probate.'),
      );
      expect(
        engine.buildPhrases('general_details', {'actv_vl_reason': 'Other'}).join(' '),
        isNot(contains('The purpose of this valuation')),
      );
    });

    test('a renamed Other with nothing typed still counts as Other', () {
      const labels = OptionLabels({
        'general_details': {
          'actv_vl_reason': {'Other': 'Something else'},
        },
      });
      final answers = labels.withWords('general_details', {'actv_vl_reason': 'Other'});
      expect(OptionLabels.named(answers, 'actv_vl_reason'), isFalse);
      expect(
        OptionLabels.named({...answers, 'actv_vl_reason_other_text': 'probate'}, 'actv_vl_reason'),
        isTrue,
      );
    });

    test('a named option is unchanged', () {
      expect(
        engine.buildPhrases('general_details', {'actv_vl_reason': 'Market Value'}).join(' '),
        contains('The purpose of this valuation is for Market Value.'),
      );
    });
  });
}
