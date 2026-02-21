-- Add new FieldType enum values
ALTER TYPE "FieldType" ADD VALUE 'TIME';
ALTER TYPE "FieldType" ADD VALUE 'BOOLEAN';
ALTER TYPE "FieldType" ADD VALUE 'MULTI_SELECT';
ALTER TYPE "FieldType" ADD VALUE 'PHOTO';

-- Bump config version
UPDATE "config_versions" SET "version" = "version" + 1, "updated_at" = NOW();
