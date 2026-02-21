/**
 * Patch gap report: add resolved dropdown options and fix types
 * for fields where native Java doesn't populate arrays.
 */
const fs = require('fs');
const path = require('path');

const GAP_PATH = path.join(__dirname, 'cleaned-gap-report.json');
const report = JSON.parse(fs.readFileSync(GAP_PATH, 'utf-8'));

// Options found from strings.xml arrays
const OPTIONS_MAP = {
  'activity_construction_floor:android_material_design_spinner2': {
    options: ['Mainly of', 'Of a mixture of'],
    source: 'Floor_Construction_Built_Type'
  },
  'activity_property_construction:android_material_design_spinner': {
    options: ['House', 'Flat', 'Bungalow', 'Other'],
    source: 'Property_Type'
  },
  'activity_property_roof:android_material_design_spinner4': {
    options: ['Factory made trusses', 'Traditional cut timber construction', 'Other'],
    source: 'Roof_Construction_Built_With'
  },
  'activity_outside_property_windows_safety_glass_rating:actv_condition': {
    options: ['Noted', 'No SG Rating'],
    source: 'windows_safety_glass_rating_status'
  }
};

// Fields that are AutoCompleteTextView WITHOUT Java array binding
// These function as free-text inputs in native, should be "text" not "dropdown"
const CHANGE_TO_TEXT = [
  'activity_outside_property_conservatory_porch_not_inspected:actv_assumed_type',
  'activity_outside_property_other_joinery_finishes_not_inspected:actv_assumed_type',
  'activity_outside_property_other_not_inspected:actv_assumed_type',
  'activity_outside_property_rainwater_goods_main_screen:actv_assumed_type',
  'activity_inside_property_ceilings_heavy_paper_lining:actv_assumed_type',
  'activity_inside_property_ceilings_not_inspected:actv_assumed_type',
  'activity_inside_property_ceilings_polystyrene:actv_assumed_type',
  'activity_inside_property_other_not_inspected:actv_assumed_type',
  'activity_inside_property_wap_not_inspected:actv_assumed_type'
];

let optionsAdded = 0;
let typeChanged = 0;

for (const gap of report.gaps) {
  const key = `${gap.screenId}:${gap.fieldId}`;

  // Add options
  if (OPTIONS_MAP[key]) {
    gap.options = OPTIONS_MAP[key].options;
    console.log(`+ Options: ${gap.screenId}.${gap.fieldId} <- ${OPTIONS_MAP[key].source} (${gap.options.length} items)`);
    optionsAdded++;
  }

  // Change type from dropdown to text
  if (CHANGE_TO_TEXT.includes(key)) {
    console.log(`~ Type: ${gap.screenId}.${gap.fieldId}: dropdown -> text (no Java array binding)`);
    gap.v2FieldType = 'text';
    typeChanged++;
  }
}

fs.writeFileSync(GAP_PATH, JSON.stringify(report, null, 2));
console.log(`\nPatched: ${optionsAdded} options added, ${typeChanged} types changed`);
console.log(`Saved: ${GAP_PATH}`);
