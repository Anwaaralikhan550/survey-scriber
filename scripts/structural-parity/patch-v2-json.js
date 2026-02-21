/**
 * Patch V2 JSON: Auto-fix unambiguous structural discrepancies
 *
 * Reads the discrepancy report and applies safe, auto-fixable patches
 * to inspection_v2_tree.json.
 *
 * Auto-fixable:
 *   - Field reordering to match native order (check 2)
 *   - Insert missing label/section heading fields (check 3)
 *   - Correct label text to match native (check 4)
 *   - Replace/add dropdown options from native (check 5)
 *
 * Creates a backup before patching.
 *
 * Usage: node patch-v2-json.js [--dry-run]
 */
const fs = require('fs');
const path = require('path');

const TREE_PATH = path.resolve(__dirname, '../../assets/inspection_v2/inspection_v2_tree.json');
const BACKUP_PATH = TREE_PATH + '.backup';
const REPORT_PATH = path.join(__dirname, 'discrepancy-report.json');
const PATCH_LOG_PATH = path.join(__dirname, 'patch-log.json');

const DRY_RUN = process.argv.includes('--dry-run');

function main() {
  console.log(`=== V2 JSON Patcher ${DRY_RUN ? '(DRY RUN)' : ''} ===\n`);

  // Load report
  const report = JSON.parse(fs.readFileSync(REPORT_PATH, 'utf-8'));

  // Load V2 tree
  const tree = JSON.parse(fs.readFileSync(TREE_PATH, 'utf-8'));

  // Build screen lookup: screenId -> { sectionIdx, nodeIdx, screen }
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

  const patchLog = [];
  let patchCount = 0;
  let skipCount = 0;

  // Process each screen with discrepancies
  for (const screenReport of report.discrepancies) {
    const screenId = screenReport.screenId;
    const loc = screenLookup[screenId];
    if (!loc) {
      console.log(`  SKIP: Screen '${screenId}' not found in tree`);
      skipCount++;
      continue;
    }

    const screen = loc.screen;
    const autoFixDiscs = screenReport.discrepancies.filter(d => d.autoFixable);
    if (autoFixDiscs.length === 0) continue;

    for (const disc of autoFixDiscs) {
      switch (disc.check) {
        case 2:
          // Field reordering - defer until after all other patches
          break;

        case 3:
          // Missing section heading
          applyMissingSectionHeading(screen, disc, patchLog);
          patchCount++;
          break;

        case 4:
          // Label text mismatch
          applyLabelTextFix(screen, disc, patchLog);
          patchCount++;
          break;

        case 5:
          // Dropdown options
          applyDropdownOptionsFix(screen, disc, patchLog);
          patchCount++;
          break;
      }
    }

    // Apply field reordering last (after headings are inserted)
    const orderDiscs = autoFixDiscs.filter(d => d.check === 2);
    if (orderDiscs.length > 0) {
      applyFieldReorder(screen, screenReport, patchLog);
      patchCount++;
    }
  }

  console.log(`\nPatches applied: ${patchCount}`);
  console.log(`Skipped: ${skipCount}`);

  // Write patch log
  fs.writeFileSync(PATCH_LOG_PATH, JSON.stringify(patchLog, null, 2));
  console.log(`Patch log: ${PATCH_LOG_PATH}`);

  if (!DRY_RUN) {
    // Create backup
    fs.copyFileSync(TREE_PATH, BACKUP_PATH);
    console.log(`Backup: ${BACKUP_PATH}`);

    // Write patched tree
    fs.writeFileSync(TREE_PATH, JSON.stringify(tree, null, 2));
    console.log(`Patched: ${TREE_PATH}`);
  } else {
    console.log('\n(Dry run - no files modified)');
  }

  // Summary by type
  const byType = {};
  for (const log of patchLog) {
    byType[log.type] = (byType[log.type] || 0) + 1;
  }
  console.log('\nPatch summary:');
  for (const [type, count] of Object.entries(byType)) {
    console.log(`  ${type}: ${count}`);
  }
}

function applyMissingSectionHeading(screen, disc, patchLog) {
  const labelField = {
    id: `label_${disc.label.toLowerCase().replace(/[^a-z0-9]+/g, '_')}`,
    label: disc.label,
    type: 'label'
  };

  // Find the insertion position
  if (disc.insertBeforeFieldId) {
    const insertIdx = screen.fields.findIndex(f => f.id === disc.insertBeforeFieldId);
    if (insertIdx >= 0) {
      screen.fields.splice(insertIdx, 0, labelField);
      patchLog.push({
        type: 'insert_section_heading',
        screenId: screen.id,
        label: disc.label,
        position: insertIdx,
        insertBeforeField: disc.insertBeforeFieldId
      });
      return;
    }
  }

  // Fallback: insert at the position matching native
  const position = Math.min(disc.nativePosition, screen.fields.length);
  screen.fields.splice(position, 0, labelField);
  patchLog.push({
    type: 'insert_section_heading',
    screenId: screen.id,
    label: disc.label,
    position: position,
    insertBeforeField: null
  });
}

