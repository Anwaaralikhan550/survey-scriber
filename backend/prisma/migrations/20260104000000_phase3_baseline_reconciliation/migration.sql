-- Phase 3.x Baseline Reconciliation Migration
-- This migration captures Phase 3.x schema objects that were applied via db push
-- It is safe to mark as applied on existing databases where these objects already exist
-- On fresh databases, this migration will create all Phase 3.x objects

-- ============================================
-- PART 1: Additional Columns on Existing Tables
-- (Applied via db push, now captured in migration history)
-- ============================================

-- Add password reset columns to users table
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "reset_password_token" VARCHAR(255);
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "reset_password_expires_at" TIMESTAMP(3);

-- Add report_pdf_path to surveys table
ALTER TABLE "surveys" ADD COLUMN IF NOT EXISTS "report_pdf_path" VARCHAR(500);

-- Add extended columns to notifications table
ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "invoice_id" UUID;
ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "booking_request_id" UUID;
ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "booking_change_request_id" UUID;

-- Add invoice_id to notification_email_logs table
ALTER TABLE "notification_email_logs" ADD COLUMN IF NOT EXISTS "invoice_id" UUID;

-- Create indexes for new notification columns
CREATE INDEX IF NOT EXISTS "notifications_invoice_id_idx" ON "notifications"("invoice_id");
CREATE INDEX IF NOT EXISTS "notifications_booking_request_id_idx" ON "notifications"("booking_request_id");
CREATE INDEX IF NOT EXISTS "notifications_booking_change_request_id_idx" ON "notifications"("booking_change_request_id");
CREATE INDEX IF NOT EXISTS "notification_email_logs_invoice_id_idx" ON "notification_email_logs"("invoice_id");

-- ============================================
-- PART 2: Extended NotificationType Enum Values
-- (Phase 3.1 and 3.2 notification types)
-- ============================================

-- Add booking request notification types
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'BOOKING_REQUEST_CREATED'
          AND enumtypid = (
              SELECT t.oid
              FROM pg_type t
              JOIN pg_namespace n ON n.oid = t.typnamespace
              WHERE t.typname = 'NotificationType'
                AND n.nspname = current_schema()
              LIMIT 1
          )
    ) THEN
        ALTER TYPE "NotificationType" ADD VALUE 'BOOKING_REQUEST_CREATED';
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'BOOKING_REQUEST_APPROVED'
          AND enumtypid = (
              SELECT t.oid
              FROM pg_type t
              JOIN pg_namespace n ON n.oid = t.typnamespace
              WHERE t.typname = 'NotificationType'
                AND n.nspname = current_schema()
              LIMIT 1
          )
    ) THEN
        ALTER TYPE "NotificationType" ADD VALUE 'BOOKING_REQUEST_APPROVED';
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'BOOKING_REQUEST_REJECTED'
          AND enumtypid = (
              SELECT t.oid
              FROM pg_type t
              JOIN pg_namespace n ON n.oid = t.typnamespace
              WHERE t.typname = 'NotificationType'
                AND n.nspname = current_schema()
              LIMIT 1
          )
    ) THEN
        ALTER TYPE "NotificationType" ADD VALUE 'BOOKING_REQUEST_REJECTED';
    END IF;
END$$;

-- Add booking change request notification types
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'BOOKING_CHANGE_REQUEST_CREATED'
          AND enumtypid = (
              SELECT t.oid
              FROM pg_type t
              JOIN pg_namespace n ON n.oid = t.typnamespace
              WHERE t.typname = 'NotificationType'
                AND n.nspname = current_schema()
              LIMIT 1
          )
    ) THEN
        ALTER TYPE "NotificationType" ADD VALUE 'BOOKING_CHANGE_REQUEST_CREATED';
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'BOOKING_CHANGE_REQUEST_APPROVED'
          AND enumtypid = (
              SELECT t.oid
              FROM pg_type t
              JOIN pg_namespace n ON n.oid = t.typnamespace
              WHERE t.typname = 'NotificationType'
                AND n.nspname = current_schema()
              LIMIT 1
          )
    ) THEN
        ALTER TYPE "NotificationType" ADD VALUE 'BOOKING_CHANGE_REQUEST_APPROVED';
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_enum
        WHERE enumlabel = 'BOOKING_CHANGE_REQUEST_REJECTED'
          AND enumtypid = (
              SELECT t.oid
              FROM pg_type t
              JOIN pg_namespace n ON n.oid = t.typnamespace
              WHERE t.typname = 'NotificationType'
                AND n.nspname = current_schema()
              LIMIT 1
          )
    ) THEN
        ALTER TYPE "NotificationType" ADD VALUE 'BOOKING_CHANGE_REQUEST_REJECTED';
    END IF;
END$$;

-- ============================================
-- PART 3: Phase 3.1 - Client Self-Service Booking Requests
-- ============================================

-- CreateEnum: BookingRequestStatus
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'BookingRequestStatus'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "BookingRequestStatus" AS ENUM ('REQUESTED', 'APPROVED', 'REJECTED');
    END IF;
