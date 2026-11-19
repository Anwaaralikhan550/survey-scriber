-- Remote Editor v1.4 R8: retention (60 days finalised / 30 days drafts), warnings, purge queue with tombstone, legal hold.
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'REPORT_RETENTION_WARNING';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'REPORT_LEGAL_HOLD';
ALTER TYPE "NotificationType" ADD VALUE IF NOT EXISTS 'REPORT_PURGED';

CREATE TABLE "report_retention" (
    "report_id" UUID NOT NULL,
    "policy" VARCHAR(12) NOT NULL,
    "anchor_at" TIMESTAMP(3) NOT NULL,
    "delete_at" TIMESTAMP(3) NOT NULL,
    "warned_days" INTEGER[] NOT NULL DEFAULT ARRAY[]::INTEGER[],
    "grace_until" TIMESTAMP(3),
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "report_retention_pkey" PRIMARY KEY ("report_id"),
    CONSTRAINT "report_retention_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "report_retention_delete_at_idx" ON "report_retention"("delete_at");

CREATE TABLE "report_legal_holds" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "report_id" UUID NOT NULL,
    "reason" VARCHAR(500) NOT NULL,
    "placed_by" UUID NOT NULL,
    "placed_by_role" VARCHAR(20) NOT NULL,
    "placed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "released_by" UUID,
    "released_at" TIMESTAMP(3),
    "release_reason" VARCHAR(500),
    CONSTRAINT "report_legal_holds_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "report_legal_holds_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "report_legal_holds_report_id_idx" ON "report_legal_holds"("report_id");
-- at most one active hold per report
CREATE UNIQUE INDEX "report_legal_holds_one_active_idx" ON "report_legal_holds"("report_id") WHERE "released_at" IS NULL;

CREATE TABLE "report_deletions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "report_id" UUID NOT NULL,
    "owner_user_id" UUID NOT NULL,
    "policy" VARCHAR(12) NOT NULL,
    "anchor_at" TIMESTAMP(3) NOT NULL,
    "delete_at" TIMESTAMP(3) NOT NULL,
    "status" VARCHAR(10) NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "next_attempt_at" TIMESTAMP(3) NOT NULL,
    "last_error" VARCHAR(300),
    "files_deleted" INTEGER NOT NULL DEFAULT 0,
    "purged_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "report_deletions_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "report_deletions_report_id_key" ON "report_deletions"("report_id");
CREATE INDEX "report_deletions_status_next_attempt_at_idx" ON "report_deletions"("status", "next_attempt_at");
