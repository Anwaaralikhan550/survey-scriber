-- P1-5: Survey Field Alignment
-- Add SurveyType enum and new survey fields

-- CreateEnum
CREATE TYPE "SurveyType" AS ENUM ('LEVEL_2', 'LEVEL_3', 'VALUATION', 'SNAGGING', 'REINSPECTION', 'OTHER');

-- AlterTable: Add new fields to surveys
ALTER TABLE "surveys" ADD COLUMN "type" "SurveyType" DEFAULT 'LEVEL_2';
ALTER TABLE "surveys" ADD COLUMN "job_ref" VARCHAR(100);
ALTER TABLE "surveys" ADD COLUMN "client_name" VARCHAR(255);
ALTER TABLE "surveys" ADD COLUMN "parent_survey_id" UUID;

-- AlterTable: Add updatedAt to sections (for sync support)
ALTER TABLE "sections" ADD COLUMN "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- AlterTable: Add updatedAt to answers (for sync support)
ALTER TABLE "answers" ADD COLUMN "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- CreateIndex: Index for survey type filtering
CREATE INDEX "surveys_type_idx" ON "surveys"("type");

-- CreateIndex: Index for parent survey (reinspection lookup)
CREATE INDEX "surveys_parent_survey_id_idx" ON "surveys"("parent_survey_id");

-- AddForeignKey: Self-relation for reinspections
ALTER TABLE "surveys" ADD CONSTRAINT "surveys_parent_survey_id_fkey" FOREIGN KEY ("parent_survey_id") REFERENCES "surveys"("id") ON DELETE SET NULL ON UPDATE CASCADE;
