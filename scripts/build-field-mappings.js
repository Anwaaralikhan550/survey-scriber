/**
 * Interactive tool to build complete field mappings
 * Goes through each app field and helps map to Excel
 */
const fs = require('fs');

const appFields = JSON.parse(fs.readFileSync('./backend/app-fields.json', 'utf-8'));
const excelLibrary = JSON.parse(fs.readFileSync('./backend/excel-phrase-library.json', 'utf-8'));
const existingMapping = JSON.parse(fs.readFileSync('./backend/field-mapping-config.json', 'utf-8'));

console.log('='.repeat(100));
console.log('FIELD MAPPING BUILDER');
console.log('='.repeat(100));
console.log('\nThis tool helps you map all 130 app fields to Excel fields.\n');

// Prepare output
const output = {
  _description: "Manual mapping between app field keys and Excel field keys",
  _instructions: "For each app field, specify which Excel field it maps to, and map each option",
  _rules: [
    "If no Excel field exists, set excelField to null",
    "If option has no Excel phrase, set to null",
    "100% Excel phrases required - no AI fallback"
  ],
  _stats: {
    totalAppFields: appFields.length,
    totalExcelFields: Object.keys(excelLibrary).length,
    mappedFields: 0,
    unmappedFields: 0,
  },
  mappings: {}
};

console.log('Available Excel Fields:');
console.log('='.repeat(100));
const excelFields = Object.keys(excelLibrary).sort();
excelFields.forEach((key, idx) => {
  const field = excelLibrary[key];
  console.log(`${String(idx + 1).padStart(3)}. ${key.padEnd(40)} - ${field.displayName} (${Object.keys(field.options).length} options)`);
});

console.log('\n' + '='.repeat(100));
console.log('\nApp Fields to Map:');
console.log('='.repeat(100));

// Group fields by similarity to Excel
const suggestions = {};

appFields.forEach(appField => {
  const appKey = appField.key;
  const appLabel = appField.label;
  const appOptions = appField.options || [];

  // Try to find similar Excel field
  let suggestedExcel = null;
  let suggestedScore = 0;

  for (const excelKey of excelFields) {
    const excelField = excelLibrary[excelKey];

    // Simple similarity: check if labels match
    const labelSim = appLabel.toLowerCase().includes(excelField.displayName.toLowerCase()) ||
                     excelField.displayName.toLowerCase().includes(appLabel.toLowerCase());

    const keySim = appKey.toLowerCase().replace(/_/g, '') === excelKey.toLowerCase().replace(/_/g, '');

    if (keySim) {
      suggestedExcel = excelKey;
      suggestedScore = 100;
      break;
    } else if (labelSim) {
      suggestedExcel = excelKey;
      suggestedScore = 75;
    }
  }

  suggestions[appKey] = {
    appLabel,
    appOptions,
    suggestedExcel,
    suggestedScore,
  };
});

// Output template for manual completion
appFields.forEach((appField, idx) => {
  const appKey = appField.key;
  const suggestion = suggestions[appKey];

  console.log(`\n${idx + 1}. ${appKey}`);
  console.log(`   Label: ${suggestion.appLabel}`);
  console.log(`   Options: ${suggestion.appOptions.join(', ')}`);

  if (suggestion.suggestedExcel) {
    const excelField = excelLibrary[suggestion.suggestedExcel];
    const excelOptions = Object.keys(excelField.options);
    console.log(`   ✓ Suggested Excel: ${suggestion.suggestedExcel} (${excelOptions.join(', ')})`);
  } else {
    console.log(`   ✗ No Excel match found`);
  }

  // Create template mapping
  const templateOptions = {};
  suggestion.appOptions.forEach(opt => {
    templateOptions[opt] = null; // User needs to fill this
  });

  output.mappings[appKey] = {
    excelField: suggestion.suggestedExcel || null,
    options: templateOptions,
    notes: suggestion.suggestedExcel
      ? `Auto-suggested: ${excelLibrary[suggestion.suggestedExcel].displayName}`
      : "No Excel field found - needs manual mapping or set to null",
    _appLabel: suggestion.appLabel,
    _appOptions: suggestion.appOptions.length,
  };
});

// Save template
fs.writeFileSync('./backend/field-mapping-template.json', JSON.stringify(output, null, 2));

console.log('\n' + '='.repeat(100));
console.log('✓ Template created: backend/field-mapping-template.json');
console.log('\nNext steps:');
console.log('1. Review the template file');
console.log('2. For each field:');
console.log('   - Set excelField to the correct Excel field key (or null if none)');
console.log('   - Map each option to an Excel option (or null if none)');
console.log('3. Save as field-mapping-config.json');
console.log('4. Run validation: node scripts/validate-mapping.js');
console.log('='.repeat(100));
