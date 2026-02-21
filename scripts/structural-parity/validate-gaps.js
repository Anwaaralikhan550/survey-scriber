/**
 * Validate Gaps: Deep cross-validation of each gap against native XML + Java
 *
 * For each verified gap:
 *  1. Read the native XML layout file
 *  2. Confirm the field element exists and is user-visible
 *  3. Determine the correct type, label, options, and conditionals
 *  4. Read the Java activity to get dropdown arrays and visibility logic
 *  5. Deduplicate (same ID appearing multiple times from extraction)
 *  6. Produce the final cleaned gap report
 */
const fs = require('fs');
const path = require('path');

const NATIVE_ROOT = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main');
const LAYOUT_DIR = path.join(NATIVE_ROOT, 'res/layout');
const ACTIVITY_DIR = path.join(NATIVE_ROOT, 'java/com/surveyscriber/android/activity');
const STRINGS_PATH = path.join(NATIVE_ROOT, 'res/values/strings.xml');
const FILTERED_PATH = path.join(__dirname, 'filtered-gaps.json');
const V2_TREE_PATH = path.resolve(__dirname, '../../assets/inspection_v2/inspection_v2_tree.json');
const OUTPUT_PATH = path.join(__dirname, 'cleaned-gap-report.json');
const OUTPUT_MD_PATH = path.join(__dirname, 'cleaned-gap-report.md');

// Parse strings.xml for string arrays
function parseStringArrays() {
  const content = fs.readFileSync(STRINGS_PATH, 'utf-8');
  const arrays = {};
  const regex = /<string-array name="([^"]+)">([\s\S]*?)<\/string-array>/g;
  let m;
  while ((m = regex.exec(content)) !== null) {
    const items = [];
    const itemRegex = /<item>([\s\S]*?)<\/item>/g;
    let im;
    while ((im = itemRegex.exec(m[2])) !== null) {
      items.push(im[1].trim());
    }
    arrays[m[1]] = items;
  }
  return arrays;
}

// Find Java activity file for a layout
function findJavaForLayout(layoutName) {
  // Read each Java file and check setContentView
  const javaFiles = fs.readdirSync(ACTIVITY_DIR).filter(f => f.endsWith('.java'));
  for (const jf of javaFiles) {
    try {
      const content = fs.readFileSync(path.join(ACTIVITY_DIR, jf), 'utf-8');
      if (content.includes('R.layout.' + layoutName)) {
        return { file: jf, content };
      }
    } catch (e) { /* skip */ }
  }
  return null;
}

// Extract field details from XML context
function extractFieldFromXml(xmlContent, fieldId) {
  const lines = xmlContent.split('\n');
  const idPattern = '@+id/' + fieldId + '"';

  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].includes(idPattern)) continue;

    // Found the field ID. Look backwards for the element tag
    let elementType = null;
    let elementStartLine = i;
    for (let j = i; j >= Math.max(0, i - 20); j--) {
      const tagMatch = lines[j].match(/<([\w.]+)/);
      if (tagMatch && !lines[j].includes('<!--')) {
        elementType = tagMatch[1].split('.').pop();
        elementStartLine = j;
        break;
      }
    }

    // Gather the full element context (from start tag to closing)
    let elementEndLine = i;
    for (let j = i; j < Math.min(lines.length, i + 15); j++) {
      if (lines[j].includes('/>') || lines[j].includes('</' + elementType)) {
        elementEndLine = j;
        break;
      }
    }

    const context = lines.slice(elementStartLine, elementEndLine + 1).join('\n');

    // Extract hint (label)
    let hint = '';
    // Check element itself
    const hintMatch = context.match(/android:hint="([^"]+)"/);
    if (hintMatch) {
      hint = hintMatch[1];
    } else {
      // Check enclosing TextInputLayout
      const enclosingContext = lines.slice(Math.max(0, elementStartLine - 15), elementStartLine + 1).join('\n');
      const enclosingHint = enclosingContext.match(/android:hint="([^"]+)"/);
      if (enclosingHint) hint = enclosingHint[1];
    }

    // Extract text (for checkboxes and TextViews)
    const textMatch = context.match(/android:text="([^"]+)"/);

    // Extract inputType
    const inputTypeMatch = context.match(/android:inputType="([^"]+)"/);

    // Extract visibility
    const visMatch = context.match(/android:visibility="([^"]+)"/);

    return {
      elementType,
      hint: hint || '',
      text: textMatch ? textMatch[1] : '',
      inputType: inputTypeMatch ? inputTypeMatch[1] : null,
      visibility: visMatch ? visMatch[1] : 'visible',
      xmlLine: i + 1,
      context: context.trim()
    };
  }

  return null;
}

