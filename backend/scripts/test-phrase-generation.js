/**
 * Test Actual Phrase Generation
 * Verify that phrases are generated correctly with real data
 */

const mappings = require('../field-mapping-config.json');
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('TESTING ACTUAL PHRASE GENERATION');
console.log('='.repeat(100));

// Helper function to generate phrase (simplified version)
function generatePhrase(fieldKey, optionValue, allFormData = {}) {
  // Find mapping
  const mapping = mappings[fieldKey] || Object.values(mappings).find(m => m.appField === fieldKey);

  if (!mapping) {
    return { success: false, error: 'No mapping found' };
  }

  // Get Excel field
  const excelField = phraseLibrary[mapping.excelField];
  if (!excelField) {
    return { success: false, error: `Excel field '${mapping.excelField}' not found` };
  }

  // Get Excel option
  const excelOption = mapping.optionMappings?.[optionValue];
  if (!excelOption) {
    return { success: false, error: `No option mapping for '${optionValue}'` };
  }

  // Get phrase template
  const phraseTemplate = excelField.options[excelOption];
  if (!phraseTemplate) {
    return { success: false, error: `Excel option '${excelOption}' not found in library` };
  }

  const template = phraseTemplate.phrase || phraseTemplate;

  // Simple template substitution (just for testing)
  let phrase = template;
  const placeholderRegex = /\(([^)]+)\)/g;
  phrase = phrase.replace(placeholderRegex, (match, content) => {
    const options = content.split('/');
    return options[0]; // Just use first option for testing
  });

  return {
    success: true,
    phrase,
    template,
    mapping: {
      appField: mapping.appField,
      excelField: mapping.excelField,
      appOption: optionValue,
      excelOption: excelOption,
      confidence: mapping.confidence
    }
  };
}

// Test cases with real-world data
console.log('\nTESTING SAMPLE PHRASES:\n');

const testCases = [
  { field: 'weather_current', value: 'Dry' },
  { field: 'overall_opinion', value: 'Reasonable' },
  { field: 'damp_type', value: 'Rising Damp' },
  { field: 'floor_build_type', value: 'Solid' },
  { field: 'energy_efficiency', value: 'C' },
  { field: 'construction_type', value: 'Detached' },
  { field: 'timber_rot', value: 'None' },
  { field: 'heating_type', value: 'Gas Central' },
  { field: 'num_bathrooms', value: '2' },
  { field: 'garden_type', value: 'Both' }
];

let passCount = 0;
let failCount = 0;

testCases.forEach(test => {
  const result = generatePhrase(test.field, test.value);

  if (result.success) {
    passCount++;
    console.log(`✅ ${test.field} = "${test.value}":`);
    console.log(`   Confidence: ${result.mapping.confidence}`);
    console.log(`   Excel: ${result.mapping.excelField} / ${result.mapping.excelOption}`);
    console.log(`   Template: ${result.template.substring(0, 60)}${result.template.length > 60 ? '...' : ''}`);
    console.log(`   Generated: ${result.phrase.substring(0, 80)}${result.phrase.length > 80 ? '...' : ''}`);
  } else {
    failCount++;
    console.log(`❌ ${test.field} = "${test.value}": ${result.error}`);
  }
  console.log('');
});

console.log('='.repeat(100));
console.log(`TEST RESULTS: ${passCount} passed, ${failCount} failed`);
if (failCount === 0) {
  console.log('✅ ALL PHRASE GENERATION TESTS PASSED');
} else {
  console.log('❌ SOME TESTS FAILED - REVIEW NEEDED');
}
console.log('='.repeat(100));
