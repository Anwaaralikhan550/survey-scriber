/**
 * Extract native Android XML layout headings (TextViewItem style)
 * and compare against V2 tree label fields.
 *
 * Outputs a JSON file mapping screen IDs to their native headings.
 */
const fs = require('fs');
const path = require('path');

const layoutDir = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/layout';
const stringsPath = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml';

// Load strings.xml for @string/ resolution
const stringsContent = fs.readFileSync(stringsPath, 'utf8');
const stringMap = {};
const stringRegex = /<string name="([^"]+)">([^<]*)<\/string>/g;
let match;
while ((match = stringRegex.exec(stringsContent)) !== null) {
  stringMap[match[1]] = match[2];
}

// Get all activity XML files
const files = fs.readdirSync(layoutDir).filter(f => f.startsWith('activity_') && f.endsWith('.xml'));

const results = {};

for (const file of files) {
  const filePath = path.join(layoutDir, file);
  const content = fs.readFileSync(filePath, 'utf8');

  // Find all TextViewItem headings
  // Match TextViewItem style TextViews and extract their android:text value
  const headings = [];

  // Split into TextView blocks
  const tvRegex = /<TextView[\s\S]*?\/>/g;
  let tvMatch;
  while ((tvMatch = tvRegex.exec(content)) !== null) {
    const block = tvMatch[0];

    // Check if it has TextViewItem style
    if (!block.includes('TextViewItem')) continue;

    // Check visibility - skip if visibility="gone" (hidden by default)
    if (block.includes('android:visibility="gone"')) continue;

    // Extract text
    const textMatch = block.match(/android:text="([^"]+)"/);
    if (!textMatch) continue;

    let text = textMatch[1];

    // Resolve @string/ references
    if (text.startsWith('@string/')) {
      const key = text.replace('@string/', '');
      text = stringMap[key] || text;
    }

    // Skip empty or generic headings
    if (!text || text === 'Dashboard' || text === '') continue;

    headings.push(text);
  }

  if (headings.length > 0) {
    // Strip .xml extension and use as key
    const screenId = file.replace('.xml', '');
    results[screenId] = headings;
  }
}

const outputPath = path.join(__dirname, 'native_headings.json');
fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));

console.log(`Extracted headings from ${Object.keys(results).length} screens`);
console.log(`Total headings: ${Object.values(results).reduce((sum, h) => sum + h.length, 0)}`);
console.log(`Saved to ${outputPath}`);

// Show sample
console.log('\nSample headings:');
const keys = Object.keys(results).slice(0, 10);
for (const k of keys) {
  console.log(`  ${k}: ${JSON.stringify(results[k])}`);
}