// Get dropdown options from Java
function getDropdownOptionsFromJava(javaContent, fieldId, stringArrays) {
  // Find R.array references near the field ID usage
  const lines = javaContent.split('\n');

  // Find lines that reference this field
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].includes(fieldId)) continue;

    // Look for R.array references in surrounding context
    const contextWindow = lines.slice(Math.max(0, i - 30), Math.min(lines.length, i + 30)).join('\n');
    const arrayMatch = contextWindow.match(/R\.array\.(\w+)/);
    if (arrayMatch && stringArrays[arrayMatch[1]]) {
      return { arrayName: arrayMatch[1], options: stringArrays[arrayMatch[1]] };
    }
  }

  // Try a broader search: match variable name to field ID
  // Common pattern: spXxx = findViewById(R.id.fieldId); then adapter with R.array
  const findViewRegex = new RegExp('(\\w+)\\s*=.*?R\\.id\\.' + fieldId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  const varMatch = javaContent.match(findViewRegex);
  if (varMatch) {
    const varName = varMatch[1];
    // Find R.array near this variable's adapter setup
    const adapterPattern = new RegExp(varName + '.*?setAdapter|adapter.*?' + varName, 's');
    // Search for R.array near the variable
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes(varName) && lines[i].includes('setAdapter')) {
        const window = lines.slice(Math.max(0, i - 15), Math.min(lines.length, i + 5)).join('\n');
        const am = window.match(/R\.array\.(\w+)/);
        if (am && stringArrays[am[1]]) {
          return { arrayName: am[1], options: stringArrays[am[1]] };
        }
      }
    }
  }

  return null;
}

