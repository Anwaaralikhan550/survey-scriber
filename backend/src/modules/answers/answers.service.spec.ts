import { Test, TestingModule } from '@nestjs/testing';
import {
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AnswersService } from './answers.service';
import { PrismaService } from '../prisma/prisma.service';

describe('AnswersService', () => {
  let service: AnswersService;

  const mockUser = { id: 'user-uuid-123', role: UserRole.SURVEYOR };
  const mockAdminUser = { id: 'admin-uuid-456', role: UserRole.ADMIN };

  const mockAnswer = {
    id: 'answer-uuid-1',
    sectionId: 'section-uuid-1',
    questionKey: 'roof_condition',
    value: 'Good',
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
  };

  const mockSectionWithSurvey = {
    id: 'section-uuid-1',
    surveyId: 'survey-uuid-1',
    survey: { userId: 'user-uuid-123', deletedAt: null },
  };

  const mockPrismaService = {
    section: {
      findUnique: jest.fn(),
    },
    answer: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnswersService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<AnswersService>(AnswersService);
  });

  describe('create', () => {
    it('should create an answer successfully', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue(mockSectionWithSurvey);
      mockPrismaService.answer.create.mockResolvedValue(mockAnswer);

      const result = await service.create(
        'section-uuid-1',
        { questionKey: 'roof_condition', value: 'Good' },
        mockUser,
      );

      expect(result.id).toBe('answer-uuid-1');
      expect(result.questionKey).toBe('roof_condition');
      expect(result.value).toBe('Good');
    });

    it('should throw NotFoundException when section not found', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue(null);

      await expect(
        service.create(
          'nonexistent',
          { questionKey: 'test', value: 'val' },
          mockUser,
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException for non-owner non-admin', async () => {
      mockPrismaService.section.findUnique.mockResolvedValue({
        ...mockSectionWithSurvey,
        survey: { userId: 'other-user', deletedAt: null },
      });

      await expect(
        service.create(
          'section-uuid-1',
          { questionKey: 'test', value: 'val' },
          mockUser,
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should handle P2002 duplicate by upserting existing answer', async () => {
      const p2002Error = new Error('Unique constraint failed');
      (p2002Error as any).code = 'P2002';

      const updatedAnswer = { ...mockAnswer, value: 'Updated value' };

      mockPrismaService.section.findUnique.mockResolvedValue(mockSectionWithSurvey);
      mockPrismaService.answer.create.mockRejectedValue(p2002Error);
      mockPrismaService.answer.findFirst.mockResolvedValue(mockAnswer);
      mockPrismaService.answer.update.mockResolvedValue(updatedAnswer);

      const result = await service.create(
        'section-uuid-1',
        { questionKey: 'roof_condition', value: 'Updated value' },
        mockUser,
      );

      expect(result.value).toBe('Updated value');
      expect(mockPrismaService.answer.findFirst).toHaveBeenCalledWith({
        where: { sectionId: 'section-uuid-1', questionKey: 'roof_condition' },
      });
      expect(mockPrismaService.answer.update).toHaveBeenCalledWith({
        where: { id: 'answer-uuid-1' },
        data: { value: 'Updated value' },
      });
    });

    it('should throw ConflictException on P2002 when existing not found', async () => {
      const p2002Error = new Error('Unique constraint failed');
      (p2002Error as any).code = 'P2002';

      mockPrismaService.section.findUnique.mockResolvedValue(mockSectionWithSurvey);
      mockPrismaService.answer.create.mockRejectedValue(p2002Error);
      mockPrismaService.answer.findFirst.mockResolvedValue(null);

      await expect(
        service.create(
          'section-uuid-1',
          { questionKey: 'test', value: 'val' },
          mockUser,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('should rethrow non-P2002 errors', async () => {
      const genericError = new Error('Database connection lost');

      mockPrismaService.section.findUnique.mockResolvedValue(mockSectionWithSurvey);
      mockPrismaService.answer.create.mockRejectedValue(genericError);

      await expect(
        service.create(
          'section-uuid-1',
          { questionKey: 'test', value: 'val' },
          mockUser,
        ),
      ).rejects.toThrow('Database connection lost');
    });
  });

  describe('update', () => {
    it('should update an answer successfully', async () => {
      mockPrismaService.answer.findUnique.mockResolvedValue({
        ...mockAnswer,
        section: { survey: { userId: mockUser.id, deletedAt: null } },
      });
      mockPrismaService.answer.update.mockResolvedValue({
        ...mockAnswer,
        value: 'Updated',
      });

      const result = await service.update(
        'answer-uuid-1',
        { questionKey: 'roof_condition', value: 'Updated' },
        mockUser,
      );

      expect(result.value).toBe('Updated');
    });

    it('should throw NotFoundException for missing answer', async () => {
      mockPrismaService.answer.findUnique.mockResolvedValue(null);

      await expect(
        service.update('nonexistent', { value: 'Test' }, mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should allow admin to update any answer', async () => {
      mockPrismaService.answer.findUnique.mockResolvedValue({
        ...mockAnswer,
        section: { survey: { userId: 'other-user', deletedAt: null } },
      });
      mockPrismaService.answer.update.mockResolvedValue({
        ...mockAnswer,
        value: 'Admin Updated',
      });

      const result = await service.update(
        'answer-uuid-1',
        { questionKey: 'roof_condition', value: 'Admin Updated' },
        mockAdminUser,
      );

      expect(result.value).toBe('Admin Updated');
    });
  });

  describe('delete', () => {
    it('should delete an answer successfully', async () => {
      mockPrismaService.answer.findUnique.mockResolvedValue({
        ...mockAnswer,
        section: { survey: { userId: mockUser.id, deletedAt: null } },
      });
      mockPrismaService.answer.delete.mockResolvedValue(mockAnswer);

      const result = await service.delete('answer-uuid-1', mockUser);

      expect(result.success).toBe(true);
      expect(result.id).toBe('answer-uuid-1');
    });

    it('should throw NotFoundException for deleted survey', async () => {
      mockPrismaService.answer.findUnique.mockResolvedValue({
        ...mockAnswer,
        section: { survey: { userId: mockUser.id, deletedAt: new Date() } },
      });

      await expect(
        service.delete('answer-uuid-1', mockUser),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
