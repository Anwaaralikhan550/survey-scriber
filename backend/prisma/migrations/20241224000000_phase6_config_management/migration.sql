-- Phase 6: Configuration Management
-- Enables dynamic, admin-editable phrases, dropdown options, and field definitions

-- ============================================
-- Config Version Tracking
-- ============================================

CREATE TABLE "config_versions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "version" INTEGER NOT NULL DEFAULT 1,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "updated_by" UUID,

    CONSTRAINT "config_versions_pkey" PRIMARY KEY ("id")
);

-- ============================================
-- Phrase Categories
-- ============================================

CREATE TABLE "phrase_categories" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "slug" VARCHAR(100) NOT NULL,
    "display_name" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "is_system" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "phrase_categories_pkey" PRIMARY KEY ("id")
);

-- Unique constraint on slug
CREATE UNIQUE INDEX "phrase_categories_slug_key" ON "phrase_categories"("slug");

-- Performance indexes
CREATE INDEX "phrase_categories_slug_idx" ON "phrase_categories"("slug");
CREATE INDEX "phrase_categories_is_active_idx" ON "phrase_categories"("is_active");
CREATE INDEX "phrase_categories_display_order_idx" ON "phrase_categories"("display_order");

-- ============================================
-- Phrases (Dropdown Options)
-- ============================================

CREATE TABLE "phrases" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "category_id" UUID NOT NULL,
    "value" VARCHAR(255) NOT NULL,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "phrases_pkey" PRIMARY KEY ("id")
);

-- Unique constraint: no duplicate values in same category
CREATE UNIQUE INDEX "phrases_category_id_value_key" ON "phrases"("category_id", "value");

-- Performance indexes
CREATE INDEX "phrases_category_id_idx" ON "phrases"("category_id");
CREATE INDEX "phrases_is_active_idx" ON "phrases"("is_active");
CREATE INDEX "phrases_display_order_idx" ON "phrases"("display_order");

-- Foreign key
ALTER TABLE "phrases" ADD CONSTRAINT "phrases_category_id_fkey"
    FOREIGN KEY ("category_id") REFERENCES "phrase_categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================
-- Field Type Enum
-- ============================================

CREATE TYPE "FieldType" AS ENUM ('TEXT', 'NUMBER', 'DROPDOWN', 'RADIO', 'CHECKBOX', 'DATE', 'SIGNATURE', 'TEXTAREA');

-- ============================================
-- Field Definitions
-- ============================================

CREATE TABLE "field_definitions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "section_type" VARCHAR(50) NOT NULL,
    "field_key" VARCHAR(100) NOT NULL,
    "field_type" "FieldType" NOT NULL,
    "label" VARCHAR(255) NOT NULL,
    "placeholder" VARCHAR(255),
    "hint" VARCHAR(500),
    "is_required" BOOLEAN NOT NULL DEFAULT false,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "phrase_category_id" UUID,
    "validation_rules" JSONB,
    "max_lines" INTEGER,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "field_definitions_pkey" PRIMARY KEY ("id")
);

-- Unique constraint: no duplicate fields in same section
CREATE UNIQUE INDEX "field_definitions_section_type_field_key_key" ON "field_definitions"("section_type", "field_key");

-- Performance indexes
CREATE INDEX "field_definitions_section_type_idx" ON "field_definitions"("section_type");
CREATE INDEX "field_definitions_is_active_idx" ON "field_definitions"("is_active");
CREATE INDEX "field_definitions_display_order_idx" ON "field_definitions"("display_order");
CREATE INDEX "field_definitions_phrase_category_id_idx" ON "field_definitions"("phrase_category_id");

-- Foreign key (optional - SetNull on delete)
ALTER TABLE "field_definitions" ADD CONSTRAINT "field_definitions_phrase_category_id_fkey"
    FOREIGN KEY ("phrase_category_id") REFERENCES "phrase_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================
-- Initialize Config Version
-- ============================================

INSERT INTO "config_versions" ("id", "version", "updated_at")
VALUES (gen_random_uuid(), 1, CURRENT_TIMESTAMP);
