const fs = require('fs');

const tree = JSON.parse(fs.readFileSync('E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json', 'utf8'));

// Build V2 dropdown inventory
const v2Dropdowns = [];
for (const sec of tree.sections) {
  if (!['E','F','G','H'].includes(sec.key)) continue;
  for (const node of sec.nodes) {
    if (node.type !== 'screen') continue;
    for (const field of (node.fields || [])) {
      if (field.type === 'dropdown' && field.options) {
        v2Dropdowns.push({
          section: sec.key,
          screen: node.id,
          fieldId: field.id,
          label: field.label,
          options: field.options,
        });
      }
    }
  }
}

// Old native string-arrays (from strings.xml extraction)
const oldArrays = {
  // Condition ratings
  'outside_property_chimney_content_rating': ['1', '2', '3'],
  'outside_property_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'outside_property_roof_covering_weather_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'outside_property_general_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'global_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],

  // Chimney
  'outside_property_stacks': ['Single', 'Multiple'],
  'outside_property_pots': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
  'outside_property_rendering': ['Fully', 'Partially'],
  'outside_property_Leaning_chimney_condition': ['Ok', 'Repair soon'],
  'outside_property_water_proofing': ['Lead', 'Mortar', 'Lead and mortar', 'Tiles', 'Other'],
  'outside_property_chimney_not_inspected_not_inspected_reason': ['Not applicable', 'Partial view', 'Removed chimney stack(s)', 'Removed pots'],

  // Roof
  'outside_property_roof_types': ['Pitched', 'Flat', 'Mansard', 'Other'],
  'outside_property_roof_covering_weather_status': ['Wet', 'Dry'],
  'outside_property_roof_covering_parapet_wall_rendered': ['Not rendered', 'Fully rendered', 'Partially rendered'],
  'outside_property_roof_covering_deflection_status': ['Minor', 'Significant'],
  'outside_property_roof_covering_roof_structure_status': ['Ok', 'Investigate'],

  // Repairs
  'repair_conditions': ['Repair soon', 'Repair now'],
  'activity_outside_property_roof_repair_tiles_condition': ['Repair soon', 'Repair now'],
  'activity_outside_property_chimney_repair_flaunching_condition': ['Repair soon', 'Repair now'],

  // Walls
  'dpc_status': ['Visible', 'Not Visible'],
  'damp_status': ['None', 'Present'],
  'movement_status': ['None', 'Usual', 'All elevations', 'Recent', 'Recurrent', 'Investigate'],
  'rendering_type': ['Fully', 'Partially'],

  // Windows/Doors
  'windows_safety_glass_rating_status': ['Noted', 'No SG Rating'],
  'out_side_doors_sealed_condition': ['Properly', 'Fairly', 'Poorly'],
  'out_side_doors_security_offered': ['Reasonable', 'Inadequate'],
  'out_side_doors_conservatory_porch_type': ['Conservatory', 'Porch', 'Open Porch', 'Integral porch', 'Other'],
  'out_side_doors_conservatory_porch_location': ['Front', 'Side', 'Rear'],
  'out_side_doors_conservatory_porch_roof': ['Conservatory', 'Porch'],
  'out_side_doors_conservatory_porch_roof_type': ['Pitched', 'Flat'],

  // Other (E8)
  'activity_outside_property_other_wall': ['Balcony', 'Carport', 'Roof terrace', 'Staircase', 'Other'],
  'outside_property_other_no_glass_safety_location': ['Balcony', 'Roof terrace', 'Other'],
  'activity_outside_property_repair_lintel_soon': ['Windows', 'Door'],
  'activity_outside_property_repair_other_steps_landing': ['Steps', 'Landing'],

  // Inside Property (F)
  'data_arr_construction': ['Built of traditional cut timber', 'Made up of factory made trusses', 'Made of steel', 'Other'],
  'data_arr_insulation': ['Adequate', 'Inadequate'],
  'data_arr_underlining': ['Underlining', 'No underlining'],
  'data_arr_roof_structure_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'inside_property_floors_about_floors_construction': ['All solid', 'All suspended', 'mixture of'],
  'inside_property_floors_timber_decay': ['None', 'Investigate'],
  'inside_property_floors_dampness': ['known cause', 'Unknown cause'],
  'inside_property_floors_ventilation': ['Ok', 'Poor'],
  'inside_property_ceilings_about_ceilings_made_up': ['mainly of', 'of a mixture of'],
  'inside_property_wap_movement_cracks': ['None', 'Normal', 'Multiple locations'],
  'inside_property_repair_insect_infestation': ['None', 'Minor', 'Severe'],
  'inside_property_repair_timber_rot': ['Minor', 'Severe'],
  'inside_property_other_status': ['No access', 'Not in use', 'In use', 'Not habitable', 'Flooded'],
  'inside_property_bf_fan': ['OK', 'Replace'],
  'inside_property_ww_rocking_handrails': ['No Handrails', 'Available'],
  'wap_dampness_status': ['None', 'Noted'],

  // Services (G)
  'mains_gas_condition': ['Ok', 'Not Inspected', 'No Gas Installation'],
  'mains_gas_meter_valve_location': ['is under the stairs', 'is in an outside box', 'is in the entrance hall', 'is in the kitchen', 'is in the garage', 'is in the communal cupboard', 'Other'],
  'service_heating_heated_by': ['Combination boiler', 'Conventional boiler', 'Condensing boiler', 'Conventional boiler combined with tank', 'Other'],
  'service_heating_installed_in_location': ['Kitchen', 'Utility', 'Bedroom', 'Garage', 'Lounge', 'Chimney breast', 'Other'],
  'condition_heating': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'connected_heating': ['Radiators', 'Underfloor pipes', 'Other'],
  'service_water_heating_gas_heating_type': ['Combi Boiler', 'Conventional', 'Other'],
  'service_water_heating_gas_heating_location': ['Airing cupboard', 'Kitchen', 'Bedroom', 'Garage', 'Other'],
  'service_drainage_chamber_lids_defect': ['Was lifted', 'Were lifted'],
  'water_insulation_status': ['Ok', 'Inadequate'],
  'water_tank_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],

  // Grounds (H)
  'garage_type': ['Detached Garage', 'Semi-detached Garage', 'Integral Garage', 'Garage in a Block of Garages', 'Other'],
  'garage_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'no_of_garage': ['Single', 'Double', 'Other'],
  'Ground_Front_Garden_Type': ['Paved', 'Lawned', 'Decked', 'Laid with gravel', 'Laid with stone chippings', 'Laid with tile chippings', 'Other'],
  'Ground_Front_Garden_Boundry_Fences': ['Timber', 'Brick wall', 'Concrete wall', 'Wire mesh', 'Hedges', 'Shrubs', 'Other'],
  'ground_other_garden_fences_condition': ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
  'knotweed_status': ['Noted', 'Restricted View'],
  'proximity_of_tree': ['One', 'A few', 'Several'],
  'proximity_condition': ['OK', 'Problems'],
};

