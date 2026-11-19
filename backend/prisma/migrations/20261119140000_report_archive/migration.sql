-- Remote Editor v1.4 R7: complete archive export and restore.
ALTER TABLE "reports" ADD COLUMN "restored_at" TIMESTAMP(3);
ALTER TABLE "reports" ADD COLUMN "restored_from_sha256" VARCHAR(64);
ALTER TABLE "report_audit_events" ADD COLUMN "imported" BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE "report_archive_imports" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "uploader_id" UUID NOT NULL,
    "file_name" VARCHAR(255),
    "size" INTEGER NOT NULL,
    "sha256" VARCHAR(64) NOT NULL,
    "outcome" VARCHAR(12) NOT NULL,
    "error_code" VARCHAR(40),
    "message" VARCHAR(500),
    "restored_report_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "report_archive_imports_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "report_archive_imports_uploader_id_created_at_idx" ON "report_archive_imports"("uploader_id", "created_at");
