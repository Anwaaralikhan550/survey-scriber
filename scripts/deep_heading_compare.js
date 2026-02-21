/**
 * PHASE 2: Deep Heading Comparison
 *
 * For each V2 screen, compare against native structure:
 * - Heading count
 * - Heading text (exact match)
 * - Heading position relative to surrounding fields
 * - Missing headings with exact insertion index
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const nativeStructurePath = path.join(__dirname, 'native-inspection-structure.json');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const nativeStructure = JSON.parse(fs.readFileSync(nativeStructurePath, 'utf8'));

// Build V2 screen map
const v2Screens = {};
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.type === 'screen' && node.fields && node.fields.length > 0) {
      v2Screens[node.id] = {
        section: section.key,
        title: node.title,
        fields: node.fields,
      };
    }
  }
}

/**
 * Normalize text for comparison.
 * Lowercase, trim, remove trailing colons/punctuation, collapse whitespace.
 */
function normalize(text) {
  return (text || '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .replace(/[:.,;!?]+$/, '')
    .trim();
}

/**
 * Check if two heading texts match.
 */
function textsMatch(nativeText, v2Label) {
  const a = normalize(nativeText);
  const b = normalize(v2Label);
  if (a === b) return true;
  // Fuzzy: one contains the other
  if (a.length > 3 && b.length > 3) {
    if (a.includes(b) || b.includes(a)) return true;
  }
  return false;
}

/**
 * Find the insertion index in V2 fields for a native heading.
 *
 * Strategy: Look at the native field that follows the heading.
 * Find that field ID in V2 fields. Insert the heading before it.
 * If no field follows, look at the field before the heading.
 */
function findInsertionIndex(nativeElements, headingIndex, v2Fields) {
  const v2FieldIds = v2Fields.map(f => f.id);

  // Look for the next field after this heading in native
  for (let i = headingIndex + 1; i < nativeElements.length; i++) {
    if (nativeElements[i].type === 'heading') break; // Stop at next heading
    if (nativeElements[i].type === 'field') {
      const nativeId = nativeElements[i].id;

      // Try exact match
      let idx = v2FieldIds.indexOf(nativeId);
      if (idx >= 0) return idx;

      // Try common transformations
      // actv_ -> various spinner prefixes in V2
      const alt1 = nativeId.replace(/^actv_/, 'android_material_design_spinner');
      idx = v2FieldIds.indexOf(alt1);
      if (idx >= 0) return idx;

      // Try partial match
      for (let k = 0; k < v2FieldIds.length; k++) {
        if (v2FieldIds[k] === nativeId ||
            (nativeId.length > 4 && v2FieldIds[k].includes(nativeId)) ||
            (v2FieldIds[k].length > 4 && nativeId.includes(v2FieldIds[k]))) {
          return k;
        }
      }
    }
  }

  // Fallback: look at the field BEFORE the heading
  for (let i = headingIndex - 1; i >= 0; i--) {
    if (nativeElements[i].type === 'field') {
      const nativeId = nativeElements[i].id;
      let idx = v2FieldIds.indexOf(nativeId);
      if (idx >= 0) return idx + 1; // Insert AFTER the preceding field

      const alt1 = nativeId.replace(/^actv_/, 'android_material_design_spinner');
      idx = v2FieldIds.indexOf(alt1);
      if (idx >= 0) return idx + 1;
    }
    if (nativeElements[i].type === 'heading') break;
  }

  return -1; // Could not determine position
}

const gaps = [];
let totalMissing = 0;
let totalExisting = 0;
let screensChecked = 0;

for (const [screenId, v2Data] of Object.entries(v2Screens)) {
  // Find matching native structure
  const native = nativeStructure[screenId];
  if (!native) continue;

  screensChecked++;

  const nativeHeadings = native.filter(e => e.type === 'heading');
  const v2Labels = v2Data.fields.filter(f => f.type === 'label');
  const v2LabelTexts = v2Labels.map(l => normalize(l.label));

  if (nativeHeadings.length === 0) continue;

  const screenGaps = [];

  for (let hi = 0; hi < nativeHeadings.length; hi++) {
    const nh = nativeHeadings[hi];
    const nhNorm = normalize(nh.text);

    // Check if this heading already exists in V2
    const found = v2LabelTexts.some(vl => textsMatch(nh.text, vl));

    if (found) {
      totalExisting++;
      continue;
    }

    // This heading is MISSING — find where to insert it
    const nativeIndex = native.indexOf(nh);
    const insertAt = findInsertionIndex(native, nativeIndex, v2Data.fields);

    screenGaps.push({
      headingText: nh.text,
      insertAtIndex: insertAt,
      nativeDomIndex: nativeIndex,
    });
    totalMissing++;
  }

  if (screenGaps.length > 0) {
    gaps.push({
      screenId,
      section: v2Data.section,
      title: v2Data.title,
      nativeHeadingCount: nativeHeadings.length,
      v2LabelCount: v2Labels.length,
      missingCount: screenGaps.length,
      missingHeadings: screenGaps,
    });
  }
}

// Sort by section then screenId
gaps.sort((a, b) => a.section.localeCompare(b.section) || a.screenId.localeCompare(b.screenId));

console.log(`\n=== HEADING GAP REPORT ===`);
console.log(`Screens checked: ${screensChecked}`);
console.log(`Headings already present: ${totalExisting}`);
console.log(`Headings MISSING: ${totalMissing}`);
console.log(`Screens with gaps: ${gaps.length}`);

console.log(`\n--- Per-screen detail ---\n`);
for (const g of gaps) {
  console.log(`[${g.section}] ${g.screenId} "${g.title}"`);
  console.log(`  Native headings: ${g.nativeHeadingCount} | V2 labels: ${g.v2LabelCount} | Missing: ${g.missingCount}`);
  for (const m of g.missingHeadings) {
    const posInfo = m.insertAtIndex >= 0 ? `insert at index ${m.insertAtIndex}` : 'position UNKNOWN';
    console.log(`  -> "${m.headingText}" (${posInfo})`);
  }
  console.log('');
}

const outputPath = path.join(__dirname, 'inspection-heading-gap-report.json');
fs.writeFileSync(outputPath, JSON.stringify(gaps, null, 2));
console.log(`Gap report saved to ${outputPath}`);
