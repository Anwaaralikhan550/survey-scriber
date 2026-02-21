/**
 * Apply Manual Gaps: Insert the 67 confirmed missing fields into V2 tree
 *
 * For each confirmed gap:
 *   1. Resolve @string/ references to actual text
 *   2. Get dropdown options from strings.xml
 *   3. Determine correct insertion position
 *   4. Insert the field into the V2 tree
 *
 * Creates backup before modifying.
 */
const fs = require('fs');
const path = require('path');

const NATIVE_ROOT = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main');
const STRINGS_PATH = path.join(NATIVE_ROOT, 'res/values/strings.xml');
const ACTIVITY_DIR = path.join(NATIVE_ROOT, 'java/com/surveyscriber/android/activity');
const LAYOUT_DIR = path.join(NATIVE_ROOT, 'res/layout');
const V2_TREE_PATH = path.resolve(__dirname, '../../assets/inspection_v2/inspection_v2_tree.json');
const BACKUP_PATH = V2_TREE_PATH.replace('.json', '.manual_gap_backup');
const GAP_REPORT_PATH = path.join(__dirname, 'cleaned-gap-report.json');
const APPLY_LOG_PATH = path.join(__dirname, 'manual-gap-apply-log.json');

const DRY_RUN = process.argv.includes('--dry-run');

// Parse strings.xml
function parseStrings() {
  const content = fs.readFileSync(STRINGS_PATH, 'utf-8');
  const strings = {};
  const arrays = {};

  const stringRegex = /<string name="([^"]+)">([\s\S]*?)<\/string>/g;
  let m;
  while ((m = stringRegex.exec(content)) !== null) {
    strings[m[1]] = m[2].trim();
  }

  const arrayRegex = /<string-array name="([^"]+)">([\s\S]*?)<\/string-array>/g;
  while ((m = arrayRegex.exec(content)) !== null) {
    const items = [];
    const itemRegex = /<item>([\s\S]*?)<\/item>/g;
    let im;
    while ((im = itemRegex.exec(m[2])) !== null) items.push(im[1].trim());
    arrays[m[1]] = items;
  }

  return { strings, arrays };
}

function resolveString(value, strings) {
  if (value && value.startsWith('@string/')) {
    const key = value.replace('@string/', '');
    return strings[key] || value;
  }
  return value;
}

// Get dropdown options from Java activity for a specific field
function getOptionsForField(screenId, fieldId, strings, arrays) {
  // First try: find Java file for this layout
  const javaFiles = fs.readdirSync(ACTIVITY_DIR).filter(f => f.endsWith('.java'));
  for (const jf of javaFiles) {
    try {
      const content = fs.readFileSync(path.join(ACTIVITY_DIR, jf), 'utf-8');
      if (!content.includes('R.layout.' + screenId)) continue;

      // Find the variable bound to this field ID
      const bindRegex = new RegExp('(\\w+)\\s*=.*?R\\.id\\.' + fieldId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
      const bindMatch = content.match(bindRegex);
      if (!bindMatch) continue;
      const varName = bindMatch[1];

      // Find R.array reference near this variable
      const lines = content.split('\n');
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes(varName)) {
          // Look for R.array in surrounding lines
          const window = lines.slice(Math.max(0, i - 10), Math.min(lines.length, i + 10)).join('\n');
          const arrayMatch = window.match(/R\.array\.(\w+)/);
          if (arrayMatch && arrays[arrayMatch[1]]) {
            return arrays[arrayMatch[1]];
          }
        }
      }

      // Broader search: find all R.array references and match by proximity to field
      const allArrayRefs = [];
      for (let i = 0; i < lines.length; i++) {
        const am = lines[i].match(/R\.array\.(\w+)/);
        if (am) allArrayRefs.push({ line: i, name: am[1] });
      }

      // Find the line where this field's variable is used with setAdapter
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes(varName) && lines[i].includes('setAdapter')) {
          // Find nearest R.array before this line
          for (let j = allArrayRefs.length - 1; j >= 0; j--) {
            if (allArrayRefs[j].line < i && arrays[allArrayRefs[j].name]) {
              return arrays[allArrayRefs[j].name];
            }
          }
        }
      }

      break; // Found the Java file but couldn't find options
    } catch (e) { /* skip */ }
  }

  return null;
}

