/**
 * verify-patches.js
 *
 * Spot-check patched screens for correct label positioning.
 */

const fs = require('fs');
const path = require('path');

const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');

function main() {
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

  const screens = [
    'outside_property_about_roof_layout',
    'activity_service_about_electricity',
    'activity_in_side_property_floors_about_floor',
    'activity_outside_property_main_walls_about_wall',
    'activity_outside_property_out_side_doors_about_doors__timber',
    'inside_property_ceilings_about_ceilings',
    'activity_outside_property_other_joinery_and_finishes_repairs__repairs',
    'activity_grounds_other_front_garden__rear_garden',
    'activity_property_roof',
  ];

  for (const screenId of screens) {
    const screen = findScreen(screenId);
    if (!screen) { console.log(screenId + ': NOT FOUND'); continue; }
    console.log('\n=== ' + screenId + ' (' + screen.title + ') ===');
    screen.fields.forEach((f, i) => {
      if (f.type === 'label') {
        console.log('  ' + i + ': >>> LABEL: "' + f.label + '" [' + f.id + ']');
      } else {
        console.log('  ' + i + ': [' + f.type + '] ' + f.id + ' (' + f.label + ')');
      }
    });
  }

  // Overall stats
  let totalLabels = 0;
  let screensWithLabels = 0;
  let totalScreens = 0;

  function countLabels(node) {
    if (node.type === 'screen' && node.fields) {
      totalScreens++;
      const labels = node.fields.filter(f => f.type === 'label');
      totalLabels += labels.length;
      if (labels.length > 0) screensWithLabels++;
    }
    const kids = node.children || node.nodes || [];
    for (const child of kids) {
      countLabels(child);
    }
  }
  for (const section of tree.sections) {
    for (const node of section.nodes || []) {
      countLabels(node);
    }
  }

  console.log('\n=== FINAL STATS ===');
  console.log('Total screens:', totalScreens);
  console.log('Screens with labels:', screensWithLabels, '(' + ((screensWithLabels/totalScreens)*100).toFixed(1) + '%)');
  console.log('Total label fields:', totalLabels);
}

main();
