/**
 * compare-labels.js
 *
 * Cross-references native XML headings against V2 tree labels to find
 * missing section headings. Generates a patch specification.
 *
 * Input:  native_headings.json, v2_labels.json
 * Output: label_diff.json — patch specification for missing labels
 */

const fs = require('fs');
const path = require('path');

const NATIVE_FILE = path.join(__dirname, 'native_headings.json');
const V2_FILE = path.join(__dirname, 'v2_labels.json');
const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');
const OUTPUT_FILE = path.join(__dirname, 'label_diff.json');
const REPORT_FILE = path.join(__dirname, 'label_diff_report.txt');

function normalizeText(text) {
  return text.toLowerCase().trim().replace(/\s+/g, ' ');
}

function main() {
  const native = JSON.parse(fs.readFileSync(NATIVE_FILE, 'utf8'));
  const v2 = JSON.parse(fs.readFileSync(V2_FILE, 'utf8'));
  const tree = JSON.parse(fs.readFileSync(TREE_FILE, 'utf8'));
  const v2Screens = Object.keys(v2);

  // Also build a lookup of V2 screens that are variants (__suffix screens)
  // These share the same native layout base
  const v2VariantMap = {}; // base screenId → [variant screenIds]
  for (const screenId of v2Screens) {
    if (screenId.includes('__')) {
      const base = screenId.split('__')[0];
      if (!v2VariantMap[base]) v2VariantMap[base] = [];
      v2VariantMap[base].push(screenId);
    }
  }

  // Headings that are NOT actual section headings (they're UI chrome, navigation items, etc.)
  const IGNORE_HEADINGS = new Set([
    'login here', 'forgot password?', 'new user? sign up', 'aboutus',
    'view_on_map', 'start inspection', 'pause inspection', 'reset inspection',
    'generate report', 'time:', 'arrive time:', 'depart time:', 'date:',
    'client name:', 'property type:', 'access type:', 'access:',
    'surveyor name:', 'purchase price:', 'country', 'name:', 'name',
    'address:', 'city:', 'phone no:', 'postcode:', 'pincode:', 'country:',
    'client notes:', 'special instruction:', 'agent details', 'agent notes:',
    'client note', 'special instruction', 'agent note', 'notes:',
    // Navigation/dashboard section headers (not field group headings)
    'e1_chimney', 'e2_roof_covering', 'e3_rain_water_goods', 'e4_main_walls',
    'e5_windows', 'e6_outside_doors', 'e7_conservatory_porches',
    'e8_other_joinery_finishes', 'e9_other',
    'roof_structure_main', 'ceilings_main', 'walls_and_partitions_main',
    'floors_main', 'fireplaces_and_chimneys_main', 'built_in_fittings_main',
    'woodwork_main', 'bathroom_fittings_main', 'other_main',
    'grounds_garage_b', 'other_b', 'grounds_other_area_b',
    'service_electricity_b', 'service_gas_and_oil_b', 'service_water_b',
    'service_heating_g', 'service_water_heating_g', 'service_drainage_b',
    'service_common_services_b',
    // Purely numeric headings
    '123', '1994',
  ]);

  // Screens that are containers/navigation (not form screens in V2)
  const NAVIGATION_SCREENS = new Set([
    'activity_about_inspection', 'activity_about_property',
    'activity_accommodation_summary', 'activity_construction',
    'activity_details', 'activity_edit_ivf', 'activity_edit_valuation',
    'activity_ground', 'activity_grounds', 'activity_inside_property',
    'activity_inspection_dashboard', 'activity_generate_report',
  ]);

  const missingLabels = [];
  const alreadyPresent = [];
  const noV2Screen = [];
  const ignored = [];

  let totalMissing = 0;
  let totalPresent = 0;

  for (const [layoutName, data] of Object.entries(native)) {
    const headings = data.headings;
    const headingDetails = data.headingDetails;

    // Skip navigation/container screens
    if (NAVIGATION_SCREENS.has(layoutName)) {
      ignored.push({ layoutName, reason: 'navigation screen' });
      continue;
    }

    // Find matching V2 screen(s)
    const matchedScreens = [];

    if (v2[layoutName]) {
      matchedScreens.push(layoutName);
    }

    // Also check for variant screens
    if (v2VariantMap[layoutName]) {
      matchedScreens.push(...v2VariantMap[layoutName]);
    }

    if (matchedScreens.length === 0) {
      // Try fuzzy match: remove common prefixes
      const stripped = layoutName.replace(/^activity_/, '');
      for (const screenId of v2Screens) {
        if (screenId === stripped || screenId.replace(/^activity_/, '') === stripped) {
          matchedScreens.push(screenId);
        }
      }
    }

    if (matchedScreens.length === 0) {
      noV2Screen.push({ layoutName, headings });
      continue;
    }

    // For each heading in the native layout, check if it exists in V2
    for (const screenId of matchedScreens) {
      const v2Data = v2[screenId];
      if (!v2Data) continue;

      const existingLabels = v2Data.labels.map(l => normalizeText(l.label));
      const screenMissing = [];

      for (let i = 0; i < headings.length; i++) {
        const headingText = headings[i];
        const normalized = normalizeText(headingText);

        // Skip non-section headings
        if (IGNORE_HEADINGS.has(normalized)) {
          ignored.push({ layoutName, screenId, heading: headingText, reason: 'ignored heading' });
          continue;
        }

        // Check if this heading already exists as a label
        if (existingLabels.includes(normalized)) {
          alreadyPresent.push({ screenId, heading: headingText });
          totalPresent++;
          continue;
        }

        // Also check partial match (native "Main Electricity" vs V2 "Main Electricity")
        const partialMatch = existingLabels.some(l =>
          l.includes(normalized) || normalized.includes(l)
        );
        if (partialMatch) {
          alreadyPresent.push({ screenId, heading: headingText, note: 'partial match' });
          totalPresent++;
          continue;
        }

        // This heading is missing from V2
        const detail = headingDetails[i] || {};
        screenMissing.push({
          text: headingText,
          fieldsAfter: detail.fieldsAfter || 0,
          nativeFirstFieldId: detail.firstFieldId || null,
        });
        totalMissing++;
      }

      if (screenMissing.length > 0) {
        // Determine where to insert the labels in the V2 field array
        // We need to figure out the correct position based on field ordering
        const insertions = determineInsertPositions(screenMissing, v2Data, headingDetails, headings);

        missingLabels.push({
          screenId,
          nativeLayout: layoutName,
          screenTitle: v2Data.title,
          fieldCount: v2Data.fieldCount,
          existingLabels: v2Data.labels.map(l => l.label),
          missing: insertions,
        });
      }
    }
  }

  // Sort missing labels: highest field count first (biggest impact)
  missingLabels.sort((a, b) => b.fieldCount - a.fieldCount);

  const result = {
    summary: {
      nativeLayoutsAnalyzed: Object.keys(native).length,
      v2ScreensAnalyzed: v2Screens.length,
      totalHeadingsFound: Object.values(native).reduce((sum, d) => sum + d.headings.length, 0),
      headingsAlreadyPresent: totalPresent,
      headingsMissing: totalMissing,
      screensNeedingPatches: missingLabels.length,
      screensNotInV2: noV2Screen.length,
      headingsIgnored: ignored.length,
    },
    missingLabels,
    noV2Screen: noV2Screen.slice(0, 50), // Cap for readability
  };

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(result, null, 2));

  // Generate human-readable report
  let report = '=== LABEL DIFF REPORT ===\n\n';
  report += `Native layouts analyzed: ${result.summary.nativeLayoutsAnalyzed}\n`;
  report += `V2 screens analyzed: ${result.summary.v2ScreensAnalyzed}\n`;
  report += `Total native headings: ${result.summary.totalHeadingsFound}\n`;
  report += `Already present in V2: ${result.summary.headingsAlreadyPresent}\n`;
  report += `MISSING from V2: ${result.summary.headingsMissing}\n`;
  report += `Screens needing patches: ${result.summary.screensNeedingPatches}\n`;
  report += `Layouts not in V2: ${result.summary.screensNotInV2}\n`;
  report += `Headings ignored (non-section): ${result.summary.headingsIgnored}\n`;
  report += '\n';

  report += '=== MISSING LABELS BY SCREEN ===\n\n';
  for (const item of missingLabels) {
    report += `Screen: ${item.screenId} (${item.screenTitle}) [${item.fieldCount} fields]\n`;
    report += `  Native layout: ${item.nativeLayout}\n`;
    if (item.existingLabels.length > 0) {
      report += `  Existing labels: ${item.existingLabels.join(', ')}\n`;
    }
    for (const m of item.missing) {
      report += `  MISSING: "${m.text}" → insert at position ${m.insertPosition}\n`;
    }
    report += '\n';
  }

  if (noV2Screen.length > 0) {
    report += '=== NATIVE LAYOUTS NOT IN V2 (first 30) ===\n\n';
    for (const item of noV2Screen.slice(0, 30)) {
      report += `  ${item.layoutName}: ${item.headings.join(', ')}\n`;
    }
  }

  fs.writeFileSync(REPORT_FILE, report);

  console.log(report);
  console.log(`\nOutput: ${OUTPUT_FILE}`);
  console.log(`Report: ${REPORT_FILE}`);
}

