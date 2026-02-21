/**
 * Check Excel Options
 * Shows actual available options for problematic fields
 */

const phraseLibrary = require('../excel-phrase-library.json');

// Fields with invalid options from verification
const problematicFields = [
  'garden', 'grounds', 'local_environment', 'communal_area',
  'roof', 'chimney', 'windows', 'doors', 'timber',
  'drainage', 'heating', 'electrics', 'water',
  'insulation', 'walls', 'floors', 'ceilings'
];

console.log('='.repeat(100));
console.log('CHECKING ACTUAL EXCEL OPTIONS FOR PROBLEMATIC FIELDS');
console.log('='.repeat(100));

problematicFields.forEach(field => {
  if (phraseLibrary[field]) {
    const options = Object.keys(phraseLibrary[field].options);
    console.log(`\n${field}:`);
    console.log(`  Options: ${options.join(', ')}`);
  } else {
    console.log(`\n${field}: NOT FOUND IN PHRASE LIBRARY`);
  }
});

console.log('\n' + '='.repeat(100));
