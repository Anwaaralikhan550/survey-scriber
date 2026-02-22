/**
 * AUDIT: Find ALL screens in the VALUATION tree where a dropdown has
 * options that overlap with checkboxes on the same screen.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_valuation', 'valuation_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

let totalFound = 0;

for (const section of tree.sections) {
  if (!section.nodes) continue;
  for (const node of section.nodes) {
    if (node.type !== 'screen' || !node.fields) continue;

    const cbLabels = new Set();
    for (const f of node.fields) {
      if (f.type === 'checkbox') {
        cbLabels.add(f.label.trim().toLowerCase());
      }
    }
    if (cbLabels.size === 0) continue;

    for (const f of node.fields) {
      if (f.type !== 'dropdown' || !f.options) continue;
      const matches = f.options.filter(opt =>
        cbLabels.has(opt.trim().toLowerCase())
      );
      if (matches.length >= 2 && matches.length >= f.options.length * 0.5) {
        totalFound++;
        console.log(`Section ${section.key} | ${node.title} (${node.id})`);
        console.log(`  Dropdown: "${f.id}" label="${f.label}"`);
        console.log(`  Options: [${f.options.join(', ')}]`);
        console.log(`  Matches checkboxes: ${matches.length}/${f.options.length} → [${matches.join(', ')}]`);
        console.log();
      }
    }
  }
}

if (totalFound === 0) {
  console.log('CLEAN: No duplicate dropdown+checkbox pairs found in valuation tree.');
} else {
  console.log(`Found ${totalFound} duplicate dropdowns in valuation tree.`);
}
