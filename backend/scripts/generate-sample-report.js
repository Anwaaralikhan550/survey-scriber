/**
 * Generate Sample Survey Report
 * Shows actual phrase generation output
 */

const mappings = require('../field-mapping-config.json');
const phraseLibrary = require('../excel-phrase-library.json');

console.log('='.repeat(100));
console.log('SAMPLE SURVEY REPORT - EXCEL PHRASE GENERATION');
console.log('='.repeat(100));

// Sample survey data - realistic inspection values
const sampleSurveyData = {
  // Property Details
  property_type: 'Semi-Detached House',
  construction_type: 'Semi-Detached',
  year_built: '1960-1979',
  num_floors: '2',

  // Weather
  weather_current: 'Dry',
  weather_previous: 'Wet',

  // Construction
  floor_build_type: 'Suspended Timber',
  external_walls: 'Good',
  wall_construction: 'Cavity',
  roof_type: 'Pitched',
  roof_covering: 'Concrete Tiles',

  // Damp
  damp_type: 'None',
  damp_locations: 'None',
  damp_meter_used: 'Yes',

  // Services
  heating_type: 'Gas Central',
  boiler_age: '5-10 years',
  mains_gas: 'Yes',
  mains_water: 'Yes',
  mains_drainage: 'Yes',
  energy_efficiency: 'C',

  // Facilities
  num_bathrooms: '2',
  num_reception: '2',
  kitchen_type: 'Fitted',

  // Defects
  timber_rot: 'None',
  timber_decay: 'None',
  structural_movement: 'None',
  cracks_noted: 'Minor',
  leak_evidence: 'None',

  // External
  garden_type: 'Both',
  parking_type: 'Driveway',
  boundary_types: 'Fence',

  // Condition
  interior_condition: 'Good',
  exterior_condition: 'Fair',

  // Opinion
  overall_opinion: 'Reasonable',
  valuation_type: 'Market Value',

  // Environment
  local_environment: 'Residential',
  facilities: 'Good',
  nearby_trees: 'Moderate (10-20m)'
};

// Helper function to generate phrase
function generatePhrase(fieldKey, optionValue, allFormData = {}) {
  // Find mapping
  const mapping = mappings[fieldKey] || Object.values(mappings).find(m => m.appField === fieldKey);

  if (!mapping) {
    return null;
  }

  // Get Excel field
  const excelField = phraseLibrary[mapping.excelField];
  if (!excelField) {
    return null;
  }

  // Get Excel option
  const excelOption = mapping.optionMappings?.[optionValue];
  if (!excelOption) {
    return null;
  }

  // Get phrase template
  const phraseTemplate = excelField.options[excelOption];
  if (!phraseTemplate) {
    return null;
  }

  const template = phraseTemplate.phrase || phraseTemplate;

  // Simple template substitution
  let phrase = template;
  const placeholderRegex = /\(([^)]+)\)/g;
  phrase = phrase.replace(placeholderRegex, (match, content) => {
    const options = content.split('/');
    // Use first option for demo, in production this would be smart substitution
    return options[0].trim();
  });

  return {
    phrase,
    confidence: mapping.confidence,
    excelField: mapping.excelField,
    excelOption
  };
}

// Generate report sections
console.log('\n');
console.log('═'.repeat(100));
console.log('PROPERTY SURVEY REPORT');
console.log('═'.repeat(100));
console.log('\nAddress: 123 Sample Street, Sample Town, ST1 2AB');
console.log('Inspection Date: 2026-02-01');
console.log('Inspector: Professional Surveyor MRICS');
console.log('\n' + '─'.repeat(100));

// 1. WEATHER CONDITIONS
console.log('\n1. WEATHER CONDITIONS\n');
const weather1 = generatePhrase('weather_current', sampleSurveyData.weather_current);
const weather2 = generatePhrase('weather_previous', sampleSurveyData.weather_previous);
if (weather1) console.log(`${weather1.phrase}\n`);

// 2. CONSTRUCTION
console.log('\n2. CONSTRUCTION & STRUCTURE\n');
const construction = generatePhrase('construction_type', sampleSurveyData.construction_type);
const floors = generatePhrase('floor_build_type', sampleSurveyData.floor_build_type);
const walls = generatePhrase('external_walls', sampleSurveyData.external_walls);
const roof = generatePhrase('roof_type', sampleSurveyData.roof_type);

if (construction) console.log(`${construction.phrase}\n`);
if (floors) console.log(`${floors.phrase}\n`);
if (walls) console.log(`External Walls: ${walls.phrase}\n`);
if (roof) console.log(`${roof.phrase}\n`);

