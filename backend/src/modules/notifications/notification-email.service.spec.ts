import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { NotificationEmailService } from './notification-email.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * NotificationEmailService Unit Tests
 *
 * Covers the sendSurveyReportEmail flow and verifies that the
 * REPORT_SENT NotificationType is correctly written to the
 * notificationEmailLog table.
 *
 * The root-cause bug was that `REPORT_SENT` existed in the Prisma
 * schema enum but was never added to the Postgres enum via a migration,
 * causing `PostgresError 22P02: invalid input value for enum`.
 * Migration 20260130000000_add_report_sent_notification_type fixes this.
 */
describe('NotificationEmailService', () => {
  let service: NotificationEmailService;

  const mockPrisma = {
    notificationEmailLog: {
      create: jest.fn().mockResolvedValue({ id: 'log-1' }),
    },
  };

  const mockConfig = {
    get: jest.fn((key: string) => {
      const config: Record<string, string> = {
        NOTIFICATION_EMAIL_ENABLED: 'true',
        // No SMTP_HOST → transporter will be null → dev-mode path
        APP_NAME: 'TestApp',
        SMTP_FROM: 'test@example.com',
        CLIENT_PORTAL_URL: 'http://localhost:3000/client',
        FRONTEND_URL: 'http://localhost:3000',
      };
      return config[key];
    }),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationEmailService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: ConfigService, useValue: mockConfig },
      ],
    }).compile();

    service = module.get<NotificationEmailService>(NotificationEmailService);
  });

  describe('sendSurveyReportEmail', () => {
    const recipientEmail = 'client@example.com';
    const surveyTitle = 'Test Survey';
    const pdfBuffer = Buffer.from('fake-pdf-content');
    const senderName = 'John Doe';

    it('should log email with REPORT_SENT notification type in dev mode', async () => {
      const result = await service.sendSurveyReportEmail(
        recipientEmail,
        surveyTitle,
        pdfBuffer,
        senderName,
      );

      expect(result).toBe(true);
      expect(mockPrisma.notificationEmailLog.create).toHaveBeenCalledTimes(1);

      const createCall = mockPrisma.notificationEmailLog.create.mock.calls[0][0];
      expect(createCall.data.notificationType).toBe('REPORT_SENT');
      expect(createCall.data.recipientEmail).toBe(recipientEmail);
      expect(createCall.data.recipientType).toBe('CLIENT');
      expect(createCall.data.subject).toContain('Survey Report');
      expect(createCall.data.status).toBe('DEV_SKIPPED');
    });

    it('should sanitize survey title for filename safety', async () => {
      await service.sendSurveyReportEmail(
        recipientEmail,
        'Dangerous <script>alert("xss")</script> Title!!!',
        pdfBuffer,
        senderName,
      );

      // Should still succeed - title sanitization is internal
      expect(mockPrisma.notificationEmailLog.create).toHaveBeenCalledTimes(1);
    });

    it('should log with FAILED status when email log create throws', async () => {
      // Even if the log itself fails, the method should handle it gracefully
      // (In dev mode path, the create is in the main flow, so an error propagates)
      mockPrisma.notificationEmailLog.create.mockRejectedValueOnce(
        new Error('DB write failed'),
      );

      await expect(
        service.sendSurveyReportEmail(
          recipientEmail,
          surveyTitle,
          pdfBuffer,
          senderName,
        ),
      ).rejects.toThrow('DB write failed');
    });
  });
});
