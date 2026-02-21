/**
 * PHASE 3: Safe Heading Insertion
 *
 * Inserts ONLY genuine FIELD_HEADINGs (headings that have fields following them
 * in native DOM order). Skips NAV_HEADINGs (already represented as group tiles).
 *
 * For each missing FIELD_HEADING:
 * 1. Finds the native field ID that follows the heading
 * 2. Locates that field in V2 fields array
 * 3. Inserts the label at the correct position
 * 4. Uses snake_case label_ ID with dedup suffix
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const nativeStructurePath = path.join(__dirname, 'native-inspection-structure.json');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const nativeStructure = JSON.parse(fs.readFileSync(nativeStructurePath, 'utf8'));

// Build V2 screen index
const screenIndex = {};
for (let si = 0; si < tree.sections.length; si++) {
  for (let ni = 0; ni < tree.sections[si].nodes.length; ni++) {
    const node = tree.sections[si].nodes[ni];
    if (node.type === 'screen') {
      screenIndex[node.id] = { si, ni };
    }
  }
}

// Collect all existing label IDs globally
const globalLabelIds = new Set();
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.fields) {
      for (const field of node.fields) {
        if (field.type === 'label') globalLabelIds.add(field.id);
      }
    }
  }
}

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

function makeLabelId(text) {
  let baseId = 'label_' + text.toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');

  let id = baseId;
  let suffix = 2;
  while (globalLabelIds.has(id)) {
    id = baseId + '_' + suffix;
    suffix++;
  }
  globalLabelIds.add(id);
  return id;
}

/**
 * Find the insertion index in V2 fields for a heading based on the native
 * field ID that follows it in DOM order.
 */
function findInsertIndex(nativeElements, headingIdx, v2Fields) {
  const v2FieldIds = v2Fields.map(f => f.id);

  // Look forward for the first field after this heading
  for (let i = headingIdx + 1; i < nativeElements.length; i++) {
    if (nativeElements[i].type === 'heading') break;
    if (nativeElements[i].type === 'field') {
      const nativeId = nativeElements[i].id;

      // Try exact match
      let idx = v2FieldIds.indexOf(nativeId);
      if (idx >= 0) return idx;

      // Try actv_ -> android_material_design_spinner
      const alt1 = nativeId.replace(/^actv_/, 'android_material_design_spinner');
      idx = v2FieldIds.indexOf(alt1);
      if (idx >= 0) return idx;

      // Try partial match
      for (let k = 0; k < v2FieldIds.length; k++) {
        const v2id = v2FieldIds[k];
        if (v2id === nativeId) return k;
        if (nativeId.length > 4 && v2id.includes(nativeId)) return k;
        if (v2id.length > 4 && nativeId.includes(v2id)) return k;
      }

      // Try next field in native (maybe this one was renamed)
      continue;
    }
  }

  // Fallback: look at field BEFORE heading
  for (let i = headingIdx - 1; i >= 0; i--) {
    if (nativeElements[i].type === 'field') {
      const nativeId = nativeElements[i].id;
      let idx = v2FieldIds.indexOf(nativeId);
      if (idx >= 0) return idx + 1;

      const alt1 = nativeId.replace(/^actv_/, 'android_material_design_spinner');
      idx = v2FieldIds.indexOf(alt1);
      if (idx >= 0) return idx + 1;
    }
    if (nativeElements[i].type === 'heading') break;
  }

  // Last resort: if this is the first heading and no field match, try index 0
  if (headingIdx === 0 || (headingIdx > 0 && nativeElements.slice(0, headingIdx).every(e => e.type === 'heading'))) {
    return 0;
  }

  return -1;
}

let totalInserted = 0;
let totalSkippedNav = 0;
let totalSkippedExisting = 0;
let totalSkippedNoPosition = 0;
let screensPatched = 0;

const patchLog = [];

for (const [screenId, native] of Object.entries(nativeStructure)) {
  const loc = screenIndex[screenId];
  if (!loc) continue;

  const node = tree.sections[loc.si].nodes[loc.ni];
  if (!node.fields || node.fields.length === 0) continue;

  const v2LabelTexts = node.fields.filter(f => f.type === 'label').map(f => normalize(f.label));

  // Identify FIELD_HEADINGs (headings with fields following)
  const insertions = [];

  for (let i = 0; i < native.length; i++) {
    if (native[i].type !== 'heading') continue;

    const headingText = native[i].text;

    // Check if it's a FIELD_HEADING (has fields following before next heading)
    let isFieldHeading = false;
    for (let j = i + 1; j < native.length; j++) {
      if (native[j].type === 'heading') break;
      if (native[j].type === 'field') { isFieldHeading = true; break; }
    }

    if (!isFieldHeading) {
      totalSkippedNav++;
      continue;
    }

    // Check if this heading already exists in V2
    const alreadyExists = v2LabelTexts.some(vl => textsMatch(headingText, vl));
    if (alreadyExists) {
      totalSkippedExisting++;
      continue;
    }

    // Find insertion position
    const insertAt = findInsertIndex(native, i, node.fields);
    if (insertAt < 0) {
      totalSkippedNoPosition++;
      patchLog.push({
        screenId,
        action: 'SKIP_NO_POSITION',
        heading: headingText,
      });
      continue;
    }

    // Check if there's already a label at this position
    if (insertAt < node.fields.length && node.fields[insertAt].type === 'label') {
      // There's already a label here - check if it matches
      if (textsMatch(node.fields[insertAt].label, headingText)) {
        totalSkippedExisting++;
        continue;
      }
    }

    insertions.push({
      headingText,
      insertAt,
      nativeDomIndex: i,
    });
  }

  if (insertions.length === 0) continue;

  // Sort by insertAt descending to preserve indices during insertion
  insertions.sort((a, b) => b.insertAt - a.insertAt);

  for (const ins of insertions) {
    const labelId = makeLabelId(ins.headingText);
    node.fields.splice(ins.insertAt, 0, {
      id: labelId,
      label: ins.headingText,
      type: 'label',
    });
    totalInserted++;
    patchLog.push({
      screenId,
      action: 'INSERTED',
      heading: ins.headingText,
      atIndex: ins.insertAt,
      labelId,
    });
  }

  screensPatched++;
}

console.log(`\n=== PATCH RESULTS ===`);
console.log(`Labels inserted: ${totalInserted}`);
console.log(`Screens patched: ${screensPatched}`);
console.log(`Skipped (nav heading): ${totalSkippedNav}`);
console.log(`Skipped (already exists): ${totalSkippedExisting}`);
console.log(`Skipped (no position): ${totalSkippedNoPosition}`);

console.log(`\n--- Insertions ---`);
for (const log of patchLog.filter(l => l.action === 'INSERTED')) {
  console.log(`  [${log.screenId}] "${log.heading}" at index ${log.atIndex} (id: ${log.labelId})`);
}

if (patchLog.some(l => l.action === 'SKIP_NO_POSITION')) {
  console.log(`\n--- Skipped (no position) ---`);
  for (const log of patchLog.filter(l => l.action === 'SKIP_NO_POSITION')) {
    console.log(`  [${log.screenId}] "${log.heading}"`);
  }
}

// Save
fs.writeFileSync(treePath, JSON.stringify(tree, null, 2));
console.log(`\nTree saved to ${treePath}`);

// Save patch log
const logPath = path.join(__dirname, 'deep_heading_patch_log.json');
fs.writeFileSync(logPath, JSON.stringify(patchLog, null, 2));
console.log(`Patch log saved to ${logPath}`);
