-- AI Module Schema Migration
-- Adds tables for AI response caching, prompt templates, and usage tracking

-- AI Feature types enum
CREATE TYPE "AiFeatureType" AS ENUM ('REPORT', 'PHOTO_TAGS', 'RECOMMENDATIONS', 'RISK_SUMMARY', 'CONSISTENCY_CHECK');

-- AI Response Cache Table
-- Stores cached AI responses to reduce API costs and latency
CREATE TABLE "ai_response_cache" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "cache_key" VARCHAR(255) NOT NULL,
    "feature_type" "AiFeatureType" NOT NULL,
    "survey_id" UUID,
    "prompt_version" VARCHAR(20) NOT NULL,
    "input_hash" VARCHAR(64) NOT NULL,
    "response" JSONB NOT NULL,
    "input_tokens" INTEGER NOT NULL DEFAULT 0,
    "output_tokens" INTEGER NOT NULL DEFAULT 0,
    "latency_ms" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ai_response_cache_pkey" PRIMARY KEY ("id")
);

-- AI Prompt Templates Table
-- Stores versioned prompt templates for different AI features
CREATE TABLE "ai_prompt_templates" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "feature_type" "AiFeatureType" NOT NULL,
    "version" VARCHAR(20) NOT NULL,
    "system_prompt" TEXT NOT NULL,
    "user_prompt_template" TEXT NOT NULL,
    "output_schema" JSONB,
    "model" VARCHAR(50) NOT NULL DEFAULT 'gemini-1.5-pro',
    "max_tokens" INTEGER NOT NULL DEFAULT 4000,
    "temperature" DECIMAL(3,2) NOT NULL DEFAULT 0.3,
    "is_active" BOOLEAN NOT NULL DEFAULT false,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ai_prompt_templates_pkey" PRIMARY KEY ("id")
);

-- AI Usage Tracking Table
-- Tracks AI usage per user/organization for quota management
CREATE TABLE "ai_usage_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "organization" VARCHAR(255),
    "feature_type" "AiFeatureType" NOT NULL,
    "survey_id" UUID,
    "prompt_version" VARCHAR(20) NOT NULL,
    "input_tokens" INTEGER NOT NULL DEFAULT 0,
    "output_tokens" INTEGER NOT NULL DEFAULT 0,
    "latency_ms" INTEGER NOT NULL DEFAULT 0,
    "cache_hit" BOOLEAN NOT NULL DEFAULT false,
    "status" VARCHAR(20) NOT NULL,
    "error_message" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_usage_logs_pkey" PRIMARY KEY ("id")
);

-- AI Daily Quota Table
-- Tracks daily token usage per organization
CREATE TABLE "ai_daily_quotas" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "organization" VARCHAR(255) NOT NULL,
    "date" DATE NOT NULL,
    "tokens_used" INTEGER NOT NULL DEFAULT 0,
    "requests_count" INTEGER NOT NULL DEFAULT 0,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ai_daily_quotas_pkey" PRIMARY KEY ("id")
);

-- Indexes for performance
CREATE UNIQUE INDEX "ai_response_cache_cache_key_key" ON "ai_response_cache"("cache_key");
CREATE INDEX "ai_response_cache_feature_type_idx" ON "ai_response_cache"("feature_type");
CREATE INDEX "ai_response_cache_survey_id_idx" ON "ai_response_cache"("survey_id");
CREATE INDEX "ai_response_cache_expires_at_idx" ON "ai_response_cache"("expires_at");

CREATE UNIQUE INDEX "ai_prompt_templates_feature_version_key" ON "ai_prompt_templates"("feature_type", "version");
CREATE INDEX "ai_prompt_templates_is_active_idx" ON "ai_prompt_templates"("is_active");

CREATE INDEX "ai_usage_logs_user_id_idx" ON "ai_usage_logs"("user_id");
CREATE INDEX "ai_usage_logs_organization_idx" ON "ai_usage_logs"("organization");
CREATE INDEX "ai_usage_logs_feature_type_idx" ON "ai_usage_logs"("feature_type");
CREATE INDEX "ai_usage_logs_created_at_idx" ON "ai_usage_logs"("created_at");

CREATE UNIQUE INDEX "ai_daily_quotas_org_date_key" ON "ai_daily_quotas"("organization", "date");
CREATE INDEX "ai_daily_quotas_date_idx" ON "ai_daily_quotas"("date");

-- Foreign key constraint for user_id
ALTER TABLE "ai_usage_logs" ADD CONSTRAINT "ai_usage_logs_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
