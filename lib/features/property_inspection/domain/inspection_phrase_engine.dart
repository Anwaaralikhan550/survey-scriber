import 'dart:convert';

import '../../../core/utils/number_to_words.dart';

part 'inspection_verbatim_spec.dart';

class InspectionPhraseEngine {
  const InspectionPhraseEngine(this._phraseTexts);

  final Map<String, String> _phraseTexts;

  /// Read-only view of the approved phrase bank backing this engine.
  /// Consumed by the report layer to derive paragraph composition from the
  /// master templates (see ParagraphComposer).
  Map<String, String> get phraseTexts => Map.unmodifiable(_phraseTexts);

  List<String> buildPhrases(String screenId, Map<String, String> answers) {
    return _refinePhrases(
      screenId,
      answers,
      [
        ..._verbatimPhrases(screenId, answers, first: true),
        ..._buildPhrasesRaw(screenId, answers),
        ..._verbatimPhrases(screenId, answers, first: false),
      ],
    );
  }

  List<String> _buildPhrasesRaw(
    String screenId,
    Map<String, String> answers,
  ) {
    final dynamicMatch = _matchDynamicSectionE(screenId, answers);
    if (dynamicMatch != null) return dynamicMatch;
    switch (screenId) {
      case 'activity_party_disclosure':
        return _partyDisclosure(answers);
      case 'activity_property_weather':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_status':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_facing':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_limitation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_covering':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rainwater_goods':
        return _rainwaterGoodsMainScreen(answers);
      case 'activity_outside_property_windows':
        return _windowsMainScreen(answers);
      case 'activity_outside_property_chimney_main_screen':
        return _outsideChimneyMainScreen(answers);
      case 'activity_outside_property_roof_covering_main':
        return _outsideRoofCoveringMainScreen(answers);
      case 'activity_outside_property_rainwater_goods_main_screen':
        return _rainwaterGoodsMainScreen(answers);
      case 'activity_outside_property_main_walls_main_screen':
        return _outsideMainWallsMainScreen(answers);
      case 'activity_outside_property_windows_main_screen':
        return _windowsMainScreen(answers);
      case 'activity_outside_property_outside_doors_main_screen':
        return _outsideDoorsMainScreen(answers);
      case 'activity_outside_property_conservatory_porch_main_screen':
        return _outsideConservatoryPorchMainScreen(answers);
      case 'activity_outside_property_other_joinery_and_finishes_main_screen':
        // RICS L2 rewrite (Phase 2B, E8): this screen's own
        // "Condition Rating" dropdown (1/2/3) was never read - the case
        // routed only to the About content, so {CONDITION_RATING} was
        // dead regardless of what the surveyor selected. Real gap, not
        // guessed: the tree screen has the field, nothing consumed it.
        return _otherJoineryConditionRating(answers);
      case 'activity_outside_property_other_main_screen':
        return _outsideOtherMainScreen(answers);
      case 'activity_grounds_garage_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{H_GARAGE}');
      case 'activity_grounds_other_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{H_OTHER}');
      case 'activity_grounds_other_area_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{H_OTHER_AREA}');
      case 'activity_grounds_limitations':
        return _groundsLimitations(answers);
      case 'activity_grounds_garage':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_garage_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_garage_garage_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_garage_roof_timber_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_garage_safety_hazard_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_grounds':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_front_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_front_garden__rear_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_front_garden__side_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_front_garden__other_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_front_garden__communal_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_shared_access':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_large_outbuildings':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_private_road':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_other_repair_legal_issues':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_other_repair_shrinkable_clay':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_repair_fence':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_repair_shed':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_other_repair_outbuilding':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_other_repair_retaining_walls':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_other_repair_nearby_trees':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_right_of_way':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_knotweed':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_common_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_lifts':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_flooding':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_emf':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_area_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_electricity_main_screen':
        return _servicesElectricityMain(answers);
      case 'activity_service_about_electricity':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_solar_power':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_electricity_repair_loose_panels':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_electricity_repair_electrical_hazard':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_electricity_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_gas_oil_main_screen':
        return _servicesGasOilMain(answers);
      case 'activity_services_gas_oil':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_main_gas':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_oil':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_gas_oil_repair_gas_meter':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_gas_oil_repair_storage_tank_pipework':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_gas_oil_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{G_WATER}');
      case 'activity_services_water_main_water':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_heating_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{G_HEATING}');
      case 'activity_services_heating_about_heating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_heating_repair_main_screen':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_heating_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{G_DRAINAGE}');
      case 'activity_services_drainage':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_chamber_cover':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_chamber_walls':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_chamber_pipes':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_soil_and_vent':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_roots_in_chamber':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_gullies':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_repair_defect_dampness':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_common_services_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{G_COMMON_SERVICES}');
      case 'activity_services_shared_services':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_shared_services_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{G_WATER_HEATING}');
      case 'activity_water_heating_communal_hot_water':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_gas_heating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_electric_heating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_solar_power':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_repair_leaking_cylinder':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_repair_loose_panels':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_limitation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_roof_structure_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{F_ABOUT_ROOF_STRUCTURE}');
      case 'activity_inside_property_weather_condition':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_loft_converted':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_about_roof_structure':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_water_tank':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_tank':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_timber_structure':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_insect_infestation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_timber_rot':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_under_size_timber':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_roof_spreading':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_heavy_roof':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_removed_chimney_breast':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_repair_party_walls':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_roof_structure_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{F_CEILINGS}');
      case 'inside_property_ceilings_about_ceilings':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_cracks':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_contains_asbestos':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_polystyrene':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_heavy_paper_lining':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_repairs_ceilings':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_repairs_ornamental_plaster':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_ceilings_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_floors_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{F_FLOORS}');
      case 'activity_in_side_property_floors':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_about_floor':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_creaking':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_tiles':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_loose_floorboards':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_timber_decay':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_timber_infection':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_dampness':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_floor_ventilation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_repair_floor_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_repair_floor_laminate_wood_floor':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_repair_floor_vibration':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_repair_sloping_floor':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_repair_uneven_floor':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_floors_repair_not_inspetcted':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_fireplaces_main_screen':
        return _fireplacesMain(answers);
      case 'activity_in_side_property_fire_places_diffrent':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places__gas_fire':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places__imitation_system':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places__wood_burning_stove':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places__electric_fire':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places__other':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_repair_fire_place':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_repair_damage_grate':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_repair_damage_surround':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_repair_blocked_fireplace':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_repair_removed_cb':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_repair_boiler_flue':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_fire_places_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_built_in_fittings_main_screen':
      case 'activity_inside_property_other_fittings_main_screen':
        return _builtInFittingsMain(answers);
      case 'activity_in_side_property_built_in_fittings':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_built_in_fittings_repair_fittings':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_built_in_fittings_repair_defective_sealants':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_built_in_fittings_repair_moulding_noted':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_built_in_fittings_repair_water_seepage':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_built_in_fittings_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_woodwork_main_screen':
      case 'activity_inside_property_wood_work_main_screen':
        return _woodWorkMainScreen(answers);
      case 'activity_in_side_property_wood_work':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_second':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_cupboards':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_door_sampling':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_ww_wood_work_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_repair_balusters':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_repair_infestation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_repair_damp_timber':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_damaged_lock':
      case 'activity_in_side_property_wood_work_damaged_lock__damaged_lock':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_bathroom_fittings_main_screen':
        return _bathroomFittingsMain(answers);
      case 'activity_in_side_property_bathroom_fittings_second':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_extractor_fan':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_extractor_fan__no_extractor_fan_installed':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_leaking':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_sealant':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_mould':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_wood_rot':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_cubicle_safety_glass_rating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fittings_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_bathroom_fitting_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_main_screen':
        return _insideOtherMainScreen(answers);
      case 'activity_in_side_property_other_communal_area':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_other_basement':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_other_cellar':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_no_access':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_no_access__no_access':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_not_in_use':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_not_in_use__not_in_use':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_inspected__used_as':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_not_habitable':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_not_habitable__not_habitable':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_flooded':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_flooded__flooded':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_damp':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_damp__serious_damp':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_joists_decay':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_celler_joists_decay__joists_decay':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_other_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_other_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_walls_and_partitions_main_screen':
        return _conditionRatingNotes(answers,
            ratingKey: 'android_material_design_spinner4',
            master: '{F_WALLS_AND_PARTITIONS}');
      case 'activity_inside_property_wap_walls':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_repair_condensation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_dampness':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_movement_cracks':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_repair_wall_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_repair_sealants':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_removed_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wap_repair_removed_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_inside_property_wap_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_stacks':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_location':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rendering':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_water_proofing':
        // Flashings / flaunching / pointing / pots: PDF-driven rules.
        return const [];
      case 'activity_outside_property_condition':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_shared_chimney':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_leaning_chimney':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_chimney_partial_view':
      case 'activity_outside_property_chimney_removed_chimney_stack':
      case 'activity_outside_property_chimney_removed_pots':
      case 'activity_outside_property_chimney_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_repair_flashing':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_chimney_repair_flaunching':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_repair_chimney_pots':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_repair_chimney_repointing':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_repair_chimney_disrepair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_repair_chimney_dish_aerial':
      case 'activity_outside_property_repair_chimney_dish_aerial__satellite':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg__repair_pipes_gutters':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg_about':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_rwg_weather_condition':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg_blocked_rwg':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg_blocked_gullies':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg_open_runoffs':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rain_water_goods_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_about_roof_layout':
      case 'outside_property_about_roof_layout__flat':
      case 'outside_property_about_roof_layout__mansard':
      case 'outside_property_about_roof_layout__other':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_weather_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_flashing_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_ridge_tiles_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_hip_tiles_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_parapet_wall_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_deflection_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_asbestos_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_roof_structure_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_roof_spreading_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_tiles':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_poor_roof':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_spreading_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_flat_roof':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_parapet_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_verge':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_valley_gutters':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_walls_about_wall':
      case 'activity_outside_property_main_walls_about_wall__cavity_brick_wall':
      case 'activity_outside_property_main_walls_about_wall__cavity_block_wall':
      case 'activity_outside_property_main_walls_about_wall__cavity_stud_wall':
      case 'activity_outside_property_main_walls_about_wall__other':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_walls_cladding':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_walls_dpc':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_walls_damp':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_walls_removed_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_walls_movements':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_thin_slim_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_cavity_wall_insulation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_near_by_tress':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_spalling':
      case 'activity_outside_property_main_wall_repairs_spalling__causing_damp':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_render':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_pointing':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_lintel':
      case 'activity_outside_property_main_wall_repairs_lintel__door':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_window_sills':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_main_wall_repairs_wall_the_repair':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_weathered_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_aboutwindow':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_safety_glass_rating':
        // Legacy no-op (intentional, locked by test suite): this screen's
        // fields (actv_status/actv_condition) are the SAME ones already
        // consumed by the windows "about" screen's safety-glass clause.
        // Wiring it here would duplicate that sentence in the assembled
        // report, not fill a gap.
        return const [];
      case 'activity_outside_property_windows_wall_sealing':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_sill_projection':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_velux_window':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_repairs_repair_window':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_repairs_failed_glazing_location':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_windows_repairs_no_fire_escape_risk':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_out_side_doors_about_doors':
      case 'activity_outside_property_out_side_doors_about_doors__timber':
      case 'activity_outside_property_out_side_doors_about_doors__aluminium':
      case 'activity_outside_property_out_side_doors_about_doors__steel':
      case 'activity_outside_property_out_side_doors_about_doors__other':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__rear_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__side_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__patio_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__garage_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__other_door':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_location_construction':
      case 'activity_outside_property_conservatory_porch_location_construction__location_and_construction':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_roof':
      case 'activity_outside_property_conservatory_porch_roof__roof':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_windows':
      case 'activity_outside_property_conservatory_porch_windows__windows':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_doors':
      case 'activity_outside_property_conservatory_porch_doors__doors':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_floor':
      case 'activity_outside_property_conservatory_porch_floor__floor':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_safety_glass_rating':
      case 'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_conservatory_porch_flashing_layout':
      case 'outside_property_conservatory_porch_flashing_layout__roof_flashing_with_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_porch_open_to_building':
      case 'activity_outside_property_porch_open_to_building__open_to_building':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_porch_condition':
      case 'activity_outside_property_porch_condition__condition':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_porch_poor_condition':
      case 'activity_outside_property_porch_poor_condition__poor_condition':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_conservatory_porch_repairs':
      case 'activity_outside_property_conservatory_porch_repairs__walls':
      case 'activity_outside_property_conservatory_porch_repairs__windows':
      case 'activity_outside_property_conservatory_porch_repairs__door_glazing':
      case 'activity_outside_property_conservatory_porch_repairs__window_glazing':
      case 'activity_outside_property_conservatory_porch_repairs__roof_glazing':
      case 'activity_outside_property_conservatory_porch_repairs__floor':
      case 'activity_outside_property_conservatory_porch_repairs__rainwater_goods':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_about_joinery_and_finishes':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_joinery_finishes_condition':
      case 'activity_outside_property_other_joinery_fininshes_condition':
        // This screen's `actv_condition` field is a numeric 1/2/3 dropdown
        // (see inspection_tree.json), not the descriptive good/reasonable/
        // fair/poor value _otherJoineryCondition expects - routing it there
        // produced nonsense like "appear in 1 condition". Route to the
        // numeric-rating handler instead (same one the main E8 screen
        // correctly uses), which this screen's field actually matches.
        // The two screens duplicating the same rating concept is a
        // separate, larger tree-structure question, flagged for a product
        // decision rather than resolved here.
        return _otherJoineryConditionRating(answers);
      case 'activity_outside_property_other_joinery_and_finishes_repairs':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_joinery_finishes_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_communal_area':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_issues_regulation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_issues_glazed_sections':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_issues_other_matters':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_risks_risk_to_building_':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_risks_other_':
        return _risksOther(answers);
      case 'activity_risks_repair_or_improve':
        return _risksRepairOrImprove(answers);

      // ── Section D: About the Property ──
      case 'activity_property_type':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_construction':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_built_year':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_roof':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_ground_area':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_extended':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_extended_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_parking':
      case 'activity_parking__parking':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_front_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_rear_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_communal_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_converted':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_flate':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_construction_floor':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_construction_window':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_gated_community':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_energy_effiency':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_energy_environment_impect':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_estate_location':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_location':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_facelities':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_local_environment':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_private_road':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_property_is_noisy_area':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_topography':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_internal_wall':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_listed_building':
      case 'activity_listed_building__listed_building':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_other_service':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_accommodation_schedule':
        return _accommodationSchedule(answers);

      // ── Section H: standalone garden screens ──
      case 'activity_grounds_other_rear_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_side_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_other_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_grounds_other_communal_garden':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)

      // ── Section G: services detail screens ──
      case 'activity_services_water_disused_tank':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_water_tank':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_insulation':
      case 'services_water_insulation':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_heating_radiators':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_heating_other_heating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_heating_old_boiler':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_repair_main_screen':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_repair_asbestos':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_repair_cover_screen':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_repair_water_tank_screen':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_chamber_lids':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_drainage_public_system':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_services_water_heating_cylinder':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)

      // ── Section F: woodwork sub-screens ──
      case 'activity_in_side_property_wood_work_creaking_stairs':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_glazed_internal_doors':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_open_threads':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_out_of_square_doors':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_in_side_property_wood_work_rocking_handrails':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)

      // ── Section F: joinery variant screens ──
      case 'activity_outside_property_other_about_joinery_and_finishes__other_joinery_and_finishes':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_joinery_and_finishes_repairs__repairs':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_other_joinery_finishes_not_inspected__not_inspected':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)

      // ── Section R: room/floor screens ──
      case 'activity_no_of_rooms':
        return _roomCounts(answers, 'Lower Ground');
      case 'activity_no_of_rooms__ground':
        return _roomCounts(answers, 'Ground');
      case 'activity_no_of_rooms__first':
        return _roomCounts(answers, 'First');
      case 'activity_no_of_rooms__second':
        return _roomCounts(answers, 'Second');
      case 'activity_no_of_rooms__third':
        return _roomCounts(answers, 'Third');
      case 'activity_no_of_rooms__other':
        return _roomCounts(answers, 'Other');
      case 'activity_no_of_rooms__roof_space':
        return _roomCounts(answers, 'Roof Space');

      // ── Section E: roof covering + door repair screens ──
      case 'activity_outside_property_roof_covering_summary':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_covering_main_screen':
        return _roofCoveringMainScreen(answers);
      case 'activity_outside_property_out_side_doors_repairs_failed_glazing_location':
      case 'activity_outside_property_out_side_doors_repairs_inadequate_lock_location':
        // Legacy no-op (intentional, locked by test suite): these screens
        // share checkbox fields (cb_has_failed_glazing_45,
        // cb_has_inadequate_lock_89, location checkboxes) with the main
        // "repair_out_side_doors" repair screen, which already narrates
        // them. Wiring a second handler here would duplicate that repair
        // sentence in the assembled report, not fill a gap.
        return const [];
      case 'activity_outside_property_out_side_safety_glass_rating':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_out_side_doors_wall_sealing':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)

      // ── Section A: overall opinion ──
      case 'activity_over_all_openion':
        return _overallOpinion(answers);

      // ── Section K: floor/site plan sketches ──
      case 'activity_capture_floor_site_plan_sketches':
        return _resolve('{K_FLOOR_SITE_PLAN_SKETCHES}');
      default:
        return const [];
    }
  }

  List<String> _refinePhrases(
    String screenId,
    Map<String, String> answers,
    List<String> phrases,
  ) {
    if (screenId.startsWith('activity_no_of_rooms')) {
      // Accommodation is structured report data and is rendered as a table.
      return const [];
    }

    final thickness = (answers['et_thickness'] ?? '').trim();
    final validThickness = RegExp(r'^\d+(?:\.\d+)?$').hasMatch(thickness);
    final result = <String>[];

    for (final original in phrases) {
      var phrase = original.trim();
      if (phrase.isEmpty ||
          RegExp(r'^status\s*:\s*(?:yes|no|true|false)\.?$',
                  caseSensitive: false)
              .hasMatch(phrase)) {
        continue;
      }
      if (!validThickness && thickness.isNotEmpty) {
        phrase = phrase.replaceAll('$thickness mm ', '');
      }
      phrase = phrase
          .replaceAll('factory made trusses', 'factory-made roof truss')
          .replaceAll('is other construction', 'is of other construction')
          .replaceAll('timber cladded', 'timber-clad')
          .replaceAll('weathered board', 'weatherboarding');
      phrase = phrase.replaceAll(
        'The underside of the roof slope has no felt underlining or timber boarding installed. The absence of such undercover could result in water leakage, lower internal temperatures, higher heating costs, condensation, and mould growth. No repair is currently needed. I will recommend that you contact a qualified person to inspect the roof covering to ascertain its water tightness. The property must be maintained in the normal way.',
        'No roofing underlay or timber boarding was visible beneath the roof covering. This reduces the secondary protection available against wind-driven rain and may increase the risk of water penetration, condensation and heat loss. No immediate repair is required solely because an underlay is absent, but a competent roofing contractor should confirm the watertightness of the covering and advise on any work required.',
      );

      phrase = phrase.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (phrase.isNotEmpty) result.add(phrase);
    }
    return result;
  }

  /// Generic "main screen" condition-rating + notes emitter shared by
  /// several unrelated sections. [master] selects that screen's approved
  /// bank family (e.g. `{H_GARAGE}`, `{F_CEILINGS}`) so the rating/notes
  /// sentences match the approved wording instead of a bare hardcoded
  /// "Condition rating: X." fallback.
  List<String> _conditionRatingNotes(
    Map<String, String> answers, {
    required String ratingKey,
    String notesKey = 'ar_etNote',
    String? master,
  }) {
    final rating = (answers[ratingKey] ?? '').trim();
    final notes = (answers[notesKey] ?? '').trim();
    final phrases = <String>[];
    if (rating.isNotEmpty) {
      final template = master == null ? '' : _sub(master, '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        phrases.addAll(_splitResolved(
          template.replaceAll(RegExp(r'\{[A-Z0-9_]+\}'), rating),
        ));
      } else {
        phrases.add('Condition rating: $rating.');
      }
    }
    if (notes.isNotEmpty) {
      final template = master == null ? '' : _sub(master, '{NOTES}');
      if (template.isNotEmpty) {
        phrases.addAll(_splitResolved(
          template.replaceAll(RegExp(r'\{[A-Z0-9_]+\}'), notes),
        ));
      } else {
        phrases.add('Notes: $notes');
      }
    }
    return phrases;
  }

  List<String> _rainwaterGoodsMainScreen(Map<String, String> answers) {
    final phrases = _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'actv_condition_rating',
      phraseCodeForRating: '{E_RAINWATER_GOODS_ABOUT}',
      ratingSubCode: '{RWG_CONDITION_RATING}',
      ratingPlaceholder: '{RWG_CONDITION_RATING}',
      phraseCodeForNotes: '{E_RAINWATER_GOODS_ABOUT}',
      notesSubCode: '{RWG_NOTES}',
      notesPlaceholder: '{RWG_NOTES}',
    );
    if (_isChecked(answers['cb_shared_rwg']) ||
        _isChecked(answers['cb_Shared_RWG'])) {
      final shared =
          _sub('{E_RAINWATER_GOODS_ABOUT}', '{RAINWATER_GOODS_SHARED}');
      if (shared.isNotEmpty) {
        phrases.addAll(_split(_normalize(shared)));
      }
    }
    return phrases;
  }

  List<String> _windowsMainScreen(Map<String, String> answers) {
    final phrases = _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_WINDOWS_REPAIR}',
      ratingSubCode: '{WINDOW_CONDITION_RATING}',
      ratingPlaceholder: '{WINDOW_CONDITION_RATING}',
      phraseCodeForNotes: '{E_WINDOWS_REPAIR}',
      notesSubCode: '{WINDOW_NOTES}',
      notesPlaceholder: '{WINDOW_NOTES}',
    );
    return phrases;
  }

  List<String> _outsideChimneyMainScreen(Map<String, String> answers) {
    return _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_CHIMNEY_REPAIR_CONDITION_RATING}',
      ratingSubCode: '{CONDITION_RATING}',
      ratingPlaceholder: '{CS_CONDITION_RATING}',
      phraseCodeForNotes: '{E_CHIMNEY_REPAIR_NOTES}',
      notesSubCode: '{NOTES}',
      notesPlaceholder: '{CS_INSPECTION_NOTES}',
    );
  }

  List<String> _outsideRoofCoveringMainScreen(Map<String, String> answers) {
    return _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_ROOF_COVERING_REPAIR}',
      ratingSubCode: '{E_RC_CONDITION_RATING}',
      ratingPlaceholder: '{RC_CONDITION_RATING}',
      phraseCodeForNotes: '{E_ROOF_COVERING_REPAIR}',
      notesSubCode: '{E_RC_NOTES}',
      notesPlaceholder: '{RC_NOTES}',
    );
  }

  List<String> _outsideMainWallsMainScreen(Map<String, String> answers) {
    return _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_MAIN_WALLS_REPAIR}',
      ratingSubCode: '{WALLS_CONDITION_RATING}',
      ratingPlaceholder: '{MAIN_WALL_CONDITION_RATING}',
      phraseCodeForNotes: '{E_MAIN_WALLS_REPAIR}',
      notesSubCode: '{MAIN_WALL_NOTES}',
      notesPlaceholder: '{MAIN_WALL_NOTES}',
    );
  }

  List<String> _outsideDoorsMainScreen(Map<String, String> answers) {
    return _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_OUTSIDE_DOORS}',
      ratingSubCode: '{CONDITION_RATING}',
      ratingPlaceholder: '{OSD_CONDITION_RATING}',
      phraseCodeForNotes: '{E_OUTSIDE_DOORS}',
      notesSubCode: '{NOTES}',
      notesPlaceholder: '{OSD_NOTES}',
    );
  }

  List<String> _outsideConservatoryPorchMainScreen(
      Map<String, String> answers) {
    return _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_CONSERVATORY_PORCHES}',
      ratingSubCode: '{CP_CONDITION_RATING}',
      ratingPlaceholder: '{CP_CONDITION_RATING}',
      phraseCodeForNotes: '{E_CONSERVATORY_PORCHES}',
      notesSubCode: '{CP_NOTES}',
      notesPlaceholder: '{CP_NOTES}',
    );
  }

  List<String> _outsideOtherMainScreen(Map<String, String> answers) {
    return _legacySectionRatingNotes(
      answers: answers,
      ratingKey: 'android_material_design_spinner4',
      phraseCodeForRating: '{E_OTHER}',
      ratingSubCode: '{OTHER_CONDITION_RATING}',
      ratingPlaceholder: '{OTHER_CONDITION_RATING}',
      phraseCodeForNotes: '{E_OTHER}',
      notesSubCode: '{OTHER_NOTES}',
      notesPlaceholder: '{OTHER_NOTES}',
    );
  }

  List<String> _legacySectionRatingNotes({
    required Map<String, String> answers,
    required String ratingKey,
    String notesKey = 'ar_etNote',
    required String phraseCodeForRating,
    required String ratingSubCode,
    required String ratingPlaceholder,
    required String phraseCodeForNotes,
    required String notesSubCode,
    required String notesPlaceholder,
  }) {
    final phrases = <String>[];
    final rating = (answers[ratingKey] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub(phraseCodeForRating, ratingSubCode);
      if (template.isNotEmpty) {
        template = template.replaceAll(ratingPlaceholder, rating);
        phrases.addAll(_split(_normalize(template)));
      }
      // RICS L2 numeric rating definition (Condition rating 1/2/3): a fixed
      // explanatory sentence per rating value, shared by every section that
      // migrates its bank to include `{CONDITION_RATING_1|2|3}`. Resolves to
      // nothing (backward compatible) for sections not yet migrated.
      if (RegExp(r'^[123]$').hasMatch(rating)) {
        final ratingDef = _sub(phraseCodeForRating, '{CONDITION_RATING_$rating}');
        if (ratingDef.isNotEmpty) {
          phrases.addAll(_split(_normalize(ratingDef)));
        }
      }
    }
    final notes = (answers[notesKey] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub(phraseCodeForNotes, notesSubCode);
      if (template.isNotEmpty) {
        template = template.replaceAll(notesPlaceholder, notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _partyDisclosure(Map<String, String> answers) {
    final value =
        (answers['android_material_design_spinner'] ?? '').toLowerCase().trim();
    if (value == 'none') {
      return _resolve('{PARTY_DISCLOSURES_NONE}');
    }
    if (value == 'conflict') {
      return _resolve('{PARTY_DISCLOSURES_CONFLICT}');
    }
    return const [];
  }

  List<String> buildStaticSubPhrases(String phraseCode, String subCode) {
    final template = subCode.isEmpty
        ? (_phraseTexts[phraseCode] ?? '')
        : _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _resolve(String code) {
    final text = _phraseTexts[code] ?? '';
    if (text.isEmpty) return const [];
    return _split(_normalize(text));
  }

  String _sub(String phraseCode, String subCode) {
    return _phraseTexts['$phraseCode::$subCode'] ?? '';
  }

  // ── RICS Level 2 rebuild — reusable machinery (additive) ──────────────
  // These helpers implement the new Master Phrase Library's cross-cutting
  // conventions. They are wired per element during the section-by-section
  // L2 migration; unused until a section is migrated.

  /// RICS L2 dual condition rating. The new library specifies BOTH a
  /// per-element **descriptive** grade (good / reasonable / fair / poor /
  /// very poor, captured on `actv_condition`) AND a per-section **numeric**
  /// rating 1/2/3 (captured on `android_material_design_spinner4`) that
  /// carries a fixed RICS definition sentence.
  ///
  /// Both are emitted from the element's approved bank family [master]:
  ///  - `{master}::{CONDITION_DESCRIPTIVE}` — "Where visible, the {ELEMENT}
  ///    appears in {DESC} condition." (`{L2_DESC}` slot filled from the
  ///    descriptive dropdown);
  ///  - `{master}::{CONDITION_RATING_1|2|3}` — the numeric rating's fixed
  ///    RICS definition paragraph.
  /// Missing answers are skipped (no empty-slot fragments). Falls back to
  /// nothing when the bank has no L2 templates yet, so it is safe to wire
  /// before a section's phrase text has been migrated.
  List<String> _l2ConditionRating(
    Map<String, String> answers, {
    required String master,
    String descriptiveKey = 'actv_condition',
    String numericKey = 'android_material_design_spinner4',
  }) {
    final phrases = <String>[];
    final desc = _cleanLower(answers[descriptiveKey]);
    if (desc.isNotEmpty) {
      final template = _sub(master, '{CONDITION_DESCRIPTIVE}');
      if (template.isNotEmpty) {
        phrases.addAll(_splitResolved(template.replaceAll('{L2_DESC}', desc)));
      }
    }
    final numeric = (answers[numericKey] ?? '').trim();
    if (numeric.isNotEmpty && RegExp(r'^[123]$').hasMatch(numeric)) {
      final def = _sub(master, '{CONDITION_RATING_$numeric}');
      if (def.isNotEmpty) {
        phrases.addAll(_splitResolved(def));
      }
    }
    return phrases;
  }

  /// RICS L2 element-narrative composer. Each L2 element is authored in the
  /// bank as an ordered set of sub-templates that follow a fixed skeleton
  /// (Description → Inspection Limitations → labelled sub-topics → Defects →
  /// General Maintenance). This resolves [subCodes] in order from [master],
  /// fills each sub-template's option-slots from [answers] via [slotFields]
  /// (placeholder token → answer field id, value lower-cased), and drops any
  /// sub-template that is empty in the bank or whose *required* slot is
  /// unanswered — so no empty-slot fragment ever reaches the report.
  ///
  /// A sub-code prefixed with `?` is optional: emitted only when at least one
  /// of its slot fields is answered (used for the "or"-branch / defect
  /// sub-topics that only appear when the surveyor recorded something).
  List<String> _composeL2Element(
    Map<String, String> answers, {
    required String master,
    required List<String> subCodes,
    Map<String, String> slotFields = const {},
  }) {
    final out = <String>[];
    for (final rawCode in subCodes) {
      final optional = rawCode.startsWith('?');
      final code = optional ? rawCode.substring(1) : rawCode;
      var template = _sub(master, code);
      if (template.isEmpty) continue;

      // Substitute this sub-template's placeholders from the answer slots.
      var missingRequired = false;
      var anySlotAnswered = false;
      final tokens = RegExp(r'\{[A-Z0-9_]+\}')
          .allMatches(template)
          .map((m) => m.group(0)!)
          .toSet();
      for (final token in tokens) {
        final field = slotFields[token];
        if (field == null) continue; // not a data slot (structural placeholder)
        final v = _cleanLower(answers[field]);
        if (v.isEmpty) {
          missingRequired = true;
        } else {
          anySlotAnswered = true;
          template = template.replaceAll(token, v);
        }
      }
      if (optional && !anySlotAnswered) continue;
      if (!optional && missingRequired) continue;
      out.addAll(_splitResolved(template));
    }
    return out;
  }

  /// Normalises + splits a resolved template, and tidies gaps left by
  /// intentionally blank slots (e.g. " ." -> "." and " ," -> ",").
  List<String> _splitResolved(String resolved) {
    final tidied = _normalize(resolved)
        .replaceAllMapped(RegExp(r'\s+([.,;:])'), (m) => m.group(1)!)
        .replaceAll(RegExp(r' {2,}'), ' ');
    return _split(tidied);
  }

  List<String> _otherJoineryConditionRating(Map<String, String> answers) {
    final rating = _firstNonEmpty(answers, const ['actv_condition', 'llMainContainer']);
    if (rating.isEmpty) return const [];
    final template =
        _sub('{E_OTHER_JOINERY_AND_FINISHES}', '{CONDITION_RATING}');
    if (template.isEmpty) return const [];
    return _split(_normalize(
        template.replaceAll('{OJAF_CONDITION_RATING}', rating)));
  }

  List<String> _groundsLimitations(Map<String, String> answers) {
    final noRestrictions = _isChecked(answers['cb_no_restrictions']);
    final noRearAccess = _isChecked(answers['cb_no_rear_access']);
    var template = _sub('{H_GROUNDS}', '{H_LIMITATIONS_STANDARD_TEXT}');
    if (template.isEmpty) return const [];
    final restrictionsText = noRestrictions
        ? _sub('{H_GROUNDS}', '{LIMITATIONS_NO_RESTRICTIONS}')
        : '';
    final rearText =
        noRearAccess ? _sub('{H_GROUNDS}', '{LIMITATIONS_NO_REAR_ACCESS}') : '';
    template = template
        .replaceAll('{LIMITATIONS_NO_RESTRICTIONS}', restrictionsText)
        .replaceAll('{LIMITATIONS_NO_REAR_ACCESS}', rearText);
    return _split(_normalize(template));
  }

  List<String> _servicesElectricityMain(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_ELECTRICITY}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{ELE_CON_RT}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_ELECTRICITY}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{ELE_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesGasOilMain(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_GAS_AND_OIL}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAO_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_GAS_AND_OIL}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAO_NOTE}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _fireplacesMain(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = _cleanLower(answers['android_material_design_spinner4']);
    if (rating.isNotEmpty) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{FAC_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{FAC_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _fireplacesLocations(Map<String, String> answers) {
    final locations = _labelsFor(
      [
        'cb_lounge',
        'cb_reception',
        'cb_dining_room',
        'cb_kitchen',
        'cb_bedroom',
        'cb_other_1073'
      ],
      answers,
      {
        'cb_lounge': 'lounge',
        'cb_reception': 'reception(s)',
        'cb_dining_room': 'dining room',
        'cb_kitchen': 'kitchen',
        'cb_bedroom': 'bedroom(s)',
        'cb_other_1073': 'other',
      },
    );
    _addOther(answers, 'cb_other_1073', 'et_other_405', locations);
    return locations;
  }

  List<String> _builtInFittingsMain(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = _cleanLower(answers['android_material_design_spinner4']);
    if (rating.isNotEmpty) {
      var template = _sub('{F_BUILT_IN_FITTINGS}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{BIF_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{F_BUILT_IN_FITTINGS}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{BIF_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _woodWorkMainScreen(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{F_WOOD_WORK}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WW_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{F_WOOD_WORK}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WW_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _insideOtherMainScreen(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{F_OTHER}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{OTH_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{F_OTHER}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{OTH_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  Map<String, String> _normalizeLegacyInsideOtherAnswers(
      Map<String, String> answers) {
    final normalized = Map<String, String>.from(answers);

    final noAccessOther = (normalized['et_other_117'] ?? '').trim();
    if (_isChecked(normalized['cb_other_858']) || noAccessOther.isNotEmpty) {
      normalized['cb_other_704'] = 'true';
    }
    if (noAccessOther.isNotEmpty) {
      normalized['et_other_412'] = noAccessOther;
    }

    if (_isChecked(normalized['cb_to_the_lower_walls_of_24'])) {
      normalized['cb_to_the_lower_walls_of'] = 'true';
    }
    if (_isChecked(normalized['cb_to_the_upper_walls_of_82'])) {
      normalized['cb_to_the_upper_walls_of'] = 'true';
    }
    if (_isChecked(normalized['cb_throughout_66'])) {
      normalized['cb_throughout'] = 'true';
    }
    if (_isChecked(normalized['cb_to_exposed_floor_joists_in_65'])) {
      normalized['cb_to_exposed_floor_joists_in'] = 'true';
    }

    final dampOther = (normalized['et_other_889'] ?? '').trim();
    if (_isChecked(normalized['cb_others_1073']) || dampOther.isNotEmpty) {
      normalized['cb_others_389'] = 'true';
    }
    if (dampOther.isNotEmpty) {
      normalized['et_others_471'] = dampOther;
    }

    if (_isChecked(normalized['cb_is_serious_damp'])) {
      normalized['cb_serious_dump'] = 'true';
    }
    if (_isChecked(normalized['cb_is_joists_decay'])) {
      normalized['cb_joists_decay'] = 'true';
    }

    final legacyStatus = _cleanLower(
      _firstNonEmpty(normalized, const ['actv_status', 'llMainContainer']),
    );
    if (legacyStatus.contains('not') && legacyStatus.contains('use')) {
      normalized['cb_not_in_use'] = 'true';
    }

    return normalized;
  }

  List<String> _bathroomFittingsMain(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = _cleanLower(answers['android_material_design_spinner4']);
    if (rating.isNotEmpty) {
      var template = _sub('{F_BATHROOM_FITTINGS}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{BF_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{F_BATHROOM_FITTINGS}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{BF_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  /// Maps a status dropdown value (none/noted/investigate family) to the
  /// approved-bank sub-code suffix. Section J status fields all follow the
  /// same three-tier legacy vocabulary.
  String? _riskStatusSubCode(String status, {required String prefix}) {
    final s = status.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'none' || s == 'not noted' || s == 'no') return '${prefix}_NONE';
    if (s.contains('investigate') || s == 'severe' || s == 'poor') {
      return '${prefix}_INVESTIGATE';
    }
    return '${prefix}_NOTED';
  }

  List<String> _risksOther(Map<String, String> answers) {
    // Section J3 (Risk to Other) - approved bank imported in Phase 4.
    if (_isChecked(answers['cb_not_applicable'])) {
      final template = _sub('{RISK_TO_OTHER}', '{OTHER_NO_APPLICABLE}');
      return template.isEmpty ? const [] : _splitResolved(template);
    }

    const proximitySubCodes = <String, String>{
      'cb_airport': '{OTHER_PROXIMITY_AIRPORT}',
      'cb_train_station': '{OTHER_PROXIMITY_TRAIN_STATION}',
      'cb_train_line': '{OTHER_PROXIMITY_TRAIN_LINE}',
      'cb_motorway': '{OTHER_PROXIMITY_MOTORWAY}',
    };
    final phrases = <String>[];
    proximitySubCodes.forEach((checkbox, subCode) {
      if (_isChecked(answers[checkbox])) {
        final template = _sub('{RISK_TO_OTHER}', subCode);
        if (template.isNotEmpty) phrases.addAll(_splitResolved(template));
      }
    });
    if (_isChecked(answers['cb_other_741'])) {
      final other = (answers['et_other_775'] ?? '').trim();
      if (other.isNotEmpty) {
        var template = _sub('{RISK_TO_OTHER}', '{OTHER_PROXIMITY_OTHER}');
        if (template.isNotEmpty) {
          phrases.addAll(_splitResolved(
            template.replaceAll('{OTHER_NAME}', other.toLowerCase()),
          ));
        }
      }
    }

    return phrases;
  }

  List<String> _risksRepairOrImprove(Map<String, String> answers) {
    if (!_isChecked(answers['cb_repair_or_improve'])) return const [];
    final template = _sub('{RISK_TO_OTHER}', '{OTHER_REPAIR_IMPROVE}');
    if (template.isEmpty) return const ['Repair or improve the property.'];
    return _splitResolved(template);
  }

  static bool _isChecked(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  static List<String> _labelsFor(
    List<String> ids,
    Map<String, String> answers,
    Map<String, String> labels,
  ) {
    final result = <String>[];
    for (final id in ids) {
      if (_isChecked(answers[id])) {
        final label = (labels[id] ?? id).trim();
        // Legacy saveCheckboxValue() never persists the literal "Other" token;
        // it only stores typed other-text when provided.
        if (label.toLowerCase() == 'other') continue;
        result.add(label);
      }
    }
    return result;
  }

  static void _addOther(
    Map<String, String> answers,
    String checkboxId,
    String textId,
    List<String> items, {
    String fallback = '',
  }) {
    if (_isChecked(answers[checkboxId])) {
      final text = (answers[textId] ?? '').trim();
      if (text.isNotEmpty) {
        items.add(text);
      } else if (fallback.trim().isNotEmpty) {
        items.add(fallback.trim());
      }
    }
  }

  static void _addOtherText(
    Map<String, String> answers,
    String checkboxId,
    List<String> textIds,
    List<String> items,
  ) {
    if (_isChecked(answers[checkboxId])) {
      final text = _firstNonEmpty(answers, textIds).trim();
      if (text.isNotEmpty) {
        items.add(text);
      }
    }
  }

  static String _cleanLower(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  /// Capitalises the first letter of a value that will start a sentence
  /// (e.g. a checked-item list substituted as the sentence subject). Most
  /// substitution values in this engine are deliberately lowercased for
  /// mid-sentence use; this is only for the minority of templates where the
  /// substituted value is itself the first word of the sentence.
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _chimneyPhraseCode(bool isMulti) {
    return isMulti ? '{E_CHIMNEY_MULTI_STACK}' : '{E_CHIMNEY_SINGLE_STACK}';
  }

  static String _chimneyPhraseCodeFromAnswers(
    Map<String, String> answers, {
    required bool fallbackIsMulti,
  }) {
    final stackType = _chimneyStackTypeFromAnswers(answers);
    if (stackType.contains('multiple')) return '{E_CHIMNEY_MULTI_STACK}';
    if (stackType.contains('single')) return '{E_CHIMNEY_SINGLE_STACK}';
    return _chimneyPhraseCode(fallbackIsMulti);
  }

  static String _chimneyStackTypeFromAnswers(Map<String, String> answers) {
    // Legacy/native and migrated trees use different spinner ids for stack type.
    return _cleanLower(
      _firstNonEmpty(
        answers,
        const [
          'android_material_design_spinner3',
          'android_material_design_spinner',
        ],
      ),
    );
  }

  static String _toWords(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  static List<String> _dedupeInsensitive(List<String> items) {
    final seen = <String>{};
    final unique = <String>[];
    for (final item in items) {
      final normalized = item.trim().toLowerCase();
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      unique.add(item.trim());
    }
    return unique;
  }

  static String _isAre(List<String> items) {
    return items.length > 1 ? 'are' : 'is';
  }

  static String _isAreForSubject(String subject) {
    final value = subject.trim().toLowerCase();
    if (value.isEmpty) return 'is';
    if (value.contains(' and ') || value.contains(',')) return 'are';
    const pluralSubjects = <String>{
      'doors',
      'windows',
      'walls',
      'rainwater goods',
    };
    return pluralSubjects.contains(value) ? 'are' : 'is';
  }

  static String _firstNonEmpty(Map<String, String> answers, List<String> ids) {
    for (final id in ids) {
      final value = (answers[id] ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  // ── Section D: About the Property ──────────────────────────────

  /// Builds the approved-bank garden narrative for front/rear/communal
  /// gardens: {D_GROUND}::{GROUND_X_GARDEN} with the fence sentence from
  /// {GROUND_GARDEN}::{GARDEN_BOUNDRY_FENCES} / {GARDEN_NO_BOUNDRY_FENCES}.
  List<String> _approvedGardenPhrases(
    String gardenName,
    String surfaceText, {
    required bool noBoundary,
    required String fencingText,
  }) {
    final area = gardenName.toLowerCase();
    final subCode = '{GROUND_${area.toUpperCase()}_GARDEN}';
    final typeToken = '{GROUND_${area.toUpperCase()}_GARDEN_TYPE}';

    String fenceSentence = '';
    if (noBoundary) {
      fenceSentence = _sub('{GROUND_GARDEN}', '{GARDEN_NO_BOUNDRY_FENCES}');
      if (fenceSentence.isEmpty) {
        fenceSentence = 'There are no boundary fences installed.';
      }
    } else if (fencingText.isNotEmpty) {
      var fenceTemplate = _sub('{GROUND_GARDEN}', '{GARDEN_BOUNDRY_FENCES}');
      if (fenceTemplate.isEmpty) {
        fenceTemplate =
            'The boundary fences are formed in {GARDEN_BOUNDRY_FENCES}.';
      }
      fenceSentence =
          fenceTemplate.replaceAll('{GARDEN_BOUNDRY_FENCES}', fencingText);
    }

    if (surfaceText.isEmpty) {
      return fenceSentence.isEmpty ? const [] : _splitResolved(fenceSentence);
    }

    var template = _sub('{D_GROUND}', subCode);
    if (template.isEmpty) {
      template = 'The $area garden of the property is $typeToken. '
          '{GARDEN_BOUNDRY_FENCES}';
    }
    template = template
        .replaceAll(typeToken, surfaceText)
        .replaceAll('{GARDEN_BOUNDRY_FENCES}', fenceSentence);
    return _splitResolved(template);
  }

  // ── New methods for uncovered screens ──────────────────────────

  // Section D: Residential garden (combined front/rear/communal)
  // Section D: Topography
  // Section D: Internal Wall
  // Section D: Listed Building
  // Section D: Other Service
  List<String> _accommodationSchedule(Map<String, String> answers) {
    final phrases = <String>[];
    final rooms = <String>[];

    void addRoom(String key, String label) {
      final v = (answers[key] ?? '').trim();
      if (v.isNotEmpty && v != '0') rooms.add('$v $label');
    }

    addRoom('et_num_reception_rooms', 'reception');
    addRoom('et_num_bedrooms', 'bedroom(s)');
    addRoom('et_num_bathrooms', 'bathroom(s)');
    addRoom('et_num_toilets', 'WC');
    addRoom('et_num_kitchens', 'kitchen(s)');
    addRoom('et_num_utility', 'utility');
    addRoom('et_num_conservatory', 'conservatory');
    addRoom('et_num_other_rooms', 'other');

    if (rooms.isNotEmpty) {
      phrases.add('Accommodation comprises ${_toWords(rooms)}.');
    }

    final otherDesc = (answers['et_other_rooms_desc'] ?? '').trim();
    if (otherDesc.isNotEmpty) phrases.add('Other rooms: $otherDesc.');

    final garage = (answers['actv_garage_type'] ?? '').trim();
    if (garage.isNotEmpty && garage != 'None') {
      phrases.add('Garage: $garage.');
    }

    final parking = (answers['actv_parking_type'] ?? '').trim();
    if (parking.isNotEmpty && parking != 'None') {
      phrases.add('Parking: $parking.');
    }

    final area = (answers['et_approx_floor_area'] ?? '').trim();
    if (area.isNotEmpty) {
      phrases.add('Approximate floor area: $area sq m.');
    }

    final floors = (answers['et_num_floors'] ?? '').trim();
    if (floors.isNotEmpty) phrases.add('Number of floors: $floors.');

    return phrases;
  }

  // Section F: woodwork legacy phrase passthrough
  // Section R: room counts
  List<String> _roomCounts(Map<String, String> answers, String floorName) {
    final rooms = <String, String>{
      'ar_etFirstName': 'living rooms',
      'ar_etLastName': 'bedrooms',
      'ar_etAddressLine1': 'bath/shower rooms',
      'ar_etCity': 'separate toilets',
      'ar_etPinCode': 'kitchens',
      'ar_etCountry': 'utility rooms',
      'ar_etConservatory': 'conservatories',
    };
    final counts = <String>[];
    for (final entry in rooms.entries) {
      final value = (answers[entry.key] ?? '').trim();
      if (value.isNotEmpty && value != '0') {
        counts.add('$value ${entry.value}');
      }
    }
    final otherName = (answers['ar_etNote'] ?? '').trim();
    final otherCount = (answers['etNoOfRoomsOther'] ?? '').trim();
    if (otherName.isNotEmpty && otherCount.isNotEmpty && otherCount != '0') {
      counts.add('$otherCount ${otherName.toLowerCase()}');
    }
    if (counts.isEmpty) return const [];
    return ['$floorName floor: ${counts.join(', ')}.'];
  }

  // Section E: roof covering summary
  // Section E: roof covering main screen
  List<String> _roofCoveringMainScreen(Map<String, String> answers) {
    final locations = <String>[];
    if (_isChecked(answers['cb_main_building'])) locations.add('main building');
    if (_isChecked(answers['cb_back_addition'])) locations.add('back addition');
    if (_isChecked(answers['cb_extension'])) locations.add('extension');
    if (_isChecked(answers['cb_bay_window'])) locations.add('bay window');
    if (_isChecked(answers['cb_dormer_window'])) locations.add('dormer window');
    if (_isChecked(answers['cb_other_601'])) {
      final other = (answers['et_other_691'] ?? '').trim();
      if (other.isNotEmpty) {
        locations.add(other.toLowerCase());
      }
    }
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    final assumedType = _cleanLower(answers['actv_assumed_type']);
    final notes = (answers['ar_etNote'] ?? '').trim();
    final phrases = <String>[];
    if (locations.isNotEmpty && assumedType.isNotEmpty) {
      var template = _sub('{E_ROOF_COVERING}', '{E_RC_NOT_INSPECTED}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{RC_NOT_INSPECTED_LOCATION}',
                _toWords(locations).toLowerCase())
            .replaceAll('{RC_NOT_INSPECTED_ASSUMED_TYPE}', assumedType);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    if (rating.isNotEmpty || notes.isNotEmpty) {
      final summary = _legacySectionRatingNotes(
        answers: answers,
        ratingKey: 'android_material_design_spinner4',
        phraseCodeForRating: '{E_ROOF_COVERING_REPAIR}',
        ratingSubCode: '{E_RC_CONDITION_RATING}',
        ratingPlaceholder: '{RC_CONDITION_RATING}',
        phraseCodeForNotes: '{E_ROOF_COVERING_REPAIR}',
        notesSubCode: '{E_RC_NOTES}',
        notesPlaceholder: '{RC_NOTES}',
      );
      phrases.addAll(summary);
    }
    return phrases;
  }

  // Section E: outside door repair location (failed glazing / inadequate lock)
  // Section E: legacy outside doors safety glass status screen
  // Section E: legacy outside doors wall sealing screen
  // Section A: overall opinion
  List<String> _overallOpinion(Map<String, String> answers) {
    final opinion = (answers['android_material_design_spinner5'] ?? '').trim();
    if (opinion.isEmpty) return const [];
    final amount = (answers['android_material_design_spinner'] ?? '').trim();
    final potential =
        (answers['android_material_design_spinner2'] ?? '').trim();
    final priceInWords =
        amount.isNotEmpty ? formatPriceAsWordsOnly(amount) : '';

    final ratingLower = opinion.toLowerCase();
    // Revised spec: the overall verdict may be reasonable, good, fair or poor
    // (the "reasonable with repair" variant is handled separately below).
    // A "reasonable" verdict keeps the favourable opener; good/fair/poor use
    // the neutral approved statement (no favourable opener, no fabricated
    // wording), with the chosen adjective substituted for {OVERALL_OPINION_RATING}.
    const qualityRatings = ['reasonable', 'good', 'fair', 'poor'];
    if (qualityRatings.contains(ratingLower)) {
      final key = ratingLower == 'reasonable'
          ? '{OVERALL_OPINION_REASONABLE}'
          : '{OVERALL_OPINION_QUALITY}';
      final template = _phraseTexts[key] ?? '';
      if (template.isNotEmpty) {
        var resolved = _normalize(template);
        if (amount.isNotEmpty) {
          resolved = resolved
              .replaceAll('{OVERALL_OPINION_PURCHASE_PRICE}', priceInWords)
              .replaceAll(
                  '{OVERALL_OPINION_PURCHASE_PRICE_WORD}', priceInWords);
        } else {
          // No purchase price captured - drop the price clause entirely
          // rather than leave the placeholder token in the report.
          resolved = resolved
              .replaceAll(
                  ' at a price of {OVERALL_OPINION_PURCHASE_PRICE_WORD}', '')
              .replaceAll(
                  ' at a price of {OVERALL_OPINION_PURCHASE_PRICE}', '')
              .replaceAll('{OVERALL_OPINION_PURCHASE_PRICE_WORD}', '')
              .replaceAll('{OVERALL_OPINION_PURCHASE_PRICE}', '');
        }
        // Substitute the chosen quality adjective into the approved sentence.
        resolved = resolved.replaceAll('{OVERALL_OPINION_RATING}', ratingLower);
        return _split(resolved);
      }
      final phrases = <String>['Overall opinion: $ratingLower.'];
      if (priceInWords.isNotEmpty)
        phrases.add('Purchase price: $priceInWords.');
      return phrases;
    }
    if (opinion.toLowerCase().contains('repair')) {
      final template =
          _phraseTexts['{OVERALL_OPINION_REASONABLE_WITH_REPAIR}'] ?? '';
      final phrases = <String>[];
      if (template.isNotEmpty) {
        var resolved = _normalize(template);
        // Try placeholder substitution first
        resolved = resolved.replaceAll('{REPAIR_AMOUNT}', priceInWords);
        resolved = resolved.replaceAll('{REPAIR_POTENTIAL}',
            potential.isNotEmpty ? potential.toLowerCase() : '');
        phrases.addAll(_split(resolved));
      } else {
        phrases.add('Overall opinion: reasonable with repairs.');
      }
      if (priceInWords.isNotEmpty || potential.isNotEmpty) {
        var allowance = _phraseTexts['{OVERALL_OPINION_REPAIR_ALLOWANCE}'] ??
            'A provisional repair allowance of {REPAIR_AMOUNT} should be '
                'considered. The anticipated scope is {REPAIR_SCOPE}.';
        allowance = allowance
            .replaceAll(
              '{REPAIR_AMOUNT}',
              priceInWords.isEmpty ? 'an amount to be confirmed' : priceInWords,
            )
            .replaceAll(
              '{REPAIR_SCOPE}',
              potential.isEmpty
                  ? 'subject to further investigation and contractor quotations'
                  : potential.toLowerCase(),
            );
        phrases.addAll(_splitResolved(allowance));
      }
      return phrases;
    }
    return const [];
  }

  static String _addCommasHelper(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  List<String>? _matchDynamicSectionE(
      String screenId, Map<String, String> answers) {
    if (screenId.startsWith('activity_outside_property_other_other_external')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_other_wall')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_other_roof')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_floors')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_drains')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_handrails')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_overloaded')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId
        .startsWith('activity_outside_property_other_no_safety_glass')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId
        .startsWith('activity_out_side_other_external_area_condition')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_wall')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_roof')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_floor')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_drains')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId
        .startsWith('activity_outside_property_other_repairs_hand_rails')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId
        .startsWith('activity_outside_property_other_repairs_steps_landing')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    if (screenId
        .startsWith('activity_outside_property_other_repairs_decorations')) {
      return const [];  // verbatim rules (inspection_verbatim_spec.dart)
    }
    return null;
  }

  static String _doorLocationFromScreen(
      String screenId, Map<String, String> answers) {
    if (screenId.contains('__rear_door')) return 'rear';
    if (screenId.contains('__side_door')) return 'side';
    if (screenId.contains('__patio_door')) return 'patio';
    if (screenId.contains('__garage_door')) return 'garage';
    if (screenId.contains('__other_door')) {
      final typed = _firstNonEmpty(answers, ['other']).trim();
      return typed.isNotEmpty ? typed.toLowerCase() : 'other';
    }
    return 'main';
  }

  static String _doorRepairSection(String screenId) {
    if (screenId.contains('__rear_door')) return '{REAR_DOOR_REPAIR}';
    if (screenId.contains('__side_door')) return '{SIDE_DOOR_REPAIR}';
    if (screenId.contains('__patio_door')) return '{PATIO_DOOR_REPAIR}';
    if (screenId.contains('__garage_door')) return '{GARAGE_DOOR_REPAIR}';
    if (screenId.contains('__other_door')) return '{OTHER_DOOR_REPAIR}';
    return '{MAIN_DOOR_REPAIR}';
  }

  static bool _isPorchScreenVariant(
    String screenId, {
    required String porchSuffix,
  }) {
    if (screenId.endsWith(porchSuffix)) return true;
    // CP screens are paired by route ID; unsuffixed route is conservatory.
    return false;
  }

  static String _cpRepairWrapper(String screenId) {
    if (screenId.contains('__walls')) return '{WALLS_REPAIR}';
    if (screenId.contains('__windows')) return '{WINDOWS_REPAIR}';
    if (screenId.contains('__door_glazing')) return '{DOOR_GLAZING_REPAIR}';
    if (screenId.contains('__window_glazing')) return '{WINDOW_GLAZING_REPAIR}';
    if (screenId.contains('__roof_glazing')) return '{ROOF_GLAZING_REPAIR}';
    if (screenId.contains('__floor')) return '{FLOOR_REPAIR}';
    if (screenId.contains('__rainwater_goods'))
      return '{RAINWATER_GOODS_REPAIR}';
    return '{DOOR_REPAIR}';
  }

  static String _cpRepairLocationFromScreen(String screenId) {
    if (screenId.contains('__walls')) return 'walls';
    if (screenId.contains('__windows')) return 'windows';
    if (screenId.contains('__door_glazing')) return 'door glazing';
    if (screenId.contains('__window_glazing')) return 'window glazing';
    if (screenId.contains('__roof_glazing')) return 'roof glazing';
    if (screenId.contains('__floor')) return 'floor';
    if (screenId.contains('__rainwater_goods')) return 'rainwater goods';
    return 'doors';
  }

  static String _veluxNumber(Map<String, String> answers) {
    if (_isChecked(answers['cb_one'])) return 'one';
    if (_isChecked(answers['cb_two'])) return 'two';
    if (_isChecked(answers['cb_three'])) return 'three';
    if (_isChecked(answers['cb_four'])) return 'four';
    if (_isChecked(answers['cb_five'])) return 'five';
    if (_isChecked(answers['cb_other_814'])) {
      final text = _firstNonEmpty(answers, ['et_other_196']);
      if (text.isNotEmpty) return text.toLowerCase();
    }
    return 'multiple';
  }

  static String _mainWallTypeCode(String wallType) {
    final value = wallType.toLowerCase();
    if (value.contains('cavity brick')) return '{CAVITY_BRICK_WALL}';
    if (value.contains('cavity block')) return '{CAVITY_BLOCK_WALL}';
    if (value.contains('cavity stud')) return '{CAVITY_STUD_WALL}';
    if (value.contains('solid')) return '{SOLID_BOUNDED_BRICK_WALL}';
    return '{OTHER_WALL}';
  }

  static String? _mainWallTypeFromScreen(
    String screenId,
    Map<String, String> answers,
  ) {
    if (screenId.contains('__cavity_brick_wall')) return 'cavity brick wall';
    if (screenId.contains('__cavity_block_wall')) return 'cavity block wall';
    if (screenId.contains('__cavity_stud_wall')) return 'cavity stud wall';
    if (screenId.endsWith('__other')) {
      final typed = _firstNonEmpty(answers, ['other', 'et_other_124']).trim();
      return typed.isNotEmpty ? typed.toLowerCase() : null;
    }
    if (screenId == 'activity_outside_property_main_walls_about_wall') {
      return 'solid brick wall';
    }
    return null;
  }

  static List<String> _split(String text) {
    return text
        .split(RegExp(r'\n{2,}'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _normalize(String text) {
    // Replace literal \r\n sequences (JSON \\r\\n → Dart \r\n) with newlines
    var cleaned = text.replaceAll(r'\r\n', '\n');
    // Replace <br>, <br/>, <br /> tags with newlines
    cleaned =
        cleaned.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // Strip remaining HTML tags (<strong>, <span>, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');
    // Replace non-breaking spaces (\u00a0) with regular spaces
    cleaned = cleaned.replaceAll('\u00a0', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\bPVC\b'), 'uPVC');
    // Collapse multiple spaces into one
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');
    return const LineSplitter().convert(cleaned).join('\n').trim();
  }
}