// 3. DAMPNESS
console.log('\n3. DAMPNESS ASSESSMENT\n');
const damp1 = generatePhrase('damp_type', sampleSurveyData.damp_type);
const damp2 = generatePhrase('damp_meter_used', sampleSurveyData.damp_meter_used);
if (damp1) console.log(`${damp1.phrase}\n`);

// 4. SERVICES
console.log('\n4. SERVICES & UTILITIES\n');
const heating = generatePhrase('heating_type', sampleSurveyData.heating_type);
const boiler = generatePhrase('boiler_age', sampleSurveyData.boiler_age);
const gas = generatePhrase('mains_gas', sampleSurveyData.mains_gas);
const water = generatePhrase('mains_water', sampleSurveyData.mains_water);
const energy = generatePhrase('energy_efficiency', sampleSurveyData.energy_efficiency);

if (heating) console.log(`Heating: ${heating.phrase}\n`);
if (gas) console.log(`Mains Gas: ${gas.phrase}\n`);
if (water) console.log(`Mains Water: ${water.phrase}\n`);
if (energy) console.log(`Energy Efficiency: ${energy.phrase}\n`);

// 5. DEFECTS
console.log('\n5. DEFECTS & REPAIRS\n');
const timber = generatePhrase('timber_rot', sampleSurveyData.timber_rot);
const movement = generatePhrase('structural_movement', sampleSurveyData.structural_movement);
const cracks = generatePhrase('cracks_noted', sampleSurveyData.cracks_noted);

if (timber) console.log(`Timber Condition: ${timber.phrase}\n`);
if (movement) console.log(`Structural Movement: ${movement.phrase}\n`);
if (cracks) console.log(`Cracking: ${cracks.phrase}\n`);

// 6. EXTERNAL AREAS
console.log('\n6. EXTERNAL AREAS\n');
const garden = generatePhrase('garden_type', sampleSurveyData.garden_type);
const parking = generatePhrase('parking_type', sampleSurveyData.parking_type);

if (garden) console.log(`Garden: ${garden.phrase}\n`);
if (parking) console.log(`Parking: ${parking.phrase}\n`);

// 7. CONDITION
console.log('\n7. OVERALL CONDITION\n');
const interior = generatePhrase('interior_condition', sampleSurveyData.interior_condition);
const exterior = generatePhrase('exterior_condition', sampleSurveyData.exterior_condition);

if (interior) console.log(`Interior: ${interior.phrase}\n`);
if (exterior) console.log(`Exterior: ${exterior.phrase}\n`);

// 8. ENVIRONMENT
console.log('\n8. LOCATION & ENVIRONMENT\n');
const environment = generatePhrase('local_environment', sampleSurveyData.local_environment);
const facilities = generatePhrase('facilities', sampleSurveyData.facilities);
const trees = generatePhrase('nearby_trees', sampleSurveyData.nearby_trees);

if (environment) console.log(`Local Environment: ${environment.phrase}\n`);
if (facilities) console.log(`Facilities: ${facilities.phrase}\n`);
if (trees) console.log(`Nearby Trees: ${trees.phrase}\n`);

// 9. OVERALL OPINION
console.log('\n9. VALUATION & OPINION\n');
const opinion = generatePhrase('overall_opinion', sampleSurveyData.overall_opinion);
const valuation = generatePhrase('valuation_type', sampleSurveyData.valuation_type);

if (opinion) console.log(`${opinion.phrase}\n`);
if (valuation) console.log(`Valuation Basis: ${valuation.phrase}\n`);

// Summary stats
console.log('\n' + '═'.repeat(100));
console.log('REPORT GENERATION SUMMARY');
console.log('═'.repeat(100));

const totalFields = Object.keys(sampleSurveyData).length;
let generatedCount = 0;
let highConfCount = 0;
let mediumConfCount = 0;

Object.entries(sampleSurveyData).forEach(([key, value]) => {
  const result = generatePhrase(key, value);
  if (result) {
    generatedCount++;
    if (result.confidence === 'high') highConfCount++;
    if (result.confidence === 'medium') mediumConfCount++;
  }
});

console.log(`\nTotal fields in sample: ${totalFields}`);
console.log(`Phrases generated: ${generatedCount}`);
console.log(`High confidence: ${highConfCount}`);
console.log(`Medium confidence: ${mediumConfCount}`);
console.log(`Success rate: ${(generatedCount/totalFields*100).toFixed(1)}%`);

console.log('\n' + '═'.repeat(100));
console.log('✅ SAMPLE REPORT GENERATION COMPLETE');
console.log('═'.repeat(100));
console.log('\nThis demonstrates the Excel phrase generation system with real mappings.');
console.log('All phrases are pulled from the professional Excel phrase library.');
console.log('\n');
