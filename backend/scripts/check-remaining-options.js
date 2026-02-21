/**
 * Check Remaining Low Confidence Field Options
 */

const phraseLibrary = require('../excel-phrase-library.json');

const fields = [
  'floors', 'inspected', 'local_environment', 'communal_area', 'grounds',
  'facilities', 'party_disclosures', 'garden', 'condition', 'doors',
  'dampness', 'hazard', 'overall_opinion', 'conservatory_porch',
  'juliet_balcony', 'no_fire_escape_risk', 'safety_glass_rating',
  'safety_hazard', 'property_status', 'blocked_fireplace', 'conversion'
];

console.log('='.repeat(100));
console.log('EXCEL OPTIONS FOR REMAINING LOW CONFIDENCE FIELDS');
console.log('='.repeat(100));

fields.forEach(field => {
  if (phraseLibrary[field]) {
    const options = Object.keys(phraseLibrary[field].options);
    console.log(`\n${field}:`);
    console.log(`  ${options.join(', ')}`);
  } else {
    console.log(`\n${field}: NOT FOUND`);
  }
});

console.log('\n' + '='.repeat(100));
