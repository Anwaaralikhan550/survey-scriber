// Client list "Valuation Feed back November 13" + handwritten note (14 Nov 2026): Valuation module.
// One group per locked step (V1..V16); see docs/VALUATION-NOV13-PROGRESS.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/legacy_answer_migration.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_answer_validator.dart';
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

  group('V3 Construction', () {
    const ticks = {
      'cb_c_masonry': 'traditional masonry',
      'cb_c_solid': 'solid wall',
      'cb_c_cavity': 'cavity wall',
      'cb_c_timber': 'timber frame',
      'cb_c_steel': 'steel frame',
      'cb_c_concrete': 'concrete wall',
      'cb_c_precast': 'precast concrete panels',
      'cb_c_system': 'system-built',
    };
    test('the screen offers exactly the client list, in his order, with Other + text box', () {
      final f = screens['general_details']!;
      final ids = f.keys.toList();
      final from = ids.indexOf('cb_c_masonry');
      expect(ids.sublist(from, from + 10),
          [...ticks.keys, 'cb_c_other', 'et_c_other_text']);
      expect([for (final k in ticks.keys) f[k]!['label']], ticks.values.toList());
      expect(f['cb_c_other']!['label'], 'other construction');
      for (final old in ['cb_non_traditional_construction', 'cb_LPS', 'cb_concrete', 'cb_steel', 'cb_timber', 'cb_modular', 'et_system_type']) {
        expect(f.keys, isNot(contains(old)));
      }
    });
    test('each tick on its own prints the client sentence', () {
      ticks.forEach((id, words) {
        expect(say('general_details', {id: 'true'}), 'The property is believed to be constructed using $words.', reason: id);
      });
    });
    test('several ticks are joined in the client order', () {
      expect(say('general_details', {'cb_c_cavity': 'true', 'cb_c_masonry': 'true'}),
          'The property is believed to be constructed using traditional masonry and cavity wall.');
      expect(say('general_details', {for (final k in ticks.keys) k: 'true'}),
          'The property is believed to be constructed using traditional masonry, solid wall, cavity wall, timber frame, steel frame, concrete wall, precast concrete panels and system-built.');
    });
    test('Other prints the typed words, nothing typed prints nothing', () {
      expect(say('general_details', {'cb_c_other': 'true', 'et_c_other_text': 'Stone rubble'}),
          'The property is believed to be constructed using stone rubble.');
      expect(say('general_details', {'cb_c_other': 'true'}), isNot(contains('constructed using')));
      expect(say('general_details', {'cb_c_solid': 'true', 'cb_c_other': 'true', 'et_c_other_text': 'cob'}),
          'The property is believed to be constructed using solid wall and cob.');
    });
    test('Other without text is refused by the validator', () {
      expect(ValuationAnswerValidator.validateScreen('general_details', {'cb_c_other': 'true'}),
          contains('Provide a description when Other construction is selected.'));
      expect(ValuationAnswerValidator.validateScreen('general_details', {'cb_c_other': 'true', 'et_c_other_text': 'cob'}), isEmpty);
    });
    test('surveys saved with the earlier ticks keep their wording', () {
      expect(say('general_details', {'cb_non_traditional_construction': 'true', 'cb_concrete': 'true'}),
          startsWith('The property incorporates non-traditional construction including pre-cast reinforced concrete (PRC) and concrete.'));
    });
  });

  group('V4 Year Built, V5 Extension, V6 Listed Building', () {
    const tail = ' This assessment is based on available information, the apparent age and style of construction, '
        'and a visual inspection only. Unless documentary evidence is available, the stated age should be regarded as an approximation.';
    test('V4 the entered year prints the client sentence', () {
      expect(say('general_details', {'et_age': '1968'}), 'The property is understood to have been built in 1968.$tail');
    });
    test('V4 every period option, and unknown', () {
      final f = screens['general_details']!['actv_year_band']!;
      expect(f['options'], ['Pre-1900', '1900–1929', '1930–1949', '1950–1969', '1970–1989', '1990–2009', '2010 onwards', 'Exact construction date unknown']);
      for (final b in (f['options'] as List).take(7)) {
        expect(say('general_details', {'actv_year_band': b as String}), 'The property is understood to have been built in $b.$tail', reason: b);
      }
      expect(say('general_details', {'actv_year_band': 'Exact construction date unknown'}), 'The exact construction date is unknown.$tail');
    });
    test('V4 a year entered wins over the period', () {
      expect(say('general_details', {'et_age': '1975', 'actv_year_band': 'Pre-1900'}), 'The property is understood to have been built in 1975.$tail');
    });
    test('V5 Extension ticks in the client order, joined', () {
      const ids = {'cb_ext_side': 'side', 'cb_ext_rear': 'rear', 'cb_ext_front': 'front', 'cb_ext_single': 'single-storey', 'cb_ext_two': 'two-storey', 'cb_ext_roof': 'roof', 'cb_ext_loft': 'loft'};
      final f = screens['general_details']!;
      expect([for (final k in ids.keys) f[k]!['label']], ids.values.toList());
      ids.forEach((id, w) => expect(say('general_details', {id: 'true'}), 'The property has been extended to provide $w accommodation.', reason: id));
      expect(say('general_details', {'cb_ext_loft': 'true', 'cb_ext_rear': 'true', 'cb_ext_single': 'true'}),
          'The property has been extended to provide rear, single-storey and loft accommodation.');
    });
    test('V5 the field is labelled Age of Extension (Date of Extension) and prints no extra sentence', () {
      expect(screens['general_details']!['et_age_extension']!['label'], 'Age of Extension (Date of Extension)');
      expect(say('general_details', {'et_age_extension': '1995'}), isEmpty);
    });
    test('V6 Listed Building prints the client sentence only', () {
      expect(say('general_details', {'cb_is_listed_building': 'true'}), 'The property is understood to be a listed building.');
      expect(say('general_details', {}), isEmpty);
    });
  });
}
