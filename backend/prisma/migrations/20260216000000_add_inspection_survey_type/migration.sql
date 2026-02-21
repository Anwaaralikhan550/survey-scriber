-- Add INSPECTION to the SurveyType enum
-- NOTE: New enum values cannot be used in the same transaction in PostgreSQL.
-- Data migration happens in the next migration (20260216000001).
ALTER TYPE "SurveyType" ADD VALUE IF NOT EXISTS 'INSPECTION';
