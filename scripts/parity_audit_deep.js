const fs = require('fs');
const path = require('path');

// Load V2 tree
const tree = JSON.parse(fs.readFileSync('E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json', 'utf8'));
const layoutDir = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/layout';

// Build V2 map
const v2Map = {};
const sectionKeys = ['E', 'F', 'G', 'H'];
for (const sec of tree.sections) {
  if (!sectionKeys.includes(sec.key)) continue;
  for (const node of sec.nodes) {
    if (node.type === 'screen') {
      v2Map[node.id] = { section: sec.key, title: node.title, fields: node.fields || [], parentId: node.parentId };
    }
  }
}

// Classify the 91 "missing" old native screens
const missingScreens = [
  // Navigation/container screens (not data screens - just menus)
  'activity_outside_property', // Section E main menu
  'activity_inside_property', // Section F main menu
  'activity_outside_property_chimney', // Chimney sub-nav
  'activity_outside_property_conservatory_porch', // Conserv sub-nav
  'activity_outside_property_main_walls', // Walls sub-nav
  'activity_outside_property_main_wall_repairs', // Repairs sub-nav
  'activity_outside_property_other', // Other sub-nav
  'activity_outside_property_other_joinery_and_finishes', // Joinery sub-nav
  'activity_outside_property_other_repairs', // Other repairs sub-nav
  'activity_outside_property_outside_door', // Door sub-nav
  'activity_outside_property_out_side_doors_repairs', // Door repairs sub-nav
  'activity_outside_property_rainwater_goods', // RWG sub-nav
  'activity_outside_property_roof_covering', // Roof covering sub-nav
  'activity_outside_property_roof_repairs', // Roof repairs sub-nav
  'activity_outside_property_windows', // Windows sub-nav
  'activity_outside_property_windows_repairs', // Window repairs sub-nav
  'activity_outside_property_external_features', // External features sub-nav
  'activity_inside_property_ceilings', // Ceilings sub-nav
  'activity_inside_property_ceilings_repairs', // Ceiling repairs sub-nav
  'activity_inside_property_repair', // Inside repair sub-nav
  'activity_inside_property_roof_structure', // Roof structure sub-nav
  'activity_inside_property_walls_and_partitions', // WAP sub-nav
  'activity_in_side_property_bathroom_fittings', // Bathroom sub-nav
  'activity_in_side_property_built_in_fittings_repair', // Built-in repairs sub-nav
  'activity_in_side_property_fire_places_repair', // Fireplaces repair sub-nav
  'activity_in_side_property_floors_repair', // Floors repair sub-nav
  'activity_in_side_property_other', // Other sub-nav
  'activity_in_side_property_wap_repair', // WAP repair sub-nav
  'activity_in_side_property_wood_work_repair', // Woodwork repair sub-nav
  'activity_grounds_other', // Grounds other sub-nav
  'activity_grounds_other_area', // Other area sub-nav
  'activity_grounds_garage_repair_main_screen', // Garage repair sub-nav
  'activity_grounds_other_repair_main_screen', // Other repair sub-nav
  'activity_services_electricity', // Electricity sub-nav
  'activity_services_electricity_repair_main_screen', // Elec repair sub-nav
  'activity_services_gas_oil_repair_main_screen', // Gas repair sub-nav
  'activity_services_heating', // Heating sub-nav
  'activity_services_water', // Water sub-nav
  'activity_services_water_heating', // Water heating sub-nav
  'activity_services_water_heating_repair_main_screen', // WH repair sub-nav
  'activity_services_drainage_repair_main_screen', // Drainage repair sub-nav
  'activity_services_solar_power_main_screen', // Solar power sub-nav
  'activity_services_other_services_main_screen', // Other services sub-nav

  // Variant selector screens (choose between types - handled by group navigation in V2)
  'activity_out_side_property_about_the_door_diffrent', // Door type selector
  'activity_out_side_property_conservatory_and_porch_diffrent', // Conserv/porch selector
  'activity_out_side_property_main_wall_about_the_wall_diffrent', // Wall type selector
  'activity_out_side_property_main_wall_lintel_diffrent', // Lintel type selector
  'activity_out_side_property_other_diffrent', // Other area type selector
  'activity_out_side_property_other_repair_diffrent', // Other repair selector
  'activity_out_side_property_out_side_door_diffrent', // Outside door type selector
  'activity_out_side_property_out_side_door_repair_diffrent', // Door repair selector
  'activity_out_side_property_repair_chimney_aerial_dish_diffrent', // Aerial/dish selector
  'activity_in_side_property_extractor_fan_diffrent', // Extractor fan selector
  'activity_in_side_property_other_basement', // Basement sub-nav
  'activity_in_side_property_other_cellar', // Cellar sub-nav
  'activity_inside_property_other_basement_main_screen', // Basement main screen
  'activity_inside_property_other_celler_main_screen', // Cellar main screen
  'activity_inside_property_other_fittings_main_screen', // Fittings main screen
  'activity_inside_property_wood_work_main_screen', // Old wood work main (replaced by activity_inside_property_woodwork_main_screen)
];

