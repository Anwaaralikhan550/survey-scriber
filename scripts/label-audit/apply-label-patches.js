/**
 * apply-label-patches.js
 *
 * Reads the label_diff.json and native XML layouts to precisely
 * insert missing label fields into the V2 inspection tree.
 *
 * Uses native field ID → V2 field position mapping for exact placement.
 */

const fs = require('fs');
const path = require('path');

const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');
const LAYOUT_DIR = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/layout');
const STRINGS_FILE = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml');
const DIFF_FILE = path.join(__dirname, 'label_diff.json');
const OUTPUT_TREE = TREE_FILE; // Overwrite in-place
const BACKUP_FILE = TREE_FILE + '.backup_pre_labels';
const LOG_FILE = path.join(__dirname, 'patch_log.json');

// ── String resources ────────────────────────────────────────────────

function loadStringResources() {
  const xml = fs.readFileSync(STRINGS_FILE, 'utf8');
  const map = {};
  const re = /<string\s+name="([^"]+)"[^>]*>([^<]*)<\/string>/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    map[m[1]] = m[2].trim();
  }
  return map;
}

// ── Parse native XML to get ordered [heading|field] sequence ────────

function parseNativeLayoutSequence(xmlContent, strings) {
  const sequence = [];

  // Extract ALL elements in document order: headings + fields
  // We need to interleave them by XML offset to get correct ordering

  // Heading TextViews
  const headingRegex = /<TextView\b([^>]*style="@style\/TextViewItem"[^>]*)(?:\/>|>[^<]*<\/TextView>)/gs;
  let m;
  while ((m = headingRegex.exec(xmlContent)) !== null) {
    const attrs = m[1];
    const textMatch = attrs.match(/android:text="([^"]+)"/);
    if (!textMatch) continue;
    let text = textMatch[1];
    if (text.startsWith('@string/')) {
      text = strings[text.replace('@string/', '')] || text;
    }
    if (text.startsWith('@') || text === '') continue;
    sequence.push({ kind: 'heading', text, offset: m.index });
  }

  // CheckBoxes
  const cbRegex = /<CheckBox\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = cbRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  // AutoCompleteTextView (dropdowns)
  const actvRegex = /<AutoCompleteTextView\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = actvRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  // EditText
  const etRegex = /<EditText\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = etRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  // Spinner
  const spRegex = /<Spinner\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = spRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  // Sort by XML position
  sequence.sort((a, b) => a.offset - b.offset);

  return sequence;
}

/**
 * Build heading → firstFieldIdAfter map from the native sequence.
 * Each heading maps to the first field element that appears after it.
 */
function buildHeadingFieldMap(sequence) {
  const map = []; // { headingText, firstFieldIdAfter }

  for (let i = 0; i < sequence.length; i++) {
    if (sequence[i].kind === 'heading') {
      // Find the next field after this heading
      let firstFieldId = null;
      for (let j = i + 1; j < sequence.length; j++) {
        if (sequence[j].kind === 'field') {
          firstFieldId = sequence[j].id;
          break;
        }
      }
      map.push({
        headingText: sequence[i].text,
        firstFieldIdAfter: firstFieldId,
      });
    }
  }

  return map;
}

// ── Headings to ignore (not section headings) ───────────────────────

const IGNORE_HEADINGS = new Set([
  'login here', 'forgot password?', 'new user? sign up', 'aboutus',
  'view_on_map', 'start inspection', 'pause inspection', 'reset inspection',
  'generate report', 'time:', 'arrive time:', 'depart time:', 'date:',
  'client name:', 'property type:', 'access type:', 'access:',
  'surveyor name:', 'purchase price:', 'country', 'name:', 'name',
  'address:', 'city:', 'phone no:', 'postcode:', 'pincode:', 'country:',
  'client notes:', 'special instruction:', 'agent details', 'agent notes:',
  'client note', 'special instruction', 'agent note', 'notes:',
  'e1_chimney', 'e2_roof_covering', 'e3_rain_water_goods', 'e4_main_walls',
  'e5_windows', 'e6_outside_doors', 'e7_conservatory_porches',
  'e8_other_joinery_finishes', 'e9_other',
  'roof_structure_main', 'ceilings_main', 'walls_and_partitions_main',
  'floors_main', 'fireplaces_and_chimneys_main', 'built_in_fittings_main',
  'woodwork_main', 'bathroom_fittings_main', 'other_main',
  'grounds_garage_b', 'other_b', 'grounds_other_area_b',
  'service_electricity_b', 'service_gas_and_oil_b', 'service_water_b',
  'service_heating_g', 'service_water_heating_g', 'service_drainage_b',
  'service_common_services_b', '123', '1994',
]);

// ── Track used label IDs to avoid duplicates ────────────────────────

function generateLabelId(text, usedIds) {
  const base = 'label_' + text.toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '_')
    .replace(/_+$/, '');

  if (!usedIds.has(base)) {
    usedIds.add(base);
    return base;
  }

  // Add numeric suffix
  for (let i = 2; i < 100; i++) {
    const candidate = `${base}_${i}`;
    if (!usedIds.has(candidate)) {
      usedIds.add(candidate);
      return candidate;
    }
  }

  return base + '_' + Date.now();
}

// ── Main ─────────────────────────────────────────────────────────────

