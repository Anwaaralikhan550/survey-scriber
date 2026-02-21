/**
 * Extract all fields from the Flutter app
 */
const fs = require('fs');

const sectionFieldsPath = './lib/features/surveys/presentation/widgets/section_fields.dart';
const content = fs.readFileSync(sectionFieldsPath, 'utf-8');

const fields = [];
const lines = content.split('\n');

let currentField = null;
let inOptionsArray = false;
let optionsBuffer = [];

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();

  // Detect new field
  if (line.includes('SectionField(')) {
    if (currentField && currentField.key) {
      fields.push(currentField);
    }
    currentField = { options: [] };
    inOptionsArray = false;
    optionsBuffer = [];
  }

  // Extract key
  if (line.startsWith('key:') && currentField) {
    const match = line.match(/key:\s*'([^']+)'/);
    if (match) currentField.key = match[1];
  }

  // Extract label
  if (line.startsWith('label:') && currentField) {
    const match = line.match(/label:\s*'([^']+)'/);
    if (match) currentField.label = match[1];
  }

  // Extract type
  if (line.startsWith('type:') && currentField) {
    const match = line.match(/type:\s*FieldType\.(\w+)/);
    if (match) currentField.type = match[1];
  }

  // Extract group
  if (line.startsWith('group:') && currentField) {
    const match = line.match(/group:\s*'([^']+)'/);
    if (match) currentField.group = match[1];
  }

  // Detect options array start
  if (line.startsWith('options:') && currentField) {
    inOptionsArray = true;
    // Check if single-line array
    const singleLineMatch = line.match(/options:\s*\[(.*)\]/);
    if (singleLineMatch) {
      const opts = singleLineMatch[1].split(',').map(o => {
        const m = o.trim().match(/'([^']+)'/);
        return m ? m[1] : null;
      }).filter(Boolean);
      currentField.options = opts;
      inOptionsArray = false;
    }
  }

  // Collect multi-line options
  if (inOptionsArray && line.includes("'")) {
    const match = line.match(/'([^']+)'/);
    if (match) {
      optionsBuffer.push(match[1]);
    }
  }

  // Detect options array end
  if (inOptionsArray && line.includes(']')) {
    currentField.options = optionsBuffer;
    inOptionsArray = false;
    optionsBuffer = [];
  }
}

// Push last field
if (currentField && currentField.key) {
  fields.push(currentField);
}

// Filter to only fields with dropdown/radio options
const fieldsWithOptions = fields.filter(f => f.options && f.options.length > 0);

console.log(`Total fields: ${fields.length}`);
console.log(`Fields with options: ${fieldsWithOptions.length}\n`);

// Save to JSON
fs.writeFileSync('./backend/app-fields.json', JSON.stringify(fieldsWithOptions, null, 2));

// Print summary
console.log('='.repeat(100));
console.log('APP FIELDS WITH OPTIONS');
console.log('='.repeat(100));

fieldsWithOptions.slice(0, 30).forEach(field => {
  console.log(`\n${field.key}`);
  console.log(`  Label: ${field.label}`);
  console.log(`  Type: ${field.type}`);
  console.log(`  Group: ${field.group || 'N/A'}`);
  console.log(`  Options (${field.options.length}): ${field.options.join(', ')}`);
});

console.log(`\n\n✓ Saved to: backend/app-fields.json`);
