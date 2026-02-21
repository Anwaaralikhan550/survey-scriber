/**
 * Add Structural Element Mappings (Batch 2)
 * Maps roof, wall, floor, ceiling, window, door fields
 */

const fs = require('fs');
const path = require('path');

// Read current mappings
const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

// Define structural element mappings
const structuralMappings = {
  "roof_covering": {
    "appField": "roof_covering",
    "appLabel": "Roof Covering",
    "excelField": "tiles",
    "excelLabel": "Tiles",
    "description": "Type of roof covering material",
    "optionMappings": {
      "Slate": "OK",
      "Tile": "OK",
      "Flat Roof": "Repair",
      "Metal": "OK",
      "Asphalt": "OK",
      "Other": "OK"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to tiles field. May need different Excel field for flat roofs."
  },

  "roof_lining": {
    "appField": "roof_lining",
    "appLabel": "Roof Lining",
    "excelField": "roof_structure",
    "excelLabel": "Roof structure",
    "description": "Roof lining and structure",
    "optionMappings": {
      "Felt": "Construction",
      "Sarking Board": "Construction",
      "None Visible": "Construction",
      "Other": "Construction"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel roof_structure has 'Construction' option. May need verification."
  },

  "insulation_type": {
    "appField": "insulation_type",
    "appLabel": "Loft Insulation Type",
    "excelField": "insulation",
    "excelLabel": "Insulation",
    "description": "Type of loft insulation",
    "optionMappings": {
      "Mineral Wool": "Good",
      "Foam": "Good",
      "Fiberglass": "Good",
      "None": "Poor",
      "Unknown": "Unknown"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to insulation field with Good/Poor/Unknown options"
  },

  "roof_spreading": {
    "appField": "roof_spreading",
    "appLabel": "Roof Spreading",
    "excelField": "roof_spreading",
    "excelLabel": "Roof Spreading",
    "description": "Evidence of roof spreading",
    "optionMappings": {
      "None Noted": "Ok",
      "Minor": "Repair soon",
      "Moderate": "Repair now",
      "Severe": "Poor Roof Condition"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to roof_spreading Excel field"
  },

  "damp_proof_course": {
    "appField": "damp_proof_course",
    "appLabel": "Damp Proof Course",
    "excelField": "dpc",
    "excelLabel": "DPC",
    "description": "Damp proof course status",
    "optionMappings": {
      "Present": "OK",
      "Absent": "Problem",
      "Unclear": "OK",
      "Breached": "Problem"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Maps to DPC Excel field"
  },

  "damp_type": {
    "appField": "damp_type",
    "appLabel": "Suspected Damp Type",
    "excelField": "dampness",
    "excelLabel": "Dampness",
    "description": "Type of dampness detected",
    "optionMappings": {
      "Rising Damp": "Rising",
      "Penetrating Damp": "Penetrating",
      "Condensation": "Condensation",
      "None": "None noted",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to dampness Excel field"
  },

  "damp_locations": {
    "appField": "damp_locations",
    "appLabel": "Damp Detected Locations",
    "excelField": "damp",
    "excelLabel": "Damp",
    "description": "Locations where damp was detected",
    "optionMappings": {
      "None": "None noted",
      "Kitchen": "Location noted",
      "Bathroom": "Location noted",
      "Bedroom": "Location noted",
      "Living Room": "Location noted",
      "Basement": "Location noted",
      "Multiple Areas": "Location noted"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to damp field"
  },

  "floor_build_type": {
    "appField": "floor_build_type",
    "appLabel": "Floor Build Type",
    "excelField": "floors",
    "excelLabel": "Floors",
    "description": "Type of floor construction",
    "optionMappings": {
      "Solid": "All solid",
      "Suspended Timber": "All suspended",
      "Mixed": "Solid & Suspended",
      "Concrete": "All solid",
      "Unknown": "OK"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to floors Excel field"
  },

  "sloping_floor": {
    "appField": "sloping_floor",
    "appLabel": "Sloping Floor",
    "excelField": "sloping_floor",
    "excelLabel": "Sloping Floor",
    "description": "Floor sloping issues",
    "optionMappings": {
      "None": "No Issue",
      "Minor": "Investigate",
      "Significant": "Investigate"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to sloping_floor Excel field"
  },

  "uneven_floor": {
    "appField": "uneven_floor",
    "appLabel": "Uneven Floor",
    "excelField": "uneven_floor",
    "excelLabel": "Uneven Floor",
    "description": "Floor levelness issues",
    "optionMappings": {
      "None": "Minor",
      "Minor": "Minor",
      "Significant": "Repair"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to uneven_floor Excel field"
  },

  "ceiling_condition": {
    "appField": "ceiling_condition",
    "appLabel": "Ceiling Condition",
    "excelField": "ceilings",
    "excelLabel": "Ceilings",
    "description": "Overall ceiling condition",
    "optionMappings": {
      "Good": "OK",
      "Fair": "Repair",
      "Poor": "Problem noted"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to ceilings Excel field"
  },

  "cracks_noted": {
    "appField": "cracks_noted",
    "appLabel": "Cracks Noted",
    "excelField": "cracks",
    "excelLabel": "Cracks",
    "description": "Structural cracks observed",
    "optionMappings": {
      "None": "None noted",
      "Hairline": "Minor",
      "Minor": "Minor",
      "Significant": "Significant",
      "Severe": "Significant"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to cracks Excel field"
  },

  "removed_wall": {
    "appField": "removed_wall",
    "appLabel": "Removed Wall",
    "excelField": "removed_wall",
    "excelLabel": "Removed Wall",
    "description": "Evidence of removed walls",
    "optionMappings": {
      "None": "OK",
      "Yes - Properly Supported": "OK",
      "Yes - Support Unclear": "Defects noted",
      "Yes - No Support": "Repair"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to removed_wall Excel field"
  },

  "removed_chimney_breast": {
    "appField": "removed_chimney_breast",
    "appLabel": "Removed Chimney Breast",
    "excelField": "removed_chimney_breast",
    "excelLabel": "Removed Chimney Breast",
    "description": "Chimney breast removal status",
    "optionMappings": {
      "None": "Not removed",
      "Ground Floor Only": "Removed",
      "First Floor Only": "Removed",
      "Both Floors": "Removed",
      "Unknown": "Not removed"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to removed_chimney_breast Excel field"
  },

  "party_wall_problem": {
    "appField": "party_wall_problem",
    "appLabel": "Party Wall Problem",
    "excelField": "party_walls",
    "excelLabel": "Party Walls",
    "description": "Issues with party walls",
    "optionMappings": {
      "None": "None noted",
      "Missing Section": "Partly missing",
      "Large Gap": "Largely missing",
      "Other": "Partly missing"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to party_walls Excel field"
  },

  "insect_infestation": {
    "appField": "insect_infestation",
    "appLabel": "Insect Infestation",
    "excelField": "insect_infestation",
    "excelLabel": "Insect infestation",
    "description": "Evidence of insect infestation",
    "optionMappings": {
      "None Noted": "None noted",
      "Woodworm": "Active",
      "Beetles": "Active",
      "Other": "Active",
      "Historical": "Old"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to insect_infestation Excel field"
  },

  "window_replacement": {
    "appField": "window_replacement",
    "appLabel": "Window Replacement",
    "excelField": "windows",
    "excelLabel": "Windows",
    "description": "Window replacement status",
    "optionMappings": {
      "All Original": "Mainly/Mixture",
      "All Replaced": "Mainly/Mixture",
      "Mixed": "Mainly/Mixture",
      "Unknown": "Mainly/Mixture"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Excel windows field may need different option. Already mapped window_type."
  },

  "window_sealing": {
    "appField": "window_sealing",
    "appLabel": "Window Sealing",
    "excelField": "window_sills",
    "excelLabel": "Window Sills",
    "description": "Window sealing and sill condition",
    "optionMappings": {
      "Good": "OK",
      "Fair": "Repair soon",
      "Poor": "Repair now",
      "Failed": "Repair now"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to window_sills Excel field"
  },

  "door_condition": {
    "appField": "door_condition",
    "appLabel": "Door Condition",
    "excelField": "door_sampling",
    "excelLabel": "Door Sampling",
    "description": "Overall door condition",
    "optionMappings": {
      "Good": "OK",
      "Fair": "Repair",
      "Poor": "Repair",
      "Replacement Needed": "Repair"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to door_sampling Excel field"
  },

  "foundation_type": {
    "appField": "foundation_type",
    "appLabel": "Foundation Type",
    "excelField": "walls",
    "excelLabel": "Walls",
    "description": "Type of foundation",
    "optionMappings": {
      "Strip": "Construction",
      "Raft": "Construction",
      "Piled": "Construction",
      "Unknown": "Construction",
      "Not Visible": "Construction"
    },
    "status": "mapped",
    "confidence": "low",
    "tested": false,
    "notes": "Maps to walls Construction option. May need separate foundation field."
  }
};

// Add new mappings
Object.assign(mappings, structuralMappings);

// Update meta
const totalMapped = Object.keys(mappings).filter(k => k !== '_meta').length;
mappings._meta.mappedFields = totalMapped;
mappings._meta.lastUpdated = new Date().toISOString().split('T')[0];

// Save
fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log('='.repeat(100));
console.log('STRUCTURAL MAPPINGS ADDED (BATCH 2)');
console.log('='.repeat(100));
console.log(`\n✅ Added ${Object.keys(structuralMappings).length} structural field mappings`);
console.log(`📊 Total mappings: ${totalMapped}/${mappings._meta.totalAppFields}`);
console.log(`📈 Coverage: ${Math.round(totalMapped/mappings._meta.totalAppFields*100)}%`);
console.log(`\n💾 Saved to: ${mappingFile}`);

console.log('\n' + '='.repeat(100));
console.log('STRUCTURAL MAPPINGS BREAKDOWN');
console.log('='.repeat(100));

const byConfidence = {
  high: [],
  medium: [],
  low: []
};

Object.keys(structuralMappings).forEach(key => {
  const mapping = structuralMappings[key];
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

console.log('\n🏠 Roof & Structure:');
console.log('  • Roof Covering, Roof Lining, Roof Spreading');
console.log('  • Loft Insulation, Removed Chimney Breast');

console.log('\n🧱 Walls & Dampness:');
console.log('  • Damp Proof Course, Damp Type, Damp Locations');
console.log('  • Removed Wall, Party Wall Problem, Foundation Type');
console.log('  • Cracks Noted');

console.log('\n📐 Floors & Ceilings:');
console.log('  • Floor Build Type, Sloping Floor, Uneven Floor');
console.log('  • Ceiling Condition');

console.log('\n🪟 Windows & Doors:');
console.log('  • Window Replacement, Window Sealing');
console.log('  • Door Condition');

console.log('\n🐛 Defects:');
console.log('  • Insect Infestation');

console.log('\n' + '='.repeat(100));
