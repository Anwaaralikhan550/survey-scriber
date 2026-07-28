import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';

void main() {
  group('InspectionPhraseEngine - F1 Roof Structure parity', () {
    const phraseTexts = <String, String>{
      '{F_ROOF_STRUCTURE}::{F_ABOUT_ROOF_STRUCTURE}':
          'construction={CONSTRUCTION}|underlining={UNDERLINING_STATUS}|insulation={INSULATION_STATUS}|damp={INSULATION_DAMP}|ventno={VENTILATION_DAMP_NO_VENTILATION}|ventinsuff={VENTILATION_DAMP_IN_SUFFICIENT_VENTILATION}',
      '{F_ABOUT_ROOF_STRUCTURE}::{CONSTRUCTION}':
          'construction-text={RS_ARS_CONSTRUCTION}',
      '{F_ABOUT_ROOF_STRUCTURE}::{UNDERLINING_STATUS_NO_UNDERLINING}':
          'no-underlining',
      '{F_ABOUT_ROOF_STRUCTURE}::{UNDERLINING_STATUS_UNDERLINING_OK}':
          'underlining-ok|{UNDERLINING_MATERIAL}|{ROOF_STRUCTURE_CONDITION}|{UNDERLINING_DEFECT}',
      '{UNDERLINING_STATUS_UNDERLINING_OK}::{UNDERLINING_MATERIAL}':
          'material={RS_ARS_UNDERLINE_MATERIAL}',
      '{UNDERLINING_STATUS_UNDERLINING_OK}::{UNDERLINING_DEFECT}':
          'defect={RS_ARS_UNDERLINE_DEFECT}',
      '{F_ABOUT_ROOF_STRUCTURE}::{ROOF_STRUCTURE_CONDITION}':
          'condition={RS_ARS_CONDITION}',
      '{F_ABOUT_ROOF_STRUCTURE}::{INSULATION_ADEQUATE}': 'insulation-adequate',
      '{F_ABOUT_ROOF_STRUCTURE}::{INSULATION_INADEQUATE}':
          'insulation-inadequate',
      '{F_ABOUT_ROOF_STRUCTURE}::{INSULATION_DAMP}': 'damp={RS_ARS_IRD_DETAIL}',
      '{F_ABOUT_ROOF_STRUCTURE}::{VENTILATION_DAMP_NO_VENTILATION}':
          'vent-none',
      '{F_ABOUT_ROOF_STRUCTURE}::{VENTILATION_DAMP_IN_SUFFICIENT_VENTILATION}':
          'vent-insufficient',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{NOT_INSPECTED}': 'tank-not-inspected',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{WATERL_TANK_MATERIAL_LOCATION}':
          'tank-loc={RS_WT_LOCATION}/mat={RS_WT_MATERIAL}/cond={RS_WT_CONDITION}',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_OK}':
          'tank-insulation-ok',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_NO_INSULATION}':
          'tank-no-insulation',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}':
          'tank-partial-insulation',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{DISUSED_WATER_TANK}':
          'disused-tank=loc:{RS_WT_DISUSED_WATER_TANK_LOCATION}/mat:{RS_WT_DISUSED_WATER_TANK_MATERIAL}',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{ASBESTOS_TANK_MATERIAL}':
          'tank-asbestos-note',
      '{F_ROOF_STRUCTURE_WATER_TANK}::{INSPECTED}':
          '{WATERL_TANK_MATERIAL_LOCATION}|{INSULATION_STATUS_OK}|{REPAIR_TANK_MISSING_COVER}|{REPAIR_TANK_POOR_COVER}|{INSULATION_STATUS_NO_INSULATION}|{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}|{DISUSED_WATER_TANK}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TANK}': 'repair-tank={RSR_RT_WATER_TANK}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TANK_MISSING_COVER}':
          'missing-cover={RSR_RT_MISSING_COVER_MATERIAL}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TANK_POOR_COVER}': 'poor-cover',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TIMBER_STRUCTURE_SOON}':
          'timber-soon={RSR_RTS_STATUS_SOON_DEFECT}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TIMBER_STRUCTURE_NOW}':
          'timber-now={RSR_RTS_STATUS_NOW_DEFECT}',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_INSECT_INFESTATION_NONE}':
          'insects-none',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_INSECT_INFESTATION_MINOR}':
          'insects-minor',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_INSECT_INFESTATION_SEVERE}':
          'insects-severe',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TIMBER_ROT_NONE}': 'rot-minor',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_TIMBER_ROT_SEVERE}': 'rot-severe',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_UNDERSIZE_TIMBER}': 'undersize-timber',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_ROOF_SPREADING}': 'roof-spreading',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_HEAVY_ROOF}': 'heavy-roof',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_REMOVED_CHIMNEY_BREAST_NOT_INSPECTED}':
          'chimney-breast-not-inspected',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}':
          '{INSPECTED_OK}|{POOR_SUPPORT}|{RISK_TO_COLLAPSE}|{DAMP_CHIMNEY}',
      '{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}::{INSPECTED_OK}':
          'chimney-breast-ok',
      '{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}::{POOR_SUPPORT}':
          'chimney-breast-poor-support',
      '{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}::{RISK_TO_COLLAPSE}':
          'chimney-breast-risk-collapse',
      '{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}::{DAMP_CHIMNEY}':
          'chimney-breast-damp',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_PARTY_WALL_PROBLEM_PARTLY_MISSING}':
          'party-wall-partly-missing',
      '{F_ABOUT_ROOF_STRUCTURE}::{REPAIR_PARTY_WALL_PROBLEM_LARGELY_MISSING}':
          'party-wall-largely-missing',
      '{F_ROOF_STRUCTURE_NOT_INSPECTED}::{ROOF_SPACE_NOT_INSPECTED}':
          'not-inspected-ok={RS_NOT_INSPECTED_PROBLEM}',
      '{F_ROOF_STRUCTURE_NOT_INSPECTED}::{DEFECT_NOTED_TO_THE_ROOF}':
          'not-inspected-defect={RS_NOT_INSPECTED_DEFECT_PROBLEM}',
    };

    const engine = InspectionPhraseEngine(phraseTexts);

    test('construction substitutes the raw dropdown phrase directly (no double lead-in)', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {'actv_construction': 'Made of steel'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('construction-text=made of steel'));
    });

    test('underlining OK emits material, condition and defect', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {
          'actv_underlining': 'Underlining',
          'cb_sacking_felt': 'true',
          'actv_roof_structure_condition': 'Reasonable',
          'cb_torn': 'true',
        },
      );
      expect(phrases, hasLength(1));
      final all = phrases.first.toLowerCase();
      expect(all, contains('material=sacking felt'));
      expect(all, contains('condition=reasonable'));
      expect(all, contains('defect=torn'));
    });

    test('underlining OK with nothing checked emits nothing (regression: bare label bug)', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {'actv_underlining': 'Underlining'},
      );
      expect(phrases, isEmpty);
    });

    test('underlining none emits the no-underlining branch', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {'actv_underlining': 'No underlining'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('no-underlining'));
    });

    test('insulation adequate vs inadequate', () {
      final adequate = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {'actv_insulation': 'Adequate'},
      );
      expect(adequate.single.toLowerCase(), contains('insulation-adequate'));

      final inadequate = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {'actv_insulation': 'Inadequate'},
      );
      expect(inadequate.single.toLowerCase(), contains('insulation-inadequate'));
    });

    test('ventilation no-ventilation and insufficient are mutually exclusive (regression: double-branch bug)', () {
      final bothChecked = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {
          'cb_ventilation_related_damp': 'true',
          'cb_none': 'true',
          'cb_damp_noted_ventilation': 'true',
        },
      );
      expect(bothChecked, hasLength(1));
      final text = bothChecked.first.toLowerCase();
      expect(text, contains('vent-none'));
      expect(text, isNot(contains('vent-insufficient')));
    });

    test('ventilation insufficient fires alone when only that checkbox is set', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_about_roof_structure',
        {
          'cb_ventilation_related_damp': 'true',
          'cb_damp_noted_ventilation': 'true',
        },
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('vent-insufficient'));
    });

    test('water tank not inspected', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_water_tank',
        {'cb_not_inspected': 'true'},
      );
      expect(phrases, hasLength(1));
      expect(phrases.first.toLowerCase(), contains('tank-not-inspected'));
    });

    test('water tank asbestos material appends the asbestos note', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_water_tank',
        {'cb_asbestos': 'true'},
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('tank-loc=/mat=asbestos'));
      expect(all, contains('tank-asbestos-note'));
    });

    test('disused water tank resolves location and material', () {
      final phrases = engine.buildPhrases(
        'activity_inside_property_water_tank',
        {
          'cb_disused_water_tank': 'true',
          'cb_plastic_disused': 'true',
          'cb_roof_space': 'true',
        },
      );
      final all = phrases.join(' ').toLowerCase();
      expect(all, contains('disused-tank=loc:roof space/mat:plastic'));
    });

    test('repair timber structure soon vs now', () {
      final soon = engine.buildPhrases(
        'activity_inside_property_repair_timber_structure',
        {'actv_status': 'Repair soon', 'cb_distorted': 'true'},
      );
      expect(soon.single.toLowerCase(), contains('timber-soon=distorted'));

      final now = engine.buildPhrases(
        'activity_inside_property_repair_timber_structure',
        {'actv_status': 'Repair now', 'cb_badly_distorted': 'true'},
      );
      expect(now.single.toLowerCase(), contains('timber-now=badly distorted'));
    });

    test('insect infestation none/minor/severe', () {
      expect(
        engine
            .buildPhrases('activity_inside_property_repair_insect_infestation',
                {'actv_insect_infestation': 'None'})
            .single
            .toLowerCase(),
        contains('insects-none'),
      );
      expect(
        engine
            .buildPhrases('activity_inside_property_repair_insect_infestation',
                {'actv_insect_infestation': 'Minor'})
            .single
            .toLowerCase(),
        contains('insects-minor'),
      );
      expect(
        engine
            .buildPhrases('activity_inside_property_repair_insect_infestation',
                {'actv_insect_infestation': 'Severe'})
            .single
            .toLowerCase(),
        contains('insects-severe'),
      );
    });

    test('chimney breast removed - not inspected vs inspected-poor-support', () {
      final notInspected = engine.buildPhrases(
        'activity_inside_property_repair_removed_chimney_breast',
        {'actv_status': 'Not inspected'},
      );
      expect(notInspected.single.toLowerCase(),
          contains('chimney-breast-not-inspected'));

      final inspected = engine.buildPhrases(
        'activity_inside_property_repair_removed_chimney_breast',
        {'actv_status': 'Inspected', 'cb_poor_support': 'true'},
      );
      expect(
          inspected.single.toLowerCase(), contains('chimney-breast-poor-support'));
    });

    test('party wall partly vs largely missing', () {
      final partly = engine.buildPhrases(
        'activity_inside_property_repair_party_walls',
        {'actv_insect_infestation': 'Partly missing'},
      );
      expect(partly.single.toLowerCase(), contains('party-wall-partly-missing'));

      final largely = engine.buildPhrases(
        'activity_inside_property_repair_party_walls',
        {'actv_insect_infestation': 'Largely missing'},
      );
      expect(
          largely.single.toLowerCase(), contains('party-wall-largely-missing'));
    });
  });
}
