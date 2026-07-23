-- Failed-attempt counters must expire with their observation window.
-- Without this field, a historical failed attempt count could re-lock an
-- otherwise valid account after an earlier lock had already expired.
ALTER TABLE "users"
ADD COLUMN "failed_login_window_started_at" TIMESTAMP(3);

-- Existing counters were recorded without a bounded window. Reset them so
-- the next failed login is treated as the first attempt in a fresh window.
UPDATE "users"
SET
  "failed_login_attempts" = 0,
  "failed_login_window_started_at" = NULL,
  "locked_until" = NULL
WHERE
  "failed_login_attempts" <> 0
  OR "locked_until" IS NOT NULL;

COMMENT ON COLUMN "users"."failed_login_window_started_at"
IS 'Start of the bounded failed-login observation window; reset after expiry or successful authentication.';
