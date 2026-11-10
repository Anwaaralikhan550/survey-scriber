// Client edit list "Survey Scriber Edit Oct 2026 (3).docx" (10 Nov 2026): Valuation.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/option_labels.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

void main() {
  final engine = ValuationPhraseEngine();

  test('C2 Road: Adopted + Made prints the existing road sentence', () {
    expect(
      engine.buildPhrases('road', {'cb_adopted': 'true', 'cb_made': 'true'}),
      ['The property fronts onto an adopted highway maintained at public expense and a made-up road.'],
    );
  });

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

    test('Location and warranty use the typed words', () {
      expect(
        engine.buildPhrases('location_amenities', {
          'actv_location': 'Other',
          'actv_location_other_text': 'Coastal',
        }).join(' '),
        contains('within an established coastal area'),
      );
      expect(
        engine.buildPhrases('new_build_property', {
          'actv_warranty': 'Other',
          'actv_warranty_other_text': 'Premier Guarantee',
        }).join(' '),
        contains('benefits from a Premier Guarantee structural warranty'),
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
