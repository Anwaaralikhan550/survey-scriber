// Client answers to the valuation questions (docx returned 17 Nov 2026) + the user's list of the same day.
// One group per locked step (A2..A10); see docs/VALUATION-NOV17-PROGRESS.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_answer_validator.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';

void main() {
  final engine = ValuationPhraseEngine();
  final tree = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync())
      as Map<String, dynamic>;
  // screen id -> field id -> field json, and screen id -> parent id / order
  final screens = <String, Map<String, Map<String, dynamic>>>{};
  final nodes = <String, Map<String, dynamic>>{};
  final order = <String>[];
  for (final s in tree['sections'] as List) {
    for (final n in (s as Map)['nodes'] as List) {
      final id = (n as Map)['id'] as String;
      nodes[id] = n.cast<String, dynamic>();
      order.add(id);
      screens[id] = {
        for (final f in (n['fields'] as List? ?? const [])) (f as Map)['id'] as String: f.cast<String, dynamic>(),
      };
    }
  }
  String say(String screen, Map<String, String> answers) => engine.buildPhrases(screen, answers).join(' ');
  Map<String, String> ticks(Iterable<String> ids, [Map<String, String> more = const {}]) =>
      {for (final i in ids) i: 'true', ...more};

  group('A2 Oil / LPG tank after Gas', () {
    test('a screen of its own sits right after Gas, before Water', () {
      expect(nodes['val_oil_lpg']!['title'], 'Oil / LPG Tank');
      expect(nodes['val_oil_lpg']!['parentId'], 'inside_property');
      expect(order.indexOf('val_oil_lpg'), order.indexOf('val_gas') + 1);
      expect(order.indexOf('val_water'), order.indexOf('val_oil_lpg') + 1);
      final orders = [for (final id in ['val_gas', 'val_oil_lpg', 'val_water']) nodes[id]!['order'] as int];
      expect(orders[0] < orders[1] && orders[1] < orders[2], isTrue, reason: '$orders');
    });
    test('the lists are exactly the client words and Other opens a text box', () {
      final f = screens['val_oil_lpg']!;
      String lab(String id) => f[id]!['label'] as String;
      expect([lab('cb_ol_oil'), lab('cb_ol_lpg')], ['Oil-fired', 'LPG-fired']);
      expect([lab('cb_ot_plastic'), lab('cb_ot_metal'), lab('cb_ot_other')], ['plastic', 'metal', 'other']);
      expect([lab('cb_ol_front'), lab('cb_ol_side'), lab('cb_ol_rear'), lab('cb_ol_other')],
          ['front garden', 'side garden', 'rear garden', 'other']);
      expect(f['et_ot_other_text']!['conditionalOn'], 'cb_ot_other');
      expect(f['et_ol_other_text']!['conditionalOn'], 'cb_ol_other');
    });
    test('the whole sentence, as the client wrote it', () {
      expect(
          say('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ot_plastic', 'cb_ol_front'])),
          'The property is served by an Oil-fired heating system with a plastic fuel storage tank(s) located at the front garden.');
    });
    test('Oil-fired, LPG-fired and both', () {
      expect(say('val_oil_lpg', ticks(['cb_ol_lpg'])), 'The property is served by an LPG-fired heating system.');
      expect(say('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ol_lpg'])),
          'The property is served by an Oil-fired / LPG-fired heating system.');
    });
    test('every tank and every place has its words', () {
      expect(say('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ot_metal'])),
          'The property is served by an Oil-fired heating system with a metal fuel storage tank(s).');
      for (final e in {'cb_ol_front': 'front garden', 'cb_ol_side': 'side garden', 'cb_ol_rear': 'rear garden'}.entries) {
        expect(say('val_oil_lpg', ticks(['cb_ol_oil', e.key])),
            'The property is served by an Oil-fired heating system located at the ${e.value}.',
            reason: e.key);
      }
    });
    test('several ticks and the typed Other words', () {
      expect(
          say('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ot_plastic', 'cb_ot_metal', 'cb_ol_side', 'cb_ol_rear'])),
          'The property is served by an Oil-fired heating system with a plastic and metal fuel storage tank(s) '
          'located at the side garden and rear garden.');
      expect(
          say('val_oil_lpg',
              ticks(['cb_ol_lpg', 'cb_ot_other', 'cb_ol_other'], {'et_ot_other_text': 'aluminium', 'et_ol_other_text': 'driveway'})),
          'The property is served by an LPG-fired heating system with an aluminium fuel storage tank(s) located at the driveway.');
    });
    test('a tank or place without a fuel prints nothing and the screen says why', () {
      final a = ticks(['cb_ot_metal', 'cb_ol_front']);
      expect(say('val_oil_lpg', a), '');
      expect(ValuationAnswerValidator.validateScreen('val_oil_lpg', a), ['Tick Oil-fired or LPG-fired for the fuel storage tank.']);
      expect(ValuationAnswerValidator.validateScreen('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ot_metal'])), isEmpty);
    });
    test('Other needs its words', () {
      expect(ValuationAnswerValidator.validateScreen('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ot_other'])),
          ['Provide a description when Other fuel storage tank is selected.']);
      expect(ValuationAnswerValidator.validateScreen('val_oil_lpg', ticks(['cb_ol_oil', 'cb_ol_other'])),
          ['Provide a description when Other fuel storage tank location is selected.']);
    });
    test('Gas and Water are unchanged', () {
      expect(say('val_gas', {'actv_gas_supply': 'Mains', 'cb_gm_kitchen': 'true'}),
          startsWith('There is a mains gas connection to the property, and the meter unit is located in the kitchen.'));
      expect(say('val_water', {'actv_water_supply': 'Mains', 'cb_sc_hall': 'true'}),
          startsWith('There is an independent mains water supply to the property. The stopcock within the property is located in the hall.'));
    });
  });

  group('A3 Electricity: Dated beside the meter location', () {
    test('one Dated tick, in the Electricity Metre group, right after the location ticks', () {
      final f = screens['val_electric_material']!;
      expect(f['cb_em_dated']!['label'], 'Dated');
      final ids = f.keys.toList();
      expect(ids.indexOf('cb_em_dated'), ids.indexOf('et_em_other_text') + 1);
      expect(ids.indexOf('cb_em_dated') < ids.indexOf('label_electric'), isTrue, reason: 'before the Electric Material group');
      expect(f.values.where((x) => (x['label'] as String).toLowerCase() == 'dated').length, 1);
    });
    test('location only keeps the client sentence', () {
      expect(say('val_electric_material', ticks(['cb_em_stairs'])),
          'There is a mains electricity supply connected to the property, and the meter unit is located under the stairs.');
    });
    test('Dated adds its sentence, with or without a location', () {
      expect(say('val_electric_material', ticks(['cb_em_kitchen', 'cb_em_dated'])),
          'There is a mains electricity supply connected to the property, and the meter unit is located in the kitchen. The meter unit is dated.');
      expect(say('val_electric_material', ticks(['cb_em_dated'])), 'The meter unit is dated.');
    });
    test('the Age ticks (Modern / Old ...) are untouched', () {
      expect(say('val_electric_material', ticks(['cb_old'])), contains('The electrical installation appears dated.'));
    });
  });

  group('A4 Date of Extension inside the Extension sentence', () {
    test('the field keeps its client label', () {
      expect(screens['general_details']!['et_age_extension']!['label'], 'Age of Extension (Date of Extension)');
    });
    test('the year is part of the Extension sentence', () {
      expect(say('general_details', ticks(['cb_ext_side', 'cb_ext_rear'], {'et_age_extension': '1995'})),
          'The property has been extended in 1995 to provide side and rear accommodation.');
    });
    test('no year: the sentence is exactly as before', () {
      expect(say('general_details', ticks(['cb_ext_loft'])), 'The property has been extended to provide loft accommodation.');
    });
    test('a year with no extension type still prints', () {
      expect(say('general_details', {'et_age_extension': '2008'}), 'The property has been extended in 2008.');
    });
    test('Year Built sentence is unaffected', () {
      final out = say('general_details', ticks(['cb_ext_two'], {'et_age': '1960', 'et_age_extension': '1995'}));
      expect(out, contains('The property is understood to have been built in 1960.'));
      expect(out, contains('The property has been extended in 1995 to provide two-storey accommodation.'));
    });
    test('the year is still checked', () {
      expect(ValuationAnswerValidator.validateScreen('general_details', {'et_age_extension': '19'}),
          isNotEmpty);
    });
  });

  group('A5 three roofs, three sentences', () {
    test('Pitched no longer offers the flat-roof materials; Flat has them', () {
      final p = screens['val_pitched_roof']!;
      for (final gone in ['cb_r_felt', 'cb_r_rubber', 'cb_r_single']) {
        expect(p.keys, isNot(contains(gone)), reason: gone);
      }
      final f = screens['val_flat_roof']!;
      expect([f['cb_fr_felt']!['label'], f['cb_fr_rubber']!['label'], f['cb_fr_single']!['label']],
          ['mineral felt', 'rubber membrane', 'single-ply membrane']);
      expect(f['et_fr_other_text']!['conditionalOn'], 'cb_fr_other');
    });
    test('Pitched keeps the client sentence', () {
      expect(say('val_pitched_roof', ticks(['cb_r_clay', 'cb_r_metal'])), 'The roof covering is formed in clay tiles and metal sheeting.');
    });
    test('Flat roof sentence for every material and Other', () {
      expect(say('val_flat_roof', ticks(['cb_fr_felt'])), 'The flat roof covering is formed in mineral felt.');
      expect(say('val_flat_roof', ticks(['cb_fr_rubber'])), 'The flat roof covering is formed in rubber membrane.');
      expect(say('val_flat_roof', ticks(['cb_fr_single'])), 'The flat roof covering is formed in single-ply membrane.');
      expect(say('val_flat_roof', ticks(['cb_fr_felt', 'cb_fr_single', 'cb_fr_other'], {'et_fr_other_text': 'asphalt'})),
          'The flat roof covering is formed in mineral felt, single-ply membrane and asphalt.');
    });
    test('Other roof sentence: the client roof list, with or without a name', () {
      const all = {
        'cb_or_clay': 'clay tiles',
        'cb_or_concrete': 'concrete tiles',
        'cb_or_natural': 'natural slate',
        'cb_or_artificial': 'artificial slate',
        'cb_or_fibre': 'fibre cement slates',
        'cb_or_metal': 'metal sheeting',
        'cb_or_felt': 'mineral felt',
        'cb_or_rubber': 'rubber membrane',
        'cb_or_single': 'single-ply membrane',
      };
      all.forEach((id, words) {
        expect(say('val_other_roof', ticks([id])), 'The other roof covering is formed in $words.', reason: id);
      });
      expect(say('val_other_roof', ticks(['cb_or_natural'], {'et_other_roof_name': 'garage roof'})),
          'Garage roof covering is formed in natural slate.');
      expect(say('val_other_roof', ticks(['cb_or_other'], {'et_or_other_text': 'thatch'})),
          'The other roof covering is formed in thatch.');
    });
    test('the three sentences are different', () {
      final s = {
        say('val_pitched_roof', ticks(['cb_r_clay'])),
        say('val_flat_roof', ticks(['cb_fr_felt'])),
        say('val_other_roof', ticks(['cb_or_clay'])),
      };
      expect(s.length, 3);
    });
    test('answers saved with the earlier ticks keep their wording', () {
      // flat-roof materials ticked on the Pitched screen before 17 Nov
      expect(say('val_pitched_roof', ticks(['cb_r_felt', 'cb_r_rubber'])),
          'The roof covering is formed in mineral felt and rubber membrane.');
      // the original Flat Roof ticks
      expect(say('val_flat_roof', ticks(['cb_asphalt_fr'])), contains('The flat roof covering is of asphalt construction.'));
      // the original Other Roof ticks
      expect(say('val_other_roof', ticks(['cb_tile_or'])), contains('is covered with'));
    });
    test('Other needs its words', () {
      expect(ValuationAnswerValidator.validateScreen('val_flat_roof', ticks(['cb_fr_other'])),
          ['Provide a description when Other flat roof covering is selected.']);
      expect(ValuationAnswerValidator.validateScreen('val_other_roof', ticks(['cb_or_other'])),
          ['Provide a description when Other other roof covering is selected.']);
    });
  });

  group('A8 Rainwater Goods: "and associated fittings" is fixed text', () {
    test('no tick for it any more', () {
      expect(screens['val_rainwater_goods']!.keys, isNot(contains('cb_rw_fittings')));
    });
    test('the whole list as the client typed it', () {
      expect(
          say('val_rainwater_goods',
              ticks(['cb_rw_pvc', 'cb_rw_cast', 'cb_rw_alum', 'cb_rw_steel', 'cb_rw_concrete', 'cb_rw_asbestos', 'cb_rw_gutters', 'cb_rw_down', 'cb_rw_hoppers'])),
          'The rainwater goods comprise PVC, cast iron, aluminium, steel, concrete, asbestos cement, gutters, downpipes, hoppers, and associated fittings.');
    });
    test('fewer ticks, Other words before the gutters', () {
      expect(say('val_rainwater_goods', ticks(['cb_rw_pvc'])), 'The rainwater goods comprise PVC, and associated fittings.');
      expect(say('val_rainwater_goods', ticks(['cb_rw_gutters'])), 'The rainwater goods comprise gutters, and associated fittings.');
      expect(say('val_rainwater_goods', ticks(['cb_rw_pvc', 'cb_rw_other', 'cb_rw_down'], {'et_rw_other_text': 'lead'})),
          'The rainwater goods comprise PVC, lead, downpipes, and associated fittings.');
    });
    test('nothing ticked prints nothing; an old fittings tick adds nothing twice', () {
      expect(say('val_rainwater_goods', {}), '');
      expect(say('val_rainwater_goods', ticks(['cb_rw_pvc', 'cb_rw_fittings'])), 'The rainwater goods comprise PVC, and associated fittings.');
    });
  });

  group('A9 Significant Valuation Consideration, Timber Defects: dry and wet rot', () {
    test('two separate ticks', () {
      final f = screens['val_sv_timber']!;
      expect(f['cb_svt_rot']!['label'], 'Extensive Dry Rot');
      expect(f['cb_svt_wet']!['label'], 'Extensive Wet Rot');
      final ids = f.keys.toList();
      expect(ids.indexOf('cb_svt_wet'), ids.indexOf('cb_svt_rot') + 1);
    });
    test('each prints its own words', () {
      const lead = 'The following are the additional timber defects related valuation concerns:';
      expect(say('val_sv_timber', ticks(['cb_svt_rot'])), '$lead Extensive Dry Rot.');
      expect(say('val_sv_timber', ticks(['cb_svt_wet'])), '$lead Extensive Wet Rot.');
      expect(say('val_sv_timber', ticks(['cb_svt_insects', 'cb_svt_rot', 'cb_svt_wet'])),
          '$lead Wood-boring Insects, Extensive Dry Rot and Extensive Wet Rot.');
    });
  });
}
