const app = require('../app-fields.json');
const mapped = require('../field-mapping-config.json');

const mappedKeys = Object.keys(mapped).filter(k => k !== '_meta');
const unmapped = app.filter(f => !mappedKeys.includes(f.key));

console.log('Unmapped app fields:', unmapped.length);
console.log('\nFirst 30 unmapped fields:\n');
unmapped.slice(0, 30).forEach((f, i) => {
  console.log((i+1).toString().padStart(2) + '. ' + f.key.padEnd(35) + ' | ' + f.label);
});
