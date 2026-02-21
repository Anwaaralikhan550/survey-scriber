-- Deactivate legacy 'exterior' and 'interior' section type definitions.
--
-- These have been superseded by 'external-items' and 'internal-items'
-- which are the current inspection flow sections. The legacy keys were
-- seeded in 20260128100001 and caused duplicate sections to appear in
-- new surveys because the create_survey_provider merge logic appended
-- config section types not already in the hardcoded templates.
--
-- Marking them inactive (rather than deleting) preserves backward
-- compatibility for any existing surveys that reference these keys.

UPDATE "section_type_definitions"
SET "is_active" = false,
    "updated_at" = NOW()
WHERE "key" IN ('exterior', 'interior');

-- Bump config version so Flutter clients pick up the change
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
