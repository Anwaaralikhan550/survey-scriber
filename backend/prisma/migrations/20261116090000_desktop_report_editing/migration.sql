-- Secure desktop report editing (client spec v1.3): report, versions, edit links, editor sessions, reviews, photo manager columns.
-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('DRAFT', 'SUBMITTED_FOR_REVIEW', 'UNDER_REVIEW', 'AMENDMENTS_REQUIRED', 'REVIEWER_APPROVED', 'OWNER_FINAL_APPROVAL', 'FINALISING', 'FINALISED');

-- CreateEnum
CREATE TYPE "EditLinkStatus" AS ENUM ('ACTIVE', 'EXPIRED', 'CANCELLED', 'REVOKED', 'INVALIDATED');

-- CreateEnum
CREATE TYPE "ReviewDecision" AS ENUM ('SUBMITTED', 'APPROVED', 'AMENDMENTS_REQUIRED', 'OWNER_APPROVED');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "AuditEntityType" ADD VALUE 'REPORT';
ALTER TYPE "AuditEntityType" ADD VALUE 'EDIT_LINK';

-- AlterTable
ALTER TABLE "media" ADD COLUMN     "caption" VARCHAR(1000),
ADD COLUMN     "section_key" VARCHAR(100),
ADD COLUMN     "sort_order" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "reports" (
    "id" UUID NOT NULL,
    "survey_id" UUID NOT NULL,
    "owner_user_id" UUID NOT NULL,
    "report_type" VARCHAR(20) NOT NULL,
    "status" "ReportStatus" NOT NULL DEFAULT 'DRAFT',
    "content" JSONB NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "edit_cycle" INTEGER NOT NULL DEFAULT 1,
    "active_edit_link_id" UUID,
    "finalised_at" TIMESTAMP(3),
    "final_version" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "report_versions" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "version" INTEGER NOT NULL,
    "content" JSONB NOT NULL,
    "saved_by" VARCHAR(80),
    "reason" VARCHAR(20) NOT NULL,
    "idempotency_key" VARCHAR(80),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "report_versions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "edit_links" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "token_hash" VARCHAR(64) NOT NULL,
    "status" "EditLinkStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "ended_at" TIMESTAMP(3),

    CONSTRAINT "edit_links_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "editor_sessions" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "link_id" UUID NOT NULL,
    "session_hash" VARCHAR(64) NOT NULL,
    "csrf_hash" VARCHAR(64) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "last_seen_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revoked_at" TIMESTAMP(3),

    CONSTRAINT "editor_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reviews" (
    "id" UUID NOT NULL,
    "report_id" UUID NOT NULL,
    "session_id" UUID,
    "reviewer_user_id" UUID,
    "decision" "ReviewDecision" NOT NULL,
    "comment" TEXT,
    "version" INTEGER NOT NULL,
    "invalidated_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reviews_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "reports_survey_id_key" ON "reports"("survey_id");

-- CreateIndex
CREATE INDEX "reports_owner_user_id_idx" ON "reports"("owner_user_id");

-- CreateIndex
CREATE INDEX "reports_status_idx" ON "reports"("status");

-- CreateIndex
CREATE INDEX "report_versions_report_id_idx" ON "report_versions"("report_id");

-- CreateIndex
CREATE UNIQUE INDEX "report_versions_report_id_version_key" ON "report_versions"("report_id", "version");

-- CreateIndex
CREATE UNIQUE INDEX "report_versions_report_id_idempotency_key_key" ON "report_versions"("report_id", "idempotency_key");

-- CreateIndex
CREATE UNIQUE INDEX "edit_links_token_hash_key" ON "edit_links"("token_hash");

-- CreateIndex
CREATE INDEX "edit_links_report_id_status_idx" ON "edit_links"("report_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "editor_sessions_session_hash_key" ON "editor_sessions"("session_hash");

-- CreateIndex
CREATE INDEX "editor_sessions_report_id_idx" ON "editor_sessions"("report_id");

-- CreateIndex
CREATE INDEX "editor_sessions_link_id_idx" ON "editor_sessions"("link_id");

-- CreateIndex
CREATE INDEX "reviews_report_id_version_idx" ON "reviews"("report_id", "version");

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "surveys"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report_versions" ADD CONSTRAINT "report_versions_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "edit_links" ADD CONSTRAINT "edit_links_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "editor_sessions" ADD CONSTRAINT "editor_sessions_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "editor_sessions" ADD CONSTRAINT "editor_sessions_link_id_fkey" FOREIGN KEY ("link_id") REFERENCES "edit_links"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reviews" ADD CONSTRAINT "reviews_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Spec section 5.1: at most one ACTIVE edit link per report, enforced by the database itself.
-- Prisma cannot describe a partial index, so it lives only here.
CREATE UNIQUE INDEX "edit_links_one_active_per_report" ON "edit_links"("report_id") WHERE "status" = 'ACTIVE';
