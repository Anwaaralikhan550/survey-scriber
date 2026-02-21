/*
  Warnings:

  - The values [TIME,BOOLEAN,MULTI_SELECT,PHOTO] on the enum `FieldType` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `booking_deleted` on the `notifications` table. All the data in the column will be lost.
  - You are about to drop the column `orphan_detected_at` on the `notifications` table. All the data in the column will be lost.
  - You are about to drop the column `completed_at` on the `surveys` table. All the data in the column will be lost.
  - You are about to drop the column `failed_login_attempts` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `locked_until` on the `users` table. All the data in the column will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "FieldType_new" AS ENUM ('TEXT', 'NUMBER', 'DROPDOWN', 'RADIO', 'CHECKBOX', 'DATE', 'SIGNATURE', 'TEXTAREA');
ALTER TABLE "field_definitions" ALTER COLUMN "field_type" TYPE "FieldType_new" USING ("field_type"::text::"FieldType_new");
ALTER TYPE "FieldType" RENAME TO "FieldType_old";
ALTER TYPE "FieldType_new" RENAME TO "FieldType";
DROP TYPE "public"."FieldType_old";
COMMIT;

-- DropIndex
DROP INDEX "notifications_booking_deleted_idx";

-- DropIndex
DROP INDEX "notifications_orphan_detected_at_idx";

-- AlterTable
ALTER TABLE "notifications" DROP COLUMN "booking_deleted",
DROP COLUMN "orphan_detected_at";

-- AlterTable
ALTER TABLE "surveys" DROP COLUMN "completed_at",
ALTER COLUMN "type" DROP NOT NULL;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "failed_login_attempts",
DROP COLUMN "locked_until";

-- CreateTable
CREATE TABLE "v2_tree_versions" (
    "id" UUID NOT NULL,
    "tree_type" VARCHAR(50) NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "tree_data" JSONB NOT NULL,
    "size_bytes" INTEGER NOT NULL,
    "checksum" VARCHAR(64),
    "published_by" UUID NOT NULL,
    "published_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "v2_tree_versions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "v2_tree_versions_tree_type_idx" ON "v2_tree_versions"("tree_type");

-- CreateIndex
CREATE INDEX "v2_tree_versions_published_at_idx" ON "v2_tree_versions"("published_at");

-- CreateIndex
CREATE UNIQUE INDEX "v2_tree_versions_tree_type_version_key" ON "v2_tree_versions"("tree_type", "version");

-- AddForeignKey
ALTER TABLE "v2_tree_versions" ADD CONSTRAINT "v2_tree_versions_published_by_fkey" FOREIGN KEY ("published_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- RenameIndex
ALTER INDEX "idx_sections_section_type_key" RENAME TO "sections_section_type_key_idx";
