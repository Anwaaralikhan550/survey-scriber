-- Migration: Add unique constraint to prevent double-booking race conditions
-- Issue: Concurrent booking requests could create overlapping bookings
-- Fix: Database-level unique constraint on (surveyorId, date, startTime)
-- Type: Additive, idempotent, production-safe

-- Create unique constraint to prevent same surveyor having two bookings
-- starting at the exact same time on the same date.
-- This is a safety net for the application-level overlap check.
CREATE UNIQUE INDEX IF NOT EXISTS "bookings_no_double_booking"
ON "bookings"("surveyor_id", "date", "start_time");
