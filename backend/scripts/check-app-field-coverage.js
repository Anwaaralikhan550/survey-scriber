const mappings = require('../field-mapping-config.json');
const appFields = require('../app-fields.json');

const mapped = new Set();
Object.values(mappings).forEach(v => {
  if (v.appField) mapped.add(v.appField);
});

const appFieldKeys = new Set(appFields.map(f => f.key));

console.log('Mapped app fields:', mapped.size);
console.log('App fields in app-fields.json:', appFieldKeys.size);

const extras = [...mapped].filter(k => !appFieldKeys.has(k));
const missing = [...appFieldKeys].filter(k => !mapped.has(k));

console.log('\nExtra mappings (not in app-fields.json):', extras.length);
if (extras.length > 0 && extras.length < 50) {
  extras.forEach(e => console.log('  -', e));
}

console.log('\nMissing mappings (in app-fields.json but not mapped):', missing.length);
if (missing.length > 0) {
  missing.forEach(e => console.log('  -', e));
}

if (missing.length === 0) {
  console.log('\n✅ ALL app fields from app-fields.json are mapped!');
  console.log(`✅ PLUS ${extras.length} additional field variations`);
}
