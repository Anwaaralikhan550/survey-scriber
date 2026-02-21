const fs = require('fs');
const tree = JSON.parse(fs.readFileSync('assets/inspection_v2/inspection_v2_tree.json', 'utf8'));
const uncovered = JSON.parse(fs.readFileSync('scripts/audit_phrase_coverage_results.json', 'utf8'));
const ids = new Set(uncovered.map(u => u.id));
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (ids.has(node.id) && node.fields) {
      const df = node.fields.filter(f => f.type !== 'label');
      console.log('=== ' + node.id + ' (' + section.key + ') ===');
      df.forEach(f => {
        let info = f.id + ' | ' + f.type + ' | "' + f.label + '"';
        if (f.options) info += ' | ' + JSON.stringify(f.options);
        if (f.conditionalOn) info += ' | IF ' + f.conditionalOn + '=' + f.conditionalValue + ' ' + f.conditionalMode;
        console.log('  ' + info);
      });
      console.log('');
    }
  }
}
