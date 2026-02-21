const fs = require('fs');
const path = require('path');

// Load V2 tree
const tree = JSON.parse(fs.readFileSync('E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json', 'utf8'));
const layoutDir = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/layout';
const stringsPath = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml';

// Load strings.xml for dropdown arrays
const stringsXml = fs.readFileSync(stringsPath, 'utf8');

// Extract string-arrays from strings.xml
function extractStringArrays(xml) {
  const arrays = {};
  const arrayRegex = /<string-array\s+name="([^"]+)">([\s\S]*?)<\/string-array>/g;
  const itemRegex = /<item>([\s\S]*?)<\/item>/g;
  let match;
  while ((match = arrayRegex.exec(xml)) !== null) {
    const name = match[1];
    const body = match[2];
    const items = [];
    let itemMatch;
    while ((itemMatch = itemRegex.exec(body)) !== null) {
      items.push(itemMatch[1].trim());
    }
    arrays[name] = items;
  }
  return arrays;
}

const stringArrays = extractStringArrays(stringsXml);

// Build V2 map for sections E, F, G, H
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

// Parse XML layout to extract fields with types
function extractFieldsFromXml(xmlPath) {
  const content = fs.readFileSync(xmlPath, 'utf8');
  const fields = [];

  // Extract Spinner fields with their entries arrays
  const spinnerRegex = /<(?:Spinner|android\.widget\.Spinner|AppCompatSpinner)[^>]*?android:id="@\+id\/([^"]+)"[^>]*?(?:android:entries="@array\/([^"]+)")?[^>]*?\/?>/g;
  // Also try reverse order (entries before id)
  const spinnerRegex2 = /<(?:Spinner|android\.widget\.Spinner|AppCompatSpinner)[^>]*?android:entries="@array\/([^"]+)"[^>]*?android:id="@\+id\/([^"]+)"[^>]*?\/?>/g;

  let match;
  const spinnerIds = new Set();

  // First pass: extract spinners
  const spinnerBlocks = content.match(/<(?:Spinner|android\.widget\.Spinner|AppCompatSpinner|com\.google\.android\.material\.textfield\.MaterialAutoCompleteTextView)[^>]*?>/g) || [];
  for (const block of spinnerBlocks) {
    const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
    const entriesMatch = block.match(/android:entries="@array\/([^"]+)"/);
    if (idMatch) {
      const id = idMatch[1];
      spinnerIds.add(id);
      fields.push({
        id,
        type: 'spinner',
        arrayName: entriesMatch ? entriesMatch[1] : null,
        options: entriesMatch && stringArrays[entriesMatch[1]] ? stringArrays[entriesMatch[1]] : []
      });
    }
  }

  // Also check MaterialAutoCompleteTextView (used as dropdowns)
  const mactvBlocks = content.match(/<com\.google\.android\.material\.textfield\.MaterialAutoCompleteTextView[^>]*?>/g) || [];
  for (const block of mactvBlocks) {
    const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
    const entriesMatch = block.match(/android:entries="@array\/([^"]+)"/);
    if (idMatch && !spinnerIds.has(idMatch[1])) {
      const id = idMatch[1];
      spinnerIds.add(id);
      fields.push({
        id,
        type: 'spinner',
        arrayName: entriesMatch ? entriesMatch[1] : null,
        options: entriesMatch && stringArrays[entriesMatch[1]] ? stringArrays[entriesMatch[1]] : []
      });
    }
  }

  // Extract EditText fields
  const etBlocks = content.match(/<(?:EditText|com\.google\.android\.material\.textfield\.TextInputEditText)[^>]*?>/g) || [];
  for (const block of etBlocks) {
    const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
    if (idMatch && !spinnerIds.has(idMatch[1])) {
      fields.push({ id: idMatch[1], type: 'text' });
    }
  }

  // Extract CheckBox fields
  const cbBlocks = content.match(/<(?:CheckBox|androidx\.appcompat\.widget\.AppCompatCheckBox|com\.google\.android\.material\.checkbox\.MaterialCheckBox)[^>]*?(?:\/>|>[^<]*<\/(?:CheckBox|androidx\.appcompat\.widget\.AppCompatCheckBox|com\.google\.android\.material\.checkbox\.MaterialCheckBox)>)/g) || [];
  for (const block of cbBlocks) {
    const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
    if (idMatch) {
      fields.push({ id: idMatch[1], type: 'checkbox' });
    }
  }

  // Extract all android:id for completeness check
  const allIdRegex = /android:id="@\+id\/([^"]+)"/g;
  const allIds = [];
  while ((match = allIdRegex.exec(content)) !== null) {
    allIds.push(match[1]);
  }

  // Filter data fields (exclude layout containers, buttons, toolbars, titles)
  const dataFields = fields.filter(f => {
    const id = f.id;
    if (id.startsWith('ll') || id.startsWith('rl_') || id.startsWith('fd_') ||
        id.startsWith('sv_') || id.startsWith('nestedScrollView') ||
        id.startsWith('al_') || id.startsWith('tv_') ||
        id.startsWith('btn_') || id === 'progressBar' || id === 'toolbar' ||
        id.startsWith('til_') || id.startsWith('textInputLayout') ||
        id.startsWith('cardView') || id.startsWith('iv_')) return false;
    return true;
  });

  return { dataFields, allIds };
}

