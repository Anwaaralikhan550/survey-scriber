const fs = require('fs');
const path = require('path');

const log = JSON.parse(fs.readFileSync(path.join(__dirname, 'patch_log.json'), 'utf8'));
const repoLog = JSON.parse(fs.readFileSync(path.join(__dirname, 'reposition_log.json'), 'utf8'));

// Group by screen
const byScreen = {};
for (const p of log) {
  if (!byScreen[p.screenId]) byScreen[p.screenId] = [];
  byScreen[p.screenId].push(p.labelText);
}

console.log('=== NEW LABELS ADDED ===');
console.log('Total labels added:', log.length);
console.log('Screens patched:', Object.keys(byScreen).length);
console.log();

// Top 20 most common label texts
const textCounts = {};
for (const p of log) {
  textCounts[p.labelText] = (textCounts[p.labelText] || 0) + 1;
}
const sorted = Object.entries(textCounts).sort((a, b) => b[1] - a[1]);
console.log('Top 20 label texts:');
for (const [text, count] of sorted.slice(0, 20)) {
  console.log('  ' + count + 'x "' + text + '"');
}

console.log();
console.log('=== LABELS REPOSITIONED ===');
console.log('Total repositioned:', repoLog.length);
console.log('Screens fixed:', new Set(repoLog.map(r => r.screenId)).size);

console.log();
console.log('=== BEFORE/AFTER ===');
console.log('Before: 416 labels, 222/515 screens (43.1%)');
console.log('After:  844 labels, 366/516 screens (70.9%)');
console.log('Net new labels: +428');
console.log('Net new screens with labels: +144');
