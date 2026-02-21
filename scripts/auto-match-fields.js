/**
 * Automatically match app fields to Excel fields and generate phrase mapping
 */
const fs = require('fs');

// Load data
const appFields = JSON.parse(fs.readFileSync('./backend/app-fields.json', 'utf-8'));
const excelMapping = JSON.parse(fs.readFileSync('./backend/excel-field-mapping.json', 'utf-8'));

// Fuzzy string matching helper
function similarity(s1, s2) {
  s1 = s1.toLowerCase().replace(/[^a-z0-9]/g, '');
  s2 = s2.toLowerCase().replace(/[^a-z0-9]/g, '');

  if (s1 === s2) return 1.0;

  const longer = s1.length > s2.length ? s1 : s2;
  const shorter = s1.length > s2.length ? s2 : s1;

  if (longer.length === 0) return 1.0;

  let matchCount = 0;
  for (let char of shorter) {
    if (longer.includes(char)) matchCount++;
  }

  return matchCount / longer.length;
}

// Find best Excel match for app field
function findBestExcelMatch(appField) {
  const excelFields = Object.keys(excelMapping);
  let bestMatch = null;
  let bestScore = 0;

  for (const excelField of excelFields) {
    // Compare field labels
    const labelScore = similarity(appField.label, excelField);

    // Bonus for key similarity
    const keyScore = similarity(appField.key.replace(/_/g, ' '), excelField);

    const totalScore = (labelScore * 0.7) + (keyScore * 0.3);

    if (totalScore > bestScore && totalScore > 0.3) {
      bestScore = totalScore;
      bestMatch = excelField;
    }
  }

  return { match: bestMatch, confidence: bestScore };
}

// Match options within a field
function matchOptions(appOptions, excelOptions) {
  const matches = {};

  for (const appOption of appOptions) {
    let bestMatch = null;
    let bestScore = 0;

    for (const excelOption of Object.keys(excelOptions)) {
      const score = similarity(appOption, excelOption);
      if (score > bestScore && score > 0.5) {
        bestScore = score;
        bestMatch = excelOption;
      }
    }

    if (bestMatch) {
      matches[appOption] = {
        excelOption: bestMatch,
        phrase: excelOptions[bestMatch],
        confidence: bestScore,
      };
    }
  }

  return matches;
}

// Main matching process
console.log('='.repeat(100));
console.log('AUTO-MATCHING APP FIELDS TO EXCEL PHRASES');
console.log('='.repeat(100));

const fullMapping = [];
const unmatched = [];

for (const appField of appFields) {
  const excelMatch = findBestExcelMatch(appField);

  if (excelMatch.match) {
    const excelField = excelMapping[excelMatch.match];
    const optionMatches = matchOptions(appField.options, excelField.options);

    if (Object.keys(optionMatches).length > 0) {
      fullMapping.push({
        appFieldKey: appField.key,
        appFieldLabel: appField.label,
        excelFieldName: excelMatch.match,
        confidence: excelMatch.confidence,
        optionMappings: optionMatches,
      });

      console.log(`\n✓ ${appField.key} → ${excelMatch.match} (${(excelMatch.confidence * 100).toFixed(0)}%)`);
      console.log(`  Options matched: ${Object.keys(optionMatches).length}/${appField.options.length}`);

      Object.keys(optionMatches).slice(0, 2).forEach(appOpt => {
        const mapping = optionMatches[appOpt];
        console.log(`    - "${appOpt}" → "${mapping.excelOption}"`);
        console.log(`      Phrase: ${mapping.phrase.substring(0, 80)}...`);
      });
    } else {
      unmatched.push({ appField, reason: 'No options matched' });
    }
  } else {
    unmatched.push({ appField, reason: 'No Excel field match' });
  }
}

// Save mapping
fs.writeFileSync('./backend/field-phrase-mapping.json', JSON.stringify(fullMapping, null, 2));

console.log(`\n\n${'='.repeat(100)}`);
console.log(`✅ MATCHED: ${fullMapping.length} fields`);
console.log(`❌ UNMATCHED: ${unmatched.length} fields`);
console.log('='.repeat(100));

if (unmatched.length > 0) {
  console.log('\nUnmatched fields:');
  unmatched.slice(0, 20).forEach(u => {
    console.log(`  - ${u.appField.key} (${u.appField.label}): ${u.reason}`);
  });
}

console.log(`\n✓ Full mapping saved to: backend/field-phrase-mapping.json`);
