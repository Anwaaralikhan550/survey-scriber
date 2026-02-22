/**
 * AUDIT: Find ALL screens where a dropdown has options that overlap
 * with checkboxes on the same screen (duplicate controls).
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

const results = [];

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

    // Check each dropdown
    for (const f of node.fields) {
      if (f.type !== 'dropdown' || !f.options) continue;

      // Count how many dropdown options match a checkbox label
      const matches = f.options.filter(opt =>
        cbLabels.has(opt.trim().toLowerCase())
      );

      // If more than half the options match checkboxes, it's a duplicate
      if (matches.length >= 2 && matches.length >= f.options.length * 0.5) {
        results.push({
          screen: node.id,
          screenTitle: node.title,
          section: section.key,
          dropdownId: f.id,
          dropdownLabel: f.label,
          dropdownOptions: f.options,
          matchingCbLabels: matches,
          matchRatio: `${matches.length}/${f.options.length}`,
        });
      }
    }
  }
}

console.log(`\n=== DUPLICATE DROPDOWN+CHECKBOX AUDIT ===`);
console.log(`Found ${results.length} duplicate dropdowns across the tree:\n`);

for (const r of results) {
  console.log(`Section ${r.section} | ${r.screenTitle} (${r.screen})`);
  console.log(`  Dropdown: "${r.dropdownId}" label="${r.dropdownLabel}"`);
  console.log(`  Options: [${r.dropdownOptions.join(', ')}]`);
  console.log(`  Matches checkboxes: ${r.matchRatio} → [${r.matchingCbLabels.join(', ')}]`);
  console.log();
}

// Output as JSON for the fix script
fs.writeFileSync(
  path.join(__dirname, 'dup-dropdown-audit.json'),
  JSON.stringify(results, null, 2) + '\n',
  'utf8'
);
console.log(`Full results saved to scripts/dup-dropdown-audit.json`);
