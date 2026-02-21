/**
 * Comprehensive Verification Script
 * Double-checks all 130 fields are properly mapped
 */

const fs = require('fs');
const path = require('path');

const appFields = require('../app-fields.json');
const mappings = require('../field-mapping-config.json');
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('COMPREHENSIVE MAPPING VERIFICATION');
console.log('='.repeat(100));

// Build list of mapped app fields
const mappedAppFields = new Set();
const mappingsByAppField = {};

Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (value.appField) {
    mappedAppFields.add(value.appField);
    if (!mappingsByAppField[value.appField]) {
      mappingsByAppField[value.appField] = [];
    }
    mappingsByAppField[value.appField].push(key);
  }
});

console.log(`\n📊 COVERAGE STATISTICS:`);
console.log(`   Total app fields: ${appFields.length}`);
console.log(`   Unique mapped fields: ${mappedAppFields.size}`);
console.log(`   Total mapping entries: ${Object.keys(mappings).length - 1}`);
console.log(`   Coverage: ${(mappedAppFields.size / appFields.length * 100).toFixed(1)}%`);

// Check for unmapped fields
console.log(`\n\n${'='.repeat(100)}`);
console.log('1. CHECKING FOR UNMAPPED FIELDS');
console.log('='.repeat(100));

const unmapped = [];
appFields.forEach(field => {
  if (!mappedAppFields.has(field.key)) {
    unmapped.push(field);
  }
});

if (unmapped.length === 0) {
  console.log('\n✅ ALL FIELDS MAPPED - No unmapped fields found!');
} else {
  console.log(`\n❌ FOUND ${unmapped.length} UNMAPPED FIELDS:`);
  unmapped.forEach((f, i) => {
    console.log(`   ${(i+1).toString().padStart(2)}. ${f.key.padEnd(35)} | ${f.label}`);
  });
}

// Check for duplicate mappings
console.log(`\n\n${'='.repeat(100)}`);
console.log('2. CHECKING FOR DUPLICATE MAPPINGS');
console.log('='.repeat(100));

const duplicates = [];
Object.entries(mappingsByAppField).forEach(([appField, mappingKeys]) => {
  if (mappingKeys.length > 1) {
    duplicates.push({ appField, count: mappingKeys.length, mappings: mappingKeys });
  }
});

if (duplicates.length === 0) {
  console.log('\n✅ No duplicate mappings found');
} else {
  console.log(`\n⚠️  Found ${duplicates.length} fields with multiple mappings:`);
  duplicates.forEach(dup => {
    console.log(`   • ${dup.appField} (${dup.count} mappings): ${dup.mappings.join(', ')}`);
  });
  console.log('\n   Note: Multiple mappings can be intentional for different use cases.');
}

// Validate Excel field existence
console.log(`\n\n${'='.repeat(100)}`);
console.log('3. VALIDATING EXCEL FIELDS EXIST');
console.log('='.repeat(100));

const invalidExcelFields = [];
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (!phraseLibrary[value.excelField]) {
    invalidExcelFields.push({
      mappingKey: key,
      appField: value.appField,
      excelField: value.excelField
    });
  }
});

if (invalidExcelFields.length === 0) {
  console.log('\n✅ All Excel fields exist in phrase library');
} else {
  console.log(`\n❌ FOUND ${invalidExcelFields.length} INVALID EXCEL FIELDS:`);
  invalidExcelFields.forEach(item => {
    console.log(`   • ${item.appField} → ${item.excelField} (NOT FOUND in library)`);
  });
}

// Validate Excel options exist
console.log(`\n\n${'='.repeat(100)}`);
console.log('4. VALIDATING EXCEL OPTIONS EXIST');
console.log('='.repeat(100));

const invalidOptions = [];
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;

  const excelField = phraseLibrary[value.excelField];
  if (!excelField) return; // Already caught in previous check

  if (value.optionMappings) {
    Object.entries(value.optionMappings).forEach(([appOption, excelOption]) => {
      if (!excelField.options[excelOption]) {
        invalidOptions.push({
          appField: value.appField,
          appOption: appOption,
          excelField: value.excelField,
          excelOption: excelOption
        });
      }
    });
  }
});

if (invalidOptions.length === 0) {
  console.log('\n✅ All Excel options are valid');
} else {
  console.log(`\n❌ FOUND ${invalidOptions.length} INVALID EXCEL OPTIONS:`);
  invalidOptions.slice(0, 20).forEach(item => {
    console.log(`   • ${item.appField}.${item.appOption} → ${item.excelField}.${item.excelOption} (NOT FOUND)`);
  });
  if (invalidOptions.length > 20) {
    console.log(`   ... and ${invalidOptions.length - 20} more`);
  }
}

// Check mapping quality distribution
console.log(`\n\n${'='.repeat(100)}`);
console.log('5. MAPPING QUALITY DISTRIBUTION');
console.log('='.repeat(100));

const byConfidence = { high: 0, medium: 0, low: 0, unknown: 0 };
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (value.confidence) {
    byConfidence[value.confidence]++;
  } else {
    byConfidence.unknown++;
  }
});

