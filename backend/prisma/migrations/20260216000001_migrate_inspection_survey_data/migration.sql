-- Migrate existing surveys: LEVEL_2, LEVEL_3, SNAGGING → INSPECTION
-- (All are inspection-type surveys in the unified V2 model)
UPDATE "surveys" SET type = 'INSPECTION'::"SurveyType"
WHERE type IN ('LEVEL_2'::"SurveyType", 'LEVEL_3'::"SurveyType", 'SNAGGING'::"SurveyType");

-- Update section_type_definitions: add INSPECTION to survey_types arrays
-- that currently contain LEVEL_2/LEVEL_3/SNAGGING
UPDATE "section_type_definitions"
SET "survey_types" = array_append("survey_types", 'INSPECTION')
WHERE "survey_types" && ARRAY['LEVEL_2', 'LEVEL_3', 'SNAGGING']
  AND NOT ('INSPECTION' = ANY("survey_types"));

-- Change column default from LEVEL_2 to INSPECTION
ALTER TABLE "surveys" ALTER COLUMN "type" SET DEFAULT 'INSPECTION'::"SurveyType";