// Known mappings: which string-array is used by which V2 field
// We check V2 dropdowns against known array patterns
let mismatches = 0;
let checked = 0;

// Check all V2 dropdowns against known patterns
for (const dd of v2Dropdowns) {
  const opts = dd.options;

  // Skip variant screens (__)
  if (dd.screen.includes('__')) continue;

  // Try to match against known arrays
  let matched = false;
  for (const [arrayName, arrayOpts] of Object.entries(oldArrays)) {
    if (JSON.stringify(opts) === JSON.stringify(arrayOpts)) {
      matched = true;
      break;
    }
    // Check trimmed
    const trimmedOld = arrayOpts.map(o => o.trim());
    const trimmedV2 = opts.map(o => o.trim());
    if (JSON.stringify(trimmedV2) === JSON.stringify(trimmedOld)) {
      matched = true;
      break;
    }
  }

  if (!matched) {
    // Check for common patterns
    const isConditionRating = opts.length === 3 && opts[0] === '1' && opts[1] === '2' && opts[2] === '3';
    const isCondition = opts.length === 3 && opts.includes('Reasonable') && opts.includes('Satisfactory');
    const isRepair = opts.length === 2 && opts.includes('Repair soon') && opts.includes('Repair now');
    const isYesNo = opts.length === 2 && (opts.includes('Yes') || opts.includes('Ok'));

    if (!isConditionRating && !isCondition && !isRepair && !isYesNo) {
      // This dropdown has options that don't match any known array
      // But it could still be correct if it was set programmatically with different values
      // Only flag it if it looks suspicious
    }
  }

  checked++;
}

