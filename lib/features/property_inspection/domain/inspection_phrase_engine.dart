import 'dart:convert';

import '../../../core/utils/number_to_words.dart';

class InspectionPhraseEngine {
  const InspectionPhraseEngine(this._phraseTexts);

  final Map<String, String> _phraseTexts;

  List<String> buildPhrases(String screenId, Map<String, String> answers) {
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
      case 'activity_outside_property_chimney_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_roof_covering_main':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_rainwater_goods_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'actv_condition_rating');
      case 'activity_outside_property_main_walls_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_windows_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_outside_doors_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_conservatory_porch_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_other_joinery_and_finishes_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_outside_property_other_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_grounds_garage_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_grounds_other_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_grounds_other_area_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_grounds_limitations':
        return _groundsLimitations(answers);
      case 'activity_grounds_garage':
        return _groundsGarage(answers);
      case 'activity_grounds_garage_not_inspected':
        return _groundsGarageNotInspected(answers);
      case 'activity_grounds_garage_garage_repair':
        return _groundsGarageRepair(answers);
      case 'activity_grounds_garage_roof_timber_repair':
        return _groundsGarageRoofTimber(answers);
      case 'activity_grounds_garage_safety_hazard_repair':
        return _groundsGarageSafetyHazard(answers);
      case 'activity_grounds_other_grounds':
        return _groundsOtherGrounds(answers);
      case 'activity_grounds_other_front_garden':
        return _groundsGarden(answers, gardenName: 'front', isCommunal: false);
      case 'activity_grounds_other_front_garden__rear_garden':
        return _groundsGarden(answers, gardenName: 'rear', isCommunal: false);
      case 'activity_grounds_other_front_garden__side_garden':
        return _groundsGarden(answers, gardenName: 'side', isCommunal: false);
      case 'activity_grounds_other_front_garden__other_garden':
        return _groundsGarden(answers, gardenName: 'other', isCommunal: false);
      case 'activity_grounds_other_front_garden__communal_garden':
        return _groundsGarden(answers, gardenName: 'communal', isCommunal: true);
      case 'activity_grounds_shared_access':
        return _groundsSharedAccess(answers);
      case 'activity_grounds_other_large_outbuildings':
        return _groundsLargeOutbuilding(answers);
      case 'activity_grounds_other_private_road':
        return _groundsPrivateRoad(answers);
      case 'activity_other_repair_legal_issues':
        return _groundsLegalIssues(answers);
      case 'activity_other_repair_shrinkable_clay':
        return _groundsShrinkableClay(answers);
      case 'activity_grounds_other_repair_fence':
        return _groundsRepairFence(answers);
      case 'activity_grounds_other_repair_shed':
        return _groundsRepairShed(answers);
      case 'activity_other_repair_outbuilding':
        return _groundsRepairOutbuilding(answers);
      case 'activity_other_repair_retaining_walls':
        return _groundsRepairRetainingWalls(answers);
      case 'activity_other_repair_nearby_trees':
        return _groundsRepairNearbyTrees(answers);
      case 'activity_grounds_other_not_inspected':
        return _groundsOtherNotInspected(answers);
      case 'activity_grounds_other_area_right_of_way':
        return _groundsOtherAreaRightOfWay(answers);
      case 'activity_grounds_other_area_knotweed':
        return _groundsOtherAreaKnotweed(answers);
      case 'activity_grounds_other_area_common_garden':
        return _groundsOtherAreaCommonGarden(answers);
      case 'activity_grounds_other_area_lifts':
        return _groundsOtherAreaLifts(answers);
      case 'activity_grounds_other_area_flooding':
        return _groundsOtherAreaFlooding(answers);
      case 'activity_grounds_other_area_emf':
        return _groundsOtherAreaEmf(answers);
      case 'activity_grounds_other_area_not_inspected':
        return _groundsOtherAreaNotInspected(answers);
      case 'activity_services_electricity_main_screen':
        return _servicesElectricityMain(answers);
      case 'activity_service_about_electricity':
        return _servicesElectricityMains(answers);
      case 'activity_services_solar_power':
        return _servicesSolarPower(answers);
      case 'activity_services_electricity_repair_loose_panels':
        return _servicesElectricityRepairLoosePanels(answers);
      case 'activity_services_electricity_repair_electrical_hazard':
        return _servicesElectricityRepairElectricalHazard(answers);
      case 'activity_services_electricity_not_inspected':
        return _servicesElectricityNotInspected(answers);
      case 'activity_services_gas_oil_main_screen':
        return _servicesGasOilMain(answers);
      case 'activity_services_gas_oil':
        return _servicesGasOil(answers);
      case 'activity_services_main_gas':
        return _servicesMainsGas(answers);
      case 'activity_services_oil':
        return _servicesOil(answers);
      case 'activity_services_gas_oil_repair_gas_meter':
        return _servicesGasOilRepairGasMeter(answers);
      case 'activity_services_gas_oil_repair_storage_tank_pipework':
        return _servicesGasOilRepairStorage(answers);
      case 'activity_services_gas_oil_not_inspected':
        return _servicesGasOilNotInspected(answers);
      case 'activity_services_water_main_screen':
        return _servicesWaterMain(answers);
      case 'activity_services_water_main_water':
        return _servicesWaterMainWater(answers);
      case 'activity_services_water_not_inspected':
        return _servicesWaterNotInspected(answers);
      case 'activity_services_heating_main_screen':
        return _servicesHeatingMain(answers);
      case 'activity_services_heating_about_heating':
        return _servicesHeatingAbout(answers);
      case 'activity_services_heating_repair_main_screen':
        return _servicesHeatingRepair(answers);
      case 'activity_services_heating_not_inspected':
        return _servicesHeatingNotInspected(answers);
      case 'activity_services_drainage_main_screen':
        return _servicesDrainageMain(answers);
      case 'activity_services_drainage':
        return _servicesDrainage(answers);
      case 'activity_services_drainage_repair_chamber_cover':
        return _servicesDrainageRepairChamberCover(answers);
      case 'activity_services_drainage_repair_chamber_walls':
        return _servicesDrainageRepairChamberWalls(answers);
      case 'activity_services_drainage_repair_chamber_pipes':
        return _servicesDrainageRepairChamberPipes(answers);
      case 'activity_services_drainage_repair_soil_and_vent':
        return _servicesDrainageRepairSoilAndVent(answers);
      case 'activity_services_drainage_repair_roots_in_chamber':
        return _servicesDrainageRepairRoots(answers);
      case 'activity_services_drainage_repair_gullies':
        return _servicesDrainageRepairGullies(answers);
      case 'activity_services_drainage_repair_defect_dampness':
        return _servicesDrainageRepairDefectDampness(answers);
      case 'activity_services_drainage_not_inspected':
        return _servicesDrainageNotInspected(answers);
      case 'activity_services_common_services_main_screen':
        return _servicesCommonServicesMain(answers);
      case 'activity_services_shared_services':
        return _servicesCommonServices(answers);
      case 'activity_services_shared_services_not_inspected':
        return _servicesCommonServicesNotInspected(answers);
      case 'activity_services_water_heating_main_screen':
        return _servicesWaterHeatingMain(answers);
      case 'activity_water_heating_communal_hot_water':
        return _servicesWaterHeatingCommunalHotWater(answers);
      case 'activity_services_water_heating_gas_heating':
        return _servicesWaterHeatingGas(answers);
      case 'activity_services_water_heating_electric_heating':
        return _servicesWaterHeatingElectric(answers);
      case 'activity_services_water_heating_solar_power':
        return _servicesWaterHeatingSolar(answers);
      case 'activity_services_water_heating_repair_leaking_cylinder':
        return _servicesWaterHeatingRepairLeakingCylinder(answers);
      case 'activity_services_water_heating_repair_loose_panels':
        return _servicesWaterHeatingRepairLoosePanels(answers);
      case 'activity_services_water_heating_not_inspected':
        return _servicesWaterHeatingNotInspected(answers);
      case 'activity_inside_property_limitation':
        return _insidePropertyLimitations(answers);
      case 'activity_inside_property_roof_structure_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_inside_property_weather_condition':
        return _insideRoofWeatherCondition(answers);
      case 'activity_inside_property_loft_converted':
        return _insideRoofLoftConverted(answers);
      case 'activity_inside_property_about_roof_structure':
        return _insideRoofAbout(answers);
      case 'activity_inside_property_water_tank':
        return _insideRoofWaterTank(answers);
      case 'activity_inside_property_repair_tank':
        return _insideRoofRepairTank(answers);
      case 'activity_inside_property_repair_timber_structure':
        return _insideRoofRepairTimberStructure(answers);
      case 'activity_inside_property_repair_insect_infestation':
        return _insideRoofRepairInsectInfestation(answers);
      case 'activity_inside_property_repair_timber_rot':
        return _insideRoofRepairTimberRot(answers);
      case 'activity_inside_property_repair_under_size_timber':
        return _insideRoofRepairUnderSizeTimber(answers);
      case 'activity_inside_property_repair_roof_spreading':
        return _insideRoofRepairRoofSpreading(answers);
      case 'activity_inside_property_repair_heavy_roof':
        return _insideRoofRepairHeavyRoof(answers);
      case 'activity_inside_property_repair_removed_chimney_breast':
        return _insideRoofRepairRemovedChimneyBreast(answers);
      case 'activity_inside_property_repair_party_walls':
        return _insideRoofRepairPartyWalls(answers);
      case 'activity_inside_property_roof_structure_not_inspected':
        return _insideRoofNotInspected(answers);
      case 'activity_inside_property_ceilings_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'inside_property_ceilings_about_ceilings':
        return _ceilingsAbout(answers);
      case 'activity_inside_property_ceilings_cracks':
        return _ceilingsCracks(answers);
      case 'activity_inside_property_ceilings_contains_asbestos':
        return _ceilingsContainsAsbestos(answers);
      case 'activity_inside_property_ceilings_polystyrene':
        return _ceilingsPolystyrene(answers);
      case 'activity_inside_property_ceilings_heavy_paper_lining':
        return _ceilingsHeavyPaper(answers);
      case 'activity_inside_property_ceilings_repairs_ceilings':
        return _ceilingsRepairCeilings(answers);
      case 'activity_inside_property_ceilings_repairs_ornamental_plaster':
        return _ceilingsOrnamentalPlaster(answers);
      case 'activity_inside_property_ceilings_not_inspected':
        return _ceilingsNotInspected(answers);
      case 'activity_inside_property_floors_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_in_side_property_floors':
        return _floorsOlderProperties(answers);
      case 'activity_in_side_property_floors_about_floor':
        return _floorsAbout(answers);
      case 'activity_in_side_property_floors_creaking':
        return _floorsCreaking(answers);
      case 'activity_in_side_property_floors_tiles':
        return _floorsTiles(answers);
      case 'activity_in_side_property_floors_loose_floorboards':
        return _floorsLooseFloorboards(answers);
      case 'activity_in_side_property_floors_timber_decay':
        return _floorsTimberDecay(answers);
      case 'activity_in_side_property_floors_timber_infection':
        return _floorsTimberInfestation(answers);
      case 'activity_in_side_property_floors_dampness':
        return _floorsDampness(answers);
      case 'activity_in_side_property_floors_floor_ventilation':
        return _floorsVentilation(answers);
      case 'activity_in_side_property_floors_repair_floor_repair':
        return _floorsRepairFloorRepair(answers);
      case 'activity_in_side_property_floors_repair_floor_laminate_wood_floor':
        return _floorsRepairLaminate(answers);
      case 'activity_in_side_property_floors_repair_floor_vibration':
        return _floorsRepairVibration(answers);
      case 'activity_in_side_property_floors_repair_sloping_floor':
        return _floorsRepairSloping(answers);
      case 'activity_in_side_property_floors_repair_uneven_floor':
        return _floorsRepairUneven(answers);
      case 'activity_in_side_property_floors_repair_not_inspetcted':
        return _floorsNotInspected(answers);
      case 'activity_inside_property_fireplaces_main_screen':
        return _fireplacesMain(answers);
      case 'activity_in_side_property_fire_places_diffrent':
        return _fireplacesFluesNotInspected(answers);
      case 'activity_in_side_property_fire_places':
        return _fireplacesOpenFire(answers);
      case 'activity_in_side_property_fire_places__gas_fire':
        return _fireplacesGasFire(answers);
      case 'activity_in_side_property_fire_places__imitation_system':
        return _fireplacesImitationSystem(answers);
      case 'activity_in_side_property_fire_places__wood_burning_stove':
        return _fireplacesWoodBurningStove(answers);
      case 'activity_in_side_property_fire_places__electric_fire':
        return _fireplacesElectricFire(answers);
      case 'activity_in_side_property_fire_places__other':
        return _fireplacesOther(answers);
      case 'activity_in_side_property_fire_places_repair_fire_place':
        return _fireplacesRepairFireplaces(answers);
      case 'activity_in_side_property_fire_places_repair_damage_grate':
        return _fireplacesDamagedGrate(answers);
      case 'activity_in_side_property_fire_places_repair_damage_surround':
        return _fireplacesDamagedSurround(answers);
      case 'activity_in_side_property_fire_places_repair_blocked_fireplace':
        return _fireplacesBlockedFireplace(answers);
      case 'activity_in_side_property_fire_places_repair_removed_cb':
        return _fireplacesRemovedCb(answers);
      case 'activity_in_side_property_fire_places_repair_boiler_flue':
        return _fireplacesBoilerFlue(answers);
      case 'activity_in_side_property_fire_places_not_inspected':
        return _fireplacesNotInspected(answers);
      case 'activity_inside_property_built_in_fittings_main_screen':
        return _builtInFittingsMain(answers);
      case 'activity_in_side_property_built_in_fittings':
        return _builtInFittings(answers);
      case 'activity_in_side_property_built_in_fittings_repair_fittings':
        return _builtInRepairFittings(answers);
      case 'activity_in_side_property_built_in_fittings_repair_defective_sealants':
        return _builtInDefectiveSealants(answers);
      case 'activity_in_side_property_built_in_fittings_repair_moulding_noted':
        return _builtInMouldingNoted(answers);
      case 'activity_in_side_property_built_in_fittings_repair_water_seepage':
        return _builtInWaterSeepage(answers);
      case 'activity_in_side_property_built_in_fittings_not_inspected':
        return _builtInNotInspected(answers);
      case 'activity_inside_property_woodwork_main_screen':
        return _woodWorkMainScreen(answers);
      case 'activity_in_side_property_wood_work':
        return _woodWorkMain(answers);
      case 'activity_in_side_property_wood_work_second':
        return _woodWorkDetails(answers);
      case 'activity_in_side_property_cupboards':
        return _woodWorkCupboards(answers);
      case 'activity_in_side_property_wood_work_door_sampling':
        return _woodWorkDoorSampling(answers);
      case 'activity_in_side_property_ww_wood_work_repair':
        return _woodWorkRepair(answers);
      case 'activity_in_side_property_wood_work_repair_balusters':
        return _woodWorkRepairBalusters(answers);
      case 'activity_in_side_property_wood_work_repair_infestation':
        return _woodWorkRepairInfestation(answers);
      case 'activity_in_side_property_wood_work_repair_damp_timber':
        return _woodWorkRepairDampTimber(answers);
      case 'activity_in_side_property_wood_work_not_inspected':
        return _woodWorkNotInspected(answers);
      case 'activity_in_side_property_wood_work_damaged_lock':
      case 'activity_in_side_property_wood_work_damaged_lock__damaged_lock':
        return _woodWorkDamagedLock(answers);
      case 'activity_inside_property_bathroom_fittings_main_screen':
        return _bathroomFittingsMain(answers);
      case 'activity_in_side_property_bathroom_fittings_second':
        return _bathroomFittings(answers);
      case 'activity_in_side_property_bathroom_fittings_extractor_fan':
        return _bathroomExtractorFan(answers);
      case 'activity_in_side_property_bathroom_fittings_extractor_fan__no_extractor_fan_installed':
        return _bathroomExtractorFanNoInstalled(answers);
      case 'activity_in_side_property_bathroom_fittings_leaking':
        return _bathroomLeaking(answers);
      case 'activity_in_side_property_bathroom_fittings_sealant':
        return _bathroomSealant(answers);
      case 'activity_in_side_property_bathroom_fittings_mould':
        return _bathroomMoulding(answers);
      case 'activity_in_side_property_bathroom_fittings_wood_rot':
        return _bathroomWoodRot(answers);
      case 'activity_in_side_property_cubicle_safety_glass_rating':
        return _bathroomCubicleSafetyGlassRating(answers);
      case 'activity_in_side_property_bathroom_fittings_repair':
        return _bathroomFittingsRepair(answers);
      case 'activity_in_side_property_bathroom_fitting_not_inspected':
        return _bathroomFittingsNotInspected(answers);
      case 'activity_inside_property_other_main_screen':
        return _insideOtherMainScreen(answers);
      case 'activity_in_side_property_other_communal_area':
        return _insideOtherCommunalArea(answers);
      case 'activity_inside_property_other_celler_no_access':
        return _insideOtherNoAccess(answers, isBasement: false);
      case 'activity_inside_property_other_celler_no_access__no_access':
        return _insideOtherNoAccess(answers, isBasement: true);
      case 'activity_inside_property_other_celler_not_in_use':
        return _insideOtherNotInUse(answers, isBasement: false);
      case 'activity_inside_property_other_celler_not_in_use__not_in_use':
        return _insideOtherNotInUse(answers, isBasement: true);
      case 'activity_inside_property_other_celler_inspected':
        return _insideOtherUsedAs(answers, isBasement: false);
      case 'activity_inside_property_other_celler_inspected__used_as':
        return _insideOtherUsedAs(answers, isBasement: true);
      case 'activity_inside_property_other_celler_not_habitable':
        return _insideOtherNotHabitable(answers, isBasement: false);
      case 'activity_inside_property_other_celler_not_habitable__not_habitable':
        return _insideOtherNotHabitable(answers, isBasement: true);
      case 'activity_inside_property_other_celler_flooded':
        return _insideOtherFlooded(answers, isBasement: false);
      case 'activity_inside_property_other_celler_flooded__flooded':
        return _insideOtherFlooded(answers, isBasement: true);
      case 'activity_inside_property_other_celler_damp':
        return _insideOtherDamp(answers, isBasement: false);
      case 'activity_inside_property_other_celler_damp__serious_damp':
        return _insideOtherDamp(answers, isBasement: true);
      case 'activity_inside_property_other_celler_joists_decay':
        return _insideOtherJoistsDecay(answers, isBasement: false);
      case 'activity_inside_property_other_celler_joists_decay__joists_decay':
        return _insideOtherJoistsDecay(answers, isBasement: true);
      case 'activity_in_side_property_other_repair':
        return _insideOtherRepair(answers);
      case 'activity_inside_property_other_not_inspected':
        return _insideOtherNotInspected(answers);
      case 'activity_inside_property_walls_and_partitions_main_screen':
        return _conditionRatingNotes(answers, ratingKey: 'android_material_design_spinner4');
      case 'activity_inside_property_wap_walls':
        return _wallsAndPartitionsAbout(answers);
      case 'activity_in_side_property_wap_repair_condensation':
        return _wallsAndPartitionsCondensation(answers);
      case 'activity_in_side_property_wap_dampness':
        return _wallsAndPartitionsDampness(answers);
      case 'activity_in_side_property_wap_movement_cracks':
        return _wallsAndPartitionsMovementCracks(answers);
      case 'activity_in_side_property_wap_repair_wall_repair':
        return _wallsAndPartitionsWallRepair(answers);
      case 'activity_in_side_property_wap_repair_sealants':
        return _wallsAndPartitionsSealants(answers);
      case 'activity_in_side_property_wap_removed_wall':
      case 'activity_in_side_property_wap_repair_removed_wall':
        return _wallsAndPartitionsRemovedWall(answers);
      case 'activity_inside_property_wap_not_inspected':
        return _wallsAndPartitionsNotInspected(answers);
      case 'activity_outside_property_stacks':
        return _chimneyStacks(answers);
      case 'activity_outside_property_location':
        return _chimneyLocation(answers);
      case 'activity_outside_property_rendering':
        return _chimneyRendering(answers);
      case 'activity_outside_property_water_proofing':
        return _chimneyWaterProofing(answers);
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
        return _rwgRepairPipesGutters(answers);
      case 'activity_outside_property_rwg_about':
        return _rwgAbout(answers);
      case 'activity_rwg_weather_condition':
        return _rwgWeatherCondition(answers);
      case 'activity_outside_property_rwg_blocked_rwg':
        return _rwgBlocked(answers);
      case 'activity_outside_property_rwg_blocked_gullies':
        return _rwgBlockedGullies(answers);
      case 'activity_outside_property_rwg_open_runoffs':
        return _rwgOpenRunoffs(answers);
      case 'activity_outside_property_rain_water_goods_not_inspected':
        return _rwgNotInspected(answers);
      case 'outside_property_about_roof_layout':
      case 'outside_property_about_roof_layout__flat':
      case 'outside_property_about_roof_layout__mansard':
      case 'outside_property_about_roof_layout__other':
        return _roofAbout(screenId, answers);
      case 'outside_property_roof_covering_weather_layout':
        return _roofWeather(answers);
      case 'outside_property_roof_covering_flashing_layout':
        return _roofFlashing(answers);
      case 'outside_property_roof_covering_ridge_tiles_layout':
        return _roofRidgeTiles(answers);
      case 'outside_property_roof_covering_hip_tiles_layout':
        return _roofHipTiles(answers);
      case 'outside_property_roof_covering_parapet_wall_layout':
        return _roofParapetWall(answers);
      case 'outside_property_roof_covering_deflection_layout':
        return _roofDeflection(answers);
      case 'outside_property_roof_covering_asbestos_layout':
        return _roofAsbestos(answers);
      case 'outside_property_roof_covering_roof_structure_layout':
        return _roofStructure(answers);
      case 'outside_property_roof_covering_roof_spreading_layout':
        return _roofSpreading(answers);
      case 'activity_outside_property_roof_repair_tiles':
        return _roofRepairTiles(answers);
      case 'activity_outside_property_roof_repair_poor_roof':
        return _roofRepairPoorRoof(answers);
      case 'activity_outside_property_roof_spreading_repair':
        return _roofSpreadingRepair(answers);
      case 'activity_outside_property_roof_repair_flat_roof':
        return _roofRepairFlatRoof(answers);
      case 'activity_outside_property_roof_repair_parapet_wall':
        return _roofRepairParapetWall(answers);
      case 'activity_outside_property_roof_repair_verge':
        return _roofRepairVerge(answers);
      case 'activity_outside_property_roof_repair_valley_gutters':
        return _roofRepairValleyGutters(answers);
      case 'activity_outside_property_roof_not_inspected':
        return _roofNotInspected(answers);
      case 'activity_outside_property_main_walls_about_wall':
      case 'activity_outside_property_main_walls_about_wall__cavity_brick_wall':
      case 'activity_outside_property_main_walls_about_wall__cavity_block_wall':
      case 'activity_outside_property_main_walls_about_wall__cavity_stud_wall':
      case 'activity_outside_property_main_walls_about_wall__other':
        return _mainWallsAbout(screenId, answers);
      case 'activity_outside_property_main_walls_cladding':
        return _mainWallsCladding(answers);
      case 'activity_outside_property_main_walls_dpc':
        return _mainWallsDpc(answers);
      case 'activity_outside_property_main_walls_damp':
        return _mainWallsDamp(answers);
      case 'activity_outside_property_main_walls_removed_wall':
        return _mainWallsRemovedWall(answers);
      case 'activity_outside_property_main_walls_movements':
        return _mainWallsMovements(answers);
      case 'activity_outside_property_main_wall_repairs_thin_slim_wall':
        return _mainWallRepairThinSlim(answers);
      case 'activity_outside_property_main_wall_repairs_cavity_wall_insulation':
        return _mainWallRepairCavityInsulation(answers);
      case 'activity_outside_property_main_wall_repairs_near_by_tress':
        return _mainWallRepairNearbyTrees(answers);
      case 'activity_outside_property_main_wall_repairs_spalling':
      case 'activity_outside_property_main_wall_repairs_spalling__causing_damp':
        return _mainWallRepairSpalling(answers);
      case 'activity_outside_property_main_wall_repairs_render':
        return _mainWallRepairRender(answers);
      case 'activity_outside_property_main_wall_repairs_pointing':
        return _mainWallRepairPointing(answers);
      case 'activity_outside_property_main_wall_repairs_lintel':
      case 'activity_outside_property_main_wall_repairs_lintel__door':
        return _mainWallRepairLintel(answers);
      case 'activity_outside_property_main_wall_repairs_window_sills':
        return _mainWallRepairWindowSills(answers);
      case 'activity_outside_property_main_wall_repairs_wall_the_repair':
        return _mainWallRepairWallTie(answers);
      case 'outside_property_roof_covering_weathered_layout':
        return _roofCoveringWeathered(answers);
      case 'activity_outside_property_windows_aboutwindow':
        return _windowsAbout(answers);
      case 'activity_outside_property_windows_safety_glass_rating':
        return _windowsSafetyGlassRating(answers);
      case 'activity_outside_property_windows_wall_sealing':
        return _windowsWallSealing(answers);
      case 'activity_outside_property_windows_sill_projection':
        return _windowsSillProjection(answers);
      case 'activity_outside_property_windows_velux_window':
        return _windowsVelux(answers);
      case 'activity_outside_property_windows_not_inspected':
        return _windowsNotInspected(answers);
      case 'activity_outside_property_windows_repairs_repair_window':
        return _windowsRepair(answers);
      case 'activity_outside_property_windows_repairs_failed_glazing_location':
        return _windowsRepairFailedGlazing(answers);
      case 'activity_outside_property_windows_repairs_no_fire_escape_risk':
        return _windowsRepairNoFireEscapeRisk(answers);
      case 'activity_outside_property_out_side_doors_about_doors':
      case 'activity_outside_property_out_side_doors_about_doors__timber':
      case 'activity_outside_property_out_side_doors_about_doors__aluminium':
      case 'activity_outside_property_out_side_doors_about_doors__steel':
      case 'activity_outside_property_out_side_doors_about_doors__other':
        return _outsideDoorsAbout(answers);
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__rear_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__side_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__patio_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__garage_door':
      case 'activity_outside_property_out_side_doors_repairs_repair_out_side_doors__other_door':
        return _outsideDoorsRepair(screenId, answers);
      case 'activity_outside_property_conservatory_porch_location_construction':
      case 'activity_outside_property_conservatory_porch_location_construction__location_and_construction':
        return _cpLocationConstruction(answers);
      case 'activity_outside_property_conservatory_porch_roof':
      case 'activity_outside_property_conservatory_porch_roof__roof':
        return _cpRoof(answers);
      case 'activity_outside_property_conservatory_porch_windows':
      case 'activity_outside_property_conservatory_porch_windows__windows':
        return _cpWindows(answers);
      case 'activity_outside_property_conservatory_porch_doors':
      case 'activity_outside_property_conservatory_porch_doors__doors':
        return _cpDoors(answers);
      case 'activity_outside_property_conservatory_porch_floor':
      case 'activity_outside_property_conservatory_porch_floor__floor':
        return _cpFloor(answers);
      case 'activity_outside_property_conservatory_porch_safety_glass_rating':
      case 'activity_outside_property_conservatory_porch_safety_glass_rating__safety_glass_rating':
        return _cpSafetyGlassRating(answers);
      case 'outside_property_conservatory_porch_flashing_layout':
      case 'outside_property_conservatory_porch_flashing_layout__roof_flashing_with_wall':
        return _cpFlashing(answers);
      case 'activity_outside_property_porch_open_to_building':
      case 'activity_outside_property_porch_open_to_building__open_to_building':
        return _cpOpenToBuilding(answers);
      case 'activity_outside_property_porch_condition':
      case 'activity_outside_property_porch_condition__condition':
        return _cpPorchCondition(answers);
      case 'activity_outside_property_porch_poor_condition':
      case 'activity_outside_property_porch_poor_condition__poor_condition':
        return _cpPoorCondition(answers);
      case 'activity_outside_property_conservatory_porch_not_inspected':
        return _cpNotInspected(answers);
      case 'activity_outside_property_conservatory_porch_repairs':
      case 'activity_outside_property_conservatory_porch_repairs__walls':
      case 'activity_outside_property_conservatory_porch_repairs__windows':
      case 'activity_outside_property_conservatory_porch_repairs__door_glazing':
      case 'activity_outside_property_conservatory_porch_repairs__window_glazing':
      case 'activity_outside_property_conservatory_porch_repairs__roof_glazing':
      case 'activity_outside_property_conservatory_porch_repairs__floor':
      case 'activity_outside_property_conservatory_porch_repairs__rainwater_goods':
        return _cpRepairs(screenId, answers);
      case 'activity_outside_property_other_about_joinery_and_finishes':
        return _otherJoineryAbout(answers);
      case 'activity_outside_property_other_joinery_finishes_condition':
        return _otherJoineryCondition(answers);
      case 'activity_outside_property_other_joinery_finishes_asbestos':
        return _otherJoineryAsbestos(answers);
      case 'activity_outside_property_other_joinery_and_finishes_repairs':
        return _otherJoineryRepairs(answers);
      case 'activity_outside_property_other_joinery_finishes_not_inspected':
        return _otherJoineryNotInspected(answers);
      case 'activity_outside_property_other_communal_area':
        return _otherCommunalArea(answers);
      case 'activity_outside_property_other_not_inspected':
        return _otherNotInspected(answers);
      case 'activity_issues_regulation':
        return _issuesRegulation(answers);
      case 'activity_issues_glazed_sections':
        return _issuesGuarantees(answers);
      case 'activity_issues_other_matters':
        return _issuesOtherMatters(answers);
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
        return _groundsGarden(answers, gardenName: 'rear', isCommunal: false);
      case 'activity_grounds_other_side_garden':
        return _groundsGarden(answers, gardenName: 'side', isCommunal: false);
      case 'activity_grounds_other_other_garden':
        return _groundsGarden(answers, gardenName: 'other', isCommunal: false);
      case 'activity_grounds_other_communal_garden':
        return _groundsGarden(answers, gardenName: 'communal', isCommunal: true);

      // ── Section G: services detail screens ──
      case 'activity_services_water_disused_tank':
        return _servicesWaterDisusedTank(answers);
      case 'activity_services_water_water_tank':
        return _servicesWaterTank(answers);
      case 'activity_services_water_insulation':
      case 'services_water_insulation':
        return _servicesWaterInsulation(answers);
      case 'activity_services_heating_radiators':
        return _servicesHeatingRadiators(answers);
      case 'activity_services_heating_other_heating':
        return _servicesHeatingOtherHeating(answers);
      case 'activity_services_heating_old_boiler':
        return _servicesHeatingOldBoiler(answers);
      case 'activity_services_water_repair_main_screen':
        return _servicesWaterRepairMain(answers);
      case 'activity_services_water_repair_asbestos':
        return _servicesWaterRepairDefect(answers, 'Asbestos repair', 'cb_other_358', 'et_other_883');
      case 'activity_services_water_repair_cover_screen':
        return _servicesWaterRepairDefect(answers, 'Cover repair', 'cb_other_750', 'et_other_704');
      case 'activity_services_water_repair_water_tank_screen':
        return _servicesWaterRepairDefect(answers, 'Water tank repair', 'cb_other_635', 'et_other_615');
      case 'activity_services_drainage_chamber_lids':
        return _servicesDrainageChamberLids(answers);
      case 'activity_services_drainage_public_system':
        return _servicesDrainagePublicSystem(answers);
      case 'activity_services_water_heating_cylinder':
        return _servicesWaterHeatingCylinder(answers);

      // ── Section F: woodwork sub-screens ──
      case 'activity_in_side_property_wood_work_creaking_stairs':
        return _woodWorkSimpleCheckbox(answers, 'cb_is_creaking_stairs', 'Creaking stairs noted.');
      case 'activity_in_side_property_wood_work_glazed_internal_doors':
        return _woodWorkSimpleCheckbox(answers, 'cb_no_safety_glass_rating', 'Glazed internal doors: no safety glass rating observed.');
      case 'activity_in_side_property_wood_work_open_threads':
        return _woodWorkSimpleCheckbox(answers, 'cb_open_threads', 'Open stair threads noted.');
      case 'activity_in_side_property_wood_work_out_of_square_doors':
        return _woodWorkSimpleCheckbox(answers, 'cb_out_of_square_doors', 'Out of square doors noted.');
      case 'activity_in_side_property_wood_work_rocking_handrails':
        return _woodWorkRockingHandrails(answers);

      // ── Section F: joinery variant screens ──
      case 'activity_outside_property_other_about_joinery_and_finishes__other_joinery_and_finishes':
        return _otherJoineryAbout(answers);
      case 'activity_outside_property_other_joinery_and_finishes_repairs__repairs':
        return _otherJoineryRepairs(answers);
      case 'activity_outside_property_other_joinery_finishes_not_inspected__not_inspected':
        return _otherJoineryNotInspected(answers);

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
        return _outsideDoorsRepairLocation(answers, 'Failed glazing');
      case 'activity_outside_property_out_side_doors_repairs_inadequate_lock_location':
        return _outsideDoorsRepairLocation(answers, 'Inadequate lock');

      // ── Section A: overall opinion ──
      case 'activity_over_all_openion':
        return _overallOpinion(answers);

      // ── Section K: floor/site plan sketches ──
      case 'activity_capture_floor_site_plan_sketches':
        return const ['Floor/site plan sketches captured during the inspection.'];
      default:
        return const [];
    }
  }

  List<String> _conditionRatingNotes(
    Map<String, String> answers, {
    required String ratingKey,
    String notesKey = 'ar_etNote',
  }) {
    final rating = (answers[ratingKey] ?? '').trim();
    final notes = (answers[notesKey] ?? '').trim();
    final phrases = <String>[];
    if (rating.isNotEmpty) {
      phrases.add('Condition rating: $rating.');
    }
    if (notes.isNotEmpty) {
      phrases.add('Notes: $notes');
    }
    return phrases;
  }

  List<String> _partyDisclosure(Map<String, String> answers) {
    final value = (answers['android_material_design_spinner'] ?? '').toLowerCase().trim();
    if (value == 'none') {
      return _resolve('{PARTY_DISCLOSURES_NONE}');
    }
    if (value == 'conflict') {
      return _resolve('{PARTY_DISCLOSURES_CONFLICT}');
    }
    return const [];
  }

  List<String> _propertyWeather(Map<String, String> answers) {
    final now = (answers['android_material_design_spinner'] ?? '').trim();
    final before = (answers['android_material_design_spinner2'] ?? '').trim();
    if (now.isEmpty && before.isEmpty) {
      return const ['Not inspected'];
    }
    final template = _phraseTexts['{D_WEATHER}'] ?? '';
    if (template.isEmpty) return const [];
    final resolved = _normalize(template)
        .replaceAll('{WEATHER_NOW}', now.toLowerCase())
        .replaceAll('{WEATHER_BEFORE}', before.toLowerCase());
    return _split(resolved);
  }

  List<String> _propertyStatus(Map<String, String> answers) {
    final occupancy = (answers['android_material_design_spinner'] ?? '').trim();
    final furnishing = (answers['android_material_design_spinner2'] ?? '').trim();
    final flooring = (answers['android_material_design_spinner3'] ?? '').trim();
    if (occupancy.isEmpty && furnishing.isEmpty && flooring.isEmpty) {
      return const ['Not inspected'];
    }
    final template = _phraseTexts['{D_PROPERTY_STATUS}'] ?? '';
    if (template.isEmpty) return const [];
    final resolved = _normalize(template)
        .replaceAll('{PROPERTY_STATUS_OCCUPANCY}', occupancy.toLowerCase())
        .replaceAll('{PROPERTY_STATUS_FURNISHING}', furnishing.toLowerCase())
        .replaceAll('{PROPERTY_STATUS_FLOOR_COVERING}', flooring.toLowerCase());
    return _split(resolved);
  }

  List<String> _propertyFacing(Map<String, String> answers) {
    final orientation = (answers['android_material_design_spinner'] ?? '').trim();
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

  List<String> _outsidePropertyLimitations(Map<String, String> answers) {
    final selections = <String>[];
    if (_isChecked(answers['ch1'])) selections.add('Height/Configuration');
    if (_isChecked(answers['ch2'])) selections.add('Nearby Buildings');
    if (_isChecked(answers['ch3'])) selections.add('No rear access');
    if (selections.isEmpty) return const [];

    final template = _phraseTexts['{E_OUTSIDE_PROPERTY_LIMITATIONS}'] ?? '';
    if (template.isEmpty) return const [];

    var result = template;
    final standard = _sub('{E_OUTSIDE_PROPERTY_LIMITATIONS}', '{STANDARD_TEXT}');
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
    final stackType = _cleanLower(answers['android_material_design_spinner3']);
    if (stackType.isEmpty) return const [];
    final isMulti = stackType.contains('multiple');
    final phraseCode = _chimneyPhraseCode(isMulti);
    final phrases = <String>[];

    var stackTemplate = _sub(phraseCode, '{STACK}');
    if (stackTemplate.isNotEmpty) {
      if (isMulti) {
        final count = _cleanLower(answers['EtMultipleNumber']);
        stackTemplate = stackTemplate.replaceAll('{CS_STACK_MULTIPLE_NUMBER}', count);
      }
      phrases.addAll(_split(_normalize(stackTemplate)));
    }

    final pots = _cleanLower(answers['android_material_design_spinner2']);
    var potsTemplate = _sub(phraseCode, '{STACK_POTS}');
    if (potsTemplate.isNotEmpty && pots.isNotEmpty) {
      if (!isMulti) {
        potsTemplate = potsTemplate.replaceAll('{CS_POTS}', pots);
      }
      phrases.addAll(_split(_normalize(potsTemplate)));
    }

    final rendering = _cleanLower(answers['android_material_design_spinner4']);
    if (rendering.isNotEmpty) {
      var renderingTemplate = _sub(phraseCode, '{STACK_RENDERING}');
      if (renderingTemplate.isNotEmpty) {
        renderingTemplate = renderingTemplate.replaceAll('{CS_RENDERING}', rendering);
        final faces = _cleanLower(answers['android_material_design_spinner5']);
        if (faces.isNotEmpty) {
          renderingTemplate = renderingTemplate.replaceAll('{CS_RENDERING_OUTER_FACE}', faces);
        } else {
          renderingTemplate = renderingTemplate.replaceAll('{CS_RENDERING_OUTER_FACE}', '');
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

    final phraseCode = _chimneyPhraseCode(locations.length > 1);
    var template = _sub(phraseCode, '{STACK_LOCATION}');
    if (template.isEmpty) return const [];
    final locationText = _toWords(locations).toLowerCase();
    template = template.replaceAll('{CS_LOCATION}', locationText);
    return _split(_normalize(template));
  }

  List<String> _chimneyRendering(Map<String, String> answers) {
    final rendering = _cleanLower(answers['android_material_design_spinner3']);
    if (rendering.isEmpty) return const [];
    var template = _sub('{E_CHIMNEY_SINGLE_STACK}', '{STACK_RENDERING}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_RENDERING}', rendering)
        .replaceAll('{CS_RENDERING_OUTER_FACE}', '');
    return _split(_normalize(template));
  }

  List<String> _chimneyWaterProofing(Map<String, String> answers) {
    final flashing = _labelsFor(
      ['ch1', 'ch2', 'ch3', 'ch4', 'ch5'],
      answers,
      {
        'ch1': 'Lead',
        'ch2': 'Mortar',
        'ch3': 'Lead and mortar',
        'ch4': 'Tiles',
        'ch5': 'Other',
      },
    );
    _addOther(answers, 'ch5', 'etGroundTypeOther', flashing);

    final flaunching = _labelsFor(
      ['ch6', 'ch7', 'ch8', 'ch9', 'ch10'],
      answers,
      {
        'ch6': 'Lead',
        'ch7': 'Mortar',
        'ch8': 'Lead and mortar',
        'ch9': 'Tiles',
        'ch10': 'Other',
      },
    );
    _addOther(answers, 'ch10', 'etFlaunchingOther', flaunching);

    if (flashing.isEmpty || flaunching.isEmpty) return const [];

    var template = _sub('{E_CHIMNEY_SINGLE_STACK}', '{WATERPROOFING}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_WATERPROOFING_FLASHING_FORMED_IN}', _toWords(flashing).toLowerCase())
        .replaceAll('{CS_WATERPROOFING_FLAUNCHING_FORMED_IN}', _toWords(flaunching).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _chimneyCondition(Map<String, String> answers) {
    final condition = _cleanLower(answers['android_material_design_spinner3']);
    if (condition.isEmpty) return const [];
    var template = _sub('{E_CHIMNEY_SINGLE_STACK}', '{CONDITION}');
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

    final phraseCode = _chimneyPhraseCode(locations.length > 1);
    var template = _sub(phraseCode, '{SHARED_CHIMNEY}');
    if (template.isEmpty) return const [];
    final locationText = _toWords(locations).toLowerCase();
    template = template
        .replaceAll('{CS_SHARED_CHIMNEY}', locationText)
        .replaceAll('{IS_ARE}', _isAre(locations));
    return _split(_normalize(template));
  }

  List<String> _chimneyLeaning(Map<String, String> answers) {
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

    final phraseCode = _chimneyPhraseCode(locations.length > 1);
    final phrases = <String>[];
    var leaningTemplate = _sub(phraseCode, '{LEANING_CHIMNEY}');
    if (leaningTemplate.isNotEmpty) {
      leaningTemplate = leaningTemplate.replaceAll('{CS_LEANING_CHIMNEY}', _toWords(locations).toLowerCase());
      leaningTemplate = leaningTemplate.replaceAll('{IS_ARE}', _isAre(locations));
      phrases.addAll(_split(_normalize(leaningTemplate)));
    }

    final condition = _cleanLower(answers['android_material_design_spinner4']);
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

    if (_isChecked(answers['cb_Partial_view']) || _isChecked(answers['cbPartial_view'])) {
      final template = _sub(phraseCode, '{PARTIAL_VIEW}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_Removed_chimney_stack'])) {
      final locations = _labelsFor(
        ['cb_main_building_83', 'cb_front_74', 'cb_rear_97', 'cb_side_72', 'cb_other_326'],
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
      if (locationText.isEmpty) {
        locationText = 'property';
      }
      var template = _sub(phraseCode, '{REMOVED_CHIMNEY_STACK}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{CS_INSPECTION_STATUS_REMOVED_CS}', locationText);
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
      if (locationText.isEmpty) {
        locationText = 'property';
      }
      var template = _sub(phraseCode, '{REMOVED_POTS}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{CS_INSPECTION_STATUS_REMOVED_CHIMNEY_POTS}', locationText);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _chimneyRepairFlashing(Map<String, String> answers) {
    final condition = _cleanLower(answers['android_material_design_spinner4']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon ? ['chs1', 'chs2', 'chs3', 'chs4', 'chs5'] : ['ch1', 'ch2', 'ch3', 'ch4', 'ch5'],
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
    _addOther(answers, isSoon ? 'chs5' : 'ch5', isSoon ? 'etChimneySoonOther' : 'etChimneyCommonOther', stacks);

    final issues = _labelsFor(
      isSoon ? ['ch10', 'ch11', 'ch12', 'ch13', 'ch14'] : ['ch6', 'ch7', 'ch8', 'ch9'],
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
    _addOther(answers, isSoon ? 'ch14' : 'ch9', isSoon ? 'etRepairSoonProblemOther' : 'etRepairNowProblemOther', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_FLASHING_REPAIR}';
    final subCode = isSoon ? '{FLASHING_REPAIR_SOON}' : '{FLASHING_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_FLASHING_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll('{CS_FLASHING_REPAIR_ISSUE}', _toWords(issues).toLowerCase())
        .replaceAll('{IS_ARE}', _isAre(stacks));
    return _split(_normalize(template));
  }

  List<String> _chimneyRepairFlaunching(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon ? ['cb_main_building_56', 'cb_front_62', 'cb_side_28', 'cb_rear_56'] : ['cb_main_building_28', 'cb_front_48', 'cb_side_50', 'cb_rear_32'],
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
      isSoon ? ['cb_cracked', 'cb_loose', 'cb_partly_missing', 'cb_other_952'] : ['cb_badly_cracked', 'cb_very_loose', 'cb_largely_missing', 'cb_other_969'],
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
    _addOther(answers, isSoon ? 'cb_other_952' : 'cb_other_969', isSoon ? 'et_other_347' : 'et_other_176', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_FLAUNCHING_REPAIR}';
    final subCode = isSoon ? '{FLAUNCHING_REPAIR_SOON}' : '{FLAUNCHING_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_FLAUNCHING_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll('{CS_FLAUNCHING_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
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
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon ? ['cb_main_building_71', 'cb_front_59', 'cb_side_79', 'cb_rear_35'] : ['cb_main_building_91', 'cb_front_97', 'cb_side_49', 'cb_rear_79'],
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
      isSoon ? ['cb_cracked', 'cb_broken', 'cb_partly_missing', 'cb_other_435'] : ['cb_badly_cracked', 'cb_badly_broken', 'cb_largely_missing', 'cb_other_467'],
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
    _addOther(answers, isSoon ? 'cb_other_435' : 'cb_other_467', isSoon ? 'et_other_634' : 'et_other_494', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_POTS_REPAIR}';
    final subCode = isSoon ? '{CHIMNEY_POTS_REPAIR_SOON}' : '{CHIMNEY_POTS_REPAIR_NOW}';
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
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final stacks = _labelsFor(
      isSoon ? ['cb_main_building_25', 'cb_front_96', 'cb_side_40', 'cb_rear_32'] : ['cb_main_building_79', 'cb_front_55', 'cb_side_79', 'cb_rear_99'],
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
      isSoon ? ['cb_has_eroded', 'cb_is_partly_missing', 'cb_is_loose', 'cb_other_669'] : ['cb_badly_eroded', 'cb_largely_missing', 'cb_other_862'],
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
    _addOther(answers, isSoon ? 'cb_other_669' : 'cb_other_862', isSoon ? 'et_other_201' : 'et_other_169', issues);

    if (stacks.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_REPOINTING_REPAIR}';
    final subCode = isSoon ? '{CHIMNEY_REPOINTING_REPAIR_SOON}' : '{CHIMNEY_REPOINTING_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{CS_REPOINTING_REPAIR_STACKS}', _toWords(stacks).toLowerCase())
        .replaceAll('{CS_REPOINTING_REPAIR_ISSUES}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_causing_dump'])) {
      final extra = _sub(phraseCode, '{CHIMNEY_REPOINTING_REPAIR_NOW_CAUSING_DUMP}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _chimneyRepairDisrepair(Map<String, String> answers) {
    if (!_isChecked(answers['cb_repair_soon_70'])) return const [];
    final stacks = _labelsFor(
      ['cb_main_building_21', 'cb_front_101', 'cb_side_71', 'cb_rear_16', 'cb_other_608'],
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

    var template = _sub('{E_CHIMNEY_DISREPAIR_REPAIR}', '{CHIMNEY_DISREPAIR_REPAIR_SOON}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CS_CHIMNEY_DISREPAIR_REPAIR_STACKS}', _toWords(stacks).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _chimneyRepairDishAerial(Map<String, String> answers, {String? screenId}) {
    final condition = _cleanLower(answers['actv_condition']);
    var type = _cleanLower(answers['actv_type']);
    if (type.isEmpty && screenId != null) {
      if (screenId.contains('satellite')) {
        type = 'satellite';
      } else if (screenId.contains('aerial')) {
        type = 'aerial';
      }
    }
    if (condition.isEmpty || type.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final issues = _labelsFor(
      isSoon ? ['cb_loose', 'cb_rusted', 'cb_other_920'] : ['cb_very_loose', 'cb_badly_rusted', 'cb_other_698'],
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
    _addOther(answers, isSoon ? 'cb_other_920' : 'cb_other_698', isSoon ? 'et_other_193' : 'et_other_633', issues);
    if (issues.isEmpty) return const [];

    final phraseCode = '{E_CHIMNEY_AERIAL_DISH_REPAIR}';
    final subCode = isSoon ? '{AERIAL_DISH_REPAIR_SOON}' : '{AERIAL_DISH_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];

    final isAerial = type.contains('aerial');
    final aerialOrDish = isAerial ? 'aerial' : 'satellite dish';
    final aAn = isAerial ? 'an' : 'a';

    template = template
        .replaceAll('{AERIAL_OR_DISH}', aerialOrDish)
        .replaceAll('{A_AN}', aAn)
        .replaceAll('{DISH_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_is_safety_hazard'])) {
      final extra = _sub(phraseCode, '{AERIAL_DISH_REPAIR_NOW_SAFETY_HAZARD}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra.replaceAll('{AERIAL_OR_DISH}', aerialOrDish))));
      }
    }
    return phrases;
  }

  List<String> _rwgRepairPipesGutters(Map<String, String> answers) {
    final condition = (answers['actv_condition'] ?? '').toLowerCase();
    if (condition.isEmpty) return const [];

    final isSoon = condition.contains('soon');
    final itemIds = isSoon ? ['cb_pipes_101', 'cb_gutters_28'] : ['cb_pipes_96', 'cb_gutters_59'];
    final defectIds = isSoon
        ? [
            'cb_are_leaking_78',
            'cb_are_loose_39',
            'cb_are_incomplete_52',
            'cb_are_blocked_101',
            'cb_are_rusted_26',
            'cb_do_not_have_sufficient_slope_53',
            'cb_other_458',
          ]
        : [
            'cb_are_leaking_89',
            'cb_are_loose_91',
            'cb_are_incomplete_94',
            'cb_are_blocked_52',
            'cb_are_rusted_18',
            'cb_do_not_have_sufficient_slope_65',
            'cb_other_4581',
          ];

    final items = _labelsFor(itemIds, answers, {
      'cb_pipes_101': 'Pipes',
      'cb_gutters_28': 'Gutters',
      'cb_pipes_96': 'Pipes',
      'cb_gutters_59': 'Gutters',
    });

    final defects = _labelsFor(defectIds, answers, {
      'cb_are_leaking_78': 'Leaking',
      'cb_are_loose_39': 'Loose',
      'cb_are_incomplete_52': 'Incomplete',
      'cb_are_blocked_101': 'Blocked',
      'cb_are_rusted_26': 'Rusted',
      'cb_do_not_have_sufficient_slope_53': 'Do not have sufficient slope',
      'cb_other_458': 'Other',
      'cb_are_leaking_89': 'Leaking',
      'cb_are_loose_91': 'Loose',
      'cb_are_incomplete_94': 'Incomplete',
      'cb_are_blocked_52': 'Blocked',
      'cb_are_rusted_18': 'Rusted',
      'cb_do_not_have_sufficient_slope_65': 'Do not have sufficient slope',
      'cb_other_4581': 'Other',
    });

    if (items.isEmpty || defects.isEmpty) return const [];

    final phraseCode = '{E_RAINWATER_GOODS_ABOUT}';
    final subCode = isSoon ? '{RWG_REPAIR_SOON}' : '{RWG_REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];

    final itemsText = _toWords(items);
    final defectsText = _toWords(defects);
    final isAre = _isAre(defects);

    if (isSoon) {
      template = template
          .replaceAll('{RWG_REPAIR_ITEM_SOON}', itemsText)
          .replaceAll('{RWG_REPAIR_DEFECT_SOON}', defectsText)
          .replaceAll('{IS_ARE}', isAre);
    } else {
      template = template
          .replaceAll('{RWG_REPAIR_ITEM_NOW}', itemsText)
          .replaceAll('{RWG_REPAIR_DEFECT_NOW}', defectsText)
          .replaceAll('{IS_ARE}', isAre);
    }

    final phrases = _split(_normalize(template)).toList();
    if (defects.any((d) => d.toLowerCase().contains('slope'))) {
      final extra = _sub(phraseCode, '{RWG_IF_TYPE_IF_INSUFFICIENT_SLOPE}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _rwgAbout(Map<String, String> answers) {
    final phrases = <String>[];
    final phraseCode = '{E_RAINWATER_GOODS_ABOUT}';

    final madeUp = _cleanLower(answers['actv_rainwater_goods_are_made_up']);
    final types = _labelsFor(
      ['cb_plastic', 'cb_cast_iron', 'cb_asbestos_cement', 'cb_concrete', 'cb_metal', 'cb_other_697'],
      answers,
      {
        'cb_plastic': 'Plastic',
        'cb_cast_iron': 'Cast iron',
        'cb_asbestos_cement': 'Asbestos cement',
        'cb_concrete': 'Concrete',
        'cb_metal': 'Metal',
        'cb_other_697': 'Other',
      },
    );
    _addOther(answers, 'cb_other_697', 'et_other_427', types);

    if (madeUp.isNotEmpty && types.isNotEmpty) {
      var template = _sub(phraseCode, '{RWG_ABOUT_TYPE}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{RWG_MADE_UP}', madeUp)
            .replaceAll('{RWG_TYPE}', _toWords(types).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub(phraseCode, '{RWG_ABOUT_CONDITION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{RWG_CONDITION}', condition);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_Shared'])) {
      phrases.addAll(_split(_normalize(_sub(phraseCode, '{RAINWATER_GOODS_SHARED}'))));
    }

    if (_isChecked(answers['cb_asbestos_cement'])) {
      final asbestos = _sub(phraseCode, '{RWG_IF_TYPE_ASBESTOS_CEMENT}');
      if (asbestos.isNotEmpty) {
        phrases.addAll(_split(_normalize(asbestos)));
      }
    }

    if (phrases.isNotEmpty) {
      final standard = _sub(phraseCode, '{RWG_STANDARD_TEXT}');
      if (standard.isNotEmpty) {
        phrases.addAll(_split(_normalize(standard)));
      }
    }

    return phrases;
  }

  List<String> _rwgWeatherCondition(Map<String, String> answers) {
    final weather = _cleanLower(answers['actv_weather_condition']);
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
    return _split(_normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_BLOCKED}')));
  }

  List<String> _rwgBlockedGullies(Map<String, String> answers) {
    if (!_isChecked(answers['cb_blocked_gullies'])) return const [];
    return _split(_normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_BLOCKED_GULLIES}')));
  }

  List<String> _rwgOpenRunoffs(Map<String, String> answers) {
    if (!_isChecked(answers['cb_open_runoffs'])) return const [];
    return _split(_normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_OPEN_RUNOFFS}')));
  }

  List<String> _rwgNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{E_RAINWATER_GOODS_ABOUT}', '{RWG_NOT_INSPECTED}')));
  }

  List<String> _roofAbout(String screenId, Map<String, String> answers) {
    final phrases = <String>[];
    final phraseCode = '{E_ROOF_COVERING}';

    var roofType = _cleanLower(answers['actv_roof_type']);
    if (roofType.isEmpty) {
      if (screenId.contains('__flat')) {
        roofType = 'flat';
      } else if (screenId.contains('__mansard')) {
        roofType = 'mansard';
      } else if (screenId.contains('__other')) {
        roofType = 'other';
      } else {
        roofType = 'pitched';
      }
    }
    final otherType = (answers['other'] ?? '').trim();
    if (roofType == 'other' && otherType.isNotEmpty) {
      roofType = otherType.toLowerCase();
    }

    final locations = _labelsFor(
      ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_dormer_window', 'cb_other_22'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_dormer_window': 'Dormer window',
        'cb_other_22': 'Other',
      },
    );
    _addOther(answers, 'cb_other_22', 'etRoofLocationOther', locations);

    final materials = _labelsFor(
      [
        'cb_original',
        'cb_replacement',
        'cb_interlocking',
        'cb_concrete',
        'cb_clay',
        'cb_natural',
        'cb_composite',
        'cb_mineral_felt',
        'cb_rubber',
        'cb_fiberglass',
        'cb_single_ply_membrane',
        'cb_other_78',
      ],
      answers,
      {
        'cb_original': 'Original',
        'cb_replacement': 'Replacement',
        'cb_interlocking': 'Interlocking',
        'cb_concrete': 'Concrete',
        'cb_clay': 'Clay',
        'cb_natural': 'Natural',
        'cb_composite': 'Composite',
        'cb_mineral_felt': 'Mineral felt',
        'cb_rubber': 'Rubber material',
        'cb_fiberglass': 'Fiberglass',
        'cb_single_ply_membrane': 'Single ply membrane',
        'cb_other_78': 'Other',
      },
    );
    _addOther(answers, 'cb_other_78', 'etRoofMaterialOther', materials);

    final shapes = _labelsFor(
      ['cb_tiles', 'cb_sheets'],
      answers,
      {
        'cb_tiles': 'Tiles',
        'cb_sheets': 'Sheets',
      },
    );

    if (roofType.isNotEmpty && locations.isNotEmpty && materials.isNotEmpty && shapes.isNotEmpty) {
      var template = _sub(phraseCode, '{RC_ABOUT_TYPE}');
      if (template.isNotEmpty) {
        final oldRoof = _isChecked(answers['cb_old_roof_covering'])
            ? _sub(phraseCode, '{OLD_ROOF_COVERING}')
            : '';
        template = template
            .replaceAll('{RC_TYPE}', roofType)
            .replaceAll('{RC_LOCATION}', _toWords(locations).toLowerCase())
            .replaceAll('{IS_ARE}', _isAre(locations))
            .replaceAll('{RC_MATERIAL}', _toWords(materials).toLowerCase())
            .replaceAll('{RC_COV_MATERIAL_SHAPE}', _toWords(shapes).toLowerCase())
            .replaceAll('{OLD_ROOF_COVERING}', oldRoof);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub(phraseCode, '{RC_ABOUT_TYPE_CONDITION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{RC_TYPE_CONDITION}', condition);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_replacement'])) {
      final replacement = _sub('{E_ROOF_COVERING_MATERIAL}', '{MATERIAL_REPLACEMENT}');
      if (replacement.isNotEmpty) {
        phrases.addAll(_split(_normalize(replacement)));
      }
    }
    if (_isChecked(answers['cb_composite'])) {
      final composite = _sub('{E_ROOF_COVERING_MATERIAL}', '{MATERIAL_COMPOSITE}');
      if (composite.isNotEmpty) {
        phrases.addAll(_split(_normalize(composite)));
      }
    }
    if (_isChecked(answers['cb_mineral_felt'])) {
      final felt = _sub('{E_ROOF_COVERING_MATERIAL}', '{FLAT_MATERIAL_MINERAL_FELT}');
      if (felt.isNotEmpty) {
        phrases.addAll(_split(_normalize(felt)));
      }
    }

    return phrases;
  }

  List<String> _roofWeather(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_status']);
    if (condition.isEmpty) return const [];
    final phraseCode = '{E_RC_WEATHER_CONDITION}';
    final subCode = condition.contains('wet') ? '{CONDITION_WET}' : '{CONDITION_DRY}';
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

  List<String> _roofFlashing(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_lead', 'cb_mortar', 'cb_tiles', 'cb_other_33'],
      answers,
      {
        'cb_lead': 'Lead',
        'cb_mortar': 'Mortar',
        'cb_tiles': 'Tiles',
        'cb_other_33': 'Other',
      },
    );
    _addOther(answers, 'cb_other_33', 'et_other_87', items);
    if (items.isEmpty) return const [];

    final phrases = <String>[];
    var template = _sub('{E_ROOF_COVERING}', '{E_RC_FLASHING}');
    if (template.isNotEmpty) {
      template = template.replaceAll('{RC_FLASHING}', _toWords(items).toLowerCase());
      phrases.addAll(_split(_normalize(template)));
    }

    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var conditionTemplate = _sub('{E_ROOF_COVERING}', '{E_RC_FLASHING_CONDITION}');
      if (conditionTemplate.isNotEmpty) {
        conditionTemplate = conditionTemplate.replaceAll('{RC_FLASHING_CONDITION}', condition);
        phrases.addAll(_split(_normalize(conditionTemplate)));
      }
    }
    return phrases;
  }

  List<String> _roofRidgeTiles(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_tiles', 'cb_lead', 'cb_concrete', 'cb_other_62'],
      answers,
      {
        'cb_tiles': 'Tiles',
        'cb_lead': 'Lead',
        'cb_concrete': 'Concrete',
        'cb_other_62': 'Other',
      },
    );
    _addOther(answers, 'cb_other_62', 'et_other_101', items);
    if (items.isEmpty) return const [];
    final phrases = <String>[];
    var template = _sub('{E_ROOF_COVERING}', '{E_RC_RIDGE_TILES}');
    if (template.isNotEmpty) {
      template = template.replaceAll('{RC_RIDGE_TILES}', _toWords(items).toLowerCase());
      phrases.addAll(_split(_normalize(template)));
    }
    final condition = _cleanLower(answers['actv_formed_in']);
    if (condition.isNotEmpty) {
      var conditionTemplate = _sub('{E_ROOF_COVERING}', '{E_RC_RIDGE_TILES_CONDITION}');
      if (conditionTemplate.isNotEmpty) {
        conditionTemplate = conditionTemplate.replaceAll('{RC_RIDGE_TILES_CONDITION}', condition);
        phrases.addAll(_split(_normalize(conditionTemplate)));
      }
    }
    return phrases;
  }

  List<String> _roofHipTiles(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_tiles', 'cb_lead', 'cb_concrete', 'cb_other_62'],
      answers,
      {
        'cb_tiles': 'Tiles',
        'cb_lead': 'Lead',
        'cb_concrete': 'Concrete',
        'cb_other_62': 'Other',
      },
    );
    _addOther(answers, 'cb_other_62', 'et_other_101', items);
    if (items.isEmpty) return const [];
    final phrases = <String>[];
    var template = _sub('{E_ROOF_COVERING}', '{E_RC_HIP_TILES}');
    if (template.isNotEmpty) {
      template = template.replaceAll('{RC_HIP_TILES}', _toWords(items).toLowerCase());
      phrases.addAll(_split(_normalize(template)));
    }
    final condition = _cleanLower(answers['actv_formed_in']);
    if (condition.isNotEmpty) {
      var conditionTemplate = _sub('{E_ROOF_COVERING}', '{E_RC_HIP_TILES_CONDITION}');
      if (conditionTemplate.isNotEmpty) {
        conditionTemplate = conditionTemplate.replaceAll('{RC_HIP_TILES_CONDITION}', condition);
        phrases.addAll(_split(_normalize(conditionTemplate)));
      }
    }
    return phrases;
  }

  List<String> _roofParapetWall(Map<String, String> answers) {
    final builtWith = _labelsFor(
      ['cb_bricks', 'cb_concrete', 'cb_block', 'cb_other_44'],
      answers,
      {
        'cb_bricks': 'Bricks',
        'cb_concrete': 'Concrete',
        'cb_block': 'Block',
        'cb_other_44': 'Other',
      },
    );
    _addOther(answers, 'cb_other_44', 'et_other_101', builtWith);
    if (builtWith.isEmpty) return const [];

    final phrases = <String>[];
    var template = _sub('{E_ROOF_COVERING}', '{E_RC_PARAPET_WALL}');
    if (template.isNotEmpty) {
      template = template
          .replaceAll('{RC_PARAPET_WALL_BUILT_WITH}', _toWords(builtWith).toLowerCase())
          .replaceAll('{RC_PARAPET_WALL_RENDERED}', _cleanLower(answers['actv_rendered']))
          .replaceAll('{IS_ARE}', _isAre(builtWith));
      phrases.addAll(_split(_normalize(template)));
    }

    final condition = _cleanLower(answers['android_material_design_spinner3']);
    if (condition.isNotEmpty) {
      var conditionTemplate = _sub('{E_ROOF_COVERING}', '{E_RC_PARAPET_WALL_CONDITION}');
      if (conditionTemplate.isNotEmpty) {
        conditionTemplate = conditionTemplate.replaceAll('{RC_PARAPET_WALL_CONDITION}', condition);
        phrases.addAll(_split(_normalize(conditionTemplate)));
      }
    }

    return phrases;
  }

  List<String> _roofDeflection(Map<String, String> answers) {
    final phrases = <String>[];
    final status = _cleanLower(answers['actv_status']);
    if (status.isNotEmpty) {
      final statusLocations = _labelsFor(
        ['cb_front_45', 'cb_side_41', 'cb_rear_47', 'cb_other_207'],
        answers,
        {
          'cb_front_45': 'Front',
          'cb_side_41': 'Side',
          'cb_rear_47': 'Rear',
          'cb_other_207': 'Other',
        },
      );
      _addOther(answers, 'cb_other_207', 'et_other_822', statusLocations);
      if (statusLocations.isNotEmpty) {
        final subCode = status.contains('significant') ? '{DEFLECTION_SIGNIFICANT}' : '{DEFLECTION_MINOR}';
        var template = _sub('{E_RC_DEFLECTION_STATUS}', subCode);
        if (template.isNotEmpty) {
          template = template.replaceAll('{RC_DEFLECTION_STATUS_LOCATION}', _toWords(statusLocations).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    final causedLocations = _labelsFor(
      ['cb_front_77', 'cb_side_14', 'cb_rear_27', 'cb_other_1028'],
      answers,
      {
        'cb_front_77': 'Front',
        'cb_side_14': 'Side',
        'cb_rear_27': 'Rear',
        'cb_other_1028': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1028', 'et_other_179', causedLocations);
    final reasons = _labelsFor(
      ['cb_damaged_roof_timber', 'cb_heavy_replacement_covering', 'cb_other_897'],
      answers,
      {
        'cb_damaged_roof_timber': 'Damaged roof timber',
        'cb_heavy_replacement_covering': 'Heavy replacement covering',
        'cb_other_897': 'Other',
      },
    );
    _addOther(answers, 'cb_other_897', 'et_other_410', reasons);
    if (causedLocations.isNotEmpty && reasons.isNotEmpty) {
      var template = _sub('{E_ROOF_COVERING}', '{E_RC_DEFLECTION_CAUSED_BY}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{RC_DEFLECTION_CAUSED_BY_LOCATION}', _toWords(causedLocations).toLowerCase())
            .replaceAll('{RC_DEFLECTION_CAUSED_BY_REASON}', _toWords(reasons).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_strengthen_timber'])) {
      final extra = _sub('{E_RC_DEFLECTION_OTHER}', '{DEFLECTION_STRENGTHEN_TIMBER}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    if (_isChecked(answers['cb_investigate'])) {
      final extra = _sub('{E_RC_DEFLECTION_OTHER}', '{DEFLECTION_INVESTIGATE}');
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
    template = template.replaceAll('{RC_CONTAINS_ASBESTOS}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _roofStructure(Map<String, String> answers) {
    final phrases = <String>[];
    final locations = _labelsFor(
      ['cb_main_building_22', 'cb_back_addition_48', 'cb_other_230'],
      answers,
      {
        'cb_main_building_22': 'Main building',
        'cb_back_addition_48': 'Back addition',
        'cb_other_230': 'Other',
      },
    );
    _addOther(answers, 'cb_other_230', 'et_other_859', locations);
    if (locations.isNotEmpty) {
      var template = _sub('{E_ROOF_COVERING}', '{RC_ROOF}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{RC_ROOF_LOCATION}', _toWords(locations).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final status = _cleanLower(answers['actv_status']);
    if (status.isNotEmpty) {
      if (status.contains('investigate')) {
        final investigateLocations = _labelsFor(
          ['cb_front_39', 'cb_side_78', 'cb_rear_20'],
          answers,
          {
            'cb_front_39': 'Front',
            'cb_side_78': 'Side',
            'cb_rear_20': 'Rear',
          },
        );
        if (investigateLocations.isNotEmpty) {
          var template = _sub('{E_ROOF_COVERING_ROOF_CONDITION}', '{RC_ROOF_CONDITION_INVESTIGATE}');
          if (template.isNotEmpty) {
            template = template.replaceAll('{RC_ROOF_INVESTIGATE_LOCATION}', _toWords(investigateLocations).toLowerCase());
            phrases.addAll(_split(_normalize(template)));
          }
        }
      } else {
        final template = _sub('{E_ROOF_COVERING_ROOF_CONDITION}', '{RC_ROOF_CONDITION_OK}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }
    return phrases;
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
    template = template.replaceAll('{RC_ROOF_SPREADING_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _roofRepairTiles(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');

    final items = _labelsFor(
      isSoon ? ['cb_roof_14', 'cb_ridge_64', 'cb_hip_95'] : ['cb_roof_40', 'cb_ridge_16', 'cb_hip_42'],
      answers,
      {
        'cb_roof_14': 'Roof',
        'cb_ridge_64': 'Ridge',
        'cb_hip_95': 'Hip',
        'cb_roof_40': 'Roof',
        'cb_ridge_16': 'Ridge',
        'cb_hip_42': 'Hip',
      },
    );

    final issues = _labelsFor(
      isSoon
          ? ['cb_are_loose_71', 'cb_have_slipped_19', 'cb_are_missing_88', 'cb_are_cracked_80', 'cb_are_poorly_secured_51', 'cb_are_damaged_24', 'cb_other_195']
          : ['cb_are_loose_24', 'cb_are_lifted_48', 'cb_have_slipped_71', 'cb_are_missing_29', 'cb_are_cracked_50', 'cb_are_poorly_secured_25', 'cb_are_damaged_65', 'cb_other_395'],
      answers,
      {
        'cb_are_loose_71': 'Are loose',
        'cb_have_slipped_19': 'Have slipped',
        'cb_are_missing_88': 'Are missing',
        'cb_are_cracked_80': 'Are cracked',
        'cb_are_poorly_secured_51': 'Are poorly secured',
        'cb_are_damaged_24': 'Are damaged',
        'cb_other_195': 'Other',
        'cb_are_loose_24': 'Are loose',
        'cb_are_lifted_48': 'Are lifted',
        'cb_have_slipped_71': 'Have slipped',
        'cb_are_missing_29': 'Are missing',
        'cb_are_cracked_50': 'Are cracked',
        'cb_are_poorly_secured_25': 'Are poorly secured',
        'cb_are_damaged_65': 'Are damaged',
        'cb_other_395': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_195' : 'cb_other_395', isSoon ? 'et_other_903' : 'et_other_339', issues);
    if (items.isEmpty || issues.isEmpty) return const [];

    final phraseCode = '{E_RC_TILES}';
    final subCode = isSoon ? '{REPAIR_SOON}' : '{REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{RC_ROOF_REPAIR_TILES_ONE_OR_FEW}', _toWords(items).toLowerCase())
        .replaceAll('{RC_ROOF_REPAIR_TILES_ISSUE}', _toWords(issues).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _roofRepairPoorRoof(Map<String, String> answers) {
    if (!_isChecked(answers['cb_repair_soon_70'])) return const [];
    final template = _sub('{E_ROOF_COVERING_REPAIR}', '{RC_POOR_ROOF_CONDITION}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _roofSpreadingRepair(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('yes')) {
      final template = _sub('{E_ROOF_COVERING_REPAIR}', '{RC_ROOF_SPREADING}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    final ok = _sub('{E_ROOF_COVERING_REPAIR}', '{ROOF_FIT_FOR_PURPOSE}');
    if (ok.isEmpty) return const [];
    return _split(_normalize(ok));
  }

  List<String> _roofRepairFlatRoof(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');
    final issues = _labelsFor(
      isSoon
          ? ['cb_torn', 'cb_split', 'cb_damaged', 'cb_blistered', 'cb_holding_water', 'cb_covered_with_moss', 'cb_other_944']
          : ['cb_torn_78', 'cb_split_43', 'cb_damaged_25', 'cb_blistered_45', 'cb_ponding_58', 'cb_other_516'],
      answers,
      {
        'cb_torn': 'Torn',
        'cb_split': 'Split',
        'cb_damaged': 'Damaged',
        'cb_blistered': 'Blistered',
        'cb_holding_water': 'Holding water',
        'cb_covered_with_moss': 'Covered with moss',
        'cb_other_944': 'Other',
        'cb_torn_78': 'Torn',
        'cb_split_43': 'Split',
        'cb_damaged_25': 'Damaged',
        'cb_blistered_45': 'Blistered',
        'cb_ponding_58': 'Ponding',
        'cb_other_516': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_944' : 'cb_other_516', isSoon ? 'et_other_617' : 'et_other_928', issues);
    if (issues.isEmpty) return const [];
    final phraseCode = '{E_RC_FLAT_ROOF_REPAIR}';
    final subCode = isSoon ? '{REPAIR_SOON}' : '{REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template.replaceAll('{RC_FLAT_ROOF_REPAIR_COVERED}', _toWords(issues).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _roofRepairParapetWall(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');
    final subject = _labelsFor(
      isSoon ? ['cb_rendering_68', 'cb_copping_21', 'cb_flashing_34', 'cb_other_836'] : ['cb_rendering_16', 'cb_copping_37', 'cb_flashing_76', 'cb_other_390'],
      answers,
      {
        'cb_rendering_68': 'Rendering',
        'cb_copping_21': 'Copping',
        'cb_flashing_34': 'Flashing',
        'cb_other_836': 'Other',
        'cb_rendering_16': 'Rendering',
        'cb_copping_37': 'Copping',
        'cb_flashing_76': 'Flashing',
        'cb_other_390': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_836' : 'cb_other_390', isSoon ? 'et_other_272' : 'et_other_662', subject);

    final location = _labelsFor(
      isSoon ? ['cb_right_72', 'cb_left_59', 'cb_rear_58', 'cb_front_70'] : ['cb_rendering_61', 'cb_copping_20', 'cb_flashing_83', 'cb_other_705'],
      answers,
      {
        'cb_right_72': 'Right',
        'cb_left_59': 'Left',
        'cb_rear_58': 'Rear',
        'cb_front_70': 'Front',
        'cb_rendering_61': 'Right',
        'cb_copping_20': 'Left',
        'cb_flashing_83': 'Rear',
        'cb_other_705': 'Front',
      },
    );

    final issues = _labelsFor(
      isSoon
          ? ['cb_damaged_94', 'cb_loose_22', 'cb_partly_missing_90', 'cb_cracked_73', 'cb_poorly_secured_94', 'cb_other_526']
          : ['cb_badly_damaged_70', 'cb_very_loose_63', 'cb_other_239'],
      answers,
      {
        'cb_damaged_94': 'Damaged',
        'cb_loose_22': 'Loose',
        'cb_partly_missing_90': 'Partly missing',
        'cb_cracked_73': 'Cracked',
        'cb_poorly_secured_94': 'Poorly secured',
        'cb_other_526': 'Other',
        'cb_badly_damaged_70': 'Badly damaged',
        'cb_very_loose_63': 'Very loose',
        'cb_other_239': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_526' : 'cb_other_239', isSoon ? 'et_other_730' : 'et_other_787', issues);

    if (subject.isEmpty || location.isEmpty || issues.isEmpty) return const [];
    final phraseCode = '{E_RC_PARAPET_WALL_REPAIR}';
    final subCode = isSoon ? '{REPAIR_SOON}' : '{REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{RC_PARAPET_WALL_REPAIR_SUBJECT}', _toWords(subject).toLowerCase())
        .replaceAll('{RC_PARAPET_WALL_REPAIR_LOCATION}', _toWords(location).toLowerCase())
        .replaceAll('{RC_PARAPET_WALL_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_safety_hazard'])) {
      final extra = _sub(phraseCode, '{REPAIR_NOW_SAFETY_HAZARD}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _roofRepairVerge(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isSoon = condition.contains('soon');
    final items = _labelsFor(
      isSoon ? ['cb_mortar_58', 'cb_tiles_101', 'cb_clips_95', 'cb_other_521'] : ['cb_rendering_52', 'cb_copping_32', 'cb_flashing_62', 'cb_other_814'],
      answers,
      {
        'cb_mortar_58': 'Mortar',
        'cb_tiles_101': 'Tiles',
        'cb_clips_95': 'Clips',
        'cb_other_521': 'Other',
        'cb_rendering_52': 'Mortar',
        'cb_copping_32': 'Tiles',
        'cb_flashing_62': 'Clips',
        'cb_other_814': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_521' : 'cb_other_814', isSoon ? 'et_other_650' : 'et_other_133', items);

    final issues = _labelsFor(
      isSoon
          ? ['cb_damaged_32', 'cb_loose_25', 'cb_partly_missing_77', 'cb_cracked_93', 'cb_poorly_secured_51', 'cb_other_507']
          : ['cb_badly_damaged_19', 'cb_badly_cracked_46', 'cb_about_to_drop_36', 'cb_other_491'],
      answers,
      {
        'cb_damaged_32': 'Damaged',
        'cb_loose_25': 'Loose',
        'cb_partly_missing_77': 'Partly missing',
        'cb_cracked_93': 'Cracked',
        'cb_poorly_secured_51': 'Poorly secured',
        'cb_other_507': 'Other',
        'cb_badly_damaged_19': 'Badly damaged',
        'cb_badly_cracked_46': 'Badly cracked',
        'cb_about_to_drop_36': 'About to drop',
        'cb_other_491': 'Other',
      },
    );
    _addOther(answers, isSoon ? 'cb_other_507' : 'cb_other_491', isSoon ? 'et_other_458' : 'et_other_477', issues);

    if (items.isEmpty || issues.isEmpty) return const [];
    final phraseCode = '{E_RC_VERGE_REPAIR}';
    final subCode = isSoon ? '{REPAIR_SOON}' : '{REPAIR_NOW}';
    var template = _sub(phraseCode, subCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{RC_VERGE_REPAIR_ITEM}', _toWords(items).toLowerCase())
        .replaceAll('{RC_VERGE_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (!isSoon && _isChecked(answers['cb_safety_hazard'])) {
      final extra = _sub(phraseCode, '{REPAIR_NOW_SAFETY_HAZARD}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _roofRepairValleyGutters(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_front_14', 'cb_side_19', 'cb_rear_95', 'cb_other_6081'],
      answers,
      {
        'cb_front_14': 'Front',
        'cb_side_19': 'Side',
        'cb_rear_95': 'Rear',
        'cb_other_6081': 'Other',
      },
    );
    _addOther(answers, 'cb_other_6081', 'et_other_7521', locations);

    final status = _labelsFor(
      ['cb_partially_35', 'cb_completely_78'],
      answers,
      {
        'cb_partially_35': 'Partially',
        'cb_completely_78': 'Completely',
      },
    );

    final issues = _labelsFor(
      ['cb_blocked_with_debris_90', 'cb_poorly_aligned_14', 'cb_Poor_detailing', 'cb_Detailing_damage', 'cb_other_608'],
      answers,
      {
        'cb_blocked_with_debris_90': 'Blocked with debris',
        'cb_poorly_aligned_14': 'Poorly aligned',
        'cb_Poor_detailing': 'Poor detailing',
        'cb_Detailing_damage': 'Detailing damage',
        'cb_other_608': 'Other',
      },
    );
    _addOther(answers, 'cb_other_608', 'et_other_752', issues);

    if (locations.isEmpty || status.isEmpty || issues.isEmpty) return const [];
    var template = _sub('{E_ROOF_COVERING_REPAIR}', '{E_RC_VALLEY_GUTTERS_REPAIR}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{RC_VALLEY_GUTTERS_REPAIR_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{RC_VALLEY_GUTTERS_REPAIR_STATUS}', _toWords(status).toLowerCase())
        .replaceAll('{RC_VALLEY_GUTTERS_REPAIR_ISSUE}', _toWords(issues).toLowerCase());
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
      ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_dormer_window', 'cb_other_601'],
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
    if (locations.isEmpty || assumed.isEmpty) return const [];
    var template = _sub('{E_ROOF_COVERING}', '{E_RC_NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{RC_NOT_INSPECTED_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{RC_NOT_INSPECTED_ASSUMED_TYPE}', assumed);
    return _split(_normalize(template));
  }

  List<String> _roofCoveringWeathered(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final template = _sub('{E_ROOF_COVERING}', '{RC_ABOUT_TYPE_CONDITION}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template.replaceAll('{RC_TYPE_CONDITION}', condition)));
  }

  List<String> _windowsAbout(Map<String, String> answers) {
    final madeUp = _cleanLower(answers['actv_made_up_of']);
    final replacement = _isChecked(answers['cb_is_replacement']) ? 'replacement' : '';
    final types = _labelsFor(
      [
        'cb_pvc',
        'cb_timber',
        'cb_steel',
        'cb_modern_pvc_sash',
        'cb_modern_timber_sash',
        'cb_aluminium',
        'cb_old_style_timber_sash',
        'cb_other_895',
      ],
      answers,
      {
        'cb_pvc': 'PVC',
        'cb_timber': 'Timber',
        'cb_steel': 'Steel',
        'cb_modern_pvc_sash': 'Modern PVC sash',
        'cb_modern_timber_sash': 'Modern timber sash',
        'cb_aluminium': 'Aluminium',
        'cb_old_style_timber_sash': 'Old style timber sash',
        'cb_other_895': 'Other',
      },
    );
    _addOther(answers, 'cb_other_895', 'et_other_220', types);
    final glazing = _labelsFor(
      ['cb_single', 'cb_double', 'cb_secondary'],
      answers,
      {
        'cb_single': 'Single',
        'cb_double': 'Double',
        'cb_secondary': 'Secondary',
      },
    );

    final phrases = <String>[];
    if (madeUp.isNotEmpty && types.isNotEmpty && glazing.isNotEmpty) {
      var template = _sub('{E_WINDOWS}', '{WINDOWS_ABOUT}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{WINDOW_ABOUT_WINDOW_MADE_UP}', madeUp)
            .replaceAll('{WINDOW_ABOUT_WINDOW_REPLACEMENT}', replacement)
            .replaceAll('{WINDOW_ABOUT_WINDOW_TYPE}', _toWords(types).toLowerCase())
            .replaceAll('{WINDOW_ABOUT_WINDOW_GLAZING}', _toWords(glazing).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final safetyStatus = _cleanLower(answers['actv_status']);
    if (safetyStatus.isNotEmpty) {
      var template = _sub('{WINDOWS_SAFETY_GLASS_RATING_STATUS}',
          safetyStatus.contains('noted') ? '{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED}' : '{WINDOWS_SAFETY_GLASS_RATING_STATUS_NO_SG_RATING}');
      if (template.isNotEmpty) {
        if (safetyStatus.contains('noted')) {
          final condition = _cleanLower(answers['actv_condition']);
          final conditionTemplate = condition.isNotEmpty
              ? _sub('{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED}', '{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED_CONDITION}')
                  .replaceAll('{WINDOW_SAFETY_STATUS_NOTED_CONDITION}', condition)
              : '';
          template = template.replaceAll('{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED_CONDITION}', conditionTemplate);
        }
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_is_replacement'])) {
      phrases.addAll(_split(_normalize(_sub('{E_WINDOWS}', '{WINDOWS_SAFETY_GLASS_RATING_IF_REPLACEMENT}'))));
    }
    if (_isChecked(answers['cb_old_style_timber_sash'])) {
      phrases.addAll(_split(_normalize(_sub('{E_WINDOWS}', '{WINDOWS_SAFETY_GLASS_RATING_IF_OLD_STYLE_TIMBER_SASH}'))));
    }

    return phrases;
  }

  List<String> _windowsSafetyGlassRating(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    var template = _sub('{WINDOWS_SAFETY_GLASS_RATING_STATUS}',
        status.contains('noted') ? '{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED}' : '{WINDOWS_SAFETY_GLASS_RATING_STATUS_NO_SG_RATING}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{WINDOWS_SAFETY_GLASS_RATING_STATUS_NOTED_CONDITION}', '');
    return _split(_normalize(template));
  }

  List<String> _windowsWallSealing(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    var template = _sub('{E_WINDOWS}', '{WINDOW_WALL_SEALING}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{WINDOW_WALL_SEALING}', condition);
    return _split(_normalize(template));
  }

  List<String> _windowsSillProjection(Map<String, String> answers) {
    final projection = _cleanLower(answers['actv_projection_type']);
    final condition = _cleanLower(answers['actv_condition']);
    if (projection.isEmpty || condition.isEmpty) return const [];
    var template = _sub('{E_WINDOWS}', '{WINDOW_SILL_PROJECTION}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{WINDOW_SILL_PROJECTION_TYPE}', projection)
        .replaceAll('{WINDOW_SILL_PROJECTION_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _windowsVelux(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_type']);
    if (type.isEmpty) return const [];
    final isMultiple = type.contains('multiple');

    final locations = _labelsFor(
      isMultiple ? ['cb_loft_32', 'cb_extension_85', 'cb_other_451'] : ['cb_loft', 'cb_extension', 'cb_other_629'],
      answers,
      {
        'cb_loft': 'Loft',
        'cb_extension': 'Extension',
        'cb_other_629': 'Other',
        'cb_loft_32': 'Loft',
        'cb_extension_85': 'Extension',
        'cb_other_451': 'Other',
      },
    );
    if (isMultiple) {
      _addOther(answers, 'cb_other_451', 'et_other_816', locations);
    } else {
      _addOther(answers, 'cb_other_629', 'et_other_290', locations);
    }

    final materials = _labelsFor(
      isMultiple ? ['cb_pvc_24', 'cb_timber_44', 'cb_steel_91', 'cb_other_975'] : ['cb_pvc', 'cb_timber', 'cb_steel', 'cb_other_610'],
      answers,
      {
        'cb_pvc': 'PVC',
        'cb_timber': 'Timber',
        'cb_steel': 'Steel',
        'cb_other_610': 'Other',
        'cb_pvc_24': 'PVC',
        'cb_timber_44': 'Timber',
        'cb_steel_91': 'Steel',
        'cb_other_975': 'Other',
      },
    );
    if (isMultiple) {
      _addOther(answers, 'cb_other_975', 'et_other_659', materials);
    } else {
      _addOther(answers, 'cb_other_610', 'et_other_196', materials);
    }

    final glazing = _labelsFor(
      isMultiple ? ['cb_single_48', 'cb_double_67', 'cb_secondary_54'] : ['cb_single', 'cb_double', 'cb_secondary'],
      answers,
      {
        'cb_single': 'Single',
        'cb_double': 'Double',
        'cb_secondary': 'Secondary',
        'cb_single_48': 'Single',
        'cb_double_67': 'Double',
        'cb_secondary_54': 'Secondary',
      },
    );

    final phrases = <String>[];
    if (locations.isNotEmpty && materials.isNotEmpty && glazing.isNotEmpty) {
      var template = _sub('{WINDOW_VELUX_TYPE}', isMultiple ? '{WINDOW_VELUX_TYPE_MULTIPLE}' : '{WINDOW_VELUX_TYPE_SINGLE}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{WINDOW_VELUX_LOCATION}', _toWords(locations).toLowerCase())
            .replaceAll('{WINDOW_VELUX_STATUS_TYPE}', _toWords(materials).toLowerCase())
            .replaceAll('{WINDOW_VELUX_GLAZZING}', _toWords(glazing).toLowerCase());
        if (isMultiple) {
          final number = _veluxNumber(answers);
          template = template.replaceAll('{WINDOW_VELUX_NUMBER}', number);
        }
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub('{WINDOW_VELUX_TYPE}', '{WINDOW_VELUX_CONDITION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WINDOW_VELUX_CONDITION}', condition);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _windowsNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{E_WINDOWS}', '{NOT_INSPECTED}')));
  }

  List<String> _windowsRepair(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_lounge_791', 'cb_lounge_79', 'cb_bedroom_35', 'cb_kitchen_80', 'cb_other_471'],
      answers,
      {
        'cb_lounge_791': 'Property',
        'cb_lounge_79': 'Lounge',
        'cb_bedroom_35': 'Bedroom',
        'cb_kitchen_80': 'Kitchen',
        'cb_other_471': 'Other',
      },
    );
    _addOther(answers, 'cb_other_471', 'et_other_175', locations);
    final defects = _labelsFor(
      [
        'cb_have_damaged_locks_63',
        'cb_are_difficult_to_open_15',
        'cb_are_badly_worn_25',
        'cb_are_rotten_64',
        'cb_have_broken_panes_14',
        'cb_have_failed_glazing_40',
        'cb_are_in_disrepair_33',
        'cb_other_1066',
      ],
      answers,
      {
        'cb_have_damaged_locks_63': 'Have damaged locks',
        'cb_are_difficult_to_open_15': 'Are difficult to open',
        'cb_are_badly_worn_25': 'Are badly worn',
        'cb_are_rotten_64': 'Are rotten',
        'cb_have_broken_panes_14': 'Have broken panes',
        'cb_have_failed_glazing_40': 'Have failed glazing',
        'cb_are_in_disrepair_33': 'Are in disrepair',
        'cb_other_1066': 'Other',
      },
    );
    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{E_WINDOWS_REPAIR}', '{WINDOWS_REPAIR}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{WINDOWS_REPAIR_WINDOW_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{WINDOWS_REPAIR_WINDOW_DEFECT}', _toWords(defects).toLowerCase());
    final phrases = _split(_normalize(template)).toList();
    if (defects.any((d) => d.toLowerCase().contains('disrepair'))) {
      phrases.addAll(_split(_normalize(_sub('{E_WINDOWS_REPAIR}', '{WINDOWS_DEFECT_IF_IN_DISREPAIR}'))));
    }
    return phrases;
  }

  List<String> _windowsRepairFailedGlazing(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb__property', 'cb_lounge_79', 'cb_bedroom_35', 'cb_kitchen_80', 'cb_have_damaged_locks_63', 'cb_other_471'],
      answers,
      {
        'cb__property': 'Property',
        'cb_lounge_79': 'Lounge',
        'cb_bedroom_35': 'Bedroom',
        'cb_kitchen_80': 'Kitchen',
        'cb_have_damaged_locks_63': 'Bathroom',
        'cb_other_471': 'Other',
      },
    );
    _addOther(answers, 'cb_other_471', 'et_other_175', locations);
    if (locations.isEmpty) return const [];
    var template = _sub('{E_WINDOWS_REPAIR}', '{WINDOWS_REPAIR_FAILED_GLAZING_LOCATION}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{WINDOWS_REPAIR_FAILED_GLAZING_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _windowsRepairNoFireEscapeRisk(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_lounge_84', 'cb_bedroom_43', 'cb_study_61', 'cb_other_175'],
      answers,
      {
        'cb_lounge_84': 'Lounge',
        'cb_bedroom_43': 'Bedroom',
        'cb_study_61': 'Study',
        'cb_other_175': 'Other',
      },
    );
    _addOther(answers, 'cb_other_175', 'et_other_308', locations);
    final defects = _labelsFor(
      ['cb_no_opening_63', 'cb_is_too_small_23', 'cb_is_too_small_23_no'],
      answers,
      {
        'cb_no_opening_63': 'No opening',
        'cb_is_too_small_23': 'Opening too small',
        'cb_is_too_small_23_no': 'No window at all',
      },
    );
    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{E_WINDOWS_REPAIR}', '{WINDOWS_REPAIR_NO_FIRE_ESCAPE_RISK}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{WINDOWS_REPAIR_NO_FIRE_ESCAPE_RISK_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{WINDOWS_REPAIR_NO_FIRE_ESCAPE_RISK_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _outsideDoorsAbout(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_main', 'cb_rear', 'cb_side', 'cb_patio', 'cb_garage', 'cb_other_859'],
      answers,
      {
        'cb_main': 'Main',
        'cb_rear': 'Rear',
        'cb_side': 'Side',
        'cb_patio': 'Patio',
        'cb_garage': 'Garage',
        'cb_other_859': 'Other',
      },
    );
    _addOther(answers, 'cb_other_859', 'et_other_179', locations);

    final materials = _labelsFor(
      ['cb_pvc', 'cb_timber', 'cb_steel', 'cb_aluminium', 'cb_other_826'],
      answers,
      {
        'cb_pvc': 'PVC',
        'cb_timber': 'Timber',
        'cb_steel': 'Steel',
        'cb_aluminium': 'Aluminium',
        'cb_other_826': 'Other',
      },
    );
    if (_isChecked(answers['cb_other_826'])) {
      final otherMaterial = _firstNonEmpty(answers, ['et_other_152', 'et_other_179', 'other']);
      materials.add(otherMaterial.isEmpty ? 'Other' : otherMaterial);
    }

    final glazing = _labelsFor(
      ['cb_single', 'cb_double'],
      answers,
      {
        'cb_single': 'Single',
        'cb_double': 'Double',
      },
    );

    final replacement = _isChecked(answers['cb_replacement']) ? 'replacement' : '';
    final safetyStatus = _cleanLower(answers['actv_status']);
    final condition = _cleanLower(answers['actv_condition']);
    final sealing = _cleanLower(answers['actv_status_security']);
    final security = _cleanLower(answers['actv_seciruty_offered']);

    final phrases = <String>[];
    for (final material in materials) {
      final code = _doorMaterialCode(material);
      var template = _sub('{E_OUTSIDE_DOORS}', code);
      if (template.isEmpty) continue;

      var doorLocation = _sub('{E_OUTSIDE_DOORS}', '{DOOR_LOCATION}');
      if (doorLocation.isNotEmpty && locations.isNotEmpty && glazing.isNotEmpty) {
        doorLocation = doorLocation
            .replaceAll('{DOOR_LOCATION}', _toWords(locations).toLowerCase())
            .replaceAll('{REPLACEMENT}', replacement)
            .replaceAll('{DOOR_MATERIAL}', material.toLowerCase())
            .replaceAll('{DOOR_GLAZZING}', _toWords(glazing).toLowerCase());
      }

      var sgText = '';
      if (safetyStatus.isNotEmpty) {
        sgText = _sub('{E_OUTSIDE_DOORS}',
            safetyStatus.contains('noted') ? '{DOOR_SG_RATING_NOTED}' : '{DOOR_SG_RATING_NO_SG_RATING}');
      }

      var conditionText = '';
      if (condition.isNotEmpty) {
        conditionText = _sub('{E_OUTSIDE_DOORS}', '{DOOR_CONDITION}')
            .replaceAll('{DOOR_CONDITION}', condition);
      }

      var sealingText = '';
      if (sealing.isNotEmpty && security.isNotEmpty) {
        sealingText = _sub('{E_OUTSIDE_DOORS}', '{WALL_SEALING}')
            .replaceAll('{DOOR_SEALING_CONDITION}', sealing)
            .replaceAll('{SECURITY_OFFERED}', security);
      }

      template = template
          .replaceAll('{DOOR_LOCATION}', doorLocation)
          .replaceAll('{DOOR_SG_RATING_STATUS}', sgText)
          .replaceAll('{DOOR_CONDITION}', conditionText)
          .replaceAll('{WALL_SEALING}', sealingText);
      phrases.addAll(_split(_normalize(template)));
    }

    if (_isChecked(answers['cb_replacement'])) {
      phrases.addAll(_split(_normalize(_sub('{E_OUTSIDE_DOORS}', '{IF_REPLACEMENT}'))));
    }

    return phrases;
  }

  List<String> _outsideDoorsRepair(String screenId, Map<String, String> answers) {
    final repairType = _cleanLower(answers['actv_repair_type']);
    if (repairType.isEmpty) return const [];
    final isNow = repairType.contains('now');

    final defects = _labelsFor(
      isNow
          ? ['cb_poorly_secured', 'cb_inadequate_lock', 'cb_rotted_frame', 'cb_damaged_lock', 'cb_other_337']
          : ['cb_damaged', 'cb_rotten', 'cb_partly_worn', 'cb_failed_glazing', 'cb_sticks_against_frame', 'cb_poorly_fitted', 'cb_other_837'],
      answers,
      {
        'cb_poorly_secured': 'Poorly secured',
        'cb_inadequate_lock': 'Inadequate lock',
        'cb_rotted_frame': 'Rotted frame',
        'cb_damaged_lock': 'Damaged lock',
        'cb_other_337': 'Other',
        'cb_damaged': 'Damaged',
        'cb_rotten': 'Rotten',
        'cb_partly_worn': 'Partly worn',
        'cb_failed_glazing': 'Failed glazing',
        'cb_sticks_against_frame': 'Sticks against frame',
        'cb_poorly_fitted': 'Poorly fitted',
        'cb_other_837': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_337', 'et_other_362', defects);
    } else {
      _addOther(answers, 'cb_other_837', 'et_other_855', defects);
    }
    if (defects.isEmpty) return const [];

    final doorLocation = _doorLocationFromScreen(screenId);
    final repairCode = _doorRepairSection(screenId);
    var wrapper = _sub('{E_OUTSIDE_DOORS}', repairCode);
    if (wrapper.isEmpty) return const [];

    final repairTemplate = _sub('{E_OUTSIDE_DOORS}', isNow ? '{DOOR_REPAIR_NOW}' : '{DOOR_REPAIR_SOON}')
        .replaceAll('{DOOR_LOCATION}', doorLocation)
        .replaceAll('{DOOR_DEFECT}', _toWords(defects).toLowerCase());

    wrapper = wrapper
        .replaceAll('{DOOR_REPAIR_SOON}', isNow ? '' : repairTemplate)
        .replaceAll('{DOOR_REPAIR_NOW}', isNow ? repairTemplate : '');

    final phrases = _split(_normalize(wrapper)).toList();
    if (_isChecked(answers['cb_damaged_lock'])) {
      final lock = _sub('{E_OUTSIDE_DOORS}', '{DAMAGED_STOCK_LOCK_SELECTED}')
          .replaceAll('{DOOR_LOCATION}', doorLocation);
      phrases.addAll(_split(_normalize(lock)));
    }
    return phrases;
  }

  List<String> _cpLocationConstruction(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_porch_type']);
    final location = _cleanLower(answers['actv_location']);
    final construction = _labelsFor(
      ['cb_brick_walls', 'cb_pvc_double_glazed_sections', 'cb_timber_double_glazed_sections', 'cb_other_925'],
      answers,
      {
        'cb_brick_walls': 'Brick walls',
        'cb_pvc_double_glazed_sections': 'PVC double glazed sections',
        'cb_timber_double_glazed_sections': 'Timber double glazed sections',
        'cb_other_925': 'Other',
      },
    );
    _addOther(answers, 'cb_other_925', 'et_other_249', construction);
    if (type.isEmpty || location.isEmpty || construction.isEmpty) return const [];

    final isPorch = type.contains('porch') && !type.contains('conservatory');
    var template = _sub('{E_CONSERVATORY_PORCHES}', isPorch ? '{PORCH_LOCATION_CONSTRUCTION}' : '{LOCATION_CONSTRUCTION}');
    if (template.isEmpty) return const [];
    if (isPorch) {
      template = template
          .replaceAll('{CP_LC_LOCATION_PORCH}', location)
          .replaceAll('{CP_LC_CONSTRUCTION_PORCH}', _toWords(construction).toLowerCase());
    } else {
      template = template
          .replaceAll('{CP_LC_LOCATION}', location)
          .replaceAll('{CP_LC_CONSTRUCTION}', _toWords(construction).toLowerCase());
    }
    return _split(_normalize(template));
  }

  List<String> _cpRoof(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_conservatory_porch']);
    final roofType = _cleanLower(answers['actv_roof_type']);
    final materials = _labelsFor(
      [
        'cb_pvc_double_glazed_sections',
        'cb_polycarbonate_sheets',
        'cb_concrete_tiles',
        'cb_clay_tiles',
        'cb_mineral_felt',
        'cb_lead',
        'cb_others_373',
      ],
      answers,
      {
        'cb_pvc_double_glazed_sections': 'PVC double glazed sections',
        'cb_polycarbonate_sheets': 'Polycarbonate sheets',
        'cb_concrete_tiles': 'Concrete tiles',
        'cb_clay_tiles': 'Clay tiles',
        'cb_mineral_felt': 'Mineral felt',
        'cb_lead': 'Lead',
        'cb_others_373': 'Other',
      },
    );
    if (_isChecked(answers['cb_others_373'])) {
      final other = (answers['et_other_403'] ?? '').trim();
      materials.add(other.isEmpty ? 'Other' : other);
    }
    if (type.isEmpty || roofType.isEmpty || materials.isEmpty) return const [];
    final isPorch = type.contains('porch');
    var template = _sub('{E_CONSERVATORY_PORCHES}', isPorch ? '{PORCH_ROOF}' : '{CP_ROOF}');
    if (template.isEmpty) return const [];
    if (isPorch) {
      template = template
          .replaceAll('{CP_ROOF_TYPE_PORCH}', roofType)
          .replaceAll('{CP_ROOF_MATERIAL_PORCH}', _toWords(materials).toLowerCase());
    } else {
      template = template
          .replaceAll('{CP_ROOF_TYPE}', roofType)
          .replaceAll('{CP_ROOF_MATERIAL}', _toWords(materials).toLowerCase());
    }
    return _split(_normalize(template));
  }

  List<String> _cpWindows(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_conservatory_porch']);
    final glazing = _labelsFor(
      ['cb_single', 'cb_double'],
      answers,
      {
        'cb_single': 'Single',
        'cb_double': 'Double',
      },
    );
    final materials = _labelsFor(
      ['cb_pvc', 'cb_timber', 'cb_other_1047'],
      answers,
      {
        'cb_pvc': 'PVC',
        'cb_timber': 'Timber',
        'cb_other_1047': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1047', 'et_other_632', materials);
    if (type.isEmpty || glazing.isEmpty || materials.isEmpty) return const [];
    final isPorch = type.contains('porch');
    var template = _sub('{E_CONSERVATORY_PORCHES}', isPorch ? '{PORCH_WINDOWS}' : '{CP_WINDOWS}');
    if (template.isEmpty) return const [];
    if (isPorch) {
      template = template
          .replaceAll('{CP_WINDOWS_INCORPORATES_PORCH}', _toWords(glazing).toLowerCase())
          .replaceAll('{CP_WINDOWS_GLAZZING_PORCH}', _toWords(materials).toLowerCase());
    } else {
      template = template
          .replaceAll('{CP_WINDOWS_INCORPORATES}', _toWords(glazing).toLowerCase())
          .replaceAll('{CP_WINDOWS_GLAZZING}', _toWords(materials).toLowerCase());
    }
    return _split(_normalize(template));
  }

  List<String> _cpDoors(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_conservatory_porch']);
    final glazing = _labelsFor(
      ['cb_single', 'cb_double'],
      answers,
      {
        'cb_single': 'Single',
        'cb_double': 'Double',
      },
    );
    final materials = _labelsFor(
      ['cb_pvc', 'cb_timber', 'cb_other_1047'],
      answers,
      {
        'cb_pvc': 'PVC',
        'cb_timber': 'Timber',
        'cb_other_1047': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1047', 'et_other_632', materials);
    if (type.isEmpty || glazing.isEmpty || materials.isEmpty) return const [];
    final isPorch = type.contains('porch');
    var template = _sub('{E_CONSERVATORY_PORCHES}', isPorch ? '{PORCH_DOORS}' : '{CP_DOORS}');
    if (template.isEmpty) return const [];
    if (isPorch) {
      template = template
          .replaceAll('{CP_DOORS_INCORPORATES_PORCH}', _toWords(glazing).toLowerCase())
          .replaceAll('{CP_DOORS_GLAZZING_PORCH}', _toWords(materials).toLowerCase());
    } else {
      template = template
          .replaceAll('{CP_DOORS_INCORPORATES}', _toWords(glazing).toLowerCase())
          .replaceAll('{CP_DOORS_GLAZZING}', _toWords(materials).toLowerCase());
    }
    final phrases = _split(_normalize(template)).toList();
    if (glazing.any((g) => g.toLowerCase().contains('double'))) {
      final extra = _sub('{E_CONSERVATORY_PORCHES}',
          isPorch ? '{PORCH_DOORS_INCORPORATES_IF_DOUBLE_SELECTED}' : '{CP_DOORS_INCORPORATES_IF_DOUBLE_SELECTED}');
      if (extra.isNotEmpty) {
        phrases.addAll(_split(_normalize(extra)));
      }
    }
    return phrases;
  }

  List<String> _cpFloor(Map<String, String> answers) {
    final coverings = _labelsFor(
      ['cb_tiles', 'cb_laminate_flooring', 'cb_carpets', 'cb_other_743'],
      answers,
      {
        'cb_tiles': 'Tiles',
        'cb_laminate_flooring': 'Laminate flooring',
        'cb_carpets': 'Carpets',
        'cb_other_743': 'Other',
      },
    );
    _addOther(answers, 'cb_other_743', 'et_other_886', coverings);
    if (coverings.isEmpty) return const [];
    var template = _sub('{E_CONSERVATORY_PORCHES}', '{CP_FLOOR}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CP_FLOOR_COVERED_IN}', _toWords(coverings).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _cpSafetyGlassRating(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    final type = _cleanLower(answers['actv_condition']);
    if (status.isEmpty || type.isEmpty) return const [];
    final isPorch = type.contains('porch');
    final code = status.contains('noted')
        ? (isPorch ? '{PORCH_SAFETY_GLASS_RATING_NOTED}' : '{CP_SAFETY_GLASS_RATING_NOTED}')
        : (isPorch ? '{PORCH_SAFETY_GLASS_RATING_NO_SG_RATING}' : '{CP_SAFETY_GLASS_RATING_NO_SG_RATING}');
    final template = _sub('{E_CONSERVATORY_PORCHES}', code);
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _cpFlashing(Map<String, String> answers) {
    final materials = _labelsFor(
      ['cb_lead', 'cb_mortar', 'cb_tiles', 'cb_other_33'],
      answers,
      {
        'cb_lead': 'Lead',
        'cb_mortar': 'Mortar',
        'cb_tiles': 'Tiles',
        'cb_other_33': 'Other',
      },
    );
    _addOther(answers, 'cb_other_33', 'et_other_87', materials);
    final condition = _cleanLower(answers['actv_condition']);
    if (materials.isEmpty || condition.isEmpty) return const [];
    var template = _sub('{E_CONSERVATORY_PORCHES}', '{ROOF_FLASHING_WITH_WALL}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{ROOF_FLASHING}', _toWords(materials).toLowerCase())
        .replaceAll('{CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _cpOpenToBuilding(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final type = _cleanLower(answers['actv_condition']);
    if (type.isEmpty) return const [];
    final template = _sub('{E_CONSERVATORY_PORCHES}',
        type.contains('porch') ? '{PORCH_OPEN_TO_BUILDING}' : '{CP_OPEN_TO_BUILDING}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _cpPorchCondition(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    var template = _sub('{E_CONSERVATORY_PORCHES}', '{PORCH_CONDITION}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CP_CONDITION_PORCH}', condition);
    return _split(_normalize(template));
  }

  List<String> _cpPoorCondition(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final type = _cleanLower(answers['actv_condition']);
    if (type.isEmpty) return const [];
    final template = _sub('{E_CONSERVATORY_PORCHES}',
        type.contains('porch') ? '{PORCH_POOR_CONDITION}' : '{CP_POOR_CONDITION}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _cpNotInspected(Map<String, String> answers) {
    if (_isChecked(answers['cb_main_building'])) {
      return _split(_normalize(_sub('{E_CONSERVATORY_PORCHES}', '{NOT_INSPECTED_NOT_APPLICABLE}')));
    }
    if (_isChecked(answers['cb_back_addition'])) {
      return _split(_normalize(_sub('{E_CONSERVATORY_PORCHES}', '{NOT_INSPECTED_NONE}')));
    }
    return const [];
  }

  List<String> _cpRepairs(String screenId, Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final isNow = condition.contains('now');
    final defects = _labelsFor(
      isNow
          ? ['cb_cracked_51', 'cb_damaged_22', 'cb_rotten_46', 'cb_leaking_80', 'cb_damp_25', 'cb_failed_89', 'cb_misted_over_85', 'cb_other_350']
          : ['cb_cracked', 'cb_damaged', 'cb_rotten', 'cb_leaking', 'cb_damp', 'cb_failed', 'cb_misted_over', 'cb_other_519'],
      answers,
      {
        'cb_cracked': 'Cracked',
        'cb_damaged': 'Damaged',
        'cb_rotten': 'Rotten',
        'cb_leaking': 'Leaking',
        'cb_damp': 'Damp',
        'cb_failed': 'Failed',
        'cb_misted_over': 'Misted over',
        'cb_other_519': 'Other',
        'cb_cracked_51': 'Badly cracked',
        'cb_damaged_22': 'Severely damaged',
        'cb_rotten_46': 'Badly rotten',
        'cb_leaking_80': 'Severely leaking',
        'cb_damp_25': 'Causing damp',
        'cb_failed_89': 'Failed',
        'cb_misted_over_85': 'Misted over',
        'cb_other_350': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_350', 'et_other_430', defects);
    } else {
      _addOther(answers, 'cb_other_519', 'et_other_346', defects);
    }
    if (defects.isEmpty) return const [];

    final location = _cpRepairLocationFromScreen(screenId);
    var repair = _sub('{E_CONSERVATORY_PORCHES}', isNow ? '{CP_REPAIR_NOW}' : '{CP_REPAIR_SOON}');
    if (repair.isEmpty) return const [];
    repair = repair
        .replaceAll('{CP_LOCATION}', location)
        .replaceAll('{IS_ARE}', 'are')
        .replaceAll('{CP_DEFECT_SOON}', _toWords(defects).toLowerCase())
        .replaceAll('{CP_DEFECT_NOW}', _toWords(defects).toLowerCase());

    final wrapper = _sub('{E_CONSERVATORY_PORCHES}', _cpRepairWrapper(screenId));
    if (wrapper.isEmpty) return _split(_normalize(repair));
    final result = wrapper
        .replaceAll('{CP_REPAIR_SOON}', isNow ? '' : repair)
        .replaceAll('{CP_REPAIR_NOW}', isNow ? repair : '');
    return _split(_normalize(result));
  }

  List<String> _otherJoineryAbout(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_facias', 'cb_soffits', 'cb_bargeboards', 'cb_verge_clips', 'cb_other_326'],
      answers,
      {
        'cb_facias': 'Facias',
        'cb_soffits': 'Soffits',
        'cb_bargeboards': 'Bargeboards',
        'cb_verge_clips': 'Verge clips',
        'cb_other_326': 'Other',
      },
    );
    _addOther(answers, 'cb_other_326', 'et_other_393', items);
    final materials = _labelsFor(
      ['cb_timber', 'cb_pvc', 'cb_slates', 'cb_other_397'],
      answers,
      {
        'cb_timber': 'Timber',
        'cb_pvc': 'PVC',
        'cb_slates': 'Slates',
        'cb_other_397': 'Other',
      },
    );
    _addOther(answers, 'cb_other_397', 'et_other_397', materials);
    if (items.isEmpty || materials.isEmpty) return const [];
    var template = _sub('{E_OTHER_JOINERY_AND_FINISHES}', '{ABOUT_OTHER_JOINERY_AND_FINISHES}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OJAF_ABOUT_EXTERNAL_WORK_INCLUDES}', _toWords(items).toLowerCase())
        .replaceAll('{OJAF_ABOUT_MATERIAL}', _toWords(materials).toLowerCase());
    final phrases = _split(_normalize(template)).toList();

    if (_isChecked(answers['cb_Redecorate'])) {
      phrases.addAll(_split(_normalize(_sub('{E_OTHER_JOINERY_AND_FINISHES}', '{REPAIR_REDECORATE}'))));
    }
    return phrases;
  }

  List<String> _otherJoineryCondition(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    var template = _sub('{E_OTHER_JOINERY_AND_FINISHES}', '{CONDITION}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OJAF_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _otherJoineryAsbestos(Map<String, String> answers) {
    if (!_isChecked(answers['cb_open_runoffs'])) return const [];
    final template = _sub('{E_OTHER_JOINERY_AND_FINISHES}', '{CONTAIN_ASBESTOS}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _otherJoineryRepairs(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_facias', 'cb_soffits', 'cb_barge_boards', 'cb_verge_clips', 'cb_timber_cladding', 'cb_other_289'],
      answers,
      {
        'cb_facias': 'Facias',
        'cb_soffits': 'Soffits',
        'cb_barge_boards': 'Barge boards',
        'cb_verge_clips': 'Verge clips',
        'cb_timber_cladding': 'Timber cladding',
        'cb_other_289': 'Other',
      },
    );
    _addOther(answers, 'cb_other_289', 'et_other_178', items);
    final locations = _labelsFor(
      ['cb_main_building_86', 'cb_back_addition_47', 'cb_extension_25', 'cb_bay_window_61', 'cb_garage_21', 'cb_other_269'],
      answers,
      {
        'cb_main_building_86': 'Main building',
        'cb_back_addition_47': 'Back addition',
        'cb_extension_25': 'Extension',
        'cb_bay_window_61': 'Bay window',
        'cb_garage_21': 'Garage',
        'cb_other_269': 'Other',
      },
    );
    final defects = _labelsFor(
      ['cb_rotted', 'cb_damaged', 'cb_poorly_secured', 'cb_incomplete', 'cb_other_777'],
      answers,
      {
        'cb_rotted': 'Rotted',
        'cb_damaged': 'Damaged',
        'cb_poorly_secured': 'Poorly secured',
        'cb_incomplete': 'Incomplete',
        'cb_other_777': 'Other',
      },
    );
    if (items.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{E_OTHER_JOINERY_AND_FINISHES}', '{REPAIR_SOON}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OJAF_REPAIR_ITEM}', _toWords(items).toLowerCase())
        .replaceAll('{OJAF_REPAIR_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{OJAF_REPAIR_DEFECT}', _toWords(defects).toLowerCase());
    final phrases = _split(_normalize(template)).toList();
    if (_isChecked(answers['cb_safety_hazard'])) {
      phrases.addAll(_split(_normalize(_sub('{E_OTHER_JOINERY_AND_FINISHES}', '{REPAIR_SAFETY_HAZARD}'))));
    }
    return phrases;
  }

  List<String> _otherJoineryNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{E_OTHER_JOINERY_AND_FINISHES}', '{NOT_INSPECTED}')));
  }

  List<String> _otherCommunalArea(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    final phrases = <String>[];
    if (status.contains('inspected')) {
      final items = _labelsFor(
        [
          'cb_automatic_gates',
          'cb_cctv',
          'cb_communal_door',
          'cb_entry_system',
          'cb_drive_access',
          'cb_car_park',
          'cb_walk_paths',
          'cb_gardens',
          'cb_grounds',
          'cb_play_ground',
          'cb_other_1034',
        ],
        answers,
        {
          'cb_automatic_gates': 'Automatic gates',
          'cb_cctv': 'CCTV',
          'cb_communal_door': 'Communal door',
          'cb_entry_system': 'Entry system',
          'cb_drive_access': 'Drive access',
          'cb_car_park': 'Car park',
          'cb_walk_paths': 'Walk paths',
          'cb_gardens': 'Gardens',
          'cb_grounds': 'Grounds',
          'cb_play_ground': 'Play ground',
          'cb_other_1034': 'Other',
        },
      );
      _addOther(answers, 'cb_other_1034', 'et_other_747', items);
      if (items.isNotEmpty) {
        var template = _sub('{E_OTHER}', '{COMMUNAL_AREA_INSPECTED}');
        template = template.replaceAll('{OTHER_COMMUNAL_AREA_EXTERNAL}', _toWords(items).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }

      final condition = _cleanLower(answers['actv_condition']);
      if (condition.isNotEmpty) {
        var template = _sub('{E_OTHER}', '{COMMUNAL_AREA_CONDITION}');
        template = template.replaceAll('{OTHER_COMMUNAL_AREA_CONDITION}', condition);
        phrases.addAll(_split(_normalize(template)));
      }
    } else {
      final reasons = _labelsFor(
        ['cb_the_area_is_not_accessible', 'cb_of_limited_access', 'cb_other_251'],
        answers,
        {
          'cb_the_area_is_not_accessible': 'The area is not accessible',
          'cb_of_limited_access': 'Of limited access',
          'cb_other_251': 'Other',
        },
      );
      if (reasons.isNotEmpty) {
        var template = _sub('{E_OTHER}', '{COMMUNAL_AREA_NOT_INSPECTED}');
        template = template.replaceAll('{OTHER_COMMUNAL_AREA_BECAUSE}', _toWords(reasons).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _otherNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{E_OTHER}', '{OTHER_NOT_APPLICABLE}')));
  }

  List<String> _otherConstruction(Map<String, String> answers, String areaKey, String otherTextKey) {
    final area = _cleanLower(answers[areaKey]);
    if (area.isEmpty) return const [];
    final materials = _labelsFor(
      ['cb_timber', 'cb_concrete', 'cb_steel', 'cb_other_472'],
      answers,
      {
        'cb_timber': 'Timber',
        'cb_concrete': 'Concrete',
        'cb_steel': 'Steel',
        'cb_other_472': 'Other',
      },
    );
    _addOther(answers, 'cb_other_472', otherTextKey, materials);
    if (materials.isEmpty) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_CONSTRUCTION}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', area)
        .replaceAll('{CONSTRUCTION}', _toWords(materials).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRoof(Map<String, String> answers) {
    final area = _cleanLower(answers['actv_roof_location']);
    final roofType = _cleanLower(answers['actv_roof_type']);
    final covered = _cleanLower(answers['actv_covered_in']);
    if (area.isEmpty || roofType.isEmpty || covered.isEmpty) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_ROOF}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', area)
        .replaceAll('{ROOF_TYPE}', roofType)
        .replaceAll('{ROOF_COVERED_IN}', covered);
    return _split(_normalize(template));
  }

  List<String> _otherFloor(Map<String, String> answers) {
    final area = _cleanLower(answers['actv_area']);
    if (area.isEmpty) return const [];
    final materials = _labelsFor(
      ['cb_timber', 'cb_other_472'],
      answers,
      {
        'cb_timber': 'Concrete',
        'cb_other_472': 'Other',
      },
    );
    _addOther(answers, 'cb_other_472', 'et_other_99', materials);
    if (materials.isEmpty) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_FLOOR}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', area)
        .replaceAll('{FLOORS}', _toWords(materials).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherDrains(Map<String, String> answers) {
    final area = _cleanLower(answers['actv_drains_location']);
    if (area.isEmpty) return const [];
    final materials = _labelsFor(
      ['cb_lead', 'cb_mortar', 'cb_bitumen', 'cb_other_782'],
      answers,
      {
        'cb_lead': 'Lead',
        'cb_mortar': 'Mortar',
        'cb_bitumen': 'Bitumen',
        'cb_other_782': 'Other',
      },
    );
    _addOther(answers, 'cb_other_782', 'et_other_171', materials);
    if (materials.isEmpty) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_DRAINS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', area)
        .replaceAll('{DRAINS_LAID_WITH}', _toWords(materials).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherHandrails(Map<String, String> answers) {
    final area = _cleanLower(answers['actv_area']);
    if (area.isEmpty) return const [];
    final materials = _labelsFor(
      ['cb_timber', 'cb_bricks', 'cb_other_472'],
      answers,
      {
        'cb_timber': 'Timber',
        'cb_bricks': 'Steel',
        'cb_other_472': 'Other',
      },
    );
    _addOther(answers, 'cb_other_472', 'et_other_99', materials);
    if (materials.isEmpty) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_HANDRAILS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', area)
        .replaceAll('{HANDRAILS_TYPE}', _toWords(materials).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherOverloaded(Map<String, String> answers) {
    if (!_isChecked(answers['is_overloaded_structure'])) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_OVERLOADED}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OTHER_EXTERNAL_AREA}', 'external area');
    return _split(_normalize(template));
  }

  List<String> _otherNoSafetyGlass(Map<String, String> answers) {
    if (!_isChecked(answers['is_overloaded_structure'])) return const [];
    final area = _cleanLower(answers['actv_condition']);
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_NO_SAFETY_GLASS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OTHER_EXTERNAL_AREA}', area.isEmpty ? 'external area' : area);
    return _split(_normalize(template));
  }

  List<String> _otherCondition(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_weather_condition']);
    if (condition.isEmpty) return const [];
    var template = _sub('{OTHER_EXTERNAL_AREA}', '{OTHER_CONDITION}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OTHER_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _otherRepairWall(Map<String, String> answers) {
    final area = _cleanLower(answers['actv_location']);
    final defects = _labelsFor(
      ['cb_cracked', 'cb_damaged', 'cb_eroded', 'cb_other_1046'],
      answers,
      {
        'cb_cracked': 'Cracked',
        'cb_damaged': 'Damaged',
        'cb_eroded': 'Eroded',
        'cb_other_1046': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1046', 'et_other_402', defects);
    if (area.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_WALL}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', area)
        .replaceAll('{WALL_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRepairRoof(Map<String, String> answers) {
    final defects = _labelsFor(
      [
        'cb_has_missing_tiles',
        'cb_has_slipped_tiles',
        'cb_is_in_disrepair',
        'cb_is_leaking',
        'cb_is_dilapidated',
        'cb_has_damaged_flashing',
        'cb_is_poorly_secured',
      ],
      answers,
      {
        'cb_has_missing_tiles': 'Missing tiles',
        'cb_has_slipped_tiles': 'Slipped tiles',
        'cb_is_in_disrepair': 'In disrepair',
        'cb_is_leaking': 'Leaking',
        'cb_is_dilapidated': 'Dilapidated',
        'cb_has_damaged_flashing': 'Damaged flashing',
        'cb_is_poorly_secured': 'Poorly secured',
      },
    );
    if (defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_ROOF}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', 'external area')
        .replaceAll('{OTHER_REPAIR_ROOF_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRepairFloor(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_split', 'cb_cracked', 'cb_other_642'],
      answers,
      {
        'cb_split': 'Split',
        'cb_cracked': 'Cracked',
        'cb_other_642': 'Other',
      },
    );
    _addOther(answers, 'cb_other_642', 'et_other_442', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_FLOOR}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', 'external area')
        .replaceAll('{FLOOR_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRepairDrains(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_split', 'cb_cracked', 'cb_other_642'],
      answers,
      {
        'cb_split': 'Too small',
        'cb_cracked': 'Blocked',
        'cb_other_642': 'Poorly drained',
      },
    );
    if (defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_DRAINS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', 'external area')
        .replaceAll('{DRAINS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRepairHandrails(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_not_strong_enough', 'cb_inadequately_designed', 'cb_partly_rotten_65', 'cb_not_strong_enough_51', 'cb_inadequately_designed_43'],
      answers,
      {
        'cb_not_strong_enough': 'Not strong enough',
        'cb_inadequately_designed': 'Inadequately designed',
        'cb_partly_rotten_65': 'Partly rotten',
        'cb_not_strong_enough_51': 'Not strong enough',
        'cb_inadequately_designed_43': 'Inadequately designed',
      },
    );
    if (defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_HANDRAILS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHER_EXTERNAL_AREA}', 'external area')
        .replaceAll('{HANDRAILS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRepairStepsLanding(Map<String, String> answers) {
    final location = _cleanLower(answers['actv_location']);
    final defects = _labelsFor(
      ['cb_cracked', 'cb_damaged', 'cb_eroded', 'cb_other_1046'],
      answers,
      {
        'cb_cracked': 'Split',
        'cb_damaged': 'Cracked',
        'cb_eroded': 'Partly rotted',
        'cb_other_1046': 'Rusted',
      },
    );
    if (location.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_STEPS_LANDING}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{STEPS_LANDING}', location)
        .replaceAll('{STEPS_LANDING_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _otherRepairDecorations(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_stairway', 'cb_fire_escape', 'cb_other_344'],
      answers,
      {
        'cb_stairway': 'Stairway',
        'cb_fire_escape': 'Fire escape',
        'cb_other_344': 'Other',
      },
    );
    _addOther(answers, 'cb_other_344', 'et_other_639', locations);
    final defects = _labelsFor(
      ['cb_perished', 'cb_flaking', 'cb_other_344'],
      answers,
      {
        'cb_perished': 'Perished',
        'cb_flaking': 'Flaking',
        'cb_other_344': 'Other',
      },
    );
    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{OTHER_REPAIR}', '{OTHER_REPAIR_PERISHED_DECORATIONS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{PERISHED_DECORATIONS_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{PERISHED_DECORATIONS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _mainWallsAbout(String screenId, Map<String, String> answers) {
    final wallTypes = <String>[];
    if (_isChecked(answers['cb_solid_bounded_brick_wall'])) wallTypes.add('solid brick wall');
    if (_isChecked(answers['cb_cavity_brick_wall'])) wallTypes.add('cavity brick wall');
    if (_isChecked(answers['cb_cavity_block_wall'])) wallTypes.add('cavity block wall');
    if (_isChecked(answers['cb_cavity_stud_wall'])) wallTypes.add('cavity stud wall');
    if (_isChecked(answers['cb_other_394'])) {
      final otherWall = _firstNonEmpty(answers, ['other', 'et_other_124', 'et_other_133', 'et_other_444']);
      wallTypes.add(otherWall.isEmpty ? 'other wall' : otherWall.toLowerCase());
    }

    if (wallTypes.isEmpty) {
      if (screenId.contains('__cavity_brick_wall')) {
        wallTypes.add('cavity brick wall');
      } else if (screenId.contains('__cavity_block_wall')) {
        wallTypes.add('cavity block wall');
      } else if (screenId.contains('__cavity_stud_wall')) {
        wallTypes.add('cavity stud wall');
      } else if (screenId.contains('__other')) {
        final otherWall = _firstNonEmpty(answers, ['other', 'et_other_124', 'et_other_133', 'et_other_444']);
        wallTypes.add(otherWall.isEmpty ? 'other wall' : otherWall.toLowerCase());
      } else {
        wallTypes.add('solid brick wall');
      }
    }

    final locations = _labelsFor(
      ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_other_832'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_other_832': 'Other',
      },
    );
    if (_isChecked(answers['cb_other_832'])) {
      final otherLocation = _firstNonEmpty(answers, ['et_other_133', 'et_other_124', 'et_other_444', 'other']);
      locations.add(otherLocation.isEmpty ? 'Other' : otherLocation);
    }

    final thickness = (answers['et_thickness'] ?? '').trim();
    final finishes = _labelsFor(
      ['cb_painted', 'cb_pebble_dash', 'cb_mock_tudor', 'cb_other_327'],
      answers,
      {
        'cb_painted': 'Painted',
        'cb_pebble_dash': 'Pebble dash',
        'cb_mock_tudor': 'Mock Tudor wall',
        'cb_other_327': 'Other',
      },
    );
    if (_isChecked(answers['cb_other_327'])) {
      final otherFinish = _firstNonEmpty(answers, ['et_other_444', 'et_other_124', 'et_other_133']);
      finishes.add(otherFinish.isEmpty ? 'Other' : otherFinish);
    }

    final finishesAmount = _cleanLower(answers['actv_finishes']);
    final rendered = _cleanLower(answers['actv_rendered']);
    final condition = _cleanLower(answers['actv_condition']);

    final wallPhraseBase = _sub('{E_MAIN_WALLS}', '{WALL}');
    final finishesPhraseBase = _sub('{E_MAIN_WALLS}', '{FINISHES}');
    final weatheredPhrase = _isChecked(answers['cb_is_weathered'])
        ? _sub('{E_MAIN_WALLS}', '{WEATHERED_WALL}')
        : '';
    final conditionPhraseBase = _sub('{E_MAIN_WALLS}', '{WALL_CONDITION}');

    final phrases = <String>[];
    for (final wallType in wallTypes) {
      var wallText = '';
      if (wallPhraseBase.isNotEmpty && locations.isNotEmpty && thickness.isNotEmpty) {
        wallText = wallPhraseBase
            .replaceAll('{WALL_LOCATION}', _toWords(locations).toLowerCase())
            .replaceAll('{WALL_THICKNESS}', thickness)
            .replaceAll('{WALL}', wallType);
      }

      var finishText = '';
      if (finishesPhraseBase.isNotEmpty && finishes.isNotEmpty && finishesAmount.isNotEmpty && rendered.isNotEmpty) {
        finishText = finishesPhraseBase
            .replaceAll('{WALL_FINISHES}', finishesAmount)
            .replaceAll('{WALL_RENDERED}', rendered)
            .replaceAll('{WALL_FINISHES_TYPE}', _toWords(finishes).toLowerCase());
      }

      var conditionText = '';
      if (conditionPhraseBase.isNotEmpty && condition.isNotEmpty) {
        conditionText = conditionPhraseBase.replaceAll('{CONDITION}', condition);
      }

      final typeCode = _mainWallTypeCode(wallType);
      var base = _sub('{E_MAIN_WALLS}', typeCode);
      if (base.isEmpty) continue;
      base = base
          .replaceAll('{WALL}', wallText)
          .replaceAll('{FINISHES}', finishText)
          .replaceAll('{WEATHERED_WALL}', weatheredPhrase)
          .replaceAll('{WALL_CONDITION}', conditionText);
      final resolved = _split(_normalize(base));
      phrases.addAll(resolved);
    }

    return phrases;
  }

  List<String> _mainWallsCladding(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_cladding']);
    final materials = _labelsFor(
      [
        'cb_clay_tiles',
        'cb_timber',
        'cb_weathered_boards',
        'cb_profile_sheets',
        'cb_shingle_plates',
        'cb_compressed_flat_panels',
        'cb_insulated_cladding',
        'cb_other_927',
      ],
      answers,
      {
        'cb_clay_tiles': 'Clay tiles',
        'cb_timber': 'Timber',
        'cb_weathered_boards': 'Weathered boards',
        'cb_profile_sheets': 'Profile sheets',
        'cb_shingle_plates': 'Shingle plates',
        'cb_compressed_flat_panels': 'Compressed flat panels',
        'cb_insulated_cladding': 'Insulated cladding',
        'cb_other_927': 'Other',
      },
    );
    _addOther(answers, 'cb_other_927', 'et_other_709', materials);

    final phrases = <String>[];
    if (type.isNotEmpty && materials.isNotEmpty) {
      var template = _sub('{E_MAIN_WALLS}', '{WALLS_CLADDING}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{MAIN_WALL_CLADDING_TYPE}', type)
            .replaceAll('{MAIN_WALL_CLADDING_CLADDED_WITH}', _toWords(materials).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub('{E_MAIN_WALLS}', '{WALLS_CONDITION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{MAIN_WALL_CLADDING_CONDITION}', condition);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _mainWallsDpc(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];

    if (status.contains('visible')) {
      final materials = _labelsFor(
        ['cb_plastic', 'cb_felt', 'cb_slates', 'cb_engineering_bricks', 'cb_other_259'],
        answers,
        {
          'cb_plastic': 'Plastic',
          'cb_felt': 'Felt',
          'cb_slates': 'Slates',
          'cb_engineering_bricks': 'Engineering bricks',
          'cb_other_259': 'Other',
        },
      );
      _addOther(answers, 'cb_other_259', 'et_other_105', materials);
      if (materials.isEmpty) return const [];
      var template = _sub('{E_MAIN_WALLS}', '{WALLS_DPC_VISIBLE}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{MAIN_WALL_DPC_CONSIST}', _toWords(materials).toLowerCase());
      return _split(_normalize(template));
    }

    final reasons = _cleanLower(answers['actv_not_visible_because_of']);
    final materials = _labelsFor(
      ['cb_plastic_89', 'cb_felt_73', 'cb_slates_45', 'cb_engineering_bricks_41', 'cb_other_312'],
      answers,
      {
        'cb_plastic_89': 'Plastic',
        'cb_felt_73': 'Felt',
        'cb_slates_45': 'Slates',
        'cb_engineering_bricks_41': 'Engineering bricks',
        'cb_other_312': 'Other',
      },
    );
    _addOther(answers, 'cb_other_312', 'et_other_637', materials);
    if (reasons.isEmpty || materials.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALLS}', '{WALLS_DPC_NOT_VISIBLE}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{MAIN_WALL_DPC_BECAUSE_OF}', reasons)
        .replaceAll('{MAIN_WALL_DPC_CONSIST}', _toWords(materials).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _mainWallsDamp(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('none')) {
      return _split(_normalize(_sub('{E_MAIN_WALLS}', '{WALLS_DAMP_TYPE_NONE}')));
    }

    var template = _sub('{E_MAIN_WALLS}', '{WALLS_DAMP_TYPE_PRESENT}');
    if (template.isEmpty) return const [];

    final areaLocation = (answers['et_location_677'] ?? '').trim();
    final areaPhrase = areaLocation.isNotEmpty
        ? _sub('{WALLS_DAMP_TYPE_PRESENT}', '{WALLS_DAMP_TYPE_PRESENT_AREA}')
            .replaceAll('{MAIN_WALL_DAMP_LOCATION}', areaLocation.toLowerCase())
        : '';

    String penetratingPhrase = '';
    if (_isChecked(answers['cb_penetrating_damp'])) {
      final causes = _labelsFor(
        [
          'cb_overflowing_gutter',
          'cb_roof_leak',
          'cb_leaking_downpipe',
          'cb_bridged_dpc',
          'cb_blocked_gully',
          'cb_other_380',
        ],
        answers,
        {
          'cb_overflowing_gutter': 'Overflowing gutter',
          'cb_roof_leak': 'Roof leak',
          'cb_leaking_downpipe': 'Leaking down pipe',
          'cb_bridged_dpc': 'Bridged DPC',
          'cb_blocked_gully': 'Blocked gully',
          'cb_other_380': 'Other',
        },
      );
      _addOther(answers, 'cb_other_380', 'et_other_184', causes);
      if (causes.isNotEmpty) {
        penetratingPhrase = _sub('{WALLS_DAMP_TYPE_PRESENT}', '{WALLS_DAMP_TYPE_PRESENT_PENETRATING}')
            .replaceAll('{MAIN_WALL_PENETRATING_DAMP_CAUSED_BY}', _toWords(causes).toLowerCase());
      }
    }

    String risingPhrase = '';
    if (_isChecked(answers['cb_rising_damp'])) {
      final causes = _labelsFor(
        [
          'cb_damaged_dpc',
          'cb_old_and_brittle_dpc',
          'cb_bridged_dpcSecond',
          'cb_defective_drainage',
          'cb_other_1030',
        ],
        answers,
        {
          'cb_damaged_dpc': 'Damaged DPC',
          'cb_old_and_brittle_dpc': 'Old and brittle DPC',
          'cb_bridged_dpcSecond': 'Bridged DPC',
          'cb_defective_drainage': 'Defective drainage',
          'cb_other_1030': 'Other',
        },
      );
      _addOther(answers, 'cb_other_1030', 'et_other_722', causes);
      if (causes.isNotEmpty) {
        risingPhrase = _sub('{WALLS_DAMP_TYPE_PRESENT}', '{WALLS_DAMP_TYPE_PRESENT_RISING}')
            .replaceAll('{MAIN_WALL_RISING_DAMP_CAUSED_BY}', _toWords(causes).toLowerCase());
      }
    }

    final installGutters = _isChecked(answers['cb_install_french_gutters'])
        ? _sub('{WALLS_DAMP_TYPE_PRESENT}', '{WALLS_DAMP_TYPE_PRESENT_INSTALL_FRENCH_GUTTERS}')
        : '';
    final unknownCause = _isChecked(answers['cb_unknown_cause'])
        ? _sub('{WALLS_DAMP_TYPE_PRESENT}', '{WALLS_DAMP_TYPE_PRESENT_UNKNOWN_CAUSE}')
        : '';
    final dpcTreatment = _isChecked(answers['cb_dpc_treatment_noted'])
        ? _sub('{WALLS_DAMP_TYPE_PRESENT}', '{WALLS_DAMP_TYPE_PRESENT_DPC_TREATMENT_NOTED}')
        : '';

    template = template
        .replaceAll('{WALLS_DAMP_TYPE_PRESENT_AREA}', areaPhrase)
        .replaceAll('{WALLS_DAMP_TYPE_PRESENT_PENETRATING}', penetratingPhrase)
        .replaceAll('{WALLS_DAMP_TYPE_PRESENT_RISING}', risingPhrase)
        .replaceAll('{WALLS_DAMP_TYPE_PRESENT_INSTALL_FRENCH_GUTTERS}', installGutters)
        .replaceAll('{WALLS_DAMP_TYPE_PRESENT_UNKNOWN_CAUSE}', unknownCause)
        .replaceAll('{WALLS_DAMP_TYPE_PRESENT_DPC_TREATMENT_NOTED}', dpcTreatment);

    return _split(_normalize(template));
  }

  List<String> _mainWallsRemovedWall(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_lounge', 'cb_kitchen', 'cb_bedroom', 'cb_other_1020'],
      answers,
      {
        'cb_lounge': 'Lounge',
        'cb_kitchen': 'Kitchen',
        'cb_bedroom': 'Bedroom',
        'cb_other_1020': 'Other',
      },
    );
    if (_isChecked(answers['cb_other_1020'])) {
      final otherLocation = _firstNonEmpty(answers, ['et_other_491', 'et_other_522', 'EtDescribeDefect']);
      locations.add(otherLocation.isEmpty ? 'Other' : otherLocation);
    }
    if (locations.isEmpty) return const [];
    final locationText = _toWords(locations).toLowerCase();

    if (_isChecked(answers['cb_defects_noted'])) {
      final defects = _labelsFor(
        ['cb_distorted', 'cb_cracked', 'cb_poorly_supported', 'cb_other_518'],
        answers,
        {
          'cb_distorted': 'Distorted',
          'cb_cracked': 'Cracked',
          'cb_poorly_supported': 'Poorly supported walls',
          'cb_other_518': 'Other',
        },
      );
      _addOther(answers, 'cb_other_518', 'et_other_522', defects);
      final describe = (answers['EtDescribeDefect'] ?? '').trim();
      if (describe.isNotEmpty) defects.add(describe);
      if (defects.isEmpty) return const [];
      var template = _sub('{E_MAIN_WALLS}', '{WALLLS_REMOVED_WALL_DEFECTS}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{MAIN_WALL_REMOVED_LOCATION}', locationText)
          .replaceAll('{MAIN_WALL_REMOVED_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    var template = _sub('{E_MAIN_WALLS}', '{REMOVED_WALL_LOCATION}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{MAIN_WALL_REMOVED_LOCATION}', locationText);
    return _split(_normalize(template));
  }

  List<String> _mainWallsMovements(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_movement_status']);
    if (status.isEmpty) return const [];

    if (status.contains('none')) {
      return _split(_normalize(_sub('{MAIN_WALL_MOVEMENTS_TYPE}', '{MAIN_WALL_MOVEMENTS_TYPE_NONE}')));
    }
    if (status.contains('usual')) {
      return _split(_normalize(_sub('{MAIN_WALL_MOVEMENTS_TYPE}', '{MAIN_WALL_MOVEMENTS_TYPE_USUAL}')));
    }
    if (status.contains('all')) {
      return _split(_normalize(_sub('{MAIN_WALL_MOVEMENTS_TYPE}', '{MAIN_WALL_MOVEMENTS_TYPE_ALL_ELEVATIONS}')));
    }
    if (status.contains('investigate')) {
      return _split(_normalize(_sub('{MAIN_WALL_MOVEMENTS_TYPE}', '{MAIN_WALL_MOVEMENTS_TYPE_INVESTIGATE}')));
    }

    if (status.contains('recent')) {
      final walls = _labelsFor(
        ['cb_front', 'cb_side', 'cb_rear'],
        answers,
        {
          'cb_front': 'Front',
          'cb_side': 'Side',
          'cb_rear': 'Rear',
        },
      );
      final locations = _labelsFor(
        ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_501'],
        answers,
        {
          'cb_main_building': 'Main building',
          'cb_back_addition': 'Back addition',
          'cb_extension': 'Extension',
          'cb_bay_window': 'Bay window',
          'cb_other_501': 'Other',
        },
      );
      _addOther(answers, 'cb_other_501', 'et_other_406', locations);
      final causes = _labelsFor(
        ['cb_settlement', 'cb_subsidence', 'cb_point_loading', 'cb_wall_tie_rust', 'cb_other_682'],
        answers,
        {
          'cb_settlement': 'Settlement',
          'cb_subsidence': 'Subsidence',
          'cb_point_loading': 'Point loading',
          'cb_wall_tie_rust': 'Wall tie rust',
          'cb_other_682': 'Other',
        },
      );
      _addOther(answers, 'cb_other_682', 'et_other_884', causes);
      if (walls.isEmpty || locations.isEmpty || causes.isEmpty) return const [];
      var template = _sub('{MAIN_WALL_MOVEMENTS_TYPE}', '{MAIN_WALL_MOVEMENTS_TYPE_RECENT}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{MAIN_WALL_MOVEMENTS_WALL}', _toWords(walls).toLowerCase())
          .replaceAll('{MAIN_WALL_MOVEMENTS_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{MAIN_WALL_MOVEMENTS_CRACKS}', _toWords(causes).toLowerCase());
      return _split(_normalize(template));
    }

    if (status.contains('recurrent')) {
      final walls = _labelsFor(
        ['cb_front_48', 'cb_side_46', 'cb_rear_89'],
        answers,
        {
          'cb_front_48': 'Front',
          'cb_side_46': 'Side',
          'cb_rear_89': 'Rear',
        },
      );
      final locations = _labelsFor(
        ['cb_main_building_92', 'cb_back_addition_19', 'cb_extension_45', 'cb_bay_window_35', 'cb_other_694'],
        answers,
        {
          'cb_main_building_92': 'Main building',
          'cb_back_addition_19': 'Back addition',
          'cb_extension_45': 'Extension',
          'cb_bay_window_35': 'Bay window',
          'cb_other_694': 'Other',
        },
      );
      _addOther(answers, 'cb_other_694', 'et_other_425', locations);
      if (walls.isEmpty || locations.isEmpty) return const [];
      var template = _sub('{MAIN_WALL_MOVEMENTS_TYPE}', '{MAIN_WALL_MOVEMENTS_TYPE_RECURRENT}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{MAIN_WALL_MOVEMENTS_WALL}', _toWords(walls).toLowerCase())
          .replaceAll('{MAIN_WALL_MOVEMENTS_LOCATION}', _toWords(locations).toLowerCase());
      return _split(_normalize(template));
    }

    return const [];
  }

  List<String> _mainWallRepairThinSlim(Map<String, String> answers) {
    final walls = _labelsFor(
      ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_608': 'Other',
      },
    );
    _addOther(answers, 'cb_other_608', 'et_other_752', walls);
    final locations = _labelsFor(
      ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_423'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_other_423': 'Other',
      },
    );
    _addOther(answers, 'cb_other_423', 'et_other_883', locations);
    if (walls.isEmpty || locations.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_THIN_SLIM_WALL}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{MAIN_WALL_REPAIR_THIN_SLIM_WALL_WALLS}', _toWords(walls).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_THIN_SLIM_WALL_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairCavityInsulation(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_REPAIR_CAVITY_WALL_INSULATION}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairNearbyTrees(Map<String, String> answers) {
    final sizes = _labelsFor(
      ['cb_small', 'cb_medium', 'cb_medium_to_large'],
      answers,
      {
        'cb_small': 'small',
        'cb_medium': 'medium',
        'cb_medium_to_large': 'medium to large',
      },
    );
    if (sizes.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_REPAIR_NEARBY_TREES}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{MAIN_WALL_REPAIR_NEAR_BY_TREES_SIZE}', _toWords(sizes));
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairSpalling(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final isNow = condition.contains('now') || _isChecked(answers['cb_causing_damp']);

    final walls = _labelsFor(
      isNow ? ['cb_front_64', 'cb_side_38', 'cb_rear_36'] : ['cb_front', 'cb_side', 'cb_rear'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_front_64': 'Front',
        'cb_side_38': 'Side',
        'cb_rear_36': 'Rear',
      },
    );
    final locations = _labelsFor(
      isNow
          ? ['cb_main_building_47', 'cb_back_addition_21', 'cb_extension_36', 'cb_bay_window_50', 'cb_other_299']
          : ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_344'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_other_344': 'Other',
        'cb_main_building_47': 'Main building',
        'cb_back_addition_21': 'Back addition',
        'cb_extension_36': 'Extension',
        'cb_bay_window_50': 'Bay window',
        'cb_other_299': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_299', 'et_other_455', locations);
    } else {
      _addOther(answers, 'cb_other_344', 'et_other_651', locations);
    }

    if (walls.isEmpty || locations.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_SPALLING_REPAIR_WALLS}');
    if (template.isEmpty) return const [];
    final repair = _sub('{WALL_SPALLING_REPAIR_WALLS}', isNow ? '{WALL_SPALLING_REPAIR_NOW}' : '{WALL_SPALLING_REPAIR_SOON}');
    template = template
        .replaceAll('{MAIN_WALL_REPAIR_SPALLING_WALLS}', _toWords(walls).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_SPALLING_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{REPAIR_SOON_NOW}', repair);
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairRender(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final isNow = condition.contains('now') || _isChecked(answers['cb_causing_damp']);

    final walls = _labelsFor(
      isNow ? ['cb_front_62', 'cb_side_16', 'cb_rear_56'] : ['cb_front', 'cb_side', 'cb_rear'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_front_62': 'Front',
        'cb_side_16': 'Side',
        'cb_rear_56': 'Rear',
      },
    );
    final locations = _labelsFor(
      isNow
          ? ['cb_main_building_87', 'cb_back_addition_36', 'cb_extension_15', 'cb_bay_window_24', 'cb_other_632']
          : ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_312'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_other_312': 'Other',
        'cb_main_building_87': 'Main building',
        'cb_back_addition_36': 'Back addition',
        'cb_extension_15': 'Extension',
        'cb_bay_window_24': 'Bay window',
        'cb_other_632': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_632', 'et_other_430', locations);
    } else {
      _addOther(answers, 'cb_other_312', 'et_other_575', locations);
    }

    final defects = _labelsFor(
      isNow
          ? ['cb_cracked_101', 'cb_loose_28', 'cb_missing_in_places_44', 'cb_other_415']
          : ['cb_cracked_96', 'cb_loose_91', 'cb_missing_in_places_63', 'cb_other_868'],
      answers,
      {
        'cb_cracked_96': 'Cracked',
        'cb_loose_91': 'Loose',
        'cb_missing_in_places_63': 'Missing in places',
        'cb_other_868': 'Other',
        'cb_cracked_101': 'Cracked',
        'cb_loose_28': 'Loose',
        'cb_missing_in_places_44': 'Missing in places',
        'cb_other_415': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_415', 'et_other_264', defects);
    } else {
      _addOther(answers, 'cb_other_868', 'et_other_857', defects);
    }

    if (walls.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_RENDER_REPAIR_WALLS}');
    if (template.isEmpty) return const [];
    final repair = _sub('{WALL_RENDER_REPAIR_WALLS}', isNow ? '{WALL_RENDER_REPAIR_NOW}' : '{WALL_RENDER_REPAIR_SOON}');
    template = template
        .replaceAll('{MAIN_WALL_REPAIR_RENDER_WALLS}', _toWords(walls).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_RENDER_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_RENDER_DEFECTS}', _toWords(defects).toLowerCase())
        .replaceAll('{REPAIR_SOON_NOW}', repair);

    final phrases = _split(_normalize(template)).toList();
    if (isNow && _isChecked(answers['cb_hazard'])) {
      final hazard = _sub('{WALL_RENDER_REPAIR_NOW}', '{WALL_RENDER_REPAIR_NOW_HAZARD}');
      if (hazard.isNotEmpty) {
        phrases.addAll(_split(_normalize(hazard)));
      }
    }
    return phrases;
  }

  List<String> _mainWallRepairPointing(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final isNow = condition.contains('now');

    final walls = _labelsFor(
      isNow ? ['cb_front_27', 'cb_side_17', 'cb_rear_30'] : ['cb_front', 'cb_side', 'cb_rear'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_front_27': 'Front',
        'cb_side_17': 'Side',
        'cb_rear_30': 'Rear',
      },
    );
    final locations = _labelsFor(
      isNow
          ? ['cb_main_building_67', 'cb_back_addition_32', 'cb_extension_63', 'cb_bay_window_86', 'cb_other_318']
          : ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_423'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_other_423': 'Other',
        'cb_main_building_67': 'Main building',
        'cb_back_addition_32': 'Back addition',
        'cb_extension_63': 'Extension',
        'cb_bay_window_86': 'Bay window',
        'cb_other_318': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_318', 'et_other_806', locations);
    } else {
      _addOther(answers, 'cb_other_423', 'et_other_883', locations);
    }

    final defects = _labelsFor(
      isNow ? ['cb_eroded_49', 'cb_loosened_83', 'cb_other_now'] : ['cb_eroded', 'cb_loosened', 'cb_other_soon'],
      answers,
      {
        'cb_eroded': 'Eroded',
        'cb_loosened': 'Loosened',
        'cb_other_soon': 'Other',
        'cb_eroded_49': 'Eroded',
        'cb_loosened_83': 'Loosened',
        'cb_other_now': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_now', 'et_other_now', defects);
    } else {
      _addOther(answers, 'cb_other_soon', 'et_other_soon', defects);
    }

    if (walls.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_POINTING_REPAIR_LOCATION}');
    if (template.isEmpty) return const [];
    final repair = _sub('{WALL_POINTING_REPAIR_LOCATION}', isNow ? '{WALL_POINTING_REPAIR_NOW}' : '{WALL_POINTING_REPAIR_SOON}');
    template = template
        .replaceAll('{MAIN_WALL_REPAIR_POINTING_WALLS}', _toWords(walls).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_POINTING_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_POINTING_DEFECT}', _toWords(defects).toLowerCase())
        .replaceAll('{REPAIR_SOON_NOW}', repair);
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairLintel(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final isNow = condition.contains('now');

    final walls = _labelsFor(
      isNow ? ['cb_front_27', 'cb_side_17', 'cb_rear_30', 'cb_other_6082'] : ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_608': 'Other',
        'cb_front_27': 'Front',
        'cb_side_17': 'Side',
        'cb_rear_30': 'Rear',
        'cb_other_6082': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_6082', 'et_other_7522', walls);
    } else {
      _addOther(answers, 'cb_other_608', 'et_other_752', walls);
    }

    final locations = _labelsFor(
      isNow
          ? ['cb_main_building_67', 'cb_back_addition_32', 'cb_extension_63', 'cb_bay_window_86', 'cb_other_318']
          : ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_423'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_other_423': 'Other',
        'cb_main_building_67': 'Main building',
        'cb_back_addition_32': 'Back addition',
        'cb_extension_63': 'Extension',
        'cb_bay_window_86': 'Bay window',
        'cb_other_318': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_318', 'et_other_806', locations);
    } else {
      _addOther(answers, 'cb_other_423', 'et_other_883', locations);
    }

    final defects = _labelsFor(
      isNow
          ? ['cb_eroded_49', 'cb_loosened_83', 'cb_distorted_now', 'cb_bulging_now', 'cb_other_6083']
          : ['cb_eroded', 'cb_loosened', 'cb_distorted', 'cb_bulging', 'cb_other_6081'],
      answers,
      {
        'cb_eroded': 'Damaged',
        'cb_loosened': 'Cracked',
        'cb_distorted': 'Distorted',
        'cb_bulging': 'Bulging',
        'cb_other_6081': 'Other',
        'cb_eroded_49': 'Badly damaged',
        'cb_loosened_83': 'Badly cracked',
        'cb_distorted_now': 'Very distorted',
        'cb_bulging_now': 'Allowing dampness',
        'cb_other_6083': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_6083', 'et_other_7523', defects);
    } else {
      _addOther(answers, 'cb_other_6081', 'et_other_7521', defects);
    }

    final opening = _cleanLower(answers[isNow ? 'actv_condition_opening_now' : 'actv_condition_opening_soon']);
    if (walls.isEmpty || locations.isEmpty || defects.isEmpty || opening.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_LINTEL_REPAIR}');
    if (template.isEmpty) return const [];
    final repair = _sub('{WALL_LINTEL_REPAIR}', isNow ? '{WALL_LINTEL_REPAIR_NOW}' : '{WALL_LINTEL_REPAIR_SOON}');
    template = template
        .replaceAll('{MAIN_WALL_REPAIR_LINTEL_OPENING_TO}', opening)
        .replaceAll('{MAIN_WALL_REPAIR_LINTEL_WALLS}', _toWords(walls).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_LINTEL_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{MAIN_WALL_REPAIR_LINTEL_DEFECT}', _toWords(defects).toLowerCase())
        .replaceAll('{REPAIR_SOON_NOW}', repair);
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairWindowSills(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final isNow = condition.contains('now');

    final walls = _labelsFor(
      isNow ? ['cb_front_27', 'cb_side_17', 'cb_rear_30', 'cb_other_6082'] : ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_608': 'Other',
        'cb_front_27': 'Front',
        'cb_side_17': 'Side',
        'cb_rear_30': 'Rear',
        'cb_other_6082': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_6082', 'et_other_7522', walls);
    } else {
      _addOther(answers, 'cb_other_608', 'et_other_752', walls);
    }

    final locations = _labelsFor(
      isNow
          ? ['cb_main_building_67', 'cb_back_addition_32', 'cb_extension_63', 'cb_bay_window_86', 'cb_other_318']
          : ['cb_main_building', 'cb_back_addition', 'cb_extension', 'cb_bay_window', 'cb_other_423'],
      answers,
      {
        'cb_main_building': 'Main building',
        'cb_back_addition': 'Back addition',
        'cb_extension': 'Extension',
        'cb_bay_window': 'Bay window',
        'cb_other_423': 'Other',
        'cb_main_building_67': 'Main building',
        'cb_back_addition_32': 'Back addition',
        'cb_extension_63': 'Extension',
        'cb_bay_window_86': 'Bay window',
        'cb_other_318': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_318', 'et_other_806', locations);
    } else {
      _addOther(answers, 'cb_other_423', 'et_other_883', locations);
    }

    final defects = _labelsFor(
      isNow
          ? ['cb_eroded_49', 'cb_loosened_83', 'cb_very_distorted_now', 'cb_allowing_dampness_now', 'cb_other_6083']
          : ['cb_loosened', 'cb_cracked_soon', 'cb_eroded', 'cb_other_6081'],
      answers,
      {
        'cb_loosened': 'Damaged',
        'cb_cracked_soon': 'Cracked',
        'cb_eroded': 'Eroded',
        'cb_other_6081': 'Other',
        'cb_eroded_49': 'Damaged',
        'cb_loosened_83': 'Unstable',
        'cb_very_distorted_now': 'Very distorted',
        'cb_allowing_dampness_now': 'Allowing dampness',
        'cb_other_6083': 'Other',
      },
    );
    if (isNow) {
      _addOther(answers, 'cb_other_6083', 'et_other_7523', defects);
    } else {
      _addOther(answers, 'cb_other_6081', 'et_other_7521', defects);
    }

    if (walls.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', isNow ? '{WALL_WINDOW_SILLS_REPAIR_NOW}' : '{WALL_WINDOW_SILLS_REPAIR_SOON}');
    if (template.isEmpty) return const [];
    if (isNow) {
      template = template
          .replaceAll('{MAIN_WALL_REPAIR_WINDOW_SILLS_WALLS_NOW}', _toWords(walls).toLowerCase())
          .replaceAll('{MAIN_WALL_REPAIR_WINDOW_SILLS_LOCATION_NOW}', _toWords(locations).toLowerCase())
          .replaceAll('{MAIN_WALL_REPAIR_WINDOW_SILLS_DEFECT_NOW}', _toWords(defects).toLowerCase());
    } else {
      template = template
          .replaceAll('{MAIN_WALL_REPAIR_WINDOW_SILLS_WALLS_SOON}', _toWords(walls).toLowerCase())
          .replaceAll('{MAIN_WALL_REPAIR_WINDOW_SILLS_LOCATION_SOON}', _toWords(locations).toLowerCase())
          .replaceAll('{MAIN_WALL_REPAIR_WINDOW_SILLS_DEFECT_SOON}', _toWords(defects).toLowerCase());
    }
    return _split(_normalize(template));
  }

  List<String> _groundsLimitations(Map<String, String> answers) {
    final noRestrictions = _isChecked(answers['cb_no_restrictions']);
    final noRearAccess = _isChecked(answers['cb_no_rear_access']);
    if (!noRestrictions && !noRearAccess) return const [];
    var template = _sub('{H_GROUNDS}', '{H_LIMITATIONS_STANDARD_TEXT}');
    if (template.isEmpty) return const [];
    final restrictionsText =
        noRestrictions ? _sub('{H_GROUNDS}', '{LIMITATIONS_NO_RESTRICTIONS}') : '';
    final rearText = noRearAccess ? _sub('{H_GROUNDS}', '{LIMITATIONS_NO_REAR_ACCESS}') : '';
    template = template
        .replaceAll('{LIMITATIONS_NO_RESTRICTIONS}', restrictionsText)
        .replaceAll('{LIMITATIONS_NO_REAR_ACCESS}', rearText);
    return _split(_normalize(template));
  }

  List<String> _groundsGarage(Map<String, String> answers) {
    final phrases = <String>[];

    final garageNo = _cleanLower(answers['actv_no_of_garage']);
    final garageType = _cleanLower(answers['actv_type']);
    if (garageNo.isNotEmpty && garageType.isNotEmpty) {
      var template = _sub('{H_GARAGE}', '{ABOUT_GARAGE_TYPE}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAR_NO_OF_GAR}', garageNo).replaceAll('{GAR_TYPE}', garageType);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final walls = _labelsFor(
      [
        'cb_cavity_brick_wall',
        'cb_block_work',
        'cb_precast_concrete_wall',
        'cb_timber_frame_wall',
        'cb_single_skin_brickwork',
        'cb_other_594',
      ],
      answers,
      {
        'cb_cavity_brick_wall': 'Cavity brick wall',
        'cb_block_work': 'Block work',
        'cb_precast_concrete_wall': 'Precast concrete wall',
        'cb_timber_frame_wall': 'Timber frame wall',
        'cb_single_skin_brickwork': 'Single skin brickwork',
        'cb_other_594': 'Other',
      },
    );
    _addOther(answers, 'cb_other_594', 'et_other_471', walls);
    if (walls.isNotEmpty) {
      var template = _sub('{H_GARAGE}', '{ABOUT_GARAGE_WALLS}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAR_WALL}', _toWords(walls).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final roofTypes = _labelsFor(
      ['cb_pitched', 'cb_flat', 'cb_other_390'],
      answers,
      {
        'cb_pitched': 'Pitched',
        'cb_flat': 'Flat',
        'cb_other_390': 'Other',
      },
    );
    _addOther(answers, 'cb_other_390', 'et_other_142', roofTypes);
    final roofCovers = _labelsFor(
      [
        'cb_the_floor_above',
        'cb_tiles',
        'cb_slates',
        'cb_mineral_felt',
        'cb_corrugated_asbestos_sheets',
        'cb_other_376',
      ],
      answers,
      {
        'cb_the_floor_above': 'The floor above',
        'cb_tiles': 'Tiles',
        'cb_slates': 'Slates',
        'cb_mineral_felt': 'Mineral felt',
        'cb_corrugated_asbestos_sheets': 'Corrugated asbestos sheets',
        'cb_other_376': 'Other',
      },
    );
    _addOther(answers, 'cb_other_376', 'et_other_634', roofCovers);
    final roofCond = _cleanLower(answers['actv_condition']);
    if (roofTypes.isNotEmpty && roofCovers.isNotEmpty && roofCond.isNotEmpty) {
      var template = _sub('{H_GARAGE}', '{ABOUT_GARAGE_ROOF}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{GAR_ROOF_TYPE}', _toWords(roofTypes).toLowerCase())
            .replaceAll('{GAR_ROOF_COVER}', _toWords(roofCovers).toLowerCase())
            .replaceAll('{GAR_ROOF_COVER_COND}', roofCond);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_single_skin_brickwork'])) {
      phrases.addAll(_split(_normalize(_sub('{H_GARAGE}', '{IF_SINGLE_BRICK_SKIN_IS_SELECTED}'))));
    }
    if (_isChecked(answers['cb_mineral_felt'])) {
      phrases.addAll(_split(_normalize(_sub('{H_GARAGE}', '{IF_MINERAL_FELT_IS_SELECTED}'))));
    }
    if (_isChecked(answers['cb_corrugated_asbestos_sheets'])) {
      phrases.addAll(_split(_normalize(_sub('{H_GARAGE}', '{IF_ASBESTOS_IS_SELECTED}'))));
    }

    final convertedTo = _cleanLower(answers['actv_converted_to']);
    if (convertedTo.isNotEmpty) {
      var template = _sub('{H_GARAGE}', '{ABOUT_GARAGE_CONVERTED}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAR_COND_CONV_TO}', convertedTo);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_shared_access'])) {
      phrases.addAll(_split(_normalize(_sub('{H_GARAGE}', '{ABOUT_GARAGE_SHARED_ACCESS}'))));
    }

    return phrases;
  }

  List<String> _groundsGarageNotInspected(Map<String, String> answers) {
    if (_isChecked(answers['cb_not_inspected_no_garage']) || _isChecked(answers['cb_not_inspected'])) {
      return _split(_normalize(_sub('{H_GARAGE}', '{NOT_INSPECTED}')));
    }
    return const [];
  }

  List<String> _groundsGarageRepair(Map<String, String> answers) {
    final phrases = <String>[];
    final soonDefects = _labelsFor(
      [
        'cb_roof_is_leaking',
        'cb_walls_are_cracked',
        'cb_window_frames_are_rotten',
        'cb_window_glazing_is_cracked',
        'cb_door_is_damaged',
        'cb_floor_is_cracked',
        'cb_other_785',
      ],
      answers,
      {
        'cb_roof_is_leaking': 'Roof is leaking',
        'cb_walls_are_cracked': 'Walls are cracked',
        'cb_window_frames_are_rotten': 'Window frames are rotten',
        'cb_window_glazing_is_cracked': 'Window glazing is cracked',
        'cb_door_is_damaged': 'Door is damaged',
        'cb_floor_is_cracked': 'Floor is cracked',
        'cb_other_785': 'Other',
      },
    );
    _addOther(answers, 'cb_other_785', 'et_other_703', soonDefects);
    if (soonDefects.isNotEmpty) {
      var template = _sub('{H_GARAGE}', '{REPAIR_GARAGE_REPAIR_SOON}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAR_REP_SOON_DEFECT}', _toWords(soonDefects).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final nowDefects = _labelsFor(
      [
        'cb_roof_is_badly_leaking',
        'cb_walls_are_badly_cracked',
        'cb_walls_are_unstable',
        'cb_window_glazing_is_smashed',
        'cb_floor_is_badly_cracked',
        'cb_doors_are_in_disrepair',
        'cb_other_528',
      ],
      answers,
      {
        'cb_roof_is_badly_leaking': 'Roof is badly leaking',
        'cb_walls_are_badly_cracked': 'Walls are badly cracked',
        'cb_walls_are_unstable': 'Walls are unstable',
        'cb_window_glazing_is_smashed': 'Window glazing is smashed',
        'cb_floor_is_badly_cracked': 'Floor is badly cracked',
        'cb_doors_are_in_disrepair': 'Doors are in disrepair',
        'cb_other_528': 'Other',
      },
    );
    _addOther(answers, 'cb_other_528', 'et_other_670', nowDefects);
    if (nowDefects.isNotEmpty) {
      var template = _sub('{H_GARAGE}', '{REPAIR_GARAGE_REPAIR_NOW}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{GAR_REP_NOW_DEFECT}', _toWords(nowDefects).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _groundsGarageRoofTimber(Map<String, String> answers) {
    final defects = _labelsFor(
      [
        'cb_is_rotten',
        'cb_has_beetles_infestation',
        'cb_is_broken',
        'cb_is_badly_cracked',
        'cb_is_badly_damaged',
        'cb_other_795',
      ],
      answers,
      {
        'cb_is_rotten': 'Is rotten',
        'cb_has_beetles_infestation': 'Has beetle infestation',
        'cb_is_broken': 'Is broken',
        'cb_is_badly_cracked': 'Is badly cracked',
        'cb_is_badly_damaged': 'Is badly damaged',
        'cb_other_795': 'Other',
      },
    );
    _addOther(answers, 'cb_other_795', 'et_other_756', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{H_GARAGE}', '{REPAIR_ROOF_TIMBER}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{GAR_REP_ROOF_TIMBER_DEF}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsGarageSafetyHazard(Map<String, String> answers) {
    if (!_isChecked(answers['cb_is_safety_hazard'])) return const [];
    return _split(_normalize(_sub('{H_GARAGE}', '{REPAIR_SAFETY_HAZARD}')));
  }

  List<String> _groundsOtherGrounds(Map<String, String> answers) {
    final groundType = _cleanLower(answers['actv_type']);
    if (groundType.isEmpty) return const [];
    var template = _sub('{H_OTHER}', '{OTHER_GROUNDS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OTH_GND_TYPE}', groundType);
    return _split(_normalize(template));
  }

  List<String> _groundsGarden(
    Map<String, String> answers, {
    required String gardenName,
    required bool isCommunal,
  }) {
    final gardenTypes = _labelsFor(
      [
        'cb_paved',
        'cb_part_paved',
        'cb_lawned',
        'cb_decked',
        'cb_artificial_lawned',
        'cb_laid_with_gravel',
        'cb_laid_with_tile_chippings',
        'cb_laid_with_stone_chippings',
        'cb_other_277',
      ],
      answers,
      {
        'cb_paved': 'Paved',
        'cb_part_paved': 'Part paved',
        'cb_lawned': 'Lawned',
        'cb_decked': 'Decked',
        'cb_artificial_lawned': 'Artificial lawned',
        'cb_laid_with_gravel': 'Laid with gravel',
        'cb_laid_with_tile_chippings': 'Laid with tile chippings',
        'cb_laid_with_stone_chippings': 'Laid with stone chippings',
        'cb_other_277': 'Other',
      },
    );
    _addOther(answers, 'cb_other_277', 'et_other_912', gardenTypes);

    String gardenTypePhrase = '';
    if (gardenTypes.isNotEmpty) {
      if (isCommunal) {
        gardenTypePhrase = _sub('{H_OTHER_GARDENS}', '{COMMUNAL_GARDEN_TYPE}')
            .replaceAll('{OTH_TYPE}', _toWords(gardenTypes).toLowerCase());
      } else {
        gardenTypePhrase = _sub('{H_OTHER_GARDENS}', '{GARDEN_TYPE}')
            .replaceAll('{GRADEN_NAME}', gardenName)
            .replaceAll('{OTH_TYPE}', _toWords(gardenTypes).toLowerCase());
      }
    }

    String fencingPhrase = '';
    if (_isChecked(answers['ch20'])) {
      fencingPhrase = _sub('{H_OTHER_GARDENS}', '{FENCING_NOT_AVAILABLE}').replaceAll('{GRADEN_NAME}', gardenName);
    } else {
      final fences = _labelsFor(
        [
          'cb_fence_formed_in_timber',
          'cb_fence_formed_in_brick_walls',
          'cb_fence_formed_in_concrete_sections',
          'cb_fence_formed_in_wire_mash',
          'cb_fence_formed_in_hedges',
          'cb_fence_formed_in_shrubs',
          'cb_fence_formed_in_other',
        ],
        answers,
        {
          'cb_fence_formed_in_timber': 'Timber',
          'cb_fence_formed_in_brick_walls': 'Brick walls',
          'cb_fence_formed_in_concrete_sections': 'Concrete sections',
          'cb_fence_formed_in_wire_mash': 'Wire mesh',
          'cb_fence_formed_in_hedges': 'Hedges',
          'cb_fence_formed_in_shrubs': 'Shrubs',
          'cb_fence_formed_in_other': 'Other',
        },
      );
      _addOther(answers, 'cb_fence_formed_in_other', 'et_other_912_fence_formed_in', fences);
      if (fences.isNotEmpty) {
        final condition = _cleanLower(answers['actv_fencing_condition']);
        final conditionPhrase = condition.isNotEmpty
            ? _sub('{H_OTHER_GARDENS}', '{FENCING_CONDITION}')
                .replaceAll('{OTH_FENCES_CON}', condition)
            : '';
        fencingPhrase = _sub('{H_OTHER_GARDENS}', '{FENCING_AVAILABLE}')
            .replaceAll('{GRADEN_NAME}', gardenName)
            .replaceAll('{OTH_FENCES}', _toWords(fences).toLowerCase())
            .replaceAll('{FENCING_CONDITION}', conditionPhrase);
      }
    }

    String pondPhrase = '';
    if (_isChecked(answers['cb_pond'])) {
      final cond = _cleanLower(answers['actv_pond_condition']);
      if (cond.isNotEmpty) {
        pondPhrase = _sub('{H_OTHER_GARDENS}', '{POND}')
            .replaceAll('{GRADEN_NAME}', gardenName)
            .replaceAll('{OTH_POND_CON}', cond);
      }
    }

    String brickShedPhrase = '';
    if (_isChecked(answers['cb_brick_sheds'])) {
      final roofType = _cleanLower(answers['actv_roof_type_brick']);
      final roofCover = _cleanLower(answers['actv_roof_covered_in_brick']);
      final cond = _cleanLower(answers['actv_brick_sheds_condition']);
      if (roofType.isNotEmpty && roofCover.isNotEmpty && cond.isNotEmpty) {
        brickShedPhrase = _sub('{H_OTHER_GARDENS}', '{BRICK_SHED}')
            .replaceAll('{GRADEN_NAME}', gardenName)
            .replaceAll('{OTH_BRICK_ROOF_TYPE}', roofType)
            .replaceAll('{OTH_BRICK_ROOF_COVER}', roofCover)
            .replaceAll('{OTH_BRICK_SHED_CON}', cond);
      }
    }

    String timberShedPhrase = '';
    if (_isChecked(answers['cb_timber_sheds'])) {
      final roofType = _cleanLower(answers['actv_roof_type_timber']);
      final roofCover = _cleanLower(answers['actv_roof_covered_in_timber']);
      final cond = _cleanLower(answers['actv_timber_sheds_condition']);
      if (roofType.isNotEmpty && roofCover.isNotEmpty && cond.isNotEmpty) {
        timberShedPhrase = _sub('{H_OTHER_GARDENS}', '{TIMBER_SHED}')
            .replaceAll('{GRADEN_NAME}', gardenName)
            .replaceAll('{OTH_TIMBER_ROOF_TYPE}', roofType)
            .replaceAll('{OTH_TIMBER_ROOF_COVER}', roofCover)
            .replaceAll('{OTH_TIMBER_SHED_CON}', cond);
      }
    }

    if (gardenTypePhrase.isEmpty &&
        fencingPhrase.isEmpty &&
        pondPhrase.isEmpty &&
        brickShedPhrase.isEmpty &&
        timberShedPhrase.isEmpty) {
      return const [];
    }

    var template = _sub('{H_OTHER}', '{H_OTHER_GARDENS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{GARDEN_TYPE}', gardenTypePhrase)
        .replaceAll('{FENCING}', fencingPhrase)
        .replaceAll('{POND}', pondPhrase)
        .replaceAll('{BRICK_SHED}', brickShedPhrase)
        .replaceAll('{TIMBER_SHED}', timberShedPhrase);
    return _split(_normalize(template));
  }

  List<String> _groundsSharedAccess(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_front', 'cb_rear', 'cb_side', 'cb_communal', 'cb_other_190'],
      answers,
      {
        'cb_front': 'Front',
        'cb_rear': 'Rear',
        'cb_side': 'Side',
        'cb_communal': 'Communal',
        'cb_other_190': 'Other',
      },
    );
    _addOther(answers, 'cb_other_190', 'et_other_935', locations);
    if (locations.isEmpty) return const [];
    final status = _cleanLower(answers['actv_shared_status']);
    final template = status.contains('unknown')
        ? _sub('{H_OTHER}', '{SHARED_ACCESS_UNKNOWN}')
        : _sub('{H_OTHER}', '{SHARED_ACCESS_KNOWN}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template.replaceAll('{SA_LOCATION}', _toWords(locations).toLowerCase())));
  }

  List<String> _groundsLargeOutbuilding(Map<String, String> answers) {
    final constructions = _labelsFor(
      ['cb_brick', 'cb_block', 'cb_timber', 'cb_glass', 'cb_other_1072'],
      answers,
      {
        'cb_brick': 'Brick',
        'cb_block': 'Block',
        'cb_timber': 'Timber',
        'cb_glass': 'Glass',
        'cb_other_1072': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1072', 'et_other_761', constructions);

    final types = _labelsFor(
      ['cb_shed', 'cb_summer_house', 'cb_workshop', 'cb_office', 'cb_greenhouse', 'cb_other_458'],
      answers,
      {
        'cb_shed': 'Shed',
        'cb_summer_house': 'Summer house',
        'cb_workshop': 'Workshop',
        'cb_office': 'Office',
        'cb_greenhouse': 'Greenhouse',
        'cb_other_458': 'Other',
      },
    );
    _addOther(answers, 'cb_other_458', 'et_other_443', types);

    final locations = _labelsFor(
      ['cb_front', 'cb_side', 'cb_rear', 'cb_other_222'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_222': 'Other',
      },
    );
    _addOther(answers, 'cb_other_222', 'et_other_198', locations);

    final roofTypes = _labelsFor(
      ['cb_pitched', 'cb_flat', 'cb_other_243'],
      answers,
      {
        'cb_pitched': 'Pitched',
        'cb_flat': 'Flat',
        'cb_other_243': 'Other',
      },
    );
    _addOther(answers, 'cb_other_243', 'et_other_585', roofTypes);

    final roofCovers = _labelsFor(
      ['cb_mineral_felt', 'cb_tiles', 'cb_other_279'],
      answers,
      {
        'cb_mineral_felt': 'Mineral felt',
        'cb_tiles': 'Tiles',
        'cb_other_279': 'Other',
      },
    );
    _addOther(answers, 'cb_other_279', 'et_other_875', roofCovers);

    final condition = _cleanLower(answers['actv_condition']);
    if (constructions.isEmpty && types.isEmpty && locations.isEmpty && roofTypes.isEmpty && roofCovers.isEmpty && condition.isEmpty) {
      return const [];
    }
    var template = _sub('{H_OTHER}', '{LARGE_OUTBUILDING}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{LOB_CONST}', _toWords(constructions).toLowerCase())
        .replaceAll('{LOB_BUIL_TYPE}', _toWords(types).toLowerCase())
        .replaceAll('{LOB_ROOF_LOC}', _toWords(locations).toLowerCase())
        .replaceAll('{LOB_ROOF_TYPE}', _toWords(roofTypes).toLowerCase())
        .replaceAll('{LOB_ROOF_COVER}', _toWords(roofCovers).toLowerCase())
        .replaceAll('{LOB_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _groundsPrivateRoad(Map<String, String> answers) {
    if (!_isChecked(answers['cb_private_road'])) return const [];
    return _split(_normalize(_sub('{H_OTHER}', '{PRIVATE_ROAD}')));
  }

  List<String> _groundsLegalIssues(Map<String, String> answers) {
    final items = _labelsFor(
      [
        'cb_drains',
        'cb_sewers',
        'cb_rainwater_goods',
        'cb_private_road',
        'cb_access',
        'cb_paths',
        'cb_other_742',
      ],
      answers,
      {
        'cb_drains': 'Drains',
        'cb_sewers': 'Sewers',
        'cb_rainwater_goods': 'Rainwater goods',
        'cb_private_road': 'Private road',
        'cb_access': 'Access',
        'cb_paths': 'Paths',
        'cb_other_742': 'Other',
      },
    );
    _addOther(answers, 'cb_other_742', 'et_other_541', items);
    if (items.isEmpty) return const [];
    var template = _sub('{H_OTHER}', '{LEGAL_ISSUES}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{LEGAL_ISSUES_SHARED_AREA}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsShrinkableClay(Map<String, String> answers) {
    if (!_isChecked(answers['cb_shrinkable_clay'])) return const [];
    return _split(_normalize(_sub('{H_OTHER}', '{REPAIR_SHRINKABLE_CLAY}')));
  }

  List<String> _groundsRepairFence(Map<String, String> answers) {
    final gardens = _labelsFor(
      ['cb_front', 'cb_rear', 'cb_side', 'cb_communal', 'cb_other_271'],
      answers,
      {
        'cb_front': 'Front',
        'cb_rear': 'Rear',
        'cb_side': 'Side',
        'cb_communal': 'Communal',
        'cb_other_271': 'Other',
      },
    );
    _addOther(answers, 'cb_other_271', 'et_other_341', gardens);

    final defects = _labelsFor(
      [
        'cb_broken',
        'cb_unstable',
        'cb_leaning',
        'cb_loose_in_places',
        'cb_badly_damaged',
        'cb_rotted_in_places',
        'cb_missing_in_places',
        'cb_other_938',
      ],
      answers,
      {
        'cb_broken': 'Broken',
        'cb_unstable': 'Unstable',
        'cb_leaning': 'Leaning',
        'cb_loose_in_places': 'Loose in places',
        'cb_badly_damaged': 'Badly damaged',
        'cb_rotted_in_places': 'Rotted in places',
        'cb_missing_in_places': 'Missing in places',
        'cb_other_938': 'Other',
      },
    );
    _addOther(answers, 'cb_other_938', 'et_other_276', defects);
    if (gardens.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{H_OTHER}', '{REPAIR_FENCE}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTH_REP_FENCES_GARD}', _toWords(gardens).toLowerCase())
        .replaceAll('{OTH_REP_FENCES_DEF}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsRepairShed(Map<String, String> answers) {
    final types = _labelsFor(
      ['cb_timber', 'cb_brick', 'cb_other'],
      answers,
      {
        'cb_timber': 'Timber',
        'cb_brick': 'Brick',
        'cb_other': 'Other',
      },
    );
    _addOther(answers, 'cb_other', 'et_other', types);
    final defects = _labelsFor(
      ['cb_is_damaged', 'cb_in_disrepair', 'cb_is_unstable', 'cb_other_998'],
      answers,
      {
        'cb_is_damaged': 'Is damaged',
        'cb_in_disrepair': 'In disrepair',
        'cb_is_unstable': 'Is unstable',
        'cb_other_998': 'Other',
      },
    );
    _addOther(answers, 'cb_other_998', 'et_other_472', defects);
    if (types.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{H_OTHER}', '{REPAIR_SHED}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTH_REP_SHED_TYPE}', _toWords(types).toLowerCase())
        .replaceAll('{OTH_REP_SHED_DEF}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsRepairOutbuilding(Map<String, String> answers) {
    final types = _labelsFor(
      ['cb_shed', 'cb_summer_house', 'cb_workshop', 'cb_office', 'cb_green_house', 'cb_other_894'],
      answers,
      {
        'cb_shed': 'Shed',
        'cb_summer_house': 'Summer house',
        'cb_workshop': 'Workshop',
        'cb_office': 'Office',
        'cb_green_house': 'Green house',
        'cb_other_894': 'Other',
      },
    );
    _addOther(answers, 'cb_other_894', 'et_other_98', types);
    final defects = _labelsFor(
      [
        'cb_damaged',
        'cb_broken',
        'cb_unstable',
        'cb_badly_damaged',
        'cb_rotted_in_places',
        'cb_missing_sections',
        'cb_other_440',
      ],
      answers,
      {
        'cb_damaged': 'Damaged',
        'cb_broken': 'Broken',
        'cb_unstable': 'Unstable',
        'cb_badly_damaged': 'Badly damaged',
        'cb_rotted_in_places': 'Rotted in places',
        'cb_missing_sections': 'Missing sections',
        'cb_other_440': 'Other',
      },
    );
    _addOther(answers, 'cb_other_440', 'et_other_923', defects);
    if (types.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{H_OTHER}', '{REPAIR_OUTBUILDING}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTH_REP_OUTBUIL_TYPE}', _toWords(types).toLowerCase())
        .replaceAll('{OTH_REP_OUTBUIL_DEF}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsRepairRetainingWalls(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_front', 'cb_side', 'cb_rear', 'cb_other_411'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_411': 'Other',
      },
    );
    _addOther(answers, 'cb_other_411', 'et_other_384', locations);
    final defects = _labelsFor(
      ['cb_cracked', 'cb_distorted', 'cb_unstable', 'cb_damaged', 'cb_other_394'],
      answers,
      {
        'cb_cracked': 'Cracked',
        'cb_distorted': 'Distorted',
        'cb_unstable': 'Unstable',
        'cb_damaged': 'Damaged',
        'cb_other_394': 'Other',
      },
    );
    _addOther(answers, 'cb_other_394', 'et_other_410', defects);
    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{H_OTHER}', '{REPAIR_RETAINING_WALLS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTH_REP_RET_WALL_TYPE}', _toWords(locations).toLowerCase())
        .replaceAll('{OTH_REP_RET_WALL_DEF}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsRepairNearbyTrees(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final number = _cleanLower(answers['actv_proximity_of_adjacent_tree']);
    if (condition.isEmpty && number.isEmpty) return const [];
    if (condition.contains('problem')) {
      final defects = _labelsFor(
        ['cb_significant_cracks', 'cb_subsidence_movement', 'cb_other_619'],
        answers,
        {
          'cb_significant_cracks': 'Cracks to the property',
          'cb_subsidence_movement': 'Subsidence movement',
          'cb_other_619': 'Other',
        },
      );
      _addOther(answers, 'cb_other_619', 'et_other_197', defects);
      if (defects.isEmpty) return const [];
      var template = _sub('{H_OTHER}', '{REPAIR_NEARBY_TREES_PROBLEM}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{OTH_REP_NBT_COND_NO_OF_TREE}', number)
          .replaceAll('{OTH_REP_NBT_COND_CAUSING}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    var template = _sub('{H_OTHER}', '{REPAIR_NEARBY_TREES_OK}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OTH_REP_NBT_COND_NO_OF_TREE}', number);
    return _split(_normalize(template));
  }

  List<String> _groundsOtherNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{H_OTHER}', '{NOT_INSPECTED}')));
  }

  List<String> _groundsOtherAreaRightOfWay(Map<String, String> answers) {
    final items = _labelsFor(
      [
        'cb_private_road',
        'cb_pedestrian_access',
        'cb_drive',
        'cb_walk_path',
        'cb_entrance_lobby',
        'cb_shared_lobby',
        'cb_other_325',
      ],
      answers,
      {
        'cb_private_road': 'Private road',
        'cb_pedestrian_access': 'Pedestrian access',
        'cb_drive': 'Drive',
        'cb_walk_path': 'Walk path',
        'cb_entrance_lobby': 'Entrance lobby',
        'cb_shared_lobby': 'Shared lobby',
        'cb_other_325': 'Other',
      },
    );
    _addOther(answers, 'cb_other_325', 'et_other_752', items);
    if (items.isEmpty) return const [];
    var template = _sub('{H_OTHER_AREA}', '{RIGHT_OF_WAY}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OA_ROW_PRO_INCLUDES}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsOtherAreaKnotweed(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    final locations = _labelsFor(
      ['cb_within_the_boundary', 'cb_just_outside_the_boundary'],
      answers,
      {
        'cb_within_the_boundary': 'Within the boundary',
        'cb_just_outside_the_boundary': 'Just outside the boundary',
      },
    );
    if ((answers['et_other_732'] ?? '').trim().isNotEmpty) {
      locations.add((answers['et_other_732'] ?? '').trim());
    }
    if (locations.isEmpty) return const [];
    final template = status.contains('restricted')
        ? _sub('{H_OTHER_AREA}', '{KNOTWEED_RESTRICTED_VIEW}')
        : _sub('{H_OTHER_AREA}', '{KNOTWEED_NOTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template.replaceAll('{OA_KNOTWEED_LOCATION}', _toWords(locations).toLowerCase())));
  }

  List<String> _groundsOtherAreaCommonGarden(Map<String, String> answers) {
    if (!_isChecked(answers['cb_common_garden'])) return const [];
    return _split(_normalize(_sub('{H_OTHER_AREA}', '{COMMON_GARDEN}')));
  }

  List<String> _groundsOtherAreaLifts(Map<String, String> answers) {
    if (!_isChecked(answers['cb_lifts'])) return const [];
    return _split(_normalize(_sub('{H_OTHER_AREA}', '{LIFTS}')));
  }

  List<String> _groundsOtherAreaFlooding(Map<String, String> answers) {
    final items = _labelsFor(
      [
        'cb_in_a_low_lying_area',
        'cb_next_to_a_river',
        'cb_next_to_a_canal',
        'cb_close_to_the_sea',
        'cb_other_535',
      ],
      answers,
      {
        'cb_in_a_low_lying_area': 'in a low lying area',
        'cb_next_to_a_river': 'next to a river',
        'cb_next_to_a_canal': 'next to a canal',
        'cb_close_to_the_sea': 'close to the sea',
        'cb_other_535': 'other',
      },
    );
    _addOther(answers, 'cb_other_535', 'et_other_912', items);
    if (items.isEmpty) return const [];
    var template = _sub('{H_OTHER_AREA}', '{FLOODING}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OA_FLOODING_AREA}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsOtherAreaEmf(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_high_voltage_pylons', 'cb_sub_station', 'cb_overhead_cables', 'cb_other_495'],
      answers,
      {
        'cb_high_voltage_pylons': 'High voltage pylons',
        'cb_sub_station': 'Sub station',
        'cb_overhead_cables': 'Overhead cables',
        'cb_other_495': 'Other',
      },
    );
    _addOther(answers, 'cb_other_495', 'et_other_222', items);
    if (items.isEmpty) return const [];
    var template = _sub('{H_OTHER_AREA}', '{EMF}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{OA_EMF_AREA}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _groundsOtherAreaNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{H_OTHER_AREA}', '{NOT_INSPECTED}')));
  }

  List<String> _servicesElectricityMain(Map<String, String> answers) {
    final phrases = <String>[];
    final standard = _sub('{G_ELECTRICITY}', '{STANDARD_TEXT}');
    if (standard.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard)));
    }

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

  List<String> _servicesElectricityMains(Map<String, String> answers) {
    final phrases = <String>[];

    if (_isChecked(answers['cb_electricity_not_inspected'])) {
      final template = _sub('{G_ELECTRICITY}', '{MAINS_ELECTRICITY_NOT_INSPECTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    } else {
      final meterLocations = _labelsFor(
        [
          'cb_under_the_stairs_40',
          'cb_in_an_outside_box_21',
          'cb_in_the_entrance_hall_13',
          'cb_in_the_kitchen_29',
          'cb_in_the_garage_49',
          'cb_in_the_communal_cupboard_21',
          'cb_other_387',
        ],
        answers,
        {
          'cb_under_the_stairs_40': 'Under the stairs',
          'cb_in_an_outside_box_21': 'In an outside box',
          'cb_in_the_entrance_hall_13': 'In the entrance hall',
          'cb_in_the_kitchen_29': 'In the kitchen',
          'cb_in_the_garage_49': 'In the garage',
          'cb_in_the_communal_cupboard_21': 'In the communal cupboard',
          'cb_other_387': 'Other',
        },
      );
      _addOther(answers, 'cb_other_387', 'et_other_564', meterLocations);
      if (meterLocations.isNotEmpty) {
        var template = _sub('{G_ELECTRICITY}', '{MAINS_ELECTRICITY_INSPECTED}');
        if (template.isNotEmpty) {
          template = template.replaceAll('{ELE_ME_METER_LOC}', _toWords(meterLocations).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    if (_isChecked(answers['cb_fuse_not_inspected'])) {
      final template = _sub('{G_ELECTRICITY}', '{FUSE_NOT_INSPECTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    } else {
      final fuseLocations = _labelsFor(
        [
          'cb_in_an_outside_box_54',
          'cb_in_the_entrance_hall_83',
          'cb_in_the_kitchen_73',
          'cb_in_the_garage_66',
          'cb_in_the_communal_cupboard_33',
          'cb_other_717',
        ],
        answers,
        {
          'cb_in_an_outside_box_54': 'Under the stairs',
          'cb_in_the_entrance_hall_83': 'In the entrance hall',
          'cb_in_the_kitchen_73': 'In the kitchen',
          'cb_in_the_garage_66': 'In the garage',
          'cb_in_the_communal_cupboard_33': 'In the communal cupboard',
          'cb_other_717': 'Other',
        },
      );
      _addOther(answers, 'cb_other_717', 'et_other_618', fuseLocations);
      if (fuseLocations.isNotEmpty) {
        var template = _sub('{G_ELECTRICITY}', '{FUSE_INSPECTED}');
        if (template.isNotEmpty) {
          template = template.replaceAll('{ELE_ME_FUSE_BOX_LOC}', _toWords(fuseLocations).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    if (_isChecked(answers['cb_dated_electrical_system'])) {
      final template = _sub('{G_ELECTRICITY}', '{DATED_ELECTRICAL_SYSTEM}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }
    if (_isChecked(answers['cb_dated_electrical_system_electrical_hazard'])) {
      final template = _sub('{G_ELECTRICITY}', '{DATED_ELECTRICAL_SYSTEM_SAFETY_HAZARD}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesSolarPower(Map<String, String> answers) {
    final phrases = <String>[];
    final pvLocations = _labelsFor(
      ['cb_front', 'cb_side', 'cb_rear', 'cb_other_783'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_783': 'Other',
      },
    );
    _addOther(answers, 'cb_other_783', 'et_other_506', pvLocations);
    if (pvLocations.isNotEmpty) {
      var template = _sub('{G_ELECTRICITY}', '{SOLAR_POWER_INSTALLED_LOCATION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{ELE_SO_PV_INST_LOC}', _toWords(pvLocations).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_reasonable_condition'])) {
      final template = _sub('{G_ELECTRICITY}', '{SOLAR_POWER_RESONABLE_CONDITION}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final batteryLocations = _labelsFor(
      ['cb_loft', 'cb_garage', 'cb_bedroom', 'cb_other_870'],
      answers,
      {
        'cb_loft': 'Loft',
        'cb_garage': 'Garage',
        'cb_bedroom': 'Bedroom',
        'cb_other_870': 'Other',
      },
    );
    _addOther(answers, 'cb_other_870', 'et_other_723', batteryLocations);
    if (batteryLocations.isNotEmpty) {
      var template = _sub('{G_ELECTRICITY}', '{SOLAR_POWER_BATTERIES_LOCATION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{ELE_SO_BATTERY_LOCATION}', _toWords(batteryLocations).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (pvLocations.isNotEmpty || batteryLocations.isNotEmpty) {
      final template = _sub('{G_ELECTRICITY}', '{IF_SOLAR_POWER_IS_SELECTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesElectricityRepairLoosePanels(Map<String, String> answers) {
    final defect = _cleanLower(answers['actv_defect']);
    if (defect.isEmpty) return const [];
    var template = _sub('{G_ELECTRICITY}', '{REPAIR_LOOSE_SOLAR_PANELS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{ELE_REP_LOOS_SOL_PANE_DEFECT}', defect);
    return _split(_normalize(template));
  }

  List<String> _servicesElectricityRepairElectricalHazard(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_exposed_wires', 'cb_damaged_fittings', 'cb_other_685'],
      answers,
      {
        'cb_exposed_wires': 'Exposed wires',
        'cb_damaged_fittings': 'Damaged fittings',
        'cb_other_685': 'Other',
      },
    );
    _addOther(answers, 'cb_other_685', 'et_other_733', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{G_ELECTRICITY}', '{REPAIR_ELECTRICAL_HAZARD}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{ELE_REP_ELE_HZRD_BECAUSE_OF}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _servicesElectricityNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{G_ELECTRICITY}', '{NOT_INSPECTED}')));
  }

  List<String> _servicesGasOilMain(Map<String, String> answers) {
    final phrases = <String>[];
    final standard = _sub('{G_GAS_AND_OIL}', '{STANDARD_TEXT}');
    if (standard.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard)));
    }

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

  List<String> _servicesGasOil(Map<String, String> answers) {
    if (!_isChecked(answers['cb_old_tank_but_ok'])) return const [];
    return _split(_normalize(_sub('{G_GAS_AND_OIL}', '{OLD_TANK}')));
  }

  List<String> _servicesMainsGas(Map<String, String> answers) {
    final phrases = <String>[];
    final condition = _cleanLower(answers['actv_condition']);

    if (condition == 'ok') {
      var template = _sub('{G_GAS_AND_OIL}', '{MAINS_GAS_CONDITION_OK}');
      if (template.isNotEmpty) {
        final location = _cleanLower(answers['actv_location']);
        final smellOk = !_isChecked(answers['cb_gas_smell_noted'])
            ? _sub('{G_GAS_AND_OIL}', '{CONDITION_OK_GAS_SMELL}')
            : '';
        template = template
            .replaceAll('{GAO_MG_METER_LOCATION}', location)
            .replaceAll('{CONDITION_OK_GAS_SMELL}', smellOk);
        phrases.addAll(_split(_normalize(template)));
      }
    } else if (condition == 'not inspected') {
      final template = _sub('{G_GAS_AND_OIL}', '{MAINS_GAS_CONDITION_NOT_INSPECTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    } else if (condition == 'no gas installation') {
      final template = _sub('{G_GAS_AND_OIL}', '{MAINS_GAS_CONDITION_NO_GAS_INSTALLATION}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_gas_smell_noted'])) {
      final template = _sub('{G_GAS_AND_OIL}', '{GAS_SMELL_NOTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }
    if (_isChecked(answers['cb_gas_supply_is_capped_off'])) {
      final template = _sub('{G_GAS_AND_OIL}', '{GAS_SUPPLY_IS_CAPPED_OFF}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesOil(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_oil_tank_status']);
    if (status != 'inspected') return const [];
    var template = _sub('{G_GAS_AND_OIL}', '{OIL_TANK_INSPECTED}');
    if (template.isEmpty) return const [];
    final location = _cleanLower(answers['actv_location']);
    final material = _cleanLower(answers['actv_oil_tank_made_up_of']);
    template = template
        .replaceAll('{GAO_O_LOCATION}', location)
        .replaceAll('{GAO_O_OIL_ANK_MADE_OF}', material);
    return _split(_normalize(template));
  }

  List<String> _servicesGasOilRepairGasMeter(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_loose', 'cb_damaged', 'cb_badly_rusted', 'cb_other_309'],
      answers,
      {
        'cb_loose': 'Loose',
        'cb_damaged': 'Damaged',
        'cb_badly_rusted': 'Badly rusted',
        'cb_other_309': 'Other',
      },
    );
    _addOther(answers, 'cb_other_309', 'et_other_595', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{G_GAS_AND_OIL}', '{GAS_METER_REPAIR}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{GAO_REP_GASMETER_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _servicesGasOilRepairStorage(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_storage_tank', 'cb_pipework', 'cb_other_316'],
      answers,
      {
        'cb_storage_tank': 'Tank',
        'cb_pipework': 'Pipework',
        'cb_other_316': 'Other',
      },
    );
    _addOther(answers, 'cb_other_316', 'et_other_537', items);
    final defects = _labelsFor(
      ['cb_corroded', 'cb_leaking', 'cb_damaged', 'cb_poorly_supported', 'cb_other_961'],
      answers,
      {
        'cb_corroded': 'Corroded',
        'cb_leaking': 'Leaking',
        'cb_damaged': 'Damaged',
        'cb_poorly_supported': 'Poorly supported',
        'cb_other_961': 'Other',
      },
    );
    _addOther(answers, 'cb_other_961', 'et_other_421', defects);
    if (items.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{G_GAS_AND_OIL}', '{OIL_STORAGE_TANK_AND_PIPEWORK_REPAIR}');
    if (template.isEmpty) return const [];
    final isAre = _isAre(items);
    template = template
        .replaceAll('{GAO_REP_OILTANK_ITEM}', _toWords(items).toLowerCase())
        .replaceAll('{GAO_REP_OILTANK_DEFECT}', _toWords(defects).toLowerCase())
        .replaceAll('{IS_ARE}', isAre);
    return _split(_normalize(template));
  }

  List<String> _servicesGasOilNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{G_GAS_AND_OIL}', '{NOT_INSPECTED}')));
  }

  List<String> _servicesWaterMain(Map<String, String> answers) {
    final phrases = <String>[];
    final standard = _sub('{G_WATER}', '{STANDARD_TEXT}');
    if (standard.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard)));
    }

    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_WATER}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WATER_CONDITION_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_WATER}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WATER_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesWaterMainWater(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_stopcock_found'])) {
      final location = _cleanLower(answers['actv_stopcok_location']);
      var template = _sub('{G_WATER}', '{STOPCOCK_FOUND}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WATER_STOPCOCK_LOCATION}', location);
        phrases.addAll(_split(_normalize(template)));
      }
    } else {
      final template = _sub('{G_WATER}', '{STOPCOCK_NOT_FOUND}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_lead_rising'])) {
      final template = _sub('{G_WATER}', '{LEAD_RISING}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final standard2 = _sub('{G_WATER}', '{STANDARD_TEXT_2}');
    if (standard2.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard2)));
    }

    return phrases;
  }

  List<String> _servicesWaterNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{G_WATER}', '{NOT_INSPECTED}')));
  }

  List<String> _servicesHeatingMain(Map<String, String> answers) {
    final phrases = <String>[];
    final standard = _sub('{G_HEATING}', '{STANDARD_TEXT}');
    if (standard.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard)));
    }

    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_HEATING}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{HEAT_COND_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_HEATING}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{HEAT_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesHeatingAbout(Map<String, String> answers) {
    if (_isChecked(answers['cb_not_inspected'])) {
      final template = _sub('{G_HEATING}', '{ABOUT_HEATING_NOT_INSPECTED}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }

    final noHeating = _isChecked(answers['cb_no_heating'])
        ? _sub('{G_HEATING}', '{ABOUT_NO_HEATING}')
        : '';
    final communal = _isChecked(answers['cb_communal_heating'])
        ? _sub('{G_HEATING}', '{ABOUT_COMMUNAL_HEATING}')
        : '';

    final otherHeatingSelections = _labelsFor(
      ['cb_oil_filled', 'cb_electric_storage', 'cb_convector', 'cb_other_923'],
      answers,
      {
        'cb_oil_filled': 'Oil filled',
        'cb_electric_storage': 'Electric storage',
        'cb_convector': 'Convector',
        'cb_other_923': 'Other',
      },
    );
    _addOther(answers, 'cb_other_923', 'et_other_717', otherHeatingSelections);
    var otherHeating = '';
    if (otherHeatingSelections.isNotEmpty) {
      var template = _sub('{G_HEATING}', '{ABOUT_OTHER_HEATING}');
      if (template.isNotEmpty) {
        otherHeating = template.replaceAll(
          '{HEAT_OTHER_HEATING}',
          _toWords(otherHeatingSelections).toLowerCase(),
        );
      }
    }

    String aboutInspected = '';
    final heatedBy = _cleanLower(answers['actv_boiler']);
    final location = _cleanLower(answers['actv_location']);
    if (heatedBy.isNotEmpty && location.isNotEmpty) {
      var template = _sub('{G_HEATING}', '{ABOUT_INSPECTED}');
      if (template.isNotEmpty) {
        aboutInspected = template
            .replaceAll('{HEAT_HEATED_BY_BOILER}', heatedBy)
            .replaceAll('{HEAT_BOILER_LOCATION}', location);
      }
    }

    String flueText = '';
    final flueLocation = _cleanLower(answers['actv_location_new']);
    final flueCondition = _cleanLower(answers['actv_condition']);
    if (flueLocation.isNotEmpty && flueCondition.isNotEmpty) {
      var template = _sub('{G_HEATING}', '{ABOUT_BOILER_FLUE_CONNECTED_TO}');
      if (template.isNotEmpty) {
        flueText = template
            .replaceAll('{HEAT_BOILER_FLUE_CONN_LOC}', flueLocation)
            .replaceAll('{HEAT_BOILER_FLUE_CONN_COND}', flueCondition);
      }
    }

    String connected = '';
    final connectedTo = _cleanLower(answers['actv_connected_heat']);
    if (connectedTo.isNotEmpty) {
      var template = _sub('{G_HEATING}', '{ABOUT_CONNECTED_TO_RADIATOR_UNDERFLOOR_PIPES}');
      if (template.isNotEmpty) {
        connected = template.replaceAll('{HEAT_CONNECTED_TO}', connectedTo);
      }
    }

    final oldBoiler = _isChecked(answers['cb_old_boiler'])
        ? _sub('{G_HEATING}', '{ABOUT_OLD_BOILER}')
        : '';

    var wrapper = _sub('{G_HEATING}', '{ABOUT_HEATING_INSPECTED}');
    if (wrapper.isEmpty) return const [];
    wrapper = wrapper
        .replaceAll('{ABOUT_NO_HEATING}', noHeating)
        .replaceAll('{ABOUT_COMMUNAL_HEATING}', communal)
        .replaceAll('{ABOUT_OTHER_HEATING}', otherHeating)
        .replaceAll('{ABOUT_INSPECTED}', aboutInspected)
        .replaceAll('{ABOUT_BOILER_FLUE_CONNECTED_TO}', flueText)
        .replaceAll('{ABOUT_CONNECTED_TO_RADIATOR_UNDERFLOOR_PIPES}', connected)
        .replaceAll('{ABOUT_OLD_BOILER}', oldBoiler);
    return _split(_normalize(wrapper));
  }

  List<String> _servicesHeatingRepair(Map<String, String> answers) {
    final severity = _cleanLower(answers['actv_leaks']);
    final items = _labelsFor(
      ['cb_radiator', 'cb_pipework', 'cb_other_245'],
      answers,
      {
        'cb_radiator': 'Radiator',
        'cb_pipework': 'Pipework',
        'cb_other_245': 'Other',
      },
    );
    _addOther(answers, 'cb_other_245', 'et_other_277', items);
    final locations = _labelsFor(
      ['cb_lounge', 'cb_bedroom', 'cb_bathroom', 'cb_other_717'],
      answers,
      {
        'cb_lounge': 'Lounge',
        'cb_bedroom': 'Bedroom',
        'cb_bathroom': 'Bathroom',
        'cb_other_717': 'Other',
      },
    );
    _addOther(answers, 'cb_other_717', 'et_other_263', locations);

    if (severity.isEmpty || items.isEmpty || locations.isEmpty) return const [];
    final phraseCode =
        severity.contains('major') ? '{REPAIR_MAJOR_LEAKS}' : '{REPAIR_MINOR_LEAKS}';
    var template = _sub('{G_HEATING}', phraseCode);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{HEAT_REP_ITEM}', _toWords(items).toLowerCase())
        .replaceAll('{HEAT_REP_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{IS_ARE}', _isAre(items));
    return _split(_normalize(template));
  }

  List<String> _servicesHeatingNotInspected(Map<String, String> answers) {
    if (_isChecked(answers['cb_no_heating']) || _isChecked(answers['cb_boiler_unit_not_inspected'])) {
      final template = _sub('{G_HEATING}', '{NOT_INSPECTED}');
      if (template.isNotEmpty) {
        return _split(_normalize(template));
      }
    }
    return const [];
  }

  List<String> _servicesDrainageMain(Map<String, String> answers) {
    final phrases = <String>[];
    final standard = _sub('{G_DRAINAGE}', '{STANDARD_TEXT}');
    if (standard.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard)));
    }
    final standard2 = _sub('{G_DRAINAGE}', '{STANDARD_TEXT_2}');
    if (standard2.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard2)));
    }

    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_DRAINAGE}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{DRA_COND_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_DRAINAGE}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{DRA_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesDrainage(Map<String, String> answers) {
    final phrases = <String>[];

    if (_isChecked(answers['cb_private_system'])) {
      if (_isChecked(answers['cb_septic_tank'])) {
        final template = _sub('{G_DRAINAGE}', '{PRIVATE_SYSTEM_SEPTIC_TANK}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
      if (_isChecked(answers['cb_cess_pit'])) {
        final template = _sub('{G_DRAINAGE}', '{PRIVATE_SYSTEM_CESS_PIT}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    if (_isChecked(answers['cb_public_system'])) {
      final publicTemplate = _sub('{G_DRAINAGE}', '{PUBLIC_SYSTEM}');
      if (publicTemplate.isNotEmpty) {
        phrases.addAll(_split(_normalize(publicTemplate)));
      }

      final status = _cleanLower(answers['actv_inspection_status']);
      if (status.contains('inspected') && !status.contains('not')) {
        final cover = _isChecked(answers['cb_cover_were_lifted']);
        final conditionOk = _isChecked(answers['cb_condition_ok']);
        if (cover && conditionOk) {
          final template = _sub('{G_DRAINAGE}', '{PUBLIC_SYSTEM_STATUS_INSPECTED}');
          if (template.isNotEmpty) {
            phrases.addAll(_split(_normalize(template)));
          }
        } else {
          if (cover) {
            final template = _sub('{G_DRAINAGE}', '{PUBLIC_SYSTEM_INSPECTED_LIFTED_TICKBOX}');
            if (template.isNotEmpty) {
              phrases.addAll(_split(_normalize(template)));
            }
          }
          if (conditionOk) {
            final template = _sub('{G_DRAINAGE}', '{PUBLIC_SYSTEM_INSPECTED_CONDITION_OK}');
            if (template.isNotEmpty) {
              phrases.addAll(_split(_normalize(template)));
            }
          }
        }
      } else if (status.contains('not inspected')) {
        final template = _sub('{G_DRAINAGE}', '{PUBLIC_SYSTEM_STATUS_NOT_INSPECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      } else if (status.contains('not found')) {
        final template = _sub('{G_DRAINAGE}', '{PUBLIC_SYSTEM_STATUS_NOT_FOUND}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    if (_isChecked(answers['cb_shared'])) {
      final template = _sub('{G_DRAINAGE}', '{DRAINAGE_SHARED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final soilStatus = _cleanLower(answers['actv_ins_status']);
    if (soilStatus.contains('partially')) {
      final visibleOnly = _labelsFor(
        ['cb_visible_only_within_roof_space', 'cb_visible_only_other'],
        answers,
        {
          'cb_visible_only_within_roof_space': 'Within the roof space',
          'cb_visible_only_other': 'Other',
        },
      );
      _addOther(answers, 'cb_visible_only_other', 'et_other_123456000', visibleOnly);

      final materials = _labelsFor(
        [
          'cb_material_plastic_pipe',
          'cb_material_cast_iron',
          'cb_material_asbestos_cement',
          'cb_material_other'
        ],
        answers,
        {
          'cb_material_plastic_pipe': 'Plastic pipe',
          'cb_material_cast_iron': 'Cast iron',
          'cb_material_asbestos_cement': 'Asbestos cement',
          'cb_material_other': 'Other',
        },
      );
      _addOther(answers, 'cb_material_other', 'et_other_123456', materials);

      if (visibleOnly.isNotEmpty && materials.isNotEmpty) {
        var template = _sub('{G_DRAINAGE}', '{SOIL_VENT_PARTIALLY_INSPECTED}');
        if (template.isNotEmpty) {
          template = template
              .replaceAll('{SOIL_VENT_VISIBLE_ONLY}', _toWords(visibleOnly).toLowerCase())
              .replaceAll('{SOIL_VENT_MATERIAL}', _toWords(materials).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }

      if (materials.any((item) => item.toLowerCase().contains('asbestos'))) {
        final template = _sub('{G_DRAINAGE}', '{IF_ASBESTOS_CEMENT_IS_SELECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    } else if (soilStatus.contains('inspected') && !soilStatus.contains('not')) {
      final locations = _labelsFor(
        ['cb_loc_front', 'cb_loc_rear', 'cb_loc_side'],
        answers,
        {
          'cb_loc_front': 'Front',
          'cb_loc_rear': 'Rear',
          'cb_loc_side': 'Side',
        },
      );

      final materials = _labelsFor(
        [
          'cb_material_plastic_pipe',
          'cb_material_cast_iron',
          'cb_material_asbestos_cement',
          'cb_material_other'
        ],
        answers,
        {
          'cb_material_plastic_pipe': 'Plastic pipe',
          'cb_material_cast_iron': 'Cast iron',
          'cb_material_asbestos_cement': 'Asbestos cement',
          'cb_material_other': 'Other',
        },
      );
      _addOther(answers, 'cb_material_other', 'et_other_123456', materials);

      if (locations.isNotEmpty && materials.isNotEmpty) {
        var template = _sub('{G_DRAINAGE}', '{SOIL_VENT_INSPECTED}');
        if (template.isNotEmpty) {
          template = template
              .replaceAll('{SOIL_VENT_LOCATION}', _toWords(locations).toLowerCase())
              .replaceAll('{SOIL_VENT_MATERIAL}', _toWords(materials).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }

      if (materials.any((item) => item.toLowerCase().contains('asbestos'))) {
        final template = _sub('{G_DRAINAGE}', '{IF_ASBESTOS_CEMENT_IS_SELECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    } else if (soilStatus.contains('not inspected')) {
      final template = _sub('{G_DRAINAGE}', '{SOIL_VENT_NOT_INSPECTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesDrainageRepairChamberCover(Map<String, String> answers) {
    final defect = _cleanLower(answers['actv_defect']);
    if (defect.isEmpty) return const [];
    var template = _sub('{G_DRAINAGE}', '{REPAIR_CHAMBER_COVER}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{DRA_REP_CHAMBER_COVER_DEFECT}', defect);
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageRepairChamberWalls(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_badly_broken', 'cb_crumbling', 'cb_badly_cracked', 'cb_other_835'],
      answers,
      {
        'cb_badly_broken': 'Badly broken',
        'cb_crumbling': 'Crumbling',
        'cb_badly_cracked': 'Badly cracked',
        'cb_other_835': 'Other',
      },
    );
    _addOther(answers, 'cb_other_835', 'et_other_558', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{G_DRAINAGE}', '{REPAIR_CHAMBER_WALLS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{DRA_REP_CHAMBER_WALLS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageRepairChamberPipes(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_badly_cracked', 'cb_poorly_installed', 'cb_partially_blocked', 'cb_other_458'],
      answers,
      {
        'cb_badly_cracked': 'Badly cracked',
        'cb_poorly_installed': 'Poorly installed',
        'cb_partially_blocked': 'Partially blocked',
        'cb_other_458': 'Other',
      },
    );
    _addOther(answers, 'cb_other_458', 'et_other_423', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{G_DRAINAGE}', '{REPAIR_CHAMBER_PIPES}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{DRA_REP_CHAMBER_PIPES_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageRepairSoilAndVent(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_cracked', 'cb_damaged', 'cb_corroded', 'cb_leaking', 'cb_poorly_fixed', 'cb_other_1098'],
      answers,
      {
        'cb_cracked': 'Cracked',
        'cb_damaged': 'Damaged',
        'cb_corroded': 'Corroded',
        'cb_leaking': 'Leaking',
        'cb_poorly_fixed': 'Poorly fixed',
        'cb_other_1098': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1098', 'et_other_889', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{G_DRAINAGE}', '{REPAIR_SOIL_AND_VENT}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{DRA_REP_SOIL_N_VENT_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageRepairRoots(Map<String, String> answers) {
    if (!_isChecked(answers['cb_roots_in_chamber'])) return const [];
    final template = _sub('{G_DRAINAGE}', '{REPAIR_ROOTS_IN_CHAMBER}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageRepairGullies(Map<String, String> answers) {
    final defects = _labelsFor(
      [
        'cb_partly_blocked',
        'cb_are_damaged',
        'cb_do_not_have_a_cover',
        'cb_completely_blocked',
        'cb_other_229'
      ],
      answers,
      {
        'cb_partly_blocked': 'Partly blocked',
        'cb_are_damaged': 'Are damaged',
        'cb_do_not_have_a_cover': 'Do not have a cover',
        'cb_completely_blocked': 'Completely blocked',
        'cb_other_229': 'Other',
      },
    );
    _addOther(answers, 'cb_other_229', 'et_other_395', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{G_DRAINAGE}', '{REPAIR_GULLIES}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{DRA_REP_GULLIES_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageRepairDefectDampness(Map<String, String> answers) {
    if (!_isChecked(answers['cb_defects_causing_dampness'])) return const [];
    final template = _sub('{G_DRAINAGE}', '{REPAIR_DEFECTS_CAUSING_DAMPNESS}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _servicesDrainageNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{G_DRAINAGE}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _servicesCommonServicesMain(Map<String, String> answers) {
    final phrases = <String>[];
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_COMMON_SERVICES}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{CS_COND_RATIING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_COMMON_SERVICES}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{CS_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _servicesCommonServices(Map<String, String> answers) {
    final selections = _labelsFor(
      [
        'cb_communal_drain',
        'cb_grounds_maintenance',
        'cb_cleaning',
        'cb_lifts',
        'cb_hot_water',
        'cb_door_access_systems',
        'cb_vehicular_access',
        'cb_parking',
        'cb_communal_lighting',
        'cb_other_268',
      ],
      answers,
      {
        'cb_communal_drain': 'Communal drain',
        'cb_grounds_maintenance': 'Grounds maintenance',
        'cb_cleaning': 'Cleaning',
        'cb_lifts': 'Lifts',
        'cb_hot_water': 'Hot water',
        'cb_door_access_systems': 'Door access systems',
        'cb_vehicular_access': 'Vehicular access',
        'cb_parking': 'Parking',
        'cb_communal_lighting': 'Communal lighting',
        'cb_other_268': 'Other',
      },
    );
    _addOther(answers, 'cb_other_268', 'et_other_783', selections);
    final commonServicesText = selections.isEmpty ? '' : _toWords(selections).toLowerCase();

    if (_isChecked(answers['cb_not_applicable'])) {
      var template = _sub('{G_COMMON_SERVICES}', '{NOT_APPLICABLE}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{COMMON_SERVICES}', commonServicesText);
      return _split(_normalize(template));
    }

    if (commonServicesText.isEmpty) return const [];
    var template = _sub('{G_COMMON_SERVICES}', '{COMMON_SERVICES}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CS_COMM_SERVICES}', commonServicesText);
    return _split(_normalize(template));
  }

  List<String> _servicesCommonServicesNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{G_COMMON_SERVICES}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _servicesWaterHeatingMain(Map<String, String> answers) {
    final phrases = <String>[];
    final standard = _sub('{G_WATER_HEATING}', '{STANDARD_TEXT}');
    if (standard.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard)));
    }
    final standard2 = _sub('{G_WATER_HEATING}', '{STANDARD_TEXT_2}');
    if (standard2.isNotEmpty) {
      phrases.addAll(_split(_normalize(standard2)));
    }

    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    if (rating.isNotEmpty) {
      var template = _sub('{G_WATER_HEATING}', '{CONDITION_RATING}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WH_COND_RATING}', rating);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    final notes = (answers['ar_etNote'] ?? '').trim();
    if (notes.isNotEmpty) {
      var template = _sub('{G_WATER_HEATING}', '{NOTES}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WH_NOTES}', notes);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesWaterHeatingCommunalHotWater(Map<String, String> answers) {
    if (!_isChecked(answers['cb_communal_hot_water'])) return const [];
    final template = _sub('{G_WATER_HEATING}', '{COMMUNAL_HOT_WATER}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _servicesWaterHeatingGas(Map<String, String> answers) {
    final phrases = <String>[];
    final type = _cleanLower(answers['actv_type']);
    final location = _cleanLower(answers['actv_location']);
    if (type.contains('combi')) {
      var template = _sub('{G_WATER_HEATING}', '{GAS_WATER_HEATING_COMBI_BOILER}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WH_GWH_CYLI_LOCATION}', location);
        phrases.addAll(_split(_normalize(template)));
      }
    } else if (type.contains('conventional')) {
      var template = _sub('{G_WATER_HEATING}', '{GAS_WATER_HEATING_CONVENTIONAL}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WH_GWH_CYLI_LOCATION}', location);
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_poor_cylinder_condition'])) {
      final template = _sub('{G_WATER_HEATING}', '{POOR_CYLINDER_CONDITION}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesWaterHeatingElectric(Map<String, String> answers) {
    final phrases = <String>[];
    final type = _cleanLower(answers['actv_type']);
    if (type.contains('immersion')) {
      var template = _sub('{G_WATER_HEATING}', '{ELECTRIC_WATER_HEATING_IMMERSION}');
      if (template.isNotEmpty) {
        template = template.replaceAll(
          '{WH_EWH_CYLI_LOCATION}',
          _cleanLower(answers['actv_location']),
        );
        phrases.addAll(_split(_normalize(template)));
      }
    } else if (type.contains('point-of-use') || type.contains('point of use')) {
      final template = _sub('{G_WATER_HEATING}', '{ELECTRIC_WATER_HEATING_POINT_OF_USE}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    if (_isChecked(answers['cb_poor_cylinder_condition'])) {
      final template = _sub('{G_WATER_HEATING}', '{ELECTRIC_POOR_CYLINDER_CONDITION}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }

    return phrases;
  }

  List<String> _servicesWaterHeatingSolar(Map<String, String> answers) {
    if (!_isChecked(answers['cb_solar_power'])) return const [];
    final template = _sub('{G_WATER_HEATING}', '{SOLAR_WATER_HEATING}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _servicesWaterHeatingRepairLeakingCylinder(Map<String, String> answers) {
    final defect = _cleanLower(answers['actv_defect']);
    if (defect.isEmpty) return const [];
    var template = _sub('{G_WATER_HEATING}', '{REPAIR_LEAKING_CYLINDER}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{WH_REPAIR_LEAK_CYLI_DEFECTS}', defect);
    return _split(_normalize(template));
  }

  List<String> _servicesWaterHeatingRepairLoosePanels(Map<String, String> answers) {
    final defect = _cleanLower(answers['actv_defect']);
    if (defect.isEmpty) return const [];
    var template = _sub('{G_WATER_HEATING}', '{REPAIR_LOOSE_SOLAR_PANELS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{WH_REPAIR_LOOS_SOL_PANEL_DEFECTS}', defect);
    return _split(_normalize(template));
  }

  List<String> _servicesWaterHeatingNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{G_WATER_HEATING}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _insidePropertyLimitations(Map<String, String> answers) {
    final phrases = <String>[];

    if (_isChecked(answers['ch1'])) {
      final chimney = _sub('{F_INSIDE_THE_PROPERTY}', '{LIMITATIONS_CHIMNEY_FLUE_NOT_INSPECTED}');
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
        ],
        answers,
        {
          'cb_statuslimited_roof_height': 'limited roof height',
          'cb_floors_not_safe_to_walk_on': 'floors not safe to walk on',
          'cb_some_or_all_of_the_floors_are_boarded': 'some or all of the floors are boarded',
          'cb_excessive_storage_of_personal_goods': 'excessive storage of personal goods',
        },
      );

      var roof = _sub('{F_INSIDE_THE_PROPERTY}', '{LIMITATIONS_ROOF_TIMBER_NOT_FULLY_INSPECTED}');
      if (roof.isNotEmpty) {
        roof = roof.replaceAll(
          '{LIM_RT_NOT_FULLY_INSPECTED_REASON}',
          reasons.isEmpty ? 'access restrictions' : _toWords(reasons).toLowerCase(),
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

  List<String> _insideRoofWeatherCondition(Map<String, String> answers) {
    final phrases = <String>[];
    final weather = _cleanLower(answers['actv_weather_condition']);
    if (weather.contains('wet')) {
      final template = _sub('{F_ROOF_STRUCTURE}', '{WEATHER_CONDITION_WET}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }
    if (weather.contains('dry')) {
      final template = _sub('{F_ROOF_STRUCTURE}', '{WEATHER_CONDITION_DRY}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }
    if (_isChecked(answers['cb_not_inspected'])) {
      final template = _sub('{F_ROOF_STRUCTURE}', '{LEAKES_NOTED}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _insideRoofLoftConverted(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_cracked_walls', 'cb_sagging_ceiling', 'cb_out_of_square_door', 'cb_other_608'],
      answers,
      {
        'cb_cracked_walls': 'Cracked walls',
        'cb_sagging_ceiling': 'Sagging ceiling',
        'cb_out_of_square_door': 'Out of square door',
        'cb_other_608': 'Other',
      },
    );
    _addOther(answers, 'cb_other_608', 'et_other_752', defects);

    if (defects.isNotEmpty) {
      var template = _sub('{F_ROOF_STRUCTURE}', '{LOFT_CONVERTED_DEFECT}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{RS_LC_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    if (_isChecked(answers['cb_loft_converted'])) {
      final template = _sub('{F_ROOF_STRUCTURE}', '{LOFT_CONVERTED}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _insideRoofAbout(Map<String, String> answers) {
    final constructionValue = (answers['actv_construction'] ?? '').trim();
    final underliningValue = _cleanLower(answers['actv_underlining']);
    final insulationValue = _cleanLower(answers['actv_insulation']);
    final conditionValue = (answers['actv_roof_structure_condition'] ?? '').trim();

    String constructionText = '';
    if (constructionValue.isNotEmpty) {
      var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{CONSTRUCTION}');
      if (template.isNotEmpty) {
        constructionText = template.replaceAll('{RS_ARS_CONSTRUCTION}', constructionValue.toLowerCase());
      }
    }

    String underliningText = '';
    if (underliningValue.isNotEmpty) {
      if (underliningValue.contains('no')) {
        underliningText = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{UNDERLINING_STATUS_NO_UNDERLINING}');
      } else if (underliningValue.contains('underlining')) {
        var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{UNDERLINING_STATUS_UNDERLINING_OK}');
        if (template.isNotEmpty) {
          final materials = _labelsFor(
            ['cb_sacking_felt', 'cb_plastic', 'cb_timber_boarding', 'cb_other_696'],
            answers,
            {
              'cb_sacking_felt': 'Sacking felt',
              'cb_plastic': 'Plastic',
              'cb_timber_boarding': 'Timber boarding',
              'cb_other_696': 'Other',
            },
          );
          _addOther(answers, 'cb_other_696', 'et_other_666', materials);

          final defects = _labelsFor(
            ['cb_torn', 'cb_missing_in_places', 'cb_damaged', 'cb_other_286'],
            answers,
            {
              'cb_torn': 'Torn',
              'cb_missing_in_places': 'Missing in places',
              'cb_damaged': 'Damaged',
              'cb_other_286': 'Other',
            },
          );
          _addOther(answers, 'cb_other_286', 'et_other_746', defects);

          var materialText = '';
          if (materials.isNotEmpty) {
            var materialTemplate = _sub('{UNDERLINING_STATUS_UNDERLINING_OK}', '{UNDERLINING_MATERIAL}');
            if (materialTemplate.isNotEmpty) {
              materialText = materialTemplate.replaceAll('{RS_ARS_UNDERLINE_MATERIAL}', _toWords(materials).toLowerCase());
            }
          }

          var defectText = '';
          if (defects.isNotEmpty) {
            var defectTemplate = _sub('{UNDERLINING_STATUS_UNDERLINING_OK}', '{UNDERLINING_DEFECT}');
            if (defectTemplate.isNotEmpty) {
              defectText = defectTemplate.replaceAll('{RS_ARS_UNDERLINE_DEFECT}', _toWords(defects).toLowerCase());
            }
          }

          var conditionText = '';
          if (conditionValue.isNotEmpty) {
            var conditionTemplate = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{ROOF_STRUCTURE_CONDITION}');
            if (conditionTemplate.isNotEmpty) {
              conditionText = conditionTemplate.replaceAll('{RS_ARS_CONDITION}', conditionValue.toLowerCase());
            }
          }

          template = template
              .replaceAll('{UNDERLINING_MATERIAL}', materialText)
              .replaceAll('{ROOF_STRUCTURE_CONDITION}', conditionText)
              .replaceAll('{UNDERLINING_DEFECT}', defectText);
          underliningText = template;
        }
      }
    }

    String insulationText = '';
    if (insulationValue.contains('adequate')) {
      insulationText = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{INSULATION_ADEQUATE}');
    } else if (insulationValue.contains('inadequate')) {
      insulationText = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{INSULATION_INADEQUATE}');
    }

    String insulationDampText = '';
    if (_isChecked(answers['cb_damp_noted'])) {
      final dampDetails = <String>[];
      if (_isChecked(answers['cb_floorboards_are_not_insulated'])) {
        dampDetails.add('not insulated');
      }
      if (_isChecked(answers['cb_floorboards_are_not_adequately_insulated'])) {
        dampDetails.add('not adequately insulated');
      }
      if (dampDetails.isNotEmpty) {
        var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{INSULATION_DAMP}');
        if (template.isNotEmpty) {
          insulationDampText = template.replaceAll('{RS_ARS_IRD_DETAIL}', _toWords(dampDetails).toLowerCase());
        }
      }
    }

    String ventilationNoText = '';
    String ventilationInsufficientText = '';
    if (_isChecked(answers['cb_ventilation_related_damp'])) {
      if (_isChecked(answers['cb_none'])) {
        ventilationNoText = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{VENTILATION_DAMP_NO_VENTILATION}');
      }
      if (_isChecked(answers['cb_damp_noted_ventilation'])) {
        ventilationInsufficientText = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{VENTILATION_DAMP_IN_SUFFICIENT_VENTILATION}');
      }
    }

    final template = _sub('{F_ROOF_STRUCTURE}', '{F_ABOUT_ROOF_STRUCTURE}');
    if (template.isEmpty) return const [];
    if ([
      constructionText,
      underliningText,
      insulationText,
      insulationDampText,
      ventilationNoText,
      ventilationInsufficientText
    ].every((value) => value.isEmpty)) {
      return const [];
    }

    final result = template
        .replaceAll('{CONSTRUCTION}', constructionText)
        .replaceAll('{UNDERLINING_STATUS}', underliningText)
        .replaceAll('{INSULATION_STATUS}', insulationText)
        .replaceAll('{INSULATION_DAMP}', insulationDampText)
        .replaceAll('{VENTILATION_DAMP_NO_VENTILATION}', ventilationNoText)
        .replaceAll('{VENTILATION_DAMP_IN_SUFFICIENT_VENTILATION}', ventilationInsufficientText);
    return _split(_normalize(result));
  }

  List<String> _insideRoofWaterTank(Map<String, String> answers) {
    if (_isChecked(answers['cb_not_inspected'])) {
      final template = _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{NOT_INSPECTED}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }

    final materials = _labelsFor(
      ['cb_plastic', 'cb_galvanised_metal', 'cb_asbestos', 'cb_other_245'],
      answers,
      {
        'cb_plastic': 'Plastic',
        'cb_galvanised_metal': 'Galvanised metal',
        'cb_asbestos': 'Asbestos',
        'cb_other_245': 'Other',
      },
    );
    _addOther(answers, 'cb_other_245', 'et_other_358', materials);

    final locations = _labelsFor(
      ['cb_roof_space_used', 'cb_airing_cupboard_used', 'cb_kitchen_used', 'cb_other_1057_used'],
      answers,
      {
        'cb_roof_space_used': 'Roof space',
        'cb_airing_cupboard_used': 'Airing cupboard',
        'cb_kitchen_used': 'Kitchen',
        'cb_other_1057_used': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1057_used', 'et_other_141_used', locations);

    final tankCondition = (answers['actv_tank_condition'] ?? '').trim();

    String materialLocationText = '';
    if (materials.isNotEmpty && locations.isNotEmpty && tankCondition.isNotEmpty) {
      var template = _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{WATERL_TANK_MATERIAL_LOCATION}');
      if (template.isNotEmpty) {
        materialLocationText = template
            .replaceAll('{RS_WT_LOCATION}', _toWords(locations).toLowerCase())
            .replaceAll('{RS_WT_MATERIAL}', _toWords(materials).toLowerCase())
            .replaceAll('{RS_WT_CONDITION}', tankCondition.toLowerCase());
      }
    }

    String insulationOkText = '';
    if (_isChecked(answers['cb_insulation'])) {
      insulationOkText = _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{INSULATION_STATUS_OK}');
    }

    String missingCoverText = '';
    if (_isChecked(answers['cb_missing_cover']) && materials.isNotEmpty) {
      var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_TANK_MISSING_COVER}');
      if (template.isNotEmpty) {
        missingCoverText =
            template.replaceAll('{RSR_RT_MISSING_COVER_MATERIAL}', _toWords(materials).toLowerCase());
      }
    }

    String noInsulationText = '';
    if (_isChecked(answers['cb_not_insulation'])) {
      noInsulationText = _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{INSULATION_STATUS_NO_INSULATION}');
    }

    String notAdequatelyInsulatedText = '';
    if (_isChecked(answers['cb_not_adequately_insulated'])) {
      notAdequatelyInsulatedText =
          _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}');
    }

    String disusedText = '';
    if (_isChecked(answers['cb_disused_water_tank'])) {
      final disusedMaterials = _labelsFor(
        ['cb_plastic_disused', 'cb_galvanised_metal_disused', 'cb_asbestos_disused', 'cb_other_245_disused'],
        answers,
        {
          'cb_plastic_disused': 'Plastic',
          'cb_galvanised_metal_disused': 'Galvanised metal',
          'cb_asbestos_disused': 'Asbestos',
          'cb_other_245_disused': 'Other',
        },
      );
      _addOther(answers, 'cb_other_245_disused', 'et_other_358_disused', disusedMaterials);

      final disusedLocations = _labelsFor(
        ['cb_roof_space', 'cb_airing_cupboard', 'cb_kitchen', 'cb_other_1057'],
        answers,
        {
          'cb_roof_space': 'Roof space',
          'cb_airing_cupboard': 'Airing cupboard',
          'cb_kitchen': 'Kitchen',
          'cb_other_1057': 'Other',
        },
      );
      _addOther(answers, 'cb_other_1057', 'et_other_141', disusedLocations);

      if (disusedMaterials.isNotEmpty && disusedLocations.isNotEmpty) {
        var template = _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{DISUSED_WATER_TANK}');
        if (template.isNotEmpty) {
          disusedText = template
              .replaceAll('{RS_WT_DISUSED_WATER_TANK_LOCATION}', _toWords(disusedLocations).toLowerCase())
              .replaceAll('{RS_WT_DISUSED_WATER_TANK_MATERIAL}', _toWords(disusedMaterials).toLowerCase());
        }
      }
    }

    final template = _sub('{F_ROOF_STRUCTURE_WATER_TANK}', '{INSPECTED}');
    if (template.isEmpty) return const [];

    final result = template
        .replaceAll('{WATERL_TANK_MATERIAL_LOCATION}', materialLocationText)
        .replaceAll('{INSULATION_STATUS_OK}', insulationOkText)
        .replaceAll('{REPAIR_TANK_MISSING_COVER}', missingCoverText)
        .replaceAll('{INSULATION_STATUS_NO_INSULATION}', noInsulationText)
        .replaceAll('{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}', notAdequatelyInsulatedText)
        .replaceAll('{TANK_STOPCOCK}', '')
        .replaceAll('{DISUSED_WATER_TANK}', disusedText);
    return _split(_normalize(result));
  }

  List<String> _insideRoofRepairTank(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_old', 'cb_leaking', 'cb_in_disrepair', 'cb_damaged', 'cb_other_696'],
      answers,
      {
        'cb_old': 'Old',
        'cb_leaking': 'Leaking',
        'cb_in_disrepair': 'In disrepair',
        'cb_damaged': 'Damaged',
        'cb_other_696': 'Other',
      },
    );
    _addOther(answers, 'cb_other_696', 'et_other_584', defects);
    if (defects.isEmpty) return const [];

    var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_TANK}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{RSR_RT_WATER_TANK}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _insideRoofRepairTimberStructure(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];

    if (status.contains('soon')) {
      final defects = _labelsFor(
        [
          'cb_distorted',
          'cb_damaged',
          'cb_affected_by_wood_boring_insect',
          'cb_rotten',
          'cb_split',
          'cb_missing',
          'cb_inadequate',
          'cb_not_strong_enough',
          'cb_other_904',
        ],
        answers,
        {
          'cb_distorted': 'Distorted',
          'cb_damaged': 'Damaged',
          'cb_affected_by_wood_boring_insect': 'Affected by wood boring insect',
          'cb_rotten': 'Rotten',
          'cb_split': 'Split',
          'cb_missing': 'Missing',
          'cb_inadequate': 'Inadequate',
          'cb_not_strong_enough': 'Not strong enough',
          'cb_other_904': 'Other',
        },
      );
      _addOther(answers, 'cb_other_904', 'et_other_707', defects);
      if (defects.isEmpty) return const [];
      var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_TIMBER_STRUCTURE_SOON}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{RSR_RTS_STATUS_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    if (status.contains('now')) {
      final defects = _labelsFor(
        [
          'cb_badly_distorted',
          'cb_extensively_damaged',
          'cb_extensively_affected_by_wood_boring_insect',
          'cb_badly_rotted',
          'cb_badly_split',
          'cb_largely_missing',
          'cb_very_inadequate',
          'cb_other_445',
        ],
        answers,
        {
          'cb_badly_distorted': 'Badly distorted',
          'cb_extensively_damaged': 'Extensively damaged',
          'cb_extensively_affected_by_wood_boring_insect': 'Extensively affected by wood boring insect',
          'cb_badly_rotted': 'Badly rotted',
          'cb_badly_split': 'Badly split',
          'cb_largely_missing': 'Largely missing',
          'cb_very_inadequate': 'Very inadequate',
          'cb_other_445': 'Other',
        },
      );
      _addOther(answers, 'cb_other_445', 'et_other_351', defects);
      if (defects.isEmpty) return const [];
      var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_TIMBER_STRUCTURE_NOW}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{RSR_RTS_STATUS_NOW_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    return const [];
  }

  List<String> _insideRoofRepairInsectInfestation(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_insect_infestation']);
    if (status.isEmpty) return const [];
    if (status.contains('none')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_INSECT_INFESTATION_NONE}')));
    }
    if (status.contains('minor')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_INSECT_INFESTATION_MINOR}')));
    }
    if (status.contains('severe')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_INSECT_INFESTATION_SEVERE}')));
    }
    return const [];
  }

  List<String> _insideRoofRepairTimberRot(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_insect_infestation']);
    if (status.isEmpty) return const [];
    if (status.contains('minor')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_TIMBER_ROT_NONE}')));
    }
    if (status.contains('severe')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_TIMBER_ROT_SEVERE}')));
    }
    return const [];
  }

  List<String> _insideRoofRepairUnderSizeTimber(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_UNDERSIZE_TIMBER}')));
  }

  List<String> _insideRoofRepairRoofSpreading(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_ROOF_SPREADING}')));
  }

  List<String> _insideRoofRepairHeavyRoof(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_HEAVY_ROOF}')));
  }

  List<String> _insideRoofRepairRemovedChimneyBreast(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('not')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_REMOVED_CHIMNEY_BREAST_NOT_INSPECTED}')));
    }

    if (status.contains('inspected')) {
      final inspectedOk = _isChecked(answers['cb_ok'])
          ? _sub('{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}', '{INSPECTED_OK}')
          : '';
      final poorSupport = _isChecked(answers['cb_poor_support'])
          ? _sub('{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}', '{POOR_SUPPORT}')
          : '';
      final riskToCollapse = _isChecked(answers['cb_risk_of_collapse'])
          ? _sub('{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}', '{RISK_TO_COLLAPSE}')
          : '';
      final dampChimney = _isChecked(answers['cb_damp_chimney'])
          ? _sub('{F_REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}', '{DAMP_CHIMNEY}')
          : '';

      if ([inspectedOk, poorSupport, riskToCollapse, dampChimney].every((value) => value.isEmpty)) {
        return const [];
      }

      var template = _sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_REMOVED_CHIMNEY_BREAST_INSPECTED}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{INSPECTED_OK}', inspectedOk)
          .replaceAll('{POOR_SUPPORT}', poorSupport)
          .replaceAll('{RISK_TO_COLLAPSE}', riskToCollapse)
          .replaceAll('{DAMP_CHIMNEY}', dampChimney);
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _insideRoofRepairPartyWalls(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_insect_infestation']);
    if (condition.isEmpty) return const [];
    if (condition.contains('partly')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_PARTY_WALL_PROBLEM_PARTLY_MISSING}')));
    }
    if (condition.contains('largely')) {
      return _split(_normalize(_sub('{F_ABOUT_ROOF_STRUCTURE}', '{REPAIR_PARTY_WALL_PROBLEM_LARGELY_MISSING}')));
    }
    return const [];
  }

  List<String> _insideRoofNotInspected(Map<String, String> answers) {
    final reasons = _labelsFor(
      ['cb_from_the_outside', 'cb_or_to_the_ceiling_below_the_roof_space', 'cb_other_637'],
      answers,
      {
        'cb_from_the_outside': 'From the outside',
        'cb_or_to_the_ceiling_below_the_roof_space': 'Or to the ceiling below the roof space',
        'cb_other_637': 'Other',
      },
    );
    _addOther(answers, 'cb_other_637', 'et_other_838', reasons);

    String reasonsText = '';
    if (_isChecked(answers['cb_roof_space_not_inspected']) && reasons.isNotEmpty) {
      var template = _sub('{F_ROOF_STRUCTURE_NOT_INSPECTED}', '{ROOF_SPACE_NOT_INSPECTED}');
      if (template.isNotEmpty) {
        reasonsText = template.replaceAll('{RS_NOT_INSPECTED_PROBLEM}', _toWords(reasons).toLowerCase());
      }
    }

    final defects = _labelsFor(
      ['cb_sagging_roof', 'cb_undulating_roof', 'cb_roof_spreading', 'cb_sagging_ceiling', 'cb_other_783'],
      answers,
      {
        'cb_sagging_roof': 'Sagging roof',
        'cb_undulating_roof': 'Undulating roof',
        'cb_roof_spreading': 'Roof spreading',
        'cb_sagging_ceiling': 'Sagging ceiling',
        'cb_other_783': 'Other',
      },
    );
    _addOther(answers, 'cb_other_783', 'et_other_724', defects);

    String defectsText = '';
    if (_isChecked(answers['cb_roof_space_not_inspected_defect']) && defects.isNotEmpty) {
      var template = _sub('{F_ROOF_STRUCTURE_NOT_INSPECTED}', '{DEFECT_NOTED_TO_THE_ROOF}');
      if (template.isNotEmpty) {
        defectsText = template.replaceAll('{RS_NOT_INSPECTED_DEFECT_PROBLEM}', _toWords(defects).toLowerCase());
      }
    }

    if (reasonsText.isEmpty && defectsText.isEmpty) return const [];
    var template = _phraseTexts['{F_ROOF_STRUCTURE_NOT_INSPECTED}'] ?? '';
    if (template.isEmpty) return const [];
    template = template.replaceAll('{ROOF_SPACE_NOT_INSPECTED}', reasonsText).replaceAll('{DEFECT_NOTED_TO_THE_ROOF}', defectsText);
    return _split(_normalize(template));
  }

  List<String> _ceilingsAbout(Map<String, String> answers) {
    final madeUp = (answers['actv_made_up'] ?? '').trim();
    final materials = _labelsFor(
      ['cb_modern_plasterboard', 'cb_plasterboard', 'cb_lath_and_plaster', 'cb_concrete', 'cb_other_406'],
      answers,
      {
        'cb_modern_plasterboard': 'modern plasterboard',
        'cb_plasterboard': 'plasterboard',
        'cb_lath_and_plaster': 'lath and plaster',
        'cb_concrete': 'concrete',
        'cb_other_406': 'other',
      },
    );
    _addOther(answers, 'cb_other_406', 'et_other_339', materials);

    final finishes = _labelsFor(
      ['cb_painted', 'cb_textured', 'cb_paper_lined', 'cb_tiled', 'cb_wallpapered', 'cb_timber_cladded', 'cb_other_388'],
      answers,
      {
        'cb_painted': 'painted',
        'cb_textured': 'textured',
        'cb_paper_lined': 'paper lined',
        'cb_tiled': 'tiled',
        'cb_wallpapered': 'wallpapered',
        'cb_timber_cladded': 'timber cladded',
        'cb_other_388': 'other',
      },
    );
    _addOther(answers, 'cb_other_388', 'et_other_340', finishes);

    final condition = (answers['actv_condition'] ?? '').trim();

    String aboutConstruction = '';
    if (madeUp.isNotEmpty && materials.isNotEmpty) {
      var template = _sub('{F_CEILINGS}', '{ABOUT_CONSTRUCTION}');
      if (template.isNotEmpty) {
        aboutConstruction = template
            .replaceAll('{CE_AC_MADE_UP}', madeUp.toLowerCase())
            .replaceAll('{CE_AC_MATERIAL}', _toWords(materials).toLowerCase());
      }
    }

    String aboutFinishes = '';
    if (finishes.isNotEmpty) {
      var template = _sub('{F_CEILINGS}', '{ABOUT_FINISHES}');
      if (template.isNotEmpty) {
        aboutFinishes = template.replaceAll('{CE_AC_FINISHES_TYPE}', _toWords(finishes).toLowerCase());
      }
    }

    String aboutCondition = '';
    if (condition.isNotEmpty) {
      var template = _sub('{F_CEILINGS}', '{ABOUT_CONDITION}');
      if (template.isNotEmpty) {
        aboutCondition = template.replaceAll('{CE_AC_CONDITION}', condition.toLowerCase());
      }
    }

    final wrapper = _phraseTexts['{F_CEILINGS}'] ?? '';
    if (wrapper.isEmpty) return const [];

    final result = wrapper
        .replaceAll('{STANDARD_TEXT}', '')
        .replaceAll('{ABOUT_CONSTRUCTION}', aboutConstruction)
        .replaceAll('{ABOUT_FINISHES}', aboutFinishes)
        .replaceAll('{ABOUT_CONDITION}', aboutCondition)
        .replaceAll('{CRACKS}', '')
        .replaceAll('{CONTAINS_ASBESTOS}', '')
        .replaceAll('{POLYSTYRENE}', '')
        .replaceAll('{HEAVY_PAPER_LINING}', '')
        .replaceAll('{REPAIRS_CELLINGS_SOON}', '')
        .replaceAll('{REPAIRS_CELLINGS_NOW}', '')
        .replaceAll('{IF_LATH_AND_PLASTER_IS_SELECTED}', '')
        .replaceAll('{IF_TEXTURED_IS_SELECTED}', '')
        .replaceAll('{ORNAMENTAL_PLASTER}', '')
        .replaceAll('{CONDITION_RATING}', '')
        .replaceAll('{NOTES}', '');

    if ([aboutConstruction, aboutFinishes, aboutCondition].every((value) => value.isEmpty)) {
      return const [];
    }
    return _split(_normalize(result));
  }

  List<String> _ceilingsCracks(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_ceiling_junction_with_walls', 'cb_plasterboard_joints', 'cb_ceiling_surfaces', 'cb_other_467'],
      answers,
      {
        'cb_ceiling_junction_with_walls': 'ceiling junction with walls',
        'cb_plasterboard_joints': 'plasterboard joints',
        'cb_ceiling_surfaces': 'ceiling surfaces',
        'cb_other_467': 'other',
      },
    );
    _addOther(answers, 'cb_other_467', 'et_other_311', items);
    if (items.isEmpty) return const [];

    var template = _sub('{F_CEILINGS}', '{CRACKS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CE_CR_NOTED}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _ceilingsContainsAsbestos(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_lounge', 'cb_bedroom', 'cb_kitchen', 'cb_bathroom', 'cb_Property', 'cb_other_525'],
      answers,
      {
        'cb_lounge': 'lounge',
        'cb_bedroom': 'bedroom',
        'cb_kitchen': 'kitchen',
        'cb_bathroom': 'bathroom',
        'cb_Property': 'property',
        'cb_other_525': 'other',
      },
    );
    _addOther(answers, 'cb_other_525', 'et_other_856', items);
    if (items.isEmpty) return const [];

    var template = _sub('{F_CEILINGS}', '{CONTAINS_ASBESTOS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CE_CA_LOCATION}', _toWords(items).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _ceilingsPolystyrene(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_CEILINGS}', '{POLYSTYRENE}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _ceilingsHeavyPaper(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_CEILINGS}', '{HEAVY_PAPER_LINING}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _ceilingsRepairCeilings(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];

    if (status.contains('now')) {
      final locations = _labelsFor(
        ['cb_lounge', 'cb_bedroom', 'cb_kitchen', 'cb_bathroom', 'cb_other_1075'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_bedroom': 'bedroom',
          'cb_kitchen': 'kitchen',
          'cb_bathroom': 'bathroom',
          'cb_other_1075': 'other',
        },
      );
      _addOther(answers, 'cb_other_1075', 'et_other_505', locations);

      final defects = _labelsFor(
        [
          'cb_badly_cracked',
          'cb_very_loose',
          'cb_stained_heavily_with_damp',
          'cb_are_unstable_and_may_fall',
          'cb_have_polystyrene_tiles',
          'cb_contain_asbestos_material',
          'cb_other_537',
        ],
        answers,
        {
          'cb_badly_cracked': 'badly cracked',
          'cb_very_loose': 'very loose',
          'cb_stained_heavily_with_damp': 'stained heavily with damp',
          'cb_are_unstable_and_may_fall': 'are unstable and may fall',
          'cb_have_polystyrene_tiles': 'have polystyrene tiles',
          'cb_contain_asbestos_material': 'contain asbestos material',
          'cb_other_537': 'other',
        },
      );
      _addOther(answers, 'cb_other_537', 'et_other_913', defects);

      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_CEILINGS}', '{REPAIRS_CELLINGS_NOW}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{CER_RC_NOW_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{CER_RC_NOW_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    if (status.contains('soon')) {
      final locations = _labelsFor(
        ['cb_lounge_48', 'cb_bedroom_61', 'cb_kitchen_100', 'cb_bathroom_55', 'cb_other_802'],
        answers,
        {
          'cb_lounge_48': 'lounge',
          'cb_bedroom_61': 'bedroom',
          'cb_kitchen_100': 'kitchen',
          'cb_bathroom_55': 'bathroom',
          'cb_other_802': 'other',
        },
      );
      _addOther(answers, 'cb_other_802', 'et_other_788', locations);

      final defects = _labelsFor(
        ['cb_missing_in_places_15', 'cb_loose_91', 'cb_uneven_60', 'cb_sagging_45', 'cb_bowed_99', 'cb_stained_39', 'cb_other_442'],
        answers,
        {
          'cb_missing_in_places_15': 'missing in places',
          'cb_loose_91': 'loose',
          'cb_uneven_60': 'uneven',
          'cb_sagging_45': 'sagging',
          'cb_bowed_99': 'bowed',
          'cb_stained_39': 'stained',
          'cb_other_442': 'other',
        },
      );
      _addOther(answers, 'cb_other_442', 'et_other_497', defects);

      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_CEILINGS}', '{REPAIRS_CELLINGS_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{CER_RC_SOON_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{CER_RC_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _ceilingsOrnamentalPlaster(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_very_loose_93', 'cb_badly_cracked_88', 'cb_partly_missing_35', 'cb_unstable_and_may_fall_54', 'cb_other_945'],
      answers,
      {
        'cb_very_loose_93': 'very loose',
        'cb_badly_cracked_88': 'badly cracked',
        'cb_partly_missing_35': 'partly missing',
        'cb_unstable_and_may_fall_54': 'unstable and may fall',
        'cb_other_945': 'other',
      },
    );
    _addOther(answers, 'cb_other_945', 'et_other_693', defects);
    if (defects.isEmpty) return const [];

    var template = _sub('{F_CEILINGS}', '{ORNAMENTAL_PLASTER}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{CER_OP_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _ceilingsNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_CEILINGS}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _floorsOlderProperties(Map<String, String> answers) {
    if (!_isChecked(answers['cb_floor_older_properties'])) return const [];
    final template = _sub('{F_FLOORS}', '{TIMBER_FLOOR_OLDER_PROPERTIES}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _floorsAbout(Map<String, String> answers) {
    final construction = _cleanLower(answers['actv_construction']);
    String constructionText = '';
    if (construction.contains('all solid')) {
      constructionText = _sub('{F_FLOORS}', '{FLOOR_CONSTRUCTION_ALL_SOLID}');
    } else if (construction.contains('all suspended')) {
      constructionText = _sub('{F_FLOORS}', '{FLOOR_CONSTRUCTION_ALL_SUSPENDED}');
    } else if (construction.contains('mixture')) {
      final mixture = _labelsFor(
        ['cb_solid', 'cb_suspended_timber', 'cb_oversite_concrete', 'cb_suspended_beam_and_block', 'cb_other_989'],
        answers,
        {
          'cb_solid': 'solid',
          'cb_suspended_timber': 'suspended timber',
          'cb_oversite_concrete': 'oversite concrete',
          'cb_suspended_beam_and_block': 'suspended beam and block',
          'cb_other_989': 'other',
        },
      );
      _addOther(answers, 'cb_other_989', 'et_other_424', mixture);
      if (mixture.isNotEmpty) {
        var template = _sub('{F_FLOORS}', '{FLOOR_CONSTRUCTION_MIXTURE_OF}');
        if (template.isNotEmpty) {
          constructionText = template.replaceAll('{FL_AF_MIXTURE_OF}', _toWords(mixture).toLowerCase());
        }
      }
    }

    String coveringText = '';
    final coveredWith = _cleanLower(answers['actv_covered_with']);
    final coveringIncludes = _labelsFor(
      [
        'cb_floorboards',
        'cb_carpets',
        'cb_laminate_flooring',
        'cb_wood_flooring',
        'cb_clay_tiles',
        'cb_ceramic_tiles',
        'cb_vinyl_tiles',
        'cb_vinyl_sheet',
        'cb_chipboards',
        'cb_other_837',
      ],
      answers,
      {
        'cb_floorboards': 'floorboards',
        'cb_carpets': 'carpets',
        'cb_laminate_flooring': 'laminate flooring',
        'cb_wood_flooring': 'wood flooring',
        'cb_clay_tiles': 'clay tiles',
        'cb_ceramic_tiles': 'ceramic tiles',
        'cb_vinyl_tiles': 'vinyl tiles',
        'cb_vinyl_sheet': 'vinyl sheet',
        'cb_chipboards': 'chipboards',
        'cb_other_837': 'other',
      },
    );
    _addOther(answers, 'cb_other_837', 'et_other_882', coveringIncludes);
    if (coveredWith.isNotEmpty && coveringIncludes.isNotEmpty) {
      var template = _sub('{F_FLOORS}', '{FLOOR_COVERING}');
      if (template.isNotEmpty) {
        coveringText = template
            .replaceAll('{FL_AF_COVERED_WITH}', coveredWith)
            .replaceAll('{FL_AF_COVERING_INCLUDES}', _toWords(coveringIncludes).toLowerCase());
      }
    }

    String conditionText = '';
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub('{F_FLOORS}', '{FLOOR_CONDITION}');
      if (template.isNotEmpty) {
        conditionText = template.replaceAll('{FL_AF_CONDITION}', condition);
      }
    }

    final standardText = _sub('{F_FLOORS}', '{STANDARD_TEXT}');
    final standardText2 = _sub('{F_FLOORS}', '{STANDARD_TEXT_2}');
    final wrapper = _phraseTexts['{F_FLOORS}'] ?? '';
    if (wrapper.isEmpty) return const [];

    final result = wrapper
        .replaceAll('{STANDARD_TEXT}', standardText)
        .replaceAll('{FLOOR_CONSTRUCTION}', constructionText)
        .replaceAll('{FLOOR_COVERING}', coveringText)
        .replaceAll('{FLOOR_CONDITION}', conditionText)
        .replaceAll('{CREAKING}', '')
        .replaceAll('{TILES_CONDITION_OK}', '')
        .replaceAll('{TILES_CONDITION_CRACKED}', '')
        .replaceAll('{LOOSE_FLOORBOARDS}', '')
        .replaceAll('{TIMBER_DECAY}', '')
        .replaceAll('{TIMBER_INFESTAION}', '')
        .replaceAll('{DAMPNESS}', '')
        .replaceAll('{FLOOR_VENTILATION}', '')
        .replaceAll('{TIMBER_FLOOR_OLDER_PROPERTIES}', '')
        .replaceAll('{FLOOR_REPAIR_SOON}', '')
        .replaceAll('{FLOOR_REPAIR_NOW}', '')
        .replaceAll('{REPAIR_LAMINATE}', '')
        .replaceAll('{REPAIR_FLOOR_VIBRATION}', '')
        .replaceAll('{REPAIR_SLOPING_FLOOR}', '')
        .replaceAll('{REPAIR_UNEVEN_FLOOR}', '')
        .replaceAll('{STANDARD_TEXT_2}', standardText2)
        .replaceAll('{CONDITION_RATING}', '')
        .replaceAll('{NOTES}', '');

    if ([constructionText, coveringText, conditionText, standardText, standardText2].every((v) => v.isEmpty)) {
      return const [];
    }
    return _split(_normalize(result));
  }

  List<String> _floorsCreaking(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('none')) {
      final template = _sub('{F_FLOORS}', '{CREAKING_NONE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (status.contains('noted')) {
      final items = _labelsFor(
        ['cb_lounge', 'cb_bedroom', 'cb_kitchen'],
        answers,
        {
          'cb_lounge': 'to parts of the floors',
          'cb_bedroom': 'stairs',
          'cb_kitchen': 'minor floor unevenness',
        },
      );
      if (items.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{CREAKING_NOTED}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{FL_CR_STATUS_NOTED}', _toWords(items).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsTiles(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_ok'])) {
      final locations = _labelsFor(
        ['cb_kitchen', 'cb_bathroom_s', 'cb_toilet_s', 'cb_utility_room', 'cb_other_240'],
        answers,
        {
          'cb_kitchen': 'kitchen',
          'cb_bathroom_s': 'bathroom',
          'cb_toilet_s': 'toilet',
          'cb_utility_room': 'utility room',
          'cb_other_240': 'other',
        },
      );
      _addOther(answers, 'cb_other_240', 'et_other_392', locations);
      if (locations.isNotEmpty) {
        var template = _sub('{F_FLOORS}', '{TILES_CONDITION_OK}');
        if (template.isNotEmpty) {
          template = template.replaceAll('{FL_TILES_OK_LOCATION}', _toWords(locations).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }
    if (_isChecked(answers['cb_cracked'])) {
      final locations = _labelsFor(
        ['cb_kitchen_29', 'cb_bathroom_s_41', 'cb_toilet_s_101', 'cb_utility_room_22', 'cb_other_933'],
        answers,
        {
          'cb_kitchen_29': 'kitchen',
          'cb_bathroom_s_41': 'bathroom',
          'cb_toilet_s_101': 'toilet',
          'cb_utility_room_22': 'utility room',
          'cb_other_933': 'other',
        },
      );
      _addOther(answers, 'cb_other_933', 'et_other_885', locations);
      if (locations.isNotEmpty) {
        var template = _sub('{F_FLOORS}', '{TILES_CONDITION_CRACKED}');
        if (template.isNotEmpty) {
          template = template.replaceAll('{FL_TILES_CRACKED_LOCATION}', _toWords(locations).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }
    return phrases;
  }

  List<String> _floorsLooseFloorboards(Map<String, String> answers) {
    if (!_isChecked(answers['cb_loose_floorboards'])) return const [];
    final template = _sub('{F_FLOORS}', '{LOOSE_FLOORBOARDS}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _floorsTimberDecay(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('none')) {
      final template = _sub('{F_FLOORS}', '{TIMBER_DECAY_NONE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (status.contains('investigate')) {
      final locations = _labelsFor(
        ['cb_staircase_timber', 'cb_roof_timber_to_garage', 'cb_floor_joists_in_the_basement', 'cb_other_802'],
        answers,
        {
          'cb_staircase_timber': 'staircase timber',
          'cb_roof_timber_to_garage': 'roof timber to garage',
          'cb_floor_joists_in_the_basement': 'floor joists in the basement',
          'cb_other_802': 'other',
        },
      );
      _addOther(answers, 'cb_other_802', 'et_other_592', locations);
      if (locations.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{TIMBER_DECAY_INVESTIGATE}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{FL_TD_INVESTIGATE_LOCATION}', _toWords(locations).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsTimberInfestation(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('none')) {
      final template = _sub('{F_FLOORS}', '{TIMBER_INFESTAION_NONE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (status.contains('investigate')) {
      final locations = _labelsFor(
        ['cb_staircase_timber', 'cb_roof_timber_to_garage', 'cb_floor_joists_in_the_basement', 'cb_other_965'],
        answers,
        {
          'cb_staircase_timber': 'staircase timber',
          'cb_roof_timber_to_garage': 'roof timber to garage',
          'cb_floor_joists_in_the_basement': 'floor joists in the basement',
          'cb_other_965': 'other',
        },
      );
      _addOther(answers, 'cb_other_965', 'et_other_529', locations);
      if (locations.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{TIMBER_INFESTAION_INVESTIGATE}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{FL_TI_INVESTIGATE_LOCATION}', _toWords(locations).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsDampness(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('known')) {
      final locations = _labelsFor(
        ['cb_kitchen', 'cb_bathroom_s', 'cb_toilet_s', 'cb_utility_room', 'cb_other_240'],
        answers,
        {
          'cb_kitchen': 'kitchen',
          'cb_bathroom_s': 'bathroom',
          'cb_toilet_s': 'toilet',
          'cb_utility_room': 'utility room',
          'cb_other_240': 'other',
        },
      );
      _addOther(answers, 'cb_other_240', 'et_other_392', locations);
      final causes = _labelsFor(
        ['cb_faulty_plumbing', 'cb_bathtub_spillage', 'cb_leaking_sealants', 'cb_other_215'],
        answers,
        {
          'cb_faulty_plumbing': 'faulty plumbing',
          'cb_bathtub_spillage': 'bathtub spillage',
          'cb_leaking_sealants': 'leaking sealants',
          'cb_other_215': 'other',
        },
      );
      _addOther(answers, 'cb_other_215', 'et_other_358', causes);
      if (locations.isEmpty || causes.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{DAMPNESS_KNOWN_CAUSE}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FL_DAMP_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{FL_DAMP_CAUSED_BY}', _toWords(causes).toLowerCase());
      return _split(_normalize(template));
    }
    if (status.contains('unknown')) {
      final template = _sub('{F_FLOORS}', '{DAMPNESS_UNKNOWN_CAUSE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsVentilation(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    if (condition.contains('ok')) {
      final template = _sub('{F_FLOORS}', '{FLOOR_VENTILATION_OK}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (condition.contains('poor')) {
      final problem = (answers['et_describe_problem'] ?? '').trim();
      if (problem.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{FLOOR_VENTILATION_POOR}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{FL_FV_POOR_PROBLEM}', problem.toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsRepairFloorRepair(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_repair_type']);
    if (status.isEmpty) return const [];

    if (status.contains('now')) {
      final locations = _labelsFor(
        ['cb_lounge', 'cb_bedroom', 'cb_kitchen', 'cb_hall', 'cb_other_221'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_bedroom': 'bedroom',
          'cb_kitchen': 'kitchen',
          'cb_hall': 'hall',
          'cb_other_221': 'other',
        },
      );
      _addOther(answers, 'cb_other_221', 'et_other_911', locations);
      final defects = _labelsFor(
        [
          'cb_poorly_supported',
          'cb_uneven',
          'cb_springy',
          'cb_loose',
          'cb_incomplete',
          'cb_damp',
          'cb_insect_infested',
          'cb_rotten',
          'cb_poorly_ventilated',
          'cb_other_565',
        ],
        answers,
        {
          'cb_poorly_supported': 'poorly supported',
          'cb_uneven': 'uneven',
          'cb_springy': 'springy',
          'cb_loose': 'loose',
          'cb_incomplete': 'incomplete',
          'cb_damp': 'damp',
          'cb_insect_infested': 'insect infested',
          'cb_rotten': 'rotten',
          'cb_poorly_ventilated': 'poorly ventilated',
          'cb_other_565': 'other',
        },
      );
      _addOther(answers, 'cb_other_565', 'et_other_232', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{FLOOR_REPAIR_NOW}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FLR_FR_NOW_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{FLR_FR_NOW_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    if (status.contains('soon')) {
      final locations = _labelsFor(
        ['cb_lounge_75', 'cb_bedroom_33', 'cb_kitchen_26', 'cb_hall_20', 'cb_other_747'],
        answers,
        {
          'cb_lounge_75': 'lounge',
          'cb_bedroom_33': 'bedroom',
          'cb_kitchen_26': 'kitchen',
          'cb_hall_20': 'hall',
          'cb_other_747': 'other',
        },
      );
      _addOther(answers, 'cb_other_747', 'et_other_772', locations);
      final defects = _labelsFor(
        ['cb_broken_24', 'cb_poorly_supported_78', 'cb_uneven_99', 'cb_springy_31', 'cb_loose_31', 'cb_sloping_28', 'cb_other_defect_soon'],
        answers,
        {
          'cb_broken_24': 'broken',
          'cb_poorly_supported_78': 'poorly supported',
          'cb_uneven_99': 'uneven',
          'cb_springy_31': 'springy',
          'cb_loose_31': 'loose',
          'cb_sloping_28': 'sloping',
          'cb_other_defect_soon': 'other',
        },
      );
      _addOther(answers, 'cb_other_defect_soon', 'et_other_945', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{FLOOR_REPAIR_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FLR_FR_SOON_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{FLR_FR_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    return const [];
  }

  List<String> _floorsRepairLaminate(Map<String, String> answers) {
    final materials = _labelsFor(
      ['cb_laminate', 'cb_wood'],
      answers,
      {
        'cb_laminate': 'laminate',
        'cb_wood': 'wood',
      },
    );
    final locations = _labelsFor(
      ['cb_kitchen', 'cb_bathroom', 'cb_utility_room', 'cb_bedrooms', 'cb_other_345'],
      answers,
      {
        'cb_kitchen': 'kitchen',
        'cb_bathroom': 'bathroom',
        'cb_utility_room': 'utility room',
        'cb_bedrooms': 'bedrooms',
        'cb_other_345': 'other',
      },
    );
    _addOther(answers, 'cb_other_345', 'et_other_711', locations);
    final defects = _labelsFor(
      ['cb_worn', 'cb_damaged', 'cb_badly_fitted', 'cb_incomplete', 'cb_broken', 'cb_lifted', 'cb_other_1109'],
      answers,
      {
        'cb_worn': 'worn',
        'cb_damaged': 'damaged',
        'cb_badly_fitted': 'badly fitted',
        'cb_incomplete': 'incomplete',
        'cb_broken': 'broken',
        'cb_lifted': 'lifted',
        'cb_other_1109': 'other',
      },
    );
    _addOther(answers, 'cb_other_1109', 'et_other_588', defects);
    if (materials.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_FLOORS}', '{REPAIR_LAMINATE}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{FLR_LWF_MATERIAL}', _toWords(materials).toLowerCase())
        .replaceAll('{FLR_LWF_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{FLR_LWF_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _floorsRepairVibration(Map<String, String> answers) {
    if (!_isChecked(answers['cb_floor_vibration_excessive'])) return const [];
    final template = _sub('{F_FLOORS}', '{REPAIR_FLOOR_VIBRATION}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _floorsRepairSloping(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('no issue')) {
      final locations = _labelsFor(
        ['cb_lounge', 'cb_hall', 'cb_kitchen', 'cb_bathroom', 'cb_utility_room', 'cb_bedrooms', 'cb_other_856'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_hall': 'hall',
          'cb_kitchen': 'kitchen',
          'cb_bathroom': 'bathroom',
          'cb_utility_room': 'utility room',
          'cb_bedrooms': 'bedrooms',
          'cb_other_856': 'other',
        },
      );
      _addOther(answers, 'cb_other_856', 'et_other_113', locations);
      if (locations.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{REPAIR_SLOPING_FLOOR_NO_ISSUE}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{FLR_SF_LOCATION}', _toWords(locations).toLowerCase());
      return _split(_normalize(template));
    }
    if (status.contains('investigate')) {
      final template = _sub('{F_FLOORS}', '{REPAIR_SLOPING_FLOOR_INVESTIGATE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsRepairUneven(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('minor')) {
      final template = _sub('{F_FLOORS}', '{REPAIR_UNEVEN_FLOOR_MINOR}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (status.contains('repair')) {
      final locations = _labelsFor(
        ['cb_lounge', 'cb_hall', 'cb_kitchen', 'cb_bathroom', 'cb_utility_room', 'cb_bedrooms', 'cb_other_839'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_hall': 'hall',
          'cb_kitchen': 'kitchen',
          'cb_bathroom': 'bathroom',
          'cb_utility_room': 'utility room',
          'cb_bedrooms': 'bedrooms',
          'cb_other_839': 'other',
        },
      );
      _addOther(answers, 'cb_other_839', 'et_other_349', locations);
      final defects = _labelsFor(
        ['cb_very_uneven', 'cb_largely_dipping_loose', 'cb_lifting', 'cb_bowing', 'cb_sloping', 'cb_damp', 'cb_other_479'],
        answers,
        {
          'cb_very_uneven': 'very uneven',
          'cb_largely_dipping_loose': 'largely dipping/loose',
          'cb_lifting': 'lifting',
          'cb_bowing': 'bowing',
          'cb_sloping': 'sloping',
          'cb_damp': 'damp',
          'cb_other_479': 'other',
        },
      );
      _addOther(answers, 'cb_other_479', 'et_other_389', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_FLOORS}', '{REPAIR_UNEVEN_FLOOR_REPAIR}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FLR_UF_REPAIR_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{FLR_UF_REPAIR_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _floorsNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspetcted'])) return const [];
    final template = _sub('{F_FLOORS}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
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

  List<String> _fireplacesOpenFire(Map<String, String> answers) {
    return _fireplacesType(
      answers,
      locationKey: '{AN_OPEN_FIRE_LOCATION}',
      conditionKey: '{AN_OPEN_FIRE_CONDITION}',
      locationToken: '{FAC_FP_AOF_LOCATION}',
      conditionToken: '{FAC_FP_AOF_CONDITION}',
    );
  }

  List<String> _fireplacesGasFire(Map<String, String> answers) {
    return _fireplacesType(
      answers,
      locationKey: '{GAS_FIRE_LOCATION}',
      conditionKey: '{GAS_FIRE_CONDITION}',
      locationToken: '{FAC_FP_GF_LOCATION}',
      conditionToken: '{FAC_FP_GF_CONDITION}',
    );
  }

  List<String> _fireplacesImitationSystem(Map<String, String> answers) {
    return _fireplacesType(
      answers,
      locationKey: '{IMITATION_SYSTEM_LOCATION}',
      conditionKey: '{IMITATION_SYSTEM_CONDITION}',
      locationToken: '{FAC_FP_LS_LOCATION}',
      conditionToken: '{FAC_FP_LS_CONDITION}',
    );
  }

  List<String> _fireplacesWoodBurningStove(Map<String, String> answers) {
    return _fireplacesType(
      answers,
      locationKey: '{WOOD_BURNING_STOVE_LOCATION}',
      conditionKey: '{WOOD_BURNING_STOVE_CONDITION}',
      locationToken: '{FAC_FP_WBS_LOCATION}',
      conditionToken: '{FAC_FP_WBS_CONDITION}',
    );
  }

  List<String> _fireplacesElectricFire(Map<String, String> answers) {
    return _fireplacesType(
      answers,
      locationKey: '{ELECTRIC_FIRE_LOCATION}',
      conditionKey: '{ELECTRIC_FIRE_CONDITION}',
      locationToken: '{FAC_FP_EF_LOCATION}',
      conditionToken: '{FAC_FP_EF_CONDITION}',
    );
  }

  List<String> _fireplacesOther(Map<String, String> answers) {
    final phrases = <String>[];
    final locations = _fireplacesLocations(answers);
    final name = (answers['other'] ?? '').trim();
    if (locations.isNotEmpty) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{OTHER_LOCATION}');
      if (template.isNotEmpty) {
        template = template
            .replaceAll('{FAC_FP_OTH_LOCATION}', _toWords(locations).toLowerCase())
            .replaceAll('{FAC_FP_OTH_NAME}', name.toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{OTHER_CONDITION}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{FAC_FP_OTH_CONDITION}', condition);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _fireplacesRepairFireplaces(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('repair soon')) {
      final floorLocation = _labelsFor(
        ['cb_ground', 'cb_first', 'cb_second', 'cb_other_270'],
        answers,
        {
          'cb_ground': 'ground',
          'cb_first': 'first',
          'cb_second': 'second',
          'cb_other_270': 'other',
        },
      );
      _addOther(answers, 'cb_other_270', 'et_other_226', floorLocation);
      final fireplaceLocation = _labelsFor(
        ['cb_lounge', 'cb_reception', 'cb_dining_room', 'cb_kitchen', 'cb_bedroom', 'cb_other_178'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_reception': 'reception',
          'cb_dining_room': 'dining room',
          'cb_kitchen': 'kitchen',
          'cb_bedroom': 'bedroom',
          'cb_other_178': 'other',
        },
      );
      _addOther(answers, 'cb_other_178', 'et_other_754', fireplaceLocation);
      final defects = _labelsFor(
        ['cb_damaged', 'cb_incomplete', 'cb_missing_part_s', 'cb_obstructed', 'cb_other_399'],
        answers,
        {
          'cb_damaged': 'damaged',
          'cb_incomplete': 'incomplete',
          'cb_missing_part_s': 'missing parts',
          'cb_obstructed': 'obstructed',
          'cb_other_399': 'other',
        },
      );
      _addOther(answers, 'cb_other_399', 'et_other_512', defects);
      if (floorLocation.isEmpty || fireplaceLocation.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{REPAIR_FIREPLACES_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FACR_RF_SOON_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
          .replaceAll('{FACR_RF_SOON_FIREPLACE_LOCATION}', _toWords(fireplaceLocation).toLowerCase())
          .replaceAll('{FACR_RF_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    if (status.contains('repair now')) {
      final floorLocation = _labelsFor(
        ['cb_ground_76', 'cb_first_69', 'cb_second_83', 'cb_other_354'],
        answers,
        {
          'cb_ground_76': 'ground',
          'cb_first_69': 'first',
          'cb_second_83': 'second',
          'cb_other_354': 'other',
        },
      );
      _addOther(answers, 'cb_other_354', 'et_other_883', floorLocation);
      final fireplaceLocation = _labelsFor(
        ['cb_lounge_48', 'cb_reception_77', 'cb_dining_room_66', 'cb_kitchen_37', 'cb_bedroom_53', 'cb_other_373'],
        answers,
        {
          'cb_lounge_48': 'lounge',
          'cb_reception_77': 'reception',
          'cb_dining_room_66': 'dining room',
          'cb_kitchen_37': 'kitchen',
          'cb_bedroom_53': 'bedroom',
          'cb_other_373': 'other',
        },
      );
      _addOther(answers, 'cb_other_373', 'et_other_869', fireplaceLocation);
      final defects = _labelsFor(
        ['cb_badly_damaged_27', 'cb_a_safety_hazard_25', 'cb_other_773'],
        answers,
        {
          'cb_badly_damaged_27': 'badly damaged',
          'cb_a_safety_hazard_25': 'a safety hazard',
          'cb_other_773': 'other',
        },
      );
      _addOther(answers, 'cb_other_773', 'et_other_122', defects);
      if (floorLocation.isEmpty || fireplaceLocation.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{REPAIR_FIREPLACES_NOW}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FACR_RF_NOW_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
          .replaceAll('{FACR_RF_NOW_FIREPLACE_LOCATION}', _toWords(fireplaceLocation).toLowerCase())
          .replaceAll('{FACR_RF_NOW_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _fireplacesDamagedGrate(Map<String, String> answers) {
    final floorLocation = _labelsFor(
      ['cb_ground', 'cb_first', 'cb_second', 'cb_other_374'],
      answers,
      {
        'cb_ground': 'ground',
        'cb_first': 'first',
        'cb_second': 'second',
        'cb_other_374': 'other',
      },
    );
    _addOther(answers, 'cb_other_374', 'et_other_458', floorLocation);
    final fireplaceLocation = _labelsFor(
      ['cb_lounge', 'cb_reception', 'cb_dining_room', 'cb_kitchen', 'cb_bedroom', 'cb_other_514'],
      answers,
      {
        'cb_lounge': 'lounge',
        'cb_reception': 'reception',
        'cb_dining_room': 'dining room',
        'cb_kitchen': 'kitchen',
        'cb_bedroom': 'bedroom',
        'cb_other_514': 'other',
      },
    );
    _addOther(answers, 'cb_other_514', 'et_other_445', fireplaceLocation);
    if (floorLocation.isEmpty || fireplaceLocation.isEmpty) return const [];
    var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{DAMAGED_GATE}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{FACR_DG_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
        .replaceAll('{FACR_DG_FIREPLACE_LOCATION}', _toWords(fireplaceLocation).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _fireplacesDamagedSurround(Map<String, String> answers) {
    final floorLocation = _labelsFor(
      ['cb_ground', 'cb_first', 'cb_second', 'cb_other_373'],
      answers,
      {
        'cb_ground': 'ground',
        'cb_first': 'first',
        'cb_second': 'second',
        'cb_other_373': 'other',
      },
    );
    _addOther(answers, 'cb_other_373', 'et_other_341', floorLocation);
    final fireplaceLocation = _labelsFor(
      ['cb_lounge', 'cb_reception', 'cb_dining_room', 'cb_kitchen', 'cb_bedroom', 'cb_other_1099'],
      answers,
      {
        'cb_lounge': 'lounge',
        'cb_reception': 'reception',
        'cb_dining_room': 'dining room',
        'cb_kitchen': 'kitchen',
        'cb_bedroom': 'bedroom',
        'cb_other_1099': 'other',
      },
    );
    _addOther(answers, 'cb_other_1099', 'et_other_125', fireplaceLocation);
    if (floorLocation.isEmpty || fireplaceLocation.isEmpty) return const [];
    var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{DAMAGED_SURROUND}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{FACR_DS_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
        .replaceAll('{FACR_DS_FIREPLACE_LOCATION}', _toWords(fireplaceLocation).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _fireplacesBlockedFireplace(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status.contains('unvented')) {
      final floorLocation = _labelsFor(
        ['cb_ground', 'cb_first', 'cb_second', 'cb_other_740'],
        answers,
        {
          'cb_ground': 'ground',
          'cb_first': 'first',
          'cb_second': 'second',
          'cb_other_740': 'other',
        },
      );
      _addOther(answers, 'cb_other_740', 'et_other_445', floorLocation);
      final fireplaceLocation = _labelsFor(
        ['cb_lounge', 'cb_reception', 'cb_dining_room', 'cb_kitchen', 'cb_bedroom', 'cb_other_369'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_reception': 'reception(s)',
          'cb_dining_room': 'dining room',
          'cb_kitchen': 'kitchen',
          'cb_bedroom': 'bedroom(s)',
          'cb_other_369': 'other',
        },
      );
      _addOther(answers, 'cb_other_369', 'et_other_897', fireplaceLocation);
      if (floorLocation.isEmpty || fireplaceLocation.isEmpty) return const [];
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{BLOCKED_FIREPLACE_UNVENTED}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FAC_BF_UNVENTED_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
          .replaceAll('{FAC_BF_UNVENTED_FIREPLACE_LOCATION}', _toWords(fireplaceLocation).toLowerCase());
      return _split(_normalize(template));
    }
    if (status.contains('vented')) {
      final floorLocation = _labelsFor(
        ['cb_ground_69', 'cb_first_23', 'cb_second_44', 'cb_other_1068'],
        answers,
        {
          'cb_ground_69': 'ground',
          'cb_first_23': 'first',
          'cb_second_44': 'second',
          'cb_other_1068': 'other',
        },
      );
      _addOther(answers, 'cb_other_1068', 'et_other_292', floorLocation);
      final fireplaceLocation = _labelsFor(
        ['cb_lounge_91', 'cb_reception_23', 'cb_dining_room_58', 'cb_kitchen_85', 'cb_bedroom_80', 'cb_other_437'],
        answers,
        {
          'cb_lounge_91': 'lounge',
          'cb_reception_23': 'reception(s)',
          'cb_dining_room_58': 'dining room',
          'cb_kitchen_85': 'kitchen',
          'cb_bedroom_80': 'bedroom(s)',
          'cb_other_437': 'other',
        },
      );
      _addOther(answers, 'cb_other_437', 'et_other_290', fireplaceLocation);
      if (floorLocation.isEmpty || fireplaceLocation.isEmpty) return const [];
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{BLOCKED_FIREPLACE_VENTED}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FAC_BF_VENTED_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
          .replaceAll('{FAC_BF_VENTED_FIREPLACE_LOCATION}', _toWords(fireplaceLocation).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _fireplacesRemovedCb(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    if (condition.contains('ok')) {
      final floorLocation = _labelsFor(
        ['cb_ground', 'cb_first', 'cb_second', 'cb_other_1010'],
        answers,
        {
          'cb_ground': 'ground',
          'cb_first': 'first',
          'cb_second': 'second',
          'cb_other_1010': 'other',
        },
      );
      _addOther(answers, 'cb_other_1010', 'et_other_848', floorLocation);
      final chimneyLocation = _labelsFor(
        ['cb_lounge', 'cb_reception', 'cb_dining_room', 'cb_kitchen', 'cb_bedroom', 'cb_other_799'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_reception': 'reception',
          'cb_dining_room': 'dining room',
          'cb_kitchen': 'kitchen',
          'cb_bedroom': 'bedroom',
          'cb_other_799': 'other',
        },
      );
      _addOther(answers, 'cb_other_799', 'et_other_725', chimneyLocation);
      if (floorLocation.isEmpty || chimneyLocation.isEmpty) return const [];
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{REMOVED_CB_OK}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FAC_RCB_OK_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
          .replaceAll('{FAC_RCB_OK_CHIMNEY_LOCATION}', _toWords(chimneyLocation).toLowerCase());
      return _split(_normalize(template));
    }
    if (condition.contains('problem')) {
      final floorLocation = _labelsFor(
        ['cb_ground_75', 'cb_first_74', 'cb_second_52', 'cb_other_1070'],
        answers,
        {
          'cb_ground_75': 'ground',
          'cb_first_74': 'first',
          'cb_second_52': 'second',
          'cb_other_1070': 'other',
        },
      );
      _addOther(answers, 'cb_other_1070', 'et_other_394', floorLocation);
      final chimneyLocation = _labelsFor(
        ['cb_lounge_61', 'cb_reception_57', 'cb_dining_room_24', 'cb_kitchen_80', 'cb_bedroom_53', 'cb_other_882'],
        answers,
        {
          'cb_lounge_61': 'lounge',
          'cb_reception_57': 'reception',
          'cb_dining_room_24': 'dining room',
          'cb_kitchen_80': 'kitchen',
          'cb_bedroom_53': 'bedroom',
          'cb_other_882': 'other',
        },
      );
      _addOther(answers, 'cb_other_882', 'et_other_820', chimneyLocation);
      final defects = _labelsFor(
        ['cb_damaged', 'cb_cracked', 'cb_distorted', 'cb_other_634'],
        answers,
        {
          'cb_damaged': 'damaged',
          'cb_cracked': 'cracked',
          'cb_distorted': 'distorted',
          'cb_other_634': 'other',
        },
      );
      _addOther(answers, 'cb_other_634', 'et_other_630', defects);
      if (floorLocation.isEmpty || chimneyLocation.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{REMOVED_CB_PROBLEM_NOTED}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FAC_RCB_PROBLEM_FLOOR_LOCATION}', _toWords(floorLocation).toLowerCase())
          .replaceAll('{FAC_RCB_PROBLEM_CHIMNEY_LOCATION}', _toWords(chimneyLocation).toLowerCase())
          .replaceAll('{FAC_RCB_PROBLEM_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _fireplacesBoilerFlue(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    final locations = _labelsFor(
      ['cb_ground', 'cb_first', 'cb_second', 'cb_garage', 'cb_other_1010'],
      answers,
      {
        'cb_ground': 'kitchen',
        'cb_first': 'bedroom(s)',
        'cb_second': 'airing cupboard',
        'cb_garage': 'garage',
        'cb_other_1010': 'other',
      },
    );
    _addOther(answers, 'cb_other_1010', 'et_other_848', locations);
    final discharge = _cleanLower(answers['actv_flue_discharges_through']);
    if (locations.isEmpty || discharge.isEmpty || condition.isEmpty) return const [];
    if (condition.contains('obstructed')) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{BOILER_FLUE_OBSTRUCTED}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FAC_BOF_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{FAC_BOF_FLUE_DISCHARGE}', discharge);
      return _split(_normalize(template));
    }
    if (condition.contains('ok')) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{BOILER_FLUE_OK}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{FAC_BOF_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{FAC_BOF_FLUE_DISCHARGE}', discharge);
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _fireplacesNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_flues_not_inspected']) && !_isChecked(answers['cb_No_Stack'])) {
      return const [];
    }
    var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    final notApplicable = _isChecked(answers['cb_flues_not_inspected'])
        ? _sub('{F_FIREPLACES_AND_CHIMNEYS_NOT_INSPECTED}', '{NOT_APPLICABLE}')
        : '';
    final noStack = _isChecked(answers['cb_No_Stack'])
        ? _sub('{F_FIREPLACES_AND_CHIMNEYS_NOT_INSPECTED}', '{NO_STACK_FIRE_PLACE}')
        : '';
    template = template.replaceAll('{NOT_APPLICABLE}', notApplicable).replaceAll('{NO_STACK_FIRE_PLACE}', noStack);
    return _split(_normalize(template));
  }

  List<String> _fireplacesFluesNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_flues_not_inspected'])) return const [];
    final template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', '{FLUES_NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _fireplacesType(
    Map<String, String> answers, {
    required String locationKey,
    required String conditionKey,
    required String locationToken,
    required String conditionToken,
  }) {
    final phrases = <String>[];
    final locations = _fireplacesLocations(answers);
    if (locations.isNotEmpty) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', locationKey);
      if (template.isNotEmpty) {
        template = template.replaceAll(locationToken, _toWords(locations).toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }
    }
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isNotEmpty) {
      var template = _sub('{F_FIREPLACES_AND_CHIMNEYS}', conditionKey);
      if (template.isNotEmpty) {
        template = template.replaceAll(conditionToken, condition);
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _fireplacesLocations(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_lounge', 'cb_reception', 'cb_dining_room', 'cb_kitchen', 'cb_bedroom', 'cb_other_1073'],
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

  List<String> _builtInFittings(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_kitchen', 'cb_utility_room', 'cb_other_1008'],
      answers,
      {
        'cb_kitchen': 'kitchen',
        'cb_utility_room': 'utility room',
        'cb_other_1008': 'other',
      },
    );
    _addOther(answers, 'cb_other_1008', 'et_other_764', locations);

    final worktops = _labelsFor(
      [
        'cb_particle_board_93',
        'cb_timber_83',
        'cb_granite_26',
        'cb_marble_38',
        'cb_glass_81',
        'cb_metal_60',
        'cb_other_672',
      ],
      answers,
      {
        'cb_particle_board_93': 'particle board',
        'cb_timber_83': 'timber',
        'cb_granite_26': 'granite',
        'cb_marble_38': 'marble',
        'cb_glass_81': 'glass',
        'cb_metal_60': 'metal',
        'cb_other_672': 'other',
      },
    );
    _addOther(answers, 'cb_other_672', 'et_other_614', worktops);

    final cabinets = _labelsFor(
      ['cb_timber', 'cb_other_343'],
      answers,
      {
        'cb_timber': 'timber',
        'cb_other_343': 'other',
      },
    );
    _addOther(answers, 'cb_other_343', 'et_other_745', cabinets);

    final condition = _cleanLower(answers['android_material_design_spinner3']);
    if (locations.isEmpty || worktops.isEmpty || cabinets.isEmpty || condition.isEmpty) {
      return const [];
    }

    var template = _sub('{F_BUILT_IN_FITTINGS}', '{BUILT_IN_FITTINGS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{BIF_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{BIF_WORKTOPS}', _toWords(worktops).toLowerCase())
        .replaceAll('{BIF_WALL_CABINET}', _toWords(cabinets).toLowerCase())
        .replaceAll('{BIF_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _builtInRepairFittings(Map<String, String> answers) {
    final repairType = _cleanLower(answers['actv_repair_type']);
    if (repairType.isEmpty) return const [];
    if (repairType.contains('repair now')) {
      final locations = _labelsFor(
        ['cb_kitchen', 'cb_utility_room', 'cb_other_672'],
        answers,
        {
          'cb_kitchen': 'kitchen',
          'cb_utility_room': 'utility room',
          'cb_other_672': 'other',
        },
      );
      _addOther(answers, 'cb_other_672', 'et_other_361', locations);
      final defects = _labelsFor(
        ['cb_badly_worn_16', 'cb_badly_damaged_94', 'cb_damp_95', 'cb_partly_rotted_19', 'cb_insect_infested_26'],
        answers,
        {
          'cb_badly_worn_16': 'badly worn',
          'cb_badly_damaged_94': 'badly damaged',
          'cb_damp_95': 'damp',
          'cb_partly_rotted_19': 'partly rotted',
          'cb_insect_infested_26': 'insect infested',
        },
      );
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_BUILT_IN_FITTINGS}', '{REPAIR_FITTING_NOW}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{BIFR_RF_NOW_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{BIFR_RF_NOW_DEFECT}', _toWords(defects).toLowerCase());
      final phrases = _split(_normalize(template));
      if (defects.any((defect) => defect.toLowerCase().contains('partly rotted'))) {
        final rotAdvice = _sub('{F_BUILT_IN_FITTINGS}', '{IF_PARTLY_ROTTED_IS_SELECTED}');
        if (rotAdvice.isNotEmpty) {
          phrases.addAll(_split(_normalize(rotAdvice)));
        }
      }
      return phrases;
    }

    if (repairType.contains('repair soon')) {
      final locations = _labelsFor(
        ['cb_kitchen_51', 'cb_utility_room_15', 'cb_other_332'],
        answers,
        {
          'cb_kitchen_51': 'kitchen',
          'cb_utility_room_15': 'utility room',
          'cb_other_332': 'other',
        },
      );
      _addOther(answers, 'cb_other_332', 'et_other_336', locations);
      final defects = _labelsFor(
        ['cb_worn', 'cb_damaged', 'cb_badly_fitted', 'cb_incomplete', 'cb_broken', 'cb_other_818'],
        answers,
        {
          'cb_worn': 'worn',
          'cb_damaged': 'damaged',
          'cb_badly_fitted': 'badly fitted',
          'cb_incomplete': 'incomplete',
          'cb_broken': 'broken',
          'cb_other_818': 'other',
        },
      );
      _addOther(answers, 'cb_other_818', 'et_other_180', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_BUILT_IN_FITTINGS}', '{REPAIR_FITTING_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{BIFR_RF_SOON_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{BIFR_RF_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _builtInDefectiveSealants(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_kitchen_sink', 'cb_utility_room_sink', 'cb_other_717'],
      answers,
      {
        'cb_kitchen_sink': 'kitchen sink',
        'cb_utility_room_sink': 'utility room sink',
        'cb_other_717': 'other',
      },
    );
    _addOther(answers, 'cb_other_717', 'et_other_916', locations);
    final defects = _labelsFor(
      ['cb_damaged_38', 'cb_partly_missing_86', 'cb_poorly_applied_75', 'cb_other_356'],
      answers,
      {
        'cb_damaged_38': 'damaged',
        'cb_partly_missing_86': 'partly missing',
        'cb_poorly_applied_75': 'poorly applied',
        'cb_other_356': 'other',
      },
    );
    _addOther(answers, 'cb_other_356', 'et_other_817', defects);
    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_BUILT_IN_FITTINGS}', '{DEFECTIVE_SEALANTS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{BIFR_DS_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{BIFR_DS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _builtInMouldingNoted(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_kitchen_sink', 'cb_Utility_room_sink', 'cb_other_717'],
      answers,
      {
        'cb_kitchen_sink': 'kitchen sink',
        'cb_Utility_room_sink': 'utility room sink',
        'cb_other_717': 'other',
      },
    );
    _addOther(answers, 'cb_other_717', 'et_other_916', locations);
    if (locations.isEmpty) return const [];
    var template = _sub('{F_BUILT_IN_FITTINGS}', '{MOULDING_NOTED}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{BIFR_MN_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _builtInWaterSeepage(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_kitchen_sink', 'cb_Utility_room_sink', 'cb_Hidden_parts', 'cb_other_717'],
      answers,
      {
        'cb_kitchen_sink': 'behind the fitting',
        'cb_Utility_room_sink': 'affecting the adjacent surfaces',
        'cb_Hidden_parts': 'hidden parts',
        'cb_other_717': 'other',
      },
    );
    _addOther(answers, 'cb_other_717', 'et_other_916', locations);
    if (locations.isEmpty) return const [];
    var template = _sub('{F_BUILT_IN_FITTINGS}', '{REPAIR_WATER_SEEPAGE}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{BIFR_WS_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _builtInNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_BUILT_IN_FITTINGS}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
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

  List<String> _insideOtherCommunalArea(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];

    if (status.contains('not')) {
      final reasons = _labelsFor(
        ['cb_the_door_is_locked', 'cb_the_area_is_not_accessible', 'cb_of_limited_access', 'cb_other_945'],
        answers,
        {
          'cb_the_door_is_locked': 'The door is locked',
          'cb_the_area_is_not_accessible': 'The area is not accessible',
          'cb_of_limited_access': 'Of limited access',
          'cb_other_945': 'Other',
        },
      );
      _addOther(answers, 'cb_other_945', 'et_other_638', reasons);
      if (reasons.isEmpty) return const [];
      var template = _sub('{F_OTHER}', '{COMMUNAL_AREA_NOT_INSPECTED}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{OTH_CA_NOT_INSPECTED_BECAUSE}', _toWords(reasons).toLowerCase());
      return _split(_normalize(template));
    }

    final property = _labelsFor(
      [
        'cb_stairs',
        'cb_landing',
        'cb_balcony',
        'cb_hallway',
        'cb_shared_lobby',
        'cb_fire_lobby',
        'cb_common_room',
        'cb_other_1054',
      ],
      answers,
      {
        'cb_stairs': 'Stairs',
        'cb_landing': 'Landing',
        'cb_balcony': 'Balcony',
        'cb_hallway': 'Hallway',
        'cb_shared_lobby': 'Shared lobby',
        'cb_fire_lobby': 'Fire lobby',
        'cb_common_room': 'Common room',
        'cb_other_1054': 'Other',
      },
    );
    _addOther(answers, 'cb_other_1054', 'et_other_914', property);

    final defects = _labelsFor(
      [
        'cb_usual_wear_and_tear_100',
        'cb_decoration_discolouration_66',
        'cb_shrinkage_cracks_43',
        'cb_movement_cracks_22',
        'cb_other_570',
      ],
      answers,
      {
        'cb_usual_wear_and_tear_100': 'Usual wear and tear',
        'cb_decoration_discolouration_66': 'Decoration discolouration',
        'cb_shrinkage_cracks_43': 'Shrinkage cracks',
        'cb_movement_cracks_22': 'Movement cracks',
        'cb_other_570': 'Other',
      },
    );
    _addOther(answers, 'cb_other_570', 'et_other_904', defects);

    final condition = _cleanLower(answers['actv_condition']);
    if (property.isEmpty || defects.isEmpty || condition.isEmpty) return const [];

    var template = _sub('{F_OTHER}', '{COMMUNAL_AREA_INSPECTED}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTH_CA_INSPECTED_PROPERTY}', _toWords(property).toLowerCase())
        .replaceAll('{OTH_CA_INSPECTED_DEFECT}', _toWords(defects).toLowerCase())
        .replaceAll('{OTH_CA_INSPECTED_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _insideOtherNoAccess(Map<String, String> answers, {required bool isBasement}) {
    final reasons = _labelsFor(
      ['cb_restricted_access', 'cb_no_access', 'cb_other_704'],
      answers,
      {
        'cb_restricted_access': 'Restricted access',
        'cb_no_access': 'No access',
        'cb_other_704': 'Other',
      },
    );
    _addOther(answers, 'cb_other_704', 'et_other_412', reasons);
    if (reasons.isEmpty) return const [];
    final subCode = isBasement ? '{BASEMENT_NO_ACCESS}' : '{CELLAR_NO_ACCESS}';
    var template = _sub('{F_OTHER}', subCode);
    if (template.isEmpty) return const [];
    template = template.replaceAll(
      isBasement ? '{OTH_BASEMENT_NA_BECAUSE}' : '{OTH_CELLAR_NA_BECAUSE}',
      _toWords(reasons).toLowerCase(),
    );
    return _split(_normalize(template));
  }

  List<String> _insideOtherNotInUse(Map<String, String> answers, {required bool isBasement}) {
    if (!_isChecked(answers['cb_not_in_use'])) return const [];
    final subCode = isBasement ? '{BASEMENT_NOT_IN_USE}' : '{CELLAR_NOT_IN_USE}';
    final template = _sub('{F_OTHER}', subCode);
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _insideOtherUsedAs(Map<String, String> answers, {required bool isBasement}) {
    final usedAs = _cleanLower(answers['actv_used_as']);
    final condition = _cleanLower(answers['actv_condition']);
    if (usedAs.isEmpty || condition.isEmpty) return const [];
    final subCode = isBasement ? '{BASEMENT_IN_USE}' : '{CELLAR_IN_USE}';
    var template = _sub('{F_OTHER}', subCode);
    if (template.isEmpty) return const [];
    template = template.replaceAll(
      isBasement ? '{OTH_BASEMENT_UA}' : '{OTH_CELLAR_UA}',
      usedAs,
    );
    template = template.replaceAll(
      isBasement ? '{OTH_BASEMENT_UA_CONDITION}' : '{OTH_CELLAR_UA_CONDITION}',
      condition,
    );
    return _split(_normalize(template));
  }

  List<String> _insideOtherNotHabitable(Map<String, String> answers, {required bool isBasement}) {
    final reasons = _labelsFor(
      ['cb_plastic', 'cb_cast_iron', 'cb_asbestos_cement', 'cb_concrete', 'cb_other_697'],
      answers,
      {
        'cb_plastic': 'the ceiling is too low',
        'cb_cast_iron': 'it is damp',
        'cb_asbestos_cement': 'access is difficult',
        'cb_concrete': 'of poor ventilation',
        'cb_other_697': 'Other',
      },
    );
    _addOther(answers, 'cb_other_697', 'et_other_427', reasons);
    if (reasons.isEmpty) return const [];
    final subCode = isBasement ? '{BASEMENT_NOT_HABITABLE}' : '{CELLAR_NOT_HABITABLE}';
    var template = _sub('{F_OTHER}', subCode);
    if (template.isEmpty) return const [];
    template = template.replaceAll(
      isBasement ? '{OTH_BASEMENT_NH_BECAUSE}' : '{OTH_CELLAR_NH_BECAUSE}',
      _toWords(reasons).toLowerCase(),
    );
    return _split(_normalize(template));
  }

  List<String> _insideOtherFlooded(Map<String, String> answers, {required bool isBasement}) {
    final flooded = _cleanLower(answers['actv_possible_flooded']);
    if (flooded.isEmpty) return const [];
    final subCode = isBasement ? '{BASEMENT_FLOODED}' : '{CELLAR_FLOODED}';
    var template = _sub('{F_OTHER}', subCode);
    if (template.isEmpty) return const [];
    template = template.replaceAll(
      isBasement ? '{OTH_BASEMENT_FLOODED}' : '{OTH_CELLAR_FLOODED}',
      flooded,
    );
    return _split(_normalize(template));
  }

  List<String> _insideOtherDamp(Map<String, String> answers, {required bool isBasement}) {
    final phrases = <String>[];
    final locations = _labelsFor(
      [
        'cb_to_the_lower_walls_of',
        'cb_to_the_upper_walls_of',
        'cb_throughout',
        'cb_to_exposed_floor_joists_in',
        'cb_others_389',
      ],
      answers,
      {
        'cb_to_the_lower_walls_of': 'to the lower walls of',
        'cb_to_the_upper_walls_of': 'to the upper walls of',
        'cb_throughout': 'throughout',
        'cb_to_exposed_floor_joists_in': 'to exposed floor joists in',
        'cb_others_389': 'other',
      },
    );
    _addOther(answers, 'cb_others_389', 'et_others_471', locations);
    if (locations.isNotEmpty) {
      final subCode = isBasement ? '{BASEMENT_DAMP}' : '{CELLAR_DAMP}';
      var template = _sub('{F_OTHER}', subCode);
      if (template.isNotEmpty) {
        template = template.replaceAll(
          isBasement ? '{OTH_BASEMENT_DAMP}' : '{OTH_CELLAR_DAMP}',
          _toWords(locations).toLowerCase(),
        );
        phrases.addAll(_split(_normalize(template)));
      }
    }
    if (_isChecked(answers['cb_serious_dump'])) {
      final subCode = isBasement ? '{BASEMENT_SERIOUS_DAMP}' : '{CELLAR_SERIOUS_DAMP}';
      final template = _sub('{F_OTHER}', subCode);
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
    }
    return phrases;
  }

  List<String> _insideOtherJoistsDecay(Map<String, String> answers, {required bool isBasement}) {
    if (!_isChecked(answers['cb_joists_decay'])) return const [];
    final subCode = isBasement ? '{BASEMENT_JOINT_DECAY}' : '{CELLAR_JOINT_DECAY}';
    final template = _sub('{F_OTHER}', subCode);
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _insideOtherRepair(Map<String, String> answers) {
    final repairType = _cleanLower(answers['actv_repair_type']);
    if (repairType.isEmpty) return const [];

    if (repairType.contains('soon')) {
      final locations = _labelsFor(
        [
          'cb_stairs',
          'cb_landing',
          'cb_balcony',
          'cb_hallway',
          'cb_shared_lobby',
          'cb_fire_lobby',
          'cb_common_room',
          'cb_other_1111',
        ],
        answers,
        {
          'cb_stairs': 'Stairs',
          'cb_landing': 'Landing',
          'cb_balcony': 'Balcony',
          'cb_hallway': 'Hallway',
          'cb_shared_lobby': 'Shared lobby',
          'cb_fire_lobby': 'Fire lobby',
          'cb_common_room': 'Common room',
          'cb_other_1111': 'Other',
        },
      );
      _addOther(answers, 'cb_other_1111', 'et_other_609', locations);
      final defects = _labelsFor(
        [
          'cb_worn',
          'cb_damaged',
          'cb_creaking',
          'cb_badly_cracked',
          'cb_sloping',
          'cb_missing_in_places',
          'cb_in_disrepair',
          'cb_other_1005',
        ],
        answers,
        {
          'cb_worn': 'Worn',
          'cb_damaged': 'Damaged',
          'cb_creaking': 'Creaking',
          'cb_badly_cracked': 'Cracked',
          'cb_sloping': 'Sloping',
          'cb_missing_in_places': 'Missing in places',
          'cb_in_disrepair': 'In disrepair',
          'cb_other_1005': 'Other',
        },
      );
      _addOther(answers, 'cb_other_1005', 'et_other_529', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_OTHER}', '{OTHER_REPAIR_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{OTHR_SOON_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{OTHR_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    final locations = _labelsFor(
      [
        'cb_stairs_54',
        'cb_landing_94',
        'cb_balcony_100',
        'cb_hallway_17',
        'cb_shared_lobby_53',
        'cb_fire_lobby_79',
        'cb_common_room_76',
        'cb_other_572',
      ],
      answers,
      {
        'cb_stairs_54': 'Stairs',
        'cb_landing_94': 'Landing',
        'cb_balcony_100': 'Balcony',
        'cb_hallway_17': 'Hallway',
        'cb_shared_lobby_53': 'Shared lobby',
        'cb_fire_lobby_79': 'Fire lobby',
        'cb_common_room_76': 'Common room',
        'cb_other_572': 'Other',
      },
    );
    _addOther(answers, 'cb_other_572', 'et_other_770', locations);
    final defects = _labelsFor(
      ['cb_severely_damaged_62', 'cb_badly_cracked_29', 'cb_in_complete_disrepair_13', 'cb_other_689'],
      answers,
      {
        'cb_severely_damaged_62': 'Severely damaged',
        'cb_badly_cracked_29': 'Badly cracked',
        'cb_in_complete_disrepair_13': 'In complete disrepair',
        'cb_other_689': 'Other',
      },
    );
    _addOther(answers, 'cb_other_689', 'et_other_216', defects);
    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_OTHER}', '{OTHER_REPAIR_NOW}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{OTHR_NOW_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{OTHR_NOW_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _insideOtherNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_OTHER}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _woodWorkMain(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_Door_sampling'])) {
      final condition = _cleanLower(answers['actv_condition']);
      if (condition.isNotEmpty) {
        final template = _sub('{F_WOOD_WORK}', '{DOOR_SAMPLING_OK}');
        if (template.isNotEmpty) {
          phrases.addAll(
            _split(_normalize(template.replaceAll('{WW_DOOR_SAMPLING_CONDITION}', condition))),
          );
        }
      }
    }
    if (_isChecked(answers['cb_out_of_square_doors'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{OUT_OF_SQUARE_DOORS}'))));
    }
    if (_isChecked(answers['cb_glazed_internal_doors'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{GLAZED_INTERNAL_DOORS}'))));
    }
    if (_isChecked(answers['cb_creaking_stairs'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{CREAKING_STAIRS}'))));
    }
    if (_isChecked(answers['cb_stairs_handrails'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{ROCKING_STAIR_HANDRAILS}'))));
    }
    if (_isChecked(answers['cb_no_stairs_handrails'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{NO_STAIRS_HANDRAILS}'))));
    }
    if (_isChecked(answers['cb_open_threads'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{OPEN_STAIR_THREADS}'))));
    }
    return phrases;
  }

  List<String> _woodWorkDetails(Map<String, String> answers) {
    final items = _labelsFor(
      [
        'cb_doors',
        'cb_architraves',
        'cb_stairs',
        'cb_stairs_threads',
        'cb_handrails',
        'cb_balusters',
        'cb_skirting_boards',
        'cb_cladding',
        'cb_other_410',
      ],
      answers,
      {
        'cb_doors': 'doors',
        'cb_architraves': 'architraves',
        'cb_stairs': 'stairs',
        'cb_stairs_threads': 'stairs threads',
        'cb_handrails': 'handrails',
        'cb_balusters': 'balusters',
        'cb_skirting_boards': 'skirting boards',
        'cb_cladding': 'cladding',
        'cb_other_410': 'other',
      },
    );
    _addOther(answers, 'cb_other_410', 'et_other_800', items);
    final condition = _cleanLower(answers['actv_condition']);
    if (items.isEmpty || condition.isEmpty) return const [];
    final phrases = <String>[];
    final template = _sub('{F_WOOD_WORK}', '{WOOD_WORK}');
    if (template.isNotEmpty) {
      phrases.addAll(
        _split(
          _normalize(
            template
                .replaceAll('{WW_WW_MADE_UP}', _toWords(items).toLowerCase())
                .replaceAll('{WW_WW_CONDITION}', condition),
          ),
        ),
      );
    }
    return phrases;
  }

  List<String> _woodWorkCupboards(Map<String, String> answers) {
    final condition = _cleanLower(answers['actv_condition']);
    if (condition.isEmpty) return const [];
    final phrases = <String>[];
    final template = _sub('{F_WOOD_WORK}', '{FITTED_BUILTIN_CUPBOARDS}');
    if (template.isNotEmpty) {
      phrases.addAll(
        _split(_normalize(template.replaceAll('{WW_FBC_CONDITION}', condition))),
      );
    }
    return phrases;
  }

  List<String> _woodWorkDoorSampling(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_lounge', 'cb_bedroom', 'cb_dining', 'cb_kitchen', 'cb_other_905'],
      answers,
      {
        'cb_lounge': 'lounge',
        'cb_bedroom': 'bedroom',
        'cb_dining': 'dining room',
        'cb_kitchen': 'kitchen',
        'cb_other_905': 'other',
      },
    );
    _addOther(answers, 'cb_other_905', 'et_other_689', locations);
    final defects = _labelsFor(
      [
        'cb_damage_29',
        'cb_poorly_fitted_50',
        'cb_not_closing_well_53',
        'cb_poorly_secured_28',
        'cb_other_443',
      ],
      answers,
      {
        'cb_damage_29': 'damaged',
        'cb_poorly_fitted_50': 'poorly fitted',
        'cb_not_closing_well_53': 'not closing well',
        'cb_poorly_secured_28': 'poorly secured',
        'cb_other_443': 'other',
      },
    );
    _addOther(answers, 'cb_other_443', 'et_other_362', defects);
    final phrases = <String>[];
    if (locations.isNotEmpty && defects.isNotEmpty) {
      final template = _sub('{F_WOOD_WORK}', '{DOOR_REPAIR}');
      if (template.isNotEmpty) {
        phrases.addAll(
          _split(
            _normalize(
              template
                  .replaceAll('{WWR_DR_LOCATION}', _toWords(locations).toLowerCase())
                  .replaceAll('{WWR_DR_DEFECT}', _toWords(defects).toLowerCase()),
            ),
          ),
        );
      }
    }
    if (_isChecked(answers['cb_door_not_closing_well'])) {
      phrases.addAll(_split(_normalize(_sub('{F_WOOD_WORK}', '{IF_NOT_CLOSING_WELL_IS_SELECTED}'))));
    }
    return phrases;
  }

  List<String> _woodWorkDamagedLock(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_lounge', 'cb_bedroom', 'cb_dining', 'cb_kitchen', 'cb_other_776'],
      answers,
      {
        'cb_lounge': 'lounge',
        'cb_bedroom': 'bedroom',
        'cb_dining': 'dining room',
        'cb_kitchen': 'kitchen',
        'cb_other_776': 'other',
      },
    );
    _addOther(answers, 'cb_other_776', 'et_other_770', locations);
    final defects = _labelsFor(
      ['cb_damaged_58', 'cb_in_disrepair_33', 'cb_stuck_35', 'cb_other_629'],
      answers,
      {
        'cb_damaged_58': 'damaged',
        'cb_in_disrepair_33': 'in disrepair',
        'cb_stuck_35': 'stuck',
        'cb_other_629': 'other',
      },
    );
    _addOther(answers, 'cb_other_629', 'et_other_259', defects);
    if (locations.isEmpty || defects.isEmpty) return const [];
    final template = _sub('{F_WOOD_WORK}', '{REPAIR_DAMAGED_LOCK}');
    if (template.isEmpty) return const [];
    return _split(
      _normalize(
        template
            .replaceAll('{WWR_DL_DAMAGED_LOCK}', _toWords(locations).toLowerCase())
            .replaceAll('{WWR_DL_DEFECT}', _toWords(defects).toLowerCase()),
      ),
    );
  }

  List<String> _woodWorkRepair(Map<String, String> answers) {
    final repairType = _cleanLower(answers['actv_repair_type']);
    if (repairType.isEmpty) return const [];
    if (repairType.contains('repair soon')) {
      final locations = _labelsFor(
        ['cb_stairs', 'cb_stairs_threads', 'cb_handrails', 'cb_balusters', 'cb_skirting_boards', 'cb_other_1084'],
        answers,
        {
          'cb_stairs': 'stairs',
          'cb_stairs_threads': 'stairs threads',
          'cb_handrails': 'handrails',
          'cb_balusters': 'balusters',
          'cb_skirting_boards': 'skirting boards',
          'cb_other_1084': 'other',
        },
      );
      _addOther(answers, 'cb_other_1084', 'et_other_661', locations);
      final defects = _labelsFor(
        ['cb_worn_68', 'cb_loose_20', 'cb_poorly_fitted_73', 'cb_damaged_42', 'cb_poorly_secured_55', 'cb_other_612'],
        answers,
        {
          'cb_worn_68': 'worn',
          'cb_loose_20': 'loose',
          'cb_poorly_fitted_73': 'poorly fitted',
          'cb_damaged_42': 'damaged',
          'cb_poorly_secured_55': 'poorly secured',
          'cb_other_612': 'other',
        },
      );
      _addOther(answers, 'cb_other_612', 'et_other_366', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_WOOD_WORK}', '{WOOD_WORK_REPAIR_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{WWR_WWR_SOON_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{WWR_WWR_SOON_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    if (repairType.contains('repair now')) {
      final locations = _labelsFor(
        ['cb_stairs_49', 'cb_stairs_threads_27', 'cb_handrails_94', 'cb_balusters_64', 'cb_skirting_boards_47'],
        answers,
        {
          'cb_stairs_49': 'stairs',
          'cb_stairs_threads_27': 'stairs threads',
          'cb_handrails_94': 'handrails',
          'cb_balusters_64': 'balusters',
          'cb_skirting_boards_47': 'skirting boards',
        },
      );
      final defects = _labelsFor(
        ['cb_badly_worn', 'cb_very_loose', 'cb_incomplete', 'cb_missing', 'cb_damp', 'cb_rotten', 'cb_other_766'],
        answers,
        {
          'cb_badly_worn': 'badly worn',
          'cb_very_loose': 'very loose',
          'cb_incomplete': 'incomplete',
          'cb_missing': 'missing',
          'cb_damp': 'damp',
          'cb_rotten': 'rotten',
          'cb_other_766': 'other',
        },
      );
      _addOther(answers, 'cb_other_766', 'et_other_516', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_WOOD_WORK}', '{WOOD_WORK_REPAIR_NOW}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{WWR_WWR_NOW_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{WWR_WWR_NOW_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _woodWorkRepairBalusters(Map<String, String> answers) {
    final defects = _labelsFor(
      ['cb_too_far_apart_93', 'cb_missing_47', 'cb_broken_89', 'cb_other_890'],
      answers,
      {
        'cb_too_far_apart_93': 'too far apart',
        'cb_missing_47': 'missing',
        'cb_broken_89': 'broken',
        'cb_other_890': 'other',
      },
    );
    _addOther(answers, 'cb_other_890', 'et_other_516', defects);
    if (defects.isEmpty) return const [];
    var template = _sub('{F_WOOD_WORK}', '{REPAIR_BALUSTERS}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{WWR_BALUSTERS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _woodWorkRepairInfestation(Map<String, String> answers) {
    final severity = _cleanLower(answers['actv_condition']);
    if (severity.isEmpty) return const [];
    final parts = _labelsFor(
      ['cb_staircase', 'cb_floorboards', 'cb_skirting', 'cb_under_stairs', 'cb_cupboards', 'cb_other_1032'],
      answers,
      {
        'cb_staircase': 'staircase',
        'cb_floorboards': 'floorboards',
        'cb_skirting': 'skirting',
        'cb_under_stairs': 'under stairs',
        'cb_cupboards': 'cupboards',
        'cb_other_1032': 'other',
      },
    );
    _addOther(answers, 'cb_other_1032', 'et_other_728', parts);
    final locations = _labelsFor(
      ['cb_plastic', 'cb_cast_iron', 'cb_asbestos_cement', 'cb_concrete', 'cb_Bedroom', 'cb_other_697'],
      answers,
      {
        'cb_plastic': 'lounge',
        'cb_cast_iron': 'reception',
        'cb_asbestos_cement': 'dining room',
        'cb_concrete': 'kitchen',
        'cb_Bedroom': 'bedroom',
        'cb_other_697': 'other',
      },
    );
    _addOther(answers, 'cb_other_697', 'et_other_427', locations);
    if (parts.isEmpty || locations.isEmpty) return const [];
    final code = severity.contains('major') ? '{REPAIR_INFESTATION_MAJOR}' : '{REPAIR_INFESTATION_MINOR}';
    var template = _sub('{F_WOOD_WORK}', code);
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{WWR_INFESTATION_PART_OF}', _toWords(parts).toLowerCase())
        .replaceAll('{WWR_INFESTATION_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _woodWorkRepairDampTimber(Map<String, String> answers) {
    final components = _labelsFor(
      ['cb_staircase', 'cb_floorboards', 'cb_skirting', 'cb_under_stairs', 'cb_cupboards', 'cb_other_270'],
      answers,
      {
        'cb_staircase': 'staircase',
        'cb_floorboards': 'floorboards',
        'cb_skirting': 'skirting',
        'cb_under_stairs': 'under stairs',
        'cb_cupboards': 'cupboards',
        'cb_other_270': 'other',
      },
    );
    _addOther(answers, 'cb_other_270', 'et_other_516', components);
    final locations = _labelsFor(
      ['cb_lounge_72', 'cb_reception_49', 'cb_dining_room_84', 'cb_kitchen_72', 'cb_bedroom_44', 'cb_other_750'],
      answers,
      {
        'cb_lounge_72': 'lounge',
        'cb_reception_49': 'reception',
        'cb_dining_room_84': 'dining room',
        'cb_kitchen_72': 'kitchen',
        'cb_bedroom_44': 'bedroom',
        'cb_other_750': 'other',
      },
    );
    _addOther(answers, 'cb_other_750', 'et_other_302', locations);
    final defects = _labelsFor(
      ['cb_damp', 'cb_rotten', 'cb_other_498'],
      answers,
      {
        'cb_damp': 'damp',
        'cb_rotten': 'rotten',
        'cb_other_498': 'other',
      },
    );
    _addOther(answers, 'cb_other_498', 'et_other_534', defects);
    if (components.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_WOOD_WORK}', '{REPAIR_DAMP_TIMBER}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{WWR_DT_COMPONENT}', _toWords(components).toLowerCase())
        .replaceAll('{WWR_DT_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{WWR_DT_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _woodWorkNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_WOOD_WORK}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
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

  List<String> _bathroomFittings(Map<String, String> answers) {
    final locations = _labelsFor(
      [
        'cb_bathroom',
        'cb_shower_room',
        'cb_en_suite_bathroom',
        'cb_en_suite_shower_room',
        'cb_separate_toilet',
        'cb_other_653',
      ],
      answers,
      {
        'cb_bathroom': 'bathroom',
        'cb_shower_room': 'shower room',
        'cb_en_suite_bathroom': 'en suite bathroom',
        'cb_en_suite_shower_room': 'en suite shower room',
        'cb_separate_toilet': 'separate toilet',
        'cb_other_653': 'other',
      },
    );
    _addOther(answers, 'cb_other_653', 'et_other_836', locations);

    final madeUp = _labelsFor(
      ['cb_old_style_94', 'cb_fairly_basic_12', 'cb_dated_68', 'cb_modern_72', 'cb_other_803'],
      answers,
      {
        'cb_old_style_94': 'old style',
        'cb_fairly_basic_12': 'fairly basic',
        'cb_dated_68': 'dated',
        'cb_modern_72': 'modern',
        'cb_other_803': 'other',
      },
    );
    _addOther(answers, 'cb_other_803', 'et_other_134', madeUp);

    final fittings = _labelsFor(
      [
        'cb_bathtub_32',
        'cb_shower_unit_60',
        'cb_overhead_shower_68',
        'cb_wc_23',
        'cb_wash_hand_basin_91',
        'cb_urinal_13',
        'cb_bidet_48',
        'cb_other_922',
      ],
      answers,
      {
        'cb_bathtub_32': 'bathtub',
        'cb_shower_unit_60': 'shower unit',
        'cb_overhead_shower_68': 'overhead shower',
        'cb_wc_23': 'wc',
        'cb_wash_hand_basin_91': 'wash hand basin',
        'cb_urinal_13': 'urinal',
        'cb_bidet_48': 'bidet',
        'cb_other_922': 'other',
      },
    );
    _addOther(answers, 'cb_other_922', 'et_other_351', fittings);

    final condition = _cleanLower(answers['android_material_design_spinner3']);
    if (locations.isEmpty || madeUp.isEmpty || fittings.isEmpty || condition.isEmpty) {
      return const [];
    }

    var template = _sub('{F_BATHROOM_FITTINGS}', '{BATHROOM_FITTINGS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{BF_BF_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{BF_BF_MADE_UP}', _toWords(madeUp).toLowerCase())
        .replaceAll('{BF_BF_FITTINGS}', _toWords(fittings).toLowerCase())
        .replaceAll('{BF_BF_CONDITION}', condition);
    return _split(_normalize(template));
  }

  List<String> _bathroomExtractorFan(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];

    final locations = _labelsFor(
      [
        'cb_bathroom_56',
        'cb_shower_room_100',
        'cb_en_suite_bathroom_101',
        'cb_en_suite_shower_room_81',
        'cb_separate_toilet_99',
        'cb_other_725',
      ],
      answers,
      {
        'cb_bathroom_56': 'bathroom',
        'cb_shower_room_100': 'shower room',
        'cb_en_suite_bathroom_101': 'en suite bathroom',
        'cb_en_suite_shower_room_81': 'en suite shower room',
        'cb_separate_toilet_99': 'separate toilet',
        'cb_other_725': 'other',
      },
    );
    _addOther(answers, 'cb_other_725', 'et_other_631', locations);
    if (locations.isEmpty) return const [];

    if (status.contains('ok')) {
      final tested = _labelsFor(
        ['cb_was_switched_on_and_it_was_35', 'cb_were_switched_on_and_were_64', 'cb_other_1068'],
        answers,
        {
          'cb_was_switched_on_and_it_was_35': 'switch was on and was working',
          'cb_were_switched_on_and_were_64': 'switch on - not working',
          'cb_other_1068': 'other',
        },
      );
      _addOther(answers, 'cb_other_1068', 'et_other_297', tested);
      if (tested.isEmpty) return const [];
      var template = _sub('{F_BATHROOM_FITTINGS}', '{EXTRACTOR_FAN_INSTALLED_OK}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{BF_EF_EFI_OK_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{BF_EF_EFI_OK_TESTED}', _toWords(tested).toLowerCase());
      return _split(_normalize(template));
    }

    if (status.contains('replace')) {
      final defects = _labelsFor(
        ['cb_was_not_working', 'cb_has_blocked_vent', 'cb_is_too_small', 'cb_has_weak_suction', 'cb_other_987'],
        answers,
        {
          'cb_was_not_working': 'was not working',
          'cb_has_blocked_vent': 'has blocked vent',
          'cb_is_too_small': 'is too small',
          'cb_has_weak_suction': 'has weak suction',
          'cb_other_987': 'other',
        },
      );
      _addOther(answers, 'cb_other_987', 'et_other_368', defects);
      if (defects.isEmpty) return const [];
      var template = _sub('{F_BATHROOM_FITTINGS}', '{EXTRACTOR_FAN_INSTALLED_REPLACE}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{BF_EF_EFI_REPLACE_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{BF_EF_EFI_REPLACE_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _bathroomExtractorFanNoInstalled(Map<String, String> answers) {
    final condensation = _cleanLower(answers['actv_status_new']);
    final locations = _labelsFor(
      [
        'cb_bathroom_56_wef',
        'cb_shower_room_100_wef',
        'cb_en_suite_bathroom_101_wef',
        'cb_en_suite_shower_room_81_wef',
        'cb_separate_toilet_99_wef',
        'cb_other_725_wef',
      ],
      answers,
      {
        'cb_bathroom_56_wef': 'bathroom',
        'cb_shower_room_100_wef': 'shower room',
        'cb_en_suite_bathroom_101_wef': 'en suite bathroom',
        'cb_en_suite_shower_room_81_wef': 'en suite shower room',
        'cb_separate_toilet_99_wef': 'separate toilet',
        'cb_other_725_wef': 'other',
      },
    );
    _addOther(answers, 'cb_other_725_wef', 'et_other_631_wef', locations);
    if (locations.isEmpty || condensation.isEmpty) return const [];

    final code = condensation.contains('noted')
        ? '{EXTRACTOR_FAN_CONDENSATION_NOTED}'
        : '{EXTRACTOR_FAN_NO_INSTALLED}';
    var template = _sub('{F_BATHROOM_FITTINGS}', code);
    if (template.isEmpty) return const [];
    template = template.replaceAll('{BF_EF_NEFI_LOCATION}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _bathroomLeaking(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_bathtub', 'cb_shower', 'cb_wc', 'cb_wash_hand_basin', 'cb_urinal', 'cb_other_937'],
      answers,
      {
        'cb_bathtub': 'bathtub',
        'cb_shower': 'shower',
        'cb_wc': 'wc',
        'cb_wash_hand_basin': 'wash hand basin',
        'cb_urinal': 'urinal',
        'cb_other_937': 'other',
      },
    );
    _addOther(answers, 'cb_other_937', 'et_other_861', locations);
    if (locations.isEmpty) return const [];
    var template = _sub('{F_BATHROOM_FITTINGS}', '{LEAKING_SEALANTS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{BF_LS_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{IS_ARE}', _isAre(locations));
    return _split(_normalize(template));
  }

  List<String> _bathroomSealant(Map<String, String> answers) {
    final around = _labelsFor(
      ['cb_bathtub', 'cb_shower_tray', 'cb_wash_hand_basin', 'cb_other_583'],
      answers,
      {
        'cb_bathtub': 'bathtub',
        'cb_shower_tray': 'shower tray',
        'cb_wash_hand_basin': 'wash hand basin',
        'cb_other_583': 'other',
      },
    );
    _addOther(answers, 'cb_other_583', 'et_other_474', around);
    final defects = _labelsFor(
      ['cb_damaged_partly_missing_poorly_applied_76', 'cb_partly_missing', 'cb_poorly_applied', 'cb_other_695'],
      answers,
      {
        'cb_damaged_partly_missing_poorly_applied_76': 'damaged',
        'cb_partly_missing': 'partly missing',
        'cb_poorly_applied': 'poorly applied',
        'cb_other_695': 'other',
      },
    );
    _addOther(answers, 'cb_other_695', 'et_other_411', defects);
    if (around.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_BATHROOM_FITTINGS}', '{SEALANT_CONDITION}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{BF_SC_SEALANTS_AROUND}', _toWords(around).toLowerCase())
        .replaceAll('{BF_SC_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _bathroomMoulding(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_bathtub', 'cb_wash_hand_basin', 'cb_shower_tray', 'cb_other_1061'],
      answers,
      {
        'cb_bathtub': 'bathtub',
        'cb_wash_hand_basin': 'wash hand basin',
        'cb_shower_tray': 'shower tray',
        'cb_other_1061': 'other',
      },
    );
    _addOther(answers, 'cb_other_1061', 'et_other_532', locations);
    if (locations.isEmpty) return const [];
    var template = _sub('{F_BATHROOM_FITTINGS}', '{MOULDING}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{BF_MOULDING_NOTED}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _bathroomWoodRot(Map<String, String> answers) {
    final items = _labelsFor(
      ['cb_cupboards', 'cb_wood_panelling', 'cb_other_458'],
      answers,
      {
        'cb_cupboards': 'cupboards',
        'cb_wood_panelling': 'wood panelling',
        'cb_other_458': 'other',
      },
    );
    _addOther(answers, 'cb_other_458', 'et_other_925', items);
    final locations = _labelsFor(
      ['cb_bathtub_37', 'cb_shower_52', 'cb_wash_hand_basin_69', 'cb_other_333'],
      answers,
      {
        'cb_bathtub_37': 'bathtub',
        'cb_shower_52': 'shower',
        'cb_wash_hand_basin_69': 'wash hand basin',
        'cb_other_333': 'other',
      },
    );
    _addOther(answers, 'cb_other_333', 'et_other_466', locations);
    final defects = _labelsFor(
      ['cb_damp_91', 'cb_partly_rotted_20', 'cb_other_940'],
      answers,
      {
        'cb_damp_91': 'damp',
        'cb_partly_rotted_20': 'partly rotted',
        'cb_other_940': 'other',
      },
    );
    _addOther(answers, 'cb_other_940', 'et_other_152', defects);
    if (items.isEmpty || locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_BATHROOM_FITTINGS}', '{WOOD_ROT}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{BF_WR_ITEM}', _toWords(items).toLowerCase())
        .replaceAll('{BF_WR_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{BF_WR_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _bathroomCubicleSafetyGlassRating(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_shower_cubicle', 'cb_bathtub', 'cb_other_1084'],
      answers,
      {
        'cb_shower_cubicle': 'shower cubicle',
        'cb_bathtub': 'bathtub screen',
        'cb_other_1084': 'other',
      },
    );
    _addOther(answers, 'cb_other_1084', 'et_other_843', locations);
    if (locations.isEmpty) return const [];
    var template = _sub('{F_BATHROOM_FITTINGS}', '{NO_CUBICAL_SG_RATING}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{BF_NCS_GR_MARK_NOTED}', _toWords(locations).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _bathroomFittingsRepair(Map<String, String> answers) {
    final repairType = _cleanLower(answers['actv_repair_type']);
    if (repairType.isEmpty) return const [];

    if (repairType.contains('soon')) {
      final locations = _labelsFor(
        [
          'cb_bathtub',
          'cb_shower_tray',
          'cb_shower_glass_cubicle',
          'cb_wc',
          'cb_wash_hand_basin',
          'cb_urinal',
          'cb_bidet',
          'cb_other_938',
        ],
        answers,
        {
          'cb_bathtub': 'bathtub',
          'cb_shower_tray': 'shower tray',
          'cb_shower_glass_cubicle': 'shower glass cubicle',
          'cb_wc': 'wc',
          'cb_wash_hand_basin': 'wash hand basin',
          'cb_urinal': 'urinal',
          'cb_bidet': 'bidet',
          'cb_other_938': 'other',
        },
      );
      _addOther(answers, 'cb_other_938', 'et_other_914', locations);
      final defects = _labelsFor(
        [
          'cb_cracked',
          'cb_loose',
          'cb_slightly_leaking',
          'cb_worn',
          'cb_stained',
          'cb_broken',
          'cb_damaged',
          'cb_partially_blocked',
          'cb_other_618',
        ],
        answers,
        {
          'cb_cracked': 'cracked',
          'cb_loose': 'loose',
          'cb_slightly_leaking': 'slightly leaking',
          'cb_worn': 'worn',
          'cb_stained': 'stained',
          'cb_broken': 'broken',
          'cb_damaged': 'damaged',
          'cb_partially_blocked': 'partially blocked',
          'cb_other_618': 'other',
        },
      );
      _addOther(answers, 'cb_other_618', 'et_other_149', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_BATHROOM_FITTINGS}', '{BATHROOM_FITTINGS_REPAIR_SOON}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{BFR_SOON_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{BFR_SOON_DEFECT}', _toWords(defects).toLowerCase())
          .replaceAll('{IS_ARE}', _isAre(locations));
      return _split(_normalize(template));
    }

    if (repairType.contains('now')) {
      final locations = _labelsFor(
        [
          'cb_bathtub_52',
          'cb_shower_tray_31',
          'cb_shower_glass_cubicle_24',
          'cb_wc_89',
          'cb_wash_hand_basin_60',
          'cb_urinal_90',
          'cb_bidet_13',
          'cb_other_609',
        ],
        answers,
        {
          'cb_bathtub_52': 'bathtub',
          'cb_shower_tray_31': 'shower tray',
          'cb_shower_glass_cubicle_24': 'shower glass cubicle',
          'cb_wc_89': 'wc',
          'cb_wash_hand_basin_60': 'wash hand basin',
          'cb_urinal_90': 'urinal',
          'cb_bidet_13': 'bidet',
          'cb_other_609': 'other',
        },
      );
      _addOther(answers, 'cb_other_609', 'et_other_791', locations);
      final defects = _labelsFor(
        [
          'cb_badly_leaking_38',
          'cb_very_loose_28',
          'cb_badly_cracked_62',
          'cb_not_working_33',
          'cb_not_connected_98',
          'cb_poorly_secured_48',
          'cb_blocked_34',
          'cb_other_398',
        ],
        answers,
        {
          'cb_badly_leaking_38': 'badly leaking',
          'cb_very_loose_28': 'very loose',
          'cb_badly_cracked_62': 'badly cracked',
          'cb_not_working_33': 'not working',
          'cb_not_connected_98': 'not connected',
          'cb_poorly_secured_48': 'poorly secured',
          'cb_blocked_34': 'blocked',
          'cb_other_398': 'other',
        },
      );
      _addOther(answers, 'cb_other_398', 'et_other_824', defects);
      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_BATHROOM_FITTINGS}', '{BATHROOM_FITTINGS_REPAIR_NOW}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{BFR_NOW_LOCATION}', _toWords(locations).toLowerCase())
          .replaceAll('{BFR_NOW_DEFECT}', _toWords(defects).toLowerCase())
          .replaceAll('{IS_ARE}', _isAre(locations));
      final phrases = _split(_normalize(template)).toList();
      if (_isChecked(answers['cb_badly_cracked_62']) || _isChecked(answers['cb_poorly_secured_48'])) {
        final extra = _sub('{F_BATHROOM_FITTINGS}', '{IF_CRACKED_OR_POORLY_SECURED_IS_SELECTED}');
        if (extra.isNotEmpty) {
          phrases.addAll(_split(_normalize(extra)));
        }
      }
      return phrases;
    }

    return const [];
  }

  List<String> _bathroomFittingsNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_BATHROOM_FITTINGS}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _wallsAndPartitionsAbout(Map<String, String> answers) {
    final wallTypes = _labelsFor(
      ['cb_solid', 'cb_stud', 'cb_lath_and_plaster', 'cb_concrete', 'cb_other_590'],
      answers,
      {
        'cb_solid': 'solid',
        'cb_stud': 'stud',
        'cb_lath_and_plaster': 'lath and plaster',
        'cb_concrete': 'concrete',
        'cb_other_590': 'other',
      },
    );
    _addOther(answers, 'cb_other_590', 'et_other_428', wallTypes);

    final finishesType = _labelsFor(
      [
        'cb_rendered',
        'cb_paper_lined',
        'cb_painted',
        'cb_textured',
        'cb_timber_cladded',
        'cb_tiled',
        'cb_wallpapered',
        'cb_other_606',
      ],
      answers,
      {
        'cb_rendered': 'rendered',
        'cb_paper_lined': 'paper lined',
        'cb_painted': 'painted',
        'cb_textured': 'textured',
        'cb_timber_cladded': 'timber cladded',
        'cb_tiled': 'tiled',
        'cb_wallpapered': 'wallpapered',
        'cb_other_606': 'other',
      },
    );
    _addOther(answers, 'cb_other_606', 'et_other_427', finishesType);

    final finishesPrefix = _isChecked(answers['actv_finishes']) ? 'a mixture of' : '';
    final condition = _cleanLower(answers['actv_condition']);

    String wallTypeText = '';
    if (wallTypes.isNotEmpty) {
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{WALL_TYPE}');
      if (template.isNotEmpty) {
        wallTypeText = template.replaceAll('{WAP_WALLS_TYPE}', _toWords(wallTypes).toLowerCase());
      }
    }

    String finishesText = '';
    if (finishesType.isNotEmpty) {
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{WALL_FINISHES}');
      if (template.isNotEmpty) {
        finishesText = template
            .replaceAll('{WAP_WALLS_FINISHES}', finishesPrefix)
            .replaceAll('{WAP_WALLS_FINISHES_TYPE}', _toWords(finishesType).toLowerCase())
            .replaceAll(RegExp(r'\\s{2,}'), ' ')
            .trim();
      }
    }

    String conditionText = '';
    if (condition.isNotEmpty) {
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{WALL_CONDITION}');
      if (template.isNotEmpty) {
        conditionText = template.replaceAll('{WAP_WALLS_CONDITION}', condition);
      }
    }

    final lathText = _isChecked(answers['cb_lath_and_plaster'])
        ? _sub('{F_WALLS_AND_PARTITIONS}', '{IF_LATH_AND_PLASTER_IS_SELECTED}')
        : '';
    final texturedText = _isChecked(answers['cb_textured'])
        ? _sub('{F_WALLS_AND_PARTITIONS}', '{IF_TEXTURED_IS_SELECTED}')
        : '';
    final tiledText =
        _isChecked(answers['cb_tiled']) ? _sub('{F_WALLS_AND_PARTITIONS}', '{IF_TILED_IS_SELECTED}') : '';

    if ([wallTypeText, finishesText, conditionText, lathText, texturedText, tiledText].every((v) => v.isEmpty)) {
      return const [];
    }

    final standardText = _sub('{F_WALLS_AND_PARTITIONS}', '{STANDARD_TEXT}');
    final wrapper = _phraseTexts['{F_WALLS_AND_PARTITIONS}'] ?? '';
    if (wrapper.isEmpty) return const [];

    final result = wrapper
        .replaceAll('{STANDARD_TEXT}', standardText)
        .replaceAll('{WALL_TYPE}', wallTypeText)
        .replaceAll('{WALL_FINISHES}', finishesText)
        .replaceAll('{WALL_CONDITION}', conditionText)
        .replaceAll('{REPAIRS_CONDENSATION}', '')
        .replaceAll('{DAMPNESS_NOTED}', '')
        .replaceAll('{DAMPNESS_CAUSES}', '')
        .replaceAll('{MOVEMENT_CRACKS}', '')
        .replaceAll('{REPAIRS_WALL_REPAIR_SOON}', '')
        .replaceAll('{REPAIRS_WALL_REPAIR_NOW}', '')
        .replaceAll('{IF_HOLLOW_IS_SELECTED}', '')
        .replaceAll('{IF_LATH_AND_PLASTER_IS_SELECTED}', lathText)
        .replaceAll('{IF_HOLLOW_OVER_LARGE_AREA_IS_SELECTED}', '')
        .replaceAll('{IF_STUD_WALL_AND_CRACKED_OR_BADLY_CRACKED_IS_SELECTED}', '')
        .replaceAll('{REPAIRS_SEALANTS}', '')
        .replaceAll('{REPAIRS_REMOVED_WALL}', '')
        .replaceAll('{IF_TEXTURED_IS_SELECTED}', texturedText)
        .replaceAll('{IF_TILED_IS_SELECTED}', tiledText)
        .replaceAll('{CONDITION_RATING}', '')
        .replaceAll('{NOTES}', '');

    return _split(_normalize(result));
  }

  List<String> _wallsAndPartitionsCondensation(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];

    if (status.contains('none')) {
      final template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_CONDENSATION_NONE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }

    if (status.contains('noted')) {
      final locations = _labelsFor(
        ['cb_property', 'cb_lounge', 'cb_bedroom', 'cb_kitchen', 'cb_bathroom', 'cb_other_857'],
        answers,
        {
          'cb_property': 'property',
          'cb_lounge': 'lounge',
          'cb_bedroom': 'bedroom',
          'cb_kitchen': 'kitchen',
          'cb_bathroom': 'bathroom',
          'cb_other_857': 'other',
        },
      );
      _addOther(answers, 'cb_other_857', 'et_other_179', locations);
      if (locations.isEmpty) return const [];
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_CONDENSATION_NOTED}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{WAPR_CONDENSATION_NOTED_LOCATION}', _toWords(locations).toLowerCase());
      return _split(_normalize(template));
    }

    return const [];
  }

  List<String> _wallsAndPartitionsDampness(Map<String, String> answers) {
    final status = _cleanLower(answers['damp_status']);
    if (status.isEmpty) return const [];

    final phrases = <String>[];
    if (status.contains('none')) {
      final template = _sub('{F_WALLS_AND_PARTITIONS}', '{DAMPNESS_NONE}');
      if (template.isNotEmpty) {
        phrases.addAll(_split(_normalize(template)));
      }
      return phrases;
    }

    if (status.contains('present')) {
      final location = (answers['et_location'] ?? '').trim();
      if (location.isEmpty) return const [];
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{DAMPNESS_NOTED}');
      if (template.isNotEmpty) {
        template = template.replaceAll('{WAP_DAMP_LOCATION}', location.toLowerCase());
        phrases.addAll(_split(_normalize(template)));
      }

      final causeStatus = _cleanLower(answers['actv_status_91']);
      if (causeStatus.contains('known')) {
        final causes = _labelsFor(
          [
            'cb_blocked_gullies',
            'cb_leaking_pipes',
            'cb_defective_rainwater_goods',
            'cb_bridged_damp_proof_course',
            'cb_rising_damp',
            'cb_other',
          ],
          answers,
          {
            'cb_blocked_gullies': 'blocked gullies',
            'cb_leaking_pipes': 'leaking pipes',
            'cb_defective_rainwater_goods': 'defective rainwater goods',
            'cb_bridged_damp_proof_course': 'bridged damp proof course',
            'cb_rising_damp': 'rising damp',
            'cb_other': 'other',
          },
        );
        _addOther(answers, 'cb_other', 'et_other_839', causes);
        if (causes.isNotEmpty) {
          var causesTemplate = _sub('{F_WALLS_AND_PARTITIONS}', '{CAUSES_KNOWN}');
          if (causesTemplate.isNotEmpty) {
            causesTemplate =
                causesTemplate.replaceAll('{WAP_DAMP_KNOWN_CAUSED_BY}', _toWords(causes).toLowerCase());
            phrases.addAll(_split(_normalize(causesTemplate)));
          }
        }
      } else if (causeStatus.contains('unknown')) {
        final causesTemplate = _sub('{F_WALLS_AND_PARTITIONS}', '{CAUSES_UNKNOWN}');
        if (causesTemplate.isNotEmpty) {
          phrases.addAll(_split(_normalize(causesTemplate)));
        }
      }
    }

    return phrases;
  }

  List<String> _wallsAndPartitionsMovementCracks(Map<String, String> answers) {
    final value = _cleanLower(answers['android_material_design_spinner3']);
    if (value.isEmpty) return const [];
    if (value.contains('none')) {
      final template = _sub('{F_WALLS_AND_PARTITIONS}', '{MOVEMENT_CRACKS_NONE}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (value.contains('normal')) {
      final template = _sub('{F_WALLS_AND_PARTITIONS}', '{MOVEMENT_CRACKS_NORMAL}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    if (value.contains('multiple')) {
      final template = _sub('{F_WALLS_AND_PARTITIONS}', '{MOVEMENT_CRACKS_SEVERAL_ELEVATIONS}');
      if (template.isEmpty) return const [];
      return _split(_normalize(template));
    }
    return const [];
  }

  List<String> _wallsAndPartitionsWallRepair(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_repair_type']);
    if (status.isEmpty) return const [];

    final phrases = <String>[];
    final isStud = _isChecked(answers['cb_stud']);

    if (status.contains('now')) {
      final locations = _labelsFor(
        ['cb_property', 'cb_lounge', 'cb_bedroom', 'cb_kitchen', 'cb_bathroom', 'cb_other_752'],
        answers,
        {
          'cb_property': 'property',
          'cb_lounge': 'lounge',
          'cb_bedroom': 'bedroom',
          'cb_kitchen': 'kitchen',
          'cb_bathroom': 'bathroom',
          'cb_other_752': 'other',
        },
      );
      _addOther(answers, 'cb_other_752', 'et_other_666', locations);

      final defects = _labelsFor(
        [
          'cb_badly_cracked_17',
          'cb_hollow_over_large_areas_90',
          'cb_badly_stained_90',
          'cb_largely_missing_86',
          'cb_affected_by_dampness_59',
          'cb_other_1072',
        ],
        answers,
        {
          'cb_badly_cracked_17': 'badly cracked',
          'cb_hollow_over_large_areas_90': 'hollow over large areas',
          'cb_badly_stained_90': 'badly stained',
          'cb_largely_missing_86': 'largely missing',
          'cb_affected_by_dampness_59': 'affected by dampness',
          'cb_other_1072': 'other',
        },
      );
      _addOther(answers, 'cb_other_1072', 'et_other_164', defects);

      if (locations.isNotEmpty && defects.isNotEmpty) {
        var template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_WALL_REPAIR_NOW}');
        if (template.isNotEmpty) {
          template = template
              .replaceAll('{WAPR_WALL_NOW_LOCATION}', _toWords(locations).toLowerCase())
              .replaceAll('{WAPR_WALL_NOW_DEFECT}', _toWords(defects).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }

      if (_isChecked(answers['cb_hollow_over_large_areas_90'])) {
        final template = _sub('{F_WALLS_AND_PARTITIONS}', '{IF_HOLLOW_OVER_LARGE_AREA_IS_SELECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }

      if (isStud && _isChecked(answers['cb_badly_cracked_17'])) {
        final template =
            _sub('{F_WALLS_AND_PARTITIONS}', '{IF_STUD_WALL_AND_CRACKED_OR_BADLY_CRACKED_IS_SELECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    if (status.contains('soon')) {
      final locations = _labelsFor(
        ['cb_property_17', 'cb_lounge_31', 'cb_bedroom_13', 'cb_kitchen_64', 'cb_bathroom_85', 'cb_other_251'],
        answers,
        {
          'cb_property_17': 'property',
          'cb_lounge_31': 'lounge',
          'cb_bedroom_13': 'bedroom',
          'cb_kitchen_64': 'kitchen',
          'cb_bathroom_85': 'bathroom',
          'cb_other_251': 'other',
        },
      );
      _addOther(answers, 'cb_other_251', 'et_other_538', locations);

      final defects = _labelsFor(
        ['cb_cracked', 'cb_hollow', 'cb_stained', 'cb_damp', 'cb_missing_in_places', 'cb_other_702'],
        answers,
        {
          'cb_cracked': 'cracked',
          'cb_hollow': 'hollow',
          'cb_stained': 'stained',
          'cb_damp': 'damp',
          'cb_missing_in_places': 'missing in places',
          'cb_other_702': 'other',
        },
      );
      _addOther(answers, 'cb_other_702', 'et_other_207', defects);

      if (locations.isNotEmpty && defects.isNotEmpty) {
        var template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_WALL_REPAIR_SOON}');
        if (template.isNotEmpty) {
          template = template
              .replaceAll('{WAPR_WALL_SOON_LOCATION}', _toWords(locations).toLowerCase())
              .replaceAll('{WAPR_WALL_SOON_DEFECT}', _toWords(defects).toLowerCase());
          phrases.addAll(_split(_normalize(template)));
        }
      }

      if (_isChecked(answers['cb_hollow'])) {
        final template = _sub('{F_WALLS_AND_PARTITIONS}', '{IF_HOLLOW_IS_SELECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }

      if (isStud && _isChecked(answers['cb_cracked'])) {
        final template =
            _sub('{F_WALLS_AND_PARTITIONS}', '{IF_STUD_WALL_AND_CRACKED_OR_BADLY_CRACKED_IS_SELECTED}');
        if (template.isNotEmpty) {
          phrases.addAll(_split(_normalize(template)));
        }
      }
    }

    return phrases;
  }

  List<String> _wallsAndPartitionsSealants(Map<String, String> answers) {
    final locations = _labelsFor(
      ['cb_hand_basin', 'cb_bathtub', 'cb_shower_tray', 'cb_kitchen_sink', 'cb_other_645'],
      answers,
      {
        'cb_hand_basin': 'wash hand basin',
        'cb_bathtub': 'bathtub',
        'cb_shower_tray': 'shower tray',
        'cb_kitchen_sink': 'kitchen sink',
        'cb_other_645': 'other',
      },
    );
    _addOther(answers, 'cb_other_645', 'et_other_852', locations);

    final defects = _labelsFor(
      ['cb_damaged', 'cb_partly_missing', 'cb_poorly_applied', 'cb_other_936'],
      answers,
      {
        'cb_damaged': 'damaged',
        'cb_partly_missing': 'partly missing',
        'cb_poorly_applied': 'poorly applied',
        'cb_other_936': 'other',
      },
    );
    _addOther(answers, 'cb_other_936', 'et_other_233', defects);

    if (locations.isEmpty || defects.isEmpty) return const [];
    var template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_SEALANTS}');
    if (template.isEmpty) return const [];
    template = template
        .replaceAll('{WAPR_SEALANTS_LOCATION}', _toWords(locations).toLowerCase())
        .replaceAll('{WAPR_SEALANTS_DEFECT}', _toWords(defects).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _wallsAndPartitionsRemovedWall(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_condition']);
    if (status.isEmpty) return const [];

    if (status.contains('ok')) {
      final locations = _labelsFor(
        ['cb_lounge', 'cb_bedroom', 'cb_kitchen', 'cb_bathroom', 'cb_other_752'],
        answers,
        {
          'cb_lounge': 'lounge',
          'cb_bedroom': 'bedroom',
          'cb_kitchen': 'kitchen',
          'cb_bathroom': 'bathroom',
          'cb_other_752': 'other',
        },
      );
      _addOther(answers, 'cb_other_752', 'et_other_666', locations);
      if (locations.isEmpty) return const [];
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_REMOVED_WALL_OK}');
      if (template.isEmpty) return const [];
      template = template.replaceAll('{WAPR_RW_CONDITION_OK}', _toWords(locations).toLowerCase());
      return _split(_normalize(template));
    }

    if (status.contains('repair')) {
      final locations = _labelsFor(
        ['cb_lounge_31', 'cb_bedroom_13', 'cb_kitchen_64', 'cb_bathroom_85', 'cb_other_251'],
        answers,
        {
          'cb_lounge_31': 'lounge',
          'cb_bedroom_13': 'bedroom',
          'cb_kitchen_64': 'kitchen',
          'cb_bathroom_85': 'bathroom',
          'cb_other_251': 'other',
        },
      );
      _addOther(answers, 'cb_other_251', 'et_other_538', locations);

      final defects = _labelsFor(
        ['cb_distorted', 'cb_cracked', 'cb_poorly_supported', 'cb_other_518'],
        answers,
        {
          'cb_distorted': 'distorted',
          'cb_cracked': 'cracked',
          'cb_poorly_supported': 'poorly supported',
          'cb_other_518': 'other',
        },
      );
      _addOther(answers, 'cb_other_518', 'et_other_491', defects);

      if (locations.isEmpty || defects.isEmpty) return const [];
      var template = _sub('{F_WALLS_AND_PARTITIONS}', '{REPAIRS_REMOVED_WALL_REPAIR}');
      if (template.isEmpty) return const [];
      template = template
          .replaceAll('{WAPR_RW_CONDITION_REPAIR}', _toWords(locations).toLowerCase())
          .replaceAll('{WAPR_RW_CONDITION_REPAIR_DEFECT}', _toWords(defects).toLowerCase());
      return _split(_normalize(template));
    }

    return const [];
  }

  List<String> _wallsAndPartitionsNotInspected(Map<String, String> answers) {
    if (!_isChecked(answers['cb_not_inspected'])) return const [];
    final template = _sub('{F_WALLS_AND_PARTITIONS}', '{NOT_INSPECTED}');
    if (template.isEmpty) return const [];
    return _split(_normalize(template));
  }

  List<String> _mainWallRepairWallTie(Map<String, String> answers) {
    final walls = _labelsFor(
      ['cb_front', 'cb_side', 'cb_rear', 'cb_other_608'],
      answers,
      {
        'cb_front': 'Front',
        'cb_side': 'Side',
        'cb_rear': 'Rear',
        'cb_other_608': 'Other',
      },
    );
    _addOther(answers, 'cb_other_608', 'et_other_752', walls);
    if (walls.isEmpty) return const [];
    var template = _sub('{E_MAIN_WALL_REPAIR}', '{WALL_TIE_REPAIR}');
    if (template.isEmpty) return const [];
    template = template.replaceAll('{MAIN_WALL_REPAIR_WALL_TIE_REPAIR}', _toWords(walls).toLowerCase());
    return _split(_normalize(template));
  }

  List<String> _issuesRegulation(Map<String, String> answers) {
    final phrases = <String>[];

    final buildingRegulation = _labelsFor(
      ['cb_removed_wall', 'cb_replacement_roof_covering', 'cb_conservatory', 'cb_other_638'],
      answers,
      {
        'cb_removed_wall': 'Removed wall',
        'cb_replacement_roof_covering': 'Replacement roof covering',
        'cb_conservatory': 'Conservatory',
        'cb_other_638': 'Other',
      },
    );
    _addOther(answers, 'cb_other_638', 'et_other_332', buildingRegulation);
    if (buildingRegulation.isNotEmpty) {
      phrases.add('Building Regulation: ${_toWords(buildingRegulation)}.');
    }

    final planningPermission = _labelsFor(
      ['cb_kitchen_extension', 'cb_rear_extension', 'cb_loft_conversion', 'cb_other_459'],
      answers,
      {
        'cb_kitchen_extension': 'Kitchen extension',
        'cb_rear_extension': 'Rear extension',
        'cb_loft_conversion': 'Loft conversion',
        'cb_other_459': 'Other',
      },
    );
    _addOther(answers, 'cb_other_459', 'et_other_575', planningPermission);
    if (planningPermission.isNotEmpty) {
      phrases.add('Planning permission: ${_toWords(planningPermission)}.');
    }

    final glazedSections = _labelsFor(
      ['cb_windows', 'cb_doors', 'cb_conservatory_glazed', 'cb_porch', 'cb_other_952'],
      answers,
      {
        'cb_windows': 'Windows',
        'cb_doors': 'Doors',
        'cb_conservatory_glazed': 'Conservatory',
        'cb_porch': 'Porch',
        'cb_other_952': 'Other',
      },
    );
    _addOther(answers, 'cb_other_952', 'et_other_154', glazedSections);
    if (glazedSections.isNotEmpty) {
      phrases.add('Glazed Sections: ${_toWords(glazedSections)}.');
    }

    if (_isChecked(answers['cb_new_build'])) {
      phrases.add('New build.');
    }

    if (_isChecked(answers['cb_converted_building'])) {
      phrases.add('Converted building.');
      final status = (answers['actv_conversion_status'] ?? '').trim();
      if (status.isNotEmpty) {
        phrases.add('Conversion status: $status.');
      }
      final builtAs = (answers['actv_before_built_as'] ?? '').trim();
      if (builtAs.isNotEmpty) {
        phrases.add('Originally built as $builtAs.');
      }
    }

    if (_isChecked(answers['cb_conservation'])) {
      phrases.add('Conservation area.');
    }

    if (_isChecked(answers['cb_listed_building'])) {
      phrases.add('Listed building.');
    }

    return phrases;
  }

  List<String> _issuesGuarantees(Map<String, String> answers) {
    final phrases = <String>[];

    final glazedSections = _labelsFor(
      ['cb_chimney_stack', 'cb_rainwater_goods', 'cb_conservatory', 'cb_porch', 'cb_other_471'],
      answers,
      {
        'cb_chimney_stack': 'windows',
        'cb_rainwater_goods': 'doors',
        'cb_conservatory': 'conservatory',
        'cb_porch': 'porch',
        'cb_other_471': 'other',
      },
    );
    _addOther(answers, 'cb_other_471', 'et_other_433', glazedSections);
    if (glazedSections.isNotEmpty) {
      phrases.add('Glazed Sections: ${_toWords(glazedSections)}.');
    }

    if (_isChecked(answers['cb_private_road'])) {
      phrases.add('DPC Treatment.');
    }
    if (_isChecked(answers['cb_party_walls'])) {
      phrases.add('Removed Wall.');
    }
    if (_isChecked(answers['cb_tenanted'])) {
      phrases.add('Building Work.');
    }

    return phrases;
  }

  List<String> _issuesOtherMatters(Map<String, String> answers) {
    final phrases = <String>[];

    if (_isChecked(answers['cb_freehold'])) {
      phrases.add('Freehold.');
    }
    if (_isChecked(answers['cb_leasehold'])) {
      phrases.add('Leasehold.');
    }
    if (_isChecked(answers['cb_right_of_way'])) {
      phrases.add('Right of Way.');
    }

    final sharedStacks = _labelsFor(
      ['cb_chimney_stack', 'cb_rainwater_goods', 'cb_other_471'],
      answers,
      {
        'cb_chimney_stack': 'Chimney stack(s)',
        'cb_rainwater_goods': 'Rainwater goods',
        'cb_other_471': 'Other',
      },
    );
    _addOther(answers, 'cb_other_471', 'et_other_433', sharedStacks);
    if (sharedStacks.isNotEmpty) {
      phrases.add('Shared Stacks and RWG: ${_toWords(sharedStacks)}.');
    }

    if (_isChecked(answers['cb_private_road'])) {
      final condition = (answers['actv_condition'] ?? '').trim();
      if (condition.isNotEmpty) {
        phrases.add('Private Road: $condition.');
      } else {
        phrases.add('Private Road.');
      }
    }

    if (_isChecked(answers['cb_party_walls'])) {
      phrases.add('Party Walls.');
    }
    if (_isChecked(answers['cb_tenanted'])) {
      phrases.add('Tenanted.');
    }

    return phrases;
  }

  List<String> _risksRiskToBuilding(Map<String, String> answers) {
    final phrases = <String>[];

    final movement = (answers['actv_movement_status'] ?? '').trim();
    if (movement.isNotEmpty) {
      phrases.add('Movement status: $movement.');
    }

    final subsidence = (answers['actv_subsidence_status'] ?? '').trim();
    if (subsidence.isNotEmpty) {
      phrases.add('Subsidence status: $subsidence.');
    }

    if (subsidence.isNotEmpty && subsidence.toLowerCase() != 'none') {
      final locations = _labelsFor(
        ['cb_window_and_door_lintel', 'cb_extension_joints', 'cb_bay_windows', 'cb_other_619'],
        answers,
        {
          'cb_window_and_door_lintel': 'Window and door lintel',
          'cb_extension_joints': 'Extension joints',
          'cb_bay_windows': 'Bay windows',
          'cb_other_619': 'Other',
        },
      );
      _addOther(answers, 'cb_other_619', 'et_other_604', locations);
      if (locations.isNotEmpty) {
        phrases.add('Subsidence location: ${_toWords(locations)}.');
      }
    }

    final dampness = (answers['actv_dampness_status'] ?? '').trim();
    if (dampness.isNotEmpty) {
      phrases.add('Dampness status: $dampness.');
    }

    final timber = (answers['actv_timber_sefect_status'] ?? '').trim();
    if (timber.isNotEmpty) {
      phrases.add('Timber defect status: $timber.');
    }

    if (_isChecked(answers['cb_near_by_tree'])) {
      phrases.add('Nearby trees.');
    }

    return phrases;
  }

  List<String> _risksOther(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_not_applicable'])) {
      phrases.add('Not Applicable.');
      return phrases;
    }

    final proximity = _labelsFor(
      ['cb_airport', 'cb_train_station', 'cb_train_line', 'cb_motorway', 'cb_other_741'],
      answers,
      {
        'cb_airport': 'Airport',
        'cb_train_station': 'Train Station',
        'cb_train_line': 'Train Line',
        'cb_motorway': 'Motorway',
        'cb_other_741': 'Other',
      },
    );
    _addOther(answers, 'cb_other_741', 'et_other_775', proximity);
    if (proximity.isNotEmpty) {
      phrases.add('Proximity: ${_toWords(proximity)}.');
    }

    return phrases;
  }

  List<String> _risksRepairOrImprove(Map<String, String> answers) {
    if (_isChecked(answers['cb_repair_or_improve'])) {
      return const ['Repair or improve the property.'];
    }
    return const [];
  }

  static bool _isChecked(String? value) {
    final v = (value ?? '').toLowerCase();
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
        result.add(labels[id] ?? id);
      }
    }
    return result;
  }

  static void _addOther(
    Map<String, String> answers,
    String checkboxId,
    String textId,
    List<String> items, {
    String fallback = 'Other',
  }) {
    if (_isChecked(answers[checkboxId])) {
      final text = (answers[textId] ?? '').trim();
      items.add(text.isEmpty ? fallback : text);
    }
  }

  static String _cleanLower(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  static String _chimneyPhraseCode(bool isMulti) {
    return isMulti ? '{E_CHIMNEY_MULTI_STACK}' : '{E_CHIMNEY_SINGLE_STACK}';
  }

  static String _toWords(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  static String _isAre(List<String> items) {
    return items.length > 1 ? 'are' : 'is';
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
      final bedrooms = (answers['android_material_design_spinner7'] ?? '').trim();
      final flatStyle = (answers['android_material_design_spinner8'] ?? '').trim();
      final floorLocation = (answers['android_material_design_spinner5'] ?? '').trim();
      final noOfStorey = (answers['android_material_design_spinner6'] ?? '').trim();
      final totalFlats = (answers['android_material_design_spinner9'] ?? '').trim();
      final resolved = _normalize(template)
          .replaceAll('{FLAT_NO_OF_BEDROOMS}', bedrooms.isNotEmpty ? bedrooms : '...')
          .replaceAll('{FLAT_TYPE}', flatStyle.isNotEmpty ? flatStyle.toLowerCase() : '...')
          .replaceAll('{FLAT_FLOOR_LOCATION}', floorLocation.isNotEmpty ? floorLocation.toLowerCase() : '...')
          .replaceAll('{FLAT_NO_OF_STOREY}', noOfStorey.isNotEmpty ? noOfStorey.toLowerCase() : '...')
          .replaceAll('{FLAT_TOTAL_FLATS}', totalFlats.isNotEmpty ? totalFlats.toLowerCase() : '...');
      return _split(resolved);
    }

    final template = _phraseTexts['{D_PROPERTY_TYPE_HOUSE}'] ?? '';
    if (template.isEmpty) return const [];
    final subType = (answers['android_material_design_spinner3'] ?? '').trim();
    final bedrooms = (answers['android_material_design_spinner4'] ?? '').trim();
    final resolved = _normalize(template)
        .replaceAll('{HOUSE_SUB_TYPE}', subType.isNotEmpty ? subType.toLowerCase() : '...')
        .replaceAll('{HOUSE_TYPE}', type.toLowerCase())
        .replaceAll('{HOUSE_NO_OF_BEDROOMS}', bedrooms.isNotEmpty ? bedrooms : '...');
    return _split(resolved);
  }

  List<String> _propertyConstruction(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['ch1'])) items.add('traditional materials and techniques');
    if (_isChecked(answers['ch2'])) items.add('solid wall');
    if (_isChecked(answers['ch3'])) items.add('cavity wall');
    if (_isChecked(answers['ch4'])) items.add('timber frame');
    if (_isChecked(answers['ch5'])) items.add('steel frame');
    if (_isChecked(answers['ch6'])) items.add('concrete frame');
    if (_isChecked(answers['ch7'])) {
      final other = (answers['etPropertyTypeOther'] ?? '').trim();
      items.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (items.isEmpty) return const [];
    return ['The property is of ${_toWords(items)} construction.'];
  }

  List<String> _propertyBuiltYear(Map<String, String> answers) {
    final year = (answers['android_material_design_spinner'] ?? '').trim();
    if (year.isEmpty) return const [];
    final source = (answers['android_material_design_spinner5'] ?? '').trim().toLowerCase();
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
    final builtWith = <String>[];
    if (_isChecked(answers['ch3'])) builtWith.add('factory made trusses');
    if (_isChecked(answers['ch4'])) builtWith.add('traditional cut timber construction');
    if (_isChecked(answers['ch5'])) {
      final other = (answers['etBuiltWithOther'] ?? '').trim();
      builtWith.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final covering = <String>[];
    if (_isChecked(answers['ch6'])) covering.add('tiles');
    if (_isChecked(answers['ch7'])) covering.add('sheets');
    if (_isChecked(answers['ch8'])) covering.add('concrete');
    if (_isChecked(answers['ch9'])) covering.add('clay');
    if (_isChecked(answers['ch10'])) covering.add('natural');
    if (_isChecked(answers['ch11'])) covering.add('composite');
    if (_isChecked(answers['ch12'])) covering.add('mineral felt');
    if (_isChecked(answers['ch13'])) covering.add('rubber');
    if (_isChecked(answers['ch14'])) covering.add('fiberglass');
    if (_isChecked(answers['ch15'])) covering.add('single ply membrane');
    if (_isChecked(answers['ch16'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      covering.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (types.isEmpty && builtWith.isEmpty && covering.isEmpty) return const [];
    final phrases = <String>[];
    if (types.isNotEmpty) {
      phrases.add('Roof type: ${_toWords(types)}.');
    }
    if (builtWith.isNotEmpty) {
      phrases.add('Built with: ${_toWords(builtWith)}.');
    }
    if (covering.isNotEmpty) {
      phrases.add('Covered with: ${_toWords(covering)}.');
    }
    return phrases;
  }

  List<String> _propertyGroundArea(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['ch1'])) items.add('residential');
    if (_isChecked(answers['ch2'])) items.add('commercial');
    if (_isChecked(answers['ch3'])) items.add('rural');
    if (_isChecked(answers['ch4'])) items.add('conservation');
    if (_isChecked(answers['ch5'])) {
      final other = (answers['etCoveredWithOther'] ?? '').trim();
      items.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (items.isEmpty) return const [];
    return ['The property is in a ${_toWords(items)} area.'];
  }

  List<String> _propertyExtended(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('not extended')) {
      return _resolve('{D_PRO_EXTENDED_STATUS_NOT_EXTENDED}');
    }
    final location = (answers['android_material_design_spinner3'] ?? '').trim();
    final year = (answers['textView3'] ?? '').trim();
    if (status == 'known') {
      final template = _phraseTexts['{D_PRO_EXTENDED_STATUS_KNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_EXTENDED_LOCATION}', location.isNotEmpty ? location.toLowerCase() : '...')
          .replaceAll('{PRO_EXTENDED_DATE}', year.isNotEmpty ? year : '...');
      return _split(resolved);
    }
    if (status == 'unknown') {
      final template = _phraseTexts['{D_PRO_EXTENDED_STATUS_UNKNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_EXTENDED_LOCATION}', location.isNotEmpty ? location.toLowerCase() : '...');
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
    if (wallTypes.isEmpty && finishes.isEmpty && cladding.isEmpty) return const [];
    final phrases = <String>[];
    if (wallTypes.isNotEmpty) {
      phrases.add('Extension walls: ${_toWords(wallTypes)}.');
    }
    if (finishes.isNotEmpty) {
      phrases.add('Finishes: ${_toWords(finishes)}.');
    }
    if (cladding.isNotEmpty) {
      phrases.add('Cladding: ${_toWords(cladding)}.');
    }
    return phrases;
  }

  List<String> _propertyParking(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
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
    if (_isChecked(answers['ch6'])) types.add('residents parking');
    if (_isChecked(answers['ch7'])) {
      final other = (answers['EtOther'] ?? answers['other'] ?? '').trim();
      types.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (types.isEmpty) return const ['The property comes with parking.'];
    return ['The property comes with ${_toWords(types)} parking.'];
  }

  List<String> _sectionDGarden(Map<String, String> answers, String gardenName) {
    final surfaceTypes = <String>[];
    if (_isChecked(answers['ch1'])) surfaceTypes.add('paved');
    if (_isChecked(answers['ch2'])) surfaceTypes.add('lawned');
    if (_isChecked(answers['ch3'])) surfaceTypes.add('decked');
    if (_isChecked(answers['ch4'])) surfaceTypes.add('laid with gravel');
    if (_isChecked(answers['ch5'])) surfaceTypes.add('laid with stone chippings');
    if (_isChecked(answers['ch6'])) surfaceTypes.add('laid with tile chippings');
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
    final phrases = <String>[];
    final label = '${gardenName[0].toUpperCase()}${gardenName.substring(1)}';
    if (surfaceTypes.isNotEmpty) {
      phrases.add('$label garden: ${_toWords(surfaceTypes)}.');
    }
    if (noBoundary) {
      phrases.add('No boundary fencing.');
    } else if (fencing.isNotEmpty) {
      phrases.add('Boundary fencing: ${_toWords(fencing)}.');
    }
    return phrases;
  }

  List<String> _propertyConverted(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('not converted')) {
      return _resolve('{D_PRO_CONVERSION_STATUS_NOT_CONVERTED}');
    }
    final proType = (answers['android_material_design_spinner2'] ?? '').trim();
    final subType = (answers['android_material_design_spinner3'] ?? '').trim();
    final year = (answers['textView3'] ?? '').trim();
    if (status == 'known') {
      final template = _phraseTexts['{D_PRO_CONVERSION_STATUS_KNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_CONVERSION_PRO_SUB_TYPE}', subType.isNotEmpty ? subType.toLowerCase() : '...')
          .replaceAll('{PRO_CONVERSION_PRO_TYPE}', proType.isNotEmpty ? proType.toLowerCase() : '...')
          .replaceAll('{PRO_CONVERSION_DATE}', year.isNotEmpty ? year : '...');
      return _split(resolved);
    }
    if (status == 'unknown') {
      final template = _phraseTexts['{D_PRO_CONVERSION_STATUS_UNKNOWN}'] ?? '';
      if (template.isEmpty) return const [];
      final resolved = _normalize(template)
          .replaceAll('{PRO_CONVERSION_PRO_SUB_TYPE}', subType.isNotEmpty ? subType.toLowerCase() : '...')
          .replaceAll('{PRO_CONVERSION_PRO_TYPE}', proType.isNotEmpty ? proType.toLowerCase() : '...');
      return _split(resolved);
    }
    return const [];
  }

  List<String> _propertyFlatInfo(Map<String, String> answers) {
    final onFloor = (answers['android_material_design_spinner'] ?? '').trim();
    if (onFloor.isEmpty) return const [];
    final template = _phraseTexts['{D_FLAT_INFORMATION}'] ?? '';
    if (template.isEmpty) return const [];
    final noOfStorey = (answers['android_material_design_spinner2'] ?? '').trim();
    final accessVia = (answers['android_material_design_spinner3'] ?? '').trim();
    final accessElevation = (answers['android_material_design_spinner4'] ?? '').trim();
    final resolved = _normalize(template)
        .replaceAll('{FLAT_INFO_PRO_ON_FLOOR}', onFloor.toLowerCase())
        .replaceAll('{FLAT_INFO_PRO_NO_OF_STOREY}', noOfStorey.isNotEmpty ? noOfStorey : '...')
        .replaceAll('{FLAT_INFO_PRO_ACCESS_VIA}', accessVia.isNotEmpty ? accessVia.toLowerCase() : '...')
        .replaceAll('{FLAT_INFO_PRO_ACCESS_ELEVATION}', accessElevation.isNotEmpty ? accessElevation.toLowerCase() : '...');
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
    final buildType = (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    final prefix = buildType.contains('mixture') ? 'a mixture of' : 'mainly of';
    return ['Floors: $prefix ${_toWords(items)} construction.'];
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
    if (glazing.isEmpty && materials.isEmpty) return const [];
    final phrases = <String>[];
    final mixType = (answers['android_material_design_spinner'] ?? '').trim().toLowerCase();
    final prefix = mixType.contains('mixture') ? 'a mixture of' : 'mainly of';
    if (glazing.isNotEmpty) {
      phrases.add('Windows: $prefix ${_toWords(glazing)} glazing.');
    }
    if (materials.isNotEmpty) {
      phrases.add('Window material: ${_toWords(materials)}.');
    }
    return phrases;
  }

  List<String> _gatedCommunity(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner3'] ?? '').trim().toLowerCase();
    if (status != 'yes') return const [];
    final text = _phraseTexts['{D_GROUND}::{GATED_COMMUNITY}'] ?? '';
    if (text.isNotEmpty) return _split(_normalize(text));
    return const ['The property is located within a gated development.'];
  }

  List<String> _energyEfficiency(Map<String, String> answers) {
    final current = (answers['android_material_design_spinner'] ?? '').trim();
    final potential = (answers['android_material_design_spinner2'] ?? '').trim();
    if (current.isEmpty && potential.isEmpty) return const [];
    final parts = <String>[];
    if (current.isNotEmpty) parts.add('Current $current');
    if (potential.isNotEmpty) parts.add('Potential $potential');
    return ['Energy Efficiency: ${parts.join(', ')}.'];
  }

  List<String> _energyEnvironmentalImpact(Map<String, String> answers) {
    final current = (answers['android_material_design_spinner'] ?? '').trim();
    final potential = (answers['android_material_design_spinner2'] ?? '').trim();
    if (current.isEmpty && potential.isEmpty) return const [];
    final parts = <String>[];
    if (current.isNotEmpty) parts.add('Current $current');
    if (potential.isNotEmpty) parts.add('Potential $potential');
    return ['Environmental Impact: ${parts.join(', ')}.'];
  }

  List<String> _estateLocation(Map<String, String> answers) {
    final location = (answers['android_material_design_spinner'] ?? '').trim();
    if (location.isEmpty) return const [];
    return ['The property is on a ${location.toLowerCase()} estate.'];
  }

  List<String> _propertyLocationDensity(Map<String, String> answers) {
    final wellNewly = (answers['android_material_design_spinner'] ?? '').trim();
    final from = (answers['android_material_design_spinner2'] ?? '').trim();
    final to = (answers['android_material_design_spinner20'] ?? '').trim();
    if (wellNewly.isEmpty && from.isEmpty && to.isEmpty) return const [];
    final phrases = <String>[];
    if (wellNewly.isNotEmpty) {
      phrases.add('The property is located in a ${wellNewly.toLowerCase()} established ${from.isNotEmpty ? from.toLowerCase() : '...'} to ${to.isNotEmpty ? to.toLowerCase() : '...'} density area.');
    }
    return phrases;
  }

  List<String> _propertyFacilities(Map<String, String> answers) {
    final value = (answers['android_material_design_spinner7'] ?? '').trim().toLowerCase();
    if (value.isEmpty) return const [];
    if (value == 'accessible') return _resolve('{D_FACILITY_ACCESSIBLE}');
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
    final status = (answers['android_material_design_spinner8'] ?? '').trim().toLowerCase();
    if (status.isEmpty) return const [];
    if (status.contains('no adverse')) {
      return _resolve('{D_LOCAL_ENVIRONMENT_NO_ADVERSE}');
    }
    final phrases = <String>[];
    final floodSources = <String>[];
    if (_isChecked(answers['ch1'])) floodSources.add('the sea');
    if (_isChecked(answers['ch2'])) floodSources.add('a river');
    if (_isChecked(answers['ch3'])) floodSources.add('a canal');
    if (_isChecked(answers['ch4'])) {
      final other = (answers['etFloodingOther'] ?? '').trim();
      floodSources.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (floodSources.isNotEmpty) {
      final template = _phraseTexts['{D_LOCAL_ENVIRONMENT_FLOODING}'] ?? '';
      if (template.isNotEmpty) {
        final resolved = _normalize(template)
            .replaceAll('{LOCAL_ENVIRONMENT_CLOSED_TO}', _toWords(floodSources));
        phrases.addAll(_split(resolved));
      }
    }
    final emfSources = <String>[];
    if (_isChecked(answers['ch5'])) emfSources.add('substation');
    if (_isChecked(answers['ch6'])) emfSources.add('pylons');
    if (_isChecked(answers['ch7'])) {
      final other = (answers['etEMFOther'] ?? '').trim();
      emfSources.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (emfSources.isNotEmpty) {
      final template = _phraseTexts['{D_LOCAL_ENVIRONMENT_EMF}'] ?? '';
      if (template.isNotEmpty) {
        final resolved = _normalize(template)
            .replaceAll('{LOCAL_ENVIRONMENT_CLOSED_TO}', _toWords(emfSources));
        phrases.addAll(_split(resolved));
      }
    }
    return phrases;
  }

  List<String> _propertyPrivateRoad(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner3'] ?? '').trim().toLowerCase();
    if (status != 'yes') return const [];
    final text = _phraseTexts['{D_LOCATION}::{LOCATION_PRIVATE_PROPERTY_AREA}'] ?? '';
    if (text.isNotEmpty) return _split(_normalize(text));
    return const ['The road outside the property is likely to be a private road.'];
  }

  List<String> _propertyNoisyArea(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner4'] ?? '').trim().toLowerCase();
    if (status != 'yes') return const [];
    final sources = <String>[];
    if (_isChecked(answers['ch1'])) sources.add('busy road');
    if (_isChecked(answers['ch2'])) sources.add('train line');
    if (_isChecked(answers['ch3'])) sources.add('train station');
    if (_isChecked(answers['ch4'])) sources.add('airport');
    if (_isChecked(answers['ch5'])) sources.add('motor way');
    if (_isChecked(answers['ch6'])) {
      final other = (answers['etGroundTypeOther'] ?? '').trim();
      sources.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (sources.isEmpty) {
      return const ['The property is in a noisy area.'];
    }
    return ['The property is in a noisy area near ${_toWords(sources)}.'];
  }

  // ── New methods for uncovered screens ──────────────────────────

  // Section D: Residential garden (combined front/rear/communal)
  List<String> _sectionDGardenResidential(Map<String, String> answers) {
    final phrases = <String>[];
    final areas = <String, List<String>>{
      'Front': ['android_material_design_spinner', 'etFrontTypeOther', 'android_material_design_spinner2', 'etFrontFencingOther'],
      'Rear': ['android_material_design_spinner3', 'etRearTypeOther', 'android_material_design_spinner4', 'etRearFencingOther'],
      'Communal': ['android_material_design_spinner5', 'etCommunalTypeOther', 'android_material_design_spinner6', 'etCommunalFencingOther'],
    };
    for (final entry in areas.entries) {
      final gardenType = (answers[entry.value[0]] ?? '').trim();
      final fencing = (answers[entry.value[2]] ?? '').trim();
      if (gardenType.isEmpty && fencing.isEmpty) continue;
      final parts = <String>[];
      if (gardenType.isNotEmpty) {
        final typeText = gardenType.toLowerCase() == 'other'
            ? (answers[entry.value[1]] ?? 'other').trim().toLowerCase()
            : gardenType.toLowerCase();
        parts.add('type: $typeText');
      }
      if (fencing.isNotEmpty) {
        final fenceText = fencing.toLowerCase() == 'other'
            ? (answers[entry.value[3]] ?? 'other').trim().toLowerCase()
            : fencing.toLowerCase();
        parts.add('boundary fencing: $fenceText');
      }
      phrases.add('${entry.key} garden: ${parts.join(', ')}.');
    }
    return phrases;
  }

  // Section D: Topography
  List<String> _sectionDTopography(Map<String, String> answers) {
    final phrases = <String>[];
    final areas = <String, List<String>>{
      'Front': ['android_material_design_spinner', 'etFrontTypeOther'],
      'Rear': ['android_material_design_spinner3', 'etRearTypeOther'],
      'Communal': ['android_material_design_spinner5', 'etCommunalTypeOther'],
    };
    for (final entry in areas.entries) {
      final topography = (answers[entry.value[0]] ?? '').trim();
      if (topography.isEmpty) continue;
      final text = topography.toLowerCase() == 'other'
          ? (answers[entry.value[1]] ?? 'other').trim().toLowerCase()
          : topography.toLowerCase();
      phrases.add('${entry.key} topography: $text.');
    }
    return phrases;
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
    final partition = (answers['android_material_design_spinner'] ?? '').trim();
    final phrases = <String>[];
    if (types.isNotEmpty) {
      phrases.add('Internal walls: ${_toWords(types)}.');
    }
    if (partition.isNotEmpty) {
      phrases.add('Partition type: ${partition.toLowerCase()}.');
    }
    return phrases;
  }

  // Section D: Listed Building
  List<String> _sectionDListedBuilding(Map<String, String> answers) {
    final status = (answers['android_material_design_spinner'] ?? '').trim();
    if (status.isEmpty) return const [];
    if (status.toLowerCase() == 'yes') {
      return [
        'The property is a listed building.',
        'Please contact your legal adviser to advise you on the implication of this building status.',
      ];
    }
    return ['The property is not a listed building.'];
  }

  // Section D: Other Service
  List<String> _sectionDOtherService(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['ch1'])) items.add('solar electricity');
    if (_isChecked(answers['ch2'])) items.add('solar hot water');
    if (items.isEmpty) return const [];
    return ['Other services: ${_toWords(items)}.'];
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

  // Section G: Services - water disused tank
  List<String> _servicesWaterDisusedTank(Map<String, String> answers) {
    final location = _cleanLower(answers['actv_disused_tank_location']);
    final material = _cleanLower(answers['actv_tank_formed_in']);
    if (location.isEmpty && material.isEmpty) return const [];
    final template = _phraseTexts['{F_ROOF_STRUCTURE_WATER_TANK}::{DISUSED_WATER_TANK}'] ?? '';
    if (template.isNotEmpty) {
      final resolved = _normalize(template)
          .replaceAll('{RS_WT_DISUSED_LOCATION}', location.isNotEmpty ? location : '...')
          .replaceAll('{RS_WT_DISUSED_MATERIAL}', material.isNotEmpty ? material : '...');
      return _split(resolved);
    }
    final phrases = <String>[];
    if (location.isNotEmpty) phrases.add('Disused water tank location: $location.');
    if (material.isNotEmpty) phrases.add('Tank material: $material.');
    return phrases;
  }

  // Section G: Services - water tank
  List<String> _servicesWaterTank(Map<String, String> answers) {
    final locations = <String>[];
    if (_isChecked(answers['cb_roof_space'])) locations.add('roof space');
    if (_isChecked(answers['cb_airing_cupboard'])) locations.add('airing cupboard');
    if (_isChecked(answers['cb_kitchen'])) locations.add('kitchen');
    if (_isChecked(answers['cb_other_289'])) {
      final other = (answers['et_other_442'] ?? '').trim();
      locations.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final materials = <String>[];
    if (_isChecked(answers['cb_plastic'])) materials.add('plastic');
    if (_isChecked(answers['cb_galvanised_metal'])) materials.add('galvanised metal');
    if (_isChecked(answers['cb_asbestos'])) materials.add('asbestos');
    if (_isChecked(answers['cb_other_640'])) {
      final other = (answers['et_other_643'] ?? '').trim();
      materials.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final condition = _cleanLower(answers['actv_condition']);
    if (locations.isEmpty && materials.isEmpty && condition.isEmpty) return const [];
    final phrases = <String>[];
    if (locations.isNotEmpty && materials.isNotEmpty) {
      phrases.add('Water tank in ${_toWords(locations)}, formed in ${_toWords(materials)}.');
    } else {
      if (locations.isNotEmpty) phrases.add('Water tank location: ${_toWords(locations)}.');
      if (materials.isNotEmpty) phrases.add('Water tank material: ${_toWords(materials)}.');
    }
    if (condition.isNotEmpty) phrases.add('Condition: $condition.');
    return phrases;
  }

  // Section G: Services - water insulation
  List<String> _servicesWaterInsulation(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty) return const [];
    if (status == 'ok' || status == 'good') {
      final template = _phraseTexts['{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_OK}'] ?? '';
      if (template.isNotEmpty) return _split(_normalize(template));
      return ['Water insulation status: $status.'];
    }
    if (status.contains('inadequate') || status == 'poor') {
      final template = _phraseTexts['{F_ROOF_STRUCTURE_WATER_TANK}::{INSULATION_STATUS_NOT_ADEQUATELY_INSULATED}'] ?? '';
      if (template.isNotEmpty) return _split(_normalize(template));
      return ['Water insulation: $status.'];
    }
    return ['Water insulation status: $status.'];
  }

  // Section G: Services - heating radiators
  List<String> _servicesHeatingRadiators(Map<String, String> answers) {
    final type = _cleanLower(answers['actv_radiators_and_clandad_floor_pipes']);
    if (type.isEmpty) return const [];
    return ['Heating distribution: $type.'];
  }

  // Section G: Services - other heating
  List<String> _servicesHeatingOtherHeating(Map<String, String> answers) {
    final items = <String>[];
    if (_isChecked(answers['cb_oil_filled'])) items.add('oil filled');
    if (_isChecked(answers['cb_electric_storage'])) items.add('electric storage');
    if (_isChecked(answers['cb_convector'])) items.add('convector');
    if (_isChecked(answers['cb_other_923'])) {
      final other = (answers['et_other_717'] ?? '').trim();
      items.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (items.isEmpty) return const [];
    return ['Other heating types: ${_toWords(items)}.'];
  }

  // Section G: Services - old boiler
  List<String> _servicesHeatingOldBoiler(Map<String, String> answers) {
    if (_isChecked(answers['cb_old_boiler'])) {
      return ['The boiler is old and may need replacing.'];
    }
    return const [];
  }

  // Section G: Services - water repair main
  List<String> _servicesWaterRepairMain(Map<String, String> answers) {
    final defects = <String>[];
    if (_isChecked(answers['cb_damaged'])) defects.add('damaged');
    if (_isChecked(answers['cb_not_properly_supported'])) defects.add('not properly supported');
    if (_isChecked(answers['cb_leaking'])) defects.add('leaking');
    if (_isChecked(answers['cb_overflowing'])) defects.add('overflowing');
    if (_isChecked(answers['cb_other_850'])) {
      final other = (answers['et_other_567'] ?? '').trim();
      defects.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (_isChecked(answers['cb_no_lid_over_tank'])) defects.add('no lid over tank');
    if (_isChecked(answers['cb_poorly_fitted_lid'])) defects.add('poorly fitted lid');
    if (_isChecked(answers['cb_asbestos_material'])) defects.add('asbestos material');
    if (defects.isEmpty) return const [];
    return ['Water tank defects: ${_toWords(defects)}. Repair needed.'];
  }

  // Section G: Services - water repair (asbestos/cover/tank variants)
  List<String> _servicesWaterRepairDefect(
    Map<String, String> answers,
    String repairType,
    String otherCbId,
    String otherEtId,
  ) {
    final defects = <String>[];
    if (_isChecked(answers['cb_damaged'])) defects.add('damaged');
    if (_isChecked(answers['cb_not_properly_supported'])) defects.add('not properly supported');
    if (_isChecked(answers['cb_leaking'])) defects.add('leaking');
    if (_isChecked(answers['cb_overflowing'])) defects.add('overflowing');
    if (_isChecked(answers[otherCbId])) {
      final other = (answers[otherEtId] ?? '').trim();
      defects.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (defects.isEmpty) return const [];
    return ['$repairType: ${_toWords(defects)}. Repair needed.'];
  }

  // Section G: Services - drainage chamber lids
  List<String> _servicesDrainageChamberLids(Map<String, String> answers) {
    final phrases = <String>[];
    if (_isChecked(answers['cb_inspected'])) phrases.add('Chamber lids inspected.');
    if (_isChecked(answers['cb_shared'])) phrases.add('Drainage system is shared.');
    final defect = _cleanLower(answers['actv_defect']);
    if (defect.isNotEmpty) phrases.add('Chamber lid defect: $defect.');
    return phrases;
  }

  // Section G: Services - drainage public system
  List<String> _servicesDrainagePublicSystem(Map<String, String> answers) {
    if (_isChecked(answers['cb_property_connected_to_public_sewer'])) {
      return ['The property is connected to the public sewer system.'];
    }
    return const [];
  }

  // Section G: Services - water heating cylinder
  List<String> _servicesWaterHeatingCylinder(Map<String, String> answers) {
    if (_isChecked(answers['cb_poor_insulation'])) {
      return ['The hot water cylinder has poor insulation.'];
    }
    return const [];
  }

  // Section F: woodwork simple checkbox
  List<String> _woodWorkSimpleCheckbox(
    Map<String, String> answers,
    String cbId,
    String phrase,
  ) {
    if (_isChecked(answers[cbId])) return [phrase];
    return const [];
  }

  // Section F: woodwork rocking handrails
  List<String> _woodWorkRockingHandrails(Map<String, String> answers) {
    final status = _cleanLower(answers['actv_status']);
    if (status.isEmpty || status == 'none') return const [];
    return ['Rocking handrails present.'];
  }

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
      phrases.add('The roof covering is fit for purpose.');
    }
    if (_isChecked(answers['cb_end_of_useful_life'])) {
      phrases.add('The roof covering is reaching the end of its useful life.');
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
      locations.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final rating = (answers['android_material_design_spinner4'] ?? '').trim();
    final assumedType = _cleanLower(answers['actv_assumed_type']);
    final notes = (answers['ar_etNote'] ?? '').trim();
    final phrases = <String>[];
    if (locations.isNotEmpty) {
      phrases.add('Roof covering on: ${_toWords(locations)}.');
    }
    if (assumedType.isNotEmpty) {
      phrases.add('Assumed roof type: $assumedType.');
    }
    if (rating.isNotEmpty) {
      phrases.add('Condition rating: $rating.');
    }
    if (notes.isNotEmpty) {
      phrases.add('Notes: $notes');
    }
    return phrases;
  }

  // Section E: outside door repair location (failed glazing / inadequate lock)
  List<String> _outsideDoorsRepairLocation(Map<String, String> answers, String repairType) {
    final locations = <String>[];
    if (_isChecked(answers['cb_main_63'])) locations.add('main');
    if (_isChecked(answers['cb_rear_80'])) locations.add('rear');
    if (_isChecked(answers['cb_side_35'])) locations.add('side');
    if (_isChecked(answers['cb_patio_42'])) locations.add('patio');
    if (_isChecked(answers['cb_garage_95'])) locations.add('garage');
    if (_isChecked(answers['cb_other_791'])) {
      final other = (answers['et_other_129'] ?? '').trim();
      locations.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    final defects = <String>[];
    if (_isChecked(answers['cb_is_damaged_25'])) defects.add('damaged');
    if (_isChecked(answers['cb_is_rotten_49'])) defects.add('rotten');
    if (_isChecked(answers['cb_is_partly_worn_73'])) defects.add('partly worn');
    if (_isChecked(answers['cb_is_poorly_secured_99'])) defects.add('poorly secured');
    if (_isChecked(answers['cb_has_inadequate_lock_89'])) defects.add('inadequate lock');
    if (_isChecked(answers['cb_has_rotted_frame_43'])) defects.add('rotted frame');
    if (_isChecked(answers['cb_has_damaged_lock_74'])) defects.add('damaged lock');
    if (_isChecked(answers['cb_has_failed_glazing_45'])) defects.add('failed glazing');
    if (_isChecked(answers['cb_sticks_against_frame_48'])) defects.add('sticks against frame');
    if (_isChecked(answers['cb_is_poorly_fitted_84'])) defects.add('poorly fitted');
    if (_isChecked(answers['cb_other_641'])) {
      final other = (answers['et_other_288'] ?? '').trim();
      defects.add(other.isNotEmpty ? other.toLowerCase() : 'other');
    }
    if (locations.isEmpty && defects.isEmpty) return const [];
    final phrases = <String>[];
    if (locations.isNotEmpty) {
      phrases.add('$repairType location: ${_toWords(locations)} door(s).');
    }
    if (defects.isNotEmpty) {
      phrases.add('Defects: ${_toWords(defects)}.');
    }
    return phrases;
  }

  // Section A: overall opinion
  List<String> _overallOpinion(Map<String, String> answers) {
    final opinion = (answers['android_material_design_spinner5'] ?? '').trim();
    if (opinion.isEmpty) return const [];
    final amount = (answers['android_material_design_spinner'] ?? '').trim();
    final potential = (answers['android_material_design_spinner2'] ?? '').trim();
    final priceFormatted = amount.isNotEmpty ? formatPriceWithWords(amount) : '';

    if (opinion.toLowerCase() == 'reasonable') {
      final template = _phraseTexts['{OVERALL_OPINION_REASONABLE}'] ?? '';
      if (template.isNotEmpty) {
        var resolved = _normalize(template);
        if (amount.isNotEmpty) {
          final cleaned = amount.replaceAll(RegExp(r'[£,\s]'), '');
          final parsed = int.tryParse(cleaned);
          final commaFormatted = parsed != null ? '£${_addCommasHelper(parsed)}' : '£$amount';
          resolved = resolved.replaceAll('{OVERALL_OPINION_PURCHASE_PRICE}', commaFormatted);
          resolved = resolved.replaceAll('{OVERALL_OPINION_PURCHASE_PRICE_WORD}', priceFormatted);
        }
        final phrases = _split(resolved);
        // If template had no price placeholders, append price separately.
        if (priceFormatted.isNotEmpty && !resolved.contains(priceFormatted)) {
          phrases.add('Purchase price: $priceFormatted.');
        }
        return phrases;
      }
      final phrases = <String>['Overall opinion: reasonable.'];
      if (priceFormatted.isNotEmpty) phrases.add('Purchase price: $priceFormatted.');
      return phrases;
    }
    if (opinion.toLowerCase().contains('repair')) {
      final template = _phraseTexts['{OVERALL_OPINION_REASONABLE_WITH_REPAIR}'] ?? '';
      final phrases = <String>[];
      if (template.isNotEmpty) {
        var resolved = _normalize(template);
        // Try placeholder substitution first
        resolved = resolved.replaceAll('{REPAIR_AMOUNT}', priceFormatted);
        resolved = resolved.replaceAll('{REPAIR_POTENTIAL}', potential.isNotEmpty ? potential.toLowerCase() : '');
        phrases.addAll(_split(resolved));
      } else {
        phrases.add('Overall opinion: reasonable with repairs.');
      }
      // Always append price/potential as separate lines so they show
      // even when the template has no placeholders for them.
      if (priceFormatted.isNotEmpty) phrases.add('Estimated repair cost: $priceFormatted.');
      if (potential.isNotEmpty) phrases.add('Potential: ${potential.toLowerCase()}.');
      return phrases;
    }
    return ['Overall opinion: ${opinion.toLowerCase()}.'];
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

  List<String>? _matchDynamicSectionE(String screenId, Map<String, String> answers) {
    if (screenId.startsWith('activity_outside_property_other_other_external')) {
      return _otherConstruction(answers, 'actv_area', 'et_other_99');
    }
    if (screenId.startsWith('activity_outside_property_other_other_wall')) {
      return _otherConstruction(answers, 'actv_area', 'et_other_99');
    }
    if (screenId.startsWith('activity_outside_property_other_other_roof')) {
      return _otherRoof(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_floors')) {
      return _otherFloor(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_drains')) {
      return _otherDrains(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_handrails')) {
      return _otherHandrails(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_overloaded')) {
      return _otherOverloaded(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_no_safety_glass')) {
      return _otherNoSafetyGlass(answers);
    }
    if (screenId.startsWith('activity_out_side_other_external_area_condition')) {
      return _otherCondition(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_wall')) {
      return _otherRepairWall(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_roof')) {
      return _otherRepairRoof(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_floor')) {
      return _otherRepairFloor(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_drains')) {
      return _otherRepairDrains(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_hand_rails')) {
      return _otherRepairHandrails(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_steps_landing')) {
      return _otherRepairStepsLanding(answers);
    }
    if (screenId.startsWith('activity_outside_property_other_repairs_decorations')) {
      return _otherRepairDecorations(answers);
    }
    return null;
  }

  static String _doorLocationFromScreen(String screenId) {
    if (screenId.contains('__rear_door')) return 'rear';
    if (screenId.contains('__side_door')) return 'side';
    if (screenId.contains('__patio_door')) return 'patio';
    if (screenId.contains('__garage_door')) return 'garage';
    if (screenId.contains('__other_door')) return 'other';
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

  static String _doorMaterialCode(String material) {
    final value = material.toLowerCase();
    if (value.contains('pvc')) return '{PVC}';
    if (value.contains('timber')) return '{TIMBER}';
    if (value.contains('steel')) return '{STEEL}';
    if (value.contains('aluminium')) return '{ALUMINIUM}';
    return '{OTHER}';
  }

  static String _cpRepairWrapper(String screenId) {
    if (screenId.contains('__walls')) return '{WALLS_REPAIR}';
    if (screenId.contains('__windows')) return '{WINDOWS_REPAIR}';
    if (screenId.contains('__door_glazing')) return '{DOOR_GLAZING_REPAIR}';
    if (screenId.contains('__window_glazing')) return '{WINDOW_GLAZING_REPAIR}';
    if (screenId.contains('__roof_glazing')) return '{ROOF_GLAZING_REPAIR}';
    if (screenId.contains('__floor')) return '{FLOOR_REPAIR}';
    if (screenId.contains('__rainwater_goods')) return '{RAINWATER_GOODS_REPAIR}';
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
      final text = _firstNonEmpty(answers, ['et_other_309', 'et_other_816', 'et_other_196', 'et_other_659']);
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

  static List<String> _split(String text) {
    return text
        .split(RegExp(r'\n{2,}'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _normalize(String text) {
    final withBreaks = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final stripped = withBreaks.replaceAll(RegExp(r'<[^>]+>'), '');
    return const LineSplitter().convert(stripped).join('\n').trim();
  }
}
