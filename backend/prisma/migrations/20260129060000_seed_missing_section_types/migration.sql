-- Seed missing section type keys that Flutter SectionTemplates expect
-- but were not included in the original 20260128100001 migration.
--
-- Root cause: The original seed used legacy keys ("exterior", "interior")
-- while Flutter templates now use "external-items" and "internal-items".
-- Additionally, several new section types were never seeded:
--   about-inspection, issues-and-risks (inspection)
--   about-valuation, property-summary, adjustments (valuation)
--
-- ON CONFLICT DO NOTHING ensures idempotency if rows already exist.

-- Missing inspection section types
INSERT INTO "section_type_definitions" ("id", "key", "label", "display_order", "survey_types", "is_active", "updated_at")
VALUES
  (gen_random_uuid(), 'about-inspection',  'About Inspection',    0, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'external-items',    'External Inspection', 3, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'internal-items',    'Internal Inspection', 4, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'issues-and-risks',  'Issues & Risks',      8, ARRAY['homebuyer', 'building']::TEXT[], true, NOW())
ON CONFLICT ("key") DO NOTHING;

-- Missing valuation section types
INSERT INTO "section_type_definitions" ("id", "key", "label", "display_order", "survey_types", "is_active", "updated_at")
VALUES
  (gen_random_uuid(), 'about-valuation',   'About Valuation',     0, ARRAY['valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'property-summary',  'Property Summary',    2, ARRAY['valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'adjustments',       'Value Adjustments',   5, ARRAY['valuation']::TEXT[], true, NOW())
ON CONFLICT ("key") DO NOTHING;

-- Bump config version so Flutter clients pick up the new section types
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
