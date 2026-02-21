-- AlterTable: Add section_type_key column to sections
ALTER TABLE "sections" ADD COLUMN "section_type_key" VARCHAR(100);

-- CreateIndex
CREATE INDEX "idx_sections_section_type_key" ON "sections"("section_type_key");

-- Backfill existing sections with known title-to-key mappings
UPDATE "sections" SET "section_type_key" = 'about-inspection' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('about this inspection', 'about inspection');
UPDATE "sections" SET "section_type_key" = 'about-property' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('about property', 'property information', 'about this property');
UPDATE "sections" SET "section_type_key" = 'construction' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('construction', 'construction details');
UPDATE "sections" SET "section_type_key" = 'external-items' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('external items', 'external');
UPDATE "sections" SET "section_type_key" = 'internal-items' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('internal items', 'internal');
UPDATE "sections" SET "section_type_key" = 'exterior' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('exterior', 'exterior assessment');
UPDATE "sections" SET "section_type_key" = 'interior' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('interior', 'interior assessment');
UPDATE "sections" SET "section_type_key" = 'rooms' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('rooms', 'room details');
UPDATE "sections" SET "section_type_key" = 'services' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('services', 'services & utilities');
UPDATE "sections" SET "section_type_key" = 'issues-and-risks' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('issues and risks', 'issues & defects', 'issues & risks');
UPDATE "sections" SET "section_type_key" = 'photos' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('photos', 'photo documentation', 'photo evidence');
UPDATE "sections" SET "section_type_key" = 'notes' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('notes', 'additional notes', 'notes & assumptions');
UPDATE "sections" SET "section_type_key" = 'signature' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('signature', 'sign off');
UPDATE "sections" SET "section_type_key" = 'about-valuation' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('about valuation', 'about this valuation');
UPDATE "sections" SET "section_type_key" = 'property-summary' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('property summary');
UPDATE "sections" SET "section_type_key" = 'market-analysis' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('market analysis');
UPDATE "sections" SET "section_type_key" = 'comparables' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('comparables', 'comparable properties');
UPDATE "sections" SET "section_type_key" = 'adjustments' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('adjustments');
UPDATE "sections" SET "section_type_key" = 'valuation' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('valuation', 'final valuation', 'valuation assessment');
UPDATE "sections" SET "section_type_key" = 'summary' WHERE "section_type_key" IS NULL AND LOWER("title") IN ('summary', 'summary & conclusion');
