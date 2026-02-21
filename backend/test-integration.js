/**
 * Integration Test - Template System with Report Generation
 * Demonstrates the complete flow from form data to final report with Excel phrases
 */

const phraseLibrary = require('./excel-phrase-library.json');
const { ExcelPhraseGeneratorService } = require('./dist/src/services/excel-phrase-generator.service');

console.log('='.repeat(100));
console.log('INTEGRATION TEST - Template System with Report Generation');
console.log('='.repeat(100));

// Simulate form data from a real survey section
const surveyFormData = {
  // Property section
  property_type: 'Detached House',
  property_subtype: 'detached',
  num_bedrooms: '4',
  bedrooms: 'four',
  construction_type: 'Traditional',

  // Weather section
  weather_current: 'dry',
  weather_previous: 'wet',

  // Overall opinion
  overall_opinion: 'Reasonable',
  purchase_price: '£545,000.00',

  // Party disclosure
  party_disclosure: 'None',
};

console.log('\n📋 FORM DATA:');
console.log(JSON.stringify(surveyFormData, null, 2));

// Test field mappings (these would come from your manual mapping config)
const fieldMappings = [
  { excelField: 'property_type', excelOption: 'House' },
  { excelField: 'weather', excelOption: 'Now / Before' },
  { excelField: 'overall_opinion', excelOption: 'Reasonable' },
  { excelField: 'party_disclosures', excelOption: 'None' },
];

console.log('\n\n📝 GENERATING PHRASES FROM EXCEL TEMPLATES:');
console.log('='.repeat(100));

// Simulate the service (we can't use DI outside NestJS, so we'll use the compiled class directly)
const TemplateRendererService = require('./dist/src/services/template-renderer.service').TemplateRendererService;

const results = [];

for (const mapping of fieldMappings) {
  const { excelField, excelOption } = mapping;

  // Get the Excel field data
  const field = phraseLibrary[excelField];
  if (!field) {
    console.log(`\n❌ Field not found: ${excelField}`);
    continue;
  }

  const option = field.options[excelOption];
  if (!option) {
    console.log(`\n❌ Option not found: ${excelField}.${excelOption}`);
    continue;
  }

  const template = option.phrase;

  console.log(`\n\n${'─'.repeat(100)}`);
  console.log(`📌 Field: ${field.displayName}`);
  console.log(`📌 Option: ${excelOption}`);
  console.log(`\n📄 Template:\n   ${template}`);

  // Render the template with form data
  const renderResult = TemplateRendererService.render(template, surveyFormData);
  const finalPhrase = TemplateRendererService.cleanText(renderResult.renderedText);

  console.log(`\n✅ Generated Phrase:\n   ${finalPhrase}`);

  if (renderResult.substitutions.length > 0) {
    console.log(`\n🔧 Substitutions:`);
    for (const sub of renderResult.substitutions) {
      console.log(`   • ${sub.placeholder} → "${sub.replacedWith}" (confidence: ${(sub.confidence * 100).toFixed(0)}%)`);
    }
  }

  if (renderResult.unmatchedPlaceholders.length > 0) {
    console.log(`\n⚠️  Unmatched placeholders (used defaults):`);
    for (const placeholder of renderResult.unmatchedPlaceholders) {
      console.log(`   • ${placeholder}`);
    }
  }

  results.push({
    field: field.displayName,
    option: excelOption,
    template,
    phrase: finalPhrase,
    substitutions: renderResult.substitutions.length,
    success: renderResult.success,
    confidence: renderResult.substitutions.length > 0
      ? renderResult.substitutions.reduce((sum, s) => sum + s.confidence, 0) / renderResult.substitutions.length
      : 1.0,
  });
}

console.log('\n\n' + '='.repeat(100));
console.log('📊 GENERATION SUMMARY');
console.log('='.repeat(100));

console.log(`\nTotal fields processed: ${results.length}`);
console.log(`Successful generations: ${results.filter(r => r.success).length}`);
console.log(`Total substitutions: ${results.reduce((sum, r) => sum + r.substitutions, 0)}`);
console.log(`Average confidence: ${(results.reduce((sum, r) => sum + r.confidence, 0) / results.length * 100).toFixed(0)}%`);

console.log('\n\n📄 FINAL REPORT NARRATIVE:');
console.log('='.repeat(100));

for (const result of results) {
  if (result.phrase) {
    console.log(`\n${result.phrase}`);
  }
}

console.log('\n\n' + '='.repeat(100));
console.log('✅ INTEGRATION TEST COMPLETE!');
console.log('='.repeat(100));
console.log('\nThe template system is now integrated into the report generation flow.');
console.log('When a user generates a report:');
console.log('  1. The system checks each field against the Excel phrase library');
console.log('  2. If found, it renders the template with form values');
console.log('  3. Placeholders are intelligently matched and substituted');
console.log('  4. The final professional phrase is included in the report');
console.log('  5. Only fields without Excel phrases will use AI generation');
console.log('\nNext step: Manual field mapping for all 130 app fields!');
console.log('='.repeat(100));
