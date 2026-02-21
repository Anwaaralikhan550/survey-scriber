import { Test, TestingModule } from '@nestjs/testing';
import {
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { SectionsService } from './sections.service';
import { PrismaService } from '../prisma/prisma.service';
import { SurveysService } from '../surveys/surveys.service';

describe('SectionsService', () => {
  let service: SectionsService;

  const mockUser = { id: 'user-uuid-123', role: UserRole.SURVEYOR };
  const mockAdminUser = { id: 'admin-uuid-456', role: UserRole.ADMIN };

  const mockSection = {
    id: 'section-uuid-1',
    surveyId: 'survey-uuid-1',
    title: 'Roof Inspection',
    order: 0,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  const mockPrismaService = {
    section: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  const mockSurveysService = {
    verifySurveyOwnership: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SectionsService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: SurveysService, useValue: mockSurveysService },
      ],
    }).compile();

    service = module.get<SectionsService>(SectionsService);
  });

  describe('create', () => {
    it('should create a section successfully', async () => {
      mockSurveysService.verifySurveyOwnership.mockResolvedValue(undefined);
      mockPrismaService.section.create.mockResolvedValue(mockSection);

      const result = await service.create(
        'survey-uuid-1',
        { title: 'Roof Inspection', order: 0 },
        mockUser,
      );

      expect(result.id).toBe('section-uuid-1');
      expect(result.title).toBe('Roof Inspection');
      expect(mockPrismaService.section.create).toHaveBeenCalledWith({
        data: { surveyId: 'survey-uuid-1', title: 'Roof Inspection', order: 0 },
      });
    });

    it('should handle P2002 duplicate by upserting existing section', async () => {
      const p2002Error = new Error('Unique constraint failed');
      (p2002Error as any).code = 'P2002';

      const updatedSection = { ...mockSection, title: 'Updated Title' };

      mockSurveysService.verifySurveyOwnership.mockResolvedValue(undefined);
      mockPrismaService.section.create.mockRejectedValue(p2002Error);
      mockPrismaService.section.findFirst.mockResolvedValue(mockSection);
      mockPrismaService.section.update.mockResolvedValue(updatedSection);

      const result = await service.create(
        'survey-uuid-1',
        { title: 'Updated Title', order: 0 },
        mockUser,
      );

      expect(result.title).toBe('Updated Title');
      expect(mockPrismaService.section.findFirst).toHaveBeenCalledWith({
        where: { surveyId: 'survey-uuid-1', order: 0 },
      });
      expect(mockPrismaService.section.update).toHaveBeenCalledWith({
        where: { id: 'section-uuid-1' },
        data: { title: 'Updated Title' },
      });
    });

    it('should throw ConflictException on P2002 when existing not found', async () => {
      const p2002Error = new Error('Unique constraint failed');
      (p2002Error as any).code = 'P2002';

      mockSurveysService.verifySurveyOwnership.mockResolvedValue(undefined);
      mockPrismaService.section.create.mockRejectedValue(p2002Error);
      mockPrismaService.section.findFirst.mockResolvedValue(null);

      await expect(
        service.create('survey-uuid-1', { title: 'Test', order: 0 }, mockUser),
      ).rejects.toThrow(ConflictException);
    });

    it('should rethrow non-P2002 errors', async () => {
      const genericError = new Error('Database connection lost');

      mockSurveysService.verifySurveyOwnership.mockResolvedValue(undefined);
      mockPrismaService.section.create.mockRejectedValue(genericError);

      await expect(
        service.create('survey-uuid-1', { title: 'Test', order: 0 }, mockUser),
      ).rejects.toThrow('Database connection lost');
    });
  });

  describe('update', () => {
    it('should update a section successfully', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue({
        ...mockSection,
        survey: { userId: mockUser.id, deletedAt: null },
      });
      mockPrismaService.section.update.mockResolvedValue({
        ...mockSection,
        title: 'Updated',
      });

      const result = await service.update(
        'section-uuid-1',
        { title: 'Updated' },
        mockUser,
      );

      expect(result.title).toBe('Updated');
    });

    it('should throw NotFoundException for missing section', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue(null);

      await expect(
        service.update('nonexistent', { title: 'Test' }, mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException for non-owner non-admin', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue({
        ...mockSection,
        survey: { userId: 'other-user', deletedAt: null },
      });

      await expect(
        service.update('section-uuid-1', { title: 'Test' }, mockUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to update any section', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue({
        ...mockSection,
        survey: { userId: 'other-user', deletedAt: null },
      });
      mockPrismaService.section.update.mockResolvedValue({
        ...mockSection,
        title: 'Admin Updated',
      });

      const result = await service.update(
        'section-uuid-1',
        { title: 'Admin Updated' },
        mockAdminUser,
      );

      expect(result.title).toBe('Admin Updated');
    });
  });

  describe('delete', () => {
    it('should delete a section successfully', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue({
        ...mockSection,
        survey: { userId: mockUser.id, deletedAt: null },
      });
      mockPrismaService.section.delete.mockResolvedValue(mockSection);

      const result = await service.delete('section-uuid-1', mockUser);

      expect(result.success).toBe(true);
      expect(result.id).toBe('section-uuid-1');
    });

    it('should throw NotFoundException for deleted survey', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue({
        ...mockSection,
        survey: { userId: mockUser.id, deletedAt: new Date() },
      });

      await expect(
        service.delete('section-uuid-1', mockUser),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
