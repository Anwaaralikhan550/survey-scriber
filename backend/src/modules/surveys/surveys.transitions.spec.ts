import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SurveyStatus, UserRole } from '@prisma/client';
import { SurveysService } from './surveys.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { WebhookDispatcherService } from '../webhooks/webhook-dispatcher.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

/**
 * Survey State Transition Tests
 * Validates that survey status transitions follow the defined state machine:
 * - DRAFT → IN_PROGRESS
 * - IN_PROGRESS → PAUSED, COMPLETED
 * - PAUSED → IN_PROGRESS
 * - COMPLETED → PENDING_REVIEW
 * - PENDING_REVIEW → APPROVED, REJECTED
 * - APPROVED → (terminal)
 * - REJECTED → IN_PROGRESS
 */
describe('SurveysService - Survey State Transitions', () => {
  let service: SurveysService;
  let mockPrismaService: {
    survey: {
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    section: {
      deleteMany: jest.Mock;
    };
    $transaction: jest.Mock;
  };

  const mockUser = {
    id: 'user-123',
    role: UserRole.SURVEYOR,
  };

  const mockAdminUser = {
    id: 'admin-123',
    role: UserRole.ADMIN,
  };

  const createMockSurvey = (status: SurveyStatus, id = 'survey-123') => ({
    id,
    title: 'Test Survey',
    propertyAddress: '123 Test St',
    status,
    type: null,
    jobRef: null,
    clientName: null,
    parentSurveyId: null,
    userId: mockUser.id,
    reportPdfPath: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
    sections: [],
  });

  beforeEach(async () => {
    mockPrismaService = {
      survey: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      section: {
        deleteMany: jest.fn(),
      },
      $transaction: jest.fn((fn) => fn(mockPrismaService)),
    };

    const mockAuditService = {
      log: jest.fn(),
    };

    const mockWebhookDispatcher = {
      dispatchReportApproved: jest.fn(),
    };

    const mockStorageService = {
      store: jest.fn(),
      retrieve: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SurveysService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuditService, useValue: mockAuditService },
        { provide: WebhookDispatcherService, useValue: mockWebhookDispatcher },
        { provide: STORAGE_SERVICE, useValue: mockStorageService },
      ],
    }).compile();

    service = module.get<SurveysService>(SurveysService);
  });

  describe('Valid Transitions', () => {
    it('should allow DRAFT → IN_PROGRESS', async () => {
      const survey = createMockSurvey(SurveyStatus.DRAFT);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.IN_PROGRESS });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.IN_PROGRESS },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.IN_PROGRESS);
    });

    it('should allow IN_PROGRESS → PAUSED', async () => {
      const survey = createMockSurvey(SurveyStatus.IN_PROGRESS);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.PAUSED });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.PAUSED },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.PAUSED);
    });

    it('should allow IN_PROGRESS → COMPLETED', async () => {
      const survey = createMockSurvey(SurveyStatus.IN_PROGRESS);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.COMPLETED });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.COMPLETED },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.COMPLETED);
    });

    it('should allow PAUSED → IN_PROGRESS', async () => {
      const survey = createMockSurvey(SurveyStatus.PAUSED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.IN_PROGRESS });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.IN_PROGRESS },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.IN_PROGRESS);
    });

    it('should allow COMPLETED → PENDING_REVIEW', async () => {
      const survey = createMockSurvey(SurveyStatus.COMPLETED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.PENDING_REVIEW });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.PENDING_REVIEW },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.PENDING_REVIEW);
    });

    it('should allow PENDING_REVIEW → APPROVED', async () => {
      const survey = createMockSurvey(SurveyStatus.PENDING_REVIEW);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.APPROVED });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.APPROVED },
        mockAdminUser,
      );

      expect(result.status).toBe(SurveyStatus.APPROVED);
    });

    it('should allow PENDING_REVIEW → REJECTED', async () => {
      const survey = createMockSurvey(SurveyStatus.PENDING_REVIEW);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.REJECTED });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.REJECTED },
        mockAdminUser,
      );

      expect(result.status).toBe(SurveyStatus.REJECTED);
    });

    it('should allow REJECTED → IN_PROGRESS (revise work)', async () => {
      const survey = createMockSurvey(SurveyStatus.REJECTED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue({ ...survey, status: SurveyStatus.IN_PROGRESS });

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.IN_PROGRESS },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.IN_PROGRESS);
    });
  });

  describe('Invalid Transitions', () => {
    it('should reject APPROVED → DRAFT (terminal state)', async () => {
      const survey = createMockSurvey(SurveyStatus.APPROVED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.DRAFT }, mockAdminUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject APPROVED → IN_PROGRESS (terminal state)', async () => {
      const survey = createMockSurvey(SurveyStatus.APPROVED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.IN_PROGRESS }, mockAdminUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject APPROVED → REJECTED (terminal state)', async () => {
      const survey = createMockSurvey(SurveyStatus.APPROVED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.REJECTED }, mockAdminUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject DRAFT → COMPLETED (must go through IN_PROGRESS)', async () => {
      const survey = createMockSurvey(SurveyStatus.DRAFT);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.COMPLETED }, mockUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject DRAFT → APPROVED (must go through workflow)', async () => {
      const survey = createMockSurvey(SurveyStatus.DRAFT);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.APPROVED }, mockAdminUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject IN_PROGRESS → PENDING_REVIEW (must go through COMPLETED)', async () => {
      const survey = createMockSurvey(SurveyStatus.IN_PROGRESS);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.PENDING_REVIEW }, mockUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject COMPLETED → APPROVED (must go through PENDING_REVIEW)', async () => {
      const survey = createMockSurvey(SurveyStatus.COMPLETED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.APPROVED }, mockAdminUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject REJECTED → APPROVED (must revise and resubmit)', async () => {
      const survey = createMockSurvey(SurveyStatus.REJECTED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      await expect(
        service.update(survey.id, { status: SurveyStatus.APPROVED }, mockAdminUser),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('No-op Transitions', () => {
    it('should allow same-status update (no transition)', async () => {
      const survey = createMockSurvey(SurveyStatus.IN_PROGRESS);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);
      mockPrismaService.survey.update.mockResolvedValue(survey);

      const result = await service.update(
        survey.id,
        { status: SurveyStatus.IN_PROGRESS },
        mockUser,
      );

      expect(result.status).toBe(SurveyStatus.IN_PROGRESS);
    });
  });

  describe('Error Messages', () => {
    it('should provide clear error message for invalid transition', async () => {
      const survey = createMockSurvey(SurveyStatus.APPROVED);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      try {
        await service.update(survey.id, { status: SurveyStatus.DRAFT }, mockAdminUser);
        fail('Expected BadRequestException');
      } catch (error) {
        expect(error).toBeInstanceOf(BadRequestException);
        expect(error.message).toContain('Invalid status transition: APPROVED');
        expect(error.message).toContain('none (terminal state)');
      }
    });

    it('should list allowed transitions in error message', async () => {
      const survey = createMockSurvey(SurveyStatus.IN_PROGRESS);
      mockPrismaService.survey.findUnique.mockResolvedValue(survey);

      try {
        await service.update(survey.id, { status: SurveyStatus.APPROVED }, mockUser);
        fail('Expected BadRequestException');
      } catch (error) {
        expect(error).toBeInstanceOf(BadRequestException);
        expect(error.message).toContain('PAUSED');
        expect(error.message).toContain('COMPLETED');
      }
    });
  });
});