// Run comprehensive comparison
const allLayouts = fs.readdirSync(layoutDir).filter(f => f.endsWith('.xml'));
const inspPrefixes = [
  'activity_outside_property', 'outside_property_',
  'activity_inside_property', 'activity_in_side_property', 'inside_property_',
  'activity_services_', 'activity_service_', 'services_',
  'activity_grounds_', 'activity_ground_', 'activity_garage',
  'activity_front_garden', 'activity_rear_garden', 'activity_communal_garden',
  'activity_garden', 'activity_rwg_', 'activity_other_repair',
  'activity_out_side_', 'activity_pid_garage', 'activity_pid_rainwater'
];

const inspLayouts = allLayouts.filter(f =>
  inspPrefixes.some(prefix => f.startsWith(prefix))
);

// Comprehensive comparison
const report = {
  summary: { total_matched: 0, total_pass: 0, total_fail: 0, total_missing_screens: 0 },
  missing_fields: [],   // Fields in old native NOT in V2
  extra_fields: [],      // Fields in V2 NOT in old native
  dropdown_mismatches: [], // Dropdown options differ
  missing_screens: [],   // Old native screens not in V2
  pass_screens: [],      // Screens that fully match
};

let matched = 0, pass = 0, fail = 0;

for (const layout of inspLayouts) {
  const screenId = layout.replace('.xml', '');
  const v2 = v2Map[screenId];

  if (!v2) continue; // Skip unmatched screens (handled separately)
  matched++;

  const xmlPath = path.join(layoutDir, layout);
  const oldFields = extractFieldsFromXml(xmlPath);
  const v2Fields = v2.fields;
  const v2FieldIds = v2Fields.map(f => f.id);
  const v2FieldMap = {};
  for (const f of v2Fields) {
    v2FieldMap[f.id] = f;
  }

  const oldDataFieldIds = oldFields.dataFields.map(f => f.id);
  const oldFieldMap = {};
  for (const f of oldFields.dataFields) {
    oldFieldMap[f.id] = f;
  }

  // Find missing in V2 (old native has, V2 doesn't)
  const missingInV2 = oldFields.dataFields.filter(f => !v2FieldIds.includes(f.id));
  // Find extra in V2 (V2 has, old native doesn't)
  const extraInV2 = v2Fields.filter(f => !oldDataFieldIds.includes(f.id) && !oldFields.allIds.includes(f.id));

  // Compare dropdown options
  const dropdownMismatches = [];
  for (const oldField of oldFields.dataFields) {
    if (oldField.type !== 'spinner') continue;
    const v2Field = v2FieldMap[oldField.id];
    if (!v2Field) continue;
    if (v2Field.type !== 'dropdown' && v2Field.type !== 'spinner') continue;

    const oldOptions = oldField.options || [];
    const v2Options = v2Field.options || [];

    // Compare options
    if (JSON.stringify(oldOptions) !== JSON.stringify(v2Options)) {
      // Check if it's just whitespace/case difference
      const normalizedOld = oldOptions.map(o => o.trim());
      const normalizedV2 = v2Options.map(o => o.trim());
      if (JSON.stringify(normalizedOld) !== JSON.stringify(normalizedV2)) {
        dropdownMismatches.push({
          fieldId: oldField.id,
          arrayName: oldField.arrayName,
          oldOptions: oldOptions,
          v2Options: v2Options,
          missingInV2: oldOptions.filter(o => !v2Options.includes(o) && !v2Options.includes(o.trim())),
          extraInV2: v2Options.filter(o => !oldOptions.includes(o) && !oldOptions.includes(o.trim())),
        });
      }
    }
  }

  const hasMissingFields = missingInV2.length > 0;
  const hasExtraFields = extraInV2.length > 0;
  const hasDropdownIssues = dropdownMismatches.length > 0;
  const isPass = !hasMissingFields && !hasDropdownIssues;

  if (isPass) {
    pass++;
    report.pass_screens.push(screenId);
  } else {
    fail++;
    if (hasMissingFields) {
      report.missing_fields.push({
        screen: screenId,
        section: v2.section,
        title: v2.title,
        fields: missingInV2.map(f => ({ id: f.id, type: f.type })),
      });
    }
    if (hasDropdownIssues) {
      report.dropdown_mismatches.push({
        screen: screenId,
        section: v2.section,
        title: v2.title,
        mismatches: dropdownMismatches,
      });
    }
  }

  if (hasExtraFields) {
    report.extra_fields.push({
      screen: screenId,
      section: v2.section,
      title: v2.title,
      fields: extraInV2.map(f => ({ id: f.id, type: f.type, label: f.label })),
    });
  }
}

