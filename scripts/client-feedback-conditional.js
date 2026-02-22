#!/usr/bin/env node
/**
 * Client feedback fixes — Conditional logic for Property Converted
 * Run: node scripts/client-feedback-conditional.js
 */
const fs = require('fs');
const path = require('path');

const TREE_PATH = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');
const tree = JSON.parse(fs.readFileSync(TREE_PATH, 'utf-8'));

let changeCount = 0;

// Find the Property Converted screen
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.id === 'activity_property_converted') {
      console.log(`Found Property Converted screen: ${node.title}`);

      // Status dropdown is android_material_design_spinner
      // Property Type = android_material_design_spinner2 — show when Known or Unknown (i.e., hide when "Not converted")
      // Sub Type = android_material_design_spinner3 — show when Known or Unknown
      // Year converted = textView3 — show ONLY when Known

      const propertyType = node.fields.find(f => f.id === 'android_material_design_spinner2');
      const subType = node.fields.find(f => f.id === 'android_material_design_spinner3');
      const otherText = node.fields.find(f => f.id === 'etOther');
      const yearConverted = node.fields.find(f => f.id === 'textView3');

      if (propertyType) {
        propertyType.conditionalOn = 'android_material_design_spinner';
        propertyType.conditionalValue = 'Not converted';
        propertyType.conditionalMode = 'hide';
        console.log(`  Added conditional: Property Type hidden when "Not converted"`);
        changeCount++;
      }

      if (subType) {
        subType.conditionalOn = 'android_material_design_spinner';
        subType.conditionalValue = 'Not converted';
        subType.conditionalMode = 'hide';
        console.log(`  Added conditional: Sub Type hidden when "Not converted"`);
        changeCount++;
      }

      if (otherText) {
        // Other text should show when Sub Type = "Other" AND status is not "Not converted"
        // But conditional logic only supports one condition. Keep existing behavior for now.
        // The Sub Type dropdown itself is hidden when "Not converted", so this is fine.
      }

      if (yearConverted) {
        yearConverted.conditionalOn = 'android_material_design_spinner';
        yearConverted.conditionalValue = 'Known';
        yearConverted.conditionalMode = 'show';
        console.log(`  Added conditional: Year converted shown ONLY when "Known"`);
        changeCount++;
      }

      break;
    }
  }
}

fs.writeFileSync(TREE_PATH, JSON.stringify(tree, null, 2) + '\n', 'utf-8');
console.log(`\nDone! Applied ${changeCount} conditional logic changes.`);
