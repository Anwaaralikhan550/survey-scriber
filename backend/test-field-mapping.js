/**
 * Test Field Mapping
 * Verifies that our field mappings work correctly with phrase generation
 */

const phraseLibrary = require('./excel-phrase-library.json');
const fieldMappings = require('./field-mapping-config.json');
const TemplateRendererService = require('./dist/src/services/template-renderer.service').TemplateRendererService;

console.log('='.repeat(100));
console.log('FIELD MAPPING TEST');
console.log('='.repeat(100));

// Function to generate phrase using field mapping
function generatePhraseFromMapping(appFieldKey, appOptionValue, formData) {
  // Get the field mapping
  const mapping = fieldMappings[appFieldKey];

  if (!mapping) {
    return {
      success: false,
      error: `No mapping found for app field: ${appFieldKey}`,
    };
  }

  // Get the Excel option for this app option
  const excelOption = mapping.optionMappings[appOptionValue];

  if (!excelOption) {
    return {
      success: false,
      error: `No Excel option mapping for: ${appFieldKey}.${appOptionValue}`,
    };
  }

  // Get the Excel field
  const excelField = phraseLibrary[mapping.excelField];

  if (!excelField) {
    return {
      success: false,
      error: `Excel field not found: ${mapping.excelField}`,
    };
  }

  // Get the Excel option data
  const excelOptionData = excelField.options[excelOption];

  if (!excelOptionData) {
    return {
      success: false,
      error: `Excel option not found: ${mapping.excelField}.${excelOption}`,
    };
  }

  // Get the template
  const template = excelOptionData.phrase;

  // Render the template
  const renderResult = TemplateRendererService.render(template, formData);
  const finalPhrase = TemplateRendererService.cleanText(renderResult.renderedText);

  return {
    success: true, // Always true if we got this far (no errors thrown)
    renderSuccess: renderResult.success, // Whether all placeholders were matched
    appField: appFieldKey,
    appOption: appOptionValue,
    excelField: mapping.excelField,
    excelOption: excelOption,
    template: template,
    phrase: finalPhrase,
    substitutions: renderResult.substitutions,
    unmatchedPlaceholders: renderResult.unmatchedPlaceholders || [],
    confidence: renderResult.substitutions.length > 0
      ? renderResult.substitutions.reduce((sum, s) => sum + s.confidence, 0) / renderResult.substitutions.length
      : 1.0,
  };
}

// Test cases for property_type mapping
const testCases = [
  {
    name: 'Detached House',
    appField: 'property_type',
    appOption: 'Detached House',
    formData: {
      property_type: 'Detached House',
      property_subtype: 'detached',
      num_bedrooms: '4',
      bedrooms: 'four',
    },
  },
  {
    name: 'Semi-Detached House',
    appField: 'property_type',
    appOption: 'Semi-Detached House',
    formData: {
      property_type: 'Semi-Detached House',
      property_subtype: 'semi-detached',
      num_bedrooms: '3',
      bedrooms: 'three',
    },
  },
  {
    name: 'Flat/Apartment',
    appField: 'property_type',
    appOption: 'Flat/Apartment',
    formData: {
      property_type: 'Flat/Apartment',
      num_bedrooms: '2',
      bedrooms: 'two',
    },
  },
  {
    name: 'Bungalow',
    appField: 'property_type',
    appOption: 'Bungalow',
    formData: {
      property_type: 'Bungalow',
      num_bedrooms: '2',
      bedrooms: 'two',
    },
  },
];

console.log(`\n📝 Testing ${testCases.length} property_type mappings...\n`);

let successCount = 0;
let failureCount = 0;

testCases.forEach((testCase, index) => {
  console.log('─'.repeat(100));
  console.log(`\nTEST ${index + 1}: ${testCase.name}`);
  console.log('─'.repeat(100));

  const result = generatePhraseFromMapping(
    testCase.appField,
    testCase.appOption,
    testCase.formData
  );

  if (result.success) {
    successCount++;
    console.log(`✅ SUCCESS`);
    console.log(`\n📱 App Field: ${result.appField} = "${testCase.appOption}"`);
    console.log(`📊 Excel Field: ${result.excelField} = "${result.excelOption}"`);
    console.log(`\n📄 Template:\n   ${result.template}`);
    console.log(`\n✨ Generated Phrase:\n   ${result.phrase}`);

    if (result.substitutions.length > 0) {
      console.log(`\n🔧 Substitutions (${result.substitutions.length}):`);
      result.substitutions.forEach(sub => {
        console.log(`   • ${sub.placeholder} → "${sub.replacedWith}" (${(sub.confidence * 100).toFixed(0)}%)`);
      });
    }

    console.log(`\n📊 Overall Confidence: ${(result.confidence * 100).toFixed(0)}%`);
  } else {
    failureCount++;
    console.log(`❌ FAILURE: ${result.error || 'Unknown error'}`);
    console.log(`\nDebug info:`, JSON.stringify(result, null, 2));
  }
});

console.log('\n\n' + '='.repeat(100));
console.log('TEST SUMMARY');
console.log('='.repeat(100));

console.log(`\n✅ Successful: ${successCount}/${testCases.length} (${Math.round(successCount/testCases.length*100)}%)`);
console.log(`❌ Failed: ${failureCount}/${testCases.length} (${Math.round(failureCount/testCases.length*100)}%)`);

if (successCount === testCases.length) {
  console.log(`\n🎉 ALL TESTS PASSED! The property_type mapping is working correctly.`);
} else {
  console.log(`\n⚠️  Some tests failed. Review the mappings above.`);
}

console.log('\n' + '='.repeat(100));
