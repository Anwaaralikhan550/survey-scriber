/**
 * Remove ALL duplicate dropdowns where checkboxes already cover the same options.
 * Also removes orphaned text fields that were conditional on the removed dropdowns.
 *
 * Found 15 duplicates across sections D, E, F, H.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

let totalRemoved = 0;

for (const section of tree.sections) {
  if (!section.nodes) continue;
  for (const node of section.nodes) {
    if (node.type !== 'screen' || !node.fields) continue;

    // Collect all checkbox labels (normalized)
    const cbLabels = new Set();
    for (const f of node.fields) {
      if (f.type === 'checkbox') {
        cbLabels.add(f.label.trim().toLowerCase());
      }
    }
    if (cbLabels.size === 0) continue;

    // Find duplicate dropdown IDs
    const dupDropdownIds = new Set();
    for (const f of node.fields) {
      if (f.type !== 'dropdown' || !f.options) continue;
      const matches = f.options.filter(opt =>
        cbLabels.has(opt.trim().toLowerCase())
      );
      if (matches.length >= 2 && matches.length >= f.options.length * 0.5) {
        dupDropdownIds.add(f.id);
      }
    }
    if (dupDropdownIds.size === 0) continue;

    // Remove duplicate dropdowns + any text fields conditional on them
    const before = node.fields.length;
    node.fields = node.fields.filter(f => {
      // Remove the duplicate dropdown itself
      if (dupDropdownIds.has(f.id)) {
        console.log(`  [${node.title}] REMOVE dropdown "${f.id}" (${f.label})`);
        return false;
      }
      // Remove text fields that are conditionalOn a removed dropdown
      if (f.conditionalOn && dupDropdownIds.has(f.conditionalOn)) {
        console.log(`  [${node.title}] REMOVE orphaned text "${f.id}" (conditional on ${f.conditionalOn})`);
        return false;
      }
      return true;
    });

    const removed = before - node.fields.length;
    if (removed > 0) {
      totalRemoved += removed;
      console.log(`  → ${node.title} (${node.id}): ${removed} fields removed\n`);
    }
  }
}

fs.writeFileSync(treePath, JSON.stringify(tree, null, 2) + '\n', 'utf8');
console.log(`\nDone: ${totalRemoved} total fields removed across the tree.`);
