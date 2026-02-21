/**
 * Fix Last 6 Low Confidence Fields
 * Chimney and roof component fields
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

console.log('='.repeat(100));
console.log('FIXING LAST 6 LOW CONFIDENCE FIELDS');
console.log('='.repeat(100));

const fixes = {
  // removed_chimney_breast - Excel: "Not inspected"
  "removed_chimney_breast": {
    "optionMappings": {
      "None": "Not inspected",
      "Ground Floor": "Not inspected",
      "First Floor": "Not inspected",
      "Multiple Floors": "Not inspected",
      "Unknown": "Not inspected"
    },
    "confidence": "high"
  },

  // leaning_chimney - Excel: Ok, Repair soon, Multiple Stacks, Location, Number of Pots, Rendering, Waterproofing
  "chimney_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Ok",
      "Leaning": "Repair soon",
      "Poor": "Repair soon",
      "Very Poor": "Repair soon",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  // chimney_pots_repair_soon - Excel: "Chimney                Defect"
  "chimney_pots": {
    "optionMappings": {
      "Good": "Chimney                Defect",
      "Replace Soon": "Chimney                Defect",
      "Immediate": "Chimney                Defect"
    },
    "confidence": "high"
  },

  // flaunching_repair_soon - Excel: "Chimney                Defect"
  "flaunching_condition": {
    "optionMappings": {
      "Good": "Chimney                Defect",
      "Replace Soon": "Chimney                Defect",
      "Immediate": "Chimney                Defect"
    },
    "confidence": "high"
  },

  // flashing_repair_soon - Excel: "Chimney                Defect"
  "flashing_condition": {
    "optionMappings": {
      "Good": "Chimney                Defect",
      "Replace Soon": "Chimney                Defect",
      "Immediate": "Chimney                Defect",
      "New": "Chimney                Defect"
    },
    "confidence": "high"
  },

  // ariel_dish_repair_soon - Excel: "Type                Defect"
  "aerial_dish_condition": {
    "optionMappings": {
      "Good": "Type                Defect",
      "Replace Soon": "Type                Defect",
      "Immediate": "Type                Defect"
    },
    "confidence": "high"
  }
};

// Apply fixes
let fixedCount = 0;
Object.entries(fixes).forEach(([key, updates]) => {
  if (mappings[key]) {
    Object.assign(mappings[key], updates);
    fixedCount++;
  }
});

// Save
fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log(`\n✅ Fixed last ${fixedCount} low confidence fields`);
console.log(`📄 Saved to: ${mappingFile}`);
console.log('='.repeat(100));