const total = Object.values(byConfidence).reduce((sum, val) => sum + val, 0);
console.log(`\n   🟢 High Confidence: ${byConfidence.high} (${(byConfidence.high/total*100).toFixed(1)}%)`);
console.log(`   🟡 Medium Confidence: ${byConfidence.medium} (${(byConfidence.medium/total*100).toFixed(1)}%)`);
console.log(`   🔴 Low Confidence: ${byConfidence.low} (${(byConfidence.low/total*100).toFixed(1)}%)`);
if (byConfidence.unknown > 0) {
  console.log(`   ⚪ Unknown: ${byConfidence.unknown}`);
}

// Check for fields without option mappings
console.log(`\n\n${'='.repeat(100)}`);
console.log('6. CHECKING FOR MISSING OPTION MAPPINGS');
console.log('='.repeat(100));

const missingOptionMappings = [];
Object.entries(mappings).forEach(([key, value]) => {
  if (key === '_meta') return;
  if (!value.optionMappings || Object.keys(value.optionMappings).length === 0) {
    missingOptionMappings.push(value.appField);
  }
});

if (missingOptionMappings.length === 0) {
  console.log('\n✅ All mappings have option mappings defined');
} else {
  console.log(`\n⚠️  Found ${missingOptionMappings.length} mappings without option mappings:`);
  missingOptionMappings.forEach(field => {
    console.log(`   • ${field}`);
  });
}

// Verify app field options coverage
console.log(`\n\n${'='.repeat(100)}`);
console.log('7. VERIFYING APP FIELD OPTIONS ARE MAPPED');
console.log('='.repeat(100));

const incompleteMappings = [];
appFields.forEach(appField => {
  const mapping = Object.values(mappings).find(m => m.appField === appField.key);
  if (!mapping) return; // Already caught as unmapped

  if (appField.options && appField.options.length > 0 && mapping.optionMappings) {
    const mappedOptions = Object.keys(mapping.optionMappings);
    const unmappedOptions = appField.options.filter(opt => !mappedOptions.includes(opt));

    if (unmappedOptions.length > 0) {
      incompleteMappings.push({
        field: appField.key,
        label: appField.label,
        unmappedOptions: unmappedOptions,
        totalOptions: appField.options.length
      });
    }
  }
});

if (incompleteMappings.length === 0) {
  console.log('\n✅ All app field options are mapped');
} else {
  console.log(`\n⚠️  Found ${incompleteMappings.length} fields with unmapped options:`);
  incompleteMappings.slice(0, 10).forEach(item => {
    console.log(`   • ${item.field}: ${item.unmappedOptions.length}/${item.totalOptions} options not mapped`);
    console.log(`     Missing: ${item.unmappedOptions.slice(0, 3).join(', ')}${item.unmappedOptions.length > 3 ? '...' : ''}`);
  });
  if (incompleteMappings.length > 10) {
    console.log(`   ... and ${incompleteMappings.length - 10} more`);
  }
}

// Final summary
console.log(`\n\n${'='.repeat(100)}`);
console.log('VERIFICATION SUMMARY');
console.log('='.repeat(100));

const issues = [];
if (unmapped.length > 0) issues.push(`${unmapped.length} unmapped fields`);
if (invalidExcelFields.length > 0) issues.push(`${invalidExcelFields.length} invalid Excel fields`);
if (invalidOptions.length > 0) issues.push(`${invalidOptions.length} invalid Excel options`);
if (incompleteMappings.length > 0) issues.push(`${incompleteMappings.length} incomplete option mappings`);

if (issues.length === 0) {
  console.log('\n✅✅✅ VERIFICATION PASSED - ALL CHECKS SUCCESSFUL! ✅✅✅');
  console.log('\n   • All 130 app fields are mapped');
  console.log('   • All Excel fields exist in phrase library');
  console.log('   • All Excel options are valid');
  console.log('   • All option mappings are complete');
  console.log('\n   System is ready for production! 🚀');
} else {
  console.log('\n⚠️  VERIFICATION FOUND ISSUES:');
  issues.forEach(issue => {
    console.log(`   ❌ ${issue}`);
  });
  console.log('\n   Please review and fix the issues listed above.');
}

console.log('\n' + '='.repeat(100));

// Export detailed report
const report = {
  timestamp: new Date().toISOString(),
  summary: {
    totalAppFields: appFields.length,
    mappedFields: mappedAppFields.size,
    coverage: (mappedAppFields.size / appFields.length * 100).toFixed(1) + '%',
    totalMappingEntries: Object.keys(mappings).length - 1
  },
  issues: {
    unmappedFields: unmapped.map(f => f.key),
    invalidExcelFields: invalidExcelFields,
    invalidOptions: invalidOptions,
    incompleteMappings: incompleteMappings,
    duplicateMappings: duplicates
  },
  quality: byConfidence
};

fs.writeFileSync('mapping-verification-report.json', JSON.stringify(report, null, 2));
console.log('\n📄 Detailed report saved to: mapping-verification-report.json');
console.log('='.repeat(100));