// Get field details from native XML
function getFieldDetailsFromXml(screenId, fieldId) {
  const layoutPath = path.join(LAYOUT_DIR, screenId + '.xml');
  try {
    const xml = fs.readFileSync(layoutPath, 'utf-8');
    const lines = xml.split('\n');

    for (let i = 0; i < lines.length; i++) {
      if (!lines[i].includes('@+id/' + fieldId + '"')) continue;

      // Look backwards for element tag
      let elementType = null;
      for (let j = i; j >= Math.max(0, i - 20); j--) {
        const tm = lines[j].match(/<([\w.]+)/);
        if (tm && !lines[j].includes('<!--')) {
          elementType = tm[1].split('.').pop();
          break;
        }
      }

      // Get context
      const context = lines.slice(Math.max(0, i - 15), Math.min(lines.length, i + 5)).join('\n');

      // Get hint
      let hint = '';
      const hintMatch = context.match(/android:hint="([^"]+)"/);
      if (hintMatch) hint = hintMatch[1];

      // Get text (for checkboxes)
      const textMatch = context.match(/android:text="([^"]+)"/);

      // Get visibility
      const visMatch = context.match(/android:visibility="([^"]+)"/);

      // Get inputType
      const inputMatch = context.match(/android:inputType="([^"]+)"/);

      return {
        elementType,
        hint,
        text: textMatch ? textMatch[1] : '',
        visibility: visMatch ? visMatch[1] : 'visible',
        inputType: inputMatch ? inputMatch[1] : null,
        line: i + 1
      };
    }
  } catch (e) { /* file not found */ }
  return null;
}

