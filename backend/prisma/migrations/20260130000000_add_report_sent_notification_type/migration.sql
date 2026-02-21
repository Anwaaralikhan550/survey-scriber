-- AlterEnum: Add REPORT_SENT to NotificationType
-- Required by notification-email.service.ts for survey report email logging.
ALTER TYPE "NotificationType" ADD VALUE 'REPORT_SENT';
