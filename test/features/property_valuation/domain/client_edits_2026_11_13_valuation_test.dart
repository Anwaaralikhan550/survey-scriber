// Client list "Valuation Feed back November 13" + handwritten note (14 Nov 2026): Valuation module.
// One group per locked step (V1..V16); see docs/VALUATION-NOV13-PROGRESS.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/legacy_answer_migration.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

void main() {
  final engine = ValuationPhraseEngine();
  final tree = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync())
      as Map<String, dynamic>;
  // screen id -> field id -> field json
  final screens = <String, Map<String, Map<String, dynamic>>>{
    for (final s in tree['sections'] as List)
      for (final n in (s as Map)['nodes'] as List)
        (n as Map)['id'] as String: {
          for (final f in (n['fields'] as List? ?? const [])) (f as Map)['id'] as String: f.cast<String, dynamic>(),
        },
  };
  String say(String screen, Map<String, String> answers) => engine.buildPhrases(screen, answers).join(' ');

  group('V1 Estate type removed', () {
    test('the field is gone from General Details', () {
      expect(screens['general_details']!.keys, isNot(contains('actv_estate_type')));
    });
    test('an old Estate type answer prints nothing', () {
      final out = say('general_details', {'actv_estate_type': 'Ex Commercial', 'actv_type': 'House'});
      expect(out, isNot(contains('estate')));
      expect(out, isNot(contains('situated on')));
    });
  });

  group('V2 Property Type + bedrooms', () {
    const types = {
      'Detached house': 'a detached house',
      'Semi-detached house': 'a semi-detached house',
      'End-of-terrace house': 'an end-of-terrace house',
      'Mid-terrace house': 'a mid-terrace house',
      'Purpose-built flat': 'a purpose-built flat',
      'Converted flat': 'a converted flat',
      'Maisonette': 'a maisonette',
      'Bungalow': 'a bungalow',
      'Cottage': 'a cottage',
    };
    test('the dropdown offers exactly the client list, Other last, with a text box and Bedrooms', () {
      final f = screens['general_details']!;
      expect(f['actv_type']!['options'], [...types.keys, 'Other']);
      expect(f['actv_type_other_text']!['conditionalOn'], 'actv_type=Other');
      expect(f['actv_bedrooms']!['options'], ['One', 'Two', 'Three', 'Four', 'Five', 'Six or more']);
      for (final gone in ['actv_sub_type', 'actv_sub_type_other_text', 'actv_flat_type', 'actv_build_type']) {
        expect(f.keys, isNot(contains(gone)));
      }
    });
    test('every type prints its sentence, with and without bedrooms', () {
      types.forEach((value, words) {
        expect(say('general_details', {'actv_type': value}), 'The property is $words.', reason: value);
        expect(say('general_details', {'actv_type': value, 'actv_bedrooms': 'Three'}),
            'The property is $words providing three bedrooms.', reason: value);
      });
    });
    test('every bedroom option', () {
      expect(say('general_details', {'actv_type': 'Bungalow', 'actv_bedrooms': 'One'}), 'The property is a bungalow providing one bedroom.');
      expect(say('general_details', {'actv_type': 'Bungalow', 'actv_bedrooms': 'Two'}), 'The property is a bungalow providing two bedrooms.');
      expect(say('general_details', {'actv_type': 'Bungalow', 'actv_bedrooms': 'Four'}), 'The property is a bungalow providing four bedrooms.');
      expect(say('general_details', {'actv_type': 'Bungalow', 'actv_bedrooms': 'Five'}), 'The property is a bungalow providing five bedrooms.');
      expect(say('general_details', {'actv_type': 'Bungalow', 'actv_bedrooms': 'Six or more'}), 'The property is a bungalow providing six or more bedrooms.');
    });
    test('Other prints the typed words, nothing typed prints nothing', () {
      expect(say('general_details', {'actv_type': 'Other', 'actv_type_other_text': 'chalet', 'actv_bedrooms': 'Two'}),
          'The property is a chalet providing two bedrooms.');
      expect(say('general_details', {'actv_type': 'Other', 'actv_bedrooms': 'Two'}), isNot(contains('The property is')));
    });
    test('flat-only fields show for the three flat types only', () {
      const flat = 'actv_type=Purpose-built flat|actv_type=Converted flat|actv_type=Maisonette';
      for (final id in ['et_no_of_floors_in_block', 'et_no_of_units_in_block', 'et_which_floor_is_flat_on', 'cb_mixed_use', 'cb_lift',
        'et_service_charge', 'cb_satisfactory_access', 'et_other_comments', 'cb_management_satisfactory', 'et_ground_rent']) {
        expect(screens['general_details']![id]!['conditionalOn'], flat, reason: id);
      }
    });
    test('older surveys: what maps moves to the new option, the rest keeps the old wording', () {
      Map<String, String> m(Map<String, String> a) => migrateLegacyAnswers('general_details', a);
      expect(m({'actv_type': 'House', 'actv_sub_type': 'Semi'})['actv_type'], 'Semi-detached house');
      expect(m({'actv_type': 'House', 'actv_sub_type': 'Detached'})['actv_type'], 'Detached house');
      expect(m({'actv_type': 'House', 'actv_sub_type': 'End'})['actv_type'], 'End-of-terrace house');
      expect(m({'actv_type': 'House', 'actv_sub_type': 'Mid'})['actv_type'], 'Mid-terrace house');
      expect(m({'actv_type': 'Flat', 'actv_flat_type': 'Maisonette', 'actv_build_type': 'Conversion'})['actv_type'], 'Maisonette');
      expect(m({'actv_type': 'Flat', 'actv_flat_type': 'Flat', 'actv_build_type': 'Purpose built'})['actv_type'], 'Purpose-built flat');
      expect(m({'actv_type': 'Flat', 'actv_build_type': 'Conversion'})['actv_type'], 'Converted flat');
      expect(m({'actv_type': 'House', 'actv_sub_type': 'Semi'}).containsKey('actv_sub_type'), isFalse);
      // not mappable: untouched
      final plain = {'actv_type': 'House', 'actv_sub_type': 'Terrace'};
      expect(m(plain), plain);
      expect(say('general_details', plain), 'The property is a terraced house.');
      expect(say('general_details', {'actv_type': 'Flat'}), 'The property is a flat.');
      expect(say('general_details', {'actv_type': 'Bungalow', 'actv_sub_type': 'Detached'}), 'The property is a detached bungalow.');
    });
  });
}
