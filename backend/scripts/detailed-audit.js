/**
 * Detailed Audit - Manual Check of Sample Mappings
 */

const mappings = require('../field-mapping-config.json');
const phraseLibrary = require('../excel-phrase-library.json');
const appFields = require('../app-fields.json');

console.log('='.repeat(100));
console.log('DETAILED AUDIT - SAMPLING MAPPINGS FOR SEMANTIC CORRECTNESS');
console.log('='.repeat(100));

// Check 1: Sample high-confidence mappings for semantic correctness
console.log('\n1. CHECKING SAMPLE HIGH CONFIDENCE MAPPINGS:\n');
const highConfidenceSamples = [
  'weather_current', 'overall_opinion', 'damp_type', 'floor_build_type',
  'energy_efficiency', 'ventilation_adequate', 'construction_type',
  'insect_infestation', 'timber_rot', 'structural_movement'
];

highConfidenceSamples.forEach(key => {
  const mapping = mappings[key];
  if (!mapping) {
    console.log(`❌ ${key}: NOT FOUND`);
    return;
  }

  const excelField = phraseLibrary[mapping.excelField];
  if (!excelField) {
    console.log(`❌ ${key}: Excel field '${mapping.excelField}' not found`);
    return;
  }

  console.log(`\n${key} (${mapping.confidence}):`);
  console.log(`  App → Excel: ${mapping.appField} → ${mapping.excelField}`);
  console.log(`  Mappings:`);

  Object.entries(mapping.optionMappings).slice(0, 3).forEach(([appOpt, excelOpt]) => {
    const valid = excelField.options[excelOpt] ? '✅' : '❌';
    console.log(`    ${valid} "${appOpt}" → "${excelOpt}"`);
  });
});

// Check 2: Verify all confidence levels are set
console.log('\n\n2. CHECKING ALL MAPPINGS HAVE CONFIDENCE LEVELS:\n');
let noConfidence = [];
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (!value.confidence) {
    noConfidence.push(key);
  }
});

if (noConfidence.length === 0) {
  console.log('✅ All mappings have confidence levels set');
} else {
  console.log(`❌ ${noConfidence.length} mappings missing confidence:`);
  noConfidence.forEach(k => console.log(`   - ${k}`));
}

// Check 3: Count mappings by Excel field
console.log('\n\n3. MAPPINGS PER EXCEL FIELD:\n');
const byExcelField = {};
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (!byExcelField[value.excelField]) {
    byExcelField[value.excelField] = [];
  }
  byExcelField[value.excelField].push(key);
});

Object.entries(byExcelField)
  .sort((a, b) => b[1].length - a[1].length)
  .slice(0, 10)
  .forEach(([excelField, keys]) => {
    console.log(`  ${excelField}: ${keys.length} mappings`);
  });

// Check 4: Verify all app fields from app-fields.json are covered
console.log('\n\n4. VERIFYING ALL APP FIELDS ARE COVERED:\n');
const mappedAppFields = new Set();
Object.values(mappings).forEach(m => {
  if (m.appField) mappedAppFields.add(m.appField);
});

const unmappedAppFields = appFields.filter(f => !mappedAppFields.has(f.key));
if (unmappedAppFields.length === 0) {
  console.log(`✅ All ${appFields.length} app fields are mapped`);
} else {
  console.log(`❌ ${unmappedAppFields.length} app fields not mapped:`);
  unmappedAppFields.forEach(f => console.log(`   - ${f.key}: ${f.label}`));
}

// Check 5: Check for any app field mapped multiple times
console.log('\n\n5. CHECKING FOR APP FIELDS WITH MULTIPLE MAPPINGS:\n');
const appFieldCounts = {};
Object.values(mappings).forEach(m => {
  if (m.appField) {
    appFieldCounts[m.appField] = (appFieldCounts[m.appField] || 0) + 1;
  }
});

const duplicates = Object.entries(appFieldCounts).filter(([k, v]) => v > 1);
if (duplicates.length === 0) {
  console.log('✅ No app fields have multiple mappings (all 1:1)');
} else {
  console.log(`⚠️  ${duplicates.length} app fields have multiple mappings:`);
  duplicates.forEach(([field, count]) => {
    console.log(`   - ${field}: ${count} mappings`);
  });
}

// Check 6: Statistics summary
console.log('\n\n6. FINAL STATISTICS:\n');
const stats = {
  totalMappings: Object.keys(mappings).length - 1,
  uniqueAppFields: mappedAppFields.size,
  uniqueExcelFields: Object.keys(byExcelField).length,
  highConfidence: Object.values(mappings).filter(m => m.confidence === 'high').length,
  mediumConfidence: Object.values(mappings).filter(m => m.confidence === 'medium').length,
  lowConfidence: Object.values(mappings).filter(m => m.confidence === 'low').length
};

console.log(`  Total mapping entries: ${stats.totalMappings}`);
console.log(`  Unique app fields covered: ${stats.uniqueAppFields}`);
console.log(`  Unique Excel fields used: ${stats.uniqueExcelFields}`);
console.log(`  High confidence: ${stats.highConfidence} (${(stats.highConfidence/stats.totalMappings*100).toFixed(1)}%)`);
console.log(`  Medium confidence: ${stats.mediumConfidence} (${(stats.mediumConfidence/stats.totalMappings*100).toFixed(1)}%)`);
console.log(`  Low confidence: ${stats.lowConfidence} (${(stats.lowConfidence/stats.totalMappings*100).toFixed(1)}%)`);

console.log('\n' + '='.repeat(100));
console.log('AUDIT COMPLETE');
console.log('='.repeat(100));
