-- D1 FIX: Make survey.type non-nullable
-- This migration safely backfills NULL values before adding NOT NULL constraint

-- Step 1: Backfill NULL values with default 'LEVEL_2'
-- This is safe because LEVEL_2 is the intended default for all surveys
UPDATE surveys
SET type = 'LEVEL_2'::"SurveyType"
WHERE type IS NULL;

-- Step 2: Add NOT NULL constraint
-- This is safe because all NULLs were backfilled above
ALTER TABLE surveys
ALTER COLUMN type SET NOT NULL;

-- Verification: Ensure no NULLs exist (will fail if any remain)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM surveys WHERE type IS NULL) THEN
    RAISE EXCEPTION 'D1 Migration failed: NULL values still exist in surveys.type';
  END IF;
END $$;
