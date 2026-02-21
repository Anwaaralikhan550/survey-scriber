/**
 * Fix Final 13 Invalid Options
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

console.log('='.repeat(100));
console.log('FIXING FINAL 13 INVALID OPTIONS');
console.log('='.repeat(100));

const fixes = {
  // conservatory_porch - Excel: "Location, construction", "Roof", "Doors", "Windows", "Floor"
  "conservatory_present": {
    "optionMappings": {
      "None": "Floor",
      "Conservatory": "Location, construction",
      "Porch": "Location, construction",
      "Both": "Location, construction",
      "Unknown": "Floor"
    },
    "confidence": "high"
  },

  // insulation - Excel: Ok, OK, Inadequate, Damp noted
  "loft_accessed": {
    "optionMappings": {
      "Yes": "OK",
      "No": "Inadequate",
      "Limited": "OK",
      "Not Possible": "Inadequate",
      "Unknown": "Inadequate"
    },
    "confidence": "high"
  },

  // doors - Excel: "replacement, type, glazing, patio"
  "damaged_locks": {
    "optionMappings": {
      "None": "replacement, type, glazing, patio",
      "Some": "replacement, type, glazing, patio",
      "Unknown": "replacement, type, glazing, patio"
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

console.log(`\n✅ Fixed ${fixedCount} fields with corrected Excel options`);
console.log(`📄 Saved to: ${mappingFile}`);
console.log('='.repeat(100));
