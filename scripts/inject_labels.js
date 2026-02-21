/**
 * Inject missing label fields into V2 tree based on native XML headings.
 *
 * Strategy: Parse native XML to find TextViewItem headings and the input field
 * IDs that follow them, then insert label fields at the matching position in V2.
 *
 * Focuses on HIGH priority screens (5+ data fields, 0 existing labels).
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const layoutDir = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/layout';
const stringsPath = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml';
const auditPath = path.join(__dirname, 'audit_missing_labels_results.json');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const auditResults = JSON.parse(fs.readFileSync(auditPath, 'utf8'));

// Load strings.xml
const stringsContent = fs.readFileSync(stringsPath, 'utf8');
const stringMap = {};
const stringRegex = /<string name="([^"]+)">([^<]*)<\/string>/g;
let match;
while ((match = stringRegex.exec(stringsContent)) !== null) {
  stringMap[match[1]] = match[2];
}

// Build a fast lookup: screenId -> section index + node index
const screenIndex = {};
for (let si = 0; si < tree.sections.length; si++) {
  for (let ni = 0; ni < tree.sections[si].nodes.length; ni++) {
    const node = tree.sections[si].nodes[ni];
    if (node.type === 'screen') {
      screenIndex[node.id] = { si, ni };
    }
  }
}

/**
 * Parse a native XML file and extract the ordered sequence of:
 * - TextViewItem headings (with their text)
 * - Input field IDs (spinner, edittext, checkbox)
 *
 * Returns array of { type: 'heading'|'field', text?, id? }
 */
function parseNativeLayout(xmlPath) {
  if (!fs.existsSync(xmlPath)) return null;
  const content = fs.readFileSync(xmlPath, 'utf8');
  const elements = [];

  // Find all relevant elements in DOM order using regex
  // We need to capture TextViewItem headings and input fields
  const elementRegex = /<(TextView|Spinner|EditText|CheckBox|com\.google\.android\.material\.textfield\.TextInputLayout)[\s\S]*?(?:\/>|<\/\1>|<\/com\.google\.android\.material\.textfield\.TextInputLayout>)/g;

  let elemMatch;
  while ((elemMatch = elementRegex.exec(content)) !== null) {
    const block = elemMatch[0];
    const tagName = elemMatch[1];

    if (tagName === 'TextView' && block.includes('TextViewItem')) {
      // Skip if inside a RelativeLayout with chevron (navigation item, not heading)
      // Check context: look backwards for unclosed RelativeLayout
      const before = content.substring(Math.max(0, elemMatch.index - 200), elemMatch.index);
      if (before.includes('<RelativeLayout') && !before.includes('</RelativeLayout>')) {
        continue;
      }

      // Skip if visibility="gone"
      if (block.includes('android:visibility="gone"')) continue;

      // Also check if parent LinearLayout has visibility="gone"
      const beforeLong = content.substring(Math.max(0, elemMatch.index - 500), elemMatch.index);
      const lastLL = beforeLong.lastIndexOf('<LinearLayout');
      if (lastLL >= 0) {
        const llBlock = beforeLong.substring(lastLL);
        if (llBlock.includes('android:visibility="gone"') && !beforeLong.substring(lastLL).includes('</LinearLayout>')) {
          continue;
        }
      }

      const textMatch = block.match(/android:text="([^"]+)"/);
      if (!textMatch) continue;

      let text = textMatch[1];
      if (text.startsWith('@string/')) {
        const key = text.replace('@string/', '');
        text = stringMap[key] || key;
      }

      // Skip empty/generic
      if (!text || text === 'Dashboard' || text.trim() === '') continue;

      elements.push({ type: 'heading', text: text.trim() });
    } else if (tagName === 'Spinner' || tagName === 'com.google.android.material.textfield.TextInputLayout') {
      const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      if (idMatch) {
        // Skip if visibility="gone"
        if (block.includes('android:visibility="gone"')) continue;
        elements.push({ type: 'field', id: idMatch[1] });
      }
    } else if (tagName === 'EditText') {
      const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      if (idMatch) {
        if (block.includes('android:visibility="gone"')) continue;
        elements.push({ type: 'field', id: idMatch[1] });
      }
    } else if (tagName === 'CheckBox') {
      const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      if (idMatch) {
        if (block.includes('android:visibility="gone"')) continue;
        elements.push({ type: 'field', id: idMatch[1] });
      }
    }
  }

  return elements;
}

/**
 * Given a parsed element sequence and V2 fields array, determine where to
 * insert each heading in the V2 fields array.
 *
 * Returns array of { labelText, insertBeforeIndex }
 */
