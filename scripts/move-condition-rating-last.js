/**
 * Move Condition Rating label + dropdown to the END of each screen's fields array.
 *
 * Pattern: Each affected screen has:
 *   - label_condition_rating_* (label)
 *   - android_material_design_spinner4 with label "Condition Rating" (dropdown)
 *
 * These two fields should be the last fields in the screen.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

let movedCount = 0;

for (const section of tree.sections) {
  if (!section.nodes) continue;
  for (const node of section.nodes) {
    if (node.type !== 'screen' || !node.fields || node.fields.length === 0) continue;

    // Find condition rating dropdown
    const crDropdownIdx = node.fields.findIndex(
      f => f.id === 'android_material_design_spinner4' && f.label === 'Condition Rating'
    );
    if (crDropdownIdx === -1) continue;

    // Find condition rating label (immediately before the dropdown typically)
    const crLabelIdx = node.fields.findIndex(
      f => f.type === 'label' && f.id.startsWith('label_condition_rating')
    );

    // Check if already last (or second-to-last with label)
    const lastIdx = node.fields.length - 1;
    const secondLastIdx = node.fields.length - 2;
    if (crLabelIdx === -1 && crDropdownIdx === lastIdx) continue;
    if (crLabelIdx !== -1 && crDropdownIdx === lastIdx && crLabelIdx === secondLastIdx) continue;

    // Extract the CR fields
    const crFields = [];
    // Remove in reverse order to preserve indices
    const indicesToRemove = [];
    if (crLabelIdx !== -1) indicesToRemove.push(crLabelIdx);
    indicesToRemove.push(crDropdownIdx);
    indicesToRemove.sort((a, b) => b - a); // descending

    for (const idx of indicesToRemove) {
      crFields.unshift(node.fields.splice(idx, 1)[0]);
    }

    // Append at the end
    node.fields.push(...crFields);
    movedCount++;

    console.log(`  [${section.key}] ${node.title} (${node.id}) — moved CR to end`);
  }
}

console.log(`\nTotal screens reordered: ${movedCount}`);

fs.writeFileSync(treePath, JSON.stringify(tree, null, 2) + '\n', 'utf8');
console.log('Tree saved.');