END$$;

-- CreateTable: booking_requests
CREATE TABLE IF NOT EXISTS "booking_requests" (
    "id" UUID NOT NULL,
    "client_id" UUID NOT NULL,
    "property_address" VARCHAR(500) NOT NULL,
    "preferred_start_date" DATE NOT NULL,
    "preferred_end_date" DATE NOT NULL,
    "notes" TEXT,
    "status" "BookingRequestStatus" NOT NULL DEFAULT 'REQUESTED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_at" TIMESTAMP(3),
    "reviewed_by_id" UUID,

    CONSTRAINT "booking_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndexes for booking_requests
CREATE INDEX IF NOT EXISTS "booking_requests_client_id_idx" ON "booking_requests"("client_id");
CREATE INDEX IF NOT EXISTS "booking_requests_status_idx" ON "booking_requests"("status");
CREATE INDEX IF NOT EXISTS "booking_requests_created_at_idx" ON "booking_requests"("created_at");
CREATE INDEX IF NOT EXISTS "booking_requests_reviewed_by_id_idx" ON "booking_requests"("reviewed_by_id");

-- AddForeignKeys for booking_requests (with IF NOT EXISTS check)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class r ON r.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        WHERE c.conname = 'booking_requests_client_id_fkey'
          AND n.nspname = current_schema()
    ) THEN
        ALTER TABLE "booking_requests" ADD CONSTRAINT "booking_requests_client_id_fkey"
            FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class r ON r.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        WHERE c.conname = 'booking_requests_reviewed_by_id_fkey'
          AND n.nspname = current_schema()
    ) THEN
        ALTER TABLE "booking_requests" ADD CONSTRAINT "booking_requests_reviewed_by_id_fkey"
            FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END$$;

-- ============================================
-- PART 4: Phase 3.2 - Client Reschedule & Cancel Requests
-- ============================================

-- CreateEnum: BookingChangeRequestType
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'BookingChangeRequestType'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "BookingChangeRequestType" AS ENUM ('RESCHEDULE', 'CANCEL');
    END IF;
END$$;

-- CreateEnum: BookingChangeRequestStatus
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'BookingChangeRequestStatus'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "BookingChangeRequestStatus" AS ENUM ('REQUESTED', 'APPROVED', 'REJECTED');
    END IF;
END$$;

-- CreateTable: booking_change_requests
CREATE TABLE IF NOT EXISTS "booking_change_requests" (
    "id" UUID NOT NULL,
    "booking_id" UUID NOT NULL,
    "client_id" UUID NOT NULL,
    "type" "BookingChangeRequestType" NOT NULL,
    "proposed_date" DATE,
    "proposed_start_time" VARCHAR(5),
    "proposed_end_time" VARCHAR(5),
    "reason" TEXT,
    "status" "BookingChangeRequestStatus" NOT NULL DEFAULT 'REQUESTED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_at" TIMESTAMP(3),
    "reviewed_by_id" UUID,

    CONSTRAINT "booking_change_requests_pkey" PRIMARY KEY ("id")
);

-- CreateIndexes for booking_change_requests
CREATE INDEX IF NOT EXISTS "booking_change_requests_booking_id_idx" ON "booking_change_requests"("booking_id");
CREATE INDEX IF NOT EXISTS "booking_change_requests_client_id_idx" ON "booking_change_requests"("client_id");
CREATE INDEX IF NOT EXISTS "booking_change_requests_type_idx" ON "booking_change_requests"("type");
CREATE INDEX IF NOT EXISTS "booking_change_requests_status_idx" ON "booking_change_requests"("status");
CREATE INDEX IF NOT EXISTS "booking_change_requests_created_at_idx" ON "booking_change_requests"("created_at");
CREATE INDEX IF NOT EXISTS "booking_change_requests_reviewed_by_id_idx" ON "booking_change_requests"("reviewed_by_id");

-- AddForeignKeys for booking_change_requests
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class r ON r.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        WHERE c.conname = 'booking_change_requests_booking_id_fkey'
          AND n.nspname = current_schema()
    ) THEN
        ALTER TABLE "booking_change_requests" ADD CONSTRAINT "booking_change_requests_booking_id_fkey"
            FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class r ON r.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        WHERE c.conname = 'booking_change_requests_client_id_fkey'
          AND n.nspname = current_schema()
    ) THEN
        ALTER TABLE "booking_change_requests" ADD CONSTRAINT "booking_change_requests_client_id_fkey"
            FOREIGN KEY ("client_id") REFERENCES "clients"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class r ON r.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        WHERE c.conname = 'booking_change_requests_reviewed_by_id_fkey'
          AND n.nspname = current_schema()
    ) THEN
        ALTER TABLE "booking_change_requests" ADD CONSTRAINT "booking_change_requests_reviewed_by_id_fkey"
            FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END$$;

-- ============================================
-- PART 5: Phase 3.3 - Audit Logging System
-- ============================================

