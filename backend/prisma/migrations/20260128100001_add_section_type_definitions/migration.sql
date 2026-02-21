-- CreateTable
CREATE TABLE "section_type_definitions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "key" VARCHAR(50) NOT NULL,
    "label" VARCHAR(255) NOT NULL,
    "description" VARCHAR(500),
    "icon" VARCHAR(50),
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "survey_types" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "section_type_definitions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "section_type_definitions_key_key" ON "section_type_definitions"("key");

-- CreateIndex
CREATE INDEX "section_type_definitions_is_active_idx" ON "section_type_definitions"("is_active");

-- CreateIndex
CREATE INDEX "section_type_definitions_display_order_idx" ON "section_type_definitions"("display_order");

-- Seed existing section types from field definitions
INSERT INTO "section_type_definitions" ("id", "key", "label", "display_order", "survey_types", "is_active", "updated_at")
VALUES
  (gen_random_uuid(), 'about-property', 'About Property', 1, ARRAY['homebuyer', 'building', 'valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'construction', 'Construction', 2, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'exterior', 'Exterior', 3, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'interior', 'Interior', 4, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'rooms', 'Rooms', 5, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'services', 'Services', 6, ARRAY['homebuyer', 'building']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'photos', 'Photos', 7, ARRAY['homebuyer', 'building', 'valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'notes', 'Notes', 8, ARRAY['homebuyer', 'building', 'valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'signature', 'Signature', 9, ARRAY['homebuyer', 'building', 'valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'market-analysis', 'Market Analysis', 10, ARRAY['valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'comparables', 'Comparables', 11, ARRAY['valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'valuation', 'Valuation', 12, ARRAY['valuation']::TEXT[], true, NOW()),
  (gen_random_uuid(), 'summary', 'Summary', 13, ARRAY['homebuyer', 'building', 'valuation']::TEXT[], true, NOW())
ON CONFLICT ("key") DO NOTHING;

-- Bump config version
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
