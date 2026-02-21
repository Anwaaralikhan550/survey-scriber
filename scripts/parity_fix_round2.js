const fs = require('fs');

const treePath = 'E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json';
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

const patchLog = [];
function log(action, screen, detail) {
  patchLog.push({ action, screen, detail });
  console.log(`[${action}] ${screen}: ${detail}`);
}

function findScreen(sectionKey, screenId) {
  const section = tree.sections.find(s => s.key === sectionKey);
  if (!section) return null;
  return section.nodes.find(n => n.id === screenId && n.type === 'screen');
}

function addFields(sectionKey, screenId, newFields) {
  const screen = findScreen(sectionKey, screenId);
  if (!screen) { log('ERROR', screenId, 'Not found in ' + sectionKey); return; }
  if (!screen.fields) screen.fields = [];
  const existingIds = new Set(screen.fields.map(f => f.id));
  for (const field of newFields) {
    if (existingIds.has(field.id)) continue;
    screen.fields.push(field);
    log('ADD_FIELD', screenId, `Added ${field.type} field: ${field.id} (${field.label})`);
  }
}

function replaceField(sectionKey, screenId, fieldId, newField) {
  const screen = findScreen(sectionKey, screenId);
  if (!screen) { log('ERROR', screenId, 'Not found in ' + sectionKey); return; }
  const idx = screen.fields.findIndex(f => f.id === fieldId);
  if (idx === -1) {
    screen.fields.push(newField);
    log('ADD_FIELD', screenId, `Added ${newField.type} field: ${newField.id} (${newField.label})`);
  } else {
    screen.fields[idx] = newField;
    log('REPLACE_FIELD', screenId, `Replaced ${fieldId} with ${newField.type}: ${newField.id} (${newField.label})`);
  }
}

// ==========================================
// ROUND 2 CORRECTIONS
// ==========================================

// 1. Garden screens - add missing dropdowns for fencing/pond/sheds condition
const gardenDropdowns = [
  { id: 'actv_fencing_condition', label: 'Fencing condition', type: 'dropdown', options: ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'] },
  { id: 'actv_pond_condition', label: 'Pond condition', type: 'dropdown', options: ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'] },
  { id: 'actv_brick_sheds_condition', label: 'Brick sheds condition', type: 'dropdown', options: ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'] },
  { id: 'actv_timber_sheds_condition', label: 'Timber sheds condition', type: 'dropdown', options: ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'] },
];

for (const gardenId of [
  'activity_grounds_other_communal_garden',
  'activity_grounds_other_other_garden',
  'activity_grounds_other_rear_garden',
  'activity_grounds_other_side_garden',
]) {
  addFields('H', gardenId, gardenDropdowns);
}

// 2. Drainage Chamber Lids - add missing actv_defect dropdown
addFields('G', 'activity_services_drainage_chamber_lids', [
  { id: 'actv_defect', label: 'Defect', type: 'dropdown', options: ['Damaged', 'Missing', 'Corroded', 'Other'] },
]);

// 3. Rocking Handrails - should be dropdown (actv_status), not checkbox
// Replace the checkbox with a dropdown
replaceField('F', 'activity_in_side_property_wood_work_rocking_handrails', 'cb_rocking_handrails', {
  id: 'actv_status',
  label: 'Status',
  type: 'dropdown',
  options: ['None', 'Rocking handrails present'],
});

// 4. Roof covering main screen - add missing dropdowns from old native
addFields('E', 'activity_outside_property_roof_covering_main_screen', [
  { id: 'android_material_design_spinner4', label: 'Condition Rating', type: 'dropdown', options: ['1', '2', '3'] },
  { id: 'actv_assumed_type', label: 'Assumed Type', type: 'dropdown', options: ['Pitched', 'Flat', 'Mansard', 'Other'] },
]);

// Save
fs.writeFileSync(treePath, JSON.stringify(tree, null, 2));
console.log('\n=== ROUND 2 PATCH COMPLETE ===');
console.log('Patches:', patchLog.length);
console.log('Errors:', patchLog.filter(p => p.action === 'ERROR').length);

fs.writeFileSync('E:/s/scriber/mobile-app/parity_patch_log_round2.json', JSON.stringify(patchLog, null, 2));
