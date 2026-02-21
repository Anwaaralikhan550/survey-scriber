-- Add deletedAt (soft-delete) column to phrase_categories and section_type_definitions.
-- Separates "disabled" (isActive=false) from "deleted" (deletedAt IS NOT NULL).
-- Enables undo-delete within a grace window.

ALTER TABLE "phrase_categories" ADD COLUMN "deleted_at" TIMESTAMP(3);
ALTER TABLE "section_type_definitions" ADD COLUMN "deleted_at" TIMESTAMP(3);

CREATE INDEX "phrase_categories_deleted_at_idx" ON "phrase_categories"("deleted_at");
CREATE INDEX "section_type_definitions_deleted_at_idx" ON "section_type_definitions"("deleted_at");
