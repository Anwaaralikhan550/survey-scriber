-- Remote Editor v1.4 R3: field-level audit (what changed, from what to what, by whom). Append-only.
CREATE TABLE "report_audit_events" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "report_version" INTEGER NOT NULL,
    "entity_type" VARCHAR(20) NOT NULL,
    "entity_id" UUID,
    "section_id" UUID,
    "section_key" VARCHAR(100),
    "field" VARCHAR(30) NOT NULL,
    "op" VARCHAR(30) NOT NULL,
    "before_value" JSONB,
    "after_value" JSONB,
    "actor" VARCHAR(80) NOT NULL,
    "session_id" UUID,
    "source" VARCHAR(20) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "report_audit_events_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "report_audit_events_report_id_created_at_idx" ON "report_audit_events"("report_id", "created_at");
CREATE INDEX "report_audit_events_report_id_report_version_idx" ON "report_audit_events"("report_id", "report_version");
ALTER TABLE "report_audit_events" ADD CONSTRAINT "report_audit_events_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Append-only: no UPDATE, and a row can only go together with its report (retention purge).
CREATE FUNCTION report_audit_events_guard() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'report_audit_events rows are immutable' USING ERRCODE = 'check_violation';
  END IF;
  IF TG_OP = 'DELETE' THEN
    IF EXISTS (SELECT 1 FROM reports WHERE id = OLD.report_id) THEN
      RAISE EXCEPTION 'an audit event cannot be deleted while its report exists' USING ERRCODE = 'check_violation';
    END IF;
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'report_audit_events cannot be truncated' USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER report_audit_events_immutable BEFORE UPDATE OR DELETE ON "report_audit_events" FOR EACH ROW EXECUTE FUNCTION report_audit_events_guard();
CREATE TRIGGER report_audit_events_no_truncate BEFORE TRUNCATE ON "report_audit_events" FOR EACH STATEMENT EXECUTE FUNCTION report_audit_events_guard();
