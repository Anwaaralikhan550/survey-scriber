/**
 * Extract phrases from Excel database for hardcoded report mapping
 */
const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');

const excelPath = path.join(__dirname, '..', 'reports', 'HB APP Database.xlsx');
const outputPath = path.join(__dirname, '..', 'backend', 'excel-phrases-mapping.json');

console.log('Reading Excel file:', excelPath);
const workbook = XLSX.readFile(excelPath);

// Process all sheets
const allPhrases = {};

workbook.SheetNames.forEach(sheetName => {
  console.log(`\n=== Processing Sheet: ${sheetName} ===`);
  const sheet = workbook.Sheets[sheetName];
  const data = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });

  // Try to identify field patterns
  const fields = {};

  for (let rowIdx = 0; rowIdx < Math.min(data.length, 500); rowIdx++) {
    const row = data[rowIdx];

    for (let colIdx = 0; colIdx < row.length; colIdx++) {
      const cell = row[colIdx];

      if (typeof cell === 'string' && cell.trim().length > 0) {
        // Look for potential field labels (short text, possibly with colons)
        const trimmed = cell.trim();

        // Check if this looks like a field label (capitalized, short)
        const isLabel = trimmed.length < 50 &&
                       trimmed[0] === trimmed[0].toUpperCase() &&
                       !trimmed.includes('\n') &&
                       (trimmed.includes(':') || /^[A-Z][a-z\s]+/.test(trimmed));

        if (isLabel) {
          const fieldKey = trimmed.replace(':', '').trim();

          // Get potential values from adjacent cells
          const values = [];

          // Check cells below (up to 5 rows)
          for (let offset = 1; offset <= 5 && rowIdx + offset < data.length; offset++) {
            const valueCell = data[rowIdx + offset][colIdx];
            if (valueCell && typeof valueCell === 'string' && valueCell.trim()) {
              values.push(valueCell.trim());
            }
          }

          // Check cells to the right (up to 3 columns)
          for (let offset = 1; offset <= 3 && colIdx + offset < row.length; offset++) {
            const valueCell = row[colIdx + offset];
            if (valueCell && typeof valueCell === 'string' && valueCell.trim()) {
              values.push(valueCell.trim());
            }
          }

          if (values.length > 0) {
            if (!fields[fieldKey]) {
              fields[fieldKey] = new Set();
            }
            values.forEach(v => {
              if (v.length > 10 && v.length < 2000) { // Filter reasonable phrase lengths
                fields[fieldKey].add(v);
              }
            });
          }
        }
      }
    }
  }

  // Convert sets to arrays
  Object.keys(fields).forEach(key => {
    fields[key] = Array.from(fields[key]);
  });

  allPhrases[sheetName] = fields;

  // Print summary
  console.log(`Found ${Object.keys(fields).length} potential fields`);
  Object.keys(fields).slice(0, 5).forEach(key => {
    console.log(`  - ${key}: ${fields[key].length} phrases`);
  });
});

// Save to file
fs.writeFileSync(outputPath, JSON.stringify(allPhrases, null, 2));
console.log(`\n✓ Saved to: ${outputPath}`);

// Also create a flattened view for easier browsing
const flattenedPath = path.join(__dirname, '..', 'backend', 'excel-phrases-flat.txt');
let flatText = '';

Object.keys(allPhrases).forEach(sheetName => {
  flatText += `\n${'='.repeat(80)}\n`;
  flatText += `SHEET: ${sheetName}\n`;
  flatText += `${'='.repeat(80)}\n\n`;

  const fields = allPhrases[sheetName];
  Object.keys(fields).sort().forEach(fieldKey => {
    flatText += `\n### ${fieldKey}\n`;
    flatText += `${'-'.repeat(40)}\n`;
    fields[fieldKey].forEach((phrase, idx) => {
      flatText += `[${idx + 1}] ${phrase.substring(0, 200)}${phrase.length > 200 ? '...' : ''}\n`;
    });
  });
});

fs.writeFileSync(flattenedPath, flatText);
console.log(`✓ Saved flattened view to: ${flattenedPath}`);
