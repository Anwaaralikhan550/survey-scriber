-- Phase 2.1: Client Portal
-- Creates Client entity and magic link authentication tables
-- Adds clientId FK to bookings and surveys (backward compatible)

-- ============================================
-- Create Client Table
-- ============================================
CREATE TABLE "clients" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "email" VARCHAR(255) NOT NULL,
    "first_name" VARCHAR(100),
    "last_name" VARCHAR(100),
    "phone" VARCHAR(50),
    "company" VARCHAR(255),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "clients_pkey" PRIMARY KEY ("id")
);

-- Unique constraint on email
CREATE UNIQUE INDEX "clients_email_key" ON "clients"("email");

-- Performance indexes
CREATE INDEX "clients_email_idx" ON "clients"("email");
CREATE INDEX "clients_is_active_idx" ON "clients"("is_active");

-- ============================================
-- Create Client Magic Link Table
-- ============================================
CREATE TABLE "client_magic_links" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_id" UUID NOT NULL,
    "token_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "used_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "client_magic_links_pkey" PRIMARY KEY ("id")
);

-- Indexes for magic link lookups
CREATE INDEX "client_magic_links_token_hash_idx" ON "client_magic_links"("token_hash");
CREATE INDEX "client_magic_links_client_id_idx" ON "client_magic_links"("client_id");
CREATE INDEX "client_magic_links_expires_at_idx" ON "client_magic_links"("expires_at");

-- Foreign key to clients
ALTER TABLE "client_magic_links" ADD CONSTRAINT "client_magic_links_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================
-- Create Client Refresh Token Table
-- ============================================
CREATE TABLE "client_refresh_tokens" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_id" UUID NOT NULL,
    "token_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "client_refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- Indexes for refresh token lookups
CREATE INDEX "client_refresh_tokens_client_id_idx" ON "client_refresh_tokens"("client_id");
CREATE INDEX "client_refresh_tokens_token_hash_idx" ON "client_refresh_tokens"("token_hash");

-- Foreign key to clients
ALTER TABLE "client_refresh_tokens" ADD CONSTRAINT "client_refresh_tokens_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================
-- Add clientId to Bookings (backward compatible)
-- ============================================
ALTER TABLE "bookings" ADD COLUMN "client_id" UUID;

-- Index for client lookups
CREATE INDEX "bookings_client_id_idx" ON "bookings"("client_id");

-- Foreign key to clients (SetNull on delete)
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================
-- Add clientId to Surveys (backward compatible)
-- ============================================
ALTER TABLE "surveys" ADD COLUMN "client_id" UUID;

-- Index for client lookups
CREATE INDEX "surveys_client_id_idx" ON "surveys"("client_id");

-- Foreign key to clients (SetNull on delete)
ALTER TABLE "surveys" ADD CONSTRAINT "surveys_client_id_fkey"
    FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ============================================
-- Trigger to update updated_at on clients
-- ============================================
CREATE OR REPLACE FUNCTION update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clients_updated_at_trigger
    BEFORE UPDATE ON "clients"
    FOR EACH ROW
    EXECUTE FUNCTION update_clients_updated_at();
