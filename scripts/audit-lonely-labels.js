/**
 * AUDIT: Find screens with "lonely labels" — label fields that have
 * no interactive field (checkbox/dropdown/text/number) immediately after them.
 * These appear as empty headings with nothing to fill in.
 *
 * Also finds screens that are almost entirely labels.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

const interactiveTypes = new Set(['checkbox', 'dropdown', 'text', 'number']);

let totalLonelyLabels = 0;
let totalScreensAffected = 0;
const results = [];

for (const section of tree.sections) {
  if (!section.nodes) continue;
  for (const node of section.nodes) {
    if (node.type !== 'screen' || !node.fields || node.fields.length === 0) continue;

    const fields = node.fields;
    const totalFields = fields.length;
    const labels = fields.filter(f => f.type === 'label');
    const interactive = fields.filter(f => interactiveTypes.has(f.type));
    const lonelyLabels = [];

    // Find consecutive labels with no interactive field after them
    for (let i = 0; i < fields.length; i++) {
      if (fields[i].type !== 'label') continue;

      // Check if next non-label field exists before the next label
      let hasFollower = false;
      for (let j = i + 1; j < fields.length; j++) {
        if (fields[j].type === 'label') break; // another label before any interactive
        if (interactiveTypes.has(fields[j].type)) {
          // Check if this interactive field is conditional (might be hidden)
          if (!fields[j].conditionalOn) {
            hasFollower = true;
          }
          break;
        }
      }

      if (!hasFollower) {
        lonelyLabels.push(fields[i]);
      }
    }

    if (lonelyLabels.length > 0) {
      totalLonelyLabels += lonelyLabels.length;
      totalScreensAffected++;

      // Only report screens with 2+ lonely labels or where lonely labels
      // make up more than half the fields
      if (lonelyLabels.length >= 2 || lonelyLabels.length > interactive.length) {
        results.push({
          section: section.key,
          screen: node.id,
          title: node.title,
          inlinePosition: node.inlinePosition || null,
          totalFields,
          labelCount: labels.length,
          interactiveCount: interactive.length,
          lonelyLabelCount: lonelyLabels.length,
          lonelyLabels: lonelyLabels.map(l => l.label),
        });
      }
    }
  }
}

// Sort by lonely label count descending
results.sort((a, b) => b.lonelyLabelCount - a.lonelyLabelCount);

console.log(`\n=== LONELY LABELS AUDIT ===`);
console.log(`Total lonely labels: ${totalLonelyLabels}`);
console.log(`Screens affected: ${totalScreensAffected}`);
console.log(`Screens with 2+ lonely labels: ${results.length}\n`);

// Categorize
const headerScreens = results.filter(r => r.inlinePosition === 'header');
const normalScreens = results.filter(r => r.inlinePosition !== 'header');

console.log(`--- HEADER/SUMMARY SCREENS (${headerScreens.length}) ---`);
console.log(`These are summary screens meant for overview, labels expected.\n`);
for (const r of headerScreens) {
  console.log(`  [${r.section}] ${r.title} (${r.screen})`);
  console.log(`     Fields: ${r.totalFields} total, ${r.labelCount} labels, ${r.interactiveCount} interactive`);
  console.log(`     Lonely: ${r.lonelyLabelCount} → [${r.lonelyLabels.join(', ')}]`);
  console.log();
}

console.log(`\n--- NORMAL SCREENS WITH LONELY LABELS (${normalScreens.length}) ---\n`);
for (const r of normalScreens) {
  console.log(`  [${r.section}] ${r.title} (${r.screen})`);
  console.log(`     Fields: ${r.totalFields} total, ${r.labelCount} labels, ${r.interactiveCount} interactive`);
  console.log(`     Lonely: ${r.lonelyLabelCount} → [${r.lonelyLabels.join(', ')}]`);
  console.log();
}

// Save full results
fs.writeFileSync(
  path.join(__dirname, 'lonely-labels-audit.json'),
  JSON.stringify({ headerScreens, normalScreens, totalLonelyLabels, totalScreensAffected }, null, 2) + '\n',
  'utf8'
);
console.log(`Full results saved to scripts/lonely-labels-audit.json`);
