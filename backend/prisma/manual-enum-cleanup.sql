-- Manual cleanup for conflicting enums in public schema.
-- Run this only on a fresh/dev database where dropping dependent objects is acceptable.

DO $$
DECLARE
  enum_name text;
BEGIN
  FOREACH enum_name IN ARRAY ARRAY[
    'NotificationType',
    'BookingRequestStatus',
    'BookingChangeRequestType',
    'BookingChangeRequestStatus',
    'ActorType',
    'AuditEntityType',
    'WebhookEventType',
    'WebhookDeliveryStatus',
    'FieldType'
  ]
  LOOP
    EXECUTE format('DROP TYPE IF EXISTS public.%I CASCADE', enum_name);
  END LOOP;
END $$;
