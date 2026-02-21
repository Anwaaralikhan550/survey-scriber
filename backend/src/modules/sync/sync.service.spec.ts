import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { UserRole, SurveyStatus } from '@prisma/client';
import { SyncService } from './sync.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  SyncOperationType,
  SyncEntityType,
  SyncPushDto,
} from './dto';

describe('SyncService', () => {
  let service: SyncService;

  const mockUser = {
    id: 'user-123',
    role: UserRole.SURVEYOR,
  };

  const mockAdminUser = {
    id: 'admin-456',
    role: UserRole.ADMIN,
  };

  const mockSurvey = {
    id: 'survey-123',
    title: 'Test Survey',
    propertyAddress: '123 Main St',
    status: SurveyStatus.DRAFT,
    type: null,
    jobRef: null,
    clientName: null,
    parentSurveyId: null,
    userId: 'user-123',
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
  };

  const mockPrismaService = {
    syncIdempotency: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    survey: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    section: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    answer: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    media: {
      findMany: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  beforeEach(async () => {
    jest.resetAllMocks();

    // Default transaction implementation that passes through mock prisma
    mockPrismaService.$transaction.mockImplementation(async (fn) => {
      return fn(mockPrismaService);
    });

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SyncService,
        { provide: PrismaService, useValue: mockPrismaService },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === 'APP_URL') return 'http://localhost:3000';
              return undefined;
            }),
          },
        },
      ],
    }).compile();

    service = module.get<SyncService>(SyncService);
  });

  describe('push', () => {
    it('should return duplicate response for existing idempotency key', async () => {
      const existingBatch = {
        id: 'batch-1',
        userId: mockUser.id,
        idempotencyKey: 'batch-key-1',
        requestHash: 'hash',
        createdAt: new Date(),
      };

      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(existingBatch);

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-1',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SURVEY,
            entityId: 'new-survey-123',
            data: { title: 'New Survey' },
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.batchDuplicate).toBe(true);
      expect(result.results[0].duplicate).toBe(true);
    });

    it('should process new batch with survey create operation', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique.mockResolvedValue(null);
      mockPrismaService.survey.create.mockResolvedValue(mockSurvey);

      const dto: SyncPushDto = {
        idempotencyKey: 'new-batch-key',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: { title: 'New Survey', propertyAddress: '123 Main St' },
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.success).toBe(true);
      expect(result.results[0].success).toBe(true);
      expect(result.results[0].entityId).toBe(mockSurvey.id);
    });

    it('should handle duplicate entity create (idempotent)', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-2',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: { title: 'Duplicate Survey' },
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.results[0].success).toBe(true);
      expect(result.results[0].duplicate).toBe(true);
    });

    it('should process survey update operation', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      mockPrismaService.survey.update.mockResolvedValue({
        ...mockSurvey,
        title: 'Updated Title',
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-3',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.UPDATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: { title: 'Updated Title' },
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.results[0].success).toBe(true);
    });

    it('should reject update for non-owner survey', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique.mockResolvedValue({
        ...mockSurvey,
        userId: 'other-user',
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-4',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.UPDATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: { title: 'Hacked Title' },
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.results[0].success).toBe(false);
      expect(result.results[0].error).toBe('Access denied');
    });

    it('should allow admin to update any survey', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique.mockResolvedValue({
        ...mockSurvey,
        userId: 'other-user',
      });
      mockPrismaService.survey.update.mockResolvedValue(mockSurvey);

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-5',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.UPDATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: { title: 'Admin Update' },
          },
        ],
      };

      const result = await service.push(dto, mockAdminUser);

      expect(result.results[0].success).toBe(true);
    });

    it('should process survey soft delete operation', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      mockPrismaService.survey.update.mockResolvedValue({
        ...mockSurvey,
        deletedAt: new Date(),
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-6',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.DELETE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.results[0].success).toBe(true);
    });

    it('should process multiple operations in batch', async () => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
      mockPrismaService.survey.findUnique
        .mockResolvedValueOnce(null) // First: create check
        .mockResolvedValueOnce(mockSurvey); // Second: for section access
      mockPrismaService.survey.create.mockResolvedValue(mockSurvey);
      mockPrismaService.section.findUnique.mockResolvedValue(null);
      mockPrismaService.section.create.mockResolvedValue({
        id: 'section-123',
        surveyId: mockSurvey.id,
        title: 'Section 1',
        order: 0,
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'batch-key-7',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: { title: 'New Survey' },
          },
          {
            operationId: 'op-2',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SECTION,
            entityId: 'section-123',
            data: { surveyId: mockSurvey.id, title: 'Section 1' },
          },
        ],
      };

      const result = await service.push(dto, mockUser);

      expect(result.results).toHaveLength(2);
      expect(result.results.every((r) => r.success)).toBe(true);
    });
  });

  describe('pull', () => {
    it('should return surveys owned by user', async () => {
      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey]);
      mockPrismaService.section.findMany.mockResolvedValue([]);
      mockPrismaService.answer.findMany.mockResolvedValue([]);
      mockPrismaService.media.findMany.mockResolvedValue([]);

      const result = await service.pull({}, mockUser);

      expect(result.changes).toHaveLength(1);
      expect(result.changes[0].entityId).toBe(mockSurvey.id);
      expect(result.changes[0].entityType).toBe(SyncEntityType.SURVEY);
    });

    it('should return changes since timestamp', async () => {
      const since = new Date('2024-01-01');

      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey]);
      mockPrismaService.section.findMany.mockResolvedValue([]);
      mockPrismaService.answer.findMany.mockResolvedValue([]);
      mockPrismaService.media.findMany.mockResolvedValue([]);

      const result = await service.pull({ since: since.toISOString() }, mockUser);

      expect(result.serverTimestamp).toBeInstanceOf(Date);
    });

    it('should indicate hasMore when results exceed limit', async () => {
      const manySurveys = Array.from({ length: 5 }, (_, i) => ({
        ...mockSurvey,
        id: 'survey-' + i,
      }));

      mockPrismaService.survey.findMany.mockResolvedValue(manySurveys);
      mockPrismaService.section.findMany.mockResolvedValue([]);
      mockPrismaService.answer.findMany.mockResolvedValue([]);
      mockPrismaService.media.findMany.mockResolvedValue([]);

      const result = await service.pull({ limit: 3 }, mockUser);

      expect(result.changes.length).toBeLessThanOrEqual(3);
      expect(result.hasMore).toBe(true);
      // totalCount reflects the limited slice, not total across all entities
      expect(result.totalCount).toBe(result.changes.length);
    });

    it('should return deleted entities with DELETE change type', async () => {
      const deletedSurvey = {
        ...mockSurvey,
        deletedAt: new Date(),
      };

      mockPrismaService.survey.findMany.mockResolvedValue([deletedSurvey]);
      mockPrismaService.section.findMany.mockResolvedValue([]);
      mockPrismaService.answer.findMany.mockResolvedValue([]);
      mockPrismaService.media.findMany.mockResolvedValue([]);

      const result = await service.pull({}, mockUser);

      expect(result.changes[0].changeType).toBe(SyncOperationType.DELETE);
      expect(result.changes[0].data).toBeNull();
    });

    it('should return all surveys for admin (includes all users)', async () => {
      const otherUserSurvey = {
        ...mockSurvey,
        id: 'other-survey',
        userId: 'other-user',
      };

      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey, otherUserSurvey]);
      mockPrismaService.section.findMany.mockResolvedValue([]);
      mockPrismaService.answer.findMany.mockResolvedValue([]);
      mockPrismaService.media.findMany.mockResolvedValue([]);

      const result = await service.pull({}, mockAdminUser);

      expect(result.changes.length).toBe(2);
    });
  });

  // ============================================================
  // Contract Tests: Validate Flutter client payloads match backend DTOs
  // ============================================================
  describe('contract: Flutter client payload compatibility', () => {
    beforeEach(() => {
      mockPrismaService.syncIdempotency.findUnique.mockResolvedValue(null);
      mockPrismaService.syncIdempotency.create.mockResolvedValue({});
    });

    it('should accept survey payload matching Flutter sync_manager format', async () => {
      // This payload mirrors what sync_manager.dart _syncSurvey sends
      // via the sync/push batch endpoint
      mockPrismaService.survey.findUnique.mockResolvedValue(null);
      mockPrismaService.survey.create.mockResolvedValue(mockSurvey);

      const dto: SyncPushDto = {
        idempotencyKey: 'contract-survey-key',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SURVEY,
            entityId: 'survey-contract-1',
            data: {
              title: 'Contract Test Survey',
              propertyAddress: '123 Contract St',
              status: 'DRAFT',
              type: 'INSPECTION',
              jobRef: 'JOB-001',
              clientName: 'John Smith',
            },
          },
        ],
      };

      const result = await service.push(dto, mockUser);
      expect(result.success).toBe(true);
      expect(result.results[0].success).toBe(true);
    });

    it('should accept section payload matching Flutter format', async () => {
      // Flutter sends: { title, order } (surveyId stripped from body, used in URL)
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      mockPrismaService.section.findUnique.mockResolvedValue(null);
      mockPrismaService.section.create.mockResolvedValue({
        id: 'section-contract-1',
        surveyId: mockSurvey.id,
        title: 'Contract Section',
        order: 0,
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'contract-section-key',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SECTION,
            entityId: 'section-contract-1',
            data: {
              surveyId: mockSurvey.id,
              title: 'Contract Section',
              order: 0,
            },
          },
        ],
      };

      const result = await service.push(dto, mockUser);
      expect(result.success).toBe(true);
      expect(result.results[0].success).toBe(true);
    });

    it('should accept answer payload matching Flutter format', async () => {
      // Flutter sends: { questionKey, value } (sectionId stripped from body, used in URL)
      const mockSection = {
        id: 'section-contract-2',
        surveyId: mockSurvey.id,
        survey: mockSurvey,
      };
      mockPrismaService.section.findUnique.mockResolvedValue(mockSection);
      mockPrismaService.answer.findUnique.mockResolvedValue(null);
      mockPrismaService.answer.create.mockResolvedValue({
        id: 'answer-contract-1',
        sectionId: mockSection.id,
        questionKey: 'roof_condition',
        value: 'Good',
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'contract-answer-key',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.ANSWER,
            entityId: 'answer-contract-1',
            data: {
              sectionId: mockSection.id,
              questionKey: 'roof_condition',
              value: 'Good',
            },
          },
        ],
      };

      const result = await service.push(dto, mockUser);
      expect(result.success).toBe(true);
      expect(result.results[0].success).toBe(true);
    });

    it('should accept batch with survey + sections + answers in order', async () => {
      // Simulates the full offline→online sync flow the Flutter client performs
      mockPrismaService.survey.findUnique
        .mockResolvedValueOnce(null) // CREATE check: survey doesn't exist
        .mockResolvedValueOnce(mockSurvey); // Section access check: survey exists
      mockPrismaService.survey.create.mockResolvedValue(mockSurvey);
      mockPrismaService.section.findUnique
        .mockResolvedValueOnce(null) // CREATE check: section doesn't exist
        .mockResolvedValueOnce({
          id: 'section-batch-1',
          surveyId: mockSurvey.id,
          survey: mockSurvey,
        }); // Answer access check
      mockPrismaService.section.create.mockResolvedValue({
        id: 'section-batch-1',
        surveyId: mockSurvey.id,
        title: 'Batch Section',
        order: 0,
      });
      mockPrismaService.answer.findUnique.mockResolvedValue(null);
      mockPrismaService.answer.create.mockResolvedValue({
        id: 'answer-batch-1',
        sectionId: 'section-batch-1',
        questionKey: 'q1',
        value: 'v1',
      });

      const dto: SyncPushDto = {
        idempotencyKey: 'contract-batch-key',
        operations: [
          {
            operationId: 'op-1',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SURVEY,
            entityId: mockSurvey.id,
            data: {
              title: 'Batch Survey',
              propertyAddress: '456 Batch Ave',
              status: 'DRAFT',
              type: 'INSPECTION',
            },
          },
          {
            operationId: 'op-2',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.SECTION,
            entityId: 'section-batch-1',
            data: {
              surveyId: mockSurvey.id,
              title: 'Batch Section',
              order: 0,
            },
          },
          {
            operationId: 'op-3',
            operationType: SyncOperationType.CREATE,
            entityType: SyncEntityType.ANSWER,
            entityId: 'answer-batch-1',
            data: {
              sectionId: 'section-batch-1',
              questionKey: 'q1',
              value: 'v1',
            },
          },
        ],
      };

      const result = await service.push(dto, mockUser);
      expect(result.success).toBe(true);
      expect(result.results).toHaveLength(3);
      expect(result.results.every((r) => r.success)).toBe(true);
    });
  });
});
