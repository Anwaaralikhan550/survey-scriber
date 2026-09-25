import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

/// Phase 3 regression suite: Section D handlers must emit the approved
/// phrase-bank sentences, not ad-hoc "Label: value" output (client
/// complaint: "phrases that have not come from the approved database bank").
void main() {
  late InspectionPhraseEngine engine;

  setUpAll(() {
    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    engine = InspectionPhraseEngine(phraseTexts);
  });

  group('D-Construction: approved templates', () {
    const concreteAdvisory =
        'Where the property is of concrete or precast concrete panel '
        'construction, some lenders may regard this as a non-standard form of '
        'construction. As a result, the availability of mortgage finance may be '
        'more limited than for traditionally constructed properties, and some '
        'lenders may decline to lend altogether. Lending criteria vary between '
        'mortgage providers and may depend on the specific construction type, '
        'its condition, and whether any approved repair or certification '
        'schemes have been carried out. You should make enquiries with your '
        'proposed lender or an independent mortgage broker at an early stage to '
        'confirm that satisfactory mortgage finance will be available before '
        'committing to the purchase.';

    test('property construction uses CONSTRUCTION_TYPE_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_property_construction',
        {'ch3': 'true', 'ch4': 'true'},
      );
      // Type sentence from the approved template …
      expect(
        phrases.first,
        'The property is believed to be constructed using cavity wall and '
        'timber frame construction.',
      );
      // … then the timber/steel Modern Building Design advisory (revised spec).
      expect(
        phrases.any((p) => p.startsWith('Modern Building Design:')),
        isTrue,
      );
      expect(
        phrases.any((p) =>
            p.contains('framed externally with timber, steel, or other')),
        isTrue,
      );
    });

    test(
        'concrete wall construction appends the mortgage-lending advisory '
        '(revised spec)', () {
      final phrases = engine.buildPhrases(
        'activity_property_construction',
        {'ch6': 'true'},
      );
      expect(phrases, hasLength(2));
      expect(
        phrases.first,
        'The property is believed to be constructed using concrete wall '
        'construction.',
      );
      expect(phrases[1], concreteAdvisory);
    });

    test(
        'precast concrete panels also trigger the mortgage-lending advisory '
        '(revised spec)', () {
      final phrases = engine.buildPhrases(
        'activity_property_construction',
        {'ch8': 'true'},
      );
      expect(phrases, hasLength(2));
      expect(
        phrases.first,
        'The property is believed to be constructed using precast concrete '
        'panels construction.',
      );
      expect(phrases[1], concreteAdvisory);
    });

    test('system-built construction emits only the type sentence (no advisory)',
        () {
      final phrases = engine.buildPhrases(
        'activity_property_construction',
        {'ch9': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The property is believed to be constructed using system-built '
        'construction.',
      );
    });

    test('non-concrete construction emits only the type sentence (no advisory)',
        () {
      final phrases = engine.buildPhrases(
        'activity_property_construction',
        {'ch3': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The property is believed to be constructed using cavity wall '
        'construction.',
      );
    });

    test('roof uses CONSTRUCTION_ROOF_AREA without built-with clause', () {
      final phrases = engine.buildPhrases(
        'activity_property_roof',
        {'ch2': 'true', 'ch8': 'true', 'ch6': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The main roof is of pitched construction. The roof covering is '
        'formed in concrete tiles.',
      );
    });

    test('roof with partial data (type only) emits nothing, not a fragment',
        () {
      final phrases = engine.buildPhrases(
        'activity_property_roof',
        {'ch2': 'true'},
      );
      expect(phrases, isEmpty,
          reason: 'no "covered in ." fragments (client-reported defect)');
    });

    test('external walls use CONSTRUCTION_EXT_WALL_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_extended_wall',
        {'ch2': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The external walls are constructed of cavity brick wall '
        'construction.',
      );
    });

    test('internal walls use CONSTRUCTION_INT_WALL_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_internal_wall',
        {'ch1': 'true', 'ch2': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'Internal walls are formed in stud and solid partitions.',
      );
    });

    test('floors use CONSTRUCTION_FLOOR_AREA with correct grammar', () {
      final phrases = engine.buildPhrases(
        'activity_construction_floor',
        {'ch1': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The floors are mainly of suspended timber construction.',
      );
      expect(phrases.single, isNot(contains('of mainly of')),
          reason: 'client-reported grammar bug must not reappear');
    });

    test('windows use CONSTRUCTION_WINDOWS_AREA', () {
      final phrases = engine.buildPhrases(
        'activity_construction_window',
        {'ch2': 'true', 'ch5': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The windows are fitted with uPVC frames incorporating double '
        'glazing.',
      );
    });
  });

  group('D-Ground: approved garden templates', () {
    test('front garden screen uses GROUND_FRONT_GARDEN + fence sentence', () {
      final phrases = engine.buildPhrases(
        'activity_front_garden',
        {'ch1': 'true', 'ch8': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The front garden is laid to paved. The boundary fences are '
        'formed in timber.',
      );
    });

    test('no-boundary variant uses GARDEN_NO_BOUNDRY_FENCES', () {
      final phrases = engine.buildPhrases(
        'activity_rear_garden',
        {'ch2': 'true', 'ch20': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The rear garden is laid to lawned. There are no boundary '
        'fences installed.',
      );
    });

    test('combined garden screen emits approved sentence per area', () {
      final phrases = engine.buildPhrases(
        'activity_garden',
        {
          'android_material_design_spinner': 'Paved',
          'android_material_design_spinner2': 'Timber',
          'android_material_design_spinner3': 'Lawned',
        },
      );
      expect(phrases, hasLength(2));
      expect(
        phrases.first,
        'The front garden is laid to paved. The boundary fences are '
        'formed in timber.',
      );
      expect(phrases.last, 'The rear garden is laid to lawned.');
    });

    test('topography uses GROUND_TOPOGRAPHY', () {
      final phrases = engine.buildPhrases(
        'activity_topography',
        {'android_material_design_spinner': 'Level'},
      );
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The property occupies a level site.',
      );
    });
  });

  group('E condition-rating coverage', () {
    test('main walls emits the approved rating and notes wording', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_main_walls_main_screen',
        {
          'android_material_design_spinner4': '2',
          'ar_etNote': 'Monitor the repaired wall finish.',
        },
      );

      expect(phrases, contains('Condition rating is: 2.'));
      expect(phrases, contains('Notes:'));
      expect(phrases, contains('Monitor the repaired wall finish.'));
    });

    test('windows emits the approved rating and notes wording', () {
      final phrases = engine.buildPhrases(
        'activity_outside_property_windows_main_screen',
        {
          'android_material_design_spinner4': '3',
          'ar_etNote': 'Obtain quotations before exchange.',
        },
      );

      expect(phrases, contains('Condition rating is: 3.'));
      expect(phrases, contains('Notes:'));
      expect(phrases, contains('Obtain quotations before exchange.'));
    });
  });

  group('G4 Heating: revised-spec heat-pump / forced-air types', () {
    List<String> heating(Map<String, String> answers) =>
        engine.buildPhrases('activity_services_heating_about_heating', answers);

    test('air source heat pump emits its advisory', () {
      final phrases = heating({'cb_air_source_heat_pump': 'true'});
      final t = phrases.join(' ');
      expect(t, contains('heated by an air source heat pump'));
      expect(t, contains('no operational testing or assessment of performance'));
      expect(t, isNot(contains('{')));
    });

    test('ground source heat pump emits its advisory', () {
      final phrases = heating({'cb_ground_source_heat_pump': 'true'});
      final t = phrases.join(' ');
      expect(t, contains('heated by a ground source heat pump'));
      expect(t, contains('ground collectors or boreholes are below ground'));
    });

    test('forced air heating emits its advisory', () {
      final phrases = heating({'cb_forced_air': 'true'});
      final t = phrases.join(' ');
      expect(t, contains('forced air heating system'));
      expect(t, contains('warm air distributed throughout the property'));
    });

    test('no heat-pump advisory when none is selected', () {
      final phrases = heating({'cb_no_heating': 'true'});
      final t = phrases.join(' ');
      expect(t, isNot(contains('air source heat pump')));
      expect(t, isNot(contains('ground source heat pump')));
      expect(t, isNot(contains('forced air heating system')));
    });
  });

  group('Overall opinion: revised-spec rating (reasonable/good/fair/poor)', () {
    List<String> opinion(String rating) => engine.buildPhrases(
          'activity_over_all_openion',
          {'android_material_design_spinner5': rating},
        );

    test('reasonable keeps the favourable opener and reads "reasonable"', () {
      final phrases = opinion('Reasonable');
      expect(phrases, hasLength(1));
      final text = phrases.single;
      expect(text, contains('I am pleased to advise'));
      expect(text,
          contains('the property represents a reasonable proposition'));
      expect(text, isNot(contains('{')));
    });

    test('good/fair/poor substitute the adjective and drop the opener', () {
      for (final rating in ['Good', 'Fair', 'Poor']) {
        final phrases = opinion(rating);
        expect(phrases, isNotEmpty, reason: '$rating should emit text');
        final text = phrases.join(' ');
        expect(
          text,
          contains(
              'the property represents a ${rating.toLowerCase()} proposition'),
          reason: '$rating adjective must be substituted',
        );
        // The favourable "pleased to advise" opener is only for a reasonable
        // verdict — never shown for good/fair/poor.
        expect(text, isNot(contains('I am pleased to advise')),
            reason: '$rating must not carry the favourable opener');
        expect(text, startsWith('In my opinion,'));
        // No placeholder or rating token leaks into the report.
        expect(text, isNot(contains('{')), reason: '$rating: no token leak');
      }
    });

    test('"reasonable with repair" still routes to the repair narrative', () {
      final phrases = engine.buildPhrases(
        'activity_over_all_openion',
        {
          'android_material_design_spinner5': 'Reasonable with repair',
          'android_material_design_spinner': '1500',
          'android_material_design_spinner2': 'Roof repairs',
        },
      );
      expect(phrases, contains(contains('provisional repair allowance')));
      expect(phrases.join(' '), isNot(contains('{')));
    });
  });

  group('F1 Roof Structure: revised-spec additions', () {
    List<String> about(Map<String, String> answers) =>
        engine.buildPhrases('activity_inside_property_about_roof_structure',
            answers);

    test('spray foam checkbox emits the spray-foam advisory', () {
      final phrases = about({'cb_spray_foam': 'true'});
      expect(phrases, hasLength(1));
      expect(phrases.single, startsWith('Spray Foam Insulation:'));
      expect(phrases.single, contains('mortgageability, insurability'));
      expect(phrases.single, isNot(contains('{')));
    });

    test('water-penetration checkbox emits the water-penetration advisory', () {
      final phrases = about({'cb_water_penetration': 'true'});
      expect(phrases, hasLength(1));
      expect(phrases.single, startsWith('Evidence of Water Penetration:'));
      expect(phrases.single, contains('Water staining or dampness'));
    });

    test('capped soil-vent-pipe checkbox emits its advisory', () {
      final phrases = about({'cb_capped_soil_vent_pipe': 'true'});
      expect(phrases, hasLength(1));
      expect(phrases.single, startsWith('Capped Soil Vent Pipe:'));
      expect(phrases.single, contains('terminating within the roof space'));
    });

    test('the three advisories can combine with the construction sentence', () {
      final phrases = about({
        'actv_construction': 'Built of traditional cut timber',
        'cb_spray_foam': 'true',
        'cb_water_penetration': 'true',
        'cb_capped_soil_vent_pipe': 'true',
      });
      expect(phrases.any((p) => p.startsWith('Roof Structure:')), isTrue);
      expect(phrases.any((p) => p.startsWith('Spray Foam Insulation:')), isTrue);
      expect(
          phrases.any((p) => p.startsWith('Evidence of Water Penetration:')),
          isTrue);
      expect(phrases.any((p) => p.startsWith('Capped Soil Vent Pipe:')), isTrue);
      expect(phrases.join(' '), isNot(contains('{')));
    });

    test('no roof-structure advisory when nothing is selected', () {
      expect(about(const {}), isEmpty);
    });
  });
}
