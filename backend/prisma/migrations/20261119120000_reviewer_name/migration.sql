-- Remote Editor v1.4 R4: the display name a link holder gives. Typed by the person, never verified.
ALTER TABLE "editor_sessions" ADD COLUMN "reviewer_name" VARCHAR(80);
ALTER TABLE "report_audit_events" ADD COLUMN "actor_name" VARCHAR(80);
ALTER TABLE "report_versions" ADD COLUMN "saved_by_name" VARCHAR(80);
ALTER TABLE "reviews" ADD COLUMN "reviewer_name" VARCHAR(80);
