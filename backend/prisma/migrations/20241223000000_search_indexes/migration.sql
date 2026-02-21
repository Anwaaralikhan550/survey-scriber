-- Search optimization indexes for surveys table
-- These indexes improve text search performance on title, client_name, property_address, and job_ref

-- Enable pg_trgm extension for better text search (optional, use if available)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Standard B-tree indexes for exact and prefix matching
CREATE INDEX IF NOT EXISTS "surveys_title_idx" ON "surveys"("title");
CREATE INDEX IF NOT EXISTS "surveys_client_name_idx" ON "surveys"("client_name");
CREATE INDEX IF NOT EXISTS "surveys_property_address_idx" ON "surveys"("property_address");
CREATE INDEX IF NOT EXISTS "surveys_job_ref_idx" ON "surveys"("job_ref");

-- Composite index for common search + filter combinations
CREATE INDEX IF NOT EXISTS "surveys_search_composite_idx" ON "surveys"("deleted_at", "status", "type", "updated_at" DESC);
