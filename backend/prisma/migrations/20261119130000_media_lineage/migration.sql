-- Remote Editor v1.4 R6: pictures and signatures are never destroyed; where a picture came from, what replaced it, and its drawing.
ALTER TABLE "media" ADD COLUMN "source" VARCHAR(10) NOT NULL DEFAULT 'PHONE';
ALTER TABLE "media" ADD COLUMN "replaced_by_id" UUID;
ALTER TABLE "media" ADD COLUMN "annotations" JSONB;
-- Pictures added in the browser so far (report editing D4) are EDITOR pictures, not originals of the inspection.
UPDATE "media" m SET "source" = 'EDITOR'
WHERE m."type" = 'PHOTO'
  AND EXISTS (SELECT 1 FROM "audit_logs" a WHERE a."action" IN ('PHOTO_UPLOADED', 'PHOTO_REPLACED') AND a."metadata"->>'photoId' = m."id"::text);
