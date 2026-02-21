/**
 * Build field -> option -> phrase mapping from Excel
 */
const XLSX = require('xlsx');
const fs = require('fs');

const excelPath = './reports/HB APP Database.xlsx';
const workbook = XLSX.readFile(excelPath);
const sheet = workbook.Sheets[workbook.SheetNames[0]];
const data = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: null });

// Column indices
const COL_FIELD = 1;  // Column B
const COL_OPTION = 5; // Column F
const COL_PHRASE = 6; // Column G

const mapping = {};
let currentField = null;
let fieldStartRow = -1;

for (let row = 2; row < Math.min(data.length, 1000); row++) {
  const fieldName = data[row][COL_FIELD];
  const optionName = data[row][COL_OPTION];
  const phraseText = data[row][COL_PHRASE];

  // Check if this is a new field
  if (fieldName && typeof fieldName === 'string' && fieldName.trim().length > 0) {
    const trimmed = fieldName.trim();

    // Skip section headers
    if (trimmed.includes(':') && !trimmed.toLowerCase().includes('add')) {
      continue;
    }

    // This is a field name
    if (!trimmed.includes('Use ADD') && !trimmed.includes('Default text')) {
      currentField = trimmed;
      fieldStartRow = row;

      if (!mapping[currentField]) {
        mapping[currentField] = {
          row: row + 1,
          options: {}
        };
      }
    }
  }

  // If we have a current field and we found an option+phrase
  if (currentField && optionName && phraseText) {
    const option = String(optionName).trim();
    const phrase = String(phraseText).trim();

    if (option.length > 0 && phrase.length > 10 && phrase.length < 5000) {
      // Skip if option looks like instructions
      if (option.toLowerCase().includes('add text') ||
          option.toLowerCase().includes('select') ||
          option.toLowerCase().includes('if ')) {
        continue;
      }

      mapping[currentField].options[option] = phrase;
    }
  }
}

// Save as JSON
const jsonPath = './backend/excel-field-mapping.json';
fs.writeFileSync(jsonPath, JSON.stringify(mapping, null, 2));
console.log(`✓ Saved mapping to: ${jsonPath}\n`);

// Print summary
console.log('='.repeat(100));
console.log('FIELD -> OPTION -> PHRASE MAPPING');
console.log('='.repeat(100));

Object.keys(mapping).slice(0, 20).forEach(fieldName => {
  console.log(`\n### ${fieldName} (Row ${mapping[fieldName].row})`);
  console.log('-'.repeat(80));

  const options = mapping[fieldName].options;
  Object.keys(options).forEach(option => {
    const phrase = options[option];
    console.log(`\n  [${option}]`);
    console.log(`  → ${phrase.substring(0, 150)}${phrase.length > 150 ? '...' : ''}`);
  });
});

console.log(`\n\n✓ Total fields extracted: ${Object.keys(mapping).length}`);
