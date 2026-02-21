-- DropForeignKey
ALTER TABLE "bookings" DROP CONSTRAINT "bookings_created_by_id_fkey";

-- CreateIndex
CREATE INDEX "config_versions_updated_at_idx" ON "config_versions"("updated_at");

-- CreateIndex
CREATE UNIQUE INDEX "webhooks_url_key" ON "webhooks"("url");

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
