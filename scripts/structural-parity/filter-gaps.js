/**
 * Filter Gaps: Classify manual-review items as artifacts vs real gaps
 *
 * Reads the discrepancy report and filters out extraction artifacts,
 * producing a cleaned list of genuine user-visible gaps.
 */
const fs = require('fs');
const path = require('path');

const REPORT_PATH = path.join(__dirname, 'discrepancy-report.json');
const NATIVE_SPEC_PATH = path.join(__dirname, 'native-spec.json');
const V2_SPEC_PATH = path.join(__dirname, 'v2-spec.json');
const NATIVE_ROOT = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main');
const LAYOUT_DIR = path.join(NATIVE_ROOT, 'res/layout');

function main() {
  const report = JSON.parse(fs.readFileSync(REPORT_PATH, 'utf-8'));
  const nativeSpec = JSON.parse(fs.readFileSync(NATIVE_SPEC_PATH, 'utf-8'));
  const v2Spec = JSON.parse(fs.readFileSync(V2_SPEC_PATH, 'utf-8'));

  // Collect all non-auto-fixable discrepancies
  const allDiscs = [];
  for (const sr of report.discrepancies) {
    for (const d of sr.discrepancies) {
      if (!d.autoFixable) {
        allDiscs.push({...d, screenId: sr.screenId, v2Section: sr.v2Section});
      }
    }
  }

  console.log('Total manual-review items:', allDiscs.length);
  console.log();

  // === STEP 1: Classify extraction artifacts ===

  // Container ID patterns that are NOT real fields
  const CONTAINER_PATTERNS = [
    /^fd_Rl\d+$/,     // RelativeLayout containers
    /^ll\d+$/,        // LinearLayout containers
    /^ll[A-Z]/,       // Named LinearLayout containers (llHouseItem, etc.)
    /^rl_/,           // RelativeLayout prefixed
    /^content_main$/, // Root content
    /^ll$/,           // Root linear layout
  ];

  function isContainerArtifact(fieldId) {
    return CONTAINER_PATTERNS.some(p => p.test(fieldId));
  }

  // === STEP 2: Analyze each discrepancy type ===

  const classified = {
    artifacts: [],
    realGaps: [],
    conditionalInfo: [],
    fieldCountOnly: []
  };

  for (const disc of allDiscs) {
    // Type 1: Field count mismatch - not directly actionable
    if (disc.type === 'field_count_mismatch') {
      classified.fieldCountOnly.push(disc);
      continue;
    }

    // Type 2: Missing conditional (info severity) - flag for later analysis
    if (disc.type === 'missing_conditional') {
      classified.conditionalInfo.push(disc);
      continue;
    }

    // Type 3: field_missing_in_v2
    if (disc.type === 'field_missing_in_v2') {
      // Filter container artifacts
      if (isContainerArtifact(disc.fieldId)) {
        classified.artifacts.push({...disc, reason: 'container_id'});
        continue;
      }

      // Filter fields with no label (likely layout containers)
      if (!disc.fieldLabel || disc.fieldLabel.trim() === '') {
        classified.artifacts.push({...disc, reason: 'no_label'});
        continue;
      }

      // Check if this is a duplicate extraction of an existing field
      // (native XML parser picking up same field from nested container)
      const v2Screen = v2Spec.screens[disc.screenId];
      if (v2Screen) {
        // Check if a field with similar ID pattern already exists in V2
        const existsInV2 = v2Screen.fields.some(f => f.id === disc.fieldId);
        if (existsInV2) {
          classified.artifacts.push({...disc, reason: 'already_exists_in_v2'});
          continue;
        }
      }

      // This looks like a real gap - verify against native XML
      classified.realGaps.push(disc);
      continue;
    }

    // Type 4: field_extra_in_v2
    if (disc.type === 'field_extra_in_v2') {
      // These are V2-only fields - usually intentional additions
      // Don't flag as gaps unless they conflict
      classified.artifacts.push({...disc, reason: 'v2_only_field'});
      continue;
    }

    // Anything else
    classified.realGaps.push(disc);
  }

  console.log('=== Classification Results ===');
  console.log('Artifacts (filtered):', classified.artifacts.length);
  console.log('  - Container IDs:', classified.artifacts.filter(a => a.reason === 'container_id').length);
  console.log('  - No label:', classified.artifacts.filter(a => a.reason === 'no_label').length);
  console.log('  - Already in V2:', classified.artifacts.filter(a => a.reason === 'already_exists_in_v2').length);
  console.log('  - V2-only fields:', classified.artifacts.filter(a => a.reason === 'v2_only_field').length);
  console.log('Field count only:', classified.fieldCountOnly.length);
  console.log('Conditional info:', classified.conditionalInfo.length);
  console.log('Potential real gaps:', classified.realGaps.length);
  console.log();

  // === STEP 3: Further analyze potential real gaps ===

  // Group by screen
  const gapsByScreen = {};
  for (const gap of classified.realGaps) {
    if (!gapsByScreen[gap.screenId]) gapsByScreen[gap.screenId] = [];
    gapsByScreen[gap.screenId].push(gap);
  }

  console.log('Screens with potential real gaps:', Object.keys(gapsByScreen).length);
  console.log();

  // Verify each gap against the actual native XML
  const verifiedGaps = [];
  const falsePositives = [];

  for (const [screenId, gaps] of Object.entries(gapsByScreen)) {
    const layoutFile = path.join(LAYOUT_DIR, screenId + '.xml');
    let xmlContent = '';
    try {
      xmlContent = fs.readFileSync(layoutFile, 'utf-8');
    } catch (e) {
      // Layout file doesn't exist - all gaps for this screen are artifacts
      for (const gap of gaps) {
        falsePositives.push({...gap, reason: 'no_native_layout'});
      }
      continue;
    }

    for (const gap of gaps) {
      if (gap.type !== 'field_missing_in_v2') {
        verifiedGaps.push(gap);
        continue;
      }

      // Verify the field actually exists as a user-visible input in the XML
      const fieldId = gap.fieldId;

      // Check if this ID appears as an android:id in the XML
      const idRegex = new RegExp('@\\+id/' + fieldId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '"');
      if (!idRegex.test(xmlContent)) {
        falsePositives.push({...gap, reason: 'id_not_in_xml'});
        continue;
      }

      // Check what element type has this ID
      const lines = xmlContent.split('\n');
      let elementType = null;
      let isUserVisible = false;

      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('@+id/' + fieldId + '"')) {
          // Look backwards to find the element tag
          for (let j = i; j >= Math.max(0, i - 15); j--) {
            const tagMatch = lines[j].match(/<([\w.]+)/);
            if (tagMatch) {
              elementType = tagMatch[1];
              break;
            }
          }
          break;
        }
      }

      // Filter: only keep actual input elements
      const inputElements = [
        'AutoCompleteTextView', 'EditText', 'TextInputEditText',
        'CheckBox', 'RadioButton', 'Spinner', 'Switch', 'TextView'
      ];

      const containerElements = [
        'LinearLayout', 'RelativeLayout', 'FrameLayout',
        'ConstraintLayout', 'ScrollView', 'CardView',
        'com.google.android.material.textfield.TextInputLayout'
      ];

      if (elementType) {
        const shortType = elementType.split('.').pop();
        if (inputElements.includes(shortType)) {
          // But TextViews that aren't section headers are just labels for layout
          if (shortType === 'TextView') {
            // Check if it's a section header style
            const context = lines.slice(Math.max(0, lines.findIndex(l => l.includes('@+id/' + fieldId)) - 5),
              lines.findIndex(l => l.includes('@+id/' + fieldId)) + 5).join(' ');
            if (/ModernSectionHeader/.test(context)) {
              isUserVisible = true;
            } else {
              falsePositives.push({...gap, reason: 'non_input_textview', elementType});
              continue;
            }
          } else {
            isUserVisible = true;
          }
        } else if (containerElements.includes(shortType) || shortType === 'TextInputLayout') {
          falsePositives.push({...gap, reason: 'container_element', elementType});
          continue;
        } else {
          // Unknown element - include for safety
          isUserVisible = true;
        }
      }

      if (isUserVisible) {
        verifiedGaps.push({...gap, elementType, xmlLine: findLineNumber(xmlContent, fieldId)});
      } else {
        falsePositives.push({...gap, reason: 'not_input_element', elementType});
      }
    }
  }

  console.log('=== Verification Results ===');
  console.log('Verified real gaps:', verifiedGaps.length);
  console.log('False positives:', falsePositives.length);
  console.log('  - No native layout:', falsePositives.filter(f => f.reason === 'no_native_layout').length);
  console.log('  - ID not in XML:', falsePositives.filter(f => f.reason === 'id_not_in_xml').length);
  console.log('  - Container element:', falsePositives.filter(f => f.reason === 'container_element').length);
  console.log('  - Non-input TextView:', falsePositives.filter(f => f.reason === 'non_input_textview').length);
  console.log('  - Not input element:', falsePositives.filter(f => f.reason === 'not_input_element').length);
  console.log();

  // Group verified gaps by type and section
  console.log('=== Verified Gaps by Section ===');
  const bySection = {};
  for (const gap of verifiedGaps) {
    const s = gap.v2Section || 'unknown';
    if (!bySection[s]) bySection[s] = [];
    bySection[s].push(gap);
  }
  for (const [section, gaps] of Object.entries(bySection).sort()) {
    console.log(`  Section ${section}: ${gaps.length} gaps`);
  }

  console.log();
  console.log('=== Verified Gaps Detail ===');
  for (const gap of verifiedGaps) {
    console.log(`[${gap.v2Section}] ${gap.screenId} | ${gap.fieldId} (${gap.fieldType}: "${gap.fieldLabel}") | ${gap.type} | element: ${gap.elementType || 'N/A'}`);
  }

  // Save results
  const output = {
    summary: {
      totalManualReview: allDiscs.length,
      artifacts: classified.artifacts.length,
      fieldCountOnly: classified.fieldCountOnly.length,
      conditionalInfo: classified.conditionalInfo.length,
      potentialGaps: classified.realGaps.length,
      verifiedGaps: verifiedGaps.length,
      falsePositives: falsePositives.length
    },
    verifiedGaps,
    falsePositives,
    conditionalInfo: classified.conditionalInfo
  };

  fs.writeFileSync(path.join(__dirname, 'filtered-gaps.json'), JSON.stringify(output, null, 2));
  console.log('\nSaved: scripts/structural-parity/filtered-gaps.json');
}

function findLineNumber(xmlContent, fieldId) {
  const lines = xmlContent.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('@+id/' + fieldId + '"')) return i + 1;
  }
  return null;
}

main();
