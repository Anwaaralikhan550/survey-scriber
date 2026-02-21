/**
 * Compare Parity: Native Spec vs V2 Spec
 *
 * Joins native-spec and v2-spec by screen ID and runs 7 comparison checks
 * per matched screen pair.
 *
 * Output: scripts/structural-parity/discrepancy-report.json + discrepancy-report.md
 */
const fs = require('fs');
const path = require('path');

const NATIVE_PATH = path.join(__dirname, 'native-spec.json');
const V2_PATH = path.join(__dirname, 'v2-spec.json');
const REPORT_JSON_PATH = path.join(__dirname, 'discrepancy-report.json');
const REPORT_MD_PATH = path.join(__dirname, 'discrepancy-report.md');

// Load prior analysis files if available
const PRIOR_DROPDOWNS_PATH = path.resolve(__dirname, '../../inspection_v2_missing_dropdowns_with_options_by_layout.json');
const PRIOR_VISIBILITY_PATH = path.resolve(__dirname, '../../inspection_v2_visibility_rules_parsed.json');

function loadPriorAnalysis() {
  const prior = { dropdowns: {}, visibility: [] };
  try {
    const dropdowns = JSON.parse(fs.readFileSync(PRIOR_DROPDOWNS_PATH, 'utf-8'));
    for (const d of dropdowns) {
      if (!prior.dropdowns[d.screen]) prior.dropdowns[d.screen] = {};
      prior.dropdowns[d.screen][d.field_id] = d.options;
    }
  } catch (e) { /* no prior data */ }
  try {
    prior.visibility = JSON.parse(fs.readFileSync(PRIOR_VISIBILITY_PATH, 'utf-8'));
  } catch (e) { /* no prior data */ }
  return prior;
}

function normalizeId(id) {
  // Strip double-underscore duplicate suffixes: activity_x__y__2 -> activity_x__y
  return id.replace(/__\d+$/, '');
}

