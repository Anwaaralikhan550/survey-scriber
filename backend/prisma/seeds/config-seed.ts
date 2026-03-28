/**
 * Phase 6: Configuration Seed Data
 * Converts all hardcoded dropdown options from Flutter to database records
 *
 * Run with: npx ts-node prisma/seeds/config-seed.ts
 */

import { PrismaClient, FieldType } from '@prisma/client';

const prisma = new PrismaClient();

// ============================================
// Phrase Categories & Phrases
// ============================================

interface PhraseCategorySeed {
  slug: string;
  displayName: string;
  description?: string;
  isSystem: boolean;
  displayOrder: number;
  phrases: string[];
}

const phraseCategories: PhraseCategorySeed[] = [
  // About Property
  {
    slug: 'property_types',
    displayName: 'Property Types',
    description: 'Types of properties for survey selection',
    isSystem: true,
    displayOrder: 1,
    phrases: [
      'Detached House',
      'Semi-Detached House',
      'Terraced House',
      'Bungalow',
      'Flat/Apartment',
      'Maisonette',
      'Commercial',
      'Industrial',
      'Other',
    ],
  },
  {
    slug: 'tenure_types',
    displayName: 'Tenure Types',
    description: 'Property ownership types',
    isSystem: true,
    displayOrder: 2,
    phrases: ['Freehold', 'Leasehold', 'Commonhold', 'Unknown'],
  },
  {
    slug: 'num_floors',
    displayName: 'Number of Floors',
    description: 'Building floor count options',
    isSystem: true,
    displayOrder: 3,
    phrases: ['1', '2', '3', '4', '5+'],
  },

  // Construction
  {
    slug: 'wall_construction',
    displayName: 'Wall Construction',
    description: 'Wall construction types',
    isSystem: true,
    displayOrder: 10,
    phrases: [
      'Brick/Block Cavity',
      'Solid Brick',
      'Stone',
      'Timber Frame',
      'Steel Frame',
      'Concrete',
      'Other',
    ],
  },
  {
    slug: 'roof_types',
    displayName: 'Roof Types',
    description: 'Types of roof construction',
    isSystem: true,
    displayOrder: 11,
    phrases: ['Pitched', 'Flat', 'Mixed', 'Other'],
  },
  {
    slug: 'roof_covering',
    displayName: 'Roof Covering',
    description: 'Roof covering materials',
    isSystem: true,
    displayOrder: 12,
    phrases: ['Tiles', 'Slate', 'Felt', 'Metal', 'Thatch', 'Other'],
  },
  {
    slug: 'foundation_types',
    displayName: 'Foundation Types',
    description: 'Building foundation types',
    isSystem: true,
    displayOrder: 13,
    phrases: ['Strip', 'Raft', 'Pile', 'Unknown'],
  },

  // Condition Ratings
  {
    slug: 'condition_5_scale',
    displayName: 'Condition (5-Point Scale)',
    description: 'Standard 5-point condition rating',
    isSystem: true,
    displayOrder: 20,
    phrases: ['Excellent', 'Good', 'Fair', 'Poor', 'Very Poor'],
  },
  {
    slug: 'condition_4_scale',
    displayName: 'Condition (4-Point Scale)',
    description: 'Standard 4-point condition rating',
    isSystem: true,
    displayOrder: 21,
    phrases: ['Good', 'Minor Issues', 'Needs Repair', 'Major Issues'],
  },
  {
    slug: 'condition_3_scale',
    displayName: 'Condition (3-Point Scale)',
    description: 'Simple 3-point condition rating',
    isSystem: true,
    displayOrder: 22,
    phrases: ['Good', 'Fair', 'Poor'],
  },

  // Exterior
  {
    slug: 'window_types',
    displayName: 'Window Types',
    description: 'Types of windows/glazing',
    isSystem: true,
    displayOrder: 30,
    phrases: [
      'Double Glazed uPVC',
      'Double Glazed Wood',
      'Single Glazed',
      'Secondary Glazing',
    ],
  },

  // Interior
  {
    slug: 'flooring_types',
    displayName: 'Flooring Types',
    description: 'Types of flooring (multi-select)',
    isSystem: true,
    displayOrder: 40,
    phrases: ['Carpet', 'Hardwood', 'Laminate', 'Tile', 'Vinyl', 'Concrete'],
  },
  {
    slug: 'decoration_standard',
    displayName: 'Decoration Standard',
    description: 'Interior decoration condition',
    isSystem: true,
    displayOrder: 41,
    phrases: ['Modern/Updated', 'Average', 'Dated', 'Needs Complete Refurbishment'],
  },
  {
    slug: 'damp_signs',
    displayName: 'Signs of Damp',
    description: 'Damp severity indicators',
    isSystem: true,
    displayOrder: 42,
    phrases: ['None Visible', 'Minor Signs', 'Moderate', 'Significant'],
  },
  {
    slug: 'report_default_paragraphs',
    displayName: 'Report Default Paragraphs',
    description: 'System default narrative paragraphs used by AST compiler rules',
    isSystem: true,
    displayOrder: 43,
    phrases: [
      'Inspection limitations apply where access, visibility, or safety constraints prevented a complete assessment of all elements.',
      'Moisture and dampness observations are based on visible surfaces and meter readings at inspection time only; concealed conditions may still exist.',
      'As the property type is Flat, it is assumed to be leasehold unless confirmed otherwise by legal title documents.',
    ],
  },

  // Rooms
  {
    slug: 'num_bedrooms',
    displayName: 'Number of Bedrooms',
    description: 'Bedroom count options',
    isSystem: true,
    displayOrder: 50,
    phrases: ['1', '2', '3', '4', '5', '6+'],
  },
  {
    slug: 'num_bathrooms',
    displayName: 'Number of Bathrooms',
    description: 'Bathroom count options',
    isSystem: true,
    displayOrder: 51,
    phrases: ['1', '2', '3', '4+'],
  },
  {
    slug: 'num_reception_rooms',
    displayName: 'Number of Reception Rooms',
    description: 'Reception room count options',
    isSystem: true,
    displayOrder: 52,
    phrases: ['1', '2', '3', '4+'],
  },
  {
    slug: 'kitchen_types',
    displayName: 'Kitchen Types',
    description: 'Kitchen style/configuration',
    isSystem: true,
    displayOrder: 53,
    phrases: ['Fitted Modern', 'Fitted Traditional', 'Basic', 'Open Plan'],
  },
  {
    slug: 'other_rooms',
    displayName: 'Other Rooms/Features',
    description: 'Additional rooms and features (multi-select)',
    isSystem: true,
    displayOrder: 54,
    phrases: [
      'Utility Room',
      'Conservatory',
      'Garage',
      'Cellar',
      'Loft Conversion',
      'Home Office',
    ],
  },

  // Services
  {
    slug: 'heating_types',
    displayName: 'Heating Types',
    description: 'Types of heating systems',
    isSystem: true,
    displayOrder: 60,
    phrases: ['Gas Central', 'Oil Central', 'Electric', 'Heat Pump', 'Solid Fuel', 'None'],
  },
  {
    slug: 'hot_water_systems',
    displayName: 'Hot Water Systems',
    description: 'Hot water system types',
    isSystem: true,
    displayOrder: 61,
    phrases: ['Combi Boiler', 'System Boiler', 'Immersion', 'Solar'],
  },
  {
    slug: 'electrical_condition',
    displayName: 'Electrical Installation Condition',
    description: 'Electrical system condition',
    isSystem: true,
    displayOrder: 62,
    phrases: ['Modern/Recent', 'Adequate', 'Dated', 'Needs Inspection'],
  },
  {
    slug: 'plumbing_condition',
    displayName: 'Plumbing Condition',
    description: 'Plumbing system condition',
    isSystem: true,
    displayOrder: 63,
    phrases: ['Good', 'Adequate', 'Poor'],
  },
  {
    slug: 'drainage_types',
    displayName: 'Drainage Types',
    description: 'Property drainage types',
    isSystem: true,
    displayOrder: 64,
    phrases: ['Mains', 'Septic Tank', 'Cesspit', 'Unknown'],
  },

  // Valuation - Market Analysis
  {
    slug: 'market_conditions',
    displayName: 'Market Conditions',
    description: 'Current property market conditions',
    isSystem: true,
    displayOrder: 70,
    phrases: ['Strong/Rising', 'Stable', 'Weak/Falling', 'Uncertain'],
  },
  {
    slug: 'demand_levels',
    displayName: 'Demand Levels',
    description: 'Local property demand level',
    isSystem: true,
    displayOrder: 71,
    phrases: ['High', 'Moderate', 'Low'],
  },
  {
    slug: 'time_on_market',
    displayName: 'Expected Time on Market',
    description: 'Expected time to sell',
    isSystem: true,
    displayOrder: 72,
    phrases: ['< 1 month', '1-3 months', '3-6 months', '6+ months'],
  },
  {
    slug: 'valuation_approaches',
    displayName: 'Valuation Approaches',
    description: 'Property valuation methods',
    isSystem: true,
    displayOrder: 73,
    phrases: ['Comparable Method', 'Income Method', 'Cost Method', 'Residual Method'],
  },

  // Signatures
  {
    slug: 'signer_roles',
    displayName: 'Signer Roles',
    description: 'Roles for signature capture',
    isSystem: true,
    displayOrder: 80,
    phrases: [
      'Surveyor',
      'Client',
      'Witness',
      'Inspector',
      'Property Owner',
      'Tenant',
      'Contractor',
    ],
  },
];

