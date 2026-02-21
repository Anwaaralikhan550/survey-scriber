-- Reclassify section types that were incorrectly marked as SHARED.
--
-- 'about-property', 'construction', 'rooms', 'services', and 'notes' are
-- inspection-specific sections. Valuation surveys have their own equivalents
-- (about-valuation, property-summary, etc.). When these were marked SHARED,
-- the Flutter create_survey_provider merged them into new valuation surveys
-- as extra sections appearing after Sign Off.
--
-- 'photos' and 'signature' remain SHARED since both flows use them.

UPDATE "section_type_definitions"
SET "survey_types" = ARRAY['LEVEL_2', 'LEVEL_3', 'SNAGGING'],
    "updated_at" = NOW()
WHERE "key" IN ('about-property', 'construction', 'rooms', 'services', 'notes')
  AND 'VALUATION' = ANY("survey_types");

-- Bump config version so Flutter clients pick up the change
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
