-- Migration: Add orphan tracking fields to notifications table
-- Purpose: Track notifications that reference deleted bookings to maintain referential integrity

-- Add bookingDeleted column with default false
ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "booking_deleted" BOOLEAN NOT NULL DEFAULT false;

-- Add orphanDetectedAt column (nullable)
ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "orphan_detected_at" TIMESTAMP(3);

-- Add index on bookingDeleted for efficient filtering
CREATE INDEX IF NOT EXISTS "notifications_booking_deleted_idx" ON "notifications"("booking_deleted");

-- Add index on orphanDetectedAt for cleanup job queries
CREATE INDEX IF NOT EXISTS "notifications_orphan_detected_at_idx" ON "notifications"("orphan_detected_at");

-- One-time data migration: Mark existing orphaned notifications
-- This identifies notifications that reference non-existent bookings
UPDATE "notifications" n
SET
  "booking_deleted" = true,
  "orphan_detected_at" = NOW()
WHERE
  n."booking_id" IS NOT NULL
  AND n."booking_deleted" = false
  AND NOT EXISTS (
    SELECT 1 FROM "bookings" b WHERE b."id" = n."booking_id"
  );