function compareScreens(nativeScreen, v2Screen, stringArrays, priorAnalysis) {
  const discrepancies = [];
  const nativeFields = nativeScreen.fields;
  const v2Fields = v2Screen.fields;

  // --- Check 1: Field Count ---
  if (nativeFields.length !== v2Fields.length) {
    discrepancies.push({
      check: 1,
      type: 'field_count_mismatch',
      severity: 'warning',
      autoFixable: false,
      native: nativeFields.length,
      v2: v2Fields.length,
      message: `Field count: native=${nativeFields.length}, v2=${v2Fields.length}`
    });
  }

  // Build field lookup maps by ID
  const nativeFieldById = {};
  const v2FieldById = {};
  for (const f of nativeFields) {
    if (f.id) nativeFieldById[f.id] = f;
  }
  for (const f of v2Fields) {
    if (f.id) v2FieldById[f.id] = f;
  }

  // --- Check 2: Field Order ---
  // Compare order of fields that exist in both (by ID)
  const commonIds = Object.keys(nativeFieldById).filter(id => v2FieldById[id]);
  const nativeOrder = commonIds.map(id => nativeFields.findIndex(f => f.id === id));
  const v2Order = commonIds.map(id => v2Fields.findIndex(f => f.id === id));

  for (let i = 0; i < commonIds.length; i++) {
    // Check relative ordering - is anything out of sequence?
    for (let j = i + 1; j < commonIds.length; j++) {
      if ((nativeOrder[i] < nativeOrder[j]) !== (v2Order[i] < v2Order[j])) {
        discrepancies.push({
          check: 2,
          type: 'field_order_mismatch',
          severity: 'warning',
          autoFixable: true,
          fieldA: commonIds[i],
          fieldB: commonIds[j],
          nativePositions: [nativeOrder[i], nativeOrder[j]],
          v2Positions: [v2Order[i], v2Order[j]],
          message: `Order: '${commonIds[i]}' before '${commonIds[j]}' in native, reversed in V2`
        });
        // Only report first order issue pair to avoid noise
        break;
      }
    }
    if (discrepancies.some(d => d.check === 2)) break;
  }

  // --- Check 3: Missing Section Headings ---
  const nativeLabels = nativeFields.filter(f => f.type === 'label');
  const v2Labels = v2Fields.filter(f => f.type === 'label');

  for (const nativeLabel of nativeLabels) {
    const found = v2Labels.some(v2l =>
      v2l.label.toLowerCase().trim() === nativeLabel.label.toLowerCase().trim()
    );
    if (!found) {
      // Find the position where this label should go
      const nativeIdx = nativeFields.indexOf(nativeLabel);
      // Find the next field after this label that has an ID
      let insertBeforeId = null;
      for (let k = nativeIdx + 1; k < nativeFields.length; k++) {
        if (nativeFields[k].id && v2FieldById[nativeFields[k].id]) {
          insertBeforeId = nativeFields[k].id;
          break;
        }
      }
      discrepancies.push({
        check: 3,
        type: 'missing_section_heading',
        severity: 'error',
        autoFixable: true,
        label: nativeLabel.label,
        nativePosition: nativeIdx,
        insertBeforeFieldId: insertBeforeId,
        message: `Missing section heading: "${nativeLabel.label}"`
      });
    }
  }

  // --- Check 4: Label Text Mismatch ---
  for (const id of commonIds) {
    const nf = nativeFieldById[id];
    const vf = v2FieldById[id];
    if (nf.label && vf.label && nf.label.trim() !== vf.label.trim()) {
      discrepancies.push({
        check: 4,
        type: 'label_text_mismatch',
        severity: 'warning',
        autoFixable: true,
        fieldId: id,
        nativeLabel: nf.label.trim(),
        v2Label: vf.label.trim(),
        message: `Label mismatch for '${id}': native="${nf.label.trim()}", v2="${vf.label.trim()}"`
      });
    }
  }

  // --- Check 5: Dropdown Option Mismatch ---
  for (const id of commonIds) {
    const nf = nativeFieldById[id];
    const vf = v2FieldById[id];
    if (nf.type === 'dropdown' && nf.options && nf.options.length > 0) {
      if (!vf.options || vf.options.length === 0) {
        // V2 has no options - check if prior analysis had them
        const priorOptions = priorAnalysis.dropdowns[v2Screen.screenId]?.[id];
        discrepancies.push({
          check: 5,
          type: 'dropdown_options_missing',
          severity: 'error',
          autoFixable: true,
          fieldId: id,
          nativeOptions: nf.options,
          nativeArrayName: nf.arrayName || null,
          v2Options: vf.options || [],
          priorOptions: priorOptions || null,
          message: `Dropdown '${id}' missing options in V2. Native has ${nf.options.length} options.`
        });
      } else {
        // Both have options - compare
        const nOpts = nf.options.map(o => o.trim());
        const vOpts = vf.options.map(o => o.trim());
        const nativeSet = new Set(nOpts);
        const v2Set = new Set(vOpts);

        const missingInV2 = nOpts.filter(o => !v2Set.has(o));
        const extraInV2 = vOpts.filter(o => !nativeSet.has(o));
        const orderDiff = nOpts.length === vOpts.length &&
          nOpts.some((o, idx) => o !== vOpts[idx]);

        if (missingInV2.length > 0 || extraInV2.length > 0 || orderDiff) {
          discrepancies.push({
            check: 5,
            type: 'dropdown_options_mismatch',
            severity: 'warning',
            autoFixable: true,
            fieldId: id,
            nativeOptions: nOpts,
            v2Options: vOpts,
            missingInV2,
            extraInV2,
            orderDifference: orderDiff && missingInV2.length === 0 && extraInV2.length === 0,
            message: `Dropdown '${id}' options differ. Missing in V2: [${missingInV2.join(', ')}], Extra in V2: [${extraInV2.join(', ')}]`
          });
        }
      }
    }
  }

  // --- Check 6: Missing/Wrong Conditionals ---
  // Check V2 fields that should have conditionals based on native visibility patterns
  for (const id of commonIds) {
    const nf = nativeFieldById[id];
    const vf = v2FieldById[id];

    // If native field has staticVisibility='gone', it should have a conditional in V2
    if (nf.staticVisibility === 'gone' && !vf.conditionalOn) {
      discrepancies.push({
        check: 6,
        type: 'missing_conditional',
        severity: 'info',
        autoFixable: false,
        fieldId: id,
        message: `Field '${id}' is hidden by default in native but has no conditional in V2`
      });
    }

    // If V2 has a conditional, validate it makes sense
    if (vf.conditionalOn && nf.staticVisibility !== 'gone') {
      // V2 has a conditional but native field isn't hidden - might be wrong
      // But don't flag this as some conditionals are set by Java code
    }
  }

  // --- Check 7: Missing/Extra Field IDs ---
  const nativeFieldIds = nativeFields.filter(f => f.id).map(f => f.id);
  const v2FieldIds = v2Fields.filter(f => f.id).map(f => f.id);

  const missingInV2 = nativeFieldIds.filter(id => !v2FieldById[id]);
  const extraInV2 = v2FieldIds.filter(id => !nativeFieldById[id]);

  for (const id of missingInV2) {
    const nf = nativeFieldById[id];
    discrepancies.push({
      check: 7,
      type: 'field_missing_in_v2',
      severity: 'error',
      autoFixable: false,
      fieldId: id,
      fieldType: nf.type,
      fieldLabel: nf.label,
      message: `Field '${id}' (${nf.type}: "${nf.label}") exists in native but missing in V2`
    });
  }

  for (const id of extraInV2) {
    const vf = v2FieldById[id];
    discrepancies.push({
      check: 7,
      type: 'field_extra_in_v2',
      severity: 'info',
      autoFixable: false,
      fieldId: id,
      fieldType: vf.type,
      fieldLabel: vf.label,
      message: `Field '${id}' (${vf.type}: "${vf.label}") exists in V2 but not in native`
    });
  }

  return discrepancies;
}

