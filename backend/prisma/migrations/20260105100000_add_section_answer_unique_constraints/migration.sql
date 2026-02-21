-- Migration: Add missing UNIQUE constraints (audit finding)
-- Issue: Section(surveyId, order) and Answer(sectionId, questionKey) constraints
--        are defined in schema.prisma but were never created in migrations
-- Impact: Potential duplicate section orders within surveys and duplicate answers
-- Type: Additive, idempotent, production-safe

-- HARDENING: Section unique constraint
-- Prevents duplicate section orders within the same survey
-- Matches schema.prisma: @@unique([surveyId, order])
CREATE UNIQUE INDEX IF NOT EXISTS "sections_survey_id_order_key" ON "sections"("survey_id", "order");

-- HARDENING: Answer unique constraint
-- Prevents duplicate question answers within the same section
-- Matches schema.prisma: @@unique([sectionId, questionKey])
CREATE UNIQUE INDEX IF NOT EXISTS "answers_section_id_question_key_key" ON "answers"("section_id", "question_key");
