const fs = require('fs');
const path = require('path');

const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');

const tree = JSON.parse(fs.readFileSync(TREE_FILE, 'utf8'));
console.log('JSON is valid');
console.log('Sections:', tree.sections.length);

let screens = 0, labels = 0, fields = 0, errors = 0;
const screensWithLabels = new Set();

function walk(node) {
  if (node.type === 'screen' && node.fields) {
    screens++;
    let hasLabel = false;
    for (const f of node.fields) {
      fields++;
      if (f.type === 'label') {
        labels++;
        hasLabel = true;
      }
      if (!f.id || !f.type) {
        console.error('INVALID FIELD:', JSON.stringify(f));
        errors++;
      }
      if (!f.label && f.type !== 'label') {
        // Non-label fields should have labels (labels always have labels)
      }
    }
    if (hasLabel) screensWithLabels.add(node.id);
  }
  for (const child of node.children || node.nodes || []) {
    walk(child);
  }
}

for (const section of tree.sections) {
  for (const node of section.nodes || []) {
    walk(node);
  }
}

console.log('Screens:', screens);
console.log('Total fields:', fields);
console.log('Label fields:', labels);
console.log('Non-label fields:', fields - labels);
console.log('Screens with labels:', screensWithLabels.size, '(' + ((screensWithLabels.size/screens)*100).toFixed(1) + '%)');
console.log('Validation errors:', errors);

// Check for duplicate field IDs within each screen
let dupScreens = 0;
function checkDups(node) {
  if (node.type === 'screen' && node.fields) {
    const ids = node.fields.map(f => f.id);
    const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
    if (dupes.length > 0) {
      console.log('  DUPLICATE IDs in', node.id, ':', [...new Set(dupes)].join(', '));
      dupScreens++;
    }
  }
  for (const child of node.children || node.nodes || []) {
    checkDups(child);
  }
}
for (const section of tree.sections) {
  for (const node of section.nodes || []) {
    checkDups(node);
  }
}
console.log('Screens with duplicate field IDs:', dupScreens);
