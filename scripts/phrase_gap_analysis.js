/**
 * Phrase Gap Analysis Script
 *
 * Identifies all inspection & valuation screens without phrase engine coverage,
 * classifies each by field pattern, and writes a gap report.
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

// ── 1. Extract all screen IDs + fields from the inspection tree ───────────

function extractScreens(treePath) {
  const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
  const screens = [];
  function walk(node) {
    if (node.type === 'screen') {
      screens.push({
        id: node.id,
        title: node.title || '',
        fields: (node.fields || []).map(f => ({
          id: f.id,
          type: f.type,
          label: f.label || '',
          options: f.options || [],
        })),
      });
    }
    if (node.nodes) node.nodes.forEach(walk);
    if (node.children) node.children.forEach(walk);
  }
  if (tree.sections) {
    tree.sections.forEach(section => {
      if (section.nodes) section.nodes.forEach(walk);
    });
  } else if (Array.isArray(tree)) {
    tree.forEach(walk);
  } else {
    walk(tree);
  }
  return screens;
}

// ── 2. Extract case IDs from a Dart phrase engine file ────────────────────

function extractCaseIds(dartPath) {
  const src = fs.readFileSync(dartPath, 'utf8');
  const ids = new Set();
  const caseRe = /case\s+'([^']+)'/g;
  let m;
  while ((m = caseRe.exec(src)) !== null) {
    ids.add(m[1]);
  }
  return ids;
}

// ── 3. Extract dynamic prefix handlers from inspection engine ─────────────

function extractDynamicPrefixes(dartPath) {
  const src = fs.readFileSync(dartPath, 'utf8');
  const prefixes = [];
  const re = /screenId\.startsWith\('([^']+)'\)/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    prefixes.push(m[1]);
  }
  return prefixes;
}

// ── 4. Classify a screen by its field patterns ────────────────────────────

function classifyScreen(screen) {
  const hasConditionRating = screen.fields.some(f =>
    f.type === 'dropdown' && f.options.length === 3 &&
    f.options.includes('1') && f.options.includes('2') && f.options.includes('3'));

  const hasRepair = screen.fields.some(f =>
    f.type === 'dropdown' &&
    (f.options.some(o => /repair\s+(soon|now)/i.test(o))));

  const hasYesNo = screen.fields.some(f =>
    f.type === 'dropdown' &&
    f.options.length <= 3 &&
    f.options.some(o => /^yes$/i.test(o)) &&
    f.options.some(o => /^no$/i.test(o)));

  const isNotInspected = screen.id.includes('not_inspected');
  const isVariant = screen.id.includes('__');

  const hasMainCondition = screen.fields.some(f =>
    f.type === 'dropdown' &&
    f.options.some(o => /reasonable/i.test(o)));

  const hasCheckboxes = screen.fields.some(f => f.type === 'checkbox');
  const hasText = screen.fields.some(f => f.type === 'text');
  const hasDropdown = screen.fields.some(f => f.type === 'dropdown');
  const hasNumber = screen.fields.some(f => f.type === 'number');

  // Priority classification
  if (isNotInspected) return 'not_inspected';
  if (hasConditionRating) return 'condition_rating';
  if (hasMainCondition) return 'main_condition';
  if (hasRepair) return 'repair';
  if (hasYesNo) return 'yes_no';
  if (isVariant) return 'variant';
  if (hasCheckboxes && hasText) return 'checkbox_text';
  if (hasCheckboxes) return 'checkbox_only';
  if (hasDropdown && hasText) return 'dropdown_text';
  if (hasDropdown) return 'dropdown_only';
  if (hasText) return 'text_only';
  if (hasNumber) return 'number_only';
  return 'other';
}

// ── 5. Section assignment ─────────────────────────────────────────────────

function getSection(screenId) {
  if (screenId.startsWith('activity_party_') ||
      screenId.startsWith('activity_property_') ||
      screenId.startsWith('activity_parking') ||
      screenId.startsWith('activity_front_garden') ||
      screenId.startsWith('activity_rear_garden') ||
      screenId.startsWith('activity_communal_garden') ||
      screenId.startsWith('activity_construction_') ||
      screenId.startsWith('activity_gated_') ||
      screenId.startsWith('activity_energy_') ||
      screenId.startsWith('activity_estate_') ||
      screenId.startsWith('activity_garden') ||
      screenId.startsWith('activity_topography') ||
      screenId.startsWith('activity_internal_wall') ||
      screenId.startsWith('activity_listed_') ||
      screenId.startsWith('activity_other_service') ||
      screenId.startsWith('activity_accommodation_') ||
      screenId.startsWith('activity_extended_')) return 'D';
  if (screenId.startsWith('activity_outside_property_') ||
      screenId.startsWith('outside_property_') ||
      screenId.startsWith('activity_out_side_') ||
      screenId.startsWith('activity_rwg_')) return 'E';
  if (screenId.startsWith('activity_inside_property_') ||
      screenId.startsWith('activity_in_side_property_') ||
      screenId.startsWith('inside_property_')) return 'F';
  if (screenId.startsWith('activity_services_') ||
      screenId.startsWith('activity_service_') ||
      screenId.startsWith('services_') ||
      screenId.startsWith('activity_water_heating_') ||
      screenId.startsWith('activity_main') ||
      screenId.startsWith('activity_services')) return 'G';
  if (screenId.startsWith('activity_grounds_') ||
      screenId.startsWith('activity_other_repair_')) return 'H';
  if (screenId.startsWith('activity_no_of_rooms')) return 'R';
  if (screenId.startsWith('activity_over_all_')) return 'O';
  if (screenId.startsWith('activity_issues_')) return 'I';
  if (screenId.startsWith('activity_risks_')) return 'J';
  return 'unknown';
}

// ── Main ──────────────────────────────────────────────────────────────────

const inspectionTreePath = path.join(ROOT, 'assets/property_inspection/inspection_tree.json');
const inspectionEnginePath = path.join(ROOT, 'lib/features/property_inspection/domain/inspection_phrase_engine.dart');
const valuationTreePath = path.join(ROOT, 'assets/property_valuation/valuation_tree.json');
const valuationEnginePath = path.join(ROOT, 'lib/features/property_valuation/domain/valuation_phrase_engine.dart');

// Inspection
const inspScreens = extractScreens(inspectionTreePath);
const inspCaseIds = extractCaseIds(inspectionEnginePath);
const inspDynamicPrefixes = extractDynamicPrefixes(inspectionEnginePath);

console.log(`Inspection tree screens: ${inspScreens.length}`);
console.log(`Inspection engine case IDs: ${inspCaseIds.size}`);
console.log(`Inspection dynamic prefixes: ${inspDynamicPrefixes.length}`);

const inspUncovered = [];
for (const screen of inspScreens) {
  if (inspCaseIds.has(screen.id)) continue;
  // Check if matched by a dynamic prefix handler
  const matchedByPrefix = inspDynamicPrefixes.some(prefix => screen.id.startsWith(prefix));
  if (matchedByPrefix) continue;
  inspUncovered.push({
    ...screen,
    section: getSection(screen.id),
    classification: classifyScreen(screen),
  });
}

console.log(`Inspection UNCOVERED: ${inspUncovered.length}`);

// Valuation
const valScreens = extractScreens(valuationTreePath);
const valCaseIds = extractCaseIds(valuationEnginePath);

console.log(`\nValuation tree screens: ${valScreens.length}`);
console.log(`Valuation engine case IDs: ${valCaseIds.size}`);

const valUncovered = [];
for (const screen of valScreens) {
  if (valCaseIds.has(screen.id)) continue;
  valUncovered.push({
    ...screen,
    classification: classifyScreen(screen),
  });
}

console.log(`Valuation UNCOVERED: ${valUncovered.length}`);

// Classification summary
const classCounts = {};
for (const s of inspUncovered) {
  classCounts[s.classification] = (classCounts[s.classification] || 0) + 1;
}
console.log('\nInspection classification summary:');
for (const [cls, count] of Object.entries(classCounts).sort((a, b) => b[1] - a[1])) {
  console.log(`  ${cls}: ${count}`);
}

const sectionCounts = {};
for (const s of inspUncovered) {
  sectionCounts[s.section] = (sectionCounts[s.section] || 0) + 1;
}
console.log('\nInspection section summary:');
for (const [sec, count] of Object.entries(sectionCounts).sort((a, b) => b[1] - a[1])) {
  console.log(`  Section ${sec}: ${count}`);
}

// Write report
const report = {
  generated: new Date().toISOString(),
  inspection: {
    totalScreens: inspScreens.length,
    coveredByCase: inspCaseIds.size,
    coveredByDynamic: inspScreens.length - inspUncovered.length - inspCaseIds.size,
    uncoveredCount: inspUncovered.length,
    classificationSummary: classCounts,
    sectionSummary: sectionCounts,
    uncovered: inspUncovered,
  },
  valuation: {
    totalScreens: valScreens.length,
    coveredByCase: valCaseIds.size,
    uncoveredCount: valUncovered.length,
    uncovered: valUncovered,
  },
};

const outPath = path.join(ROOT, 'scripts/phrase_gap_report.json');
fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
console.log(`\nReport written to ${outPath}`);
