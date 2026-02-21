-- D2 FIX: Add updatedAt to mutable models for consistent audit trail
-- These models have fields that are updated after creation, so they need updatedAt

-- Add updatedAt to Notification (isRead, readAt are mutable)
ALTER TABLE notifications
ADD COLUMN updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Add updatedAt to BookingRequest (status, reviewedAt are mutable)
ALTER TABLE booking_requests
ADD COLUMN updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Add updatedAt to BookingChangeRequest (status, reviewedAt are mutable)
ALTER TABLE booking_change_requests
ADD COLUMN updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Add updatedAt to WebhookDelivery (attempts, lastAttemptAt, nextAttemptAt are mutable during retries)
ALTER TABLE webhook_deliveries
ADD COLUMN updated_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Create triggers to auto-update updatedAt on modification
-- Note: Prisma's @updatedAt will handle this in application code, but triggers provide database-level safety

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_booking_requests_updated_at
    BEFORE UPDATE ON booking_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_booking_change_requests_updated_at
    BEFORE UPDATE ON booking_change_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_webhook_deliveries_updated_at
    BEFORE UPDATE ON webhook_deliveries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
