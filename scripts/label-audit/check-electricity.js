const fs = require('fs');
const path = require('path');

const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');
const LAYOUT_DIR = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/layout');
const STRINGS_FILE = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml');

const tree = JSON.parse(fs.readFileSync(TREE_FILE, 'utf8'));

function findScreen(id) {
  for (const section of tree.sections) {
    for (const node of section.nodes || []) {
      const found = walk(node, id);
      if (found) return found;
    }
  }
  return null;
}
function walk(node, id) {
  if (node.id === id) return node;
  for (const child of node.children || node.nodes || []) {
    const f = walk(child, id);
    if (f) return f;
  }
  return null;
}

// Check electricity screen
const screen = findScreen('activity_service_about_electricity');
const fields = screen.fields;
const labels = fields.filter(f => f.type === 'label');
const nonLabels = fields.filter(f => f.type !== 'label');

console.log('Total fields:', fields.length);
console.log('Labels:', labels.length);
console.log('Non-labels:', nonLabels.length);
console.log();

labels.forEach(l => {
  const idx = fields.indexOf(l);
  console.log('  Label at pos', idx, ':', l.label, '(' + l.id + ')');
});

// Check: Find screens where ALL labels are clustered at the end
console.log('\n\n=== SCREENS WITH LABELS CLUSTERED AT END ===\n');
let found = 0;

function checkAllScreens(node) {
  if (node.type === 'screen' && node.fields && node.fields.length > 0) {
    const allLabels = node.fields.filter(f => f.type === 'label');
    if (allLabels.length === 0) return;

    const allNonLabels = node.fields.filter(f => f.type !== 'label');
    if (allNonLabels.length === 0) return;

    // Get positions of labels
    const labelPositions = allLabels.map(l => node.fields.indexOf(l));
    const minLabelPos = Math.min(...labelPositions);

    // Get positions of non-labels
    const nonLabelPositions = allNonLabels.map(l => node.fields.indexOf(l));
    const maxNonLabelPos = Math.max(...nonLabelPositions);

    // If all labels come after all non-labels, they're clustered at end
    if (minLabelPos > maxNonLabelPos) {
      found++;
      console.log(`${node.id} (${node.title}): ${allLabels.length} labels at end (pos ${minLabelPos}-${Math.max(...labelPositions)}) after ${allNonLabels.length} fields`);
    }
  }
  const kids = node.children || node.nodes || [];
  for (const child of kids) {
    checkAllScreens(child);
  }
}

for (const section of tree.sections) {
  for (const node of section.nodes || []) {
    checkAllScreens(node);
  }
}

console.log(`\nTotal screens with all labels at end: ${found}`);
