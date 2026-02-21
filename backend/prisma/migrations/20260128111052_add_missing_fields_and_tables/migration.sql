-- DropIndex
DROP INDEX "surveys_search_composite_idx";

-- AlterTable
ALTER TABLE "ai_daily_quotas" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "ai_prompt_templates" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "model" SET DEFAULT 'DYNAMIC_FROM_CONFIG';

-- AlterTable
ALTER TABLE "ai_response_cache" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "ai_usage_logs" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "answers" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "booking_change_requests" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "booking_requests" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "client_magic_links" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "client_refresh_tokens" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "clients" ALTER COLUMN "id" DROP DEFAULT,
ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "config_versions" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "field_definitions" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "media" ALTER COLUMN "storage_path" DROP DEFAULT,
ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "notifications" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "phrase_categories" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "phrases" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "section_type_definitions" ALTER COLUMN "id" DROP DEFAULT;

-- AlterTable
ALTER TABLE "sections" ALTER COLUMN "updated_at" DROP DEFAULT;

-- AlterTable
ALTER TABLE "webhook_deliveries" ALTER COLUMN "updated_at" DROP DEFAULT;

-- CreateIndex
CREATE INDEX "invoices_invoice_number_idx" ON "invoices"("invoice_number");

-- RenameIndex
ALTER INDEX "ai_daily_quotas_org_date_key" RENAME TO "ai_daily_quotas_organization_date_key";

-- RenameIndex
ALTER INDEX "ai_prompt_templates_feature_version_key" RENAME TO "ai_prompt_templates_feature_type_version_key";

-- RenameIndex
ALTER INDEX "bookings_no_double_booking" RENAME TO "bookings_surveyor_id_date_start_time_key";
