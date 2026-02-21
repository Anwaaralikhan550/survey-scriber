const fs = require('fs');
const t = JSON.parse(fs.readFileSync('E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json', 'utf8'));
let screens = 0, fields = 0;
for (const s of t.sections) {
  if (!['E','F','G','H'].includes(s.key)) continue;
  for (const n of s.nodes) {
    if (n.type === 'screen') {
      screens++;
      fields += (n.fields || []).length;
    }
  }
}
console.log('Valid JSON: YES');
console.log('Inspection screens (E,F,G,H):', screens);
console.log('Total fields:', fields);
console.log('Total sections:', t.sections.length);
