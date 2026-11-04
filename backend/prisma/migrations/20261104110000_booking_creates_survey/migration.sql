-- A booking now owns the inspection the surveyor works in.
ALTER TABLE "surveys" ADD COLUMN "inspection_date" DATE;
ALTER TABLE "bookings" ADD COLUMN "survey_id" UUID;

CREATE UNIQUE INDEX "bookings_survey_id_key" ON "bookings"("survey_id");

ALTER TABLE "bookings" ADD CONSTRAINT "bookings_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "surveys"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Bookings made before this change get their inspection too. Cancelled ones do not.
WITH new_surveys AS (
    SELECT
        b."id" AS booking_id,
        gen_random_uuid() AS survey_id,
        b."survey_type" = 'valuation' AS is_valuation,
        COALESCE(
            NULLIF(BTRIM(b."job_ref"), ''),
            NULLIF(BTRIM(b."client_name"), ''),
            NULLIF(BTRIM(b."postcode"), ''),
            TO_CHAR(b."date", 'FMDD Mon YYYY')
        ) AS title_end,
        COALESCE(b."property_address", '') AS address,
        NULLIF(BTRIM(b."job_ref"), '') AS job_ref,
        NULLIF(BTRIM(b."client_name"), '') AS client_name,
        b."surveyor_id" AS user_id,
        b."date" AS inspection_date
    FROM "bookings" b
    WHERE b."status" <> 'CANCELLED' AND b."survey_id" IS NULL
),
inserted AS (
    INSERT INTO "surveys" ("id", "title", "property_address", "status", "type", "job_ref", "client_name", "user_id", "inspection_date", "created_at", "updated_at")
    SELECT
        survey_id,
        LEFT((CASE WHEN is_valuation THEN 'Valuation - ' ELSE 'Inspection - ' END) || title_end, 255),
        address,
        'DRAFT'::"SurveyStatus",
        (CASE WHEN is_valuation THEN 'VALUATION' ELSE 'INSPECTION' END)::"SurveyType",
        job_ref,
        client_name,
        user_id,
        inspection_date,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    FROM new_surveys
    RETURNING "id"
)
UPDATE "bookings" b
SET "survey_id" = n.survey_id
FROM new_surveys n
WHERE b."id" = n.booking_id
  AND n.survey_id IN (SELECT "id" FROM inserted);
