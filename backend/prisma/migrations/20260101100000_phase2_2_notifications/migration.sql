-- Phase 2.2: Notifications System
-- Creates notifications tables for in-app and email notifications

-- CreateEnum: NotificationType
CREATE TYPE "NotificationType" AS ENUM ('BOOKING_CREATED', 'BOOKING_CONFIRMED', 'BOOKING_CANCELLED', 'BOOKING_COMPLETED');

-- CreateEnum: RecipientType
CREATE TYPE "RecipientType" AS ENUM ('CLIENT', 'USER');

-- CreateTable: notifications
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "type" "NotificationType" NOT NULL,
    "recipient_type" "RecipientType" NOT NULL,
    "recipient_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "body" TEXT NOT NULL,
    "booking_id" UUID,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "read_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable: notification_email_logs
CREATE TABLE "notification_email_logs" (
    "id" UUID NOT NULL,
    "notification_type" "NotificationType" NOT NULL,
    "recipient_email" VARCHAR(255) NOT NULL,
    "recipient_type" "RecipientType" NOT NULL,
    "recipient_id" UUID,
    "booking_id" UUID,
    "subject" VARCHAR(255) NOT NULL,
    "sent_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" VARCHAR(50) NOT NULL,
    "error_message" TEXT,

    CONSTRAINT "notification_email_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex: notifications indexes
CREATE INDEX "notifications_recipient_type_recipient_id_idx" ON "notifications"("recipient_type", "recipient_id");
CREATE INDEX "notifications_recipient_id_is_read_idx" ON "notifications"("recipient_id", "is_read");
CREATE INDEX "notifications_booking_id_idx" ON "notifications"("booking_id");
CREATE INDEX "notifications_created_at_idx" ON "notifications"("created_at");

-- CreateIndex: notification_email_logs indexes
CREATE INDEX "notification_email_logs_recipient_email_idx" ON "notification_email_logs"("recipient_email");
CREATE INDEX "notification_email_logs_booking_id_idx" ON "notification_email_logs"("booking_id");
CREATE INDEX "notification_email_logs_sent_at_idx" ON "notification_email_logs"("sent_at");
CREATE INDEX "notification_email_logs_status_idx" ON "notification_email_logs"("status");
