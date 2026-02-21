-- Phase 5C-3: Media Upload + Sync Core
-- This migration adds storage path to media and creates sync idempotency table

-- AlterTable: Add storagePath, updatedAt, deletedAt to media
ALTER TABLE "media" ADD COLUMN "storage_path" VARCHAR(500) NOT NULL DEFAULT '';
ALTER TABLE "media" ADD COLUMN "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "media" ADD COLUMN "deleted_at" TIMESTAMP(3);

-- CreateTable: SyncIdempotency for offline sync support
CREATE TABLE "sync_idempotency" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "idempotency_key" VARCHAR(255) NOT NULL,
    "request_hash" VARCHAR(64),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sync_idempotency_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: Sync indexes for updatedAt on surveys, sections, answers
CREATE INDEX "surveys_updated_at_idx" ON "surveys"("updated_at");
CREATE INDEX "sections_updated_at_idx" ON "sections"("updated_at");
CREATE INDEX "answers_updated_at_idx" ON "answers"("updated_at");

-- CreateIndex: Media indexes
CREATE INDEX "media_updated_at_idx" ON "media"("updated_at");
CREATE INDEX "media_deleted_at_idx" ON "media"("deleted_at");

-- CreateIndex: SyncIdempotency indexes
CREATE UNIQUE INDEX "sync_idempotency_user_id_idempotency_key_key" ON "sync_idempotency"("user_id", "idempotency_key");
CREATE INDEX "sync_idempotency_user_id_idx" ON "sync_idempotency"("user_id");
CREATE INDEX "sync_idempotency_created_at_idx" ON "sync_idempotency"("created_at");

-- AddForeignKey
ALTER TABLE "sync_idempotency" ADD CONSTRAINT "sync_idempotency_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
