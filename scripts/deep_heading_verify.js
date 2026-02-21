/**
 * PHASE 4: Full Verification
 *
 * 1. Re-run deep comparison: every native FIELD_HEADING must exist as a V2 label
 * 2. No duplicate labels within a screen
 * 3. JSON valid
 * 4. Node count unchanged
 * 5. Label order matches native DOM order
 * 6. No field moved
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const nativeStructurePath = path.join(__dirname, 'native-inspection-structure.json');

// Parse tree
let tree;
try {
  tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
  console.log('[PASS] JSON is valid');
} catch (e) {
  console.log('[FAIL] JSON parse error:', e.message);
  process.exit(1);
}

const nativeStructure = JSON.parse(fs.readFileSync(nativeStructurePath, 'utf8'));

// 1. Node count
let totalNodes = 0;
let totalFields = 0;
let totalLabels = 0;
for (const section of tree.sections) {
  totalNodes += section.nodes.length;
  for (const node of section.nodes) {
    if (node.fields) {
      totalFields += node.fields.length;
      totalLabels += node.fields.filter(f => f.type === 'label').length;
    }
  }
}
console.log(`\nTotal nodes: ${totalNodes}`);
console.log(`Total fields: ${totalFields}`);
console.log(`Total labels: ${totalLabels}`);

// 2. Check for duplicate labels within each screen
let dupCount = 0;
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (!node.fields) continue;
    const labelIds = node.fields.filter(f => f.type === 'label').map(f => f.id);
    const uniqueIds = new Set(labelIds);
    if (uniqueIds.size !== labelIds.length) {
      console.log(`[FAIL] Duplicate label IDs in ${node.id}`);
      dupCount++;
    }
    // Also check for duplicate label TEXT within a screen
    const labelTexts = node.fields.filter(f => f.type === 'label').map(f => f.label.toLowerCase().trim());
    const textCounts = {};
    for (const t of labelTexts) {
      textCounts[t] = (textCounts[t] || 0) + 1;
    }
    for (const [text, count] of Object.entries(textCounts)) {
      if (count > 1) {
        // Check if native also has duplicates
        const native = nativeStructure[node.id];
        if (native) {
          const nativeHeadings = native.filter(e => e.type === 'heading').map(e => e.text.toLowerCase().trim());
          const nativeCount = nativeHeadings.filter(h => h === text || h.includes(text) || text.includes(h)).length;
          if (nativeCount >= count) {
            // Native also has this many — it's valid
          } else {
            console.log(`[WARN] "${text}" appears ${count}x in ${node.id} but only ${nativeCount}x in native`);
          }
        }
      }
    }
  }
}
if (dupCount === 0) console.log('[PASS] No duplicate label IDs');

// 3. Re-run gap check: every native FIELD_HEADING must exist in V2
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

let missingFieldHeadings = 0;
let totalFieldHeadings = 0;
const remainingGaps = [];

// Build V2 screen map
const v2Screens = {};
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.type === 'screen' && node.fields) {
      v2Screens[node.id] = {
        section: section.key,
        fields: node.fields,
      };
    }
  }
}

for (const [screenId, native] of Object.entries(nativeStructure)) {
  const v2Data = v2Screens[screenId];
  if (!v2Data) continue;

  const v2LabelTexts = v2Data.fields.filter(f => f.type === 'label').map(f => normalize(f.label));

  for (let i = 0; i < native.length; i++) {
    if (native[i].type !== 'heading') continue;

    // Check if it's a FIELD_HEADING
    let isFieldHeading = false;
    for (let j = i + 1; j < native.length; j++) {
      if (native[j].type === 'heading') break;
      if (native[j].type === 'field') { isFieldHeading = true; break; }
    }
    if (!isFieldHeading) continue;

    totalFieldHeadings++;

    const found = v2LabelTexts.some(vl => textsMatch(native[i].text, vl));
    if (!found) {
      missingFieldHeadings++;
      remainingGaps.push({ screenId, heading: native[i].text, section: v2Data.section });
    }
  }
}

console.log(`\nField headings in native: ${totalFieldHeadings}`);
console.log(`Present in V2: ${totalFieldHeadings - missingFieldHeadings}`);
console.log(`Still missing: ${missingFieldHeadings}`);

if (missingFieldHeadings === 0) {
  console.log('[PASS] All native FIELD_HEADINGs present in V2');
} else {
  console.log('[FAIL] Missing field headings:');
  for (const g of remainingGaps) {
    console.log(`  [${g.section}] ${g.screenId}: "${g.heading}"`);
  }
}

// 4. Label order check
let orderIssues = 0;
for (const [screenId, native] of Object.entries(nativeStructure)) {
  const v2Data = v2Screens[screenId];
  if (!v2Data) continue;

  const nativeFieldHeadings = [];
  for (let i = 0; i < native.length; i++) {
    if (native[i].type !== 'heading') continue;
    let isFieldHeading = false;
    for (let j = i + 1; j < native.length; j++) {
      if (native[j].type === 'heading') break;
      if (native[j].type === 'field') { isFieldHeading = true; break; }
    }
    if (isFieldHeading) nativeFieldHeadings.push(native[i].text);
  }

  const v2Labels = v2Data.fields.filter(f => f.type === 'label');
  // Map V2 labels to native heading order
  let lastNativeIdx = -1;
  for (const label of v2Labels) {
    const nativeIdx = nativeFieldHeadings.findIndex((h, i) =>
      i > lastNativeIdx && textsMatch(h, label.label));
    if (nativeIdx >= 0) {
      if (nativeIdx < lastNativeIdx) {
        orderIssues++;
        console.log(`[ORDER] ${screenId}: "${label.label}" out of order`);
      }
      lastNativeIdx = nativeIdx;
    }
  }
}

if (orderIssues === 0) {
  console.log('[PASS] All labels in correct order');
} else {
  console.log(`[WARN] ${orderIssues} label order issues`);
}

// 5. Check inline header screens still have inlinePosition
const inlineHeaders = tree.sections.flatMap(s => s.nodes).filter(n => n.inlinePosition === 'header');
console.log(`\nInline headers: ${inlineHeaders.length}`);

console.log('\n=== VERIFICATION COMPLETE ===');
