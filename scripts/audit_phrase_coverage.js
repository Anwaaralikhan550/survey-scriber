/**
 * Audit phrase engine coverage gaps.
 *
 * Identifies all screens in the V2 tree that:
 * 1. Have at least 1 data field (non-label)
 * 2. Don't have a matching case in the phrase engine switch statement
 * 3. Aren't covered by _matchDynamicSectionE prefix matching
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const enginePath = path.join(__dirname, '..', 'lib', 'features', 'inspection_v2', 'domain', 'inspection_v2_phrase_engine.dart');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const engineSource = fs.readFileSync(enginePath, 'utf8');

// Extract all case strings from the switch statement
const caseRegex = /case '([^']+)':/g;
const coveredScreens = new Set();
let caseMatch;
while ((caseMatch = caseRegex.exec(engineSource)) !== null) {
  coveredScreens.add(caseMatch[1]);
}

// Extract dynamic prefix matches
const dynamicPrefixes = [];
const prefixRegex = /screenId\.startsWith\('([^']+)'\)/g;
let prefixMatch;
while ((prefixMatch = prefixRegex.exec(engineSource)) !== null) {
  dynamicPrefixes.push(prefixMatch[1]);
}

console.log(`Switch cases: ${coveredScreens.size}`);
console.log(`Dynamic prefixes: ${dynamicPrefixes.length}`);

// Find all screens with data fields
const allScreens = [];
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.type !== 'screen') continue;
    const dataFields = (node.fields || []).filter(f => f.type !== 'label');
    if (dataFields.length === 0) continue;
    allScreens.push({
      id: node.id,
      section: section.key,
      title: node.title,
      dataFieldCount: dataFields.length,
      fieldTypes: [...new Set(dataFields.map(f => f.type))],
    });
  }
}

// Check coverage
const uncovered = [];
for (const screen of allScreens) {
  // Check exact case match
  if (coveredScreens.has(screen.id)) continue;

  // Check dynamic prefix match
  const hasDynamicMatch = dynamicPrefixes.some(p => screen.id.startsWith(p));
  if (hasDynamicMatch) continue;

  uncovered.push(screen);
}

console.log(`\nTotal data-entry screens: ${allScreens.length}`);
console.log(`Covered: ${allScreens.length - uncovered.length}`);
console.log(`Uncovered: ${uncovered.length}\n`);

// Group by section
const bySection = {};
for (const s of uncovered) {
  if (!bySection[s.section]) bySection[s.section] = [];
  bySection[s.section].push(s);
}

for (const [section, screens] of Object.entries(bySection)) {
  console.log(`\n=== Section ${section} (${screens.length} uncovered) ===`);
  for (const s of screens) {
    console.log(`  ${s.id}`);
    console.log(`    "${s.title}" | ${s.dataFieldCount} fields | types: ${s.fieldTypes.join(', ')}`);
  }
}

// Output JSON
const outputPath = path.join(__dirname, 'audit_phrase_coverage_results.json');
fs.writeFileSync(outputPath, JSON.stringify(uncovered, null, 2));
console.log(`\nResults saved to ${outputPath}`);
