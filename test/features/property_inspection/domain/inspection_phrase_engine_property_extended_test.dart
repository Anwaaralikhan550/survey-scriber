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

      expect(phrases, hasLength(3));
      expect(phrases[0].toLowerCase(), contains('roof type: flat'));
      expect(phrases[1].toLowerCase(), contains('concrete'));
      expect(phrases[1].toLowerCase(), contains('plastic'));
      expect(phrases[1].toLowerCase(), contains('zinc'));
      expect(phrases[2].toLowerCase(), contains('tiles'));
      expect(phrases[2].toLowerCase(), contains('slates'));
      expect(phrases[2].toLowerCase(), contains('felt shingles'));
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

      expect(phrases, hasLength(3));
      expect(phrases[0].toLowerCase(), contains('extension walls'));
      expect(phrases[1].toLowerCase(), contains('rendered (fully, smooth)'));
      expect(phrases[1].toLowerCase(), contains('painted'));
      expect(phrases[2].toLowerCase(), contains('cladding (partially)'));
      expect(phrases[2].toLowerCase(), contains('tiles'));
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

      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('floors: a mixture of'));
      expect(phrases.first.toLowerCase(), contains('suspended timber'));
      expect(phrases.first.toLowerCase(), contains('resin'));
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

      expect(phrases, hasLength(2));
      expect(phrases[0].toLowerCase(), contains('windows: a mixture of'));
      expect(phrases[0].toLowerCase(), contains('double'));
      expect(phrases[0].toLowerCase(), contains('triple'));
      expect(phrases[1].toLowerCase(), contains('window material:'));
      expect(phrases[1], contains('PVC'));
      expect(phrases[1].toLowerCase(), contains('composite'));
    });
  });
}
