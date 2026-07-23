import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - property extended', () {
    const phraseTexts = <String, String>{
      '{D_PRO_EXTENDED_STATUS_KNOWN}':
          '<strong>Known:</strong> The year of the {PRO_EXTENDED_LOCATION} extension is {PRO_EXTENDED_DATE}.',
      '{D_PRO_EXTENDED_STATUS_UNKNOWN}':
          '<strong>Unknown:</strong> The year of the {PRO_EXTENDED_LOCATION} extension is not known.',
      '{D_PRO_EXTENDED_STATUS_NOT_EXTENDED}':
          '<strong>Not Extended:</strong> The property has not been extended.',
    };

    test('uses selected location checkboxes for known status', () {
      const engine = InspectionPhraseEngine(phraseTexts);
      final phrases = engine.buildPhrases('activity_property_extended', {
        'android_material_design_spinner': 'Known',
        'textView3': '2001',
        'ch1': 'true',
        'ch3': 'true',
      });

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('front and rear extension'));
      expect(phrases.first, contains('2001'));
      expect(phrases.first, isNot(contains('...')));
    });
  });

  group('InspectionPhraseEngine - flat maisonettes', () {
    const phraseTexts = <String, String>{
      '{D_FLAT_INFORMATION}':
          'Flat info: {FLAT_INFO_PRO_ON_FLOOR}, {FLAT_INFO_PRO_NO_OF_STOREY}, {FLAT_INFO_PRO_ACCESS_VIA}, {FLAT_INFO_PRO_ACCESS_ELEVATION}.',
    };

    test('uses companion text value when dropdown selection is Other', () {
      const engine = InspectionPhraseEngine(phraseTexts);
      final phrases = engine.buildPhrases('activity_property_flate', {
        'android_material_design_spinner': 'Other',
        'etPropertyOnTheFloor': 'Mezzanine',
        'android_material_design_spinner2': '4',
        'android_material_design_spinner3': 'Other',
        'etAccessVia': 'private stairs',
        'android_material_design_spinner4': 'Other',
        'etAccesElevation': 'north side',
      });

      expect(phrases, isNotEmpty);
      expect(phrases.first.toLowerCase(), contains('mezzanine'));
      expect(phrases.first.toLowerCase(), contains('private stairs'));
      expect(phrases.first.toLowerCase(), contains('north side'));
    });
  });

  group('InspectionPhraseEngine - construction roof', () {
    const phraseTexts = <String, String>{};

    test('includes extended roof material and cover type fields in phrases', () {
      const engine = InspectionPhraseEngine(phraseTexts);
      final phrases = engine.buildPhrases('activity_property_roof', {
        'ch1': 'true',
        'ch8': 'true',
        'ch_plastic': 'true',
        'ch16': 'true',
        'etCoveredWithOther': 'zinc',
        'ch6': 'true',
        'ch_slates': 'true',
        'ch17': 'true',
        'etCoveredTypeOther': 'felt shingles',
      });

      // Phase 3: single approved-bank sentence
      // ({D_CONSTRUCTION}::{CONSTRUCTION_ROOF_AREA}) instead of the legacy
      // "Roof type:" label output.
      expect(phrases, hasLength(1));
      final sentence = phrases.single.toLowerCase();
      expect(
        sentence,
        startsWith('the flat roof construction over the main building'),
      );
      expect(sentence, contains('covered in'));
      expect(sentence, contains('concrete'));
      expect(sentence, contains('plastic'));
      expect(sentence, contains('zinc'));
      expect(sentence, contains('tiles'));
      expect(sentence, contains('slates'));
      expect(sentence, contains('felt shingles'));
    });
  });

  group('InspectionPhraseEngine - external wall', () {
    const phraseTexts = <String, String>{};

    test('includes rendered and cladding dropdown context in phrases', () {
      const engine = InspectionPhraseEngine(phraseTexts);
      final phrases = engine.buildPhrases('activity_extended_wall', {
        'ch1': 'true',
        'android_material_design_spinner': 'Fully',
        'android_material_design_spinner2': 'Smooth',
        'ch7': 'true',
        'android_material_design_spinner4': 'Partially',
        'ch11': 'true',
      });

      // Phase 3: approved-bank external wall / finishes / cladding sentences
      // instead of the legacy "Extension walls:" label output.
      expect(phrases, hasLength(3));
      expect(
        phrases[0],
        'The main external walls are built of cavity wall construction.',
      );
      expect(
        phrases[1],
        'Externally, the main walls are fully rendered smooth with painted '
        'finishes.',
      );
      expect(
        phrases[2],
        'The main walls are partially cladded with tiles finishing.',
      );
    });
  });

  group('InspectionPhraseEngine - construction floor', () {
    const phraseTexts = <String, String>{};

    test('uses composition and selected construction checkboxes', () {
      const engine = InspectionPhraseEngine(phraseTexts);
      final phrases = engine.buildPhrases('activity_construction_floor', {
        'android_material_design_spinner': 'Of a mixture of',
        'ch1': 'true',
        'ch5': 'true',
        'etCoveredWithOther': 'resin',
      });

      // Phase 3: approved-bank floor sentence
      // ({D_CONSTRUCTION}::{CONSTRUCTION_FLOOR_AREA}).
      expect(phrases, hasLength(1));
      expect(
        phrases.single,
        'The floors of the property are built of a mixture of suspended '
        'timber and resin floor construction.',
      );
      expect(phrases.single, isNot(contains('of mainly of')));
    });
  });

  group('InspectionPhraseEngine - construction window', () {
    const phraseTexts = <String, String>{};

    test('includes glazing and frame selections with composition', () {
      const engine = InspectionPhraseEngine(phraseTexts);
      final phrases = engine.buildPhrases('activity_construction_window', {
        'android_material_design_spinner': 'A mixture of',
        'ch2': 'true',
        'ch4': 'true',
        'etCoveredWithOther': 'triple',
        'ch5': 'true',
        'ch9': 'true',
        'etWindowMaterialOther': 'composite',
      });

      // Phase 3: single approved-bank window sentence
      // ({D_CONSTRUCTION}::{CONSTRUCTION_WINDOWS_AREA}).
      expect(phrases, hasLength(1));
      final sentence = phrases.single;
      expect(sentence.toLowerCase(), startsWith('the windows are'));
      expect(sentence.toLowerCase(), contains('a mixture of'));
      expect(sentence.toLowerCase(), contains('double'));
      expect(sentence.toLowerCase(), contains('triple'));
      expect(sentence, contains('uPVC'));
      expect(sentence.toLowerCase(), contains('composite'));
      expect(sentence.toLowerCase(), endsWith('units.'));
    });
  });
}
