/**
 * List Low Confidence Mappings
 * Identifies fields that need semantic fixes
 */

const mappings = require('../field-mapping-config.json');

console.log('='.repeat(100));
console.log('LOW CONFIDENCE MAPPINGS REQUIRING SEMANTIC FIXES');
console.log('='.repeat(100));

const lowConfidence = [];

Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (value.confidence === 'low') {
    lowConfidence.push({
      key,
      appField: value.appField,
      excelField: value.excelField,
      optionCount: value.optionMappings ? Object.keys(value.optionMappings).length : 0
    });
  }
});

console.log(`\nFound ${lowConfidence.length} low confidence mappings:\n`);

// Group by Excel field
const byExcelField = {};
lowConfidence.forEach(item => {
  if (!byExcelField[item.excelField]) {
    byExcelField[item.excelField] = [];
  }
  byExcelField[item.excelField].push(item);
});

Object.entries(byExcelField).forEach(([excelField, items]) => {
  console.log(`\n${excelField} (${items.length} mappings):`);
  items.forEach(item => {
    console.log(`  - ${item.appField} (${item.optionCount} options)`);
  });
});

console.log('\n' + '='.repeat(100));
console.log(`\nTotal: ${lowConfidence.length} fields need semantic review`);
console.log('='.repeat(100));
