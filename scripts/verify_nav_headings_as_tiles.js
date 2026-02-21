/**
 * Verify that each NAV_HEADING from native is represented as a child
 * node (group or screen tile) in the V2 tree.
 *
 * NAV_HEADINGs are headings NOT followed by fields — they're navigation
 * elements in native that should correspond to tree nodes in V2.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const nativeStructurePath = path.join(__dirname, 'native-inspection-structure.json');

const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));
const nativeStructure = JSON.parse(fs.readFileSync(nativeStructurePath, 'utf8'));

function normalize(text) {
  return (text || '').toLowerCase().replace(/\s+/g, ' ').replace(/[:.,;!?]+$/, '').trim();
}

function textsMatch(a, b) {
  const na = normalize(a);
  const nb = normalize(b);
  if (na === nb) return true;
  if (na.length > 3 && nb.length > 3) {
    if (na.includes(nb) || nb.includes(na)) return true;
  }
  return false;
}

// Build parent→children map from the tree
const childrenOf = {};
const nodeById = {};
for (const section of tree.sections) {
  for (const node of section.nodes) {
    nodeById[node.id] = node;
    const pid = node.parentId;
    if (pid) {
      if (!childrenOf[pid]) childrenOf[pid] = [];
      childrenOf[pid].push(node);
    }
  }
}

// Find the parent group for each screen
function findParentGroup(screenId) {
  const node = nodeById[screenId];
  if (!node) return null;
  return node.parentId;
}

// For each screen with NAV_HEADINGs, check if those headings
// correspond to sibling/child tiles
let totalNavHeadings = 0;
let matchedAsTiles = 0;
let notMatchedAsTiles = 0;
const unmatched = [];

for (const [screenId, native] of Object.entries(nativeStructure)) {
  if (!nodeById[screenId]) continue;

  // Find NAV_HEADINGs (headings NOT followed by a field before the next heading)
  const navHeadings = [];
  for (let i = 0; i < native.length; i++) {
    if (native[i].type !== 'heading') continue;
    let hasFieldAfter = false;
    for (let j = i + 1; j < native.length; j++) {
      if (native[j].type === 'heading') break;
      if (native[j].type === 'field') { hasFieldAfter = true; break; }
    }
    if (!hasFieldAfter) {
      navHeadings.push(native[i].text);
    }
  }

  if (navHeadings.length === 0) continue;

  // Get the parent group of this screen, then find siblings and children
  const parentId = findParentGroup(screenId);
  const siblings = parentId ? (childrenOf[parentId] || []) : [];
  const children = childrenOf[screenId] || [];

  // Also check children of the parent's parent (for inline headers)
  const grandparentId = parentId ? (nodeById[parentId] || {}).parentId : null;
  const uncles = grandparentId ? (childrenOf[grandparentId] || []) : [];

  // Collect all nearby tile titles for matching
  const tileTexts = [];
  for (const n of [...siblings, ...children, ...uncles]) {
    if (n.title) tileTexts.push(normalize(n.title));
  }

  for (const nh of navHeadings) {
    totalNavHeadings++;
    const nhNorm = normalize(nh);

    // Check if any nearby tile matches this heading
    const matched = tileTexts.some(t => textsMatch(t, nh));
    if (matched) {
      matchedAsTiles++;
    } else {
      notMatchedAsTiles++;
      unmatched.push({ screenId, heading: nh, parentId });
    }
  }
}

console.log('=== NAV_HEADING → TILE VERIFICATION ===');
console.log(`Total NAV_HEADINGs: ${totalNavHeadings}`);
console.log(`Matched as tiles:   ${matchedAsTiles}`);
console.log(`NOT matched:        ${notMatchedAsTiles}`);

if (unmatched.length > 0) {
  console.log('\n--- Unmatched NAV_HEADINGs ---');
  for (const u of unmatched) {
    console.log(`  [${u.screenId}] "${u.heading}" (parent: ${u.parentId})`);
  }
}

if (notMatchedAsTiles === 0) {
  console.log('\n[PASS] All NAV_HEADINGs are represented as tree tiles in V2');
} else {
  console.log(`\n[INFO] ${notMatchedAsTiles} NAV_HEADINGs need investigation`);
}