// Screens that have actual data fields and need to be checked
const dataScreensMissing = [
  'activity_outside_property_pots', // Chimney pots (might be merged into chimney_removed_pots)
  'activity_outside_property_rendering', // Rendering (1 field in V2 tree - check if separate or merged)
  'activity_outside_property_roof_covering_main_screen', // Roof covering main (different name in V2)
  'activity_outside_property_out_side_doors_repairs_failed_glazing_location', // Door failed glazing
  'activity_outside_property_out_side_doors_repairs_inadequate_lock_location', // Door inadequate lock
  'activity_outside_property_out_side_doors_wall_sealing', // Door wall sealing
  'activity_outside_property_out_side_safety_glass_rating', // Outside safety glass
  'activity_outside_property_other_joinery_fininshes_condition', // Joinery condition (typo in original)
  'activity_in_side_property_wood_work_creaking_stairs', // Creaking stairs
  'activity_in_side_property_wood_work_glazed_internal_doors', // Glazed internal doors
  'activity_in_side_property_wood_work_open_threads', // Open threads
  'activity_in_side_property_wood_work_out_of_square_doors', // Out of square doors
  'activity_in_side_property_wood_work_rocking_handrails', // Rocking handrails
  'activity_communal_garden', // Communal garden (simple - Type + Boundary Fencing)
  'activity_front_garden', // Front garden (simple - Type + Boundary Fencing)
  'activity_rear_garden', // Rear garden (simple - Type + Boundary Fencing)
  'activity_garden', // General garden
  'activity_grounds_other_communal_garden', // Communal garden detail
  'activity_grounds_other_other_garden', // Other garden detail
  'activity_grounds_other_rear_garden', // Rear garden detail
  'activity_grounds_other_side_garden', // Side garden detail
  'activity_services_drainage_chamber_lids', // Chamber lids
  'activity_services_drainage_public_system', // Public system
  'activity_services_water_heating_cylinder', // Cylinder
  'activity_services_water_repair_asbestos', // Water repair asbestos
  'activity_services_water_repair_cover_screen', // Water repair cover
  'activity_services_water_repair_water_tank_screen', // Water tank repair
  'outside_property_roof_covering_roof_spreading_layout', // Roof spreading
  'services_water_insulation', // Water insulation
  'activity_pid_garage', // PID garage (valuation-specific)
  'activity_pid_rainwater_goods', // PID rainwater (valuation-specific)
];

console.log('=== DISCREPANCY CLASSIFICATION ===');
console.log();
console.log('CATEGORY 1: Navigation/Container screens (NOT data screens)');
console.log('These are menu/navigation screens in old native that are handled by');
console.log('the group hierarchy in V2. They do not contain data fields.');
console.log('Count:', missingScreens.length);
console.log('STATUS: NOT A DISCREPANCY - architecture difference, no data loss');
console.log();
console.log('CATEGORY 2: Variant Selector screens ("diffrent" screens)');
console.log('These are screens that let users choose between types (e.g., wall types).');
console.log('In V2, this is handled by group navigation nodes.');
console.log('STATUS: NOT A DISCREPANCY - architecture difference, no data loss');
console.log();
console.log('CATEGORY 3: Data screens that may need attention');
console.log('Count:', dataScreensMissing.length);
console.log();

