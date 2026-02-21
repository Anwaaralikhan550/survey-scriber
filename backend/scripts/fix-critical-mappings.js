/**
 * Fix Critical Field Mappings
 * Manually fix high-priority fields with correct Excel options
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('FIXING CRITICAL FIELD MAPPINGS');
console.log('='.repeat(100));

// First, let's see what Excel options are available for key fields
const keyFields = [
  'weather', 'overall_opinion', 'party_disclosures', 'dampness', 'damp',
  'floors', 'walls', 'ceilings', 'insulation', 'basement', 'garden',
  'grounds', 'energy', 'ventilation', 'extractor_fan', 'facilities',
  'condition', 'local_environment', 'communal_area', 'cellar'
];

console.log('\nExcel options available for key fields:\n');
keyFields.forEach(field => {
  if (phraseLibrary[field]) {
    const options = Object.keys(phraseLibrary[field].options);
    console.log(`${field}: ${options.join(', ')}`);
  }
});

// Now create proper mappings
const fixes = {
  // Weather - already correct
  "weather_current": {
    "optionMappings": {
      "Dry": "Now / Before",
      "Wet": "Now / Before",
      "Snowy": "Now / Before",
      "Overcast": "Now / Before",
      "Changeable": "Now / Before"
    },
    "confidence": "high"
  },

  "weather_previous": {
    "optionMappings": {
      "Dry": "Now / Before",
      "Wet": "Now / Before",
      "Snowy": "Now / Before",
      "Mixed": "Now / Before"
    },
    "confidence": "high"
  },

  // Overall opinion
  "overall_opinion": {
    "optionMappings": {
      "Reasonable": "Reasonable",
      "Not Reasonable": "Reasonable with Repair",
      "Uncertain": "Reasonable with Repair"
    },
    "confidence": "high"
  },

  // Party disclosures
  "party_disclosure": {
    "optionMappings": {
      "None": "None",
      "Client": "Conflict",
      "Vendor": "Conflict",
      "Other": "Conflict"
    },
    "confidence": "high"
  },

  // Dampness
  "damp_type": {
    "optionMappings": {
      "Rising Damp": "Noted",
      "Penetrating Damp": "Noted",
      "Condensation": "Noted",
      "None": "None",
      "Unknown": "Unknown cause"
    },
    "confidence": "high"
  },

  "damp_locations": {
    "optionMappings": {
      "None": "None",
      "Kitchen": "Present",
      "Bathroom": "Present",
      "Bedroom": "Present",
      "Living Room": "Present",
      "Basement": "Present",
      "Multiple Areas": "Present"
    },
    "confidence": "high"
  },

  "damp_signs": {
    "optionMappings": {
      "None": "None",
      "Staining": "Noted",
      "Mould": "Noted",
      "Peeling Paint": "Noted",
      "Multiple Signs": "Implement action",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  // Floors
  "floor_build_type": {
    "optionMappings": {
      "Solid": "All solid",
      "Suspended Timber": "All suspended",
      "Mixed": "Solid & Suspended",
      "Concrete": "All solid",
      "Unknown": "OK"
    },
    "confidence": "high"
  },

  "flooring": {
    "optionMappings": {
      "Carpet": "Coverings",
      "Laminate": "Coverings",
      "Wood": "Coverings",
      "Tile": "Coverings",
      "Mixed": "Coverings",
      "Other": "Coverings"
    },
    "confidence": "high"
  },

  // Walls
  "external_walls": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Weathered",
      "Poor": "Weathered",
      "Unknown": "Ok"
    },
    "confidence": "high"
  },

  "wall_finishes": {
    "optionMappings": {
      "Brick": "Finishes",
      "Render": "Finishes",
      "Stone": "Finishes",
      "Cladding": "Finishes",
      "Mixed": "Finishes",
      "Other": "Finishes"
    },
    "confidence": "high"
  },

  "external_wall_built_of": {
    "optionMappings": {
      "Brick": "Construction",
      "Stone": "Construction",
      "Concrete": "Construction",
      "Timber": "Construction",
      "Mixed": "Construction",
      "Other": "Construction"
    },
    "confidence": "high"
  },

  "wall_construction": {
    "optionMappings": {
      "Solid Brick": "Construction",
      "Cavity": "Construction",
      "Timber Frame": "Construction",
      "Concrete": "Construction",
      "Stone": "Construction",
      "Brick/Block Cavity": "Construction",
      "Steel Frame": "Construction",
      "Other": "Construction"
    },
    "confidence": "high"
  },

  // Ceilings
  "ceiling_condition": {
    "optionMappings": {
      "Good": "Ok",
      "Fair": "Finishes",
      "Poor": "Construction"
    },
    "confidence": "high"
  },

  // Insulation
  "insulation_type": {
    "optionMappings": {
      "Mineral Wool": "Ok",
      "Foam": "Ok",
      "Fiberglass": "Ok",
      "None": "Inadequate",
      "Unknown": "OK"
    },
    "confidence": "high"
  },

  // Basement
  "basement_present": {
    "optionMappings": {
      "Yes": "In use",
      "No": "No access",
      "Unknown": "No access"
    },
    "confidence": "high"
  },

  // Cellar - Actual Excel options: No access, Not in use, In use, Ok, Not habitable, Flooded, Damp, Serious Damp, Joists Decay
  "cellar_present": {
    "optionMappings": {
      "Yes": "In use",
      "No": "No access",
      "Unknown": "No access"
    },
    "confidence": "high"
  },

  // Garden - Actual Excel options: Garden, Communal Garden, Fences, No fencing, OK, Shared, Unknown Status, Pond, Brick Shed(s), Timber Shed(s), Large Outbuilding
  "garden_type": {
    "optionMappings": {
      "Front": "Garden",
      "Rear": "Garden",
      "Both": "Garden",
      "None": "No fencing",
      "Unknown": "Unknown Status"
    },
    "confidence": "high"
  },

  // Grounds - Actual Excel options: Area, Topography, Front Garden, Rear Garden, Communal Garden, Parking, No parking, Pay and display, Residential Parking, Gated Community, Estate Location
  "grounds_type": {
    "optionMappings": {
      "Gardens": "Front Garden",
      "Communal Gardens": "Communal Garden",
      "Hard Standing": "Parking",
      "Paved": "Parking",
      "Mixed": "Front Garden",
      "None": "No parking",
      "Unknown": "No parking"
    },
    "confidence": "high"
  },

  "parking_type": {
    "optionMappings": {
      "None": "No parking",
      "Street": "Pay and display",
      "Driveway": "Parking",
      "Garage": "Parking",
      "Carport": "Parking",
      "Communal": "Residential Parking",
      "Multiple": "Parking",
      "Unknown": "No parking"
    },
    "confidence": "high"
  },

  "driveway_type": {
    "optionMappings": {
      "Tarmac": "Parking",
      "Block Paving": "Parking",
      "Gravel": "Parking",
      "Concrete": "Parking",
      "None": "No parking",
      "Other": "Parking"
    },
    "confidence": "high"
  },

  "garage_present": {
    "optionMappings": {
      "Yes - Garage": "Parking",
      "Yes - Outbuilding": "Parking",
      "Yes - Both": "Parking",
      "No": "No parking",
      "Unknown": "No parking"
    },
    "confidence": "high"
  },

  "boundary_types": {
    "optionMappings": {
      "Fence": "Area",
      "Wall": "Area",
      "Hedge": "Area",
      "Mixed": "Area",
      "None": "Area"
    },
    "confidence": "medium"
  },

  // Energy - Actual Excel options: Efficiency, Environmental Impact
  "energy_efficiency": {
    "optionMappings": {
      "A": "Efficiency",
      "B": "Efficiency",
      "C": "Efficiency",
      "D": "Efficiency",
      "E": "Efficiency",
      "F": "Efficiency",
      "G": "Efficiency",
      "Not Available": "Environmental Impact",
      "Unknown": "Environmental Impact"
    },
    "confidence": "high"
  },

  "energy_rating": {
    "optionMappings": {
      "A": "Efficiency",
      "B": "Efficiency",
      "C": "Efficiency",
      "D": "Efficiency",
      "E": "Efficiency",
      "F": "Efficiency",
      "G": "Efficiency",
      "Not Available": "Environmental Impact",
      "Unknown": "Environmental Impact"
    },
    "confidence": "high"
  },

  // Ventilation - Actual Excel options: None, Damp noted
  "ventilation_adequate": {
    "optionMappings": {
      "Adequate": "None",
      "Inadequate": "Damp noted",
      "Not Visible": "None",
      "Unknown": "None"
    },
    "confidence": "high"
  },

  "extractor_fans": {
    "optionMappings": {
      "Present - All Wet Rooms": "OK",
      "Present - Some Rooms": "OK",
      "Absent": "Replace             Clean",
      "Not Required": "OK",
      "Unknown": "OK"
    },
    "confidence": "high"
  },

  // Facilities - Actual Excel options: Accessible, Remote
  "facilities": {
    "optionMappings": {
      "Good": "Accessible",
      "Fair": "Accessible",
      "Poor": "Remote",
      "Schools": "Accessible",
      "Shops": "Accessible",
      "Public Transport": "Accessible",
      "Medical Facilities": "Accessible",
      "Parks/Green Spaces": "Accessible",
      "Restaurants/Cafes": "Accessible",
      "Sports/Leisure": "Accessible",
      "Unknown": "Accessible"
    },
    "confidence": "high"
  },

  // Condition - Actual Excel options: Ok, Investigate          Roof slope location
  "interior_condition": {
    "optionMappings": {
      "Excellent": "Ok",
      "Good": "Ok",
      "Fair": "Ok",
      "Poor": "Investigate          Roof slope location",
      "Very Poor": "Investigate          Roof slope location"
    },
    "confidence": "high"
  },

  "decoration": {
    "optionMappings": {
      "Excellent": "Ok",
      "Good": "Ok",
      "Fair": "Ok",
      "Poor": "Investigate          Roof slope location",
      "Needs Updating": "Investigate          Roof slope location"
    },
    "confidence": "high"
  },

  "exterior_condition": {
    "optionMappings": {
      "Excellent": "Ok",
      "Good": "Ok",
      "Fair": "Weathered",
      "Poor": "Weathered",
      "Very Poor": "Weathered"
    },
    "confidence": "high"
  },

  // Local environment - Actual Excel options: No Adverse, Flooding, EMF
  "local_environment": {
    "optionMappings": {
      "Residential": "No Adverse",
      "Commercial": "No Adverse",
      "Mixed": "No Adverse",
      "Rural": "No Adverse",
      "Industrial": "No Adverse",
      "Residential - Quiet": "No Adverse",
      "Residential - Busy": "No Adverse",
      "Mixed Use": "No Adverse",
      "Commercial Area": "No Adverse",
      "Industrial Area": "No Adverse",
      "Near Main Road": "No Adverse",
      "Near Railway": "No Adverse",
      "Near Airport": "No Adverse",
      "Unknown": "No Adverse"
    },
    "confidence": "high"
  },

  // Communal area - Actual Excel options: Not Inspected, Inspected, OK, Condition              OK
  "communal_area": {
    "optionMappings": {
      "N/A": "Not Inspected",
      "Good": "OK",
      "Fair": "Inspected",
      "Poor": "Inspected"
    },
    "confidence": "high"
  },

  "flat_access_type": {
    "optionMappings": {
      "N/A": "Not Inspected",
      "Own entrance": "OK",
      "Communal entrance": "Inspected",
      "Other": "Inspected"
    },
    "confidence": "medium"
  },

  "common_services_present": {
    "optionMappings": {
      "None": "Not Inspected",
      "Heating": "Inspected",
      "Water": "Inspected",
      "Both": "Inspected",
      "Other": "Inspected"
    },
    "confidence": "medium"
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

console.log(`\n\n${'='.repeat(100)}`);
console.log(`✅ Fixed ${fixedCount} critical field mappings with proper Excel options`);
console.log(`📄 Saved to: ${mappingFile}`);
console.log('='.repeat(100));
