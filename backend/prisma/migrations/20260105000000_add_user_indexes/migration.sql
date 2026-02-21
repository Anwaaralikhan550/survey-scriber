-- Migration: Add missing user table indexes (audit finding)
-- Issue: User role and isActive indexes missing from migrations
-- Impact: User list filtering by role/status performs full table scans
-- Type: Additive, non-destructive, production-safe

-- Add index for user role filtering (used in admin user management)
CREATE INDEX IF NOT EXISTS "users_role_idx" ON "users"("role");

-- Add index for user active status filtering (used in user list queries)
CREATE INDEX IF NOT EXISTS "users_is_active_idx" ON "users"("is_active");
