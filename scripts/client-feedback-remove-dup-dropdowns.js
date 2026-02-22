/**
 * Remove duplicate dropdowns where checkboxes already cover the same options.
 *
 * 1. Chimney Partial View: remove actv_not_inspected_reason dropdown
 *    (duplicates cb_Partial_view, cb_Not_applicable, cb_Removed_chimney_stack, cb_Removed_pots)
 *
 * 2. External Wall: remove 3 dropdowns + 3 orphaned text fields
 *    - android_material_design_spinner6 (Wall Types)   → duplicates ch1-ch6
 *    - etWallTypesOther                                → orphaned Other for dropdown
 *    - android_material_design_spinner3 (Finishes)     → duplicates ch7-ch10
 *    - android_material_design_spinner5 (Cladding Fin) → duplicates ch11-ch18
 *    - etFinishesOther                                 → orphaned Other
 *    - etCladdingFingerOther                           → orphaned Other
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

const removals = {
  // Chimney Partial View
  activity_outside_property_chimney_partial_view: [
    'actv_not_inspected_reason',
  ],
  // External Wall
  activity_extended_wall: [
    'android_material_design_spinner6',  // Wall Types dropdown
    'etWallTypesOther',                  // orphaned text
    'android_material_design_spinner3',  // Finishes dropdown
    'android_material_design_spinner5',  // Cladding Finishes dropdown
    'etFinishesOther',                   // orphaned text
    'etCladdingFingerOther',             // orphaned text
  ],
};

let totalRemoved = 0;

for (const section of tree.sections) {
  if (!section.nodes) continue;
  for (const node of section.nodes) {
    const toRemove = removals[node.id];
    if (!toRemove) continue;

    const before = node.fields.length;
    node.fields = node.fields.filter(f => {
      if (toRemove.includes(f.id)) {
        console.log(`  [${node.id}] REMOVED field "${f.id}" (${f.type}: "${f.label}")`);
        return false;
      }
      return true;
    });
    const removed = before - node.fields.length;
    totalRemoved += removed;
    console.log(`${node.title}: ${removed} fields removed (${node.fields.length} remaining)`);
  }
}

fs.writeFileSync(treePath, JSON.stringify(tree, null, 2) + '\n', 'utf8');
console.log(`\nDone: ${totalRemoved} duplicate fields removed.`);
