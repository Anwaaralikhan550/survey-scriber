/**
 * Extract phrases from Excel in a structured column-by-column format
 */
const XLSX = require('xlsx');
const fs = require('path');

const excelPath = './reports/HB APP Database.xlsx';
const workbook = XLSX.readFile(excelPath);
const sheet = workbook.Sheets[workbook.SheetNames[0]];

// Convert to array of arrays
const data = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: null });

console.log(`Total rows: ${data.length}`);
console.log(`\n${'='.repeat(100)}\n`);

// Process each column
const maxCols = Math.max(...data.map(row => row.length));

for (let col = 0; col < Math.min(maxCols, 30); col++) {
  const colLetter = XLSX.utils.encode_col(col);
  console.log(`\n### COLUMN ${colLetter} (Index ${col}) ###`);
  console.log('-'.repeat(80));

  let fieldName = null;
  let options = [];
  let phrases = [];

  for (let row = 0; row < Math.min(data.length, 300); row++) {
    const cell = data[row][col];

    if (cell === null || cell === undefined || cell === '') continue;

    const cellStr = String(cell).trim();

    // Skip very long text (likely phrases)
    if (cellStr.length > 200) continue;

    console.log(`  [Row ${row + 1}] ${cellStr.substring(0, 100)}${cellStr.length > 100 ? '...' : ''}`);
  }

  console.log('');
}
