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

  group('V7 New Build Property removed', () {
    test('the screen is gone from the tree', () {
      expect(screens.keys, isNot(contains('new_build_property')));
    });
    test('answers saved on it do not block the export', () {
      final all = {
        'new_build_property': {'actv_warranty': 'Other'},
        'general_details': {'actv_type': 'Bungalow'},
      };
      final live = screens.keys.toSet();
      expect(ValuationAnswerValidator.validateSurvey(all, liveScreens: live), isEmpty);
    });
    test('the engine prints nothing for the removed screen', () {
      expect(say('new_build_property', {'et_builder_name': 'Acme', 'actv_work_stage': 'Complete'}), isEmpty);
    });
  });

  group('V8 Accommodation like Inspection, Parking Locations removed', () {
    test('one Accommodation screen whose fields and labels equal the Inspection floor screen', () {
      final insp = jsonDecode(File('assets/property_inspection/inspection_tree.json').readAsStringSync()) as Map<String, dynamic>;
      final ground = [
        for (final sec in insp['sections'] as List)
          for (final n in (sec as Map)['nodes'] as List)
            if ((n as Map)['id'] == 'activity_no_of_rooms__ground') n,
      ].single as Map;
      final inspLabels = [for (final f in ground['fields'] as List) (f as Map)['label']];
      final valLabels = [for (final f in screens['no_of_rooms']!.values) f['label']];
      expect(valLabels, inspLabels);
      expect([for (final f in screens['no_of_rooms']!.values) f['type']],
          [for (final f in ground['fields'] as List) (f as Map)['type']]);
      final node = [
        for (final sec in tree['sections'] as List)
          for (final n in (sec as Map)['nodes'] as List)
            if ((n as Map)['id'] == 'no_of_rooms') n,
      ].single as Map;
      expect(node['title'], 'Accommodation');
      expect(screens.keys.where((k) => k == 'no_of_rooms').length, 1);
    });
    test('Parking Location is gone and prints nothing', () {
      expect(screens['accommodation_summary']!.keys, isNot(contains('actv_parking_location')));
      expect(say('accommodation_summary', {'cb_garage': 'true', 'actv_parking_location': 'Onsite'}),
          isNot(contains('parking provision')));
      expect(say('accommodation_summary', {'cb_garage': 'true'}), 'Off-street parking is provided by way of a garage.');
    });
  });

  group('V9 Location & Amenities and Road removed', () {
    test('both screens are gone from the tree', () {
      expect(screens.keys, isNot(contains('location_amenities')));
      expect(screens.keys, isNot(contains('road')));
    });
    test('answers saved on them print nothing and do not block the export', () {
      expect(say('location_amenities', {'actv_location': 'Town', 'cb_local_amenities': 'true'}), isEmpty);
      expect(say('road', {'cb_adopted': 'true', 'cb_made': 'true'}), isEmpty);
      final all = {
        'road': {'cb_made': 'true', 'cb_unmade': 'true'},
        'location_amenities': {'actv_location': 'Other'},
      };
      expect(ValuationAnswerValidator.validateSurvey(all, liveScreens: screens.keys.toSet()), isEmpty);
    });
  });

  group('V10 Standardised Condition: good, reasonable, fair, poor, very poor', () {
    const five = ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor'];
    final condIds = [
      for (final e in screens.entries)
        for (final f in e.value.entries)
          if (f.value['label'] == 'Condition' && f.value['type'] == 'dropdown') f.key,
    ];
    String screenOf(String field) => screens.entries.firstWhere((e) => e.value.containsKey(field)).key;
    test('all 29 Condition dropdowns carry exactly the client list (Floor one block in V11, Kitchen + Bathroom in V13)', () {
      expect(condIds, hasLength(29));
      for (final id in condIds) {
        expect(screens[screenOf(id)]![id]!['options'], five, reason: id);
      }
    });
    test('the Notes box of each shows for Fair, Poor and Very poor', () {
      for (final id in condIds) {
        final notes = screens[screenOf(id)]!.values.where((f) => (f['conditionalOn'] as String? ?? '').startsWith('$id='));
        expect(notes, hasLength(1), reason: id);
        expect(notes.single['conditionalOn'], '$id=Fair|$id=Poor|$id=Very poor', reason: id);
      }
    });
    test('every screen prints a sentence for every option', () {
      for (final id in condIds) {
        final screen = screenOf(id);
        if (screen == 'val_decorations_ext') continue; // own client sentence, tested in V11
        for (final entry in {
          'Good': 'considered good',
          'Reasonable': 'considered reasonable',
          'Poor': 'considered unsatisfactory and remedial work is necessary',
          'Fair': 'assessed as fair',
          'Very poor': 'assessed as very poor',
        }.entries) {
          expect(say(screen, {id: entry.key}), contains(entry.value), reason: '$screen $id ${entry.key}');
        }
      }
    });
    test('typed notes print for Fair, Poor and Very poor but not for Good or Reasonable', () {
      const id = 'actv_condition_chimney';
      const notesId = 'et_notes_chimney';
      for (final c in ['Fair', 'Poor', 'Very poor']) {
        expect(say('val_chimney_stacks', {id: c, notesId: 'cracked pots'}), contains('Cracked pots'), reason: c);
      }
      for (final c in ['Good', 'Reasonable']) {
        expect(say('val_chimney_stacks', {id: c, notesId: 'cracked pots'}), isNot(contains('Cracked pots')), reason: c);
      }
    });
    test('surveys saved with Satisfactory / Unsatisfactory keep their wording', () {
      expect(say('val_chimney_stacks', {'actv_condition_chimney': 'Satisfactory'}), contains('considered satisfactory'));
      expect(say('val_chimney_stacks', {'actv_condition_chimney': 'Unsatisfactory', 'et_notes_chimney': 'loose'}),
          allOf(contains('considered unsatisfactory and remedial work is necessary'), contains('Loose')));
    });
  });

  group('V11 Outside Property: the client sentences', () {
    List<String> labelsOf(String screen, String from, String to) {
      final f = screens[screen]!;
      final ids = f.keys.toList();
      return [for (final id in ids.sublist(ids.indexOf(from), ids.indexOf(to) + 1)) f[id]!['label'] as String];
    }

    test('Roof: the client list in his order, one sentence per tick', () {
      expect(labelsOf('val_pitched_roof', 'cb_r_clay', 'cb_r_other'), [
        'clay tiles', 'concrete tiles', 'natural slate', 'artificial slate', 'fibre cement slates',
        'metal sheeting', 'mineral felt', 'rubber membrane', 'single-ply membrane', 'other',
      ]);
      const words = {
        'cb_r_clay': 'clay tiles', 'cb_r_concrete': 'concrete tiles', 'cb_r_natural': 'natural slate',
        'cb_r_artificial': 'artificial slate', 'cb_r_fibre': 'fibre cement slates', 'cb_r_metal': 'metal sheeting',
        'cb_r_felt': 'mineral felt', 'cb_r_rubber': 'rubber membrane', 'cb_r_single': 'single-ply membrane',
      };
      words.forEach((id, w) => expect(say('val_pitched_roof', {id: 'true'}), 'The roof covering is formed in $w.', reason: id));
      expect(say('val_pitched_roof', {'cb_r_clay': 'true', 'cb_r_metal': 'true', 'cb_r_other': 'true', 'et_r_other_text': 'Copper'}),
          'The roof covering is formed in clay tiles, metal sheeting and copper.');
      expect(say('val_pitched_roof', {'cb_r_other': 'true'}), isEmpty);
      expect(say('val_pitched_roof', {'cb_r_clay': 'true', 'actv_condition_pitched_roof': 'Reasonable'}),
          startsWith('The roof covering is formed in clay tiles. The pitched roof covering is considered reasonable'));
    });
    test('Roof: surveys saved with the earlier ticks keep their sentence', () {
      expect(say('val_pitched_roof', {'cb_tile': 'true'}), startsWith('The main roof is of pitched construction, covered with tile materials'));
    });

    test('Rainwater Goods', () {
      expect(labelsOf('val_rainwater_goods', 'cb_rw_pvc', 'cb_rw_fittings'), [
        'PVC', 'cast iron', 'aluminium', 'steel', 'concrete', 'asbestos cement', 'other', 'Other (describe)',
        'gutters', 'downpipes', 'hoppers', 'associated fittings',
      ]);
      expect(say('val_rainwater_goods', {'cb_rw_pvc': 'true'}), 'The rainwater goods comprise PVC.');
      expect(say('val_rainwater_goods', {'cb_rw_cast': 'true', 'cb_rw_gutters': 'true', 'cb_rw_down': 'true'}),
          'The rainwater goods comprise cast iron, gutters and downpipes.');
      expect(say('val_rainwater_goods', {'cb_rw_asbestos': 'true', 'cb_rw_fittings': 'true'}),
          'The rainwater goods comprise asbestos cement and associated fittings.');
      expect(say('val_rainwater_goods', {'cb_rw_other': 'true', 'et_rw_other_text': 'Lead', 'cb_rw_hoppers': 'true'}),
          'The rainwater goods comprise hoppers and lead.');
    });

    test('Chimney', () {
      expect(say('val_chimney_stacks', {'cb_ch_brick': 'true'}), 'The property is installed with chimney stack(s) of brick construction.');
      expect(say('val_chimney_stacks', {'cb_ch_stone': 'true', 'cb_ch_rendered': 'true', 'cb_ch_original': 'true'}),
          'The property is installed with chimney stack(s) of stone and rendered masonry construction and the chimney stack(s) appear original.');
      expect(say('val_chimney_stacks', {'cb_ch_other': 'true', 'et_ch_other_text': 'Concrete block', 'cb_ch_rebuilt': 'true'}),
          'The property is installed with chimney stack(s) of concrete block construction and the chimney stack(s) appear rebuilt.');
      expect(say('val_chimney_stacks', {'cb_ch_replaced': 'true'}), 'The chimney stack(s) appear replaced.');
    });

    test('Main Walls', () {
      expect(labelsOf('val_walls_type', 'cb_w_solid', 'cb_w_other'),
          ['solid brick', 'cavity brick', 'stone', 'timber frame', 'steel frame', 'rendered masonry', 'other construction']);
      expect(say('val_walls_type', {'cb_w_cavity': 'true'}), 'External walls: The external walls are constructed of cavity brick.');
      expect(say('val_walls_type', {'cb_w_solid': 'true', 'cb_w_rendered': 'true', 'cb_w_other': 'true', 'et_w_other_text': 'cob'}),
          'External walls: The external walls are constructed of solid brick, rendered masonry and cob.');
    });

    test('Windows', () {
      expect(labelsOf('val_external_joinery', 'cb_wn_replacement', 'cb_wn_other'), [
        'replacement', 'original', 'old', 'PVCu', 'timber', 'old style timber sash', 'modern PVC sash',
        'modern timber sash', 'aluminium', 'composite', 'other framed units',
      ]);
      expect(say('val_external_joinery', {'cb_wn_pvcu': 'true'}), 'The windows are formed of PVCu.');
      expect(say('val_external_joinery', {'cb_wn_replacement': 'true', 'cb_wn_pvcu': 'true', 'cb_wn_timber': 'true'}),
          'The windows are formed of replacement PVCu and timber.');
      expect(say('val_external_joinery', {'cb_wn_composite': 'true', 'cb_wn_other': 'true', 'et_wn_other_text': 'steel'}),
          'The windows are formed of composite and steel.');
    });

    test('External Decorations/finishes', () {
      for (final c in ['Good', 'Reasonable', 'Fair', 'Poor', 'Very poor']) {
        expect(say('val_decorations_ext', {'actv_condition_dec_ext': c}),
            'Where visible, the walls appear in ${c.toLowerCase()} condition, consistent with their age and type of construction.');
      }
      expect(say('val_decorations_ext', {'actv_condition_dec_ext': 'Poor', 'et_notes_dec_ext': 'flaking'}), endsWith('Flaking'));
      expect(screens['val_decorations_ext']!.keys, isNot(contains('cb_paint_de')));
      expect(say('val_decorations_ext', {'cb_paint_de': 'true', 'actv_condition_dec_ext': 'Satisfactory'}),
          startsWith('The external decorations comprise paint finishes.'));
    });

    test('Floor', () {
      expect(labelsOf('val_floor_ext', 'cb_f_concrete', 'cb_f_other'), ['solid concrete', 'suspended timber', 'beam and block', 'other construction']);
      expect(screens['val_floor_ext']!.keys, isNot(contains('actv_condition_upper_floor')));
      expect(say('val_floor_ext', {'cb_f_concrete': 'true'}), 'Floors are of solid concrete.');
      expect(say('val_floor_ext', {'cb_f_timber': 'true', 'cb_f_beam': 'true', 'actv_condition_floor_ext': 'Good'}),
          startsWith('Floors are of suspended timber and beam and block. The floors are considered good'));
      expect(say('val_floor_ext', {'cb_f_other': 'true', 'et_f_other_text': 'Stone flags'}), 'Floors are of stone flags.');
      expect(say('val_floor_ext', {'cb_solid_gf': 'true'}), startsWith('The ground floor is of solid concrete construction.'));
    });

    test('Garage', () {
      expect(labelsOf('val_garage', 'cb_g_block', 'cb_g_other'),
          ['a garage in a block of garages', 'attached', 'detached', 'integral', 'under croft', 'other garage(s)']);
      expect(say('val_garage', {'cb_g_block': 'true'}), 'The property incorporates a garage in a block of garages.');
      expect(say('val_garage', {'cb_g_attached': 'true'}), 'The property incorporates an attached garage.');
      expect(say('val_garage', {'cb_g_detached': 'true'}), 'The property incorporates a detached garage.');
      expect(say('val_garage', {'cb_g_integral': 'true'}), 'The property incorporates an integral garage.');
      expect(say('val_garage', {'cb_g_croft': 'true'}), 'The property incorporates an under croft garage.');
      expect(say('val_garage', {'cb_g_other': 'true', 'et_g_other_text': 'Linked'}), 'The property incorporates a linked garage(s).');
      expect(say('val_garage', {'actv_garage_type': 'Detached', 'actv_number_of_garage': 'Double'}),
          startsWith('The property includes a double detached garage'));
    });

    test('Outbuilding', () {
      expect(labelsOf('val_outbuildings', 'cb_o_shed', 'cb_o_other'), ['large shed', 'workshop', 'annex', 'summer house', 'office', 'studio', 'other']);
      expect(say('val_outbuildings', {'cb_o_shed': 'true'}), 'The property incorporates a large shed.');
      expect(say('val_outbuildings', {'cb_o_annex': 'true', 'cb_o_office': 'true', 'cb_o_studio': 'true'}),
          'The property incorporates an annex, an office and a studio.');
      expect(say('val_outbuildings', {'cb_o_other': 'true', 'et_o_other_text': 'Gazebo'}), 'The property incorporates a gazebo.');
      expect(say('val_outbuildings', {'et_outbuilding_describe': 'Summer house'}), startsWith('The property includes outbuildings comprising Summer house.'));
    });
  });

  group('V12 Flat Roof and Main Wall (handwritten note)', () {
    test('Flat Roof has no Partial View and no Visibility Condition', () {
      final f = screens['val_flat_roof']!.keys;
      for (final gone in ['cb_partial_view_fr', 'actv_visibility_condition_fr', 'et_visibility_notes_fr']) {
        expect(f, isNot(contains(gone)));
      }
      expect(say('val_flat_roof', {'cb_partial_view_fr': 'true', 'actv_visibility_condition_fr': 'Unsatisfactory', 'et_visibility_notes_fr': 'x'}), isEmpty);
      // Pitched and Other roof keep theirs (the client only named Flat roof).
      expect(screens['val_pitched_roof']!.keys, contains('cb_partial_view_pr'));
      expect(screens['val_other_roof']!.keys, contains('cb_partial_view_or'));
    });
    test('Flat Roof still prints its material and condition', () {
      expect(say('val_flat_roof', {'cb_felt_fr': 'true', 'actv_condition_flat_roof': 'Good'}),
          allOf(startsWith('The flat roof covering is of mineral felt construction.'), contains('The flat roof covering is considered good')));
    });
    test('Main Wall Building movement: none / minor movement / significant movement', () {
      expect(screens['val_walls_type']!['actv_building_movement']!['options'], ['None', 'Minor movement', 'Significant movement']);
      expect(say('val_walls_type', {'actv_building_movement': 'None'}),
          'A careful examination was made of all accessible wall surfaces for evidence of structural movement, including cracking, distortion, bulging, or displacement of masonry.');
      expect(say('val_walls_type', {'actv_building_movement': 'Minor movement'}), contains('Evidence of building movement was noted: minor movement.'));
      expect(say('val_walls_type', {'actv_building_movement': 'Significant movement'}), contains('Evidence of building movement was noted: significant movement.'));
    });
    test('older answers (Structural Movement, Underpinning) still print', () {
      expect(say('val_walls_type', {'actv_building_movement': 'Underpinning'}), contains('Evidence of building movement was noted: underpinning.'));
    });
  });

  group('V13 Inside Property: the client sentences', () {
    List<String> labelsOf(String screen, String from, String to) {
      final f = screens[screen]!;
      final ids = f.keys.toList();
      return [for (final id in ids.sublist(ids.indexOf(from), ids.indexOf(to) + 1)) f[id]!['label'] as String];
    }

    test('Roof Space', () {
      expect(labelsOf('val_roof_space', 'cb_rs_timber', 'cb_rs_other'),
          ['traditional cut timber', 'prefabricated trussed rafters', 'steel', 'other construction']);
      expect(say('val_roof_space', {'cb_rs_timber': 'true'}), 'The roof structure is formed in traditional cut timber.');
      expect(say('val_roof_space', {'cb_rs_trussed': 'true', 'cb_rs_steel': 'true'}), 'The roof structure is formed in prefabricated trussed rafters and steel.');
      expect(say('val_roof_space', {'cb_rs_other': 'true', 'et_rs_other_text': 'Green oak'}), 'The roof structure is formed in green oak.');
      expect(say('val_roof_space', {'cb_trussed': 'true'}), startsWith('The roof space was entered and inspected where accessible.'));
    });

    test('Walls', () {
      final node = tree['sections'].expand((s) => s['nodes'] as List).firstWhere((n) => n['id'] == 'val_walls_internal') as Map;
      expect(node['title'], 'Walls');
      expect(labelsOf('val_walls_internal', 'cb_wi_masonry', 'cb_wi_other'),
          ['solid masonry', 'timber stud partitions', 'plasterboard partitions', 'lath and plaster', 'other construction']);
      expect(say('val_walls_internal', {'cb_wi_masonry': 'true'}), 'The walls are formed in solid masonry.');
      expect(say('val_walls_internal', {'cb_wi_stud': 'true', 'cb_wi_lath': 'true'}), 'The walls are formed in timber stud partitions and lath and plaster.');
      expect(say('val_walls_internal', {'cb_wi_other': 'true', 'et_wi_other_text': 'Brick nogging'}), 'The walls are formed in brick nogging.');
      expect(say('val_walls_internal', {'cb_solid_wi': 'true'}), startsWith('The internal walls and partitions are of solid construction.'));
    });

    test('Kitchen and Bathroom are two screens, Internal Fittings is gone', () {
      expect(screens.keys, containsAll(['val_kitchen', 'val_bathroom']));
      expect(screens.keys, isNot(contains('val_internal_fittings')));
    });

    test('Kitchen worktops', () {
      expect(labelsOf('val_kitchen', 'cb_k_laminate', 'cb_k_other'), [
        'laminate particle board', 'solid timber', 'granite', 'quartz', 'stone', 'Corian', 'compressed composite', 'marble', 'steel', 'other material',
      ]);
      expect(labelsOf('val_kitchen', 'cb_k_loc_kitchen', 'cb_k_loc_other'), ['kitchen', 'utility room', 'other']);
      expect(say('val_kitchen', {'cb_k_loc_kitchen': 'true', 'cb_k_laminate': 'true'}), 'The kitchen worktops comprise laminate particle board.');
      expect(say('val_kitchen', {'cb_k_loc_kitchen': 'true', 'cb_k_loc_utility': 'true', 'cb_k_granite': 'true', 'cb_k_quartz': 'true'}),
          'The kitchen and utility room worktops comprise granite and quartz.');
      expect(say('val_kitchen', {'cb_k_loc_other': 'true', 'et_k_loc_other_text': 'pantry', 'cb_k_marble': 'true'}), 'The pantry worktops comprise marble.');
      expect(say('val_kitchen', {'cb_k_other': 'true', 'et_k_other_text': 'Slate', 'cb_k_loc_kitchen': 'true'}), 'The kitchen worktops comprise slate.');
      expect(say('val_kitchen', {'cb_k_steel': 'true', 'actv_condition_kitchen': 'Fair', 'et_notes_kitchen': 'chipped'}),
          allOf(startsWith('The worktops comprise steel.'), contains('The kitchen has been assessed as fair.'), endsWith('Chipped')));
    });

    test('Bathroom', () {
      expect(labelsOf('val_bathroom', 'cb_b_family', 'cb_b_other'), [
        'family bathroom(s)', 'shower room(s)', 'ensuite shower room(s)', 'ensuite bathroom(s)', 'separate toilet(s)', 'utility room', 'other',
      ]);
      expect(say('val_bathroom', {'cb_b_family': 'true'}), 'The property incorporates family bathroom(s).');
      expect(say('val_bathroom', {'cb_b_shower': 'true', 'cb_b_ensuite_bath': 'true', 'cb_b_toilet': 'true'}),
          'The property incorporates shower room(s), ensuite bathroom(s) and separate toilet(s).');
      expect(say('val_bathroom', {'cb_b_other': 'true', 'et_b_other_text': 'wet room'}), 'The property incorporates wet room.');
      expect(say('val_bathroom', {'cb_b_utility': 'true', 'actv_condition_bathroom': 'Good'}),
          startsWith('The property incorporates utility room. The bathroom is considered good'));
    });

    test('Damp: locations and Damp Source only with Damp Found', () {
      expect(labelsOf('val_damp_meter', 'cb_dw_lounge', 'cb_dw_other'), ['lounge', 'dining room', 'bedroom', 'kitchen', 'bathroom', 'other']);
      expect(labelsOf('val_damp_meter', 'cb_ds_rainwater', 'cb_ds_other'),
          ['defective rainwater goods', 'blocked gullies', 'leaking pipework', 'bridged damp-proof course', 'other']);
      for (final id in ['cb_dw_lounge', 'cb_ds_rainwater']) {
        expect(screens['val_damp_meter']![id]!['conditionalOn'], 'actv_damp_meter=Damp Found');
      }
      expect(say('val_damp_meter', {'actv_damp_meter': 'Damp Found', 'cb_dw_lounge': 'true', 'cb_dw_bathroom': 'true'}),
          'Elevated moisture readings were recorded to sections of the wall surfaces in lounge and bathroom.');
      expect(say('val_damp_meter', {'actv_damp_meter': 'Damp Found', 'cb_dw_other': 'true', 'et_dw_other_text': 'hall'}),
          'Elevated moisture readings were recorded to sections of the wall surfaces in hall.');
      expect(say('val_damp_meter', {'actv_damp_meter': 'Damp Found', 'cb_ds_rainwater': 'true', 'cb_ds_dpc': 'true'}),
          allOf(contains('Elevated moisture levels were detected.'), contains('Dampness is suspected to be caused by defective rainwater goods and bridged damp-proof course.')));
      expect(say('val_damp_meter', {'actv_damp_meter': 'Damp Found', 'cb_ds_other': 'true', 'et_ds_other_text': 'condensation', 'cb_dw_kitchen': 'true'}),
          'Elevated moisture readings were recorded to sections of the wall surfaces in kitchen. Dampness is suspected to be caused by condensation.');
      expect(say('val_damp_meter', {'actv_damp_meter': 'Damp Not Found'}), 'Damp meter readings indicated: damp not found.');
      expect(say('val_damp_meter', {'actv_damp_meter': 'Damp Found', 'et_damp_found': 'bathroom'}), contains('Elevated readings were noted at bathroom.'));
    });
  });

  group('V14 Services: the client sentences', () {
    List<String> labelsOf(String screen, String from, String to) {
      final f = screens[screen]!;
      final ids = f.keys.toList();
      return [for (final id in ids.sublist(ids.indexOf(from), ids.indexOf(to) + 1)) f[id]!['label'] as String];
    }

    test('Electricity Metre', () {
      expect(labelsOf('val_electric_material', 'cb_em_stairs', 'cb_em_other'),
          ['under the stairs', 'in an outside box', 'in the entrance hall', 'in the kitchen', 'in the garage', 'in a communal cupboard', 'other']);
      const base = 'There is a mains electricity supply connected to the property, and the meter unit is located';
      const where = {
        'cb_em_stairs': 'under the stairs', 'cb_em_outside': 'in an outside box', 'cb_em_hall': 'in the entrance hall',
        'cb_em_kitchen': 'in the kitchen', 'cb_em_garage': 'in the garage', 'cb_em_cupboard': 'in a communal cupboard',
      };
      where.forEach((id, w) => expect(say('val_electric_material', {id: 'true'}), '$base $w.', reason: id));
      expect(say('val_electric_material', {'cb_em_hall': 'true', 'cb_em_garage': 'true'}), '$base in the entrance hall and in the garage.');
      expect(say('val_electric_material', {'cb_em_other': 'true', 'et_em_other_text': 'in the loft'}), '$base in the loft.');
      expect(say('val_electric_material', {'cb_old': 'true'}), startsWith('The electrical installation appears dated.'));
    });

    test('Gas: meter location shows and prints for Mains', () {
      expect(labelsOf('val_gas', 'cb_gm_stairs', 'cb_gm_other'),
          ['under the stairs', 'in an outside box', 'in the kitchen', 'in the garage', 'in a communal cupboard', 'other']);
      expect(screens['val_gas']!['cb_gm_stairs']!['conditionalOn'], 'actv_gas_supply=Mains');
      const base = 'There is a mains gas connection to the property, and the meter unit is located';
      expect(say('val_gas', {'actv_gas_supply': 'Mains', 'cb_gm_outside': 'true'}), '$base in an outside box.');
      expect(say('val_gas', {'actv_gas_supply': 'Mains', 'cb_gm_kitchen': 'true', 'cb_gm_garage': 'true', 'actv_condition_gas': 'Good'}),
          startsWith('$base in the kitchen and in the garage. The gas installation is considered good'));
      expect(say('val_gas', {'actv_gas_supply': 'Mains', 'cb_gm_other': 'true', 'et_gm_other_text': 'in the porch'}), '$base in the porch.');
      // Without a location the usual Mains sentence stays.
      expect(say('val_gas', {'actv_gas_supply': 'Mains'}), startsWith('The property is connected to mains gas supply.'));
      expect(say('val_gas', {'actv_gas_supply': 'LPG', 'cb_gm_stairs': 'true'}), isNot(contains('meter unit')));
    });

    test('Water: stopcock location shows and prints for Mains', () {
      expect(labelsOf('val_water', 'cb_sc_stairs', 'cb_sc_other'),
          ['under the stairs', 'under the kitchen sink', 'in the bathroom', 'in the hall', 'in the garage', 'other']);
      expect(screens['val_water']!['cb_sc_stairs']!['conditionalOn'], 'actv_water_supply=Mains');
      const base = 'There is an independent mains water supply to the property. The stopcock within the property is located';
      expect(say('val_water', {'actv_water_supply': 'Mains', 'cb_sc_sink': 'true'}), '$base under the kitchen sink.');
      expect(say('val_water', {'actv_water_supply': 'Mains', 'cb_sc_hall': 'true', 'cb_sc_bathroom': 'true'}), '$base in the bathroom and in the hall.');
      expect(say('val_water', {'actv_water_supply': 'Mains', 'cb_sc_other': 'true', 'et_sc_other_text': 'in the cellar'}), '$base in the cellar.');
      expect(say('val_water', {'actv_water_supply': 'Mains'}), startsWith('The property is connected to mains water supply.'));
    });

    test('Heating and Water Heating', () {
      expect(labelsOf('val_hot_water_central_heating', 'cb_h_combi', 'cb_h_other'),
          ['combination boiler', 'conventional boiler', 'sealed boiler system', 'electrical boiler', 'oil-fired boiler', 'other']);
      expect(labelsOf('val_hot_water_central_heating', 'cb_hw_combi', 'cb_hw_other'),
          ['combination boiler', 'conventional boiler', 'sealed boiler system', 'electrical boiler', 'oil-fired boiler', 'other']);
      const heat = {
        'cb_h_combi': 'a combination boiler', 'cb_h_conventional': 'a conventional boiler', 'cb_h_sealed': 'a sealed boiler system',
        'cb_h_electric': 'an electrical boiler', 'cb_h_oil': 'an oil-fired boiler',
      };
      heat.forEach((id, w) => expect(say('val_hot_water_central_heating', {id: 'true'}), 'The property is heated by $w.', reason: id));
      const water = {
        'cb_hw_combi': 'the combination boiler', 'cb_hw_conventional': 'the conventional boiler', 'cb_hw_sealed': 'the sealed boiler system',
        'cb_hw_electric': 'the electrical boiler', 'cb_hw_oil': 'the oil-fired boiler',
      };
      water.forEach((id, w) => expect(say('val_hot_water_central_heating', {id: 'true'}), 'The hot water is provided by $w.', reason: id));
      expect(say('val_hot_water_central_heating', {'cb_h_combi': 'true', 'cb_h_oil': 'true', 'cb_hw_combi': 'true'}),
          'The property is heated by a combination boiler and an oil-fired boiler. The hot water is provided by the combination boiler.');
      expect(say('val_hot_water_central_heating', {'cb_h_other': 'true', 'et_h_other_text': 'a heat pump', 'cb_hw_other': 'true', 'et_hw_other_text': 'a solar cylinder'}),
          'The property is heated by a heat pump. The hot water is provided by a solar cylinder.');
      expect(say('val_hot_water_central_heating', {'cb_gas_hw': 'true', 'cb_radiators': 'true'}),
          startsWith('The hot water and central heating system is fuelled by gas.'));
    });
  });

  group('V15 Overall Condition, Other Matters / EPC removed, Valuation, Purpose', () {
    test('Overall Condition: the two client options and sentences', () {
      expect(screens['overall_condition']!['actv_overall_condition']!['options'], ['Reasonable', 'Reasonable with repair']);
      expect(say('overall_condition', {'actv_overall_condition': 'Reasonable'}),
          'I am pleased to advise you that this property is believed to be in reasonable condition consistent with the age and type of construction.');
      expect(say('overall_condition', {'actv_overall_condition': 'Reasonable with repair'}),
          'I am pleased to advise you that this property is believed to be in reasonable condition consistent with the age and type of construction. '
          'You should be prepared to cover the costs and accept the inconvenience of dealing with any repairs or improvement works reported.');
      expect(say('overall_condition', {'actv_overall_condition': 'Reasonable', 'et_restrictions': 'no access to the loft'}),
          endsWith('should be noted: no access to the loft'));
    });
    test('Overall Condition: surveys saved with Good / Average / Poor keep their wording', () {
      expect(say('overall_condition', {'actv_overall_condition': 'Good'}), contains('considered good'));
      expect(say('overall_condition', {'actv_overall_condition': 'Poor'}), contains('considered unsatisfactory'));
    });
    test('Other Matters and Energy Performance are gone', () {
      expect(screens.keys, isNot(contains('other_matters')));
      expect(screens.keys, isNot(contains('energy_performance')));
      expect(say('other_matters', {'cb_flooding': 'true', 'et_notes_flooding': 'low'}), isEmpty);
      expect(say('energy_performance', {'actv_epc_current_rating': 'C'}), isEmpty);
      expect(
          ValuationAnswerValidator.validateSurvey({'energy_performance': {'et_epc_current_score': '999'}}, liveScreens: screens.keys.toSet()),
          isEmpty);
    });
    test('Valuation: the client sentence with the amount in figures and words', () {
      expect(say('valuation', {'et_purchase_price': '325000'}),
          'Based on an analysis of recent comparable sales for similar properties in the locality, the agreed purchase price of '
          '£325,000.00 (Three Hundred and Twenty Five Thousand Pounds) appears reasonable in current market conditions.');
      expect(say('valuation', {'et_purchase_price': '£1,250,500'}),
          contains('£1,250,500.00 (One Million Two Hundred and Fifty Thousand Five Hundred Pounds)'));
      expect(say('valuation', {}), isEmpty);
    });
    test('Valuation: the other fields stay and still print', () {
      expect(screens['valuation']!.keys, containsAll(['et_estimated_value', 'cb_open_market_value', 'et_value_of_share', 'et_share', 'et_after_works_value', 'et_retention', 'cb_suitable_security']));
      expect(say('valuation', {'et_retention': '5000'}), contains('A retention of £5,000 is recommended'));
    });
    test('Purpose of Valuation: the client list, Staircasing added', () {
      final f = screens['general_details']!['actv_vl_reason']!;
      expect(f['options'], ['Market Value', 'Shared Ownership', 'Staircasing', 'Help to Buy', 'Compulsory Purchase', 'Other']);
      for (final o in (f['options'] as List).take(5)) {
        expect(say('general_details', {'actv_vl_reason': o as String}), 'The purpose of this valuation is for $o.', reason: o);
      }
      expect(say('general_details', {'actv_vl_reason': 'Other', 'actv_vl_reason_other_text': 'probate'}), 'The purpose of this valuation is for probate.');
      expect(say('general_details', {'actv_vl_reason': 'Right to Buy'}), 'The purpose of this valuation is for Right to Buy.');
    });
  });
}