function main() {
  console.log('=== Deep Gap Validation ===\n');

  const filtered = JSON.parse(fs.readFileSync(FILTERED_PATH, 'utf-8'));
  const tree = JSON.parse(fs.readFileSync(V2_TREE_PATH, 'utf-8'));
  const stringArrays = parseStringArrays();

  // Build V2 screen lookup
  const v2Screens = {};
  for (const section of tree.sections) {
    for (const node of section.nodes) {
      if (node.type === 'screen') {
        v2Screens[node.id] = { ...node, sectionKey: section.key };
      }
    }
  }

  const gaps = filtered.verifiedGaps;
  console.log('Verified gaps to validate:', gaps.length);

  // Deduplicate: group by (screenId, fieldId)
  const uniqueGaps = {};
  for (const gap of gaps) {
    const key = gap.screenId + '|' + gap.fieldId;
    if (!uniqueGaps[key]) {
      uniqueGaps[key] = gap;
    }
  }
  console.log('Unique gaps after dedup:', Object.keys(uniqueGaps).length);

  // Validate each gap
  const validatedGaps = [];
  const dismissed = [];
  const javaCache = {}; // layoutName -> java content

  for (const [key, gap] of Object.entries(uniqueGaps)) {
    const layoutFile = path.join(LAYOUT_DIR, gap.screenId + '.xml');
    let xmlContent;
    try {
      xmlContent = fs.readFileSync(layoutFile, 'utf-8');
    } catch (e) {
      dismissed.push({ ...gap, dismissReason: 'no_layout_file' });
      continue;
    }

    // Extract field details from XML
    const fieldInfo = extractFieldFromXml(xmlContent, gap.fieldId);
    if (!fieldInfo) {
      dismissed.push({ ...gap, dismissReason: 'field_not_found_in_xml' });
      continue;
    }

    // Classify the element type to V2 field type
    let v2Type = null;
    let label = '';
    let options = null;

    switch (fieldInfo.elementType) {
      case 'AutoCompleteTextView':
      case 'MaterialBetterSpinner':
        v2Type = 'dropdown';
        label = fieldInfo.hint;
        // Get options from Java
        if (!javaCache[gap.screenId]) {
          const java = findJavaForLayout(gap.screenId);
          javaCache[gap.screenId] = java;
        }
        if (javaCache[gap.screenId]) {
          const optsInfo = getDropdownOptionsFromJava(javaCache[gap.screenId].content, gap.fieldId, stringArrays);
          if (optsInfo) {
            options = optsInfo.options;
          }
        }
        break;

      case 'EditText':
      case 'TextInputEditText':
        v2Type = fieldInfo.inputType === 'number' ? 'number' : 'text';
        label = fieldInfo.hint;
        break;

      case 'CheckBox':
        v2Type = 'checkbox';
        label = fieldInfo.text || fieldInfo.hint;
        break;

      case 'RadioButton':
        v2Type = 'checkbox'; // V2 uses checkbox for radio-like inputs
        label = fieldInfo.text || fieldInfo.hint;
        break;

      default:
        dismissed.push({ ...gap, dismissReason: 'unsupported_element: ' + fieldInfo.elementType });
        continue;
    }

    if (!label) label = gap.fieldLabel || '';

    // Check if this field already exists in V2 under a different ID
    const v2Screen = v2Screens[gap.screenId];
    if (v2Screen) {
      const existingByLabel = v2Screen.fields.find(f =>
        f.label === label && f.type === v2Type
      );
      if (existingByLabel && existingByLabel.id !== gap.fieldId) {
        // Field exists but under different ID - this is a naming mismatch, not a missing field
        dismissed.push({ ...gap, dismissReason: 'exists_under_different_id: ' + existingByLabel.id });
        continue;
      }

      // Double check: is this exact ID already in V2?
      const existsById = v2Screen.fields.find(f => f.id === gap.fieldId);
      if (existsById) {
        dismissed.push({ ...gap, dismissReason: 'already_exists_in_v2' });
        continue;
      }
    }

    // Determine insertion position - find native position and map to V2
    const nativeFieldOrder = [];
    // Re-extract all fields from XML to get order
    const allXmlFields = extractAllFieldIds(xmlContent);
    const nativePos = allXmlFields.indexOf(gap.fieldId);

    // Find the nearest previous field that exists in V2
    let insertAfterFieldId = null;
    if (v2Screen && nativePos >= 0) {
      for (let p = nativePos - 1; p >= 0; p--) {
        const prevId = allXmlFields[p];
        if (v2Screen.fields.some(f => f.id === prevId)) {
          insertAfterFieldId = prevId;
          break;
        }
      }
    }

    // Check conditional: if field is visibility="gone", look for conditional trigger
    let conditional = null;
    if (fieldInfo.visibility === 'gone') {
      conditional = { note: 'hidden_by_default' };
    }

    validatedGaps.push({
      section: gap.v2Section,
      screenId: gap.screenId,
      fieldId: gap.fieldId,
      type: 'missing_field',
      v2FieldType: v2Type,
      label: label,
      options: options,
      xmlLine: fieldInfo.xmlLine,
      elementType: fieldInfo.elementType,
      visibility: fieldInfo.visibility,
      insertAfterFieldId,
      conditional,
      nativeEvidence: gap.screenId + '.xml:' + fieldInfo.xmlLine,
      impact: `Field "${label}" (${v2Type}) missing from V2 screen. Users cannot enter this data.`
    });
  }

  console.log('\nValidated real gaps:', validatedGaps.length);
  console.log('Dismissed:', dismissed.length);

  // Show dismissal reasons
  const reasons = {};
  dismissed.forEach(d => {
    const r = d.dismissReason || 'unknown';
    reasons[r] = (reasons[r] || 0) + 1;
  });
  console.log('\nDismissal reasons:');
  Object.entries(reasons).sort((a, b) => b[1] - a[1]).forEach(([r, c]) => {
    console.log('  ' + r + ': ' + c);
  });

  // Group by section
  console.log('\n=== Validated Gaps by Section ===');
  const bySection = {};
  for (const gap of validatedGaps) {
    if (!bySection[gap.section]) bySection[gap.section] = [];
    bySection[gap.section].push(gap);
  }
  for (const [s, g] of Object.entries(bySection).sort()) {
    console.log(`  Section ${s}: ${g.length} gaps`);
  }

  // Generate markdown report
  const md = generateMarkdown(validatedGaps);
  fs.writeFileSync(OUTPUT_MD_PATH, md);

  // Save JSON
  const output = {
    meta: {
      timestamp: new Date().toISOString(),
      totalVerified: gaps.length,
      uniqueAfterDedup: Object.keys(uniqueGaps).length,
      validatedGaps: validatedGaps.length,
      dismissed: dismissed.length
    },
    gaps: validatedGaps,
    dismissed
  };
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(output, null, 2));

  console.log('\nOutput: ' + OUTPUT_PATH);
  console.log('Report: ' + OUTPUT_MD_PATH);
}

