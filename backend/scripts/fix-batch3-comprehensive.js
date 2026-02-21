/**
 * Batch 3 - Comprehensive Fixes
 * Roof components, heating, windows, chimneys, and remaining critical fields
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('BATCH 3 - COMPREHENSIVE SEMANTIC FIXES');
console.log('='.repeat(100));

// Helper to get actual Excel options
function getExcelOptions(field) {
  if (phraseLibrary[field]) {
    return Object.keys(phraseLibrary[field].options);
  }
  return [];
}

// Show options for fields we're fixing
console.log('\nChecking Excel options for fields:\n');
[
  'gas_heating', 'boiler_flue', 'cylinder', 'water_tank', 'radiators',
  'roof_structure', 'removed_chimney_breast', 'party_walls', 'insect_infestation',
  'windows', 'window_sills', 'doors', 'pointing', 'render', 'spalling',
  'movement_cracks', 'leaning_chimney', 'chimney_pots_repair_soon',
  'flaunching_repair_soon', 'flashing_repair_soon', 'ridge_tiles',
  'verge_repair', 'flat_roof_repair', 'parapet_wall_repair',
  'ariel_dish_repair_soon', 'valley_gutters_repair', 'blocked_fireplace',
  'conversion', 'conservatory_porch', 'juliet_balcony',
  'no_fire_escape_risk', 'safety_glass_rating', 'safety_hazard',
  'property_status', 'year_built', 'year_extended', 'nearby_trees',
  'hazard', 'dampness'
].forEach(field => {
  const opts = getExcelOptions(field);
  if (opts.length > 0) {
    console.log(`${field}: ${opts.join(', ')}`);
  }
});

const fixes = {
  // Gas Heating - Excel options: Type, Fuel, Full/Part, Age, Service, Flue
  "heating_type": {
    "optionMappings": {
      "Gas Central": "Type",
      "Electric": "Type",
      "Oil": "Type",
      "Solid Fuel": "Type",
      "Heat Pump": "Type",
      "Other": "Type"
    },
    "confidence": "high"
  },

  "boiler_age": {
    "optionMappings": {
      "Less than 5 years": "Age",
      "5-10 years": "Age",
      "10-15 years": "Age",
      "15+ years": "Age",
      "Unknown": "Age",
      "Not Visible": "Age"
    },
    "confidence": "high"
  },

  // Boiler Flue - Excel options: Type
  "boiler_location": {
    "optionMappings": {
      "Kitchen": "Type",
      "Utility Room": "Type",
      "Bathroom": "Type",
      "Cupboard": "Type",
      "Garage": "Type",
      "External": "Type",
      "Loft": "Type",
      "Other": "Type"
    },
    "confidence": "high"
  },

  "flues_not_inspected": {
    "optionMappings": {
      "Yes": "Type",
      "No": "Type",
      "Unknown": "Type"
    },
    "confidence": "medium"
  },

  // Cylinder - Excel options: Type, Age, Insulation
  "water_heater_type": {
    "optionMappings": {
      "Combi Boiler": "Type",
      "System Boiler": "Type",
      "Regular Boiler": "Type",
      "Immersion": "Type",
      "Instant Electric": "Type",
      "Other": "Type"
    },
    "confidence": "high"
  },

  // Water Tank - Excel options: Material, Condition, Location
  "water_heater_location": {
    "optionMappings": {
      "Loft": "Location",
      "Airing Cupboard": "Location",
      "Kitchen": "Location",
      "Bathroom": "Location",
      "Garage": "Location",
      "External": "Location",
      "Other": "Location"
    },
    "confidence": "high"
  },

  "water_tank_material": {
    "optionMappings": {
      "Copper": "Material",
      "Plastic": "Material",
      "Galvanized": "Material",
      "Asbestos": "Material",
      "Unknown": "Material",
      "Other": "Material"
    },
    "confidence": "high"
  },

  "water_tank_condition": {
    "optionMappings": {
      "Good": "Condition",
      "Fair": "Condition",
      "Poor": "Condition",
      "Not Visible": "Condition",
      "Unknown": "Condition"
    },
    "confidence": "high"
  },

  "water_tank_location": {
    "optionMappings": {
      "Loft": "Location",
      "Cupboard": "Location",
      "External": "Location",
      "Other": "Location"
    },
    "confidence": "high"
  },

  // Radiators - Excel options: Type, Condition
  "radiator_condition": {
    "optionMappings": {
      "Good": "Condition",
      "Fair": "Condition",
      "Poor": "Condition",
      "Mixed": "Condition",
      "Unknown": "Condition"
    },
    "confidence": "high"
  },

  // Roof Structure - Excel options: Defects
  "roof_lining": {
    "optionMappings": {
      "Felt": "Defects",
      "Sarking Boards": "Defects",
      "None": "Defects",
      "Other": "Defects"
    },
    "confidence": "medium"
  },

  // Removed Chimney Breast - Excel options: Yes/No, Noted
  "removed_chimney_breast": {
    "optionMappings": {
      "None": "Yes/No",
      "Ground Floor": "Noted",
      "First Floor": "Noted",
      "Multiple Floors": "Noted",
      "Unknown": "Yes/No"
    },
    "confidence": "high"
  },

  // Party Walls - Excel options: None, Noted
  "party_wall_problem": {
    "optionMappings": {
      "None": "None",
      "Cracks": "Noted",
      "Damp": "Noted",
      "Other": "Noted"
    },
    "confidence": "high"
  },

  // Insect Infestation - Excel options: None, Noted
  "insect_infestation": {
    "optionMappings": {
      "None": "None",
      "Woodworm": "Noted",
      "Beetles": "Noted",
      "Other": "Noted",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  // Windows - Excel options: Mainly/Mixture
  "window_replacement": {
    "optionMappings": {
      "Original": "Mainly/Mixture",
      "Replacement": "Mainly/Mixture",
      "Mixed": "Mainly/Mixture",
      "Unknown": "Mainly/Mixture"
    },
    "confidence": "high"
  },

  "window_glazing": {
    "optionMappings": {
      "Single": "Mainly/Mixture",
      "Double": "Mainly/Mixture",
      "Triple": "Mainly/Mixture",
      "Mixed": "Mainly/Mixture",
      "Unknown": "Mainly/Mixture"
    },
    "confidence": "high"
  },

  // Window Sills - Excel options: Ok, Defects
  "window_sealing": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Ok",
      "Poor": "Defects",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  // Doors - Excel options: replacement, type, glazing, patio
  "damaged_locks": {
    "optionMappings": {
      "None": "type",
      "Some": "type",
      "Unknown": "type"
    },
    "confidence": "medium"
  },

  // Pointing - Excel options: Ok, Re-point, Re-pointing
  "pointing_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Re-point",
      "Poor": "Re-pointing",
      "Very Poor": "Re-pointing",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  // Render - Excel options: Ok, Defects
  "rendering_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Ok",
      "Poor": "Defects",
      "Very Poor": "Defects",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  "wall_rendered": {
    "optionMappings": {
      "Yes": "Ok",
      "No": "Ok",
      "Partial": "Ok",
      "Unknown": "Ok"
    },
    "confidence": "medium"
  },

  // Spalling - Excel options: None, Noted
  "spalling_brickwork": {
    "optionMappings": {
      "None": "None",
      "Minor": "Noted",
      "Moderate": "Noted",
      "Severe": "Noted",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  // Movement Cracks - Excel options: None, Noted
  "movement_cracks_severity": {
    "optionMappings": {
      "None": "None",
      "Minor": "Noted",
      "Moderate": "Noted",
      "Severe": "Noted",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  // Leaning Chimney - Excel options: Ok, Leaning, Rebuilding
  "chimney_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Ok",
      "Leaning": "Leaning",
      "Poor": "Rebuilding",
      "Very Poor": "Rebuilding",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  // Chimney Pots Repair Soon - Excel options: Ok, Replace Soon, Immediate
  "chimney_pots": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate"
    },
    "confidence": "high"
  },

  // Flaunching Repair Soon - Excel options: Ok, Replace Soon, Immediate
  "flaunching_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate"
    },
    "confidence": "high"
  },

  // Flashing Repair Soon - Excel options: Ok, Replace Soon, Immediate, New
  "flashing_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate",
      "New": "New"
    },
    "confidence": "high"
  },

  // Ridge Tiles - Excel options: Ok, Replace Soon, Immediate
  "ridge_tiles_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate"
    },
    "confidence": "high"
  },

  // Verge Repair - Excel options: Ok, Replace Soon, Immediate
  "verge_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate"
    },
    "confidence": "high"
  },

  // Flat Roof Repair - Excel options: Ok, Replace Soon, Immediate, New
  "flat_roof_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Replace Soon",
      "Poor": "Immediate",
      "New": "New"
    },
    "confidence": "high"
  },

  // Parapet Wall Repair - Excel options: Ok, Replace Soon, Immediate, New
  "parapet_wall_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Replace Soon",
      "Poor": "Immediate",
      "New": "New"
    },
    "confidence": "high"
  },

  // Ariel Dish Repair Soon - Excel options: Ok, Replace Soon, Immediate
  "aerial_dish_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate"
    },
    "confidence": "high"
  },

  // Valley Gutters Repair - Excel options: Ok, Replace Soon, Immediate, New
  "gutter_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Replace Soon",
      "Poor": "Immediate",
      "Very Poor": "Immediate",
      "New": "New"
    },
    "confidence": "high"
  },

  "valley_gutter_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Replace Soon": "Replace Soon",
      "Immediate": "Immediate",
      "New": "New"
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

console.log(`\n✅ Fixed ${fixedCount} roof, heating, and system field mappings`);
console.log(`📄 Saved to: ${mappingFile}`);
console.log('='.repeat(100));
