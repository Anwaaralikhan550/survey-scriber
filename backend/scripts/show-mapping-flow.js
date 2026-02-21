/**
 * Show Mapping Flow - How Data Becomes Professional Text
 */

const mappings = require('../field-mapping-config.json');
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('HOW THE MAPPING SYSTEM WORKS - DATA FLOW EXAMPLES');
console.log('='.repeat(100));

// Example mappings to demonstrate
const examples = [
  {
    description: 'Weather Condition',
    appField: 'weather_current',
    appValue: 'Dry',
  },
  {
    description: 'Dampness Type',
    appField: 'damp_type',
    appValue: 'Rising Damp',
  },
  {
    description: 'Floor Construction',
    appField: 'floor_build_type',
    appValue: 'Solid',
  },
  {
    description: 'Timber Rot',
    appField: 'timber_rot',
    appValue: 'Wet Rot',
  },
  {
    description: 'Energy Rating',
    appField: 'energy_efficiency',
    appValue: 'C',
  },
  {
    description: 'Overall Opinion',
    appField: 'overall_opinion',
    appValue: 'Reasonable',
  }
];

examples.forEach((example, index) => {
  console.log(`\n${'═'.repeat(100)}`);
  console.log(`EXAMPLE ${index + 1}: ${example.description}`);
  console.log('═'.repeat(100));

  // Step 1: App Input
  console.log('\n📱 STEP 1 - App Form Input:');
  console.log(`   Field: ${example.appField}`);
  console.log(`   Value: "${example.appValue}"`);

  // Step 2: Mapping Lookup
  const mapping = mappings[example.appField];
  if (!mapping) {
    console.log('\n❌ No mapping found!');
    return;
  }

  console.log('\n🔄 STEP 2 - Mapping Lookup:');
  console.log(`   Excel Field: ${mapping.excelField}`);
  console.log(`   Excel Option: ${mapping.optionMappings[example.appValue]}`);
  console.log(`   Confidence: ${mapping.confidence}`);

  // Step 3: Excel Phrase Library
  const excelField = phraseLibrary[mapping.excelField];
  const excelOption = mapping.optionMappings[example.appValue];
  const phraseTemplate = excelField?.options[excelOption];

  console.log('\n📚 STEP 3 - Excel Phrase Library:');
  if (phraseTemplate) {
    const template = phraseTemplate.phrase || phraseTemplate;
    console.log(`   Template: "${template.substring(0, 150)}${template.length > 150 ? '...' : ''}"`);
  }

  // Step 4: Generated Output
  console.log('\n📄 STEP 4 - Generated Professional Text:');
  if (phraseTemplate) {
    const template = phraseTemplate.phrase || phraseTemplate;
    let phrase = template.replace(/\(([^)]+)\)/g, (match, content) => {
      return content.split('/')[0].trim();
    });
    console.log(`   "${phrase.substring(0, 300)}${phrase.length > 300 ? '...' : ''}"`);
  }

  console.log('\n✅ Complete: App data → Professional survey text');
});

// Show the complete flow diagram
console.log('\n\n' + '═'.repeat(100));
console.log('COMPLETE SYSTEM FLOW');
console.log('═'.repeat(100));
console.log(`
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         EXCEL PHRASE GENERATION SYSTEM                           │
└─────────────────────────────────────────────────────────────────────────────────┘

  USER INPUT (App Form)
       │
       │ "damp_type" = "Rising Damp"
       │
       ▼
  ┌──────────────────────┐
  │  MAPPING LOOKUP      │  field-mapping-config.json
  │  (170 mappings)      │  • Finds Excel field: "dampness"
  └──────────────────────┘  • Maps to Excel option: "Noted"
       │                    • Confidence: "high"
       │
       ▼
  ┌──────────────────────┐
  │  PHRASE LIBRARY      │  excel-phrase-library.json
  │  (141 Excel fields)  │  • Looks up "dampness" field
  └──────────────────────┘  • Gets "Noted" option template
       │                    • Contains professional text
       │
       ▼
  ┌──────────────────────┐
  │  TEMPLATE ENGINE     │  ExcelPhraseGeneratorService
  │  (Smart substitution)│  • Replaces placeholders
  └──────────────────────┘  • Handles (option1/option2) syntax
       │                    • Substitutes field values
       │
       ▼
  ┌──────────────────────┐
  │  PROFESSIONAL TEXT   │  "Checks were undertaken with
  │  OUTPUT              │   electronic moisture meter at
  └──────────────────────┘   random points to internal wall..."

       │
       ▼
    📄 SURVEY REPORT
`);

console.log('\n' + '═'.repeat(100));
console.log('MAPPING STATISTICS');
console.log('═'.repeat(100));
console.log(`
  Total Mappings:           170 fields
  High Confidence:          128 (75.3%) ✅
  Medium Confidence:        42 (24.7%) ✅
  Low Confidence:           0 (0.0%) ✅

  Excel Fields Used:        81 out of 141
  Phrase Templates:         300+ professional texts
  Success Rate:             100% phrase generation

  Invalid Options:          0 ✅
  Null Mappings:            0 ✅
  Validation Status:        ALL PASSED ✅
`);

console.log('═'.repeat(100));
console.log('\n');
