-- Normalize legacy surveyTypes values to the current SurveyType enum strings.
--
-- The original migrations (20260128100001, 20260129060000) seeded section type
-- definitions with legacy values: 'homebuyer', 'building', 'valuation'.
-- The application now uses the enum values: 'LEVEL_2', 'LEVEL_3', 'SNAGGING',
-- 'VALUATION', 'REINSPECTION', 'OTHER'.
--
-- The runtime seed (seedDefaultSectionTypes) only backfills rows with EMPTY
-- surveyTypes arrays, so it never corrects rows that already have legacy values.
--
-- This migration replaces legacy values in-place so that:
--   'homebuyer'  -> 'LEVEL_2'
--   'building'   -> 'LEVEL_3'
--   'valuation'  -> 'VALUATION'
--
-- Uses array_replace to swap each legacy value individually.

-- Step 1: Replace 'homebuyer' with 'LEVEL_2'
UPDATE "section_type_definitions"
SET "survey_types" = array_replace("survey_types", 'homebuyer', 'LEVEL_2'),
    "updated_at" = NOW()
WHERE 'homebuyer' = ANY("survey_types");

-- Step 2: Replace 'building' with 'LEVEL_3'
UPDATE "section_type_definitions"
SET "survey_types" = array_replace("survey_types", 'building', 'LEVEL_3'),
    "updated_at" = NOW()
WHERE 'building' = ANY("survey_types");

-- Step 3: Replace 'valuation' with 'VALUATION' (case normalization)
UPDATE "section_type_definitions"
SET "survey_types" = array_replace("survey_types", 'valuation', 'VALUATION'),
    "updated_at" = NOW()
WHERE 'valuation' = ANY("survey_types");

-- Step 4: Now apply the correct surveyTypes from the seed for section types
-- that had 'LEVEL_2' and 'LEVEL_3' but are missing 'SNAGGING'.
-- The seed defines INSPECTION = ['LEVEL_2', 'LEVEL_3', 'SNAGGING'] and
-- SHARED = [...INSPECTION, 'VALUATION'].
-- After steps 1-3, inspection-only rows have ['LEVEL_2', 'LEVEL_3'].
-- They should also include 'SNAGGING'.

-- Inspection-only section types: add SNAGGING where it's missing
UPDATE "section_type_definitions"
SET "survey_types" = array_append("survey_types", 'SNAGGING'),
    "updated_at" = NOW()
WHERE "key" IN (
    'about-inspection', 'external-items', 'internal-items', 'issues-and-risks',
    'construction', 'exterior', 'interior', 'rooms', 'services'
)
AND NOT ('SNAGGING' = ANY("survey_types"))
AND 'LEVEL_2' = ANY("survey_types");

-- Shared section types: add SNAGGING where it's missing
UPDATE "section_type_definitions"
SET "survey_types" = array_append("survey_types", 'SNAGGING'),
    "updated_at" = NOW()
WHERE "key" IN (
    'about-property', 'photos', 'notes', 'signature', 'summary'
)
AND NOT ('SNAGGING' = ANY("survey_types"))
AND 'LEVEL_2' = ANY("survey_types");

-- Bump config version so Flutter clients pick up the normalized values
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
