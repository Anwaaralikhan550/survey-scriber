const fs = require('fs');

// Load tree
const treePath = 'E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json';
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

const patchLog = [];

function log(action, screen, detail) {
  const entry = { action, screen, detail };
  patchLog.push(entry);
  console.log(`[${action}] ${screen}: ${detail}`);
}

// Helper to find a screen node in a section
function findScreen(sectionKey, screenId) {
  const section = tree.sections.find(s => s.key === sectionKey);
  if (!section) return null;
  return section.nodes.find(n => n.id === screenId && n.type === 'screen');
}

// Helper to add fields to a screen
function addFields(sectionKey, screenId, newFields) {
  const screen = findScreen(sectionKey, screenId);
  if (!screen) {
    log('ERROR', screenId, 'Screen not found in section ' + sectionKey);
    return false;
  }
  if (!screen.fields) screen.fields = [];
  const existingIds = new Set(screen.fields.map(f => f.id));
  let added = 0;
  for (const field of newFields) {
    if (existingIds.has(field.id)) {
      continue; // Skip already existing
    }
    screen.fields.push(field);
    added++;
    log('ADD_FIELD', screenId, `Added ${field.type} field: ${field.id} (${field.label})`);
  }
  return added > 0;
}

// Helper to add a new screen to a section
function addScreen(sectionKey, screenDef) {
  const section = tree.sections.find(s => s.key === sectionKey);
  if (!section) {
    log('ERROR', screenDef.id, 'Section not found: ' + sectionKey);
    return false;
  }
  // Check if screen already exists
  const existing = section.nodes.find(n => n.id === screenDef.id);
  if (existing) {
    log('SKIP', screenDef.id, 'Screen already exists');
    return false;
  }
  section.nodes.push(screenDef);
  log('ADD_SCREEN', screenDef.id, `Added new screen: ${screenDef.title} with ${(screenDef.fields || []).length} fields`);
  return true;
}

// ==========================================
// SECTION E - OUTSIDE PROPERTY FIXES
// ==========================================

// E1: Chimney Not Inspected - missing 11 data fields
addFields('E', 'activity_outside_property_chimney_not_inspected', [
  { id: 'cb_Partial_view', label: 'Partial view', type: 'checkbox' },
  { id: 'cb_Removed_chimney_stack', label: 'Removed chimney stack(s)', type: 'checkbox' },
  { id: 'cb_Removed_pots', label: 'Removed pots', type: 'checkbox' },
  { id: 'label_location', label: 'Location', type: 'label' },
  { id: 'cb_main_building_83', label: 'Main building', type: 'checkbox' },
  { id: 'cb_front_74', label: 'Front', type: 'checkbox' },
  { id: 'cb_rear_97', label: 'Rear', type: 'checkbox' },
  { id: 'cb_side_72', label: 'Side', type: 'checkbox' },
  { id: 'cb_front_88', label: 'Front (pots)', type: 'checkbox' },
  { id: 'cb_side_43', label: 'Side (pots)', type: 'checkbox' },
  { id: 'cb_rear_83', label: 'Rear (pots)', type: 'checkbox' },
  { id: 'et_other_782', label: 'Other', type: 'text' },
]);

// E1: Chimney Partial View - missing 11 data fields
addFields('E', 'activity_outside_property_chimney_partial_view', [
  { id: 'cb_Not_applicable', label: 'Not applicable', type: 'checkbox' },
  { id: 'cb_Removed_chimney_stack', label: 'Removed chimney stack(s)', type: 'checkbox' },
  { id: 'cb_Removed_pots', label: 'Removed pots', type: 'checkbox' },
  { id: 'label_location', label: 'Location', type: 'label' },
  { id: 'cb_main_building_83', label: 'Main building', type: 'checkbox' },
  { id: 'cb_front_74', label: 'Front', type: 'checkbox' },
  { id: 'cb_rear_97', label: 'Rear', type: 'checkbox' },
  { id: 'cb_side_72', label: 'Side', type: 'checkbox' },
  { id: 'cb_front_88', label: 'Front (pots)', type: 'checkbox' },
  { id: 'cb_side_43', label: 'Side (pots)', type: 'checkbox' },
  { id: 'cb_rear_83', label: 'Rear (pots)', type: 'checkbox' },
  { id: 'et_other_782', label: 'Other', type: 'text' },
]);

