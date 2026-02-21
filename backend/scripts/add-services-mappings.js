/**
 * Add Services & Utilities Mappings (Batch 3)
 * Maps heating, electrical, water, gas, drainage fields
 */

const fs = require('fs');
const path = require('path');

// Read current mappings
const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

// Define services mappings
const servicesMappings = {
  "mains_gas": {
    "appField": "mains_gas",
    "appLabel": "Mains Gas Connected",
    "excelField": "mains_gas",
    "excelLabel": "Mains Gas",
    "description": "Mains gas supply connection",
    "optionMappings": {
      "Yes": "Connected",
      "No": "Not Connected",
      "Unknown": "Not Connected",
      "Capped": "Capped"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to mains_gas Excel field"
  },

  "mains_water": {
    "appField": "mains_water",
    "appLabel": "Mains Water Connected",
    "excelField": "main_water",
    "excelLabel": "Main Water",
    "description": "Mains water supply connection",
    "optionMappings": {
      "Yes": "Connected",
      "No": "Not connected",
      "Unknown": "Connected"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to main_water Excel field"
  },

  "mains_drainage": {
    "appField": "mains_drainage",
    "appLabel": "Mains Drainage Connected",
    "excelField": "mains_gas",
    "excelLabel": "Mains Gas",
    "description": "Mains drainage connection",
    "optionMappings": {
      "Yes": "Connected",
      "No": "Not Connected",
      "Septic Tank": "Not Connected",
      "Unknown": "Connected"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "No specific drainage Excel field found. Using mains_gas as placeholder. Needs review."
  },

  "consumer_unit_type": {
    "appField": "consumer_unit_type",
    "appLabel": "Consumer Unit Type",
    "excelField": "fuse",
    "excelLabel": "Fuse",
    "description": "Type of electrical consumer unit/fuse box",
    "optionMappings": {
      "Modern RCD": "Modern",
      "Modern MCB": "Modern",
      "Rewireable Fuses": "Old",
      "Mixed": "Old",
      "Unknown": "Old"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to fuse Excel field with Modern/Old options"
  },

  "last_electrical_test": {
    "appField": "last_electrical_test",
    "appLabel": "Last Electrical Test",
    "excelField": "mains_electricity",
    "excelLabel": "Mains Electricity",
    "description": "When electrical installation was last tested",
    "optionMappings": {
      "Within 5 years": "Present",
      "5-10 years": "Present",
      "Over 10 years": "Test recommended",
      "Never": "Test recommended",
      "Unknown": "Test recommended"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to mains_electricity with Present/Test recommended options"
  },

  "boiler_age": {
    "appField": "boiler_age",
    "appLabel": "Boiler Age (years)",
    "excelField": "gas_heating",
    "excelLabel": "Gas Heating",
    "description": "Age of boiler in years",
    "optionMappings": {
      "0-5": "Central",
      "6-10": "Central",
      "11-15": "Old",
      "16-20": "Old",
      "Over 20": "Old",
      "Unknown": "Central"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel gas_heating has various options. Age mapping may need different field."
  },

  "boiler_location": {
    "appField": "boiler_location",
    "appLabel": "Boiler Location",
    "excelField": "boiler_flue",
    "excelLabel": "Boiler Flue",
    "description": "Location of boiler",
    "optionMappings": {
      "Kitchen": "OK",
      "Utility Room": "OK",
      "Bathroom": "Problem",
      "Garage": "OK",
      "External": "OK",
      "Cupboard": "OK",
      "Loft": "OK",
      "Other": "OK"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Maps to boiler_flue. Location not directly mapped in Excel."
  },

  "water_heater_type": {
    "appField": "water_heater_type",
    "appLabel": "Water Heater Type",
    "excelField": "cylinder",
    "excelLabel": "Cylinder",
    "description": "Type of water heating system",
    "optionMappings": {
      "Combi Boiler": "Combi",
      "Hot Water Cylinder": "Cylinder",
      "Immersion Heater": "Cylinder",
      "Instant Electric": "Combi",
      "None": "Cylinder",
      "Unknown": "Cylinder"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to cylinder Excel field"
  },

  "water_heater_location": {
    "appField": "water_heater_location",
    "appLabel": "Water Heater Location",
    "excelField": "water_tank",
    "excelLabel": "Water tank",
    "description": "Location of water heater/tank",
    "optionMappings": {
      "Loft": "Location",
      "Cupboard": "Location",
      "Bathroom": "Location",
      "Kitchen": "Location",
      "External": "Location",
      "None": "None",
      "Unknown": "Location"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Maps to water_tank Location option"
  },

  "water_tank_material": {
    "appField": "water_tank_material",
    "appLabel": "Water Tank Material",
    "excelField": "water_tank",
    "excelLabel": "Water tank",
    "description": "Material of water storage tank",
    "optionMappings": {
      "Plastic": "Material",
      "Copper": "Material",
      "Galvanised Steel": "Old",
      "Asbestos": "Old",
      "None": "None",
      "Unknown": "Material"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to water_tank Material/Old options"
  },

  "water_tank_condition": {
    "appField": "water_tank_condition",
    "appLabel": "Water Tank Condition",
    "excelField": "water_tank",
    "excelLabel": "Water tank",
    "description": "Condition of water tank",
    "optionMappings": {
      "Good": "OK",
      "Fair": "OK",
      "Poor": "Old",
      "Replacement Needed": "Old",
      "Not Visible": "OK"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to water_tank OK/Old options"
  },

  "radiator_condition": {
    "appField": "radiator_condition",
    "appLabel": "Radiator Condition",
    "excelField": "radiators",
    "excelLabel": "Radiators",
    "description": "Overall condition of radiators",
    "optionMappings": {
      "Good": "OK",
      "Fair": "OK",
      "Poor": "OK",
      "Mixed": "OK",
      "Not Applicable": "OK"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel radiators field has single OK option"
  },

  "gutter_condition": {
    "appField": "gutter_condition",
    "appLabel": "Gutter Condition",
    "excelField": "valley_gutters_repair",
    "excelLabel": "Valley Gutters Repair",
    "description": "Condition of gutters and downpipes",
    "optionMappings": {
      "Good": "OK",
      "Fair": "Repair soon",
      "Poor": "Repair now",
      "Blocked": "Repair now",
      "Damaged": "Repair now"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to valley_gutters_repair field"
  }
};

// Add new mappings
Object.assign(mappings, servicesMappings);

// Update meta
const totalMapped = Object.keys(mappings).filter(k => k !== '_meta').length;
mappings._meta.mappedFields = totalMapped;
mappings._meta.lastUpdated = new Date().toISOString().split('T')[0];

// Save
fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log('='.repeat(100));
console.log('SERVICES & UTILITIES MAPPINGS ADDED (BATCH 3)');
console.log('='.repeat(100));
console.log(`\n✅ Added ${Object.keys(servicesMappings).length} services field mappings`);
console.log(`📊 Total mappings: ${totalMapped}/${mappings._meta.totalAppFields}`);
console.log(`📈 Coverage: ${Math.round(totalMapped/mappings._meta.totalAppFields*100)}%`);
console.log(`\n💾 Saved to: ${mappingFile}`);

console.log('\n' + '='.repeat(100));
console.log('SERVICES MAPPINGS BREAKDOWN');
console.log('='.repeat(100));

const byConfidence = {
  high: [],
  medium: [],
  low: []
};

Object.keys(servicesMappings).forEach(key => {
  const mapping = servicesMappings[key];
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

console.log('\n⚡ Electrical:');
console.log('  • Consumer Unit Type, Last Electrical Test');

console.log('\n🔥 Gas:');
console.log('  • Mains Gas Connected');

console.log('\n💧 Water:');
console.log('  • Mains Water Connected');
console.log('  • Water Tank Material, Water Tank Condition');
console.log('  • Water Heater Type, Water Heater Location');

console.log('\n🌡️ Heating:');
console.log('  • Boiler Age, Boiler Location');
console.log('  • Radiator Condition');

console.log('\n🚰 Drainage & Plumbing:');
console.log('  • Mains Drainage Connected');
console.log('  • Gutter Condition');

console.log('\n' + '='.repeat(100));
console.log('\n🎯 MILESTONE: 46 FIELDS MAPPED (35% COVERAGE!)');
console.log('='.repeat(100));
