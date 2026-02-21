/**
 * extract-v2-labels.js
 *
 * Parses the V2 inspection tree JSON and extracts all existing
 * "type": "label" fields per screen.
 *
 * Output: v2_labels.json — { screenId: { title, labels, fieldCount, allFieldLabels } }
 */

const fs = require('fs');
const path = require('path');

const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');
const OUTPUT_FILE = path.join(__dirname, 'v2_labels.json');

function main() {
  console.log('Loading V2 inspection tree...');
  const tree = JSON.parse(fs.readFileSync(TREE_FILE, 'utf8'));

  const result = {};
  let totalLabels = 0;
  let screensWithLabels = 0;
  let totalScreens = 0;

  // Walk nodes recursively — handles both `children` and `nodes` arrays
  function walkNode(node) {
    if (node.type === 'screen' && node.fields && node.fields.length > 0) {
      totalScreens++;
      const labels = [];

      node.fields.forEach((field, index) => {
        if (field.type === 'label') {
          labels.push({
            id: field.id,
            label: field.label,
            position: index,
            totalFields: node.fields.length,
          });
        }
      });

      result[node.id] = {
        title: node.title || node.label || '',
        labels: labels,
        fieldCount: node.fields.length,
        allFieldLabels: node.fields.map(f => ({
          id: f.id,
          label: f.label,
          type: f.type,
        })),
      };

      if (labels.length > 0) {
        screensWithLabels++;
        totalLabels += labels.length;
      }
    }

    // Recurse into children/nodes
    const kids = node.children || node.nodes || [];
    for (const child of kids) {
      walkNode(child);
    }
  }

  // Tree format: { sections: [ { key, title, nodes: [...] } ] }
  if (tree.sections) {
    for (const section of tree.sections) {
      // Each section has `nodes` array
      const nodes = section.nodes || section.children || [];
      for (const node of nodes) {
        walkNode(node);
      }
    }
  } else if (Array.isArray(tree)) {
    for (const node of tree) {
      walkNode(node);
    }
  } else {
    walkNode(tree);
  }

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(result, null, 2));

  console.log('\n=== RESULTS ===');
  console.log(`Total screens: ${totalScreens}`);
  console.log(`Screens with labels: ${screensWithLabels} (${((screensWithLabels/totalScreens)*100).toFixed(1)}%)`);
  console.log(`Screens without labels: ${totalScreens - screensWithLabels} (${(((totalScreens-screensWithLabels)/totalScreens)*100).toFixed(1)}%)`);
  console.log(`Total label fields: ${totalLabels}`);
  console.log(`Output: ${OUTPUT_FILE}`);

  // Print top screens without labels by field count (candidates for adding)
  const noLabelScreens = Object.entries(result)
    .filter(([_, data]) => data.labels.length === 0 && data.fieldCount >= 3)
    .sort((a, b) => b[1].fieldCount - a[1].fieldCount);

  console.log(`\nScreens without labels (3+ fields): ${noLabelScreens.length}`);
  for (const [id, data] of noLabelScreens.slice(0, 30)) {
    console.log(`  ${data.fieldCount} fields: ${id} (${data.title})`);
  }
}

main();
