/**
 * Field Mapping Assistant
 * Interactive tool to map app fields to Excel fields one by one
 */

const fs = require('fs');
const readline = require('readline');

// Load data
const appFields = require('../app-fields.json');
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('FIELD MAPPING ASSISTANT');
console.log('='.repeat(100));

// Get list of Excel fields
const excelFields = Object.keys(phraseLibrary).map(key => {
  const field = phraseLibrary[key];
  return {
    key,
    name: field.displayName,
    excelName: field.excelFieldName,
    optionCount: Object.keys(field.options).length,
    row: field.row,
  };
});

console.log(`\n📊 Available Data:`);
console.log(`   App Fields: ${appFields.length}`);
console.log(`   Excel Fields: ${excelFields.length}`);

// Load existing mappings if they exist
let mappings = {};
const mappingFile = '../field-mapping-config.json';
if (fs.existsSync(mappingFile)) {
  try {
    mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));
    console.log(`   Existing Mappings: ${Object.keys(mappings).length}`);
  } catch (e) {
    console.log(`   ⚠️  Could not load existing mappings: ${e.message}`);
  }
}

console.log('\n' + '='.repeat(100));

// Helper function to find matching Excel fields
function findExcelMatches(appField) {
  const appKey = appField.key.toLowerCase();
  const appLabel = appField.label.toLowerCase();

  const matches = [];

  for (const excelField of excelFields) {
    const excelKey = excelField.key.toLowerCase();
    const excelName = excelField.name.toLowerCase();

    let score = 0;
    let reasons = [];

    // Exact key match
    if (appKey === excelKey) {
      score += 100;
      reasons.push('exact key match');
    }

    // Key contains match
    if (appKey.includes(excelKey) || excelKey.includes(appKey)) {
      score += 50;
      reasons.push('key similarity');
    }

    // Label/name match
    if (appLabel.includes(excelName) || excelName.includes(appLabel)) {
      score += 30;
      reasons.push('name similarity');
    }

    // Word overlap
    const appWords = appLabel.split(/[\s_-]+/);
    const excelWords = excelName.split(/[\s_-]+/);
    const commonWords = appWords.filter(w => excelWords.includes(w) && w.length > 2);
    if (commonWords.length > 0) {
      score += commonWords.length * 10;
      reasons.push(`${commonWords.length} common words`);
    }

    if (score > 0) {
      matches.push({
        ...excelField,
        score,
        reasons: reasons.join(', '),
      });
    }
  }

  // Sort by score (highest first)
  matches.sort((a, b) => b.score - a.score);

  return matches;
}

// Display field mapping info
function displayField(appField, index) {
  console.log('\n' + '─'.repeat(100));
  console.log(`\n📝 FIELD ${index + 1}/${appFields.length}: ${appField.label}`);
  console.log('─'.repeat(100));

  console.log(`\n📱 App Field:`);
  console.log(`   Key: ${appField.key}`);
  console.log(`   Type: ${appField.type}`);
  console.log(`   Group: ${appField.group || 'N/A'}`);
  console.log(`   Options (${appField.options ? appField.options.length : 0}):`);
  if (appField.options) {
    appField.options.slice(0, 10).forEach(opt => {
      console.log(`      • ${opt}`);
    });
    if (appField.options.length > 10) {
      console.log(`      ... and ${appField.options.length - 10} more`);
    }
  }

  // Check if already mapped
  if (mappings[appField.key]) {
    console.log(`\n✅ ALREADY MAPPED:`);
    console.log(`   Excel Field: ${mappings[appField.key].excelField}`);
    console.log(`   Excel Option: ${mappings[appField.key].excelOption}`);
  }

  // Find suggested matches
  const matches = findExcelMatches(appField);

  if (matches.length > 0) {
    console.log(`\n💡 SUGGESTED EXCEL MATCHES (${matches.length} found):`);
    matches.slice(0, 5).forEach((match, i) => {
      console.log(`\n   ${i + 1}. ${match.name} (${match.key})`);
      console.log(`      Score: ${match.score} - ${match.reasons}`);
      console.log(`      Excel Name: ${match.excelName}`);
      console.log(`      Options: ${match.optionCount} (Row ${match.row})`);

      // Show Excel options
      const excelOptions = Object.keys(phraseLibrary[match.key].options);
      console.log(`      Excel Options: ${excelOptions.slice(0, 5).join(', ')}${excelOptions.length > 5 ? '...' : ''}`);
    });
  } else {
    console.log(`\n⚠️  NO AUTOMATIC MATCHES FOUND`);
    console.log(`   This field may need manual review or might not have a corresponding Excel field.`);
  }

  console.log('\n' + '─'.repeat(100));
}

// Display summary
console.log(`\n📋 FIELD MAPPING SUMMARY\n`);

let mapped = 0;
let unmapped = 0;

appFields.forEach((field, index) => {
  if (mappings[field.key]) {
    mapped++;
  } else {
    unmapped++;
  }
});

console.log(`✅ Mapped: ${mapped}/${appFields.length} (${Math.round(mapped/appFields.length*100)}%)`);
console.log(`⏳ Unmapped: ${unmapped}/${appFields.length} (${Math.round(unmapped/appFields.length*100)}%)`);

console.log('\n' + '='.repeat(100));
console.log('FIELD MAPPING GUIDE');
console.log('='.repeat(100));

// Show first 10 unmapped fields
const unmappedFields = appFields.filter(f => !mappings[f.key]);

console.log(`\nShowing first 10 unmapped fields:\n`);

unmappedFields.slice(0, 10).forEach((field, index) => {
  displayField(field, index);

  const matches = findExcelMatches(field);
  if (matches.length > 0) {
    const topMatch = matches[0];
    console.log(`\n💡 RECOMMENDED ACTION:`);
    console.log(`   Map "${field.key}" to Excel field "${topMatch.key}" (${topMatch.name})`);
    console.log(`   Confidence: ${topMatch.score > 80 ? 'HIGH' : topMatch.score > 40 ? 'MEDIUM' : 'LOW'}`);

    // Show suggested mapping
    if (topMatch.score > 80) {
      console.log(`\n📝 Suggested mapping:`);
      console.log(`   {`);
      console.log(`     "appField": "${field.key}",`);
      console.log(`     "excelField": "${topMatch.key}",`);
      console.log(`     "excelOption": "??? (need to choose based on app options)",`);
      console.log(`     "confidence": "high"`);
      console.log(`   }`);
    }
  }
});

console.log('\n\n' + '='.repeat(100));
console.log('📊 NEXT STEPS');
console.log('='.repeat(100));

console.log(`\n1. Review the suggested matches above`);
console.log(`2. For each field, determine:`);
console.log(`   a) Which Excel field it maps to`);
console.log(`   b) Which Excel option each app option should use`);
console.log(`3. Add mappings to field-mapping-config.json`);
console.log(`4. Test the phrase generation for each mapping`);

console.log('\n' + '='.repeat(100));

// Export unmapped fields for reference
const unmappedFieldsData = unmappedFields.map(f => ({
  appKey: f.key,
  appLabel: f.label,
  appOptions: f.options,
  suggestedExcelField: findExcelMatches(f)[0]?.key || null,
  suggestedExcelName: findExcelMatches(f)[0]?.name || null,
  matchConfidence: findExcelMatches(f)[0]?.score || 0,
}));

fs.writeFileSync(
  'unmapped-fields-reference.json',
  JSON.stringify(unmappedFieldsData, null, 2)
);

console.log(`\n✅ Exported unmapped fields to: unmapped-fields-reference.json`);
console.log('='.repeat(100));