/**
 * Determine where in the V2 field array each missing label should be inserted.
 *
 * Strategy: Match native field IDs to V2 field IDs to find positions.
 * If no field ID match, use ordering relative to known headings.
 */
function determineInsertPositions(missingHeadings, v2Data, headingDetails, allHeadings) {
  const v2Fields = v2Data.allFieldLabels;
  const existingLabels = v2Data.labels;

  return missingHeadings.map(missing => {
    // Try to find insertion point by matching the native field ID
    // that follows this heading in the native layout
    let insertPosition = 0;

    if (missing.nativeFirstFieldId) {
      // Look for a V2 field with matching ID
      const fieldIdx = v2Fields.findIndex(f =>
        f.id === missing.nativeFirstFieldId ||
        f.id.includes(missing.nativeFirstFieldId) ||
        missing.nativeFirstFieldId.includes(f.id)
      );
      if (fieldIdx >= 0) {
        insertPosition = fieldIdx;
      }
    }

    // If no match found, try to place relative to existing labels
    if (insertPosition === 0 && existingLabels.length > 0) {
      // Find the position of the heading in the native ordering
      const nativeIdx = allHeadings.indexOf(missing.text);
      if (nativeIdx >= 0) {
        // Find the nearest preceding existing label
        for (let i = nativeIdx - 1; i >= 0; i--) {
          const prevHeading = normalizeText(allHeadings[i]);
          const prevLabel = existingLabels.find(l => normalizeText(l.label) === prevHeading);
          if (prevLabel) {
            // Insert after the previous label's position + its field group
            insertPosition = prevLabel.position + 1;
            break;
          }
        }
      }
    }

    // If still 0 and we have fields, place at beginning
    if (insertPosition === 0 && v2Fields.length > 0) {
      // Default: insert at beginning or end depending on heading position
      const nativeIdx = allHeadings.indexOf(missing.text);
      if (nativeIdx > 0) {
        // Not the first heading, place near the end
        insertPosition = Math.min(v2Fields.length, Math.floor(v2Fields.length * (nativeIdx / allHeadings.length)));
      }
    }

    return {
      text: missing.text,
      insertPosition,
      fieldsAfter: missing.fieldsAfter,
    };
  });
}

main();