function computeInsertions(nativeElements, v2Fields) {
  const insertions = [];
  const v2FieldIds = v2Fields.map(f => f.id);

  for (let i = 0; i < nativeElements.length; i++) {
    if (nativeElements[i].type !== 'heading') continue;

    const labelText = nativeElements[i].text;

    // Find the next field in the native sequence after this heading
    let nextFieldId = null;
    for (let j = i + 1; j < nativeElements.length; j++) {
      if (nativeElements[j].type === 'field') {
        nextFieldId = nativeElements[j].id;
        break;
      }
    }

    if (!nextFieldId) {
      // Heading at the end with no following field — skip or append
      continue;
    }

    // Find this field in V2
    // Try exact match first, then common transformations
    let v2Index = v2FieldIds.indexOf(nextFieldId);

    if (v2Index === -1) {
      // Try with common ID mappings
      // actv_ prefix -> android_material_design_spinner
      // et_ prefix -> various
      // cb_ prefix -> cb_
      const altId = nextFieldId.replace(/^actv_/, 'android_material_design_spinner');
      v2Index = v2FieldIds.indexOf(altId);
    }

    if (v2Index === -1) {
      // Try partial match — find the field whose ID contains or starts with the native ID
      for (let k = 0; k < v2FieldIds.length; k++) {
        if (v2FieldIds[k].includes(nextFieldId) || nextFieldId.includes(v2FieldIds[k])) {
          v2Index = k;
          break;
        }
      }
    }

    if (v2Index === -1) {
      // Try matching by the field after nextField in native sequence
      for (let j = i + 2; j < nativeElements.length; j++) {
        if (nativeElements[j].type === 'field') {
          const altFieldId = nativeElements[j].id;
          v2Index = v2FieldIds.indexOf(altFieldId);
          if (v2Index === -1) {
            const altId2 = altFieldId.replace(/^actv_/, 'android_material_design_spinner');
            v2Index = v2FieldIds.indexOf(altId2);
          }
          if (v2Index >= 0) break;
        }
        if (nativeElements[j].type === 'heading') break; // stop at next heading
      }
    }

    if (v2Index >= 0) {
      // Check if there's already a label at this position
      if (v2Index > 0 && v2Fields[v2Index - 1].type === 'label') {
        continue; // Already has a label
      }
      insertions.push({ labelText, insertBeforeIndex: v2Index });
    }
  }

  return insertions;
}

function makeLabelId(text, existingIds) {
  let baseId = 'label_' + text.toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');

  let id = baseId;
  let suffix = 2;
  while (existingIds.has(id)) {
    id = baseId + '_' + suffix;
    suffix++;
  }
  existingIds.add(id);
  return id;
}

// Process HIGH priority screens only
const highPriority = auditResults.filter(g => g.priority === 'HIGH');
let totalInserted = 0;
let screensModified = 0;
const usedIds = new Set();

// Collect all existing label IDs to avoid conflicts
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.fields) {
      for (const field of node.fields) {
        if (field.type === 'label') usedIds.add(field.id);
      }
    }
  }
}

for (const gap of highPriority) {
  const loc = screenIndex[gap.screenId];
  if (!loc) {
    console.log(`SKIP: ${gap.screenId} not found in tree`);
    continue;
  }

  const node = tree.sections[loc.si].nodes[loc.ni];
  const xmlPath = path.join(layoutDir, gap.screenId + '.xml');

  // Parse the native layout
  const nativeElements = parseNativeLayout(xmlPath);
  if (!nativeElements || nativeElements.length === 0) {
    console.log(`SKIP: No native layout or no elements for ${gap.screenId}`);
    continue;
  }

  // Compute insertion points
  const insertions = computeInsertions(nativeElements, node.fields);

  if (insertions.length === 0) {
    // Fallback: insert labels at position 0 for the first missing label
    if (gap.missingLabels.length > 0 && node.fields.length > 0 && node.fields[0].type !== 'label') {
      const labelId = makeLabelId(gap.missingLabels[0], usedIds);
      node.fields.splice(0, 0, {
        id: labelId,
        label: gap.missingLabels[0],
        type: 'label',
      });
      totalInserted++;
      screensModified++;
      console.log(`FALLBACK: ${gap.screenId} +1 label at top: "${gap.missingLabels[0]}"`);
    } else {
      console.log(`SKIP: No insertion points found for ${gap.screenId}`);
    }
    continue;
  }

  // Insert labels in reverse order to preserve indices
  const sorted = [...insertions].sort((a, b) => b.insertBeforeIndex - a.insertBeforeIndex);
  let count = 0;
  for (const ins of sorted) {
    const labelId = makeLabelId(ins.labelText, usedIds);
    node.fields.splice(ins.insertBeforeIndex, 0, {
      id: labelId,
      label: ins.labelText,
      type: 'label',
    });
    count++;
  }

  if (count > 0) {
    totalInserted += count;
    screensModified++;
    console.log(`FIXED: ${gap.screenId} +${count} labels: ${insertions.map(i => '"' + i.labelText + '"').join(', ')}`);
  }
}

console.log(`\nTotal labels inserted: ${totalInserted}`);
console.log(`Screens modified: ${screensModified}`);

// Save
fs.writeFileSync(treePath, JSON.stringify(tree, null, 2));
console.log(`Tree saved to ${treePath}`);
