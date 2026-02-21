/**
 * Audit missing labels: Compare native headings against V2 tree label fields
 *
 * For each screen in the V2 tree that has a matching native layout:
 * - Check which native headings are present as label fields
 * - Report missing labels and their insertion positions
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const nativeHeadingsPath = path.join(__dirname, 'native_headings.json');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const nativeHeadings = JSON.parse(fs.readFileSync(nativeHeadingsPath, 'utf8'));

// Build a map of all V2 screen nodes with their fields
const v2Screens = {};
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.type === 'screen' && node.fields && node.fields.length > 0) {
      v2Screens[node.id] = {
        section: section.key,
        title: node.title,
        fields: node.fields,
        labels: node.fields.filter(f => f.type === 'label').map(f => f.label),
        dataFieldCount: node.fields.filter(f => f.type !== 'label').length,
      };
    }
  }
}

// Focus on sections E, F, G, H
const targetSections = ['E', 'F', 'G', 'H'];

const gaps = [];
let totalMissing = 0;

for (const [screenId, screenData] of Object.entries(v2Screens)) {
  if (!targetSections.includes(screenData.section)) continue;

  // Find matching native layout
  const nativeKey = screenId;
  const nativeLabels = nativeHeadings[nativeKey];

  if (!nativeLabels || nativeLabels.length === 0) continue;

  // Check which native headings are missing in V2
  const existingLabels = screenData.labels.map(l => l.toLowerCase().trim());
  const missingLabels = nativeLabels.filter(nl => {
    const nlLower = nl.toLowerCase().trim();
    // Check exact match or close match (ignore trailing colons, trailing spaces)
    const nlClean = nlLower.replace(/:$/, '').trim();
    return !existingLabels.some(el => {
      const elClean = el.replace(/:$/, '').trim();
      return elClean === nlClean || elClean.includes(nlClean) || nlClean.includes(elClean);
    });
  });

  if (missingLabels.length > 0) {
    gaps.push({
      screenId,
      section: screenData.section,
      title: screenData.title,
      dataFieldCount: screenData.dataFieldCount,
      existingLabels: screenData.labels,
      nativeLabels,
      missingLabels,
      priority: screenData.dataFieldCount >= 5 && screenData.labels.length === 0 ? 'HIGH' : 'NORMAL',
    });
    totalMissing += missingLabels.length;
  }
}

// Sort by priority then section
gaps.sort((a, b) => {
  if (a.priority === 'HIGH' && b.priority !== 'HIGH') return -1;
  if (b.priority === 'HIGH' && a.priority !== 'HIGH') return 1;
  return a.section.localeCompare(b.section) || a.screenId.localeCompare(b.screenId);
});

console.log(`\nScreens with missing labels: ${gaps.length}`);
console.log(`Total missing labels: ${totalMissing}`);
console.log(`\nHIGH priority (5+ data fields, 0 existing labels): ${gaps.filter(g => g.priority === 'HIGH').length}\n`);

for (const gap of gaps) {
  console.log(`[${gap.priority}] [${gap.section}] ${gap.screenId} "${gap.title}"`);
  console.log(`  Data fields: ${gap.dataFieldCount}, Existing labels: ${gap.existingLabels.length}`);
  console.log(`  Missing: ${JSON.stringify(gap.missingLabels)}`);
  console.log('');
}

const outputPath = path.join(__dirname, 'audit_missing_labels_results.json');
fs.writeFileSync(outputPath, JSON.stringify(gaps, null, 2));
console.log(`Results saved to ${outputPath}`);
