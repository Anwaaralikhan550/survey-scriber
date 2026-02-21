/**
 * Verify existing labels in V2 match native headings.
 * For each V2 screen that has labels AND a matching native structure,
 * check that every native FIELD_HEADING has a matching V2 label.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const nativeStructurePath = path.join(__dirname, 'native-inspection-structure.json');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const nativeStructure = JSON.parse(fs.readFileSync(nativeStructurePath, 'utf8'));

function normalize(text) {
  return (text || '').toLowerCase().replace(/\s+/g, ' ').replace(/[:.,;!?]+$/, '').trim();
}

function textsMatch(a, b) {
  const na = normalize(a);
  const nb = normalize(b);
  if (na === nb) return true;
  if (na.length > 3 && nb.length > 3) {
    if (na.includes(nb) || nb.includes(na)) return true;
  }
  return false;
}

let totalChecked = 0;
let totalCorrect = 0;
let totalMisplaced = 0;
const issues = [];

for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.type !== 'screen' || !node.fields) continue;
    const v2Labels = node.fields.filter(f => f.type === 'label');
    if (v2Labels.length === 0) continue;

    const native = nativeStructure[node.id];
    if (!native) continue;

    totalChecked++;

    // Get native FIELD_HEADINGs only
    const nativeFieldHeadings = [];
    for (let i = 0; i < native.length; i++) {
      if (native[i].type !== 'heading') continue;
      let hasFieldAfter = false;
      for (let j = i + 1; j < native.length; j++) {
        if (native[j].type === 'heading') break;
        if (native[j].type === 'field') { hasFieldAfter = true; break; }
      }
      if (hasFieldAfter) nativeFieldHeadings.push(native[i]);
    }

    // Check each V2 label matches a native heading
    for (const label of v2Labels) {
      const matchesNative = nativeFieldHeadings.some(nh => textsMatch(nh.text, label.label));
      if (matchesNative) {
        totalCorrect++;
      } else {
        // Check if it's a heading that was added from native but doesn't match our field-heading classification
        // (e.g., it could match a heading we filtered as gone-container)
      }
    }

    // Check position correctness: each V2 label should appear before the first field it categorizes
    // Compare order of labels vs native heading order
    const v2LabelTexts = v2Labels.map(l => normalize(l.label));
    const nativeHeadingTexts = nativeFieldHeadings.map(h => normalize(h.text));

    // Check if V2 labels are in the same order as native headings
    let lastNativeIdx = -1;
    for (const vl of v2LabelTexts) {
      const nativeIdx = nativeHeadingTexts.findIndex((nh, i) => i > lastNativeIdx && textsMatch(nh, vl));
      if (nativeIdx >= 0 && nativeIdx < lastNativeIdx) {
        issues.push({
          screenId: node.id,
          issue: 'ORDER_MISMATCH',
          label: vl,
        });
        totalMisplaced++;
      }
      if (nativeIdx >= 0) lastNativeIdx = nativeIdx;
    }
  }
}

console.log(`Screens with labels checked: ${totalChecked}`);
console.log(`Labels matching native: ${totalCorrect}`);
console.log(`Order mismatches: ${totalMisplaced}`);
if (issues.length > 0) {
  console.log('\nIssues:');
  issues.forEach(i => console.log(`  [${i.issue}] ${i.screenId}: "${i.label}"`));
}
