/**
 * Check what children exist under the gas_and_oil group in V2,
 * and whether the 7 unmatched NAV_HEADINGs are navigation to
 * sub-screens that exist elsewhere in the tree.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

// Build lookup
const nodeById = {};
const childrenOf = {};
for (const section of tree.sections) {
  for (const node of section.nodes) {
    nodeById[node.id] = { ...node, sectionKey: section.key };
    const pid = node.parentId;
    if (pid) {
      if (!childrenOf[pid]) childrenOf[pid] = [];
      childrenOf[pid].push(node);
    }
  }
}

// Find group_gas_and_oil_89 and show its tree
function showTree(id, depth) {
  const node = nodeById[id];
  const indent = '  '.repeat(depth);
  const fieldCount = node.fields ? node.fields.length : 0;
  const inlinePos = node.inlinePosition ? ` [inline:${node.inlinePosition}]` : '';
  console.log(`${indent}${node.type}: "${node.title || node.id}" (${id})${inlinePos} [${fieldCount} fields]`);
  const children = childrenOf[id] || [];
  for (const child of children) {
    showTree(child.id, depth + 1);
  }
}

console.log('=== Gas and Oil tree (G2) ===');
showTree('group_g2_gas_and_oil_88', 0);

console.log('\n=== Chimney tree (E1) ===');
showTree('group_e1_chimney_5', 0);

// Search for screens with these heading texts anywhere
const searchTerms = ['No.of pots', 'Rendering', 'Waterproofing', 'Shared Chimney', 'Leaning Chimney', 'Other Joinery finishes'];
console.log('\n=== Searching for matching screen/group titles ===');
for (const term of searchTerms) {
  const matches = [];
  for (const section of tree.sections) {
    for (const node of section.nodes) {
      if (node.title && node.title.toLowerCase().includes(term.toLowerCase())) {
        matches.push(`[${section.key}] ${node.type}:${node.id} "${node.title}"`);
      }
    }
  }
  if (matches.length > 0) {
    console.log(`"${term}" -> ${matches.join(', ')}`);
  } else {
    console.log(`"${term}" -> NO MATCH in V2 tree`);
  }
}

// Also check if these headings exist in the chimney XML
console.log('\n=== Check chimney_main_screen native structure ===');
const ns = JSON.parse(fs.readFileSync(path.join(__dirname, 'native-inspection-structure.json'), 'utf8'));
const chimneyNative = ns['activity_outside_property_chimney_main_screen'];
if (chimneyNative) {
  for (const e of chimneyNative) {
    console.log(`  ${e.type}: ${e.text || e.id}`);
  }
}