function generateMarkdownReport(report) {
  const lines = [];
  lines.push('# Structural Parity Discrepancy Report');
  lines.push('');
  lines.push(`Generated: ${new Date().toISOString()}`);
  lines.push('');

  // Summary
  lines.push('## Summary');
  lines.push('');
  lines.push(`| Metric | Count |`);
  lines.push(`|--------|-------|`);
  lines.push(`| Matched screen pairs | ${report.summary.matchedScreens} |`);
  lines.push(`| Native-only screens (not in V2) | ${report.summary.nativeOnlyScreens} |`);
  lines.push(`| V2-only screens (not in native) | ${report.summary.v2OnlyScreens} |`);
  lines.push(`| Total discrepancies | ${report.summary.totalDiscrepancies} |`);
  lines.push(`| Auto-fixable | ${report.summary.autoFixable} |`);
  lines.push(`| Manual review needed | ${report.summary.manualReview} |`);
  lines.push('');

  // By check type
  lines.push('## Discrepancies by Type');
  lines.push('');
  lines.push(`| # | Check | Count | Auto-fixable |`);
  lines.push(`|---|-------|-------|-------------|`);
  const checkNames = {
    1: 'Field count mismatch',
    2: 'Field order mismatch',
    3: 'Missing section headings',
    4: 'Label text mismatch',
    5: 'Dropdown option mismatch',
    6: 'Missing/wrong conditionals',
    7: 'Missing/extra field IDs'
  };
  for (let i = 1; i <= 7; i++) {
    const items = report.discrepancies.filter(d => d.discrepancies.some(dd => dd.check === i));
    const count = report.discrepancies.reduce((sum, d) =>
      sum + d.discrepancies.filter(dd => dd.check === i).length, 0);
    const fixable = report.discrepancies.reduce((sum, d) =>
      sum + d.discrepancies.filter(dd => dd.check === i && dd.autoFixable).length, 0);
    lines.push(`| ${i} | ${checkNames[i]} | ${count} | ${fixable} |`);
  }
  lines.push('');

  // By severity
  lines.push('## By Severity');
  lines.push('');
  const allDiscs = report.discrepancies.flatMap(d => d.discrepancies);
  const errors = allDiscs.filter(d => d.severity === 'error').length;
  const warnings = allDiscs.filter(d => d.severity === 'warning').length;
  const infos = allDiscs.filter(d => d.severity === 'info').length;
  lines.push(`- **Errors**: ${errors} (must fix)`);
  lines.push(`- **Warnings**: ${warnings} (should fix)`);
  lines.push(`- **Info**: ${infos} (review)`);
  lines.push('');

  // By section
  lines.push('## By Section');
  lines.push('');
  const sectionDiscrepancies = {};
  for (const screenReport of report.discrepancies) {
    const section = screenReport.v2Section || 'unknown';
    if (!sectionDiscrepancies[section]) sectionDiscrepancies[section] = { total: 0, screens: 0 };
    sectionDiscrepancies[section].total += screenReport.discrepancies.length;
    sectionDiscrepancies[section].screens++;
  }
  lines.push(`| Section | Screens with issues | Total discrepancies |`);
  lines.push(`|---------|-------------------|-------------------|`);
  for (const [section, data] of Object.entries(sectionDiscrepancies).sort()) {
    lines.push(`| ${section} | ${data.screens} | ${data.total} |`);
  }
  lines.push('');

  // Detailed per-screen discrepancies (auto-fixable only in main section)
  lines.push('## Auto-Fixable Discrepancies (by screen)');
  lines.push('');

  const screensWithAutoFix = report.discrepancies
    .filter(d => d.discrepancies.some(dd => dd.autoFixable))
    .sort((a, b) => {
      const sectionOrder = (a.v2Section || 'Z').localeCompare(b.v2Section || 'Z');
      return sectionOrder !== 0 ? sectionOrder : a.screenId.localeCompare(b.screenId);
    });

  let currentSection = '';
  for (const screenReport of screensWithAutoFix) {
    if (screenReport.v2Section !== currentSection) {
      currentSection = screenReport.v2Section;
      lines.push(`### Section ${currentSection}`);
      lines.push('');
    }

    const autoFixDiscs = screenReport.discrepancies.filter(d => d.autoFixable);
    lines.push(`#### ${screenReport.screenId}`);
    lines.push('');
    for (const d of autoFixDiscs) {
      lines.push(`- **[Check ${d.check}]** ${d.message}`);
      if (d.nativeOptions) {
        lines.push(`  - Native options: ${JSON.stringify(d.nativeOptions)}`);
      }
      if (d.v2Options && d.v2Options.length > 0) {
        lines.push(`  - V2 options: ${JSON.stringify(d.v2Options)}`);
      }
    }
    lines.push('');
  }

  // Manual review section
  lines.push('## Manual Review Items');
  lines.push('');

  const screensWithManual = report.discrepancies
    .filter(d => d.discrepancies.some(dd => !dd.autoFixable));

  for (const screenReport of screensWithManual.slice(0, 50)) {
    const manualDiscs = screenReport.discrepancies.filter(d => !d.autoFixable);
    if (manualDiscs.length > 0) {
      lines.push(`#### ${screenReport.screenId}`);
      for (const d of manualDiscs) {
        lines.push(`- **[${d.severity}]** ${d.message}`);
      }
      lines.push('');
    }
  }
  if (screensWithManual.length > 50) {
    lines.push(`... and ${screensWithManual.length - 50} more screens with manual review items`);
  }

  return lines.join('\n');
}

