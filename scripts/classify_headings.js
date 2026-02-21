// scripts/classify_headings.js
const fs = require('fs');
const path = require('path');

const nativeStructure = JSON.parse(fs.readFileSync(path.join(__dirname, 'native-inspection-structure.json'), 'utf8'));
const gaps = JSON.parse(fs.readFileSync(path.join(__dirname, 'inspection-heading-gap-report.json'), 'utf8'));

// For each screen in the gap report, check native structure
for (const gap of gaps) {
  const native = nativeStructure[gap.screenId];
  if (!native) {
    console.log(`[NO NATIVE] ${gap.screenId}`);
    continue;
  }
  
  console.log(`\n=== ${gap.screenId} (${gap.section}) ===`);
  console.log(`Native elements: ${native.length}`);
  
  // Show full native structure
  for (let i = 0; i < native.length; i++) {
    const e = native[i];
    if (e.type === 'heading') {
      // Check if next element is a field or another heading
      let nextType = i + 1 < native.length ? native[i + 1].type : 'END';
      let hasFieldsBeforeNextHeading = false;
      for (let j = i + 1; j < native.length; j++) {
        if (native[j].type === 'heading') break;
        if (native[j].type === 'field') { hasFieldsBeforeNextHeading = true; break; }
      }
      const classification = hasFieldsBeforeNextHeading ? 'FIELD_HEADING' : 'NAV_HEADING';
      console.log(`  [${classification}] H: "${e.text}" (next: ${nextType})`);
    } else {
      console.log(`           F: ${e.id} (${e.fieldType})`);
    }
  }
}
