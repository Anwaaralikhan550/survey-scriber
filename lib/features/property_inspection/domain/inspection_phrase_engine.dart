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
        return _propertyWeather(answers);
      case 'activity_property_status':
        return _propertyStatus(answers);
      case 'activity_property_facing':
        return _propertyFacing(answers);
      case 'activity_outside_property_limitation':
        return _outsidePropertyLimitations(answers);
      case 'activity_outside_property_roof_covering':
        return _roofCoveringSummary(answers);
      case 'activity_outside_property_rainwater_goods':
        return [
          ..._rainwaterGoodsMainScreen(answers),
          ..._rwgBlocked(answers),
          ..._rwgOpenRunoffs(answers),
        ];
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
        return _insidePropertyLimitations(answers);
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
        return _chimneyStacks(answers);
      case 'activity_outside_property_location':
        return _chimneyLocation(answers);
      case 'activity_outside_property_rendering':
        return _chimneyRendering(answers);
      case 'activity_outside_property_water_proofing':
        // Flashings / flaunching / pointing / pots: PDF-driven rules.
        return const [];
      case 'activity_outside_property_condition':
        return _chimneyCondition(answers);
      case 'activity_outside_property_shared_chimney':
        return _chimneyShared(answers);
      case 'activity_outside_property_leaning_chimney':
        return _chimneyLeaning(answers);
      case 'activity_outside_property_chimney_partial_view':
      case 'activity_outside_property_chimney_removed_chimney_stack':
      case 'activity_outside_property_chimney_removed_pots':
      case 'activity_outside_property_chimney_not_inspected':
        return _chimneyInspectionStatus(answers);
      case 'activity_outside_property_repair_flashing':
        return _chimneyRepairFlashing(answers);
      case 'activity_outside_property_chimney_repair_flaunching':
        return _chimneyRepairFlaunching(answers);
      case 'activity_outside_property_repair_chimney_pots':
        return _chimneyRepairPots(answers);
      case 'activity_outside_property_repair_chimney_repointing':
        return _chimneyRepairRepointing(answers);
      case 'activity_outside_property_repair_chimney_disrepair':
        return _chimneyRepairDisrepair(answers);
      case 'activity_outside_property_repair_chimney_dish_aerial':
      case 'activity_outside_property_repair_chimney_dish_aerial__satellite':
        return _chimneyRepairDishAerial(answers, screenId: screenId);
      case 'activity_outside_property_rwg__repair_pipes_gutters':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg_about':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_rwg_weather_condition':
        return _rwgWeatherCondition(answers);
      case 'activity_outside_property_rwg_blocked_rwg':
        return _rwgBlocked(answers);
      case 'activity_outside_property_rwg_blocked_gullies':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_rwg_open_runoffs':
        return _rwgOpenRunoffs(answers);
      case 'activity_outside_property_rain_water_goods_not_inspected':
        return _rwgNotInspected(answers);
      case 'outside_property_about_roof_layout':
      case 'outside_property_about_roof_layout__flat':
      case 'outside_property_about_roof_layout__mansard':
      case 'outside_property_about_roof_layout__other':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_weather_layout':
        return _roofWeather(answers);
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
        return _roofAsbestos(answers);
      case 'outside_property_roof_covering_roof_structure_layout':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'outside_property_roof_covering_roof_spreading_layout':
        return _roofSpreading(answers);
      case 'activity_outside_property_roof_repair_tiles':
        return const [];  // verbatim rules (inspection_verbatim_spec.dart)
      case 'activity_outside_property_roof_repair_poor_roof':
        return _roofRepairPoorRoof(answers);
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
        return _roofNotInspected(answers);
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
        return _windowsNotInspected(answers);
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
        return _risksRiskToBuilding(answers);
      case 'activity_risks_other_':
        return _risksOther(answers);
      case 'activity_risks_repair_or_improve':
        return _risksRepairOrImprove(answers);

      // ── Section D: About the Property ──
      case 'activity_property_type':
        return _propertyType(answers);
      case 'activity_property_construction':
        return _propertyConstruction(answers);
      case 'activity_property_built_year':
        return _propertyBuiltYear(answers);
      case 'activity_property_roof':
        return _propertyRoof(answers);
      case 'activity_property_ground_area':
        return _propertyGroundArea(answers);
      case 'activity_property_extended':
        return _propertyExtended(answers);
      case 'activity_extended_wall':
        return _extendedWall(answers);
      case 'activity_parking':
      case 'activity_parking__parking':
        return _propertyParking(answers);
      case 'activity_front_garden':
        return _sectionDGarden(answers, 'front');
      case 'activity_rear_garden':
        return _sectionDGarden(answers, 'rear');
      case 'activity_communal_garden':
        return _sectionDGarden(answers, 'communal');
      case 'activity_property_converted':
        return _propertyConverted(answers);
      case 'activity_property_flate':
        return _propertyFlatInfo(answers);
      case 'activity_construction_floor':
        return _constructionFloor(answers);
      case 'activity_construction_window':
        return _constructionWindow(answers);
      case 'activity_gated_community':
        return _gatedCommunity(answers);
      case 'activity_energy_effiency':
        return _energyEfficiency(answers);
      case 'activity_energy_environment_impect':
        return _energyEnvironmentalImpact(answers);
      case 'activity_estate_location':
        return _estateLocation(answers);
      case 'activity_property_location':
        return _propertyLocationDensity(answers);
      case 'activity_property_facelities':
        return _propertyFacilities(answers);
      case 'activity_property_local_environment':
        return _propertyLocalEnvironment(answers);
      case 'activity_property_private_road':
        return _propertyPrivateRoad(answers);
      case 'activity_property_is_noisy_area':
        return _propertyNoisyArea(answers);
      case 'activity_garden':
        return _sectionDGardenResidential(answers);
      case 'activity_topography':
        return _sectionDTopography(answers);
      case 'activity_internal_wall':
        return _sectionDInternalWall(answers);
      case 'activity_listed_building':
      case 'activity_listed_building__listed_building':
        return _sectionDListedBuilding(answers);
      case 'activity_other_service':
        return _sectionDOtherService(answers);
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
        return _roofCoveringSummary(answers);
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

  List<String> _propertyWeather(Map<String, String> answers) {
    final now = (answers['android_material_design_spinner'] ?? '').trim();
    final before = (answers['android_material_design_spinner2'] ?? '').trim();
    if (now.isEmpty && before.isEmpty) {
      return const ['Not inspected'];
    }
    // Both values are required to complete this sentence; a double space
    // where an empty value was substituted is not acceptable in a
    // finalised client report, so wait until both are answered.
    if (now.isEmpty || before.isEmpty) return const [];
    final template = _phraseTexts['{D_WEATHER}'] ?? '';
    if (template.isEmpty) return const [];
    final resolved = _normalize(template)
        .replaceAll('{WEATHER_NOW}', now.toLowerCase())
        .replaceAll('{WEATHER_BEFORE}', before.toLowerCase());
    return _split(resolved);
  }

  List<String> _propertyStatus(Map<String, String> answers) {
    final occupancy = (answers['android_material_design_spinner'] ?? '').trim();
    final furnishing =
        (answers['android_material_design_spinner2'] ?? '').trim();
    final flooring = (answers['android_material_design_spinner3'] ?? '').trim();
    if (occupancy.isEmpty && furnishing.isEmpty && flooring.isEmpty) {
      return const ['Not inspected'];
    }
    // All three values are required to complete this sentence; a double
    // space or dangling "and ." where an empty value was substituted is
    // not acceptable in a finalised client report, so wait until the
    // surveyor has answered them all.
    if (occupancy.isEmpty || furnishing.isEmpty || flooring.isEmpty) {
      return const [];
    }
    var template = _phraseTexts['{D_PROPERTY_STATUS}'] ?? '';
    if (template.isEmpty) return const [];
    // The floor-covering options already end in "covered" ("Fully
    // covered", "Partially covered"), but the template has its own fixed
    // trailing "covered" word - doubling up to "fully covered covered"
    // when substituted verbatim. Drop the template's redundant word when
    // the option already supplies it.
    if (flooring.toLowerCase().contains('covered')) {
      template = template.replaceAll(
        '{PROPERTY_STATUS_FLOOR_COVERING} covered',
        '{PROPERTY_STATUS_FLOOR_COVERING}',
      );
    }
    final resolved = _normalize(template)
        .replaceAll('{PROPERTY_STATUS_OCCUPANCY}', occupancy.toLowerCase())
        .replaceAll('{PROPERTY_STATUS_FURNISHING}', furnishing.toLowerCase())
        .replaceAll('{PROPERTY_STATUS_FLOOR_COVERING}', flooring.toLowerCase());
    return _split(resolved);
  }

  List<String> _propertyFacing(Map<String, String> answers) {
    final orientation =
        (answers['android_material_design_spinner'] ?? '').trim();
    if (orientation.isEmpty) return const [];
    final template = _phraseTexts['{D_PROPERTY_FACING}'] ?? '';
    if (template.isEmpty) return const [];
    final resolved = _normalize(template)
        .replaceAll('{PROPERTY_ORIENTATION}', orientation.toLowerCase());
    return _split(resolved);
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

  List<String> _outsidePropertyLimitations(Map<String, String> answers) {
    final selections = <String>[];
    if (_isChecked(answers['ch1'])) selections.add('Height/Configuration');
    if (_isChecked(answers['ch2'])) selections.add('Nearby Buildings');
    if (_isChecked(answers['ch3'])) selections.add('No rear access');
    if (selections.isEmpty) return const [];

    final template = _phraseTexts['{E_OUTSIDE_PROPERTY_LIMITATIONS}'] ?? '';
    if (template.isEmpty) return const [];

    var result = template;
    final standard =
        _sub('{E_OUTSIDE_PROPERTY_LIMITATIONS}', '{STANDARD_TEXT}');
    result = result.replaceAll('{STANDARD_TEXT}', standard);

    final height = selections.contains('Height/Configuration')
        ? _sub('{E_OUTSIDE_PROPERTY_LIMITATIONS}', '{HEIGHT_CONFIGURATION}')
        : '';
    result = result.replaceAll('{HEIGHT_CONFIGURATION}', height);

    final nearby = selections.contains('Nearby Buildings')
        ? _sub('{E_OUTSIDE_PROPERTY_LIMITATIONS}', '{NEARBY_BUILDINGS}')
        : '';
    result = result.replaceAll('{NEARBY_BUILDINGS}', nearby);

    final noRear = selections.contains('No rear access')
        ? _sub('{E_OUTSIDE_PROPERTY_LIMITATIONS}', '{NO_REAR_ACCESS}')
        : '';
    result = result.replaceAll('{NO_REAR_ACCESS}', noRear);

    return _split(_normalize(result));
  }

  List<String> _chimneyStacks(Map<String, String> answers) {
    final stackType = _chimneyStackTypeFromAnswers(answers);
    if (stackType.isEmpty) return const [];
    final isMulti = stackType.contains('multiple');
    final phraseCode = _chimneyPhraseCode(isMulti);
    final phrases = <String>[];

    // Description (construction / appearance) and Pots are PDF-driven rules
    // in inspection_verbatim_spec.dart.

    final rendering = _cleanLower(answers['android_material_design_spinner4']);
    if (rendering.isNotEmpty) {
      var renderingTemplate = _sub(phraseCode, '{STACK_RENDERING}');
      if (renderingTemplate.isNotEmpty) {
        renderingTemplate =
            renderingTemplate.replaceAll('{CS_RENDERING}', rendering);
        final faces = _cleanLower(answers['android_material_design_spinner5']);
        if (faces.isNotEmpty) {
          renderingTemplate =
              renderingTemplate.replaceAll('{CS_RENDERING_OUTER_FACE}', faces);
        } else {
          renderingTemplate =
              renderingTemplate.replaceAll('{CS_RENDERING_OUTER_FACE}', '');
        }
        phrases.addAll(_split(_normalize(renderingTemplate)));
      }
    }

    return phrases;
  }

  List<String> _chimneyLocation(Map<String, String> answers) {
    final locations = _labelsFor(
      ['ch1', 'ch2', 'ch3', 'ch4', 'ch5'],
      answers,
      {
        'ch1': 'Centre',
        'ch2': 'Front',
        'ch3': 'Side',
        'ch4': 'Rear',
        'ch5': 'Other',
      },
    );
    _addOther(answers, 'ch5', 'etGroundTypeOther', locations);
    if (locations.isEmpty) return const [];

    final phraseCode = _chimneyPhraseCodeFromAnswers(
      answers,
      fallbackIsMulti: locations.length > 1,
    );
    var template = _sub(phraseCode, '{STACK_LOCATION}');
    if (template.isEmpty) return const [];
    final locationText = _toWords(locations).toLowerCase();
    template = template.replaceAll('{CS_LOCATION}', locationText);
    return _split(_normalize(template));
  }

  List<String> _chimneyRendering(Map<String, String> answers) {
    final rendering = _cleanLower(answers['android_material_design_spinner3']);
    if (rendering.isEmpty) return const [];
    final phraseCode = _chimneyPhraseCodeFromAnswers(
      answers,
      fallbackIsMulti: false,
    );
    var template = _sub(phraseCode, '{STACK_RENDERING}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_RENDERING}', rendering)
        .replaceAll('{CS_RENDERING_OUTER_FACE}', '');
    return _split(_normalize(template));
  }

  List<String> _chimneyCondition(Map<String, String> answers) {
    final condition = _cleanLower(answers['android_material_design_spinner3']);
    if (condition.isEmpty) return const [];
    final phraseCode = _chimneyPhraseCodeFromAnswers(
      answers,
      fallbackIsMulti: false,
    );
    var template = _sub(phraseCode, '{CONDITION}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CS_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _chimneyShared(Map<String, String> answers) {
    final locations = _labelsFor(
      ['ch1', 'ch2', 'ch3', 'ch4', 'cb_other_608'],
      answers,
      {
        'ch1': 'Main building',
        'ch2': 'Front',
        'ch3': 'Side',
        'ch4': 'Rear',
        'cb_other_608': 'Other',
      },
    );
    _addOther(answers, 'cb_other_608', 'et_other_752', locations);
    if (locations.isEmpty) return const [];

    final phraseCode = _chimneyPhraseCodeFromAnswers(
      answers,
      fallbackIsMulti: locations.length > 1,
    );
    var template = _sub(phraseCode, '{SHARED_CHIMNEY}');
    if (template.isEmpty) return const [];
    final locationText = _toWords(locations).toLowerCase();
    template = template
        .replaceAll('{CS_SHARED_CHIMNEY}', locationText)
        .replaceAll('{IS_ARE}', _isAre(locations));
    return _split(_normalize(template));
  }

  List<String> _chimneyLeaning(Map<String, String> answers) {
    // PDF E1: "The chimney stack appears slightly leaning, significantly
    // leaning." - the surveyor picks the degree; no location is printed.
    final degree = _cleanLower(answers['actv_leaning_degree']);
    final condition = _cleanLower(answers['android_material_design_spinner4']);
    if (degree.isEmpty && condition.isEmpty) return const [];

    // The degree sentence is a PDF-driven rule (inspection_verbatim_spec.dart).
    final phraseCode = _chimneyPhraseCodeFromAnswers(
      answers,
      fallbackIsMulti: false,
    );
    final phrases = <String>[];

    if (condition.isNotEmpty) {
      final conditionCode = condition.contains('repair')
          ? '{LEANING_CHIMNEY_CONDITION_REPAIR_SOON}'
          : '{LEANING_CHIMNEY_CONDITION_OK}';
      final conditionTemplate = _sub(phraseCode, conditionCode);
      if (conditionTemplate.isNotEmpty) {
        phrases.addAll(_split(_normalize(conditionTemplate)));
      }
    }

    return phrases;
  }

  List<String> _chimneyInspectionStatus(Map<String, String> answers) {
    final phrases = <String>[];
    final phraseCode = '{E_CS_CHIMNEY_INSPECTION_STATUS}';

    if (_isChecked(answers['cb_Not_applicable'])) {
      phrases.addAll(_split(_normalize(_sub(phraseCode, '{NOT_APPLICABLE}'))));
      return phrases;
    }

    if (_isChecked(answers['cb_not_inspected_access'])) {
      phrases
          .addAll(_split(_normalize(_sub(phraseCode, '{NOT_INSPECTED_ACCESS}'))));
      return phrases;
    }

    if (_isChecked(answers['cb_dummy_chimney_breast'])) {
      phrases.addAll(
          _split(_normalize(_sub(phraseCode, '{DUMMY_CHIMNEY_BREAST}'))));
    }

    // "Not fully inspected" (with its reasons) is a PDF-driven rule in
    // inspection_verbatim_spec.dart.

    if (_isChecked(answers['cb_Removed_chimney_stack'])) {
      final locations = _labelsFor(
        [
          'cb_main_building_83',
          'cb_front_74',
          'cb_rear_97',
          'cb_side_72',
          'cb_other_326'
        ],
        answers,
        {
          'cb_main_building_83': 'Main building',
          'cb_front_74': 'Front',
          'cb_rear_97': 'Rear',
          'cb_side_72': 'Side',
          'cb_other_326': 'Other',
        },
      );
      _addOther(answers, 'cb_other_326', 'et_other_782', locations);
      var locationText = _toWords(locations).toLowerCase();
      var template = _sub(phraseCode, '{REMOVED_CHIMNEY_STACK}');
      if (template.isNotEmpty) {
        template = template.replaceAll(
            '{CS_INSPECTION_STATUS_REMOVED_CS}', locationText);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_Removed_pots'])) {
      final locations = _labelsFor(
        ['cb_front_88', 'cb_side_43', 'cb_rear_83', 'cb_other_326'],
        answers,
        {
          'cb_front_88': 'Front',
          'cb_side_43': 'Side',
          'cb_rear_83': 'Rear',
          'cb_other_326': 'Other',
        },
      );
      _addOther(answers, 'cb_other_326', 'et_other_782', locations);
      var locationText = _toWords(locations).toLowerCase();
      var template = _sub(phraseCode, '{REMOVED_POTS}');
      if (template.isNotEmpty) {
        template = template.replaceAll(
            '{CS_INSPECTION_STATUS_REMOVED_CHIMNEY_POTS}', locationText);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _chimneyRepairFlashing(Map<String, String> answers) {
    final condition = _cleanLower(
      _firstNonEmpty(
        answers,
        const [
          'android_material_design_spinner4',
          'actv_condition',
          'llMainContainer'
        ],
      ),
    );
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon
          ? ['chs1', 'chs2', 'chs3', 'chs4', 'chs5']
          : ['ch1', 'ch2', 'ch3', 'ch4', 'ch5'],
      answers,
      {
        'chs1': 'Main building',
        'chs2': 'Front',
        'chs3': 'Side',
        'chs4': 'Rear',
        'chs5': 'Other',
        'ch1': 'Main building',
        'ch2': 'Front',
        'ch3': 'Side',
        'ch4': 'Rear',
        'ch5': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'chs5' : 'ch5',
        isSoon ? 'etChimneySoonOther' : 'etChimneyCommonOther', stacks);

    final issues = _labelsFor(
      isSoon
          ? ['ch10', 'ch11', 'ch12', 'ch13', 'ch14']
          : ['ch6', 'ch7', 'ch8', 'ch9'],
      answers,
      {
        'ch10': 'Loose',
        'ch11': 'Incomplete',
        'ch12': 'Split',
        'ch13': 'Lifted',
        'ch14': 'Other',
        'ch6': 'Very loose',
        'ch7': 'Largely missing',
        'ch8': 'Badly cracked',
        'ch9': 'Other',
      },
    );
    _addOther(
        answers,
        isSoon ? 'ch14' : 'ch9',
        isSoon ? 'etRepairSoonProblemOther' : 'etRepairNowProblemOther',
        issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_FLASHING_REPAIR}';
    final subCode = isSoon ? '{FLASHING_REPAIR_SOON}' : '{FLASHING_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll(
            '{CS_FLASHING_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll(
            '{CS_FLASHING_REPAIR_ISSUE}', _toWords(issues).toLowerCase())
        .replaceAll('{IS_ARE}', _isAre(stacks));
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_causing_dump'])) {
      final extra = _sub(phraseCode, '{FLASHING_REPAIR_NOW_CAUSING_DUMP}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _chimneyRepairFlaunching(Map<String, String> answers) {
    final condition = _cleanLower(
      _firstNonEmpty(answers, const ['actv_condition', 'llMainContainer']),
    );
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon
          ? ['cb_main_building_56', 'cb_front_62', 'cb_side_28', 'cb_rear_56']
          : ['cb_main_building_28', 'cb_front_48', 'cb_side_50', 'cb_rear_32'],
      answers,
      {
        'cb_main_building_56': 'Main building',
        'cb_front_62': 'Front',
        'cb_side_28': 'Side',
        'cb_rear_56': 'Rear',
        'cb_main_building_28': 'Main building',
        'cb_front_48': 'Front',
        'cb_side_50': 'Side',
        'cb_rear_32': 'Rear',
      },
    );

    final issues = _labelsFor(
      isSoon
          ? ['cb_cracked', 'cb_loose', 'cb_partly_missing', 'cb_other_952']
          : [
              'cb_badly_cracked',
              'cb_very_loose',
              'cb_largely_missing',
              'cb_other_969'
            ],
      answers,
      {
        'cb_cracked': 'Cracked',
        'cb_loose': 'Loose',
        'cb_partly_missing': 'Partly missing',
        'cb_other_952': 'Other',
        'cb_badly_cracked': 'Badly cracked',
        'cb_very_loose': 'Very loose',
        'cb_largely_missing': 'Largely missing',
        'cb_other_969': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_952' : 'cb_other_969',
        isSoon ? 'et_other_347' : 'et_other_176', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_FLAUNCHING_REPAIR}';
    final subCode =
        isSoon ? '{FLAUNCHING_REPAIR_SOON}' : '{FLAUNCHING_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll(
            '{CS_FLAUNCHING_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll(
            '{CS_FLAUNCHING_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_causing_dump'])) {
      final extra = _sub(phraseCode, '{FLAUNCHING_REPAIR_NOW_CAUSING_DUMP}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _chimneyRepairPots(Map<String, String> answers) {
    final condition = _cleanLower(
      _firstNonEmpty(answers, const ['actv_condition', 'llMainContainer']),
    );
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon
          ? ['cb_main_building_71', 'cb_front_59', 'cb_side_79', 'cb_rear_35']
          : ['cb_main_building_91', 'cb_front_97', 'cb_side_49', 'cb_rear_79'],
      answers,
      {
        'cb_main_building_71': 'Main building',
        'cb_front_59': 'Front',
        'cb_side_79': 'Side',
        'cb_rear_35': 'Rear',
        'cb_main_building_91': 'Main building',
        'cb_front_97': 'Front',
        'cb_side_49': 'Side',
        'cb_rear_79': 'Rear',
      },
    );

    final issues = _labelsFor(
      isSoon
          ? ['cb_cracked', 'cb_broken', 'cb_partly_missing', 'cb_other_435']
          : [
              'cb_badly_cracked',
              'cb_badly_broken',
              'cb_largely_missing',
              'cb_other_467'
            ],
      answers,
      {
        'cb_cracked': 'Cracked',
        'cb_broken': 'Broken',
        'cb_partly_missing': 'Partly missing',
        'cb_other_435': 'Other',
        'cb_badly_cracked': 'Badly cracked',
        'cb_badly_broken': 'Badly broken',
        'cb_largely_missing': 'Largely missing',
        'cb_other_467': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_435' : 'cb_other_467',
        isSoon ? 'et_other_634' : 'et_other_494', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_POTS_REPAIR}';
    final subCode =
        isSoon ? '{CHIMNEY_POTS_REPAIR_SOON}' : '{CHIMNEY_POTS_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_POTS_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll('{CS_POTS_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_safety_hazard'])) {
      final extra = _sub(phraseCode, '{CHIMNEY_POTS_REPAIR_NOW_SAFETY_HAZARD}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _chimneyRepairRepointing(Map<String, String> answers) {
    final condition = _cleanLower(
      _firstNonEmpty(answers, const ['actv_condition', 'llMainContainer']),
    );
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon
          ? ['cb_main_building_25', 'cb_front_96', 'cb_side_40', 'cb_rear_32']
          : ['cb_main_building_79', 'cb_front_55', 'cb_side_79', 'cb_rear_99'],
      answers,
      {
        'cb_main_building_25': 'Main building',
        'cb_front_96': 'Front',
        'cb_side_40': 'Side',
        'cb_rear_32': 'Rear',
        'cb_main_building_79': 'Main building',
        'cb_front_55': 'Front',
        'cb_side_79': 'Side',
        'cb_rear_99': 'Rear',
      },
    );

    final issues = _labelsFor(
      isSoon
          ? [
              'cb_has_eroded',
              'cb_is_partly_missing',
              'cb_is_loose',
              'cb_other_669'
            ]
          : ['cb_badly_eroded', 'cb_largely_missing', 'cb_other_862'],
      answers,
      {
        'cb_has_eroded': 'Has eroded',
        'cb_is_partly_missing': 'Is partly missing',
        'cb_is_loose': 'Is loose',
        'cb_other_669': 'Other',
        'cb_badly_eroded': 'Badly eroded',
        'cb_largely_missing': 'Largely missing',
        'cb_other_862': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_669' : 'cb_other_862',
        isSoon ? 'et_other_201' : 'et_other_169', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_REPOINTING_REPAIR}';
    final subCode = isSoon
        ? '{CHIMNEY_REPOINTING_REPAIR_SOON}'
        : '{CHIMNEY_REPOINTING_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll(
            '{CS_REPOINTING_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll(
            '{CS_REPOINTING_REPAIR_ISSUES}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_causing_dump'])) {
      final extra =
          _sub(phraseCode, '{CHIMNEY_REPOINTING_REPAIR_NOW_CAUSING_DUMP}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _chimneyRepairDisrepair(Map<String, String> answers) {
    if (!_isChecked(answers['cb_repair_soon_70'])) return const [];
    final stacks = _labelsFor(
      [
        'cb_main_building_21',
        'cb_front_101',
        'cb_side_71',
        'cb_rear_16',
        'cb_other_608'
      ],
      answers,
      {
        'cb_main_building_21': 'Main building',
        'cb_front_101': 'Front',
        'cb_side_71': 'Side',
        'cb_rear_16': 'Rear',
        'cb_other_608': 'Other',
      },
    );
    _addOther(answers, 'cb_other_608', 'et_other_752', stacks);
    if (stacks.isEmpty) return const [];

    var template =
        _sub('{E_CHIMNEY_DISREPAIR_REPAIR}', '{CHIMNEY_DISREPAIR_REPAIR_SOON}');
    if (template.isEmpty) return const [];
    template = template.replaceAll(
        '{CS_CHIMNEY_DISREPAIR_REPAIR_STACKS}', _toWords(stacks).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _chimneyRepairDishAerial(Map<String, String> answers,
      {String? screenId}) {
    final condition = _cleanLower(
      _firstNonEmpty(answers, const ['actv_condition', 'llMainContainer']),
    );
    String type = '';
    if (screenId != null) {
      if (screenId.contains('satellite')) {
        type = 'satellite';
      } else if (screenId.contains('dish_aerial')) {
        type = 'aerial';
      }
    }
    if (type.isEmpty) {
      type = _cleanLower(answers['actv_type']);
    }
    if (condition.isEmpty || type.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final issues = _labelsFor(
      isSoon
          ? ['cb_loose', 'cb_rusted', 'cb_other_920']
          : ['cb_very_loose', 'cb_badly_rusted', 'cb_other_698'],
      answers,
      {
        'cb_loose': 'Loose',
        'cb_rusted': 'Rusted',
        'cb_other_920': 'Other',
        'cb_very_loose': 'Very loose',
        'cb_badly_rusted': 'Badly rusted',
        'cb_other_698': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_920' : 'cb_other_698',
        isSoon ? 'et_other_193' : 'et_other_633', issues);
    if (issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_AERIAL_DISH_REPAIR}';
    final subCode =
        isSoon ? '{AERIAL_DISH_REPAIR_SOON}' : '{AERIAL_DISH_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];

    final isAerial = type.contains('aerial');
    final aerialOrDish = isAerial ? 'aerial' : 'satellite dish';
    // {A_AN} is the first word of this sentence in the bank template
    // ("{A_AN} {AERIAL_OR_DISH} attached to the chimney is..."), so the
    // article must be capitalized here rather than left lowercase like a
    // normal mid-sentence substitution.
    final aAn = isAerial ? 'An' : 'A';

    template = template
        .replaceAll('{AERIAL_OR_DISH}', aerialOrDish)
        .replaceAll('{A_AN}', aAn)
        .replaceAll('{DISH_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_safety_hazard'])) {
      final extra = _sub(phraseCode, '{AERIAL_DISH_REPAIR_NOW_SAFETY_HAZARD}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(
            _normalize(extra.replaceAll('{AERIAL_OR_DISH}', aerialOrDish))));
      }
    }
    return phrases;
  }

  List<String> _rwgWeatherCondition(Map<String, String> answers) {
    final weather = _cleanLower(
      _firstNonEmpty(
          answers, const ['actv_weather_condition', 'llMainContainer']),
    );
    if (weather.isEmpty) return const [];
    final phraseCode = '{E_RAINWATER_GOODS_WEATHER_CONDITION}';
    final subCode = weather.contains('wet')
        ? '{WEATHER_CONDITION_WET}'
        : '{WEATHER_CONDITION_DRY}';
    final phrases = <String>[];
    final base = _sub(phraseCode, subCode);
    if (base.isNotEmpty) {
      phrases.addAll(_split(_normalize(base)));
    }
    if (_isChecked(answers['cb_leakes_noted'])) {
      final extra = _sub(phraseCode, '{WEATHER_CONDITION_LEAKES_NOTES}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _rwgBlocked(Map<String, String> answers) {
    if (!_isChecked(answers['cb_blocked_rwg'])) return const [];
    return _split(
        _normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_BLOCKED}')));
  }

  List<String> _rwgOpenRunoffs(Map<String, String> answers) {
    if (!_isChecked(answers['cb_open_runoffs'])) return const [];
    return _split(
        _normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_OPEN_RUNOFFS}')));
  }

  List<String> _rwgNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(
        _normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_NOT_INSPECTED}')));
  }

  List<String> _roofWeather(Map<String, String> answers) {
    final condition = _cleanLower(
      _firstNonEmpty(answers, const ['actv_status', 'llMainContainer']),
    );
    if (condition.isEmpty) return const [];
    final phraseCode = '{E_RC_WEATHER_CONDITION}';
    final subCode =
        condition.contains('wet') ? '{CONDITION_WET}' : '{CONDITION_DRY}';
    final phrases = <String>[];
    final base = _sub(phraseCode, subCode);
    if (base.isNotEmpty) {
      phrases.addAll(_split(_normalize(base)));
    }
    if (_isChecked(answers['cb_weather_leaks_noted'])) {
      final extra = _sub(phraseCode, '{CONDITION_LEAKS_NOTED}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _roofAsbestos(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_roof_covering', 'cb_verge', 'cb_soffits', 'cb_other_654'],
      answers,
      {
        'cb_roof_covering': 'Roof covering',
        'cb_verge': 'Verge',
        'cb_soffits': 'Soffits',
        'cb_other_654': 'Other',
      },
    );
    _addOther(answers, 'cb_other_654', 'et_other_151', items);
    if (items.isEmpty) return const [];
    var template = _sub('{E_ROOF_COVERING}', '{RC_CONTAINS_ASBESTOS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll(
        '{RC_CONTAINS_ASBESTOS}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _roofSpreading(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_front', 'cb_side', 'cb_rear'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
      },
    );
    if (locations.isEmpty) return const [];
    var template = _sub('{E_ROOF_COVERING}', '{RC_ROOF_SPREADING}');
    if (template.isEmpty) return const [];
    template = template.replaceAll(
        '{RC_ROOF_SPREADING_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _roofRepairPoorRoof(Map<String, String> answers) {
    if (!_isChecked(answers['cb_repair_soon_70'])) return const [];
    final template =
        _sub('{E_ROOF_COVERING_REPAIR}', '{RC_POOR_ROOF_CONDITION}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _roofNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_main_building']) &&
        !_isChecked(answers['cb_back_addition']) &&
        !_isChecked(answers['cb_extension']) &&
        !_isChecked(answers['cb_bay_window']) &&
        !_isChecked(answers['cb_dormer_window']) &&
        !_isChecked(answers['cb_other_601'])) {
      return const [];
    }
    final locations = _labelsFor(
      [
        'cb_main_building',
        'cb_back_addition',
        'cb_extension',
        'cb_bay_window',
        'cb_dormer_window',
        'cb_other_601'
      ],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_dormer_window': 'Dormer window',
        'cb_other_601': 'Other',
      },
    );
    _addOther(answers, 'cb_other_601', 'et_other_691', locations);
    final assumed = _cleanLower(answers['actv_assumed_type']);
    if (locations.isEmpty) return const [];
    var template = _sub('{E_ROOF_COVERING}', '{E_RC_NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll(
            '{RC_NOT_INSPECTED_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{RC_NOT_INSPECTED_ASSUMED_TYPE}', assumed);
    return _split(_normalize(template));
  }

  List<String> _windowsNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{E_WINDOWS}', '{NOT_INSPECTED}')));
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

  List<String> _insidePropertyLimitations(Map<String, String> answers) {
    final phrases = <String>[];

    if (_isChecked(answers['ch1'])) {
      final chimney = _sub('{F_INSIDE_THE_PROPERTY}',
          '{LIMITATIONS_CHIMNEY_FLUE_NOT_INSPECTED}');
      if (chimney.isNotEmpty) {
        phrases.addAll(_split(_normalize(chimney)));
      }
    }

    if (_isChecked(answers['ch2'])) {
      final reasons = _labelsFor(
        [
          'cb_statuslimited_roof_height',
          'cb_floors_not_safe_to_walk_on',
          'cb_some_or_all_of_the_floors_are_boarded',
          'cb_excessive_storage_of_personal_goods',
          'ch3',
          'ch4',
          'ch5',
          'ch6',
        ],
        answers,
        {
          'cb_statuslimited_roof_height': 'Limited roof height',
          'cb_floors_not_safe_to_walk_on': 'The floors are not safe to walk on',
          'cb_some_or_all_of_the_floors_are_boarded':
              'Some or all of the floors are boarded',
          'cb_excessive_storage_of_personal_goods':
              'Excessive storage of personal goods',
          'ch3': 'No rear access',
          'ch4': 'Airport',
          'ch5': 'Motor way',
          'ch6': 'Other',
        },
      );
      _addOther(answers, 'ch6', 'etGroundTypeOther', reasons);

      var roof = _sub('{F_INSIDE_THE_PROPERTY}',
          '{LIMITATIONS_ROOF_TIMBER_NOT_FULLY_INSPECTED}');
      if (roof.isNotEmpty && reasons.isNotEmpty) {
        roof = roof.replaceAll(
          '{LIM_RT_NOT_FULLY_INSPECTED_REASON}',
          _toWords(reasons),
        );
        phrases.addAll(_split(_normalize(roof)));
      }
    }

    if (phrases.isNotEmpty) {
      final standard = _sub('{F_INSIDE_THE_PROPERTY}', '{STANDARD_TEXT}');
      if (standard.isNotEmpty) {
        phrases.addAll(_split(_normalize(standard)));
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

  List<String> _risksRiskToBuilding(Map<String, String> answers) {
    // Section J1 (Risk to Building) - approved bank imported in Phase 4.
    final phrases = <String>[];

    final movement = (answers['actv_movement_status'] ?? '').trim();
    final movementSub =
        _riskStatusSubCode(movement, prefix: '{BUILDING_MOVEMENTS_STATUS');
    if (movementSub != null) {
      final template = _sub('{RISK_TO_BUILDING}', '$movementSub}');
      if (template.isNotEmpty) phrases.addAll(_splitResolved(template));
    }

    final subsidence = (answers['actv_subsidence_status'] ?? '').trim();
    final subsidenceSub =
        _riskStatusSubCode(subsidence, prefix: '{BUILDING_SUBSIDENCE_STATUS');
    if (subsidenceSub != null) {
      var template = _sub('{RISK_TO_BUILDING}', '$subsidenceSub}');
      if (template.isNotEmpty) {
        final locations = _labelsFor(
          [
            'cb_window_and_door_lintel',
            'cb_extension_joints',
            'cb_bay_windows',
            'cb_other_619'
          ],
          answers,
          {
            'cb_window_and_door_lintel': 'window and door lintel',
            'cb_extension_joints': 'extension joints',
            'cb_bay_windows': 'bay windows',
            'cb_other_619': 'other',
          },
        );
        _addOther(answers, 'cb_other_619', 'et_other_604', locations);
        template = locations.isEmpty
            ? template.replaceAll(' around {RTB_SUBSIDENCE_INVESTIGATE_LOCATION}', '')
            : template.replaceAll(
                '{RTB_SUBSIDENCE_INVESTIGATE_LOCATION}',
                _toWords(locations).toLowerCase(),
              );
        phrases.addAll(_splitResolved(template));
      }
    }

    final dampness = (answers['actv_dampness_status'] ?? '').trim();
    final dampnessSub =
        _riskStatusSubCode(dampness, prefix: '{BUILDING_DAMPNESS_STATUS');
    if (dampnessSub != null) {
      // Legacy dampness has 3 states: NONE / IMPLEMENT_ACTION / INVESTIGATE.
      final key = dampnessSub == '{BUILDING_DAMPNESS_STATUS_NOTED'
          ? '{BUILDING_DAMPNESS_STATUS_IMPLEMENT_ACTION}'
          : '$dampnessSub}';
      final template = _sub('{RISK_TO_BUILDING}', key);
      if (template.isNotEmpty) phrases.addAll(_splitResolved(template));
    }

    final timber = (answers['actv_timber_sefect_status'] ?? '').trim();
    final timberSub =
        _riskStatusSubCode(timber, prefix: '{BUILDING_TIMBER_DEFECT_STATUS');
    if (timberSub != null) {
      // Legacy timber defect bank only has NONE / NOTED (no INVESTIGATE tier).
      final key = timberSub == '{BUILDING_TIMBER_DEFECT_STATUS_INVESTIGATE'
          ? '{BUILDING_TIMBER_DEFECT_STATUS_NOTED}'
          : '$timberSub}';
      final template = _sub('{RISK_TO_BUILDING}', key);
      if (template.isNotEmpty) phrases.addAll(_splitResolved(template));
    }

    if (_isChecked(answers['cb_near_by_tree'])) {
      final template = _sub('{RISK_TO_BUILDING}', '{BUILDING_NEAR_BY_TREES}');
      if (template.isNotEmpty) phrases.addAll(_splitResolved(template));
    }

    return phrases;
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

  List<String> _propertyType(Map<String, String> answers) {
    final type = (answers['android_material_design_spinner'] ?? '').trim();
    if (type.isEmpty) return const [];

    if (type.toLowerCase() == 'flat') {
      final template = _phraseTexts['{D_PROPERTY_TYPE_FLAT}'] ?? '';
      if (template.isEmpty) return const [];
      final bedrooms =
          (answers['android_material_design_spinner7'] ?? '').trim();
      final flatStyle =
          (answers['android_material_design_spinner8'] ?? '').trim();
      final floorLocation =
          (answers['android_material_design_spinner5'] ?? '').trim();
      final noOfStorey =
          (answers['android_material_design_spinner6'] ?? '').trim();
      final totalFlats =
          (answers['android_material_design_spinner9'] ?? '').trim();
      // All five details are required to complete this sentence; a literal
      // "..." placeholder for any missing one is not acceptable in a
      // finalised client report, so wait until every field is answered.
      if (bedrooms.isEmpty ||
          flatStyle.isEmpty ||
          floorLocation.isEmpty ||
          noOfStorey.isEmpty ||
          totalFlats.isEmpty) {
        return const [];
      }
      final resolved = _normalize(template)
          .replaceAll('{FLAT_NO_OF_BEDROOMS}', bedrooms)
          .replaceAll('{FLAT_TYPE}', flatStyle.toLowerCase())
          .replaceAll('{FLAT_FLOOR_LOCATION}', floorLocation.toLowerCase())
          .replaceAll('{FLAT_NO_OF_STOREY}', noOfStorey.toLowerCase())
          .replaceAll('{FLAT_TOTAL_FLATS}', totalFlats.toLowerCase());
      return _split(resolved);
    }

    final template = _phraseTexts['{D_PROPERTY_TYPE_HOUSE}'] ?? '';
    if (template.isEmpty) return const [];
    final subType = (answers['android_material_design_spinner3'] ?? '').trim();
    final bedrooms = (answers['android_material_design_spinner4'] ?? '').trim();
    if (subType.isEmpty || bedrooms.isEmpty) return const [];
    var resolved = _normalize(template)
        .replaceAll('{HOUSE_SUB_TYPE}', subType.toLowerCase())
        .replaceAll('{HOUSE_TYPE}', type.toLowerCase())
        .replaceAll('{HOUSE_NO_OF_BEDROOMS}', bedrooms);
    // The template's trailing "bedrooms" is fixed plural; singularise it
    // when the count is 1 ("1 bedrooms" -> "1 bedroom").
    if (bedrooms.trim() == '1') {
      resolved = resolved.replaceFirst('1 bedrooms', '1 bedroom');
    }
    return _split(resolved);
  }

  List<String> _propertyConstruction(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['ch1']))
      items.add('traditional materials and techniques');
    if (_isChecked(answers['ch2'])) items.add('solid wall');
    if (_isChecked(answers['ch3'])) items.add('cavity wall');
    if (_isChecked(answers['ch4'])) items.add('timber frame');
    if (_isChecked(answers['ch5'])) items.add('steel frame');
    if (_isChecked(answers['ch6'])) items.add('concrete wall');
    if (_isChecked(answers['ch8'])) items.add('precast concrete panels');
    if (_isChecked(answers['ch9'])) items.add('system-built');
    if (_isChecked(answers['ch7'])) {
      final other = (answers['etPropertyTypeOther'] ?? '').trim();
      items.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (items.isEmpty) return const [];
    // Approved bank: {D_CONSTRUCTION}::{CONSTRUCTION_TYPE_AREA}
    final template = _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_TYPE_AREA}');
    final result = <String>[];
    if (template.isEmpty) {
      result.add(
        'The property is believed to be built using ${_toWords(items)} '
            'construction.',
      );
    } else {
      result.addAll(_split(_normalize(
        template.replaceAll('{CONSTRUCTION_TYPE}', _toWords(items)),
      )));
    }
    // Spec conditional — "If timber or steel frame is selected, add this":
    // the Modern Building Design advisory (approved bank sub-key).
    if (_isChecked(answers['ch4']) || _isChecked(answers['ch5'])) {
      final modern =
          _sub('{D_CONSTRUCTION}', '{CONDITION_TYPE_OF_CONSTRUCTION}');
      if (modern.isNotEmpty) result.addAll(_split(_normalize(modern)));
    }
    // Spec conditional — "If concrete wall or precast concrete panels are
    // selected, add this": the mortgage-lending advisory (approved bank
    // sub-key). Fires for concrete wall (ch6) or precast concrete panels
    // (ch8); system-built (ch9) is not covered by the spec's advisory.
    if (_isChecked(answers['ch6']) || _isChecked(answers['ch8'])) {
      final concrete =
          _sub('{D_CONSTRUCTION}', '{CONCRETE_CONSTRUCTION_ADVISORY}');
      if (concrete.isNotEmpty) result.addAll(_split(_normalize(concrete)));
    }
    return result;
  }

  List<String> _propertyBuiltYear(Map<String, String> answers) {
    final year = (answers['android_material_design_spinner'] ?? '').trim();
    if (year.isEmpty) return const [];
    final source = (answers['android_material_design_spinner5'] ?? '')
        .trim()
        .toLowerCase();
    final key = source.contains('vendor')
        ? '{D_YEAR_BUILT_VENDOR_TOLD_ME}'
        : '{D_YEAR_BUILT_I_THINK}';
    final template = _phraseTexts[key] ?? '';
    if (template.isEmpty) return const [];
    final resolved = _normalize(template).replaceAll('{PRO_BUILT_YEAR}', year);
    return _split(resolved);
  }

  List<String> _propertyRoof(Map<String, String> answers) {
    final types = <String>[];
    if (_isChecked(answers['ch1'])) types.add('flat');
    if (_isChecked(answers['ch2'])) types.add('pitched');
    final roofMaterial = <String>[];
    if (_isChecked(answers['ch8'])) roofMaterial.add('concrete');
    if (_isChecked(answers['ch9'])) roofMaterial.add('clay');
    if (_isChecked(answers['ch10'])) roofMaterial.add('natural');
    if (_isChecked(answers['ch11'])) roofMaterial.add('composite');
    if (_isChecked(answers['ch12'])) roofMaterial.add('mineral felt');
    if (_isChecked(answers['ch13'])) roofMaterial.add('rubber');
    if (_isChecked(answers['ch14'])) roofMaterial.add('fiberglass');
    if (_isChecked(answers['ch15'])) roofMaterial.add('single ply membrane');
    if (_isChecked(answers['ch_plastic'])) roofMaterial.add('plastic');
    if (_isChecked(answers['ch_asphalt'])) roofMaterial.add('asphalt');
    if (_isChecked(answers['ch_polycarbonate']))
      roofMaterial.add('polycarbonate');
    if (_isChecked(answers['ch16'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      roofMaterial.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final coverType = <String>[];
    if (_isChecked(answers['ch6'])) coverType.add('tiles');
    if (_isChecked(answers['ch7'])) coverType.add('sheets');
    if (_isChecked(answers['ch_slates'])) coverType.add('slates');
    if (_isChecked(answers['ch_coatings'])) coverType.add('coatings');
    if (_isChecked(answers['ch17'])) {
      final other = (answers['etCoveredTypeOther'] ?? '').trim();
      coverType.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (types.isEmpty && roofMaterial.isEmpty && coverType.isEmpty) {
      return const [];
    }
    // Approved bank: {D_CONSTRUCTION}::{CONSTRUCTION_ROOF_AREA}. Emit only
    // when the sentence can be completed - partial data would otherwise
    // produce fragments like "covered in ." (client-reported defect class).
    if (types.isEmpty || (roofMaterial.isEmpty && coverType.isEmpty)) {
      return const [];
    }
    if (types.length > 1 || roofMaterial.length > 1 || coverType.length > 1) {
      final forms = types.length == 1
          ? 'a ${types.single} roof form'
          : 'a combination of ${_toWords(types)} roof forms';
      final hasCoverings = roofMaterial.isNotEmpty;
      final hasFinishes = coverType.isNotEmpty;
      final key = hasCoverings && hasFinishes
          ? '{D_CONSTRUCTION}::{CONSTRUCTION_ROOF_COMPOSITE}'
          : hasCoverings
              ? '{D_CONSTRUCTION}::{CONSTRUCTION_ROOF_COMPOSITE_COVERING}'
              : '{D_CONSTRUCTION}::{CONSTRUCTION_ROOF_COMPOSITE_FINISH}';
      final fallback = hasCoverings && hasFinishes
          ? 'The main building has {ROOF_FORMS}. The roof coverings comprise '
              '{ROOF_COVERINGS}, finished in {ROOF_FINISHES}.'
          : hasCoverings
              ? 'The main building has {ROOF_FORMS}. The roof coverings '
                  'comprise {ROOF_COVERINGS}.'
              : 'The main building has {ROOF_FORMS}. The roof coverings are '
                  'formed in {ROOF_FINISHES}.';
      var composite = _phraseTexts[key] ?? fallback;
      composite = composite
          .replaceAll('{ROOF_FORMS}', forms)
          .replaceAll('{ROOF_COVERINGS}', _toWords(roofMaterial))
          .replaceAll('{ROOF_FINISHES}', _toWords(coverType));
      return _splitResolved(composite);
    }
    var template = _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_ROOF_AREA}');
    if (template.isEmpty) {
      template = 'The main roof is of {CONTSTRUCTION_ROOF_TYPE} construction '
          'formed with {CONTSTRUCTION_ROOF_BUILT_WITH} structural members. '
          'The roof covering is formed in {CONSTRUCTION_ROOF_COVERED_WITH} '
          '{CONTSTRUCTION_ROOF_MATERIAL}.';
    }
    // This screen does not capture the roof structure build-up; drop that
    // clause rather than leaving an empty slot (RICS L2 wording).
    template = template.replaceAll(
      ' formed with {CONTSTRUCTION_ROOF_BUILT_WITH} structural members',
      '',
    );
    template = template
        .replaceAll('{CONTSTRUCTION_ROOF_TYPE}', _toWords(types))
        .replaceAll('{CONSTRUCTION_ROOF_COVERED_WITH}', _toWords(roofMaterial))
        .replaceAll('{CONTSTRUCTION_ROOF_MATERIAL}', _toWords(coverType));
    return _splitResolved(template);
  }

  List<String> _propertyGroundArea(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['ch1'])) items.add('residential');
    if (_isChecked(answers['ch2'])) items.add('commercial');
    if (_isChecked(answers['ch3'])) items.add('rural');
    if (_isChecked(answers['ch4'])) items.add('conservation');
    if (_isChecked(answers['ch5'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      if (other.isNotEmpty) items.add(other.toLowerCase());
    }
    if (items.isEmpty) return const [];
    final key = items.length == 1
        ? '{D_GROUND_AREA_SINGLE}'
        : '{D_GROUND_AREA_MIXED}';
    final fallback = items.length == 1
        ? 'The property is situated in a predominantly {AREA_TYPE} area.'
        : 'The surrounding area has a mixed {AREA_TYPE} character.';
    final template = _phraseTexts[key] ?? fallback;
    return _splitResolved(
      template.replaceAll('{AREA_TYPE}', _toWords(items)),
    );
  }

  List<String> _propertyExtended(Map<String, String> answers) {
    final status =
        (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('not extended')) {
      return _resolve('{D_PRO_EXTENDED_STATUS_NOT_EXTENDED}');
    }
    final locations = <String>[];
    if (_isChecked(answers['ch1'])) locations.add('front');
    if (_isChecked(answers['ch2'])) locations.add('side');
    if (_isChecked(answers['ch3'])) locations.add('rear');
    if (_isChecked(answers['ch4'])) {
      final other = (answers['etFloodingOther'] ?? '').trim();
      locations.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final location = locations.isNotEmpty
        ? _toWords(locations)
        : (answers['android_material_design_spinner3'] ?? '').trim();
    final year = (answers['textView3'] ?? '').trim();
    // Both details are required to complete this sentence; a literal "..."
    // placeholder is not acceptable in a finalised client report, so wait
    // until the surveyor has answered both.
    if (status == 'known') {
      if (location.isEmpty || year.isEmpty) return const [];
      final template = _phraseTexts['{D_PRO_EXTENDED_STATUS_KNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_EXTENDED_LOCATION}', location.toLowerCase())
          .replaceAll('{PRO_EXTENDED_DATE}', year);
      return _split(resolved);
    }
    if (status == 'unknown') {
      if (location.isEmpty) return const [];
      final template = _phraseTexts['{D_PRO_EXTENDED_STATUS_UNKNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_EXTENDED_LOCATION}', location.toLowerCase());
      return _split(resolved);
    }
    return const [];
  }

  List<String> _extendedWall(Map<String, String> answers) {
    final wallTypes = <String>[];
    if (_isChecked(answers['ch1'])) wallTypes.add('cavity wall');
    if (_isChecked(answers['ch2'])) wallTypes.add('cavity brick wall');
    if (_isChecked(answers['ch3'])) wallTypes.add('solid wall');
    if (_isChecked(answers['ch4'])) wallTypes.add('solid bounded brick wall');
    if (_isChecked(answers['ch5'])) wallTypes.add('stud wall');
    if (_isChecked(answers['ch6'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      wallTypes.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final finishes = <String>[];
    if (_isChecked(answers['ch7'])) finishes.add('painted');
    if (_isChecked(answers['ch8'])) finishes.add('pebble dash');
    if (_isChecked(answers['ch9'])) finishes.add('mock tudor');
    if (_isChecked(answers['ch10'])) {
      final other = (answers['etFinishesOtherNew'] ?? '').trim();
      finishes.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final cladding = <String>[];
    if (_isChecked(answers['ch11'])) cladding.add('tiles');
    if (_isChecked(answers['ch12'])) cladding.add('timber');
    if (_isChecked(answers['ch13'])) cladding.add('weathered board');
    if (_isChecked(answers['ch14'])) cladding.add('profile sheets');
    if (_isChecked(answers['ch15'])) cladding.add('shingle plates');
    if (_isChecked(answers['ch16'])) cladding.add('compressed flat panel');
    if (_isChecked(answers['ch17'])) cladding.add('insulated cladding');
    if (_isChecked(answers['ch18'])) {
      final other = (answers['etCladdingFinishesOther'] ?? '').trim();
      cladding.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final renderedArea =
        (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    final renderedQuality = (answers['android_material_design_spinner2'] ?? '')
        .trim()
        .toLowerCase();
    final claddingArea = (answers['android_material_design_spinner4'] ?? '')
        .trim()
        .toLowerCase();
    if (wallTypes.isEmpty &&
        finishes.isEmpty &&
        cladding.isEmpty &&
        renderedArea.isEmpty &&
        renderedQuality.isEmpty &&
        claddingArea.isEmpty) {
      return const [];
    }
    // Approved bank: {D_CONSTRUCTION} external wall sentences. This screen
    // (id `activity_extended_wall`, tree title "External Wall") is the
    // Construction group's External Walls / Finishes / Cladding element.
    final phrases = <String>[];
    if (wallTypes.isNotEmpty) {
      var template = _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_EXT_WALL_AREA}');
      if (template.isEmpty) {
        template = 'The main external walls are built of '
            '{CONSTRUCTION_EXT_WALL_TYPE} construction.';
      }
      phrases.addAll(_splitResolved(
        template.replaceAll(
          '{CONSTRUCTION_EXT_WALL_TYPE}',
          _toWords(wallTypes),
        ),
      ));
    }
    if (finishes.isNotEmpty || renderedArea.isNotEmpty) {
      var template =
          _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_EXT_WALL_FINISHES}');
      if (template.isEmpty) {
        template = 'Externally, the main walls are '
            '{CONSTRUCTION_EXT_WALL_RENDERED_AREA} rendered '
            '{CONSTRUCTION_EXT_WALL_RENDERED_TYPE} with '
            '{CONSTRUCTION_EXT_WALL_RENDERED_FINISHES} finishes.';
      }
      if (finishes.isEmpty) {
        template = template.replaceAll(
          'with {CONSTRUCTION_EXT_WALL_RENDERED_FINISHES} finishes',
          '',
        );
      }
      phrases.addAll(_splitResolved(
        template
            .replaceAll('{CONSTRUCTION_EXT_WALL_RENDERED_AREA}', renderedArea)
            .replaceAll(
              '{CONSTRUCTION_EXT_WALL_RENDERED_TYPE}',
              renderedQuality,
            )
            .replaceAll(
              '{CONSTRUCTION_EXT_WALL_RENDERED_FINISHES}',
              _toWords(finishes),
            ),
      ));
    }
    if (cladding.isNotEmpty) {
      var template =
          _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_EXT_WALL_CLADDING}');
      if (template.isEmpty) {
        template = 'The main walls are {CONSTRUCTION_EXT_WALL_CLADDING_AREA} '
            'cladded with {CONSTRUCTION_EXT_WALL_CLADDING_FINISHES} '
            'finishing.';
      }
      phrases.addAll(_splitResolved(
        template
            .replaceAll('{CONSTRUCTION_EXT_WALL_CLADDING_AREA}', claddingArea)
            .replaceAll(
              '{CONSTRUCTION_EXT_WALL_CLADDING_FINISHES}',
              _toWords(cladding),
            ),
      ));
    }
    return phrases;
  }

  List<String> _propertyParking(Map<String, String> answers) {
    final status =
        (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('no parking')) {
      final text = _phraseTexts['{D_GROUND}::{NO_PARKING}'] ?? '';
      if (text.isNotEmpty) return _split(_normalize(text));
      return const ['The property does not come with parking.'];
    }
    final types = <String>[];
    if (_isChecked(answers['ch1'])) types.add('private');
    if (_isChecked(answers['ch2'])) types.add('allocated');
    if (_isChecked(answers['ch3'])) types.add('communal');
    if (_isChecked(answers['ch4'])) types.add('off street');
    if (_isChecked(answers['ch5'])) types.add('pay and display');
    if (_isChecked(answers['ch6'])) types.add('residential parking');
    if (types.isEmpty) return const ['The property comes with parking.'];
    // "Residential parking" already ends in the word this sentence
    // appends as a suffix; skip the suffix when the last selected type
    // already supplies it, to avoid "residential parking parking".
    final wordsText = _toWords(types);
    final suffix = wordsText.toLowerCase().endsWith('parking') ? '' : ' parking';
    return ['The property comes with $wordsText$suffix.'];
  }

  List<String> _sectionDGarden(Map<String, String> answers, String gardenName) {
    final surfaceTypes = <String>[];
    if (_isChecked(answers['ch1'])) surfaceTypes.add('paved');
    if (_isChecked(answers['ch2'])) surfaceTypes.add('lawned');
    if (_isChecked(answers['ch3'])) surfaceTypes.add('decked');
    if (_isChecked(answers['ch4'])) surfaceTypes.add('laid with gravel');
    if (_isChecked(answers['ch5']))
      surfaceTypes.add('laid with stone chippings');
    if (_isChecked(answers['ch6']))
      surfaceTypes.add('laid with tile chippings');
    if (_isChecked(answers['ch7'])) {
      final other = (answers['etGroundTypeOther'] ?? '').trim();
      surfaceTypes.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final noBoundary = _isChecked(answers['ch20']);
    final fencing = <String>[];
    if (!noBoundary) {
      if (_isChecked(answers['ch8'])) fencing.add('timber');
      if (_isChecked(answers['ch9'])) fencing.add('brick wall');
      if (_isChecked(answers['ch10'])) fencing.add('concrete wall');
      if (_isChecked(answers['ch11'])) fencing.add('wire mesh');
      if (_isChecked(answers['ch12'])) fencing.add('hedges');
      if (_isChecked(answers['ch13'])) fencing.add('shrubs');
      if (_isChecked(answers['ch14'])) {
        final other = (answers['etGroundBoundryFencingOther'] ?? '').trim();
        fencing.add(other.isNotEmpty ? other.toLowerCase() : 'other');
      }
    }
    if (surfaceTypes.isEmpty && !noBoundary && fencing.isEmpty) return const [];
    return _approvedGardenPhrases(
      gardenName,
      _toWords(surfaceTypes),
      noBoundary: noBoundary,
      fencingText: _toWords(fencing),
    );
  }

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

  List<String> _propertyConverted(Map<String, String> answers) {
    final status =
        (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('not converted')) {
      return _resolve('{D_PRO_CONVERSION_STATUS_NOT_CONVERTED}');
    }
    final proType = (answers['android_material_design_spinner2'] ?? '').trim();
    final subType = (answers['android_material_design_spinner3'] ?? '').trim();
    final year = (answers['textView3'] ?? '').trim();
    // All details are required to complete these sentences; a literal "..."
    // placeholder is not acceptable in a finalised client report, so wait
    // until the surveyor has answered them.
    if (status == 'known') {
      if (subType.isEmpty || proType.isEmpty || year.isEmpty) return const [];
      final template = _phraseTexts['{D_PRO_CONVERSION_STATUS_KNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_CONVERSION_PRO_SUB_TYPE}', subType.toLowerCase())
          .replaceAll('{PRO_CONVERSION_PRO_TYPE}', proType.toLowerCase())
          .replaceAll('{PRO_CONVERSION_DATE}', year);
      return _split(resolved);
    }
    if (status == 'unknown') {
      if (subType.isEmpty || proType.isEmpty) return const [];
      final template = _phraseTexts['{D_PRO_CONVERSION_STATUS_UNKNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_CONVERSION_PRO_SUB_TYPE}', subType.toLowerCase())
          .replaceAll('{PRO_CONVERSION_PRO_TYPE}', proType.toLowerCase());
      return _split(resolved);
    }
    return const [];
  }

  List<String> _propertyFlatInfo(Map<String, String> answers) {
    String pickValue(String dropdownId, String otherId) {
      final dropdown = (answers[dropdownId] ?? '').trim();
      if (dropdown.toLowerCase() == 'other') {
        final other = (answers[otherId] ?? '').trim();
        return other.isNotEmpty ? other : dropdown;
      }
      if (dropdown.isNotEmpty) return dropdown;
      return (answers[otherId] ?? '').trim();
    }

    final onFloor =
        pickValue('android_material_design_spinner', 'etPropertyOnTheFloor');
    if (onFloor.isEmpty) return const [];
    final template = _phraseTexts['{D_FLAT_INFORMATION}'] ?? '';
    if (template.isEmpty) return const [];
    final noOfStorey =
        pickValue('android_material_design_spinner2', 'etNoOFStorey');
    final accessVia =
        pickValue('android_material_design_spinner3', 'etAccessVia');
    final accessElevation =
        pickValue('android_material_design_spinner4', 'etAccesElevation');
    // All four details are required to complete this sentence; a literal
    // "..." placeholder is not acceptable in a finalised client report, so
    // wait until the surveyor has answered them all.
    if (noOfStorey.isEmpty || accessVia.isEmpty || accessElevation.isEmpty) {
      return const [];
    }
    final resolved = _normalize(template)
        .replaceAll('{FLAT_INFO_PRO_ON_FLOOR}', onFloor.toLowerCase())
        .replaceAll('{FLAT_INFO_PRO_NO_OF_STOREY}', noOfStorey)
        .replaceAll('{FLAT_INFO_PRO_ACCESS_VIA}', accessVia.toLowerCase())
        .replaceAll(
            '{FLAT_INFO_PRO_ACCESS_ELEVATION}', accessElevation.toLowerCase());
    return _split(resolved);
  }

  List<String> _constructionFloor(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['ch1'])) items.add('suspended timber');
    if (_isChecked(answers['ch2'])) items.add('solid');
    if (_isChecked(answers['ch3'])) items.add('suspended beam and block');
    if (_isChecked(answers['ch4'])) items.add('in situ-concrete');
    if (_isChecked(answers['ch5'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      items.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (items.isEmpty) return const [];
    final buildType =
        (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    final prefix =
        buildType.contains('mixture') ? 'of a mixture of' : 'mainly of';
    // Approved bank: {D_CONSTRUCTION}::{CONSTRUCTION_FLOOR_AREA}
    var template = _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_FLOOR_AREA}');
    if (template.isEmpty) {
      template = 'The floors of the property are built '
          '{CONSTRUCTION_FLOOR_BUILT_TYPE} {CONSTRUCTION_FLOOR_BUILT_WITH} '
          'floor construction.';
    }
    return _splitResolved(
      template
          .replaceAll('{CONSTRUCTION_FLOOR_BUILT_TYPE}', prefix)
          .replaceAll('{CONSTRUCTION_FLOOR_BUILT_WITH}', _toWords(items)),
    );
  }

  List<String> _constructionWindow(Map<String, String> answers) {
    final glazing = <String>[];
    if (_isChecked(answers['ch1'])) glazing.add('single');
    if (_isChecked(answers['ch2'])) glazing.add('double');
    if (_isChecked(answers['ch3'])) glazing.add('secondary');
    if (_isChecked(answers['ch4'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      glazing.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final materials = <String>[];
    if (_isChecked(answers['ch5'])) materials.add('PVC');
    if (_isChecked(answers['ch6'])) materials.add('timber');
    if (_isChecked(answers['ch7'])) materials.add('aluminium');
    if (_isChecked(answers['ch8'])) materials.add('steel');
    if (_isChecked(answers['ch9'])) {
      final other = (answers['etWindowMaterialOther'] ?? '').trim();
      materials.add(other.isNotEmpty ? other : 'other');
    }
    if (glazing.isEmpty) return const [];
    final mixType =
        (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    final prefix = mixType.contains('mixture') ? 'a mixture of' : 'mainly of';
    // Approved bank: {D_CONSTRUCTION}::{CONSTRUCTION_WINDOWS_AREA}
    var template = _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_WINDOWS_AREA}');
    if (template.isEmpty) {
      template = 'The windows are {CONSTUCTION_GLAZED_WITH} '
          '{CONSTRUCTION_GLAZED_TYPE} glazed {CONSTRUCTION_WINDOW_MATERIAL} '
          'units.';
    }
    return _splitResolved(
      template
          .replaceAll('{CONSTUCTION_GLAZED_WITH}', prefix)
          .replaceAll('{CONSTRUCTION_GLAZED_TYPE}', _toWords(glazing))
          .replaceAll('{CONSTRUCTION_WINDOW_MATERIAL}', _toWords(materials)),
    );
  }

  List<String> _gatedCommunity(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner3'] ?? '')
        .trim()
        .toLowerCase();
    if (status != 'yes') return const [];
    final text = _phraseTexts['{D_GROUND}::{GATED_COMMUNITY}'] ?? '';
    if (text.isNotEmpty) return _split(_normalize(text));
    return const ['The property is located within a gated development.'];
  }

  List<String> _energyEfficiency(Map<String, String> answers) {
    // Approved bank: {D_ENERGY} embeds both efficiency and environmental
    // impact ratings in one paragraph; this screen only captures the
    // efficiency half, so substitute just that pair and leave the impact
    // placeholders for _energyEnvironmentalImpact() to fill on its screen.
    final current = (answers['android_material_design_spinner'] ?? '').trim();
    final potential =
        (answers['android_material_design_spinner2'] ?? '').trim();
    // Both values are required to complete this sentence; a literal "..."
    // placeholder is not acceptable in a finalised client report, so wait
    // until the surveyor has answered both.
    if (current.isEmpty || potential.isEmpty) return const [];
    var template = _phraseTexts['{D_ENERGY}'] ?? '';
    if (template.isEmpty) {
      return ['Energy Efficiency: Current $current, Potential $potential.'];
    }
    template = template
        .replaceAll('{ENERGY_EFFICIENCY_CURRENT_VALUE}', current)
        .replaceAll('{ENERGY_EFFICIENCY_POTENTIAL_VALUE}', potential)
        // Environmental impact half is answered on its own screen; keep
        // this screen's output scoped to the energy-efficiency line only.
        .replaceAll(
          RegExp(r'<strong>Environmental Impact:<\/strong>[\s\S]*'),
          '',
        );
    return _splitResolved(template);
  }

  List<String> _energyEnvironmentalImpact(Map<String, String> answers) {
    // Approved bank: {D_ENERGY} - environmental-impact half (see
    // _energyEfficiency above for the paired efficiency half).
    final current = (answers['android_material_design_spinner'] ?? '').trim();
    final potential =
        (answers['android_material_design_spinner2'] ?? '').trim();
    // Both values are required to complete this sentence; a literal "..."
    // placeholder is not acceptable in a finalised client report, so wait
    // until the surveyor has answered both.
    if (current.isEmpty || potential.isEmpty) return const [];
    var template = _phraseTexts['{D_ENERGY}'] ?? '';
    if (template.isEmpty) {
      return [
        'Environmental Impact: Current $current, Potential $potential.',
      ];
    }
    final match =
        RegExp(r'<strong>Environmental Impact:<\/strong>[^<]*').firstMatch(
      template,
    );
    if (match == null) return const [];
    template = match
        .group(0)!
        .replaceAll('{ENVIRONMENT_IMPACT_CURRENT_VALUE}', current)
        .replaceAll('{ENVIRONMENT_IMPACT_POTENTIAL_VALUE}', potential);
    return _splitResolved(template);
  }

  List<String> _estateLocation(Map<String, String> answers) {
    final location = (answers['android_material_design_spinner'] ?? '').trim();
    if (location.isEmpty) return const [];
    // Approved bank: {D_GROUND}::{GROUND_ESTATE_LOCATION}
    var template = _sub('{D_GROUND}', '{GROUND_ESTATE_LOCATION}');
    if (template.isEmpty) {
      return ['The property is on a ${location.toLowerCase()} estate.'];
    }
    return _splitResolved(
      template.replaceAll('{ESTATE_LOCATION}', location.toLowerCase()),
    );
  }

  List<String> _propertyLocationDensity(Map<String, String> answers) {
    final wellNewly = (answers['android_material_design_spinner'] ?? '').trim();
    final from = (answers['android_material_design_spinner2'] ?? '').trim();
    final to = (answers['android_material_design_spinner20'] ?? '').trim();
    if (wellNewly.isEmpty && from.isEmpty && to.isEmpty) return const [];
    final phrases = <String>[];
    final normalizedArea = wellNewly.toLowerCase();
    if (wellNewly.isNotEmpty &&
        normalizedArea != 'yes' &&
        normalizedArea != 'no') {
      final density = from.isNotEmpty
          ? from
          : (to.isNotEmpty ? to : '');
      // Approved bank: {D_LOCATION}::{LOCATION_AREA}
      var template = _sub('{D_LOCATION}', '{LOCATION_AREA}');
      if (template.isEmpty) {
        phrases.add(
          'The property is located in a $normalizedArea established area.',
        );
      } else {
        if (density.isEmpty) {
          // RICS L2 wording: strip the optional density clause when neither
          // density value is captured, leaving the bare area sentence.
          template = template.replaceAll(
            ', and the surrounding development is considered '
                '{LOCATION_SURROUNDING_PROPERTY_DENSITY_FROM} to '
                '{LOCATION_SURROUNDING_PROPERTY_DENSITY_TO} density',
            '',
          );
        } else if (from.isNotEmpty && to.isNotEmpty) {
          if (from.toLowerCase() == to.toLowerCase()) {
            final equalDensity = _phraseTexts[
                    '{D_LOCATION}::{LOCATION_EQUAL_DENSITY}'] ??
                'The property is located in an established '
                    '{LOCATION_DENSITY}-density area.';
            phrases.addAll(_splitResolved(equalDensity.replaceAll(
                '{LOCATION_DENSITY}', from.toLowerCase())));
            return phrases;
          }
          template = template
              .replaceAll('{LOCATION_SURROUNDING_PROPERTY_DENSITY_FROM}',
                  from.toLowerCase())
              .replaceAll(
                  '{LOCATION_SURROUNDING_PROPERTY_DENSITY_TO}', to.toLowerCase());
        } else {
          template = template
              .replaceAll(
                  ' to {LOCATION_SURROUNDING_PROPERTY_DENSITY_TO}', '')
              .replaceAll(
                  '{LOCATION_SURROUNDING_PROPERTY_DENSITY_FROM}',
                  density.toLowerCase());
        }
        phrases.addAll(_splitResolved(
          template.replaceAll('{LOCATION_ESTABLISHED_AREA_TYPE}', normalizedArea),
        ));
      }
    }
    return phrases;
  }

  List<String> _propertyFacilities(Map<String, String> answers) {
    final value = (answers['android_material_design_spinner7'] ?? '')
        .trim()
        .toLowerCase();
    if (value.isEmpty) return const [];
    if (value == 'accessible') {
      final resolved = _resolve('{D_FACILITY_ACCESSIBLE}');
      if (resolved.isNotEmpty) return resolved;
      return const [
        'The local facilities include schools, shops and transport links and appear to be reasonably accessible from the property.',
      ];
    }
    if (value == 'remote') {
      final resolved = _resolve('{D_FACILITY_REMOTE}');
      if (resolved.isNotEmpty) return resolved;
      return const [
        'The property is located in a remote area and is likely to be far away from some of the usual facilities and amenities. Also, because of the location of the property, it is recommended that you contact the utility company to be certain regarding the nature of the drainage connection.',
      ];
    }
    return const [];
  }

  List<String> _propertyLocalEnvironment(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner8'] ?? '')
        .trim()
        .toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('no adverse')) {
      final resolved = _resolve('{D_LOCAL_ENVIRONMENT_NO_ADVERSE}');
      if (resolved.isNotEmpty) return resolved;
      return const [
        'There are no known or apparent adverse local environmental features that are likely to materially affect the property.',
      ];
    }
    final phrases = <String>[];
    final floodSources = <String>[];
    if (_isChecked(answers['ch1'])) floodSources.add('the sea');
    if (_isChecked(answers['ch2'])) floodSources.add('a river');
    if (_isChecked(answers['ch3'])) floodSources.add('a canal');
    if (_isChecked(answers['ch4'])) {
      final other = (answers['etFloodingOther'] ?? '').trim();
      if (other.isNotEmpty) floodSources.add(other.toLowerCase());
    }
    if (floodSources.isNotEmpty) {
      final template = _phraseTexts['{D_LOCAL_ENVIRONMENT_FLOODING}'] ?? '';
      if (template.isNotEmpty) {
        final resolved = _normalize(template).replaceAll(
            '{LOCAL_ENVIRONMENT_CLOSED_TO}', _toWords(floodSources));
        phrases.addAll(_split(resolved));
      } else {
        phrases.add(
          'The property is close to ${_toWords(floodSources)}, which may present a flooding or dampness risk depending on local conditions.',
        );
      }
    }
    final emfSources = <String>[];
    if (_isChecked(answers['ch5'])) emfSources.add('substation');
    if (_isChecked(answers['ch6'])) emfSources.add('pylons');
    if (_isChecked(answers['ch7'])) {
      final other = (answers['etEMFOther'] ?? '').trim();
      if (other.isNotEmpty) emfSources.add(other.toLowerCase());
    }
    if (emfSources.isNotEmpty) {
      final template = _phraseTexts['{D_LOCAL_ENVIRONMENT_EMF}'] ?? '';
      if (template.isNotEmpty) {
        final resolved = _normalize(template)
            .replaceAll('{LOCAL_ENVIRONMENT_CLOSED_TO}', _toWords(emfSources));
        phrases.addAll(_split(resolved));
      } else {
        phrases.add(
          'Potential electromagnetic influences were noted nearby, including ${_toWords(emfSources)}.',
        );
      }
    }
    return phrases;
  }

  List<String> _propertyPrivateRoad(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner3'] ?? '')
        .trim()
        .toLowerCase();
    if (status.isEmpty) return const [];
    final yesLike = <String>{'yes', 'true', 'private', 'likely private'};
    final noLike = <String>{'no', 'false', 'not private'};

    if (yesLike.contains(status)) {
      final text =
          _phraseTexts['{D_LOCATION}::{LOCATION_PRIVATE_PROPERTY_AREA}'] ?? '';
      if (text.isNotEmpty) return _split(_normalize(text));
      return const [
        'The road outside the property is likely to be a private road.'
      ];
    }
    if (noLike.contains(status)) {
      final text =
          _phraseTexts['{D_LOCATION}::{LOCATION_NOT_PRIVATE_ROAD}'] ??
              'The road serving the property is understood to be maintained '
                  'at public expense; your legal adviser should confirm its '
                  'adoption status.';
      return _splitResolved(text);
    }
    return const [];
  }

  List<String> _propertyNoisyArea(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner4'] ?? '')
        .trim()
        .toLowerCase();
    if (status.isEmpty) return const [];
    final sources = <String>[];
    if (_isChecked(answers['ch1'])) sources.add('busy road');
    if (_isChecked(answers['ch2'])) sources.add('train line');
    if (_isChecked(answers['ch3'])) sources.add('train station');
    if (_isChecked(answers['ch4'])) sources.add('airport');
    if (_isChecked(answers['ch5'])) sources.add('motor way');
    if (_isChecked(answers['ch6'])) {
      final other = (answers['etGroundTypeOther'] ?? '').trim();
      if (other.isNotEmpty) sources.add(other.toLowerCase());
    }
    final yesLike = <String>{'yes', 'true', 'fully', 'present', 'adverse'};
    final noLike = <String>{'no', 'false', 'none', 'not present'};
    final noisy = yesLike.contains(status) ||
        (sources.isNotEmpty && !noLike.contains(status));
    if (!noisy) return const [];
    if (sources.isEmpty) {
      final text =
          _phraseTexts['{D_LOCATION}::{D_LOCATION_NOISE_UNSPECIFIED}'] ??
              'External noise was apparent at the time of inspection. Its '
                  'effect on amenity and value will depend on frequency and '
                  'intensity, and you should revisit the area at different '
                  'times before purchase.';
      return _splitResolved(text);
    }
    final template = _sub('{D_LOCATION}', '{D_LOCATION_NEAR_NOISY_AREA}');
    if (template.isEmpty) {
      return ['The property is in a noisy area near ${_toWords(sources)}.'];
    }
    return _split(_normalize(
      template.replaceAll(
          '{LOCATION_NOISY_AREA_TYPE}', _toWords(sources).toLowerCase()),
    ));
  }

  // ── New methods for uncovered screens ──────────────────────────

  // Section D: Residential garden (combined front/rear/communal)
  List<String> _sectionDGardenResidential(Map<String, String> answers) {
    final phrases = <String>[];
    final areas = <String, List<String>>{
      'Front': [
        'android_material_design_spinner',
        'etFrontTypeOther',
        'android_material_design_spinner2',
        'etFrontFencingOther'
      ],
      'Rear': [
        'android_material_design_spinner3',
        'etRearTypeOther',
        'android_material_design_spinner4',
        'etRearFencingOther'
      ],
      'Communal': [
        'android_material_design_spinner5',
        'etCommunalTypeOther',
        'android_material_design_spinner6',
        'etCommunalFencingOther'
      ],
    };
    for (final entry in areas.entries) {
      final gardenType = (answers[entry.value[0]] ?? '').trim();
      final fencing = (answers[entry.value[2]] ?? '').trim();
      if (gardenType.isEmpty && fencing.isEmpty) continue;
      final typeText = gardenType.toLowerCase() == 'other'
          ? (answers[entry.value[1]] ?? 'other').trim().toLowerCase()
          : gardenType.toLowerCase();
      final fenceText = fencing.toLowerCase() == 'other'
          ? (answers[entry.value[3]] ?? 'other').trim().toLowerCase()
          : fencing.toLowerCase();
      phrases.addAll(_approvedGardenPhrases(
        entry.key,
        gardenType.isEmpty ? '' : typeText,
        noBoundary: false,
        fencingText: fencing.isEmpty ? '' : fenceText,
      ));
    }
    return phrases;
  }

  // Section D: Topography
  List<String> _sectionDTopography(Map<String, String> answers) {
    final topography =
        (answers['android_material_design_spinner'] ?? '').trim();
    if (topography.isEmpty) return const [];
    final text = topography.toLowerCase() == 'other'
        ? (answers['etFrontTypeOther'] ?? 'other').trim().toLowerCase()
        : topography.toLowerCase();
    // Approved bank: {D_GROUND}::{GROUND_TOPOGRAPHY}
    var template = _sub('{D_GROUND}', '{GROUND_TOPOGRAPHY}');
    if (template.isEmpty) {
      template = 'The property occupies a relatively {GROUND_TOPOGRAPHY} '
          'ground.';
    }
    return _splitResolved(template.replaceAll('{GROUND_TOPOGRAPHY}', text));
  }

  // Section D: Internal Wall
  List<String> _sectionDInternalWall(Map<String, String> answers) {
    final types = <String>[];
    if (_isChecked(answers['ch1'])) types.add('stud');
    if (_isChecked(answers['ch2'])) types.add('solid');
    if (_isChecked(answers['ch3'])) types.add('lath and plaster');
    if (_isChecked(answers['ch4'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      types.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (types.isEmpty) return const [];
    // Approved bank: {D_CONSTRUCTION}::{CONSTRUCTION_INT_WALL_AREA}
    var template = _sub('{D_CONSTRUCTION}', '{CONSTRUCTION_INT_WALL_AREA}');
    if (template.isEmpty) {
      template = 'The internal walls are built of '
          '{CONSTRUCTION_INT_WALL_PARTITION_TYPE} partitions.';
    }
    return _splitResolved(
      template.replaceAll(
        '{CONSTRUCTION_INT_WALL_PARTITION_TYPE}',
        _toWords(types),
      ),
    );
  }

  // Section D: Listed Building
  List<String> _sectionDListedBuilding(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner'] ?? '').trim();
    if (status.isEmpty) return const [];
    if (status.toLowerCase() == 'yes') {
      // Approved bank: {D_LISTED_BUILDING} (single paragraph, no <br/>).
      final template = _phraseTexts['{D_LISTED_BUILDING}'] ?? '';
      if (template.isNotEmpty) return _splitResolved(template);
      return [
        'The property is a listed building.',
        'Please contact your legal adviser to advise you on the implication of this building status.',
      ];
    }
    final template = _phraseTexts['{D_LISTED_BUILDING_NOT_LISTED}'] ??
        'The property is not understood to be a listed building.';
    return _splitResolved(template);
  }

  // Section D: Other Service
  List<String> _sectionDOtherService(Map<String, String> answers) {
    final hasSolarElectricity = _isChecked(answers['ch1']);
    final hasSolarHotWater = _isChecked(answers['ch2']);

    List<String> resolveSub(String subCode, String fallback) {
      final template = _sub('{ENERGY_OTHER_SERVICES}', subCode);
      if (template.trim().isEmpty) return <String>[fallback];
      return _split(_normalize(template));
    }

    if (!hasSolarElectricity && !hasSolarHotWater) {
      return resolveSub(
        '{ENERGY_OTHER_SERVICES_NONE}',
        'No other energy services were identified.',
      );
    }

    final phrases = <String>[];
    if (hasSolarElectricity) {
      phrases.addAll(resolveSub(
        '{ENERGY_OTHER_SERVICES_SOLAR_ELECTRICITY}',
        'The property has photovoltaic panels that generate electricity.',
      ));
    }
    if (hasSolarHotWater) {
      phrases.addAll(resolveSub(
        '{ENERGY_OTHER_SERVICES_SOLAR_HOT_WATER}',
        'The property has solar water heating panels installed.',
      ));
    }
    return phrases;
  }

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
  List<String> _roofCoveringSummary(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_roof_fit_for_pupose'])) {
      final text = _sub('{E_ROOF_COVERING_REPAIR}', '{ROOF_FIT_FOR_PURPOSE}');
      if (text.isNotEmpty) {
        phrases.addAll(_split(_normalize(text)));
      }
    }
    if (_isChecked(answers['cb_end_of_useful_life'])) {
      final text = _sub('{E_ROOF_COVERING_REPAIR}', '{END_OF_USEFUL_LIFE}');
      if (text.isNotEmpty) {
        phrases.addAll(_split(_normalize(text)));
      }
    }
    return phrases;
  }

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