function applyLabelTextFix(screen, disc, patchLog) {
  const field = screen.fields.find(f => f.id === disc.fieldId);
  if (!field) return;

  const oldLabel = field.label;
  field.label = disc.nativeLabel;

  patchLog.push({
    type: 'fix_label_text',
    screenId: screen.id,
    fieldId: disc.fieldId,
    oldLabel: oldLabel,
    newLabel: disc.nativeLabel
  });
}

function applyDropdownOptionsFix(screen, disc, patchLog) {
  const field = screen.fields.find(f => f.id === disc.fieldId);
  if (!field) return;

  const oldOptions = field.options || [];

  if (disc.type === 'dropdown_options_missing') {
    // V2 has no options, add native options
    field.options = disc.nativeOptions;
  } else if (disc.type === 'dropdown_options_mismatch') {
    // Replace with native options to match exactly
    field.options = disc.nativeOptions;
  }

  patchLog.push({
    type: 'fix_dropdown_options',
    screenId: screen.id,
    fieldId: disc.fieldId,
    oldOptions: oldOptions,
    newOptions: field.options,
    nativeArrayName: disc.nativeArrayName || null
  });
}

function applyFieldReorder(screen, screenReport, patchLog) {
  // Load native spec to get the correct field order
  const nativeSpec = JSON.parse(fs.readFileSync(path.join(__dirname, 'native-spec.json'), 'utf-8'));
  const nativeScreen = nativeSpec.screens[screen.id];
  if (!nativeScreen) return;

  // Build native field order map: fieldId -> first position (deduplicated)
  const nativeOrder = {};
  const seen = new Set();
  nativeScreen.fields.forEach((f, idx) => {
    if (f.id && !seen.has(f.id)) {
      nativeOrder[f.id] = idx;
      seen.add(f.id);
    }
  });

  // Only reorder fields that exist in both native and V2
  const existsInNative = screen.fields.filter(f => f.id && nativeOrder[f.id] !== undefined);
  const notInNative = screen.fields.filter(f => !f.id || nativeOrder[f.id] === undefined);

  if (existsInNative.length < 2) return;

  // Sort V2 fields by native order
  existsInNative.sort((a, b) => nativeOrder[a.id] - nativeOrder[b.id]);

  // Rebuild fields: interleave V2-only fields at their original relative positions
  const oldFields = [...screen.fields];

  // Build position map: for each V2-only field, find which native-ordered fields
  // it was between in the original V2 array
  const newFields = [];
  const oldFieldIds = oldFields.map(f => f.id);

  // Track which V2-only fields come after each native field in original order
  const v2OnlyAfter = new Map(); // nativeFieldIdx -> [v2OnlyFields]
  let lastNativeIdx = -1;
  for (const field of oldFields) {
    if (field.id && nativeOrder[field.id] !== undefined) {
      lastNativeIdx = existsInNative.indexOf(
        existsInNative.find(f => f.id === field.id)
      );
    } else {
      if (!v2OnlyAfter.has(lastNativeIdx)) v2OnlyAfter.set(lastNativeIdx, []);
      v2OnlyAfter.get(lastNativeIdx).push(field);
    }
  }

  // Place V2-only fields that came before any native field
  if (v2OnlyAfter.has(-1)) {
    for (const f of v2OnlyAfter.get(-1)) newFields.push(f);
  }

  // Interleave native-ordered fields with their trailing V2-only fields
  for (let i = 0; i < existsInNative.length; i++) {
    newFields.push(existsInNative[i]);
    // Find V2-only fields that were after this field's original position
    const origIdx = oldFields.findIndex(f => f.id === existsInNative[i].id);
    // Append any V2-only fields that follow this field in the NEW native order
    if (v2OnlyAfter.has(i)) {
      for (const f of v2OnlyAfter.get(i)) newFields.push(f);
    }
  }

  // Any remaining V2-only fields not yet placed
  const placedIds = new Set(newFields.map(f => f.id || JSON.stringify(f)));
  for (const field of notInNative) {
    const key = field.id || JSON.stringify(field);
    if (!placedIds.has(key)) {
      newFields.push(field);
    }
  }

  screen.fields = newFields;

  patchLog.push({
    type: 'reorder_fields',
    screenId: screen.id,
    oldOrder: oldFields.map(f => f.id || f.label),
    newOrder: newFields.map(f => f.id || f.label)
  });
}

main();