function main() {
  console.log('Loading resources...');
  const strings = loadStringResources();
  const tree = JSON.parse(fs.readFileSync(TREE_FILE, 'utf8'));
  const diff = JSON.parse(fs.readFileSync(DIFF_FILE, 'utf8'));

  // Create backup
  console.log('Creating backup...');
  fs.writeFileSync(BACKUP_FILE, JSON.stringify(tree, null, 2));

  // Collect all existing label IDs to avoid collisions
  const usedIds = new Set();
  function collectIds(node) {
    if (node.fields) {
      for (const f of node.fields) {
        usedIds.add(f.id);
      }
    }
    const kids = node.children || node.nodes || [];
    for (const child of kids) {
      collectIds(child);
    }
  }
  for (const section of tree.sections) {
    for (const node of section.nodes || []) {
      collectIds(node);
    }
  }
  console.log(`  Existing field IDs: ${usedIds.size}`);

  // Build index of V2 screens for fast lookup
  const screenIndex = {}; // screenId → reference to the node's fields array
  function indexScreens(node) {
    if (node.type === 'screen' && node.fields) {
      screenIndex[node.id] = node;
    }
    const kids = node.children || node.nodes || [];
    for (const child of kids) {
      indexScreens(child);
    }
  }
  for (const section of tree.sections) {
    for (const node of section.nodes || []) {
      indexScreens(node);
    }
  }

  const patchLog = [];
  let totalInserted = 0;
  let screensPatched = 0;

  // Process each screen in the diff
  for (const item of diff.missingLabels) {
    const screenId = item.screenId;
    const nativeLayout = item.nativeLayout;
    const screenNode = screenIndex[screenId];

    if (!screenNode) {
      console.log(`  SKIP: V2 screen ${screenId} not found in tree`);
      continue;
    }

    // Read native XML
    const xmlPath = path.join(LAYOUT_DIR, nativeLayout + '.xml');
    if (!fs.existsSync(xmlPath)) {
      console.log(`  SKIP: Native layout ${nativeLayout}.xml not found`);
      continue;
    }

    const xmlContent = fs.readFileSync(xmlPath, 'utf8');
    const sequence = parseNativeLayoutSequence(xmlContent, strings);
    const headingFieldMap = buildHeadingFieldMap(sequence);

    // Get existing V2 labels for this screen
    const existingLabelTexts = new Set(
      screenNode.fields.filter(f => f.type === 'label').map(f => f.label.toLowerCase().trim())
    );

    // Determine which headings are truly missing
    const insertions = []; // { position, labelField }

    for (const hfm of headingFieldMap) {
      const headingText = hfm.headingText;
      const normalized = headingText.toLowerCase().trim();

      // Skip ignored headings
      if (IGNORE_HEADINGS.has(normalized)) continue;

      // Skip if already present
      if (existingLabelTexts.has(normalized)) continue;

      // Check partial match too
      const partialMatch = [...existingLabelTexts].some(l =>
        l.includes(normalized) || normalized.includes(l)
      );
      if (partialMatch) continue;

      // Find insert position: where is firstFieldIdAfter in V2?
      let insertPos = 0;
      if (hfm.firstFieldIdAfter) {
        const idx = screenNode.fields.findIndex(f => f.id === hfm.firstFieldIdAfter);
        if (idx >= 0) {
          insertPos = idx;
        } else {
          // Try partial ID match
          const partialIdx = screenNode.fields.findIndex(f =>
            f.id.includes(hfm.firstFieldIdAfter) ||
            hfm.firstFieldIdAfter.includes(f.id)
          );
          if (partialIdx >= 0) {
            insertPos = partialIdx;
          } else {
            // Fall back to estimated position based on heading order
            continue; // Skip if we can't determine position
          }
        }
      }

      const labelId = generateLabelId(headingText, usedIds);
      insertions.push({
        position: insertPos,
        labelField: {
          id: labelId,
          label: headingText,
          type: 'label',
        },
      });
    }

    if (insertions.length === 0) continue;

    // Sort insertions by position (descending) so we insert from back to front
    // This prevents position shifts from affecting subsequent insertions
    insertions.sort((a, b) => b.position - a.position);

    for (const ins of insertions) {
      screenNode.fields.splice(ins.position, 0, ins.labelField);
      totalInserted++;

      patchLog.push({
        screenId,
        screenTitle: screenNode.title,
        labelId: ins.labelField.id,
        labelText: ins.labelField.label,
        insertPosition: ins.position,
        nativeLayout,
      });
    }

    screensPatched++;
  }

  // Write patched tree
  console.log('\nWriting patched tree...');
  fs.writeFileSync(OUTPUT_TREE, JSON.stringify(tree, null, 2));
  fs.writeFileSync(LOG_FILE, JSON.stringify(patchLog, null, 2));

  // Count final stats
  let finalLabels = 0;
  let finalScreensWithLabels = 0;
  let finalTotalScreens = 0;
  function countLabels(node) {
    if (node.type === 'screen' && node.fields) {
      finalTotalScreens++;
      const labels = node.fields.filter(f => f.type === 'label');
      finalLabels += labels.length;
      if (labels.length > 0) finalScreensWithLabels++;
    }
    const kids = node.children || node.nodes || [];
    for (const child of kids) {
      countLabels(child);
    }
  }
  for (const section of tree.sections) {
    for (const node of section.nodes || []) {
      countLabels(node);
    }
  }

  console.log('\n=== PATCH RESULTS ===');
  console.log(`Screens patched: ${screensPatched}`);
  console.log(`Labels inserted: ${totalInserted}`);
  console.log(`\nBefore: 416 labels across 222/515 screens (43.1%)`);
  console.log(`After: ${finalLabels} labels across ${finalScreensWithLabels}/${finalTotalScreens} screens (${((finalScreensWithLabels/finalTotalScreens)*100).toFixed(1)}%)`);
  console.log(`\nBackup: ${BACKUP_FILE}`);
  console.log(`Patch log: ${LOG_FILE}`);
}

main();
