/**
 * Phrase Coverage Verification Script
 *
 * Re-runs the gap analysis and asserts 100% coverage for both engines.
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

// ── Helpers (duplicated from gap analysis for standalone usage) ───────────

function extractScreens(treePath) {
  const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
  const screens = [];
  function walk(node) {
    if (node.type === 'screen') {
      screens.push({ id: node.id, title: node.title || '' });
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

// ── Paths ─────────────────────────────────────────────────────────────────

const inspectionTreePath = path.join(ROOT, 'assets/property_inspection/inspection_tree.json');
const inspectionEnginePath = path.join(ROOT, 'lib/features/property_inspection/domain/inspection_phrase_engine.dart');
const valuationTreePath = path.join(ROOT, 'assets/property_valuation/valuation_tree.json');
const valuationEnginePath = path.join(ROOT, 'lib/features/property_valuation/domain/valuation_phrase_engine.dart');

// ── Inspection ────────────────────────────────────────────────────────────

const inspScreens = extractScreens(inspectionTreePath);
const inspCaseIds = extractCaseIds(inspectionEnginePath);
const inspDynamicPrefixes = extractDynamicPrefixes(inspectionEnginePath);

const inspUncovered = [];
for (const screen of inspScreens) {
  if (inspCaseIds.has(screen.id)) continue;
  const matchedByPrefix = inspDynamicPrefixes.some(prefix => screen.id.startsWith(prefix));
  if (matchedByPrefix) continue;
  inspUncovered.push(screen);
}

// ── Valuation ─────────────────────────────────────────────────────────────

const valScreens = extractScreens(valuationTreePath);
const valCaseIds = extractCaseIds(valuationEnginePath);

const valUncovered = [];
for (const screen of valScreens) {
  if (valCaseIds.has(screen.id)) continue;
  valUncovered.push(screen);
}

// ── Report ────────────────────────────────────────────────────────────────

let exitCode = 0;

console.log('=== Phrase Coverage Verification ===\n');

const inspCoveredByCase = inspCaseIds.size;
const inspCoveredByDynamic = inspScreens.length - inspUncovered.length - inspCoveredByCase;
const inspTotal = inspScreens.length;
const inspCovered = inspTotal - inspUncovered.length;

console.log(`Inspection: ${inspCovered}/${inspTotal} screens covered`);
console.log(`  - By switch/case: ${inspCoveredByCase}`);
console.log(`  - By dynamic prefix: ${inspCoveredByDynamic}`);
if (inspUncovered.length > 0) {
  console.log(`  - UNCOVERED (${inspUncovered.length}):`);
  inspUncovered.forEach(s => console.log(`    - ${s.id} (${s.title})`));
  exitCode = 1;
} else {
  console.log('  - PASS: All screens covered');
}

console.log('');

const valTotal = valScreens.length;
const valCovered = valTotal - valUncovered.length;

console.log(`Valuation: ${valCovered}/${valTotal} screens covered`);
console.log(`  - By switch/case: ${valCaseIds.size}`);
if (valUncovered.length > 0) {
  console.log(`  - UNCOVERED (${valUncovered.length}):`);
  valUncovered.forEach(s => console.log(`    - ${s.id} (${s.title})`));
  exitCode = 1;
} else {
  console.log('  - PASS: All screens covered');
}

console.log('');
if (exitCode === 0) {
  console.log('RESULT: 100% phrase coverage achieved');
} else {
  console.log('RESULT: FAIL — some screens lack coverage');
}

process.exit(exitCode);
