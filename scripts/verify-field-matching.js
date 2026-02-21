/**
 * Verify app fields match Excel fields
 * Shows which fields match, which don't, and which need manual mapping
 */
const fs = require('fs');

// Load data
const appFields = JSON.parse(fs.readFileSync('./backend/app-fields.json', 'utf-8'));
const excelLibrary = JSON.parse(fs.readFileSync('./backend/excel-phrase-library.json', 'utf-8'));

console.log('='.repeat(100));
console.log('FIELD MATCHING VERIFICATION');
console.log('='.repeat(100));

const results = {
  perfectMatches: [],
  partialMatches: [],
  noMatches: [],
  excelOnly: [],
};

// Helper: normalize for comparison
function normalize(str) {
  return str.toLowerCase().replace(/[^a-z0-9]/g, '');
}

// Check each app field
for (const appField of appFields) {
  const appKey = appField.key;
  const appLabel = appField.label;
  const appOptions = appField.options || [];

  // Try to find in Excel
  const excelKey = appKey; // Already normalized in library
  const excelField = excelLibrary[excelKey];

  if (excelField) {
    // Field found! Now check options
    const excelOptions = Object.keys(excelField.options);

    // Count how many app options have Excel phrases
    let matchedOptions = 0;
    const optionDetails = [];

    for (const appOption of appOptions) {
      const found = excelOptions.some(excelOpt =>
        normalize(excelOpt) === normalize(appOption) ||
        excelOpt === appOption
      );

      if (found) {
        matchedOptions++;
        optionDetails.push({ appOption, status: '✓ MATCHED' });
      } else {
        optionDetails.push({ appOption, status: '✗ NO PHRASE' });
      }
    }

    const matchPercent = appOptions.length > 0
      ? Math.round((matchedOptions / appOptions.length) * 100)
      : 0;

    if (matchPercent === 100) {
      results.perfectMatches.push({
        appKey,
        appLabel,
        excelField: excelField.displayName,
        appOptions: appOptions.length,
        matchedOptions,
        optionDetails,
      });
    } else if (matchPercent > 0) {
      results.partialMatches.push({
        appKey,
        appLabel,
        excelField: excelField.displayName,
        appOptions: appOptions.length,
        matchedOptions,
        matchPercent,
        optionDetails,
      });
    } else {
      results.noMatches.push({
        appKey,
        appLabel,
        excelField: excelField.displayName,
        reason: 'Options do not match',
        appOptions,
        excelOptions,
      });
    }
  } else {
    // No Excel field found
    results.noMatches.push({
      appKey,
      appLabel,
      excelField: null,
      reason: 'No Excel field found',
      appOptions: appOptions.length,
    });
  }
}

// Check for Excel fields not in app
const appKeys = new Set(appFields.map(f => f.key));
for (const [excelKey, excelData] of Object.entries(excelLibrary)) {
  if (!appKeys.has(excelKey)) {
    results.excelOnly.push({
      excelKey,
      excelField: excelData.displayName,
      options: Object.keys(excelData.options).length,
    });
  }
}

// Print results
console.log(`\n${'='.repeat(100)}`);
console.log('✅ PERFECT MATCHES (100% options matched)');
console.log('='.repeat(100));
console.log(`Total: ${results.perfectMatches.length} fields\n`);

results.perfectMatches.slice(0, 10).forEach(match => {
  console.log(`${match.appKey}`);
  console.log(`  App: ${match.appLabel}`);
  console.log(`  Excel: ${match.excelField}`);
  console.log(`  Options: ${match.matchedOptions}/${match.appOptions} matched`);
  match.optionDetails.forEach(opt => {
    console.log(`    - ${opt.appOption} ${opt.status}`);
  });
  console.log('');
});

if (results.perfectMatches.length > 10) {
  console.log(`... and ${results.perfectMatches.length - 10} more\n`);
}

console.log(`\n${'='.repeat(100)}`);
console.log('⚠️  PARTIAL MATCHES (some options matched)');
console.log('='.repeat(100));
console.log(`Total: ${results.partialMatches.length} fields\n`);

results.partialMatches.forEach(match => {
  console.log(`${match.appKey} (${match.matchPercent}% matched)`);
  console.log(`  App: ${match.appLabel}`);
  console.log(`  Excel: ${match.excelField}`);
  console.log(`  Matched: ${match.matchedOptions}/${match.appOptions} options`);
  match.optionDetails.forEach(opt => {
    console.log(`    - ${opt.appOption} ${opt.status}`);
  });
  console.log('');
});

console.log(`\n${'='.repeat(100)}`);
console.log('❌ NO MATCHES');
console.log('='.repeat(100));
console.log(`Total: ${results.noMatches.length} fields\n`);

results.noMatches.slice(0, 15).forEach(field => {
  console.log(`${field.appKey}`);
  console.log(`  App: ${field.appLabel}`);
  console.log(`  Excel: ${field.excelField || 'NOT FOUND'}`);
  console.log(`  Reason: ${field.reason}`);
  console.log('');
});

if (results.noMatches.length > 15) {
  console.log(`... and ${results.noMatches.length - 15} more\n`);
}

console.log(`\n${'='.repeat(100)}`);
console.log('📊 SUMMARY');
console.log('='.repeat(100));
console.log(`App fields total: ${appFields.length}`);
console.log(`Excel fields total: ${Object.keys(excelLibrary).length}`);
console.log(`Perfect matches: ${results.perfectMatches.length} (${Math.round(results.perfectMatches.length / appFields.length * 100)}%)`);
console.log(`Partial matches: ${results.partialMatches.length} (${Math.round(results.partialMatches.length / appFields.length * 100)}%)`);
console.log(`No matches: ${results.noMatches.length} (${Math.round(results.noMatches.length / appFields.length * 100)}%)`);
console.log(`Excel-only fields: ${results.excelOnly.length}`);

// Save detailed report
fs.writeFileSync('./backend/field-matching-report.json', JSON.stringify(results, null, 2));
console.log(`\n✓ Detailed report saved to: backend/field-matching-report.json`);
