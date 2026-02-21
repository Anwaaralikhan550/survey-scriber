/**
 * Add External Features & Environmental Mappings (Batch 4)
 * Maps gardens, grounds, energy, safety, ventilation, age fields
 */

const fs = require('fs');
const path = require('path');

// Read current mappings
const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

// Define batch 4 mappings
const batch4Mappings = {
  "year_built": {
    "appField": "year_built",
    "appLabel": "Year Built",
    "excelField": "year_built",
    "excelLabel": "Year Built",
    "description": "Year property was built",
    "optionMappings": {
      "Pre-1900": "Age",
      "1900-1919": "Age",
      "1920-1945": "Age",
      "1946-1979": "Age",
      "1980-1999": "Age",
      "2000-Present": "Recent",
      "Unknown": "Age"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to year_built with Age/Recent options"
  },

  "property_facing": {
    "appField": "property_facing",
    "appLabel": "Property Orientation",
    "excelField": "property_facing",
    "excelLabel": "Property Facing",
    "description": "Main orientation of property",
    "optionMappings": {
      "North": "Orientation",
      "South": "Orientation",
      "East": "Orientation",
      "West": "Orientation",
      "North-East": "Orientation",
      "North-West": "Orientation",
      "South-East": "Orientation",
      "South-West": "Orientation",
      "Unknown": "Orientation"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to property_facing Excel field"
  },

  "nearby_trees": {
    "appField": "nearby_trees",
    "appLabel": "Nearby Trees",
    "excelField": "nearby_trees",
    "excelLabel": "Nearby Trees",
    "description": "Trees near property that may affect foundations",
    "optionMappings": {
      "None": "None noted",
      "Small Trees": "Close",
      "Medium Trees": "Close",
      "Large Trees": "Large",
      "Multiple Large Trees": "Large",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to nearby_trees Excel field"
  },

  "conservatory_present": {
    "appField": "conservatory_present",
    "appLabel": "Conservatory/Porch Present",
    "excelField": "conservatory_porch",
    "excelLabel": "Conservatory   Porch",
    "description": "Presence of conservatory or porch",
    "optionMappings": {
      "None": "None",
      "Conservatory": "Present",
      "Porch": "Present",
      "Both": "Present",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to conservatory_porch Excel field"
  },

  "balcony_present": {
    "appField": "balcony_present",
    "appLabel": "Balcony Present",
    "excelField": "juliet_balcony",
    "excelLabel": "Juliet Balcony",
    "description": "Presence of balcony",
    "optionMappings": {
      "None": "None",
      "Juliet": "Present",
      "Full": "Present",
      "Multiple": "Present",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel only has juliet_balcony field"
  },

  "grounds_type": {
    "appField": "grounds_type",
    "appLabel": "Grounds Type",
    "excelField": "grounds",
    "excelLabel": "Grounds",
    "description": "Type of grounds/outdoor space",
    "optionMappings": {
      "Gardens": "Gardens",
      "Communal Gardens": "Communal",
      "Hard Standing": "Hard standing",
      "Paved": "Paved",
      "Mixed": "Gardens",
      "None": "None",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to grounds Excel field"
  },

  "parking_type": {
    "appField": "parking_type",
    "appLabel": "Parking Type",
    "excelField": "grounds",
    "excelLabel": "Grounds",
    "description": "Type of parking available",
    "optionMappings": {
      "None": "None",
      "Street": "None",
      "Driveway": "Parking",
      "Garage": "Garage",
      "Carport": "Parking",
      "Communal": "Communal",
      "Multiple": "Parking",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to grounds field Parking/Garage options"
  },

  "local_environment": {
    "appField": "local_environment",
    "appLabel": "Local Environment",
    "excelField": "local_environment",
    "excelLabel": "Local environment",
    "description": "Character of local area",
    "optionMappings": {
      "Residential": "Residential",
      "Commercial": "Commercial",
      "Mixed": "Mixed",
      "Rural": "Residential",
      "Industrial": "Commercial",
      "Unknown": "Residential"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to local_environment Excel field"
  },

  "energy_efficiency": {
    "appField": "energy_efficiency",
    "appLabel": "Energy Efficiency",
    "excelField": "energy",
    "excelLabel": "Energy",
    "description": "Energy efficiency rating/certificate",
    "optionMappings": {
      "A": "EPC",
      "B": "EPC",
      "C": "EPC",
      "D": "EPC",
      "E": "EPC",
      "F": "EPC",
      "G": "EPC",
      "Not Available": "No EPC",
      "Unknown": "No EPC"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Maps to energy EPC/No EPC options"
  },

  "ventilation_adequate": {
    "appField": "ventilation_adequate",
    "appLabel": "Roof Space Ventilation",
    "excelField": "ventilation",
    "excelLabel": "Ventilation",
    "description": "Adequacy of ventilation",
    "optionMappings": {
      "Adequate": "Adequate",
      "Inadequate": "Poor",
      "Not Visible": "Adequate",
      "Unknown": "Adequate"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to ventilation Excel field"
  },

  "extractor_fans": {
    "appField": "extractor_fans",
    "appLabel": "Extractor Fans",
    "excelField": "extractor_fan",
    "excelLabel": "Extractor fan",
    "description": "Presence of extractor fans",
    "optionMappings": {
      "Present - All Wet Rooms": "Present",
      "Present - Some Rooms": "Present",
      "Absent": "None",
      "Not Required": "None",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Maps to extractor_fan Present/None options"
  },

  "fire_safety": {
    "appField": "fire_safety",
    "appLabel": "Fire Safety Provisions",
    "excelField": "no_fire_escape_risk",
    "excelLabel": "No Fire Escape Risk",
    "description": "Fire safety and escape routes",
    "optionMappings": {
      "Adequate": "Adequate",
      "Concerns Noted": "Risk noted",
      "Not Assessed": "Adequate",
      "Unknown": "Adequate"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Maps to no_fire_escape_risk Excel field"
  },

  "safety_glass": {
    "appField": "safety_glass",
    "appLabel": "Safety Glass Compliance",
    "excelField": "safety_glass_rating",
    "excelLabel": "Safety Glass Rating",
    "description": "Compliance with safety glass regulations",
    "optionMappings": {
      "Compliant": "OK",
      "Partial Compliance": "Upgrade",
      "Non-Compliant": "Problem",
      "Not Applicable": "OK",
      "Unknown": "OK"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to safety_glass_rating Excel field"
  },

  "blocked_fireplace": {
    "appField": "blocked_fireplace",
    "appLabel": "Blocked Fireplace",
    "excelField": "blocked_fireplace",
    "excelLabel": "Blocked Fireplace",
    "description": "Fireplaces that have been blocked",
    "optionMappings": {
      "None": "None",
      "One": "Present",
      "Multiple": "Present",
      "All": "Present",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to blocked_fireplace Excel field"
  },

  "loft_accessed": {
    "appField": "loft_accessed",
    "appLabel": "Loft Space Accessed",
    "excelField": "insulation",
    "excelLabel": "Insulation",
    "description": "Whether loft was inspected",
    "optionMappings": {
      "Yes - Fully": "Good",
      "Yes - Partially": "Unknown",
      "No - Access Available": "Unknown",
      "No - No Access": "Unknown",
      "Not Applicable": "Unknown"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "No direct Excel field for loft access. Using insulation as proxy."
  },

  "loft_converted": {
    "appField": "loft_converted",
    "appLabel": "Loft Converted",
    "excelField": "conversion",
    "excelLabel": "Conversion",
    "description": "Whether loft has been converted",
    "optionMappings": {
      "Yes - With Approval": "Approved",
      "Yes - Without Approval": "Not approved",
      "No": "None",
      "Unknown": "Unknown"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to conversion Excel field"
  },

  "year_extended": {
    "appField": "year_extended",
    "appLabel": "Year Extended",
    "excelField": "year_extended",
    "excelLabel": "Year extended",
    "description": "When property was extended",
    "optionMappings": {
      "Not Extended": "None",
      "Within 10 years": "Recent",
      "10-20 years ago": "Extended",
      "Over 20 years ago": "Extended",
      "Unknown": "Unknown"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to year_extended Excel field"
  },

  "security_measures": {
    "appField": "security_measures",
    "appLabel": "Security Measures",
    "excelField": "safety_hazard",
    "excelLabel": "Safety hazard",
    "description": "Security features present",
    "optionMappings": {
      "Alarm": "None",
      "Locks": "None",
      "Both": "None",
      "None": "Present",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "No direct security Excel field. Using safety_hazard as inverse mapping."
  },

  "occupancy_status": {
    "appField": "occupancy_status",
    "appLabel": "Occupancy Status",
    "excelField": "property_status",
    "excelLabel": "Property Status",
    "description": "Whether property is occupied",
    "optionMappings": {
      "Occupied": "Occupancy           Furnishing             Floor Covering",
      "Vacant": "Occupancy           Furnishing             Floor Covering",
      "Part Furnished": "Occupancy           Furnishing             Floor Covering",
      "Unfurnished": "Occupancy           Furnishing             Floor Covering",
      "Unknown": "Occupancy           Furnishing             Floor Covering"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel property_status has combined option for occupancy/furnishing/floor covering"
  }
};

// Add new mappings
Object.assign(mappings, batch4Mappings);

// Update meta
const totalMapped = Object.keys(mappings).filter(k => k !== '_meta').length;
mappings._meta.mappedFields = totalMapped;
mappings._meta.lastUpdated = new Date().toISOString().split('T')[0];

// Save
fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log('='.repeat(100));
console.log('EXTERNAL FEATURES & ENVIRONMENTAL MAPPINGS ADDED (BATCH 4)');
console.log('='.repeat(100));
console.log(`\n✅ Added ${Object.keys(batch4Mappings).length} field mappings`);
console.log(`📊 Total mappings: ${totalMapped}/${mappings._meta.totalAppFields}`);
console.log(`📈 Coverage: ${Math.round(totalMapped/mappings._meta.totalAppFields*100)}%`);
console.log(`\n💾 Saved to: ${mappingFile}`);

console.log('\n' + '='.repeat(100));
console.log('BATCH 4 MAPPINGS BREAKDOWN');
console.log('='.repeat(100));

const byConfidence = {
  high: [],
  medium: [],
  low: []
};

Object.keys(batch4Mappings).forEach(key => {
  const mapping = batch4Mappings[key];
  byConfidence[mapping.confidence].push(mapping.appLabel);
});

console.log(`\n🟢 High Confidence (${byConfidence.high.length}):`);
byConfidence.high.forEach(label => console.log(`  • ${label}`));

console.log(`\n🟡 Medium Confidence (${byConfidence.medium.length}):`);
byConfidence.medium.forEach(label => console.log(`  • ${label}`));

console.log(`\n🔴 Low Confidence (${byConfidence.low.length}):`);
byConfidence.low.forEach(label => console.log(`  • ${label}`));

console.log('\n' + '='.repeat(100));
console.log('CATEGORY BREAKDOWN');
console.log('='.repeat(100));

console.log('\n🏡 Property Details:');
console.log('  • Year Built, Property Orientation, Occupancy Status');

console.log('\n🌳 External Features:');
console.log('  • Nearby Trees, Conservatory/Porch, Balcony');
console.log('  • Grounds Type, Parking Type');

console.log('\n🌍 Environmental:');
console.log('  • Local Environment, Energy Efficiency');

console.log('\n💨 Ventilation & Safety:');
console.log('  • Ventilation, Extractor Fans');
console.log('  • Fire Safety, Safety Glass, Blocked Fireplace');

console.log('\n🏗️ Conversions & Extensions:');
console.log('  • Loft Accessed, Loft Converted, Year Extended');

console.log('\n🔒 Security:');
console.log('  • Security Measures');

console.log('\n' + '='.repeat(100));

if (totalMapped >= 65) {
  console.log('\n🎉 MILESTONE ACHIEVED: 50% COVERAGE! 🎉');
} else {
  console.log(`\n🎯 Almost at 50%! Need ${65 - totalMapped} more fields`);
}

console.log('='.repeat(100));
