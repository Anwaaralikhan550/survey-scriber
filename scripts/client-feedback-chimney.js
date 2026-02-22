/**
 * Chimney section reordering:
 * 1. Move "Not Inspected" to first position (order 0)
 * 2. Chimney group stays second (order 1)
 * 3. Repairs group stays third (order 4)
 * 4. Move Condition Rating main screen out of group_chimney_6 → direct child of group_e1_chimney_5, order 99 (last)
 * 5. Add "Not inspected" as first option in Condition Rating dropdown
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

let changes = 0;

for (const section of tree.sections) {
  if (!section.nodes) continue;
  for (const node of section.nodes) {
    // 1. Move "Not Inspected" to order 0
    if (node.id === 'activity_outside_property_chimney_not_inspected') {
      console.log(`Not Inspected: order ${node.order} → 0`);
      node.order = 0;
      changes++;
    }

    // 2. Move chimney main screen (condition rating) to group_e1_chimney_5 with order 99
    if (node.id === 'activity_outside_property_chimney_main_screen') {
      console.log(`Chimney Main Screen: parentId ${node.parentId} → group_e1_chimney_5, order ${node.order} → 99`);
      node.parentId = 'group_e1_chimney_5';
      node.order = 99;
      changes++;

      // 3. Add "Not inspected" as first option in condition rating dropdown
      if (node.fields) {
        for (const field of node.fields) {
          if (field.id === 'android_material_design_spinner4' && field.type === 'dropdown') {
            if (!field.options.includes('Not inspected')) {
              field.options.unshift('Not inspected');
              console.log(`Condition Rating dropdown: added "Not inspected" as first option → [${field.options.join(', ')}]`);
              changes++;
            }
          }
        }
      }
    }
  }
}

fs.writeFileSync(treePath, JSON.stringify(tree, null, 2) + '\n', 'utf8');
console.log(`\nDone: ${changes} changes applied.`);