function main() {
  console.log('=== Structural Parity Comparison ===\n');

  const native = JSON.parse(fs.readFileSync(NATIVE_PATH, 'utf-8'));
  const v2 = JSON.parse(fs.readFileSync(V2_PATH, 'utf-8'));
  const priorAnalysis = loadPriorAnalysis();

  const nativeScreens = native.screens;
  const v2Screens = v2.screens;
  const stringArrays = native.stringArrays;

  const nativeIds = Object.keys(nativeScreens);
  const v2Ids = Object.keys(v2Screens);

  // Find matches - V2 screen ID should match native layout name
  const matched = [];
  const nativeOnly = [];

  for (const nativeId of nativeIds) {
    if (v2Screens[nativeId]) {
      matched.push(nativeId);
    } else {
      nativeOnly.push(nativeId);
    }
  }

  const v2Only = v2Ids.filter(id => !nativeScreens[id] && !nativeScreens[normalizeId(id)]);

  console.log(`Matched screens: ${matched.length}`);
  console.log(`Native-only: ${nativeOnly.length}`);
  console.log(`V2-only: ${v2Only.length}`);

  // Also check duplicate screens
  const duplicateScreens = v2.duplicates || {};
  console.log(`Duplicate screen groups: ${Object.keys(duplicateScreens).length}`);

  // Run comparison on all matched screens
  const results = [];
  let totalDiscrepancies = 0;
  let autoFixable = 0;

  for (const screenId of matched) {
    const nativeScreen = nativeScreens[screenId];
    const v2Screen = v2Screens[screenId];

    // Skip screens with no fields on both sides
    if (nativeScreen.fields.length === 0 && v2Screen.fields.length === 0) continue;

    const discrepancies = compareScreens(nativeScreen, v2Screen, stringArrays, priorAnalysis);

    if (discrepancies.length > 0) {
      totalDiscrepancies += discrepancies.length;
      autoFixable += discrepancies.filter(d => d.autoFixable).length;

      results.push({
        screenId,
        nativeTitle: nativeScreen.screenTitle,
        v2Title: v2Screen.title,
        v2Section: v2Screen.sectionKey,
        nativeFieldCount: nativeScreen.fields.length,
        v2FieldCount: v2Screen.fields.length,
        discrepancies
      });
    }
  }

  // Check duplicate screens for structural consistency with base
  const duplicateResults = [];
  for (const [baseId, copies] of Object.entries(duplicateScreens)) {
    if (!v2Screens[baseId]) continue;
    const baseScreen = v2Screens[baseId];

    for (const copyId of copies) {
      if (!v2Screens[copyId]) continue;
      const copyScreen = v2Screens[copyId];

      // Compare copy to base
      const baseFieldIds = baseScreen.fields.map(f => f.id).join(',');
      const copyFieldIds = copyScreen.fields.map(f => f.id).join(',');

      if (baseFieldIds !== copyFieldIds) {
        duplicateResults.push({
          baseId,
          copyId,
          baseFieldCount: baseScreen.fields.length,
          copyFieldCount: copyScreen.fields.length,
          message: `Duplicate '${copyId}' differs from base '${baseId}'`
        });
      }
    }
  }

  console.log(`\nScreens with discrepancies: ${results.length}`);
  console.log(`Total discrepancies: ${totalDiscrepancies}`);
  console.log(`Auto-fixable: ${autoFixable}`);
  console.log(`Manual review: ${totalDiscrepancies - autoFixable}`);
  console.log(`Duplicate consistency issues: ${duplicateResults.length}`);

  // Summary by check type
  console.log('\nBy check type:');
  for (let i = 1; i <= 7; i++) {
    const count = results.reduce((sum, r) =>
      sum + r.discrepancies.filter(d => d.check === i).length, 0);
    const checkNames = {
      1: 'Field count mismatch',
      2: 'Field order mismatch',
      3: 'Missing section headings',
      4: 'Label text mismatch',
      5: 'Dropdown option mismatch/missing',
      6: 'Missing/wrong conditionals',
      7: 'Missing/extra field IDs'
    };
    console.log(`  ${i}. ${checkNames[i]}: ${count}`);
  }

  const report = {
    summary: {
      matchedScreens: matched.length,
      nativeOnlyScreens: nativeOnly.length,
      v2OnlyScreens: v2Only.length,
      screensWithDiscrepancies: results.length,
      totalDiscrepancies,
      autoFixable,
      manualReview: totalDiscrepancies - autoFixable,
      duplicateIssues: duplicateResults.length
    },
    nativeOnlyScreens: nativeOnly,
    v2OnlyScreens: v2Only,
    discrepancies: results,
    duplicateIssues: duplicateResults
  };

  // Write JSON report
  fs.writeFileSync(REPORT_JSON_PATH, JSON.stringify(report, null, 2));
  console.log(`\nJSON report: ${REPORT_JSON_PATH}`);

  // Write Markdown report
  const mdReport = generateMarkdownReport(report);
  fs.writeFileSync(REPORT_MD_PATH, mdReport);
  console.log(`MD report: ${REPORT_MD_PATH}`);
}

main();