-- CreateEnum: ActorType
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'ActorType'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "ActorType" AS ENUM ('STAFF', 'CLIENT', 'SYSTEM');
    END IF;
END$$;

-- CreateEnum: AuditEntityType
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'AuditEntityType'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "AuditEntityType" AS ENUM ('BOOKING', 'BOOKING_REQUEST', 'BOOKING_CHANGE_REQUEST', 'INVOICE', 'SURVEY', 'REPORT_PDF', 'AUTH', 'WEBHOOK');
    END IF;
END$$;

-- CreateTable: audit_logs
CREATE TABLE IF NOT EXISTS "audit_logs" (
    "id" UUID NOT NULL,
    "actor_type" "ActorType" NOT NULL,
    "actor_id" UUID,
    "action" VARCHAR(100) NOT NULL,
    "entity_type" "AuditEntityType" NOT NULL,
    "entity_id" UUID,
    "metadata" JSONB,
    "ip" VARCHAR(45),
    "user_agent" VARCHAR(500),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndexes for audit_logs
CREATE INDEX IF NOT EXISTS "audit_logs_actor_type_actor_id_idx" ON "audit_logs"("actor_type", "actor_id");
CREATE INDEX IF NOT EXISTS "audit_logs_entity_type_entity_id_idx" ON "audit_logs"("entity_type", "entity_id");
CREATE INDEX IF NOT EXISTS "audit_logs_action_idx" ON "audit_logs"("action");
CREATE INDEX IF NOT EXISTS "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- ============================================
-- PART 6: Phase 3.4.1 - Webhooks System
-- ============================================

-- CreateEnum: WebhookEventType
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'WebhookEventType'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "WebhookEventType" AS ENUM ('BOOKING_CREATED', 'BOOKING_UPDATED', 'BOOKING_CANCELLED', 'BOOKING_REQUEST_CREATED', 'BOOKING_REQUEST_APPROVED', 'BOOKING_CHANGE_APPROVED', 'INVOICE_ISSUED', 'INVOICE_PAID', 'REPORT_APPROVED');
    END IF;
END$$;

-- CreateEnum: WebhookDeliveryStatus
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'WebhookDeliveryStatus'
          AND n.nspname = current_schema()
    ) THEN
        CREATE TYPE "WebhookDeliveryStatus" AS ENUM ('SUCCESS', 'FAILED');
    END IF;
END$$;

-- CreateTable: webhooks
CREATE TABLE IF NOT EXISTS "webhooks" (
    "id" UUID NOT NULL,
    "url" VARCHAR(2000) NOT NULL,
    "secret_hash" VARCHAR(255) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "events" "WebhookEventType"[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "webhooks_pkey" PRIMARY KEY ("id")
);

-- CreateIndexes for webhooks
CREATE INDEX IF NOT EXISTS "webhooks_is_active_idx" ON "webhooks"("is_active");
CREATE INDEX IF NOT EXISTS "webhooks_created_at_idx" ON "webhooks"("created_at");

-- CreateTable: webhook_deliveries
CREATE TABLE IF NOT EXISTS "webhook_deliveries" (
    "id" UUID NOT NULL,
    "webhook_id" UUID NOT NULL,
    "event" "WebhookEventType" NOT NULL,
    "event_id" VARCHAR(100),
    "payload" JSONB NOT NULL,
    "status" "WebhookDeliveryStatus" NOT NULL,
    "response_status_code" INTEGER,
    "response_body" TEXT,
    "attempts" INTEGER NOT NULL DEFAULT 1,
    "last_attempt_at" TIMESTAMP(3),
    "next_attempt_at" TIMESTAMP(3),
    "last_error" VARCHAR(500),
    "is_test" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "webhook_deliveries_pkey" PRIMARY KEY ("id")
);

-- CreateIndexes for webhook_deliveries
CREATE INDEX IF NOT EXISTS "webhook_deliveries_webhook_id_idx" ON "webhook_deliveries"("webhook_id");
CREATE INDEX IF NOT EXISTS "webhook_deliveries_event_idx" ON "webhook_deliveries"("event");
CREATE INDEX IF NOT EXISTS "webhook_deliveries_status_idx" ON "webhook_deliveries"("status");
CREATE INDEX IF NOT EXISTS "webhook_deliveries_created_at_idx" ON "webhook_deliveries"("created_at");
CREATE INDEX IF NOT EXISTS "webhook_deliveries_next_attempt_at_idx" ON "webhook_deliveries"("next_attempt_at");

-- AddForeignKey for webhook_deliveries
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class r ON r.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = r.relnamespace
        WHERE c.conname = 'webhook_deliveries_webhook_id_fkey'
          AND n.nspname = current_schema()
    ) THEN
        ALTER TABLE "webhook_deliveries" ADD CONSTRAINT "webhook_deliveries_webhook_id_fkey"
            FOREIGN KEY ("webhook_id") REFERENCES "webhooks"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END$$;
