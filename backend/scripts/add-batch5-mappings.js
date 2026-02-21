/**
 * Add Defects & Repairs Mappings (Batch 5)
 * Maps specific defects, damage, repairs, urgency levels
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));

const batch5Mappings = {
  "timber_rot": {
    "appField": "timber_rot",
    "appLabel": "Timber Rot",
    "excelField": "timber_rot",
    "excelLabel": "Timber rot",
    "description": "Evidence of timber rot",
    "optionMappings": {
      "None Noted": "None noted",
      "Wet Rot": "Present",
      "Dry Rot": "Dry rot",
      "Both": "Dry rot",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to timber_rot Excel field"
  },

  "timber_decay": {
    "appField": "timber_decay",
    "appLabel": "Timber Decay",
    "excelField": "timber_decay",
    "excelLabel": "Timber Decay",
    "description": "Timber decay issues",
    "optionMappings": {
      "None": "None noted",
      "Minor": "Present",
      "Moderate": "Significant",
      "Severe": "Significant",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to timber_decay Excel field"
  },

  "undersize_timber": {
    "appField": "undersize_timber",
    "appLabel": "Undersize Timber",
    "excelField": "timber_defect",
    "excelLabel": "Timber Defect",
    "description": "Undersized structural timber",
    "optionMappings": {
      "None Noted": "None noted",
      "Minor Concerns": "Present",
      "Significant": "Significant",
      "Severe": "Significant",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Maps to timber_defect Excel field"
  },

  "heavy_roof": {
    "appField": "heavy_roof",
    "appLabel": "Heavy Roof",
    "excelField": "timber_defect",
    "excelLabel": "Timber Defect",
    "description": "Roof heavier than structure designed for",
    "optionMappings": {
      "Not Applicable": "None noted",
      "No Issues": "None noted",
      "Concerns Noted": "Present",
      "Significant Concerns": "Significant",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Maps to timber_defect as related structural issue"
  },

  "pointing_condition": {
    "appField": "pointing_condition",
    "appLabel": "Pointing Condition",
    "excelField": "pointing",
    "excelLabel": "Pointing",
    "description": "Condition of mortar pointing",
    "optionMappings": {
      "Good": "OK",
      "Fair": "Re-point",
      "Poor": "Problem",
      "Failed": "Problem",
      "Unknown": "OK"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to pointing Excel field"
  },

  "rendering_condition": {
    "appField": "rendering_condition",
    "appLabel": "Rendering Condition",
    "excelField": "render",
    "excelLabel": "Render",
    "description": "Condition of external render",
    "optionMappings": {
      "Good": "OK",
      "Fair": "Repair",
      "Poor": "Problem",
      "Failed": "Problem",
      "Not Applicable": "OK"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to render Excel field"
  },

  "spalling_brickwork": {
    "appField": "spalling_brickwork",
    "appLabel": "Spalling Brickwork",
    "excelField": "spalling",
    "excelLabel": "Spalling",
    "description": "Brick/stone spalling (face deterioration)",
    "optionMappings": {
      "None": "None noted",
      "Minor": "Present",
      "Moderate": "Significant",
      "Severe": "Significant",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to spalling Excel field"
  },

  "structural_movement": {
    "appField": "structural_movement",
    "appLabel": "Structural Movement",
    "excelField": "movements",
    "excelLabel": "Movements",
    "description": "Evidence of structural movement",
    "optionMappings": {
      "None Noted": "None noted",
      "Historical": "Old",
      "Recent": "Recent",
      "Active": "Recent",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to movements Excel field"
  },

  "movement_cracks_severity": {
    "appField": "movement_cracks_severity",
    "appLabel": "Movement Crack Severity",
    "excelField": "movement_cracks",
    "excelLabel": "Movement Cracks",
    "description": "Severity of movement cracks",
    "optionMappings": {
      "None": "None noted",
      "Hairline": "Minor",
      "Minor": "Minor",
      "Significant": "Significant",
      "Severe": "Significant"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to movement_cracks Excel field"
  },

  "chimney_condition": {
    "appField": "chimney_condition",
    "appLabel": "Chimney Condition",
    "excelField": "leaning_chimney",
    "excelLabel": "Leaning Chimney",
    "description": "Overall chimney condition",
    "optionMappings": {
      "Good": "None noted",
      "Fair": "Location",
      "Poor": "Repair soon",
      "Leaning": "Leaning",
      "Dangerous": "Dangerous",
      "Not Applicable": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to leaning_chimney Excel field"
  },

  "chimney_pots": {
    "appField": "chimney_pots",
    "appLabel": "Chimney Pots Condition",
    "excelField": "chimney_pots_repair_soon",
    "excelLabel": "Chimney Pots Repair soon",
    "description": "Chimney pots condition",
    "optionMappings": {
      "Good": "None",
      "Repair Needed": "Repair soon",
      "Not Applicable": "None"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to chimney_pots_repair_soon"
  },

  "flaunching_condition": {
    "appField": "flaunching_condition",
    "appLabel": "Flaunching Condition",
    "excelField": "flaunching_repair_soon",
    "excelLabel": "Flaunching Repair soon",
    "description": "Chimney flaunching condition",
    "optionMappings": {
      "Good": "None",
      "Repair Needed": "Repair soon",
      "Not Applicable": "None"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to flaunching_repair_soon"
  },

  "flashing_condition": {
    "appField": "flashing_condition",
    "appLabel": "Flashing Condition",
    "excelField": "flashing_repair_soon",
    "excelLabel": "Flashing Repair soon",
    "description": "Roof flashing condition",
    "optionMappings": {
      "Good": "None",
      "Fair": "Repair soon",
      "Poor": "Repair soon",
      "Failed": "Repair soon"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to flashing_repair_soon"
  },

  "ridge_tiles_condition": {
    "appField": "ridge_tiles_condition",
    "appLabel": "Ridge Tiles Condition",
    "excelField": "ridge_tiles",
    "excelLabel": "Ridge tiles",
    "description": "Ridge tiles condition",
    "optionMappings": {
      "Good": "OK",
      "Repair Needed": "Repair",
      "Poor": "Repair"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to ridge_tiles"
  },

  "verge_condition": {
    "appField": "verge_condition",
    "appLabel": "Verge Condition",
    "excelField": "verge_repair",
    "excelLabel": "Verge Repair",
    "description": "Roof verge condition",
    "optionMappings": {
      "Good": "OK",
      "Repair Needed": "Repair soon",
      "Poor": "Repair now"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to verge_repair"
  },

  "valley_gutter_condition": {
    "appField": "valley_gutter_condition",
    "appLabel": "Valley Gutter Condition",
    "excelField": "valley_gutters_repair",
    "excelLabel": "Valley Gutters Repair",
    "description": "Valley gutter condition",
    "optionMappings": {
      "Good": "OK",
      "Repair Needed": "Repair soon",
      "Poor": "Repair now",
      "Not Applicable": "OK"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to valley_gutters_repair (already mapped gutter_condition, this is more specific)"
  },

  "flat_roof_condition": {
    "appField": "flat_roof_condition",
    "appLabel": "Flat Roof Condition",
    "excelField": "flat_roof_repair",
    "excelLabel": "Flat Roof Repair",
    "description": "Flat roof condition",
    "optionMappings": {
      "Good": "OK",
      "Repair Soon": "Repair soon",
      "Urgent": "Repair now",
      "Not Applicable": "OK"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to flat_roof_repair"
  },

  "parapet_wall_condition": {
    "appField": "parapet_wall_condition",
    "appLabel": "Parapet Wall Condition",
    "excelField": "parapet_wall_repair",
    "excelLabel": "Parapet Wall Repair",
    "description": "Parapet wall condition",
    "optionMappings": {
      "Good": "OK",
      "Repair Soon": "Repair soon",
      "Urgent": "Repair now",
      "Not Applicable": "OK"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to parapet_wall_repair"
  },

  "leak_evidence": {
    "appField": "leak_evidence",
    "appLabel": "Leak Evidence",
    "excelField": "leaking",
    "excelLabel": "Leaking",
    "description": "Evidence of water leaks",
    "optionMappings": {
      "None": "None noted",
      "Historical": "Past",
      "Recent": "Present",
      "Active": "Present",
      "Unknown": "None noted"
    },
    "status": "mapped",
    "confidence": "high",
    "tested": false,
    "notes": "Direct mapping to leaking Excel field"
  },

  "aerial_dish_condition": {
    "appField": "aerial_dish_condition",
    "appLabel": "Aerial/Dish Condition",
    "excelField": "ariel_dish_repair_soon",
    "excelLabel": "Ariel/Dish Repair soon",
    "description": "TV aerial or satellite dish condition",
    "optionMappings": {
      "Good": "None",
      "Repair Needed": "Repair soon",
      "Not Present": "None"
    },
    "status": "mapped",
    "confidence": "medium",
    "tested": false,
    "notes": "Direct mapping to ariel_dish_repair_soon"
  }
};

Object.assign(mappings, batch5Mappings);

const totalMapped = Object.keys(mappings).filter(k => k !== '_meta').length;
mappings._meta.mappedFields = totalMapped;
mappings._meta.lastUpdated = new Date().toISOString().split('T')[0];

fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log('='.repeat(100));
console.log('DEFECTS & REPAIRS MAPPINGS ADDED (BATCH 5)');
console.log('='.repeat(100));
console.log(`\n✅ Added ${Object.keys(batch5Mappings).length} defect/repair field mappings`);
console.log(`📊 Total mappings: ${totalMapped}/${mappings._meta.totalAppFields}`);
console.log(`📈 Coverage: ${Math.round(totalMapped/mappings._meta.totalAppFields*100)}%`);
console.log(`\n💾 Saved to: ${mappingFile}`);

const byConfidence = { high: [], medium: [], low: [] };
Object.keys(batch5Mappings).forEach(key => {
  byConfidence[batch5Mappings[key].confidence].push(batch5Mappings[key].appLabel);
});

console.log('\n' + '='.repeat(100));
console.log(`🟢 High Confidence (${byConfidence.high.length}): ${byConfidence.high.length} fields`);
console.log(`🟡 Medium Confidence (${byConfidence.medium.length}): ${byConfidence.medium.length} fields`);
console.log(`🔴 Low Confidence (${byConfidence.low.length}): ${byConfidence.low.length} fields`);

console.log('\n' + '='.repeat(100));
console.log('DEFECTS BREAKDOWN');
console.log('='.repeat(100));
console.log('\n🪵 Timber: timber_rot, timber_decay, undersize_timber, heavy_roof');
console.log('🧱 Masonry: pointing, rendering, spalling, structural_movement');
console.log('🏚️ Cracks: movement_cracks_severity');
console.log('🏠 Chimney: condition, pots, flaunching');
console.log('🏔️ Roof: flashing, ridge_tiles, verge, valley_gutter, flat_roof, parapet_wall');
console.log('💧 Leaks: leak_evidence');
console.log('📡 Other: aerial_dish');

console.log('\n' + '='.repeat(100));
console.log(`🎯 Coverage: ${Math.round(totalMapped/mappings._meta.totalAppFields*100)}% - ${totalMapped >= 104 ? 'TARGET EXCEEDED!' : `${104 - totalMapped} fields to 80%`}`);
console.log('='.repeat(100));
