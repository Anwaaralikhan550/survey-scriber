/**
 * Build a complete, ready-to-use phrase mapping for report generation
 * This creates a JSON file that maps field keys to their Excel phrases
 */
const fs = require('fs');

const excelMapping = JSON.parse(fs.readFileSync('./backend/excel-field-mapping.json', 'utf-8'));

// Create comprehensive phrase library organized by field
const phraseLibrary = {};

// Convert Excel data to field-key based structure
for (const [excelFieldName, excelData] of Object.entries(excelMapping)) {
  const options = excelData.options;

  if (!options || Object.keys(options).length === 0) continue;

  // Create field key from Excel field name
  const fieldKey = excelFieldName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');

  phraseLibrary[fieldKey] = {
    excelFieldName: excelFieldName,
    displayName: excelFieldName,
    row: excelData.row,
    options: {}
  };

  // Add each option with its phrase
  for (const [optionValue, phraseText] of Object.entries(options)) {
    phraseLibrary[fieldKey].options[optionValue] = {
      value: optionValue,
      phrase: phraseText,
      phraseLength: phraseText.length
    };
  }
}

// Save complete library
const outputPath = './backend/excel-phrase-library.json';
fs.writeFileSync(outputPath, JSON.stringify(phraseLibrary, null, 2));

console.log('✅ Complete phrase library created!');
console.log(`📄 Saved to: ${outputPath}`);
console.log(`📊 Total fields: ${Object.keys(phraseLibrary).length}`);

// Print summary
console.log('\n' + '='.repeat(100));
console.log('PHRASE LIBRARY SUMMARY');
console.log('='.repeat(100));

Object.keys(phraseLibrary).slice(0, 20).forEach(key => {
  const field = phraseLibrary[key];
  console.log(`\n${key}`);
  console.log(`  Excel: ${field.excelFieldName}`);
  console.log(`  Options: ${Object.keys(field.options).length}`);

  // Show first 2 options
  Object.keys(field.options).slice(0, 2).forEach(opt => {
    const phrase = field.options[opt].phrase;
    console.log(`    - "${opt}": ${phrase.substring(0, 80)}...`);
  });
});

console.log(`\n\n✅ Ready to use in report generation!`);
