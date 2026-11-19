-- Remote Editor v1.4 R1: stored report documents (original, final, archive) with checksums.
CREATE TYPE "ReportFileState" AS ENUM ('ORIGINAL', 'FINAL', 'ARCHIVE');
CREATE TYPE "ReportFileKind" AS ENUM ('PDF', 'DOCX', 'ZIP');

CREATE TABLE "report_files" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "state" "ReportFileState" NOT NULL,
    "kind" "ReportFileKind" NOT NULL,
    "file_name" VARCHAR(255) NOT NULL,
    "storage_path" VARCHAR(500) NOT NULL,
    "size" INTEGER NOT NULL,
    "sha256" VARCHAR(64) NOT NULL,
    "cycle" INTEGER NOT NULL DEFAULT 1,
    "version" INTEGER,
    "uploaded_by" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "report_files_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "report_files_report_id_state_idx" ON "report_files"("report_id", "state");
ALTER TABLE "report_files" ADD CONSTRAINT "report_files_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- The original document of each kind is written once and never replaced; one final document per edit cycle and kind.
CREATE UNIQUE INDEX "report_files_one_original" ON "report_files"("report_id", "kind") WHERE "state" = 'ORIGINAL';
CREATE UNIQUE INDEX "report_files_one_final" ON "report_files"("report_id", "cycle", "kind") WHERE "state" = 'FINAL';
