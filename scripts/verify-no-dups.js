const tree = JSON.parse(require('fs').readFileSync('assets/property_inspection/inspection_tree.json','utf8'));
let found = 0;
for (const s of tree.sections) {
  if (!s.nodes) continue;
  for (const n of s.nodes) {
    if (n.type !== 'screen' || !n.fields) continue;
    const cb = new Set();
    for (const f of n.fields) { if (f.type==='checkbox') cb.add(f.label.trim().toLowerCase()); }
    if (cb.size === 0) continue;
    for (const f of n.fields) {
      if (f.type !== 'dropdown' || !f.options) continue;
      const m = f.options.filter(o => cb.has(o.trim().toLowerCase()));
      if (m.length >= 2 && m.length >= f.options.length * 0.5) {
        console.log('STILL DUP:', n.title, f.id, f.label);
        found++;
      }
    }
  }
}
if (found === 0) console.log('CLEAN: No duplicate dropdown+checkbox pairs remain.');
else console.log(`WARNING: ${found} duplicates still remain.`);