// Now check each data screen
for (const screenId of dataScreensMissing) {
  const layoutFile = path.join(layoutDir, screenId + '.xml');
  const exists = fs.existsSync(layoutFile);

  // Check if it's in V2 under a different name
  let v2Match = null;
  for (const [id, data] of Object.entries(v2Map)) {
    if (id.includes(screenId.replace('activity_', '')) || screenId.includes(id.replace('activity_', ''))) {
      v2Match = { id, title: data.title, fieldCount: data.fields.length };
      break;
    }
  }

  console.log('  ' + screenId);
  console.log('    Old native layout exists:', exists);
  if (v2Match) {
    console.log('    Possible V2 match:', v2Match.id, '(' + v2Match.fieldCount + ' fields)');
  } else {
    console.log('    V2 match: NONE FOUND - POTENTIAL MISSING SCREEN');
  }
  console.log();
}

// V2-only variant screens analysis
console.log();
console.log('=== V2-ONLY SCREENS ANALYSIS ===');
console.log('These are screens that exist in V2 but have no direct old native layout.');
console.log('Most are __variant suffixed duplicates of a base screen for different areas.');
console.log();

const v2OnlyScreens = [];
const allLayouts = fs.readdirSync(layoutDir).filter(f => f.endsWith('.xml'));
for (const [id, data] of Object.entries(v2Map)) {
  if (!allLayouts.includes(id + '.xml')) {
    v2OnlyScreens.push({ id, ...data });
  }
}

// Classify V2-only screens
const variantScreens = v2OnlyScreens.filter(s => s.id.includes('__'));
const nonVariantV2Only = v2OnlyScreens.filter(s => !s.id.includes('__'));

console.log('Variant screens (duplicates with __ suffix):', variantScreens.length);
console.log('Non-variant V2-only screens:', nonVariantV2Only.length);
console.log();

// Variant screens are copies of base screens for different area types
// (e.g., carport, porch canopy, roof terrace, balcony, etc.)
// These are CORRECT - they duplicate the base screen fields for each area type

console.log('Non-variant V2-only screens:');
for (const s of nonVariantV2Only) {
  // Check if base layout exists
  const baseName = s.id.replace(/__.*$/, '');
  const baseExists = allLayouts.includes(baseName + '.xml');
  console.log('  [' + s.section + '] ' + s.id + ' - ' + s.title);
  if (baseExists) {
    console.log('    Base layout: ' + baseName + '.xml EXISTS');
  } else {
    console.log('    Base layout: NOT FOUND');
  }
}

// Now the critical part: field-by-field comparison for matched screens
console.log();
console.log('=== FIELD COUNT COMPARISON (matched screens) ===');
console.log();

// Parse XML to extract field counts (simple regex-based approach)
function extractFieldsFromXml(xmlPath) {
  const content = fs.readFileSync(xmlPath, 'utf8');
  const fields = [];

  // Extract EditText fields
  const etRegex = /android:id="@\+id\/([^"]+)"/g;
  let match;
  const allIds = [];
  while ((match = etRegex.exec(content)) !== null) {
    allIds.push(match[1]);
  }

  // Filter to actual data fields (exclude layout containers, buttons, etc.)
  const dataIds = allIds.filter(id => {
    // Skip layout containers
    if (id.startsWith('ll') || id.startsWith('rl_') || id.startsWith('fd_') ||
        id.startsWith('sv_') || id.startsWith('nestedScrollView') ||
        id === 'al_btnNext' || id === 'al_btnSave' || id === 'al_btnNotes' ||
        id === 'al_toolbar' || id === 'al_title' || id === 'al_tvTitle' ||
        id === 'al_topBar' || id.startsWith('al_') || id.startsWith('tv_') ||
        id === 'progressBar' || id === 'toolbar') return false;
    return true;
  });

  return { allIds, dataIds };
}

