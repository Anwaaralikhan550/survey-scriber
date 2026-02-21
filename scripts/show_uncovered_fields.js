const fs = require('fs');
const tree = JSON.parse(fs.readFileSync('assets/inspection_v2/inspection_v2_tree.json', 'utf8'));
const uncovered = JSON.parse(fs.readFileSync('scripts/audit_phrase_coverage_results.json', 'utf8'));
const screenIds = new Set(uncovered.map(u => u.id));
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (screenIds.has(node.id) && node.fields) {
      console.log('=== ' + node.id + ' ===');
      const dataFields = node.fields.filter(f => f.type !== 'label');
      dataFields.forEach(f => {
        let info = f.id + ' (' + f.type + ') "' + f.label + '"';
        if (f.options) info += ' opts=' + JSON.stringify(f.options);
        if (f.conditionalOn) info += ' cond:' + f.conditionalOn + '=' + f.conditionalValue;
        console.log('  ' + info);
      });
      console.log('');
    }
  }
}
