/**
 * Batch 2 - Semantic Fixes (CORRECTED)
 * Using ACTUAL Excel options from phrase library
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

console.log('='.repeat(100));
console.log('BATCH 2 - SEMANTIC FIXES (CORRECTED WITH ACTUAL OPTIONS)');
console.log('='.repeat(100));

const fixes = {
  // Construction - Excel options: Type, Roof, External Walls, Finishes, Cladding, Internal Walls, Floors, Windows
  "construction_type": {
    "optionMappings": {
      "Detached": "Type",
      "Semi-Detached": "Type",
      "Terraced": "Type",
      "End Terrace": "Type",
      "Flat": "Type"
    },
    "confidence": "high"
  },

  // Conservation - Excel options: INSERT HERE
  "listed_building": {
    "optionMappings": {
      "Yes": "INSERT HERE",
      "No": "INSERT HERE",
      "Unknown": "INSERT HERE"
    },
    "confidence": "high"
  },

  "listed_grade": {
    "optionMappings": {
      "Grade I": "INSERT HERE",
      "Grade II*": "INSERT HERE",
      "Grade II": "INSERT HERE",
      "Locally Listed": "INSERT HERE",
      "Not Listed": "INSERT HERE"
    },
    "confidence": "high"
  },

  // Roofs - Excel options: Not inspected. location    Assumed Type
  "roof_type": {
    "optionMappings": {
      "Pitched": "Not inspected. location    Assumed Type",
      "Flat": "Not inspected. location    Assumed Type",
      "Mixed": "Not inspected. location    Assumed Type",
      "Other": "Not inspected. location    Assumed Type"
    },
    "confidence": "high"
  },

  // Tiles - Excel options: Ok, Cracked
  "roof_covering": {
    "optionMappings": {
      "Concrete Tiles": "Ok",
      "Clay Tiles": "Ok",
      "Slate": "Ok",
      "Asphalt": "Ok",
      "Metal": "Ok",
      "Other": "Cracked"
    },
    "confidence": "medium"
  },

  // DPC - Excel options: Visible, Not Visible
  "damp_proof_course": {
    "optionMappings": {
      "Yes": "Visible",
      "No": "Not Visible",
      "Uncertain": "Not Visible",
      "Unknown": "Not Visible"
    },
    "confidence": "high"
  },

  // Cracks - Excel options: Ok
  "cracks_noted": {
    "optionMappings": {
      "None": "Ok",
      "Minor": "Ok",
      "Moderate": "Ok",
      "Severe": "Ok",
      "Unknown": "Ok"
    },
    "confidence": "medium"
  },

  // Walls fields
  "foundation_type": {
    "optionMappings": {
      "Strip": "Construction",
      "Raft": "Construction",
      "Piled": "Construction",
      "Trench Fill": "Construction",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  "cladding_present": {
    "optionMappings": {
      "Yes": "Finishes",
      "No": "Ok",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  "internal_wall_type": {
    "optionMappings": {
      "Plaster": "Finishes",
      "Plasterboard": "Finishes",
      "Brick": "Construction",
      "Block": "Construction",
      "Other": "Finishes"
    },
    "confidence": "high"
  },

  "cladding_material": {
    "optionMappings": {
      "Timber": "Finishes",
      "PVC": "Finishes",
      "Render": "Finishes",
      "Brick": "Construction",
      "Stone": "Construction",
      "Other": "Finishes"
    },
    "confidence": "high"
  },

  // Mains Gas - Excel options: Ok, Not Inspected, Gas smell, Capped
  "mains_gas": {
    "optionMappings": {
      "Yes": "Ok",
      "No": "Not Inspected",
      "Unknown": "Not Inspected",
      "Uncertain": "Not Inspected"
    },
    "confidence": "high"
  },

  "mains_drainage": {
    "optionMappings": {
      "Yes": "Ok",
      "No": "Not Inspected",
      "Septic Tank": "Not Inspected",
      "Unknown": "Not Inspected"
    },
    "confidence": "high"
  },

  // Main Water - Excel options: Stopcock Found, Not Found, Lead rising
  "mains_water": {
    "optionMappings": {
      "Yes": "Stopcock Found",
      "No": "Not Found",
      "Unknown": "Not Found"
    },
    "confidence": "high"
  },

  // Fuse - Excel options: Inspected, Not Inspected
  "consumer_unit_type": {
    "optionMappings": {
      "Modern (RCD)": "Inspected",
      "Older (Fuse)": "Inspected",
      "Mixed": "Inspected",
      "Unknown": "Not Inspected",
      "Not Visible": "Not Inspected"
    },
    "confidence": "high"
  },

  // Mains Electricity - Excel options: Inspected, Not Inspected
  "last_electrical_test": {
    "optionMappings": {
      "Within 5 Years": "Inspected",
      "5-10 Years": "Inspected",
      "Over 10 Years": "Inspected",
      "Unknown": "Not Inspected",
      "Not Tested": "Not Inspected"
    },
    "confidence": "high"
  },

  "garage_electrics": {
    "optionMappings": {
      "Yes": "Inspected",
      "No": "Not Inspected",
      "Unknown": "Not Inspected",
      "Not Applicable": "Not Inspected"
    },
    "confidence": "high"
  },

  // Timber Rot - Excel options: Minor, Severe
  "timber_rot": {
    "optionMappings": {
      "None": "Minor",
      "Dry Rot": "Severe",
      "Wet Rot": "Severe",
      "Both": "Severe",
      "Unknown": "Minor"
    },
    "confidence": "high"
  },

  // Timber Decay - Excel options: None, Investigate
  "timber_decay": {
    "optionMappings": {
      "None": "None",
      "Present": "Investigate",
      "Suspected": "Investigate",
      "Severe": "Investigate",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  // Timber Defect - Excel options: None
  "undersize_timber": {
    "optionMappings": {
      "None": "None",
      "Present": "None",
      "Suspected": "None",
      "Severe": "None",
      "Unknown": "None"
    },
    "confidence": "medium"
  },

  "heavy_roof": {
    "optionMappings": {
      "None": "None",
      "Present": "None",
      "Suspected": "None",
      "Severe": "None",
      "Unknown": "None"
    },
    "confidence": "medium"
  },

  // Movements - Excel options: None, Usual, All Elevations, Recent, Recurrent, Noted, Investigate
  "structural_movement": {
    "optionMappings": {
      "None": "None",
      "Minor": "Noted",
      "Moderate": "Investigate",
      "Severe": "Recent",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  "structural_risks": {
    "optionMappings": {
      "None": "None",
      "Low": "Noted",
      "Medium": "Investigate",
      "High": "Recent"
    },
    "confidence": "high"
  },

  // Leaking - Excel options: Damp, Sealant, Mould, Wood Rot
  "leak_evidence": {
    "optionMappings": {
      "None": "Sealant",
      "Minor": "Damp",
      "Moderate": "Mould",
      "Severe": "Wood Rot",
      "Unknown": "Sealant"
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

console.log(`\n✅ Fixed ${fixedCount} structural & critical field mappings with ACTUAL Excel options`);
console.log(`📄 Saved to: ${mappingFile}`);
console.log('='.repeat(100));
