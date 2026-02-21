-- Phase 7: Dynamic Form Builder - Add missing columns to field_definitions
-- Adds group, conditional visibility, and description support

-- Add field_group column for UI grouping within sections
ALTER TABLE "field_definitions" ADD COLUMN "field_group" VARCHAR(100);

-- Add conditional visibility columns
ALTER TABLE "field_definitions" ADD COLUMN "conditional_on" VARCHAR(100);
ALTER TABLE "field_definitions" ADD COLUMN "conditional_value" VARCHAR(255);

-- Add extended description column
ALTER TABLE "field_definitions" ADD COLUMN "description" VARCHAR(1000);

-- Fix section type naming: standardize camelCase to kebab-case for consistency
-- This ensures mobile (kebab-case) matches DB records
UPDATE "field_definitions" SET "section_type" = 'about-property' WHERE "section_type" = 'aboutProperty';
UPDATE "field_definitions" SET "section_type" = 'about-inspection' WHERE "section_type" = 'aboutInspection';
UPDATE "field_definitions" SET "section_type" = 'external-items' WHERE "section_type" = 'externalItems';
UPDATE "field_definitions" SET "section_type" = 'internal-items' WHERE "section_type" = 'internalItems';
UPDATE "field_definitions" SET "section_type" = 'issues-and-risks' WHERE "section_type" = 'issuesAndRisks';
UPDATE "field_definitions" SET "section_type" = 'about-valuation' WHERE "section_type" = 'aboutValuation';
UPDATE "field_definitions" SET "section_type" = 'property-summary' WHERE "section_type" = 'propertySummary';
UPDATE "field_definitions" SET "section_type" = 'market-analysis' WHERE "section_type" = 'marketAnalysis';

-- Bump config version so mobile clients refetch
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
