-- Remote Editor v1.4 R2: the immutable original report snapshot.
CREATE TABLE "report_original_snapshots" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "schema_version" INTEGER NOT NULL DEFAULT 1,
    "survey_type" VARCHAR(20) NOT NULL,
    "tree_version_id" VARCHAR(100),
    "phrase_bank_version_id" VARCHAR(100),
    "generated_at" TIMESTAMP(3) NOT NULL,
    "app_version" VARCHAR(50),
    "snapshot" JSONB NOT NULL,
    "checksum" VARCHAR(64) NOT NULL,
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "report_original_snapshots_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "report_original_snapshots_report_id_key" ON "report_original_snapshots"("report_id");
ALTER TABLE "report_original_snapshots" ADD CONSTRAINT "report_original_snapshots_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Immutable: no UPDATE ever; a row can only go when its report is gone (the cascade of a purge), never on its own.
CREATE FUNCTION report_original_snapshots_guard() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'report_original_snapshots rows are immutable' USING ERRCODE = 'check_violation';
  END IF;
  IF TG_OP = 'DELETE' THEN
    IF EXISTS (SELECT 1 FROM reports WHERE id = OLD.report_id) THEN
      RAISE EXCEPTION 'an original report snapshot cannot be deleted while its report exists' USING ERRCODE = 'check_violation';
    END IF;
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'report_original_snapshots cannot be truncated' USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER report_original_snapshots_immutable
  BEFORE UPDATE OR DELETE ON "report_original_snapshots"
  FOR EACH ROW EXECUTE FUNCTION report_original_snapshots_guard();
CREATE TRIGGER report_original_snapshots_no_truncate
  BEFORE TRUNCATE ON "report_original_snapshots"
  FOR EACH STATEMENT EXECUTE FUNCTION report_original_snapshots_guard();

-- Reports that already exist get an original snapshot from their first uploaded version (version 1).
INSERT INTO "report_original_snapshots" ("id", "report_id", "schema_version", "survey_type", "generated_at", "snapshot", "checksum", "created_by")
SELECT gen_random_uuid(), r."id", 1,
       CASE WHEN r."report_type" = 'VALUATION' THEN 'VALUATION' ELSE 'INSPECTION' END,
       v."created_at",
       snap.j,
       encode(sha256(convert_to(snap.j::text, 'UTF8')), 'hex'),
       r."owner_user_id"
FROM "reports" r
JOIN "report_versions" v ON v."report_id" = r."id" AND v."version" = 1
JOIN "surveys" s ON s."id" = r."survey_id"
CROSS JOIN LATERAL (
  SELECT jsonb_build_object(
    'schemaVersion', 1,
    'surveyId', r."id",
    'surveyType', CASE WHEN r."report_type" = 'VALUATION' THEN 'VALUATION' ELSE 'INSPECTION' END,
    'generatedAt', v."created_at",
    'survey', jsonb_build_object('title', s."title", 'propertyAddress', s."property_address", 'jobRef', s."job_ref", 'clientName', s."client_name"),
    'sections', v."content",
    'media', '[]'::jsonb,
    'signatures', '[]'::jsonb,
    'capturedFrom', 'backfill of report version 1'
  ) AS j
) snap;