function extractAllFieldIds(xmlContent) {
  const ids = [];
  const regex = /android:id="@\+id\/([^"]+)"/g;
  let m;
  while ((m = regex.exec(xmlContent)) !== null) {
    // Filter out container IDs
    const id = m[1];
    if (/^(toolbar|tl_toolbar|toolbar_title|tv_reset|al_btnNext|btnSubmit)$/.test(id)) continue;
    ids.push(id);
  }
  return ids;
}

function generateMarkdown(gaps) {
  const lines = [];
  lines.push('# Cleaned Gap Report');
  lines.push('');
  lines.push(`Generated: ${new Date().toISOString()}`);
  lines.push('');
  lines.push(`**Total confirmed gaps: ${gaps.length}**`);
  lines.push('');

  // Summary table
  lines.push('## Summary by Section');
  lines.push('');
  lines.push('| Section | Gaps |');
  lines.push('|---------|------|');
  const bySection = {};
  gaps.forEach(g => {
    bySection[g.section] = (bySection[g.section] || 0) + 1;
  });
  for (const [s, c] of Object.entries(bySection).sort()) {
    lines.push(`| ${s} | ${c} |`);
  }
  lines.push('');

  // Summary by type
  lines.push('## Summary by Field Type');
  lines.push('');
  const byType = {};
  gaps.forEach(g => { byType[g.v2FieldType] = (byType[g.v2FieldType] || 0) + 1; });
  for (const [t, c] of Object.entries(byType).sort((a, b) => b[1] - a[1])) {
    lines.push(`- **${t}**: ${c}`);
  }
  lines.push('');

  // Detailed table
  lines.push('## Detailed Gap Report');
  lines.push('');
  lines.push('| # | Section | Screen ID | Field ID | Type | Label | Options | Evidence | Impact |');
  lines.push('|---|---------|-----------|----------|------|-------|---------|----------|--------|');

  let n = 1;
  for (const gap of gaps.sort((a, b) => {
    const s = a.section.localeCompare(b.section);
    return s !== 0 ? s : a.screenId.localeCompare(b.screenId);
  })) {
    const opts = gap.options ? gap.options.length + ' opts' : '-';
    lines.push(`| ${n++} | ${gap.section} | ${gap.screenId} | ${gap.fieldId} | ${gap.v2FieldType} | ${gap.label} | ${opts} | ${gap.nativeEvidence} | ${gap.impact} |`);
  }

  lines.push('');

  // Per-screen detail
  lines.push('## Per-Screen Detail');
  lines.push('');

  const byScreen = {};
  gaps.forEach(g => {
    if (!byScreen[g.screenId]) byScreen[g.screenId] = [];
    byScreen[g.screenId].push(g);
  });

  for (const [screenId, screenGaps] of Object.entries(byScreen).sort()) {
    lines.push(`### ${screenId}`);
    lines.push('');
    for (const gap of screenGaps) {
      lines.push(`- **${gap.fieldId}** (${gap.v2FieldType}): "${gap.label}"`);
      if (gap.options) {
        lines.push(`  - Options: ${JSON.stringify(gap.options)}`);
      }
      lines.push(`  - Insert after: \`${gap.insertAfterFieldId || 'beginning'}\``);
      lines.push(`  - Native: ${gap.nativeEvidence}`);
    }
    lines.push('');
  }

  return lines.join('\n');
}

main();
