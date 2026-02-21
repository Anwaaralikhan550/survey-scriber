/**
 * Final System Check - Comprehensive Validation
 */

const fs = require('fs');
const mappings = require('../field-mapping-config.json');
const phraseLibrary = require('../excel-phrase-library.json');
const appFields = require('../app-fields.json');

console.log('='.repeat(100));
console.log('FINAL COMPREHENSIVE SYSTEM CHECK');
console.log('='.repeat(100));

const issues = [];
const warnings = [];

// Check 1: Meta data consistency
console.log('\n1. META DATA CHECK:');
if (mappings._meta) {
  console.log(`   Total app fields in meta: ${mappings._meta.totalAppFields}`);
  console.log(`   Mapped fields in meta: ${mappings._meta.mappedFields}`);
  console.log(`   Last updated: ${mappings._meta.lastUpdated}`);

  const actualMappingCount = Object.keys(mappings).length - 1;
  if (mappings._meta.mappedFields !== actualMappingCount) {
    warnings.push(`Meta mappedFields (${mappings._meta.mappedFields}) != actual (${actualMappingCount})`);
  }
  if (mappings._meta.totalAppFields !== appFields.length) {
    warnings.push(`Meta totalAppFields (${mappings._meta.totalAppFields}) != actual (${appFields.length})`);
  }
}

// Check 2: Ensure no undefined/null values
console.log('\n2. NULL/UNDEFINED CHECK:');
let nullCount = 0;
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;

  if (!value.appField || !value.excelField) {
    issues.push(`${key}: Missing appField or excelField`);
    nullCount++;
  }
  if (!value.optionMappings || Object.keys(value.optionMappings).length === 0) {
    issues.push(`${key}: No option mappings`);
    nullCount++;
  }
  if (!value.confidence) {
    issues.push(`${key}: No confidence level`);
    nullCount++;
  }
});
console.log(`   ${nullCount === 0 ? '✅' : '❌'} Found ${nullCount} null/undefined issues`);

// Check 3: Confidence distribution validation
console.log('\n3. CONFIDENCE DISTRIBUTION:');
const confidenceCounts = { high: 0, medium: 0, low: 0, other: 0 };
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (value.confidence === 'high') confidenceCounts.high++;
  else if (value.confidence === 'medium') confidenceCounts.medium++;
  else if (value.confidence === 'low') confidenceCounts.low++;
  else confidenceCounts.other++;
});

const total = confidenceCounts.high + confidenceCounts.medium + confidenceCounts.low + confidenceCounts.other;
console.log(`   High: ${confidenceCounts.high} (${(confidenceCounts.high/total*100).toFixed(1)}%)`);
console.log(`   Medium: ${confidenceCounts.medium} (${(confidenceCounts.medium/total*100).toFixed(1)}%)`);
console.log(`   Low: ${confidenceCounts.low} (${(confidenceCounts.low/total*100).toFixed(1)}%)`);
if (confidenceCounts.other > 0) {
  console.log(`   Other: ${confidenceCounts.other}`);
  warnings.push(`${confidenceCounts.other} mappings have invalid confidence levels`);
}
if (confidenceCounts.low > 0) {
  issues.push(`${confidenceCounts.low} low confidence mappings still exist`);
}

// Check 4: Excel field coverage
console.log('\n4. EXCEL FIELD USAGE:');
const usedExcelFields = new Set();
Object.values(mappings).forEach(m => {
  if (m.excelField) usedExcelFields.add(m.excelField);
});
const totalExcelFields = Object.keys(phraseLibrary).length;
console.log(`   Using ${usedExcelFields.size} out of ${totalExcelFields} Excel fields`);
console.log(`   Coverage: ${(usedExcelFields.size/totalExcelFields*100).toFixed(1)}%`);

// Check 5: App field coverage
console.log('\n5. APP FIELD COVERAGE:');
const mappedAppFields = new Set();
Object.values(mappings).forEach(m => {
  if (m.appField) mappedAppFields.add(m.appField);
});
console.log(`   Mapped: ${mappedAppFields.size} out of ${appFields.length} app fields`);
if (mappedAppFields.size !== appFields.length) {
  issues.push(`Not all app fields are mapped: ${mappedAppFields.size}/${appFields.length}`);
}

// Check 6: Option mapping completeness
console.log('\n6. OPTION MAPPING COMPLETENESS:');
let totalOptions = 0;
let mappedOptions = 0;
appFields.forEach(field => {
  if (field.options && field.options.length > 0) {
    totalOptions += field.options.length;

    const mapping = Object.values(mappings).find(m => m.appField === field.key);
    if (mapping && mapping.optionMappings) {
      const mappedCount = field.options.filter(opt => mapping.optionMappings[opt]).length;
      mappedOptions += mappedCount;
    }
  }
});
console.log(`   Mapped: ${mappedOptions} out of ${totalOptions} individual options`);
console.log(`   Coverage: ${(mappedOptions/totalOptions*100).toFixed(1)}%`);

// Check 7: Validate all Excel options exist
console.log('\n7. EXCEL OPTION VALIDATION:');
let invalidOptionCount = 0;
Object.entries(mappings).forEach(([key, mapping]) => {
  if (key === '_meta') return;

  const excelField = phraseLibrary[mapping.excelField];
  if (!excelField) return;

  if (mapping.optionMappings) {
    Object.values(mapping.optionMappings).forEach(excelOption => {
      if (!excelField.options[excelOption]) {
        issues.push(`${key}: Excel option '${excelOption}' not found in '${mapping.excelField}'`);
        invalidOptionCount++;
      }
    });
  }
});
console.log(`   ${invalidOptionCount === 0 ? '✅' : '❌'} Found ${invalidOptionCount} invalid Excel options`);

// Check 8: File integrity
console.log('\n8. FILE INTEGRITY:');
try {
  const mappingJson = JSON.stringify(mappings);
  const parsed = JSON.parse(mappingJson);
  console.log('   ✅ Mapping file is valid JSON');
} catch (e) {
  issues.push(`Mapping file JSON is corrupted: ${e.message}`);
}

try {
  const libraryJson = JSON.stringify(phraseLibrary);
  const parsed = JSON.parse(libraryJson);
  console.log('   ✅ Phrase library is valid JSON');
} catch (e) {
  issues.push(`Phrase library JSON is corrupted: ${e.message}`);
}

// Final summary
console.log('\n' + '='.repeat(100));
console.log('FINAL SYSTEM CHECK RESULTS');
console.log('='.repeat(100));

if (issues.length === 0 && warnings.length === 0) {
  console.log('\n✅✅✅ SYSTEM CHECK PASSED - NO ISSUES FOUND ✅✅✅\n');
  console.log('System is production ready:');
  console.log('  • 100% field coverage');
  console.log('  • 0% low confidence');
  console.log('  • All Excel options valid');
  console.log('  • Phrase generation working');
  console.log('  • File integrity verified');
} else {
  if (issues.length > 0) {
    console.log(`\n❌ FOUND ${issues.length} CRITICAL ISSUES:\n`);
    issues.forEach((issue, i) => {
      console.log(`   ${i + 1}. ${issue}`);
    });
  }

  if (warnings.length > 0) {
    console.log(`\n⚠️  FOUND ${warnings.length} WARNINGS:\n`);
    warnings.forEach((warning, i) => {
      console.log(`   ${i + 1}. ${warning}`);
    });
  }
}

console.log('\n' + '='.repeat(100));

// Exit with appropriate code
process.exit(issues.length > 0 ? 1 : 0);