// ============================================
// Field Definitions
// ============================================

interface FieldDefinitionSeed {
  sectionType: string;
  fieldKey: string;
  fieldType: FieldType;
  label: string;
  placeholder?: string;
  hint?: string;
  isRequired: boolean;
  displayOrder: number;
  phraseCategorySlug?: string; // Links to phrase category
  maxLines?: number;
}

const fieldDefinitions: FieldDefinitionSeed[] = [
  // About Property (kebab-case to match SectionTypeDefinition.key)
  { sectionType: 'about-property', fieldKey: 'property_type', fieldType: 'DROPDOWN', label: 'Property Type', isRequired: false, displayOrder: 1, phraseCategorySlug: 'property_types' },
  { sectionType: 'about-property', fieldKey: 'tenure', fieldType: 'DROPDOWN', label: 'Tenure', isRequired: false, displayOrder: 2, phraseCategorySlug: 'tenure_types' },
  { sectionType: 'about-property', fieldKey: 'year_built', fieldType: 'TEXT', label: 'Year Built (Approximate)', hint: 'e.g., 1990', isRequired: false, displayOrder: 3 },
  { sectionType: 'about-property', fieldKey: 'floor_area', fieldType: 'NUMBER', label: 'Approximate Floor Area (sqm)', hint: 'e.g., 150', isRequired: false, displayOrder: 4 },
  { sectionType: 'about-property', fieldKey: 'num_floors', fieldType: 'DROPDOWN', label: 'Number of Floors', isRequired: false, displayOrder: 5, phraseCategorySlug: 'num_floors' },

  // Construction
  { sectionType: 'construction', fieldKey: 'wall_construction', fieldType: 'DROPDOWN', label: 'Wall Construction', isRequired: false, displayOrder: 1, phraseCategorySlug: 'wall_construction' },
  { sectionType: 'construction', fieldKey: 'roof_type', fieldType: 'DROPDOWN', label: 'Roof Type', isRequired: false, displayOrder: 2, phraseCategorySlug: 'roof_types' },
  { sectionType: 'construction', fieldKey: 'roof_covering', fieldType: 'DROPDOWN', label: 'Roof Covering', isRequired: false, displayOrder: 3, phraseCategorySlug: 'roof_covering' },
  { sectionType: 'construction', fieldKey: 'foundation_type', fieldType: 'DROPDOWN', label: 'Foundation Type', isRequired: false, displayOrder: 4, phraseCategorySlug: 'foundation_types' },
  { sectionType: 'construction', fieldKey: 'construction_notes', fieldType: 'TEXTAREA', label: 'Construction Notes', hint: 'Any additional construction observations', isRequired: false, displayOrder: 5, maxLines: 3 },

  // Exterior
  { sectionType: 'exterior', fieldKey: 'exterior_condition', fieldType: 'RADIO', label: 'Overall Exterior Condition', isRequired: false, displayOrder: 1, phraseCategorySlug: 'condition_5_scale' },
  { sectionType: 'exterior', fieldKey: 'external_walls', fieldType: 'RADIO', label: 'External Walls Condition', isRequired: false, displayOrder: 2, phraseCategorySlug: 'condition_4_scale' },
  { sectionType: 'exterior', fieldKey: 'windows', fieldType: 'DROPDOWN', label: 'Windows Type', isRequired: false, displayOrder: 3, phraseCategorySlug: 'window_types' },
  { sectionType: 'exterior', fieldKey: 'doors_condition', fieldType: 'RADIO', label: 'External Doors Condition', isRequired: false, displayOrder: 4, phraseCategorySlug: 'condition_3_scale' },
  { sectionType: 'exterior', fieldKey: 'exterior_notes', fieldType: 'TEXTAREA', label: 'Exterior Notes', hint: 'Additional observations', isRequired: false, displayOrder: 5, maxLines: 3 },

  // Interior
  { sectionType: 'interior', fieldKey: 'interior_condition', fieldType: 'RADIO', label: 'Overall Interior Condition', isRequired: false, displayOrder: 1, phraseCategorySlug: 'condition_5_scale' },
  { sectionType: 'interior', fieldKey: 'flooring', fieldType: 'CHECKBOX', label: 'Main Flooring Types', isRequired: false, displayOrder: 2, phraseCategorySlug: 'flooring_types' },
  { sectionType: 'interior', fieldKey: 'decoration', fieldType: 'RADIO', label: 'Decoration Standard', isRequired: false, displayOrder: 3, phraseCategorySlug: 'decoration_standard' },
  { sectionType: 'interior', fieldKey: 'damp_signs', fieldType: 'RADIO', label: 'Signs of Damp', isRequired: false, displayOrder: 4, phraseCategorySlug: 'damp_signs' },
  { sectionType: 'interior', fieldKey: 'interior_notes', fieldType: 'TEXTAREA', label: 'Interior Notes', hint: 'Additional observations', isRequired: false, displayOrder: 5, maxLines: 3 },
  { sectionType: 'interior', fieldKey: 'inspection_limitations_default', fieldType: 'TEXTAREA', label: 'Inspection Limitations (Default)', isRequired: false, displayOrder: 6, phraseCategorySlug: 'report_default_paragraphs', maxLines: 3 },
  { sectionType: 'interior', fieldKey: 'moisture_dampness_default', fieldType: 'TEXTAREA', label: 'Moisture and Dampness (Default)', isRequired: false, displayOrder: 7, phraseCategorySlug: 'report_default_paragraphs', maxLines: 3 },

  // Rooms
  { sectionType: 'rooms', fieldKey: 'num_bedrooms', fieldType: 'DROPDOWN', label: 'Number of Bedrooms', isRequired: false, displayOrder: 1, phraseCategorySlug: 'num_bedrooms' },
  { sectionType: 'rooms', fieldKey: 'num_bathrooms', fieldType: 'DROPDOWN', label: 'Number of Bathrooms', isRequired: false, displayOrder: 2, phraseCategorySlug: 'num_bathrooms' },
  { sectionType: 'rooms', fieldKey: 'num_reception', fieldType: 'DROPDOWN', label: 'Number of Reception Rooms', isRequired: false, displayOrder: 3, phraseCategorySlug: 'num_reception_rooms' },
  { sectionType: 'rooms', fieldKey: 'kitchen_type', fieldType: 'DROPDOWN', label: 'Kitchen Type', isRequired: false, displayOrder: 4, phraseCategorySlug: 'kitchen_types' },
  { sectionType: 'rooms', fieldKey: 'other_rooms', fieldType: 'CHECKBOX', label: 'Other Rooms/Features', isRequired: false, displayOrder: 5, phraseCategorySlug: 'other_rooms' },

  // Services
  { sectionType: 'services', fieldKey: 'heating_type', fieldType: 'DROPDOWN', label: 'Heating Type', isRequired: false, displayOrder: 1, phraseCategorySlug: 'heating_types' },
  { sectionType: 'services', fieldKey: 'hot_water', fieldType: 'DROPDOWN', label: 'Hot Water System', isRequired: false, displayOrder: 2, phraseCategorySlug: 'hot_water_systems' },
  { sectionType: 'services', fieldKey: 'electrics', fieldType: 'RADIO', label: 'Electrical Installation', isRequired: false, displayOrder: 3, phraseCategorySlug: 'electrical_condition' },
  { sectionType: 'services', fieldKey: 'plumbing', fieldType: 'RADIO', label: 'Plumbing Condition', isRequired: false, displayOrder: 4, phraseCategorySlug: 'plumbing_condition' },
  { sectionType: 'services', fieldKey: 'drainage', fieldType: 'DROPDOWN', label: 'Drainage', isRequired: false, displayOrder: 5, phraseCategorySlug: 'drainage_types' },

  // Inspection - E8 / E9 alignment for report payload coverage
  { sectionType: 'e8-other-joinery-and-finishes', fieldKey: 'condition_rating', fieldType: 'DROPDOWN', label: 'Condition Rating', isRequired: false, displayOrder: 1, phraseCategorySlug: 'condition_3_scale' },
  { sectionType: 'e8-other-joinery-and-finishes', fieldKey: 'e8_notes', fieldType: 'TEXTAREA', label: 'E8 Notes', isRequired: false, displayOrder: 2, maxLines: 3 },
  { sectionType: 'e9-other-outside-property', fieldKey: 'condition_rating', fieldType: 'DROPDOWN', label: 'Condition Rating', isRequired: false, displayOrder: 1, phraseCategorySlug: 'condition_3_scale' },
  { sectionType: 'e9-other-outside-property', fieldKey: 'e9_notes', fieldType: 'TEXTAREA', label: 'E9 Notes', isRequired: false, displayOrder: 2, maxLines: 3 },

  // Photos
  { sectionType: 'photos', fieldKey: 'front_exterior', fieldType: 'TEXT', label: 'Front Exterior Photo', hint: 'Photo reference or notes', isRequired: false, displayOrder: 1 },
  { sectionType: 'photos', fieldKey: 'rear_exterior', fieldType: 'TEXT', label: 'Rear Exterior Photo', hint: 'Photo reference or notes', isRequired: false, displayOrder: 2 },
  { sectionType: 'photos', fieldKey: 'kitchen_photo', fieldType: 'TEXT', label: 'Kitchen Photo', hint: 'Photo reference or notes', isRequired: false, displayOrder: 3 },
  { sectionType: 'photos', fieldKey: 'bathroom_photo', fieldType: 'TEXT', label: 'Bathroom Photo', hint: 'Photo reference or notes', isRequired: false, displayOrder: 4 },
  { sectionType: 'photos', fieldKey: 'photo_notes', fieldType: 'TEXTAREA', label: 'Photo Notes', hint: 'Additional photo documentation notes', isRequired: false, displayOrder: 5, maxLines: 3 },

  // Notes
  { sectionType: 'notes', fieldKey: 'general_notes', fieldType: 'TEXTAREA', label: 'General Notes', hint: 'Enter any general observations', isRequired: false, displayOrder: 1, maxLines: 5 },
  { sectionType: 'notes', fieldKey: 'defects_noted', fieldType: 'TEXTAREA', label: 'Defects Noted', hint: 'List any defects observed', isRequired: false, displayOrder: 2, maxLines: 4 },
  { sectionType: 'notes', fieldKey: 'recommendations', fieldType: 'TEXTAREA', label: 'Recommendations', hint: 'Any recommendations for the client', isRequired: false, displayOrder: 3, maxLines: 4 },

  // Signature
  { sectionType: 'signature', fieldKey: 'surveyor_name', fieldType: 'TEXT', label: 'Surveyor Name', hint: 'Enter your full name', isRequired: false, displayOrder: 1 },
  { sectionType: 'signature', fieldKey: 'survey_date', fieldType: 'DATE', label: 'Survey Date', isRequired: false, displayOrder: 2 },
  { sectionType: 'signature', fieldKey: 'signature', fieldType: 'SIGNATURE', label: 'Signature', isRequired: false, displayOrder: 3 },
  { sectionType: 'signature', fieldKey: 'declaration', fieldType: 'TEXTAREA', label: 'Declaration', hint: 'I confirm this survey was conducted accurately', isRequired: false, displayOrder: 4, maxLines: 2 },

  // Market Analysis (Valuation) — kebab-case to match SectionTypeDefinition.key
  { sectionType: 'market-analysis', fieldKey: 'market_conditions', fieldType: 'DROPDOWN', label: 'Current Market Conditions', isRequired: false, displayOrder: 1, phraseCategorySlug: 'market_conditions' },
  { sectionType: 'market-analysis', fieldKey: 'demand_level', fieldType: 'RADIO', label: 'Local Demand Level', isRequired: false, displayOrder: 2, phraseCategorySlug: 'demand_levels' },
  { sectionType: 'market-analysis', fieldKey: 'time_on_market', fieldType: 'DROPDOWN', label: 'Expected Time on Market', isRequired: false, displayOrder: 3, phraseCategorySlug: 'time_on_market' },
  { sectionType: 'market-analysis', fieldKey: 'market_analysis_notes', fieldType: 'TEXTAREA', label: 'Market Analysis Notes', hint: 'Additional market observations', isRequired: false, displayOrder: 4, maxLines: 4 },

  // Comparables (Valuation)
  { sectionType: 'comparables', fieldKey: 'comparable_1', fieldType: 'TEXT', label: 'Comparable 1 Address & Price', hint: 'Address and sale price', isRequired: false, displayOrder: 1 },
  { sectionType: 'comparables', fieldKey: 'comparable_2', fieldType: 'TEXT', label: 'Comparable 2 Address & Price', hint: 'Address and sale price', isRequired: false, displayOrder: 2 },
  { sectionType: 'comparables', fieldKey: 'comparable_3', fieldType: 'TEXT', label: 'Comparable 3 Address & Price', hint: 'Address and sale price', isRequired: false, displayOrder: 3 },
  { sectionType: 'comparables', fieldKey: 'adjustments', fieldType: 'TEXTAREA', label: 'Adjustments Made', hint: 'Describe any adjustments to comparables', isRequired: false, displayOrder: 4, maxLines: 3 },

  // Valuation
  { sectionType: 'valuation', fieldKey: 'valuation_approach', fieldType: 'DROPDOWN', label: 'Valuation Approach', isRequired: false, displayOrder: 1, phraseCategorySlug: 'valuation_approaches' },
  { sectionType: 'valuation', fieldKey: 'market_value', fieldType: 'NUMBER', label: 'Market Value Estimate', hint: 'Enter value in currency', isRequired: false, displayOrder: 2 },
  { sectionType: 'valuation', fieldKey: 'forced_sale_value', fieldType: 'NUMBER', label: 'Forced Sale Value (if applicable)', hint: 'Enter value in currency', isRequired: false, displayOrder: 3 },
  { sectionType: 'valuation', fieldKey: 'valuation_assumptions', fieldType: 'TEXTAREA', label: 'Assumptions & Conditions', hint: 'List any assumptions made', isRequired: false, displayOrder: 4, maxLines: 4 },

  // Summary
  { sectionType: 'summary', fieldKey: 'executive_summary', fieldType: 'TEXTAREA', label: 'Executive Summary', hint: 'Brief summary of findings', isRequired: false, displayOrder: 1, maxLines: 5 },
  { sectionType: 'summary', fieldKey: 'key_findings', fieldType: 'TEXTAREA', label: 'Key Findings', hint: 'List the main findings', isRequired: false, displayOrder: 2, maxLines: 4 },
  { sectionType: 'summary', fieldKey: 'final_opinion', fieldType: 'TEXTAREA', label: 'Final Opinion', hint: 'Your professional opinion', isRequired: false, displayOrder: 3, maxLines: 4 },
];

