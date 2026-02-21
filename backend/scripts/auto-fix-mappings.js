/**
 * Auto-Fix Invalid Mappings
 * Updates mappings to use actual Excel option names
 */

const fs = require('fs');
const path = require('path');

const mappingFile = path.join(__dirname, '..', 'field-mapping-config.json');
const mappings = JSON.parse(fs.readFileSync(mappingFile, 'utf-8'));
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('AUTO-FIXING INVALID EXCEL OPTION MAPPINGS');
console.log('='.repeat(100));

let fixedCount = 0;
let unfixableCount = 0;
const fixLog = [];

Object.entries(mappings).forEach(([key, mapping]) => {
  if (key === '_meta') return;

  const excelField = phraseLibrary[mapping.excelField];
  if (!excelField) {
    fixLog.push(`⚠️  ${mapping.appField}: Excel field '${mapping.excelField}' not found`);
    unfixableCount++;
    return;
  }

  const actualOptions = Object.keys(excelField.options);

  // Check each option mapping
  if (mapping.optionMappings) {
    const newOptionMappings = {};
    let hasChanges = false;

    Object.entries(mapping.optionMappings).forEach(([appOption, excelOption]) => {
      if (!excelField.options[excelOption]) {
        // Option doesn't exist - try to fix
        hasChanges = true;

        // Simple fix: use first available option
        if (actualOptions.length > 0) {
          const firstOption = actualOptions[0];
          newOptionMappings[appOption] = firstOption;
          fixLog.push(`   Fixed ${mapping.appField}.${appOption}: "${excelOption}" → "${firstOption}"`);
          fixedCount++;
        } else {
          newOptionMappings[appOption] = excelOption; // Keep original
          fixLog.push(`   ❌ ${mapping.appField}.${appOption}: No options available in ${mapping.excelField}`);
          unfixableCount++;
        }
      } else {
        newOptionMappings[appOption] = excelOption; // Valid, keep it
      }
    });

    if (hasChanges) {
      mapping.optionMappings = newOptionMappings;
      mapping.confidence = 'low'; // Mark as low confidence since auto-fixed
      mapping.notes = (mapping.notes || '') + ' [AUTO-FIXED: Options updated to match Excel library]';
    }
  }
});

// Save fixed mappings
fs.writeFileSync(mappingFile, JSON.stringify(mappings, null, 2));

console.log(`\n✅ Fixed ${fixedCount} invalid option mappings`);
console.log(`❌ Could not fix ${unfixableCount} mappings`);

console.log(`\n📄 Saved updated mappings to: ${mappingFile}`);
console.log('\n' + '='.repeat(100));

// Show sample of fixes
if (fixLog.length > 0) {
  console.log('\nSample fixes (first 30):');
  fixLog.slice(0, 30).forEach(log => console.log(log));
  if (fixLog.length > 30) {
    console.log(`... and ${fixLog.length - 30} more`);
  }
}

console.log('\n' + '='.repeat(100));
console.log('⚠️  WARNING: Auto-fix uses first available option as fallback');
console.log('   Manual review recommended for critical fields');
console.log('='.repeat(100));
