/**
 * Add Bulk Mappings
 * Helper script to add multiple field mappings at once
 */

const fs = require('fs');

// Read current mappings
const path = require('path');
const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

// Define new mappings to add
const newMappings = {
  "weather_current": {
    "appField": "weather_current",
    "appLabel": "Current Weather",
    "excelField": "weather",
    "excelLabel": "Weather",
    "description": "Maps current weather conditions to Excel weather field",
    "optionMappings": {
      "Dry": "Now / Before",
      "Wet": "Now / Before",
      "Snowy": "Now / Before",
      "Overcast": "Now / Before",
      "Changeable": "Now / Before"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Weather field uses 'Now / Before' option with template placeholders for specific conditions"
  },

  "weather_previous": {
    "appField": "weather_previous",
    "appLabel": "Previous Weather",
    "excelField": "weather",
    "excelLabel": "Weather",
    "description": "Maps previous weather conditions - used in same template as weather_current",
    "optionMappings": {
      "Dry": "Now / Before",
      "Wet": "Now / Before",
      "Snowy": "Now / Before",
      "Overcast": "Now / Before",
      "Changeable": "Now / Before"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Combined with weather_current in template: 'weather was (dry/wet) following (dry/wet) weather'"
  },

  "overall_opinion": {
    "appField": "overall_opinion",
    "appLabel": "Overall Opinion",
    "excelField": "overall_opinion",
    "excelLabel": "Overall Opinion",
    "description": "Surveyor's overall opinion of the property",
    "optionMappings": {
      "Reasonable": "Reasonable",
      "Not Reasonable": "Not Reasonable",
      "Uncertain": "Uncertain"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to Excel field"
  },

  "party_disclosure": {
    "appField": "party_disclosure",
    "appLabel": "Party Disclosure",
    "excelField": "party_disclosures",
    "excelLabel": "Party Disclosures",
    "description": "Conflict of interest disclosure",
    "optionMappings": {
      "None": "None",
      "Client": "Client",
      "Vendor": "Vendor",
      "Other": "Other"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Maps to party_disclosures Excel field"
  },

  "roof_type": {
    "appField": "roof_type",
    "appLabel": "Roof Type",
    "excelField": "roofs",
    "excelLabel": "Roofs",
    "description": "Type of roof construction",
    "optionMappings": {
      "Pitched": "Not inspected. location    Assumed Type",
      "Flat": "Not inspected. location    Assumed Type",
      "Mixed": "Not inspected. location    Assumed Type",
      "Unknown": "Not inspected. location    Assumed Type"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel field may need different option. Need to verify."
  },

  "wall_construction": {
    "appField": "wall_construction",
    "appLabel": "Wall Construction",
    "excelField": "walls",
    "excelLabel": "Walls",
    "description": "External wall construction type",
    "optionMappings": {
      "Solid Brick": "Construction",
      "Cavity": "Construction",
      "Timber Frame": "Construction",
      "Concrete": "Construction",
      "Stone": "Construction",
      "Other": "Construction"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to walls field Construction option"
  },

  "window_type": {
    "appField": "window_type",
    "appLabel": "Window Type",
    "excelField": "windows",
    "excelLabel": "Windows",
    "description": "Type of windows in the property",
    "optionMappings": {
      "Single Glazed": "Mainly/Mixture",
      "Double Glazed": "Mainly/Mixture",
      "Triple Glazed": "Mainly/Mixture",
      "Mixed": "Mainly/Mixture",
      "Unknown": "Mainly/Mixture"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to windows Mainly/Mixture option"
  },

  "heating_type": {
    "appField": "heating_type",
    "appLabel": "Heating Type",
    "excelField": "gas_heating",
    "excelLabel": "Gas Heating",
    "description": "Type of heating system",
    "optionMappings": {
      "Gas Central Heating": "Central",
      "Electric Heating": "Central",
      "Oil": "Central",
      "Solid Fuel": "Central",
      "None": "Central",
      "Other": "Central"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel has separate gas_heating and electric_heating fields. May need multiple mappings."
  },

  "basement_present": {
    "appField": "basement_present",
    "appLabel": "Basement Present",
    "excelField": "basement",
    "excelLabel": "Basement",
    "description": "Whether property has a basement",
    "optionMappings": {
      "Yes": "Present",
      "No": "Not Present",
      "Unknown": "Not Present"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to basement field"
  },

  "garden_type": {
    "appField": "garden_type",
    "appLabel": "Garden Type",
    "excelField": "garden",
    "excelLabel": "Garden",
    "description": "Type of garden/outdoor space",
    "optionMappings": {
      "Front": "Front",
      "Rear": "Rear",
      "Both": "Front & Rear",
      "None": "None",
      "Unknown": "None"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to garden field"
  }
};

// Add new mappings to existing ones
Object.assign(mappings, newMappings);

// Update meta count
const totalMapped = Object.keys(mappings).filter(k => k !== '_meta').length;
mappings._meta.mappedFields = totalMapped;
mappings._meta.lastUpdated = new Date().toISOString().split('T')[0];

// Save updated mappings
fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log('='.repeat(100));
console.log('BULK MAPPINGS ADDED');
console.log('='.repeat(100));
console.log(`\n✅ Added ${Object.keys(newMappings).length} new field mappings`);
console.log(`📊 Total mappings: ${totalMapped}/${mappings._meta.totalAppFields}`);
console.log(`📈 Coverage: ${Math.round(totalMapped/mappings._meta.totalAppFields*100)}%`);
console.log(`\n💾 Saved to: ${mappingFile}`);
console.log('\n='.repeat(100));
console.log('\nNew mappings added:');
Object.keys(newMappings).forEach(key => {
  const mapping = newMappings[key];
  console.log(`  • ${mapping.appLabel} → ${mapping.excelLabel} (${mapping.confidence} confidence)`);
});
console.log('\n='.repeat(100));