// ============================================
// Seed Execution
// ============================================

async function main() {
  console.log('🌱 Starting configuration seed...');

  // Create phrase categories and their phrases
  const categoryMap = new Map<string, string>(); // slug -> id

  for (const category of phraseCategories) {
    console.log(`  📁 Creating category: ${category.displayName}`);

    const created = await prisma.phraseCategory.upsert({
      where: { slug: category.slug },
      update: {
        displayName: category.displayName,
        description: category.description,
        isSystem: category.isSystem,
        displayOrder: category.displayOrder,
      },
      create: {
        slug: category.slug,
        displayName: category.displayName,
        description: category.description,
        isSystem: category.isSystem,
        isActive: true,
        displayOrder: category.displayOrder,
      },
    });

    categoryMap.set(category.slug, created.id);

    // Create phrases for this category
    for (let i = 0; i < category.phrases.length; i++) {
      const phrase = category.phrases[i];
      await prisma.phrase.upsert({
        where: {
          categoryId_value: {
            categoryId: created.id,
            value: phrase,
          },
        },
        update: {
          displayOrder: i,
          isActive: true,
        },
        create: {
          categoryId: created.id,
          value: phrase,
          displayOrder: i,
          isActive: true,
          isDefault: i === 0, // First option is default
        },
      });
    }

    console.log(`    ✅ Created ${category.phrases.length} phrases`);
  }

  // ============================================
  // Normalize legacy camelCase sectionType values → kebab-case
  // Existing deployments may have field_definitions with camelCase
  // sectionType values (e.g., 'aboutProperty') from before the
  // convention was standardized to kebab-case.
  // ============================================
  const legacyMappings: Record<string, string> = {
    'aboutProperty': 'about-property',
    'aboutInspection': 'about-inspection',
    'marketAnalysis': 'market-analysis',
    'externalItems': 'external-items',
    'internalItems': 'internal-items',
    'issuesAndRisks': 'issues-and-risks',
    'aboutValuation': 'about-valuation',
    'propertySummary': 'property-summary',
  };

  console.log(`\n🔧 Normalizing legacy sectionType values...`);
  for (const [camelCase, kebabCase] of Object.entries(legacyMappings)) {
    const result = await prisma.fieldDefinition.updateMany({
      where: { sectionType: camelCase },
      data: { sectionType: kebabCase },
    });
    if (result.count > 0) {
      console.log(`  ✅ Migrated ${result.count} fields: ${camelCase} → ${kebabCase}`);
    }
  }

  console.log(`\n📋 Creating field definitions...`);

  // Create field definitions
  for (const field of fieldDefinitions) {
    const phraseCategoryId = field.phraseCategorySlug
      ? categoryMap.get(field.phraseCategorySlug)
      : null;

    await prisma.fieldDefinition.upsert({
      where: {
        sectionType_fieldKey: {
          sectionType: field.sectionType,
          fieldKey: field.fieldKey,
        },
      },
      update: {
        fieldType: field.fieldType,
        label: field.label,
        placeholder: field.placeholder,
        hint: field.hint,
        isRequired: field.isRequired,
        displayOrder: field.displayOrder,
        phraseCategoryId,
        maxLines: field.maxLines,
        isActive: true,
      },
      create: {
        sectionType: field.sectionType,
        fieldKey: field.fieldKey,
        fieldType: field.fieldType,
        label: field.label,
        placeholder: field.placeholder,
        hint: field.hint,
        isRequired: field.isRequired,
        displayOrder: field.displayOrder,
        phraseCategoryId,
        maxLines: field.maxLines,
        isActive: true,
      },
    });
  }

  console.log(`  ✅ Created ${fieldDefinitions.length} field definitions`);

  // Update config version
  await prisma.configVersion.updateMany({
    data: {
      version: { increment: 1 },
    },
  });

  console.log('\n✅ Configuration seed completed successfully!');
  console.log(`   📁 Categories: ${phraseCategories.length}`);
  console.log(`   📝 Phrases: ${phraseCategories.reduce((sum, c) => sum + c.phrases.length, 0)}`);
  console.log(`   📋 Fields: ${fieldDefinitions.length}`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
