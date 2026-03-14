import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - roof structure water tank parity', () {
    const phraseTexts = <String, String>{
      '{F_ROOF_STRUCTURE_WATER_TANK}::{NOT_INSPECTED}': 'not-inspected',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSPECTED}':
          '{WATERL_TANK_MATERIAL_LOCATION}|{INSULATION_STATUS_OK}|{REPAIR_TANK_MISSING_COVER}|{INSULATION_STATUS_NO_INSULATION}|{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}|{TANK_STOPCOCK}|{DISUSED_WATER_TANK}',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{WATERL_TANK_MATERIAL_LOCATION}':
          'material={RS_WT_MATERIAL};location={RS_WT_LOCATION};condition={RS_WT_CONDITION}',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_OK}': 'insulation-ok',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_NO_INSULATION}':
          'no-insulation',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}':
          'not-adequately-insulated',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{DISUSED_WATER_TANK}':
          'disused-material={RS_WT_DISUSED_WATER_TANK_MATERIAL};disused-location={RS_WT_DISUSED_WATER_TANK_LOCATION}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TANK_MISSING_COVER}':
          'missing-cover={RSR_RT_MISSING_COVER_MATERIAL}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('emits material/location phrase when only one legacy input is filled',
        () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_water_tank',
        <String, String>{
          'cb_plastic': 'true',
        },
      );

      expect(phrases.join(' ').toLowerCase(), contains('material=plastic'));
    });

    test('requires parent tank insulation checkbox for insulation detail text',
        () {
      final withoutParent = engine.buildPhrases(
        'activity_inside_property_water_tank',
        <String, String>{
          'cb_insulation': 'true',
          'cb_not_insulation': 'true',
          'cb_not_adequately_insulated': 'true',
        },
      );

      expect(withoutParent.join(' ').toLowerCase(),
          isNot(contains('insulation-ok')));
      expect(withoutParent.join(' ').toLowerCase(),
          isNot(contains('no-insulation')));
      expect(
        withoutParent.join(' ').toLowerCase(),
        isNot(contains('not-adequately-insulated')),
      );

      final withParent = engine.buildPhrases(
        'activity_inside_property_water_tank',
        <String, String>{
          'cb_not_insulated': 'true',
          'cb_insulation': 'true',
          'cb_not_insulation': 'true',
          'cb_not_adequately_insulated': 'true',
        },
      );

      final all = withParent.join(' ').toLowerCase();
      expect(all, contains('insulation-ok'));
      expect(all, contains('no-insulation'));
      expect(all, contains('not-adequately-insulated'));
    });

    test('emits disused water tank phrase when only legacy material is filled',
        () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_water_tank',
        <String, String>{
          'cb_disused_water_tank': 'true',
          'cb_plastic_disused': 'true',
        },
      );

      expect(
        phrases.join(' ').toLowerCase(),
        contains('disused-material=plastic'),
      );
    });
  });
}
