/**
 * Map Excel phrases to database phrase categories
 * Run with: npx ts-node backend/scripts/map-excel-phrases.ts
 */
import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();
const excelMapping = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'excel-field-mapping.json'), 'utf-8')
);

interface FieldMapping {
  excelFieldName: string;
  categorySlug: string;
  optionMappings: {
    excelOption: string;
    phraseValue: string;
  }[];
}

// ============================================
// FIELD MAPPINGS: Excel Field → App Category
// ============================================

const fieldMappings: FieldMapping[] = [
  // #1: Party Disclosures
  {
    excelFieldName: 'Party Disclosures',
    categorySlug: 'party_disclosure',
    optionMappings: [
      { excelOption: 'None', phraseValue: 'None' },
      { excelOption: 'Conflict', phraseValue: 'Conflict' },
    ],
  },

  // #2: Property Type
  {
    excelFieldName: 'Property Type',
    categorySlug: 'property_types',
    optionMappings: [
      { excelOption: 'House', phraseValue: 'Detached House' }, // Maps to existing option
      { excelOption: 'Flat', phraseValue: 'Flat/Apartment' },
    ],
  },

  // Add more mappings here as we go through each field...
];

async function updatePhrasesWithExcelText() {
  console.log('Starting Excel phrase mapping...\n');

  for (const mapping of fieldMappings) {
    console.log(`\n${'='.repeat(80)}`);
    console.log(`Processing: ${mapping.excelFieldName} → ${mapping.categorySlug}`);
    console.log('='.repeat(80));

    // Get Excel data
    const excelField = excelMapping[mapping.excelFieldName];
    if (!excelField) {
      console.log(`  ⚠ Excel field "${mapping.excelFieldName}" not found in mapping`);
      continue;
    }

    // Find or create category
    let category = await prisma.phraseCategory.findUnique({
      where: { slug: mapping.categorySlug },
      include: { phrases: true },
    });

    if (!category) {
      console.log(`  Creating new category: ${mapping.categorySlug}`);
      category = await prisma.phraseCategory.create({
        data: {
          slug: mapping.categorySlug,
          displayName: mapping.excelFieldName,
          isSystem: false,
          isActive: true,
          displayOrder: 1000, // Put custom ones at end
        },
        include: { phrases: true },
      });
    }

    // Update each phrase with Excel text
    for (const optionMap of mapping.optionMappings) {
      const excelPhrase = excelField.options[optionMap.excelOption];

      if (!excelPhrase) {
        console.log(`  ⚠ Excel option "${optionMap.excelOption}" not found`);
        continue;
      }

      // Find existing phrase or create new
      let phrase = category.phrases.find((p) => p.value === optionMap.phraseValue);

      if (!phrase) {
        console.log(`  ➕ Creating phrase: "${optionMap.phraseValue}"`);
        phrase = await prisma.phrase.create({
          data: {
            categoryId: category.id,
            value: optionMap.phraseValue,
            displayOrder: category.phrases.length,
            isActive: true,
            isDefault: false,
            metadata: {
              excelPhrase: excelPhrase,
            },
          },
        });
      } else {
        console.log(`  ✏️  Updating phrase: "${optionMap.phraseValue}"`);
        await prisma.phrase.update({
          where: { id: phrase.id },
          data: {
            metadata: {
              ...(phrase.metadata as object),
              excelPhrase: excelPhrase,
            },
          },
        });
      }

      console.log(`     Excel phrase: ${excelPhrase.substring(0, 100)}...`);
    }
  }

  console.log('\n✅ Done!\n');
  await prisma.$disconnect();
}

// Run
updatePhrasesWithExcelText().catch((error) => {
  console.error('Error:', error);
  prisma.$disconnect();
  process.exit(1);
});
