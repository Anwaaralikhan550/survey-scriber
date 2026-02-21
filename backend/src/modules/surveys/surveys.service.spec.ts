import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { UserRole, SurveyStatus, SurveyType } from '@prisma/client';
import { SurveysService } from './surveys.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { WebhookDispatcherService } from '../webhooks/webhook-dispatcher.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

describe('SurveysService', () => {
  let service: SurveysService;
  let prismaService: jest.Mocked<PrismaService>;

  const mockUser = {
    id: 'user-uuid-123',
    role: UserRole.SURVEYOR,
  };

  const mockAdminUser = {
    id: 'admin-uuid-456',
    role: UserRole.ADMIN,
  };

  const mockSurvey = {
    id: 'survey-uuid-123',
    title: 'Test Survey',
    propertyAddress: '123 Test Street',
    status: SurveyStatus.DRAFT,
    type: SurveyType.INSPECTION,
    jobRef: 'JOB-001',
    clientName: 'Test Client',
    parentSurveyId: null,
    userId: 'user-uuid-123',
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
    deletedAt: null,
    sections: [],
  };

  const mockPrismaService = {
    survey: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    section: {
      deleteMany: jest.fn(),
    },
    sectionTypeDefinition: {
      findMany: jest.fn(),
    },
    fieldDefinition: {
      findMany: jest.fn(),
    },
    $transaction: jest.fn(),
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

  beforeEach(async () => {
    jest.clearAllMocks();

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
    prismaService = module.get(PrismaService);
  });

  describe('create', () => {
    it('should create a survey successfully', async () => {
      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        return callback({
          survey: {
            create: jest.fn().mockResolvedValue(mockSurvey),
          },
        });
      });

      const result = await service.create(
        {
          title: 'Test Survey',
          propertyAddress: '123 Test Street',
          status: SurveyStatus.DRAFT,
          type: SurveyType.INSPECTION,
          jobRef: 'JOB-001',
          clientName: 'Test Client',
        },
        mockUser,
      );

      expect(result).toHaveProperty('id', mockSurvey.id);
      expect(result).toHaveProperty('title', mockSurvey.title);
      expect(result).toHaveProperty('status', mockSurvey.status);
    });

    it('should create a survey with sections and answers', async () => {
      const surveyWithSections = {
        ...mockSurvey,
        sections: [
          {
            id: 'section-uuid-1',
            title: 'Exterior',
            sectionTypeKey: 'exterior',
            order: 0,
            createdAt: new Date(),
            updatedAt: new Date(),
            answers: [
              {
                id: 'answer-uuid-1',
                questionKey: 'roof_condition',
                value: 'Good',
                createdAt: new Date(),
                updatedAt: new Date(),
              },
            ],
          },
        ],
      };

      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        return callback({
          survey: {
            create: jest.fn().mockResolvedValue(surveyWithSections),
          },
        });
      });

      const result = await service.create(
        {
          title: 'Test Survey',
          propertyAddress: '123 Test Street',
          sections: [
            {
              title: 'Exterior',
              order: 0,
              answers: [{ questionKey: 'roof_condition', value: 'Good' }],
            },
          ],
        },
        mockUser,
      );

      expect(result.sections).toHaveLength(1);
      expect(result.sections[0].answers).toHaveLength(1);
    });
  });

  describe('findOne', () => {
    it('should return a survey if user owns it', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);

      const result = await service.findOne(mockSurvey.id, mockUser);

      expect(result).toHaveProperty('id', mockSurvey.id);
      expect(mockPrismaService.survey.findUnique).toHaveBeenCalledWith({
        where: { id: mockSurvey.id },
        include: {
          sections: {
            include: { answers: true },
            orderBy: { order: 'asc' },
          },
        },
      });
    });

    it('should return a survey for admin regardless of ownership', async () => {
      const otherUserSurvey = { ...mockSurvey, userId: 'other-user-id' };
      mockPrismaService.survey.findUnique.mockResolvedValue(otherUserSurvey);

      const result = await service.findOne(mockSurvey.id, mockAdminUser);

      expect(result).toHaveProperty('id', mockSurvey.id);
    });

    it('should throw NotFoundException if survey does not exist', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(null);

      await expect(service.findOne('nonexistent-id', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException if survey is soft-deleted', async () => {
      const deletedSurvey = { ...mockSurvey, deletedAt: new Date() };
      mockPrismaService.survey.findUnique.mockResolvedValue(deletedSurvey);

      await expect(service.findOne(mockSurvey.id, mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException if user does not own survey', async () => {
      const otherUserSurvey = { ...mockSurvey, userId: 'other-user-id' };
      mockPrismaService.survey.findUnique.mockResolvedValue(otherUserSurvey);

      await expect(service.findOne(mockSurvey.id, mockUser)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('findAll', () => {
    it('should return paginated surveys for user', async () => {
      mockPrismaService.survey.count.mockResolvedValue(1);
      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey]);

      const result = await service.findAll({}, mockUser);

      expect(result.data).toHaveLength(1);
      expect(result.meta).toHaveProperty('total', 1);
      expect(result.meta).toHaveProperty('page', 1);
    });

    it('should filter by status', async () => {
      mockPrismaService.survey.count.mockResolvedValue(1);
      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey]);

      await service.findAll({ status: SurveyStatus.DRAFT }, mockUser);

      expect(mockPrismaService.survey.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: SurveyStatus.DRAFT,
          }),
        }),
      );
    });

    it('should return all surveys for admin', async () => {
      mockPrismaService.survey.count.mockResolvedValue(10);
      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey]);

      await service.findAll({}, mockAdminUser);

      expect(mockPrismaService.survey.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.not.objectContaining({
            userId: expect.anything(),
          }),
        }),
      );
    });

    it('should filter by user for non-admin', async () => {
      mockPrismaService.survey.count.mockResolvedValue(1);
      mockPrismaService.survey.findMany.mockResolvedValue([mockSurvey]);

      await service.findAll({}, mockUser);

      expect(mockPrismaService.survey.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            userId: mockUser.id,
          }),
        }),
      );
    });
  });

  describe('update', () => {
    it('should update a survey successfully', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      const updatedSurvey = { ...mockSurvey, title: 'Updated Title' };
      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        return callback({
          section: { deleteMany: jest.fn() },
          survey: { update: jest.fn().mockResolvedValue(updatedSurvey) },
        });
      });

      const result = await service.update(
        mockSurvey.id,
        { title: 'Updated Title' },
        mockUser,
      );

      expect(result).toHaveProperty('title', 'Updated Title');
    });

    it('should throw NotFoundException if survey does not exist', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(null);

      await expect(
        service.update('nonexistent-id', { title: 'Update' }, mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException if user does not own survey', async () => {
      const otherUserSurvey = { ...mockSurvey, userId: 'other-user-id' };
      mockPrismaService.survey.findUnique.mockResolvedValue(otherUserSurvey);

      await expect(
        service.update(mockSurvey.id, { title: 'Update' }, mockUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to update any survey', async () => {
      const otherUserSurvey = { ...mockSurvey, userId: 'other-user-id' };
      mockPrismaService.survey.findUnique.mockResolvedValue(otherUserSurvey);
      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        return callback({
          section: { deleteMany: jest.fn() },
          survey: { update: jest.fn().mockResolvedValue(otherUserSurvey) },
        });
      });

      const result = await service.update(
        mockSurvey.id,
        { title: 'Admin Update' },
        mockAdminUser,
      );

      expect(result).toBeDefined();
    });
  });

  describe('softDelete', () => {
    it('should soft delete a survey successfully', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      const deletedAt = new Date();
      mockPrismaService.survey.update.mockResolvedValue({
        ...mockSurvey,
        deletedAt,
      });

      const result = await service.softDelete(mockSurvey.id, mockUser);

      expect(result).toHaveProperty('success', true);
      expect(result).toHaveProperty('id', mockSurvey.id);
      expect(result).toHaveProperty('deletedAt');
    });

    it('should throw NotFoundException if survey does not exist', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(null);

      await expect(
        service.softDelete('nonexistent-id', mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException if survey already deleted', async () => {
      const deletedSurvey = { ...mockSurvey, deletedAt: new Date() };
      mockPrismaService.survey.findUnique.mockResolvedValue(deletedSurvey);

      await expect(service.softDelete(mockSurvey.id, mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException if user does not own survey', async () => {
      const otherUserSurvey = { ...mockSurvey, userId: 'other-user-id' };
      mockPrismaService.survey.findUnique.mockResolvedValue(otherUserSurvey);

      await expect(service.softDelete(mockSurvey.id, mockUser)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should allow admin to delete any survey', async () => {
      const otherUserSurvey = { ...mockSurvey, userId: 'other-user-id' };
      mockPrismaService.survey.findUnique.mockResolvedValue(otherUserSurvey);
      mockPrismaService.survey.update.mockResolvedValue({
        ...otherUserSurvey,
        deletedAt: new Date(),
      });

      const result = await service.softDelete(mockSurvey.id, mockAdminUser);

      expect(result).toHaveProperty('success', true);
    });
  });

  describe('getReportData', () => {
    const mockFieldDefinitions = [
      {
        id: 'fd-1',
        sectionType: 'construction',
        fieldKey: 'wall_type',
        fieldType: 'TEXT',
        label: 'Wall Type',
        placeholder: null,
        hint: null,
        isRequired: false,
        displayOrder: 0,
        phraseCategoryId: null,
        validationRules: null,
        maxLines: null,
        fieldGroup: null,
        conditionalOn: null,
        conditionalValue: null,
        description: null,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        phraseCategory: null,
      },
    ];

    const mockSectionTypeDefs = [
      {
        id: 'std-1',
        key: 'construction',
        label: 'Construction',
        description: null,
        icon: null,
        displayOrder: 0,
        surveyTypes: [],
        isActive: true,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ];

    it('should resolve fields via sectionTypeKey (direct match)', async () => {
      const surveyWithKey = {
        ...mockSurvey,
        sections: [
          {
            id: 'sec-1',
            title: 'Construction Details',
            sectionTypeKey: 'construction',
            order: 0,
            createdAt: new Date(),
            updatedAt: new Date(),
            answers: [
              { id: 'a-1', questionKey: 'wall_type', value: 'Brick', createdAt: new Date(), updatedAt: new Date() },
            ],
          },
        ],
      };
      mockPrismaService.survey.findUnique.mockResolvedValue(surveyWithKey);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue(mockSectionTypeDefs);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue(mockFieldDefinitions);

      const result = await service.getReportData(mockSurvey.id, mockUser);

      expect(result.sections).toHaveLength(1);
      expect(result.sections[0].sectionTypeKey).toBe('construction');
      expect(result.sections[0].fields.length).toBeGreaterThan(0);
      expect(result.sections[0].fields[0].label).toBe('Wall Type');
      expect(result.sections[0].fields[0].displayValue).toBe('Brick');
    });

    it('should resolve fields via title alias fallback (old surveys without sectionTypeKey)', async () => {
      const surveyNoKey = {
        ...mockSurvey,
        sections: [
          {
            id: 'sec-2',
            title: 'Construction Details',
            sectionTypeKey: null,
            order: 0,
            createdAt: new Date(),
            updatedAt: new Date(),
            answers: [
              { id: 'a-2', questionKey: 'wall_type', value: 'Stone', createdAt: new Date(), updatedAt: new Date() },
            ],
          },
        ],
      };
      mockPrismaService.survey.findUnique.mockResolvedValue(surveyNoKey);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue(mockSectionTypeDefs);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue(mockFieldDefinitions);

      const result = await service.getReportData(mockSurvey.id, mockUser);

      // "Construction Details" doesn't match seed label "Construction" exactly,
      // but the title alias map maps it to 'construction'
      expect(result.sections[0].sectionTypeKey).toBe('construction');
      expect(result.sections[0].fields.length).toBeGreaterThan(0);
      expect(result.sections[0].fields[0].displayValue).toBe('Stone');
    });

    it('should resolve fields via exact title match (backward compat)', async () => {
      const surveyExactTitle = {
        ...mockSurvey,
        sections: [
          {
            id: 'sec-3',
            title: 'Construction',
            sectionTypeKey: null,
            order: 0,
            createdAt: new Date(),
            updatedAt: new Date(),
            answers: [
              { id: 'a-3', questionKey: 'wall_type', value: 'Timber', createdAt: new Date(), updatedAt: new Date() },
            ],
          },
        ],
      };
      mockPrismaService.survey.findUnique.mockResolvedValue(surveyExactTitle);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue(mockSectionTypeDefs);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue(mockFieldDefinitions);

      const result = await service.getReportData(mockSurvey.id, mockUser);

      // "Construction" matches the seed label "Construction" exactly via labelToKey
      expect(result.sections[0].sectionTypeKey).toBe('construction');
      expect(result.sections[0].fields.length).toBeGreaterThan(0);
      expect(result.sections[0].fields[0].displayValue).toBe('Timber');
    });
  });

  describe('verifySurveyOwnership', () => {
    it('should not throw if user owns the survey', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue({
        userId: mockUser.id,
        deletedAt: null,
      });

      await expect(
        service.verifySurveyOwnership(mockSurvey.id, mockUser),
      ).resolves.not.toThrow();
    });

    it('should not throw if user is admin', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue({
        userId: 'other-user-id',
        deletedAt: null,
      });

      await expect(
        service.verifySurveyOwnership(mockSurvey.id, mockAdminUser),
      ).resolves.not.toThrow();
    });

    it('should throw NotFoundException if survey not found', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(null);

      await expect(
        service.verifySurveyOwnership('nonexistent-id', mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException if user does not own survey', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue({
        userId: 'other-user-id',
        deletedAt: null,
      });

      await expect(
        service.verifySurveyOwnership(mockSurvey.id, mockUser),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