function main() {
  console.log(`=== Apply Manual Gaps ${DRY_RUN ? '(DRY RUN)' : ''} ===\n`);

  const gapReport = JSON.parse(fs.readFileSync(GAP_REPORT_PATH, 'utf-8'));
  const tree = JSON.parse(fs.readFileSync(V2_TREE_PATH, 'utf-8'));
  const { strings, arrays } = parseStrings();

  const gaps = gapReport.gaps;
  console.log('Gaps to apply:', gaps.length);

  // Build screen lookup
  const screenLookup = {};
  for (let si = 0; si < tree.sections.length; si++) {
    const section = tree.sections[si];
    for (let ni = 0; ni < section.nodes.length; ni++) {
      const node = section.nodes[ni];
      if (node.type === 'screen') {
        screenLookup[node.id] = { sectionIdx: si, nodeIdx: ni, screen: node };
      }
    }
  }

  const applyLog = [];
  let applied = 0;
  let skipped = 0;

  for (const gap of gaps) {
    const loc = screenLookup[gap.screenId];
    if (!loc) {
      console.log(`  SKIP: Screen '${gap.screenId}' not found in V2 tree`);
      skipped++;
      continue;
    }

    const screen = loc.screen;

    // Check if field already exists
    if (screen.fields.some(f => f.id === gap.fieldId)) {
      console.log(`  SKIP: Field '${gap.fieldId}' already exists in '${gap.screenId}'`);
      skipped++;
      continue;
    }

    // Resolve label
    let label = resolveString(gap.label, strings);
    if (!label || label.startsWith('@string/')) {
      // Try to get from XML directly
      const xmlDetails = getFieldDetailsFromXml(gap.screenId, gap.fieldId);
      if (xmlDetails) {
        label = resolveString(xmlDetails.hint || xmlDetails.text, strings);
      }
    }
    if (!label) label = gap.fieldId; // Fallback

    // Build the field object
    const newField = {
      id: gap.fieldId,
      label: label,
      type: gap.v2FieldType
    };

    // Get dropdown options
    if (gap.v2FieldType === 'dropdown') {
      let options = gap.options;
      if (!options || options.length === 0) {
        options = getOptionsForField(gap.screenId, gap.fieldId, strings, arrays);
      }
      if (options && options.length > 0) {
        newField.options = options;
      }
    }

    // Determine visibility/conditional
    if (gap.visibility === 'gone' || (gap.conditional && gap.conditional.note === 'hidden_by_default')) {
      // This field is hidden by default - check for conditional trigger
      const xmlDetails = getFieldDetailsFromXml(gap.screenId, gap.fieldId);
      if (xmlDetails && xmlDetails.visibility === 'gone') {
        // Look for a nearby checkbox/dropdown that controls this
        // Common pattern: cb_other -> et_other (checkbox toggles text field)
        if (gap.fieldId.startsWith('et_other') || gap.fieldId.startsWith('etGroundTypeOther') ||
            gap.fieldId.startsWith('etFrontTypeOther') || gap.fieldId.startsWith('etFrontFencingOther') ||
            gap.fieldId.startsWith('etRearTypeOther') || gap.fieldId.startsWith('etRearFencingOther') ||
            gap.fieldId.startsWith('etCommunalTypeOther') || gap.fieldId.startsWith('etCommunalFencingOther') ||
            gap.fieldId.startsWith('etAreaOther') || gap.fieldId.startsWith('etPartitionTypesOther')) {
          // Find the controlling dropdown - look for the nearest dropdown/checkbox before this field
          const controllerIdx = screen.fields.findIndex(f =>
            (f.type === 'dropdown' || f.type === 'checkbox') &&
            f.options && f.options.includes('Other')
          );
          if (controllerIdx >= 0) {
            const controller = screen.fields[controllerIdx];
            if (controller.type === 'dropdown') {
              newField.conditionalOn = controller.id;
              newField.conditionalValue = 'Other';
              newField.conditionalMode = 'show';
            }
          }
        }
      }
    }

    // Determine insertion position
    let insertIdx = screen.fields.length; // Default: append
    if (gap.insertAfterFieldId) {
      const afterIdx = screen.fields.findIndex(f => f.id === gap.insertAfterFieldId);
      if (afterIdx >= 0) {
        insertIdx = afterIdx + 1;
      }
    }

    // Insert the field
    screen.fields.splice(insertIdx, 0, newField);

    applyLog.push({
      screenId: gap.screenId,
      section: gap.section,
      fieldId: gap.fieldId,
      type: gap.v2FieldType,
      label: label,
      options: newField.options || null,
      insertedAt: insertIdx,
      conditional: newField.conditionalOn ? {
        on: newField.conditionalOn,
        value: newField.conditionalValue,
        mode: newField.conditionalMode
      } : null,
      nativeEvidence: gap.nativeEvidence
    });

    applied++;
  }

  console.log(`\nApplied: ${applied}`);
  console.log(`Skipped: ${skipped}`);

  // Summary by section
  const bySection = {};
  applyLog.forEach(l => { bySection[l.section] = (bySection[l.section] || 0) + 1; });
  console.log('\nBy section:');
  Object.entries(bySection).sort().forEach(([s, c]) => console.log(`  ${s}: ${c}`));

  // Summary by type
  const byType = {};
  applyLog.forEach(l => { byType[l.type] = (byType[l.type] || 0) + 1; });
  console.log('\nBy type:');
  Object.entries(byType).forEach(([t, c]) => console.log(`  ${t}: ${c}`));

  // Save log
  fs.writeFileSync(APPLY_LOG_PATH, JSON.stringify(applyLog, null, 2));
  console.log(`\nApply log: ${APPLY_LOG_PATH}`);

  if (!DRY_RUN) {
    // Create backup
    fs.copyFileSync(V2_TREE_PATH, BACKUP_PATH);
    console.log(`Backup: ${BACKUP_PATH}`);

    // Write patched tree
    fs.writeFileSync(V2_TREE_PATH, JSON.stringify(tree, null, 2));
    console.log(`Patched: ${V2_TREE_PATH}`);
  } else {
    console.log('\n(Dry run - no files modified)');
  }

  // Show fields with no options that should have them
  const missingOptions = applyLog.filter(l => l.type === 'dropdown' && !l.options);
  if (missingOptions.length > 0) {
    console.log(`\nWARNING: ${missingOptions.length} dropdown fields have no options:`);
    missingOptions.forEach(l => console.log(`  ${l.screenId}.${l.fieldId} (${l.label})`));
  }
}

main();
