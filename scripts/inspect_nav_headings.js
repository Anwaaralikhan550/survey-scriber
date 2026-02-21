/**
 * Inspect the native structure for the 52 remaining "missing" headings
 * to understand why they're classified as NAV_HEADINGs vs FIELD_HEADINGs.
 */
const fs = require('fs');
const ns = JSON.parse(fs.readFileSync('scripts/native-inspection-structure.json', 'utf8'));

const screens = [
  'activity_outside_property_chimney_main_screen',
  'activity_in_side_property_fire_places_diffrent',
  'activity_in_side_property_floors',
  'activity_inside_property_fireplaces_main_screen',
  'activity_services_gas_oil_main_screen',
  'activity_services_gas_oil',
  'activity_grounds_other_main_screen',
];

for (const s of screens) {
  const d = ns[s];
  if (!d) { console.log(s + ': NOT FOUND in native structure'); continue; }
  console.log('\n=== ' + s + ' ===');
  for (let i = 0; i < d.length; i++) {
    const e = d[i];
    const marker = e.type === 'heading' ? 'H' : 'F';

    // For headings, check if next element is heading or field
    let classification = '';
    if (e.type === 'heading') {
      let hasFieldAfter = false;
      for (let j = i + 1; j < d.length; j++) {
        if (d[j].type === 'heading') break;
        if (d[j].type === 'field') { hasFieldAfter = true; break; }
      }
      classification = hasFieldAfter ? ' [FIELD_HEADING]' : ' [NAV_HEADING]';
    }

    console.log('  [' + i + '] ' + marker + ': ' + (e.text || e.id) + classification);
  }
}