report.summary.total_matched = matched;
report.summary.total_pass = pass;
report.summary.total_fail = fail;

// Add missing screens analysis
const navScreens = new Set([
  'activity_outside_property', 'activity_inside_property',
  'activity_outside_property_chimney', 'activity_outside_property_conservatory_porch',
  'activity_outside_property_main_walls', 'activity_outside_property_main_wall_repairs',
  'activity_outside_property_other', 'activity_outside_property_other_joinery_and_finishes',
  'activity_outside_property_other_repairs', 'activity_outside_property_outside_door',
  'activity_outside_property_out_side_doors_repairs', 'activity_outside_property_rainwater_goods',
  'activity_outside_property_roof_covering', 'activity_outside_property_roof_repairs',
  'activity_outside_property_windows', 'activity_outside_property_windows_repairs',
  'activity_outside_property_external_features',
  'activity_inside_property_ceilings', 'activity_inside_property_ceilings_repairs',
  'activity_inside_property_repair', 'activity_inside_property_roof_structure',
  'activity_inside_property_walls_and_partitions',
  'activity_in_side_property_bathroom_fittings', 'activity_in_side_property_built_in_fittings_repair',
  'activity_in_side_property_fire_places_repair', 'activity_in_side_property_floors_repair',
  'activity_in_side_property_other', 'activity_in_side_property_wap_repair',
  'activity_in_side_property_wood_work_repair',
  'activity_grounds_other', 'activity_grounds_other_area',
  'activity_grounds_garage_repair_main_screen', 'activity_grounds_other_repair_main_screen',
  'activity_services_electricity', 'activity_services_electricity_repair_main_screen',
  'activity_services_gas_oil_repair_main_screen', 'activity_services_heating',
  'activity_services_water', 'activity_services_water_heating',
  'activity_services_water_heating_repair_main_screen',
  'activity_services_drainage_repair_main_screen',
  'activity_services_solar_power_main_screen', 'activity_services_other_services_main_screen',
]);