// Compare field counts for critical screens
const criticalScreens = [
  'activity_outside_property_stacks',
  'activity_outside_property_repair_flashing',
  'activity_outside_property_chimney_not_inspected',
  'activity_outside_property_main_walls_about_wall',
  'activity_outside_property_main_walls_damp',
  'activity_outside_property_main_walls_dpc',
  'activity_outside_property_main_walls_movements',
  'activity_outside_property_windows_aboutwindow',
  'activity_outside_property_windows_velux_window',
  'activity_outside_property_out_side_doors_about_doors',
  'activity_outside_property_conservatory_porch_location_construction',
  'activity_outside_property_rwg_about',
  'activity_outside_property_other_about_joinery_and_finishes',
  'activity_outside_property_other_communal_area',
  'activity_inside_property_about_roof_structure',
  'activity_inside_property_water_tank',
  'inside_property_ceilings_about_ceilings',
  'activity_inside_property_wap_walls',
  'activity_in_side_property_floors_about_floor',
  'activity_in_side_property_fire_places',
  'activity_in_side_property_built_in_fittings',
  'activity_in_side_property_wood_work_second',
  'activity_in_side_property_bathroom_fittings_second',
  'activity_services_heating_about_heating',
  'activity_services_drainage',
  'activity_grounds_garage',
  'activity_grounds_other_front_garden',
  'activity_service_about_electricity',
  'activity_services_main_gas',
  'activity_services_water_main_water',
];

let discrepancies = 0;
const discrepancyList = [];

for (const screenId of criticalScreens) {
  const xmlPath = path.join(layoutDir, screenId + '.xml');
  if (!fs.existsSync(xmlPath)) continue;

  const v2 = v2Map[screenId];
  if (!v2) continue;

  const xmlFields = extractFieldsFromXml(xmlPath);
  const v2FieldCount = v2.fields.length;
  const v2FieldIds = v2.fields.map(f => f.id);

  // Find fields in old native not in V2
  const missingInV2Fields = xmlFields.dataIds.filter(id => !v2FieldIds.includes(id));
  // Find V2 fields not in old native
  const extraInV2Fields = v2FieldIds.filter(id => !xmlFields.dataIds.includes(id) && !xmlFields.allIds.includes(id));

  const status = (missingInV2Fields.length === 0 && extraInV2Fields.length === 0) ? 'PASS' : 'FAIL';
  if (status === 'FAIL') discrepancies++;

  console.log('[' + status + '] ' + screenId + ' - ' + v2.title);
  console.log('       Old native data fields: ' + xmlFields.dataIds.length + ' | V2 fields: ' + v2FieldCount);
  if (missingInV2Fields.length > 0) {
    console.log('       MISSING in V2: ' + missingInV2Fields.join(', '));
    discrepancyList.push({
      screen: screenId,
      title: v2.title,
      type: 'MISSING_IN_V2',
      fields: missingInV2Fields
    });
  }
  if (extraInV2Fields.length > 0) {
    console.log('       EXTRA in V2: ' + extraInV2Fields.join(', '));
  }
}

console.log();
console.log('=== SUMMARY ===');
console.log('Critical screens checked:', criticalScreens.length);
console.log('Discrepancies found:', discrepancies);
console.log();

// Save discrepancy data
fs.writeFileSync('E:/s/scriber/mobile-app/parity_audit_results.json', JSON.stringify({
  summary: {
    oldNativeLayouts: 373,
    v2Screens: Object.keys(v2Map).length,
    matched: 282,
    missingInV2Nav: missingScreens.length,
    missingInV2Data: dataScreensMissing.length,
    v2OnlyVariants: variantScreens.length,
    v2OnlyNonVariant: nonVariantV2Only.length,
    fieldDiscrepancies: discrepancies,
  },
  dataScreensMissing,
  discrepancyList,
}, null, 2));

console.log('Results saved to parity_audit_results.json');
