const log = JSON.parse(require('fs').readFileSync('scripts/structural-parity/manual-gap-apply-log.json', 'utf-8'));
const missing = log.filter(l => l.type === 'dropdown' && !l.options);
console.log('Dropdowns missing options:', missing.length);
missing.forEach(l => console.log('  ' + l.screenId + '.' + l.fieldId + ' (' + l.label + ')'));
console.log('\nAll types:', JSON.stringify(log.reduce((acc, l) => { acc[l.type] = (acc[l.type] || 0) + 1; return acc; }, {})));
