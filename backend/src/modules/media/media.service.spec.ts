import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { UserRole, MediaType } from '@prisma/client';
import { MediaService } from './media.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService, STORAGE_SERVICE } from './storage/storage.interface';

describe('MediaService', () => {
  let service: MediaService;

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
    userId: 'user-123',
    deletedAt: null,
  };

  const mockMedia = {
    id: 'media-123',
    surveyId: 'survey-123',
    type: MediaType.PHOTO,
    fileName: 'test-photo.jpg',
    mimeType: 'image/jpeg',
    size: 1024,
    storagePath: 'survey-123/media-123.jpg',
    createdAt: new Date(),
    updatedAt: new Date(),
    deletedAt: null,
    survey: mockSurvey,
  };

  const mockPrismaService = {
    survey: {
      findUnique: jest.fn(),
    },
    media: {
      create: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
  };

  const mockStorageService = {
    store: jest.fn(),
    retrieve: jest.fn(),
    delete: jest.fn(),
    exists: jest.fn(),
    getAbsolutePath: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string, defaultVal: unknown) => defaultVal),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MediaService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: STORAGE_SERVICE, useValue: mockStorageService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<MediaService>(MediaService);
  });

  describe('upload', () => {
    const mockFile = {
      originalname: 'test-photo.jpg',
      mimetype: 'image/jpeg',
      size: 1024,
      buffer: Buffer.from('test'),
    };

    it('should upload a photo successfully', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      mockStorageService.store.mockResolvedValue('survey-123/new-id.jpg');
      mockPrismaService.media.create.mockResolvedValue({
        ...mockMedia,
        id: 'new-id',
      });

      const result = await service.upload(
        mockSurvey.id,
        MediaType.PHOTO,
        mockFile,
        mockUser,
      );

      expect(result).toBeDefined();
      expect(result.type).toBe(MediaType.PHOTO);
      expect(mockPrismaService.survey.findUnique).toHaveBeenCalledWith({
        where: { id: mockSurvey.id },
        select: { userId: true, deletedAt: true },
      });
      expect(mockStorageService.store).toHaveBeenCalled();
    });

    it('should reject upload for non-owner', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue({
        ...mockSurvey,
        userId: 'other-user',
      });

      await expect(
        service.upload(mockSurvey.id, MediaType.PHOTO, mockFile, mockUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to upload to any survey', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue({
        ...mockSurvey,
        userId: 'other-user',
      });
      mockStorageService.store.mockResolvedValue('survey-123/new-id.jpg');
      mockPrismaService.media.create.mockResolvedValue(mockMedia);

      const result = await service.upload(
        mockSurvey.id,
        MediaType.PHOTO,
        mockFile,
        mockAdminUser,
      );

      expect(result).toBeDefined();
    });

    it('should reject upload for deleted survey', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue({
        ...mockSurvey,
        deletedAt: new Date(),
      });

      await expect(
        service.upload(mockSurvey.id, MediaType.PHOTO, mockFile, mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should reject upload for non-existent survey', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(null);

      await expect(
        service.upload('non-existent', MediaType.PHOTO, mockFile, mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should reject oversized photo', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);

      const largeFile = {
        ...mockFile,
        size: 100 * 1024 * 1024, // 100MB
      };

      await expect(
        service.upload(mockSurvey.id, MediaType.PHOTO, largeFile, mockUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject invalid mime type', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);

      const invalidFile = {
        ...mockFile,
        mimetype: 'application/pdf',
      };

      await expect(
        service.upload(mockSurvey.id, MediaType.PHOTO, invalidFile, mockUser),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('findOne', () => {
    it('should return media for owner', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue(mockMedia);

      const result = await service.findOne(mockMedia.id, mockUser);

      expect(result).toBeDefined();
      expect(result.id).toBe(mockMedia.id);
    });

    it('should return media for admin', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue({
        ...mockMedia,
        survey: { ...mockSurvey, userId: 'other-user' },
      });

      const result = await service.findOne(mockMedia.id, mockAdminUser);

      expect(result).toBeDefined();
    });

    it('should reject access for non-owner', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue({
        ...mockMedia,
        survey: { ...mockSurvey, userId: 'other-user' },
      });

      await expect(service.findOne(mockMedia.id, mockUser)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw NotFoundException for non-existent media', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException for deleted media', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue({
        ...mockMedia,
        deletedAt: new Date(),
      });

      await expect(service.findOne(mockMedia.id, mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getFilePath', () => {
    it('should return file path for owner', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue(mockMedia);
      mockStorageService.getAbsolutePath.mockReturnValue('/storage/survey-123/media-123.jpg');

      const result = await service.getFilePath(mockMedia.id, mockUser);

      expect(result.path).toBe('/storage/survey-123/media-123.jpg');
      expect(result.mimeType).toBe('image/jpeg');
      expect(result.fileName).toBe('test-photo.jpg');
    });
  });

  describe('delete', () => {
    it('should delete media for owner', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue(mockMedia);
      mockStorageService.delete.mockResolvedValue(true);
      mockPrismaService.media.delete.mockResolvedValue(mockMedia);

      const result = await service.delete(mockMedia.id, mockUser);

      expect(result.success).toBe(true);
      expect(result.id).toBe(mockMedia.id);
      expect(mockStorageService.delete).toHaveBeenCalledWith(mockMedia.storagePath);
    });

    it('should reject delete for non-owner', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue({
        ...mockMedia,
        survey: { ...mockSurvey, userId: 'other-user' },
      });

      await expect(service.delete(mockMedia.id, mockUser)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });
});
