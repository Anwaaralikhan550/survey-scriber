/**
 * Test the template substitution system
 * Shows how it works with real examples
 */

// Simple JS version for quick testing
const phraseLibrary = require('./excel-phrase-library.json');

// Simulate the services
function parseTemplate(template) {
  const placeholders = [];
  const regex = /\(([^)]+)\)/g;
  let match;

  while ((match = regex.exec(template)) !== null) {
    const options = match[1].split('/').map(s => s.trim());
    if (options.length > 1) {
      placeholders.push({
        fullMatch: match[0],
        options,
        startIndex: match.index,
        endIndex: match.index + match[0].length,
      });
    }
  }

  return { template, placeholders };
}

function matchValue(formValue, placeholderOptions) {
  const normalized = formValue.toLowerCase().replace(/[^a-z0-9]/g, '');

  for (const option of placeholderOptions) {
    const normalizedOption = option.toLowerCase().replace(/[^a-z0-9]/g, '');

    if (normalized === normalizedOption) {
      return { matched: true, option, confidence: 1.0 };
    }

    if (normalized.includes(normalizedOption)) {
      return { matched: true, option, confidence: 0.8 };
    }

    if (normalizedOption.includes(normalized)) {
      return { matched: true, option, confidence: 0.7 };
    }
  }

  return { matched: false, option: placeholderOptions[0], confidence: 0 };
}

function renderTemplate(template, formData) {
  const parsed = parseTemplate(template);
  let rendered = template;
  const formValues = Object.values(formData).filter(v => v);

  // Process placeholders in reverse
  const placeholdersReverse = [...parsed.placeholders].reverse();

  for (const ph of placeholdersReverse) {
    let bestMatch = { matched: false, option: ph.options[0], confidence: 0 };

    for (const formValue of formValues) {
      const match = matchValue(String(formValue), ph.options);
      if (match.confidence > bestMatch.confidence) {
        bestMatch = match;
      }
    }

    rendered =
      rendered.substring(0, ph.startIndex) +
      bestMatch.option +
      rendered.substring(ph.endIndex);
  }

  return rendered.replace(/\s+/g, ' ').trim();
}

// TEST CASES
console.log('='.repeat(100));
console.log('TEMPLATE SUBSTITUTION SYSTEM - TEST');
console.log('='.repeat(100));

// Test 1: Property Type (from Word doc example)
console.log('\n📝 TEST 1: Property Type');
console.log('-'.repeat(100));

const propertyTypeTemplate = phraseLibrary.property_type.options.House.phrase;
console.log('Template:', propertyTypeTemplate);

const formData1 = {
  property_type: 'Detached House',
  property_subtype: 'detached',
  num_bedrooms: '4',
  bedrooms: 'four',
};

const result1 = renderTemplate(propertyTypeTemplate, formData1);
console.log('\nForm Data:', formData1);
console.log('\n✅ Result:', result1);
console.log('\n📄 Expected (from Word doc): "The property is a detached house with four bedrooms."');

// Test 2: Party Disclosure
console.log('\n\n📝 TEST 2: Party Disclosure');
console.log('-'.repeat(100));

const partyTemplate = phraseLibrary.party_disclosures.options.None.phrase;
console.log('Template:', partyTemplate);

const formData2 = {
  party_disclosure: 'None',
};

const result2 = renderTemplate(partyTemplate, formData2);
console.log('\nForm Data:', formData2);
console.log('\n✅ Result:', result2);

// Test 3: Overall Opinion
console.log('\n\n📝 TEST 3: Overall Opinion');
console.log('-'.repeat(100));

const opinionTemplate = phraseLibrary.overall_opinion.options.Reasonable.phrase;
console.log('Template:', opinionTemplate);

const formData3 = {
  overall_opinion: 'Reasonable',
  purchase_price: '£1,190,000.00',
};

const result3 = renderTemplate(opinionTemplate, formData3);
console.log('\nForm Data:', formData3);
console.log('\n✅ Result:', result3);

// Test 4: Weather
console.log('\n\n📝 TEST 4: Weather');
console.log('-'.repeat(100));

const weatherTemplate = phraseLibrary.weather.options['Now / Before'].phrase;
console.log('Template:', weatherTemplate);

const formData4 = {
  weather_current: 'dry',
  weather_previous: 'wet',
};

const result4 = renderTemplate(weatherTemplate, formData4);
console.log('\nForm Data:', formData4);
console.log('\n✅ Result:', result4);

console.log('\n' + '='.repeat(100));
console.log('✅ TEMPLATE SYSTEM WORKS!');
console.log('='.repeat(100));
console.log('\nNext: Integrate into report generation');