// E1: Chimney Removed Chimney Stack - missing 11 data fields
addFields('E', 'activity_outside_property_chimney_removed_chimney_stack', [
  { id: 'cb_Not_applicable', label: 'Not applicable', type: 'checkbox' },
  { id: 'cb_Partial_view', label: 'Partial view', type: 'checkbox' },
  { id: 'cb_Removed_pots', label: 'Removed pots', type: 'checkbox' },
  { id: 'label_location', label: 'Location', type: 'label' },
  { id: 'cb_main_building_83', label: 'Main building', type: 'checkbox' },
  { id: 'cb_front_74', label: 'Front', type: 'checkbox' },
  { id: 'cb_rear_97', label: 'Rear', type: 'checkbox' },
  { id: 'cb_side_72', label: 'Side', type: 'checkbox' },
  { id: 'cb_front_88', label: 'Front (pots)', type: 'checkbox' },
  { id: 'cb_side_43', label: 'Side (pots)', type: 'checkbox' },
  { id: 'cb_rear_83', label: 'Rear (pots)', type: 'checkbox' },
  { id: 'et_other_782', label: 'Other', type: 'text' },
]);

// E1: Chimney Removed Pots - missing 11 data fields
addFields('E', 'activity_outside_property_chimney_removed_pots', [
  { id: 'cb_Not_applicable', label: 'Not applicable', type: 'checkbox' },
  { id: 'cb_Partial_view', label: 'Partial view', type: 'checkbox' },
  { id: 'cb_Removed_chimney_stack', label: 'Removed chimney stack(s)', type: 'checkbox' },
  { id: 'label_location', label: 'Location', type: 'label' },
  { id: 'cb_main_building_83', label: 'Main building', type: 'checkbox' },
  { id: 'cb_front_74', label: 'Front', type: 'checkbox' },
  { id: 'cb_rear_97', label: 'Rear', type: 'checkbox' },
  { id: 'cb_side_72', label: 'Side', type: 'checkbox' },
  { id: 'cb_front_88', label: 'Front (pots)', type: 'checkbox' },
  { id: 'cb_side_43', label: 'Side (pots)', type: 'checkbox' },
  { id: 'cb_rear_83', label: 'Rear (pots)', type: 'checkbox' },
  { id: 'et_other_782', label: 'Other', type: 'text' },
]);

// E1: Leaning Chimney - missing etGroundTypeOther
addFields('E', 'activity_outside_property_leaning_chimney', [
  { id: 'etGroundTypeOther', label: 'Other', type: 'text' },
]);

// E1: Shared Chimney - missing etGroundTypeOther
addFields('E', 'activity_outside_property_shared_chimney', [
  { id: 'etGroundTypeOther', label: 'Other', type: 'text' },
]);

// E4: Main Wall Repairs Lintel - missing cb_causing_damp
addFields('E', 'activity_outside_property_main_wall_repairs_lintel', [
  { id: 'cb_causing_damp', label: 'Causing damp', type: 'checkbox' },
]);

// E4: Main Wall Repairs Window Sills - missing cb_causing_damp
addFields('E', 'activity_outside_property_main_wall_repairs_window_sills', [
  { id: 'cb_causing_damp', label: 'Causing damp', type: 'checkbox' },
]);

// E7: Other - About Joinery and Finishes - missing cb_open_runoffs
addFields('E', 'activity_outside_property_other_about_joinery_and_finishes', [
  { id: 'cb_open_runoffs', label: 'Open runoffs (asbestos)', type: 'checkbox' },
]);