const variantSelectorScreens = new Set([
  'activity_out_side_property_about_the_door_diffrent',
  'activity_out_side_property_conservatory_and_porch_diffrent',
  'activity_out_side_property_main_wall_about_the_wall_diffrent',
  'activity_out_side_property_main_wall_lintel_diffrent',
  'activity_out_side_property_other_diffrent',
  'activity_out_side_property_other_repair_diffrent',
  'activity_out_side_property_out_side_door_diffrent',
  'activity_out_side_property_out_side_door_repair_diffrent',
  'activity_out_side_property_repair_chimney_aerial_dish_diffrent',
  'activity_in_side_property_extractor_fan_diffrent',
  'activity_in_side_property_other_basement',
  'activity_in_side_property_other_cellar',
  'activity_inside_property_other_basement_main_screen',
  'activity_inside_property_other_celler_main_screen',
  'activity_inside_property_other_fittings_main_screen',
  'activity_inside_property_wood_work_main_screen',
]);

for (const layout of inspLayouts) {
  const screenId = layout.replace('.xml', '');
  if (v2Map[screenId]) continue;
  if (navScreens.has(screenId)) continue;
  if (variantSelectorScreens.has(screenId)) continue;

  // This is a data screen missing from V2
  const xmlPath = path.join(layoutDir, layout);
  const oldFields = extractFieldsFromXml(xmlPath);

  report.missing_screens.push({
    screen: screenId,
    dataFields: oldFields.dataFields.map(f => ({ id: f.id, type: f.type, options: f.options || undefined, arrayName: f.arrayName || undefined })),
  });
}

report.summary.total_missing_screens = report.missing_screens.length;

// Console output
console.log('=== COMPREHENSIVE PARITY AUDIT RESULTS ===');
console.log();
console.log('SUMMARY:');
console.log('  Matched screens:', report.summary.total_matched);
console.log('  PASS (no missing fields or dropdown issues):', report.summary.total_pass);
console.log('  FAIL (has missing fields or dropdown issues):', report.summary.total_fail);
console.log('  Missing data screens (old native not in V2):', report.summary.total_missing_screens);
console.log();

console.log('=== SCREENS WITH MISSING FIELDS ===');
for (const item of report.missing_fields) {
  console.log('[' + item.section + '] ' + item.screen + ' - ' + item.title);
  for (const f of item.fields) {
    console.log('    MISSING: ' + f.id + ' (' + f.type + ')');
  }
}
console.log();

console.log('=== DROPDOWN OPTION MISMATCHES ===');
for (const item of report.dropdown_mismatches) {
  console.log('[' + item.section + '] ' + item.screen + ' - ' + item.title);
  for (const m of item.mismatches) {
    console.log('  Field: ' + m.fieldId + ' (array: ' + m.arrayName + ')');
    if (m.missingInV2.length > 0) {
      console.log('    Missing in V2: ' + JSON.stringify(m.missingInV2));
    }
    if (m.extraInV2.length > 0) {
      console.log('    Extra in V2: ' + JSON.stringify(m.extraInV2));
    }
    console.log('    Old native options: ' + JSON.stringify(m.oldOptions));
    console.log('    V2 options: ' + JSON.stringify(m.v2Options));
  }
}
console.log();

console.log('=== MISSING DATA SCREENS (old native not in V2) ===');
for (const item of report.missing_screens) {
  console.log(item.screen);
  for (const f of item.dataFields) {
    let extra = '';
    if (f.options && f.options.length > 0) {
      extra = ' options=' + JSON.stringify(f.options);
    }
    console.log('    ' + f.id + ' (' + f.type + ')' + extra);
  }
}
console.log();

console.log('=== EXTRA FIELDS IN V2 (V2 has, old native does not) ===');
for (const item of report.extra_fields) {
  console.log('[' + item.section + '] ' + item.screen + ' - ' + item.title);
  for (const f of item.fields) {
    console.log('    EXTRA: ' + f.id + ' (' + f.type + ') - ' + (f.label || ''));
  }
}

// Save comprehensive report
fs.writeFileSync('E:/s/scriber/mobile-app/parity_audit_comprehensive.json', JSON.stringify(report, null, 2));
console.log();
console.log('Full report saved to parity_audit_comprehensive.json');