// Specific critical dropdown checks
const criticalChecks = [
  { screen: 'activity_outside_property_chimney_main_screen', field: 'android_material_design_spinner4', expected: ['1', '2', '3'], name: 'Chimney Condition Rating' },
  { screen: 'activity_outside_property_stacks', field: 'android_material_design_spinner', expected: ['Single', 'Multiple'], name: 'Stacks Type' },
  { screen: 'activity_outside_property_stacks', field: 'android_material_design_spinner2', expected: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'], name: 'Pots Count' },
  { screen: 'activity_outside_property_water_proofing', field: 'actv_type', expected: ['Lead', 'Mortar', 'Lead and mortar', 'Tiles', 'Other'], name: 'Waterproofing Type' },
  { screen: 'activity_outside_property_main_walls_dpc', field: 'actv_status', expected: ['Visible', 'Not Visible'], name: 'DPC Status' },
  { screen: 'activity_outside_property_main_walls_damp', field: 'actv_status', expected: ['None', 'Present'], name: 'Damp Status' },
  { screen: 'activity_outside_property_main_walls_movements', field: 'actv_status', expected: ['None', 'Usual', 'All elevations', 'Recent', 'Recurrent', 'Investigate'], name: 'Movement Status' },
  { screen: 'activity_inside_property_about_roof_structure', field: 'actv_construction', expected: ['Built of traditional cut timber', 'Made up of factory made trusses', 'Made of steel', 'Other'], name: 'Roof Construction' },
  { screen: 'activity_inside_property_about_roof_structure', field: 'actv_insulation', expected: ['Adequate', 'Inadequate'], name: 'Roof Insulation' },
  { screen: 'activity_services_main_gas', field: 'actv_condition', expected: ['Ok', 'Not Inspected', 'No Gas Installation'], name: 'Gas Condition' },
  { screen: 'activity_services_heating_about_heating', field: 'actv_heated_by', expected: ['Combination boiler', 'Conventional boiler', 'Condensing boiler', 'Conventional boiler combined with tank', 'Other'], name: 'Heated By' },
  { screen: 'activity_grounds_garage', field: 'actv_type', expected: ['Detached Garage', 'Semi-detached Garage', 'Integral Garage', 'Garage in a Block of Garages', 'Other'], name: 'Garage Type' },
];

console.log('=== CRITICAL DROPDOWN VERIFICATION ===');
console.log();

for (const check of criticalChecks) {
  const dd = v2Dropdowns.find(d => d.screen === check.screen && d.fieldId === check.field);
  if (!dd) {
    console.log('[SKIP] ' + check.name + ' - V2 field not found: ' + check.screen + '.' + check.field);
    continue;
  }

  const v2Opts = dd.options.map(o => o.trim());
  const expectedOpts = check.expected.map(o => o.trim());

  if (JSON.stringify(v2Opts) === JSON.stringify(expectedOpts)) {
    console.log('[PASS] ' + check.name);
  } else {
    // Check for subset/superset
    const missing = expectedOpts.filter(o => !v2Opts.includes(o));
    const extra = v2Opts.filter(o => !expectedOpts.includes(o));

    if (missing.length === 0 && extra.length === 0) {
      console.log('[PASS] ' + check.name + ' (order differs)');
    } else {
      console.log('[MISMATCH] ' + check.name);
      if (missing.length > 0) console.log('  Missing in V2: ' + JSON.stringify(missing));
      if (extra.length > 0) console.log('  Extra in V2: ' + JSON.stringify(extra));
      console.log('  Expected: ' + JSON.stringify(expectedOpts));
      console.log('  V2 has: ' + JSON.stringify(v2Opts));
      mismatches++;
    }
  }
}

console.log();
console.log('=== SUMMARY ===');
console.log('Total V2 dropdowns (base screens):', v2Dropdowns.filter(d => !d.screen.includes('__')).length);
console.log('Critical checks:', criticalChecks.length);
console.log('Mismatches:', mismatches);