// E8: Other Handrails - missing cb_concrete, cb_steel
addFields('E', 'activity_outside_property_other_handrails', [
  { id: 'cb_concrete', label: 'Concrete', type: 'checkbox' },
  { id: 'cb_steel', label: 'Steel', type: 'checkbox' },
]);

// E8: Other Not Inspected - missing 3 location checkboxes
addFields('E', 'activity_outside_property_other_not_inspected', [
  { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
  { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
  { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
]);

// E3: Rainwater Goods Main Screen - missing location checkboxes and text
addFields('E', 'activity_outside_property_rainwater_goods_main_screen', [
  { id: 'label_location_area', label: 'Location / Area', type: 'label' },
  { id: 'cb_main_building', label: 'Main building', type: 'checkbox' },
  { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
  { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
  { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
  { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
  { id: 'et_other_691', label: 'Other', type: 'text' },
]);

// ==========================================
// SECTION F - INSIDE PROPERTY FIXES
// ==========================================

// F1: About Roof Structure - missing cb_underlining
addFields('F', 'activity_inside_property_about_roof_structure', [
  { id: 'cb_underlining', label: 'Underlining', type: 'checkbox' },
]);

// F3: Ceilings Heavy Paper Lining - missing 5 location checkboxes
addFields('F', 'activity_inside_property_ceilings_heavy_paper_lining', [
  { id: 'label_location_area', label: 'Location / Area', type: 'label' },
  { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
  { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
  { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
  { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
  { id: 'cb_other_601', label: 'Other', type: 'checkbox' },
]);

// F3: Ceilings Not Inspected - missing 5 location checkboxes
addFields('F', 'activity_inside_property_ceilings_not_inspected', [
  { id: 'label_location_area', label: 'Location / Area', type: 'label' },
  { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
  { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
  { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
  { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
  { id: 'cb_other_601', label: 'Other', type: 'checkbox' },
]);

// F3: Ceilings Polystyrene - missing text + 4 checkboxes
addFields('F', 'activity_inside_property_ceilings_polystyrene', [
  { id: 'label_location_area', label: 'Location / Area', type: 'label' },
  { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
  { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
  { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
  { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
  { id: 'et_other_691', label: 'Other', type: 'text' },
]);

// F: Limitation - missing ch3-ch6
addFields('F', 'activity_inside_property_limitation', [
  { id: 'ch3', label: 'Fitted floor coverings', type: 'checkbox' },
  { id: 'ch4', label: 'Stored items / furniture', type: 'checkbox' },
  { id: 'ch5', label: 'Wall linings', type: 'checkbox' },
  { id: 'ch6', label: 'Thermal insulation', type: 'checkbox' },
]);

// F: Other Not Inspected - missing cb_extension
addFields('F', 'activity_inside_property_other_not_inspected', [
  { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
]);

// F4: WAP Not Inspected - missing text + 5 checkboxes
addFields('F', 'activity_inside_property_wap_not_inspected', [
  { id: 'label_location_area', label: 'Location / Area', type: 'label' },
  { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
  { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
  { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
  { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
  { id: 'et_other_691', label: 'Other', type: 'text' },
]);

// F2: Water Tank - missing cb_defect
addFields('F', 'activity_inside_property_water_tank', [
  { id: 'cb_defect', label: 'Defect', type: 'checkbox' },
]);

// F8: Bathroom Fittings Extractor Fan - missing 20 fields
addFields('F', 'activity_in_side_property_bathroom_fittings_extractor_fan', [
  { id: 'label_where_extractor_fan', label: 'Where is the extractor fan?', type: 'label' },
  { id: 'cb_Property', label: 'Property', type: 'checkbox' },
  { id: 'cb_bathroom_56_wef', label: 'Bathroom', type: 'checkbox' },
  { id: 'cb_shower_room_100_wef', label: 'Shower room', type: 'checkbox' },
  { id: 'cb_en_suite_bathroom_101_wef', label: 'En-suite bathroom', type: 'checkbox' },
  { id: 'cb_en_suite_shower_room_81_wef', label: 'En-suite shower room', type: 'checkbox' },
  { id: 'cb_separate_toilet_99_wef', label: 'Separate toilet', type: 'checkbox' },
  { id: 'cb_other_725_wef', label: 'Other', type: 'checkbox' },
  { id: 'et_other_631_wef', label: 'Other (specify)', type: 'text' },
  { id: 'label_where_no_extractor_fan', label: 'Where is there no extractor fan?', type: 'label' },
  { id: 'cb_bathroom', label: 'Bathroom (no fan)', type: 'checkbox' },
  { id: 'cb_bathrooms', label: 'Bathrooms (no fan)', type: 'checkbox' },
  { id: 'cb_shower_room', label: 'Shower room (no fan)', type: 'checkbox' },
  { id: 'cb_shower_rooms', label: 'Shower rooms (no fan)', type: 'checkbox' },
  { id: 'cb_other_295', label: 'Other (no fan)', type: 'checkbox' },
  { id: 'et_other_768', label: 'Other (no fan specify)', type: 'text' },
  { id: 'label_where_broken', label: 'Where is fan broken/not working?', type: 'label' },
  { id: 'cb_bathroom_21', label: 'Bathroom (broken)', type: 'checkbox' },
  { id: 'cb_shower_room_71', label: 'Shower room (broken)', type: 'checkbox' },
  { id: 'cb_en_suite_bathroom_97', label: 'En-suite bathroom (broken)', type: 'checkbox' },
  { id: 'cb_en_suite_shower_room_14', label: 'En-suite shower room (broken)', type: 'checkbox' },
  { id: 'cb_other_1016', label: 'Other (broken)', type: 'checkbox' },
  { id: 'et_other_704', label: 'Other (broken specify)', type: 'text' },
]);

// F7: Built In Fittings Repair Fittings - missing et_other_732
addFields('F', 'activity_in_side_property_built_in_fittings_repair_fittings', [
  { id: 'et_other_732', label: 'Other', type: 'text' },
]);

// F6: Fire Places - missing 8 fields (type selectors + text)
addFields('F', 'activity_in_side_property_fire_places', [
  { id: 'label_fire_type', label: 'Fire Type', type: 'label' },
  { id: 'cb_flues_not_inspected', label: 'Flues not inspected', type: 'checkbox' },
  { id: 'cb_an_open_fire', label: 'An open fire', type: 'checkbox' },
  { id: 'cb_gas_fire', label: 'Gas fire', type: 'checkbox' },
  { id: 'cb_imitation_system', label: 'Imitation system', type: 'checkbox' },
  { id: 'cb_wood_burning_stove', label: 'Wood burning stove', type: 'checkbox' },
  { id: 'cb_electric_fire', label: 'Electric fire', type: 'checkbox' },
  { id: 'cb_other_316', label: 'Other', type: 'checkbox' },
  { id: 'et_other_633', label: 'Other (specify)', type: 'text' },
]);

// ==========================================
// SECTION G - SERVICES FIXES
// ==========================================

// G: Drainage - missing et_other_373
addFields('G', 'activity_services_drainage', [
  { id: 'et_other_373', label: 'Other', type: 'text' },
]);

// G: Electricity Main Screen - missing cb_dated_electrical_system
addFields('G', 'activity_services_electricity_main_screen', [
  { id: 'cb_dated_electrical_system', label: 'Dated electrical system', type: 'checkbox' },
]);

// G: Heating About Heating - missing cb_connected_to_radiator
addFields('G', 'activity_services_heating_about_heating', [
  { id: 'cb_connected_to_radiator', label: 'Connected to radiator', type: 'checkbox' },
]);

// G: Shared Services - missing cb_not_inspected
addFields('G', 'activity_services_shared_services', [
  { id: 'cb_not_inspected', label: 'Not inspected', type: 'checkbox' },
]);

// ==========================================
// SECTION H - GROUNDS FIXES
// ==========================================

// H: Knotweed - missing et_other_732
addFields('H', 'activity_grounds_other_area_knotweed', [
  { id: 'et_other_732', label: 'Other', type: 'text' },
]);

// H: Not Inspected - missing cb_not_inspected_no_garage
addFields('H', 'activity_grounds_other_area_not_inspected', [
  { id: 'cb_not_inspected_no_garage', label: 'Not inspected (no garage)', type: 'checkbox' },
]);

// ==========================================
// MISSING SCREENS - ADD NEW SCREENS
// ==========================================

// Find parent groups for inserting new screens
function findParentId(sectionKey, partialId) {
  const section = tree.sections.find(s => s.key === sectionKey);
  if (!section) return null;
  // Find a group node that could be the parent
  for (const node of section.nodes) {
    if (node.type === 'group' && node.id.includes(partialId)) {
      return node.id;
    }
  }
  return null;
}

// Woodwork sub-screens (Section F - Inside Property)
// Find the woodwork parent group
const woodworkParent = findParentId('F', 'wood_work') || 'activity_inside_property_woodwork_main_screen';

addScreen('F', {
  id: 'activity_in_side_property_wood_work_creaking_stairs',
  title: 'Creaking Stairs',
  type: 'screen',
  parentId: woodworkParent,
  order: 200,
  fields: [
    { id: 'cb_is_creaking_stairs', label: 'Creaking stairs', type: 'checkbox' },
  ],
});

addScreen('F', {
  id: 'activity_in_side_property_wood_work_glazed_internal_doors',
  title: 'Glazed Internal Doors',
  type: 'screen',
  parentId: woodworkParent,
  order: 201,
  fields: [
    { id: 'cb_no_safety_glass_rating', label: 'No safety glass rating', type: 'checkbox' },
  ],
});

addScreen('F', {
  id: 'activity_in_side_property_wood_work_open_threads',
  title: 'Open Threads',
  type: 'screen',
  parentId: woodworkParent,
  order: 202,
  fields: [
    { id: 'cb_open_threads', label: 'Open threads', type: 'checkbox' },
  ],
});

addScreen('F', {
  id: 'activity_in_side_property_wood_work_out_of_square_doors',
  title: 'Out Of Square Doors',
  type: 'screen',
  parentId: woodworkParent,
  order: 203,
  fields: [
    { id: 'cb_out_of_square_doors', label: 'Out of square doors', type: 'checkbox' },
  ],
});

addScreen('F', {
  id: 'activity_in_side_property_wood_work_rocking_handrails',
  title: 'Rocking Handrails',
  type: 'screen',
  parentId: woodworkParent,
  order: 204,
  fields: [
    { id: 'cb_rocking_handrails', label: 'Rocking handrails', type: 'checkbox' },
  ],
});

// Outside door repair detail screens (Section E)
const doorRepairParent = findParentId('E', 'out_side_doors_repairs') || 'activity_outside_property_out_side_doors_repairs';

addScreen('E', {
  id: 'activity_outside_property_out_side_doors_repairs_failed_glazing_location',
  title: 'Failed Glazing Location',
  type: 'screen',
  parentId: doorRepairParent,
  order: 300,
  fields: [
    { id: 'label_location', label: 'Location', type: 'label' },
    { id: 'cb_main_63', label: 'Main', type: 'checkbox' },
    { id: 'cb_rear_80', label: 'Rear', type: 'checkbox' },
    { id: 'cb_side_35', label: 'Side', type: 'checkbox' },
    { id: 'cb_patio_42', label: 'Patio', type: 'checkbox' },
    { id: 'cb_garage_95', label: 'Garage', type: 'checkbox' },
    { id: 'cb_other_791', label: 'Other', type: 'checkbox' },
    { id: 'et_other_129', label: 'Other (specify)', type: 'text' },
    { id: 'label_defects', label: 'Defects', type: 'label' },
    { id: 'cb_is_damaged_25', label: 'Damaged', type: 'checkbox' },
    { id: 'cb_is_rotten_49', label: 'Rotten', type: 'checkbox' },
    { id: 'cb_is_partly_worn_73', label: 'Partly worn', type: 'checkbox' },
    { id: 'cb_is_poorly_secured_99', label: 'Poorly secured', type: 'checkbox' },
    { id: 'cb_has_inadequate_lock_89', label: 'Inadequate lock', type: 'checkbox' },
    { id: 'cb_has_rotted_frame_43', label: 'Rotted frame', type: 'checkbox' },
    { id: 'cb_has_damaged_lock_74', label: 'Damaged lock', type: 'checkbox' },
    { id: 'cb_has_failed_glazing_45', label: 'Failed glazing', type: 'checkbox' },
    { id: 'cb_sticks_against_frame_48', label: 'Sticks against frame', type: 'checkbox' },
    { id: 'cb_is_poorly_fitted_84', label: 'Poorly fitted', type: 'checkbox' },
    { id: 'cb_other_641', label: 'Other defect', type: 'checkbox' },
    { id: 'et_other_288', label: 'Other defect (specify)', type: 'text' },
  ],
});

addScreen('E', {
  id: 'activity_outside_property_out_side_doors_repairs_inadequate_lock_location',
  title: 'Inadequate Lock Location',
  type: 'screen',
  parentId: doorRepairParent,
  order: 301,
  fields: [
    { id: 'label_location', label: 'Location', type: 'label' },
    { id: 'cb_main_63', label: 'Main', type: 'checkbox' },
    { id: 'cb_rear_80', label: 'Rear', type: 'checkbox' },
    { id: 'cb_side_35', label: 'Side', type: 'checkbox' },
    { id: 'cb_patio_42', label: 'Patio', type: 'checkbox' },
    { id: 'cb_garage_95', label: 'Garage', type: 'checkbox' },
    { id: 'cb_other_791', label: 'Other', type: 'checkbox' },
    { id: 'et_other_129', label: 'Other (specify)', type: 'text' },
    { id: 'label_defects', label: 'Defects', type: 'label' },
    { id: 'cb_is_damaged_25', label: 'Damaged', type: 'checkbox' },
    { id: 'cb_is_rotten_49', label: 'Rotten', type: 'checkbox' },
    { id: 'cb_is_partly_worn_73', label: 'Partly worn', type: 'checkbox' },
    { id: 'cb_is_poorly_secured_99', label: 'Poorly secured', type: 'checkbox' },
    { id: 'cb_has_inadequate_lock_89', label: 'Inadequate lock', type: 'checkbox' },
    { id: 'cb_has_rotted_frame_43', label: 'Rotted frame', type: 'checkbox' },
    { id: 'cb_has_damaged_lock_74', label: 'Damaged lock', type: 'checkbox' },
    { id: 'cb_has_failed_glazing_45', label: 'Failed glazing', type: 'checkbox' },
    { id: 'cb_sticks_against_frame_48', label: 'Sticks against frame', type: 'checkbox' },
    { id: 'cb_is_poorly_fitted_84', label: 'Poorly fitted', type: 'checkbox' },
    { id: 'cb_other_641', label: 'Other defect', type: 'checkbox' },
    { id: 'et_other_288', label: 'Other defect (specify)', type: 'text' },
  ],
});

// Roof Covering Main Screen (Section E)
const roofParent = findParentId('E', 'roof_covering') || 'activity_outside_property_roof_covering';

addScreen('E', {
  id: 'activity_outside_property_roof_covering_main_screen',
  title: 'Roof Covering',
  type: 'screen',
  parentId: roofParent,
  order: 310,
  fields: [
    { id: 'label_location_area', label: 'Location / Area', type: 'label' },
    { id: 'cb_main_building', label: 'Main building', type: 'checkbox' },
    { id: 'cb_back_addition', label: 'Back addition', type: 'checkbox' },
    { id: 'cb_extension', label: 'Extension', type: 'checkbox' },
    { id: 'cb_bay_window', label: 'Bay window', type: 'checkbox' },
    { id: 'cb_dormer_window', label: 'Dormer window', type: 'checkbox' },
    { id: 'cb_other_601', label: 'Other', type: 'checkbox' },
    { id: 'et_other_691', label: 'Other (specify)', type: 'text' },
    { id: 'ar_etNote', label: 'Note', type: 'text' },
  ],
});

// Roof Spreading Layout (Section E)
addScreen('E', {
  id: 'outside_property_roof_covering_roof_spreading_layout',
  title: 'Roof Spreading',
  type: 'screen',
  parentId: roofParent,
  order: 311,
  fields: [
    { id: 'label_roof_spreading', label: 'Roof Spreading Location', type: 'label' },
    { id: 'cb_front', label: 'Front', type: 'checkbox' },
    { id: 'cb_side', label: 'Side', type: 'checkbox' },
    { id: 'cb_rear', label: 'Rear', type: 'checkbox' },
  ],
});

// Garden variant screens (Section H)
const gardenParent = findParentId('H', 'grounds_other') || 'activity_grounds_other';
const gardenFields = [
  { id: 'label_garden_type', label: 'Garden Type', type: 'label' },
  { id: 'cb_paved', label: 'Paved', type: 'checkbox' },
  { id: 'cb_part_paved', label: 'Part paved', type: 'checkbox' },
  { id: 'cb_lawned', label: 'Lawned', type: 'checkbox' },
  { id: 'cb_decked', label: 'Decked', type: 'checkbox' },
  { id: 'cb_artificial_lawned', label: 'Artificial lawned', type: 'checkbox' },
  { id: 'cb_laid_with_gravel', label: 'Laid with gravel', type: 'checkbox' },
  { id: 'cb_laid_with_tile_chippings', label: 'Laid with tile chippings', type: 'checkbox' },
  { id: 'cb_laid_with_stone_chippings', label: 'Laid with stone chippings', type: 'checkbox' },
  { id: 'cb_other_277', label: 'Other', type: 'checkbox' },
  { id: 'et_other_912', label: 'Other (specify)', type: 'text' },
  { id: 'ch20', label: 'Communal', type: 'checkbox' },
  { id: 'label_boundary_fencing', label: 'Boundary Fencing', type: 'label' },
  { id: 'cb_fence_formed_in_timber', label: 'Timber', type: 'checkbox' },
  { id: 'cb_fence_formed_in_brick_walls', label: 'Brick walls', type: 'checkbox' },
  { id: 'cb_fence_formed_in_concrete_sections', label: 'Concrete sections', type: 'checkbox' },
  { id: 'cb_fence_formed_in_wire_mash', label: 'Wire mesh', type: 'checkbox' },
  { id: 'cb_fence_formed_in_hedges', label: 'Hedges', type: 'checkbox' },
  { id: 'cb_fence_formed_in_shrubs', label: 'Shrubs', type: 'checkbox' },
  { id: 'cb_fence_formed_in_other', label: 'Other', type: 'checkbox' },
  { id: 'et_other_912_fence_formed_in', label: 'Other fencing (specify)', type: 'text' },
  { id: 'label_outbuildings', label: 'Outbuildings', type: 'label' },
  { id: 'cb_pond', label: 'Pond', type: 'checkbox' },
  { id: 'cb_brick_sheds', label: 'Brick sheds', type: 'checkbox' },
  { id: 'cb_timber_sheds', label: 'Timber sheds', type: 'checkbox' },
];

const gardenVariants = [
  { id: 'activity_grounds_other_communal_garden', title: 'Communal Garden' },
  { id: 'activity_grounds_other_other_garden', title: 'Other Garden' },
  { id: 'activity_grounds_other_rear_garden', title: 'Rear Garden' },
  { id: 'activity_grounds_other_side_garden', title: 'Side Garden' },
];

for (const variant of gardenVariants) {
  addScreen('H', {
    id: variant.id,
    title: variant.title,
    type: 'screen',
    parentId: gardenParent,
    order: 400,
    fields: [...gardenFields],
  });
}

// Drainage sub-screens (Section G)
const drainageParent = findParentId('G', 'drainage') || 'activity_services_drainage';

addScreen('G', {
  id: 'activity_services_drainage_chamber_lids',
  title: 'Chamber Lids',
  type: 'screen',
  parentId: drainageParent,
  order: 500,
  fields: [
    { id: 'cb_inspected', label: 'Inspected', type: 'checkbox' },
    { id: 'cb_shared', label: 'Shared', type: 'checkbox' },
  ],
});

addScreen('G', {
  id: 'activity_services_drainage_public_system',
  title: 'Public System',
  type: 'screen',
  parentId: drainageParent,
  order: 501,
  fields: [
    { id: 'cb_property_connected_to_public_sewer', label: 'Property connected to public sewer', type: 'checkbox' },
  ],
});

// Water Heating Cylinder (Section G)
const waterHeatingParent = findParentId('G', 'water_heating') || 'activity_services_water_heating';

addScreen('G', {
  id: 'activity_services_water_heating_cylinder',
  title: 'Cylinder',
  type: 'screen',
  parentId: waterHeatingParent,
  order: 510,
  fields: [
    { id: 'cb_poor_insulation', label: 'Poor insulation', type: 'checkbox' },
  ],
});

// Water Repair screens (Section G)
const waterRepairParent = findParentId('G', 'water_repair') || 'activity_services_water';

const waterRepairFields = [
  { id: 'cb_damaged', label: 'Damaged', type: 'checkbox' },
  { id: 'cb_not_properly_supported', label: 'Not properly supported', type: 'checkbox' },
  { id: 'cb_leaking', label: 'Leaking', type: 'checkbox' },
  { id: 'cb_overflowing', label: 'Overflowing', type: 'checkbox' },
];

addScreen('G', {
  id: 'activity_services_water_repair_asbestos',
  title: 'Asbestos Repair',
  type: 'screen',
  parentId: waterRepairParent,
  order: 520,
  fields: [
    ...waterRepairFields,
    { id: 'cb_other_358', label: 'Other', type: 'checkbox' },
    { id: 'et_other_883', label: 'Other (specify)', type: 'text' },
  ],
});

addScreen('G', {
  id: 'activity_services_water_repair_cover_screen',
  title: 'Cover Repair',
  type: 'screen',
  parentId: waterRepairParent,
  order: 521,
  fields: [
    ...waterRepairFields,
    { id: 'cb_other_750', label: 'Other', type: 'checkbox' },
    { id: 'et_other_704', label: 'Other (specify)', type: 'text' },
  ],
});

addScreen('G', {
  id: 'activity_services_water_repair_water_tank_screen',
  title: 'Water Tank Repair',
  type: 'screen',
  parentId: waterRepairParent,
  order: 522,
  fields: [
    ...waterRepairFields,
    { id: 'cb_other_635', label: 'Other', type: 'checkbox' },
    { id: 'et_other_615', label: 'Other (specify)', type: 'text' },
  ],
});

// Water Insulation (Section G)
addScreen('G', {
  id: 'services_water_insulation',
  title: 'Water Insulation',
  type: 'screen',
  parentId: waterRepairParent,
  order: 523,
  fields: [
    { id: 'actv_status', label: 'Status', type: 'dropdown', options: ['Good', 'Poor', 'Not applicable'] },
  ],
});

// ==========================================
// Save updated tree
// ==========================================

fs.writeFileSync(treePath, JSON.stringify(tree, null, 2));
console.log('\n=== PATCH COMPLETE ===');
console.log('Total patches applied:', patchLog.length);
console.log('Fields added:', patchLog.filter(p => p.action === 'ADD_FIELD').length);
console.log('Screens added:', patchLog.filter(p => p.action === 'ADD_SCREEN').length);
console.log('Errors:', patchLog.filter(p => p.action === 'ERROR').length);
console.log('Skipped (already exist):', patchLog.filter(p => p.action === 'SKIP').length);

// Save patch log
fs.writeFileSync('E:/s/scriber/mobile-app/parity_patch_log.json', JSON.stringify(patchLog, null, 2));
console.log('\nPatch log saved to parity_patch_log.json');
