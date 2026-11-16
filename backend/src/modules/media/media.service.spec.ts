import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { UserRole, MediaType } from '@prisma/client';
import { MediaService } from './media.service';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService, STORAGE_SERVICE } from './storage/storage.interface';
import sharp from 'sharp';

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
    let mockFile: { originalname: string; mimetype: string; size: number; buffer: Buffer };

    beforeAll(async () => {
      const buffer = await sharp({ create: { width: 64, height: 48, channels: 3, background: '#808080' } }).jpeg().toBuffer();
      mockFile = { originalname: 'test-photo.jpg', mimetype: 'image/jpeg', size: buffer.length, buffer };
    });

    it('should upload a photo successfully', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      mockStorageService.store.mockResolvedValue('survey-123/new-id.jpg');
      mockPrismaService.media.create.mockResolvedValue({
        ...mockMedia,
        id: 'new-id',
      });

      const result = await service.upload(mockSurvey.id, MediaType.PHOTO, mockFile, mockUser);

      expect(result).toBeDefined();
      expect(result.type).toBe(MediaType.PHOTO);
      expect(mockPrismaService.survey.findUnique).toHaveBeenCalledWith({
        where: { id: mockSurvey.id },
        select: { userId: true, deletedAt: true },
      });
      expect(mockStorageService.store).toHaveBeenCalled();
    });

    describe('photo processing (spec section 9)', () => {
      const exif = { IFD0: { Copyright: 'Secret Surveyor', ImageDescription: 'at 51.4,0.2' }, IFD3: { GPSLatitudeRef: 'N', GPSLatitude: '51/1 24/1 0/1', GPSLongitudeRef: 'E', GPSLongitude: '0/1 12/1 0/1' } };

      beforeEach(() => {
        mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
        mockStorageService.store.mockReset();
        mockStorageService.store.mockResolvedValue('survey-123/new-id.jpg');
        mockPrismaService.media.create.mockReset();
        mockPrismaService.media.create.mockImplementation(async ({ data }: { data: Record<string, unknown> }) => ({ ...mockMedia, ...data }));
      });

      const stored = () => mockStorageService.store.mock.calls[0][2] as Buffer;

      it('removes EXIF and GPS from the stored file', async () => {
        const withGps = await sharp({ create: { width: 64, height: 48, channels: 3, background: '#445566' } }).jpeg().withExif(exif).toBuffer();
        expect((await sharp(withGps).metadata()).exif).toBeDefined();
        await service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 'g.jpg', mimetype: 'image/jpeg', size: withGps.length, buffer: withGps }, mockUser);
        const out = await sharp(stored()).metadata();
        expect(out.exif).toBeUndefined();
        expect(stored().includes(Buffer.from('Secret Surveyor'))).toBe(false);
        expect(stored().includes(Buffer.from('GPS'))).toBe(false);
        expect(out.format).toBe('jpeg');
      });

      it('turns a sideways phone photo upright before the orientation tag is dropped', async () => {
        const sideways = await sharp({ create: { width: 80, height: 40, channels: 3, background: '#aa5500' } }).jpeg().withMetadata({ orientation: 6 }).toBuffer();
        await service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 's.jpg', mimetype: 'image/jpeg', size: sideways.length, buffer: sideways }, mockUser);
        const out = await sharp(stored()).metadata();
        expect([out.width, out.height]).toEqual([40, 80]);
        expect(out.orientation).toBeUndefined();
      });

      it('stores the size and type of the processed file and the caption, section and order from the phone', async () => {
        await service.upload(mockSurvey.id, MediaType.PHOTO, mockFile, mockUser, { caption: 'Rear elevation', sectionKey: 'E/roof', sortOrder: 3 });
        const data = mockPrismaService.media.create.mock.calls[0][0].data;
        expect(data.size).toBe(stored().length);
        expect(data.mimeType).toBe('image/jpeg');
        expect(data).toMatchObject({ caption: 'Rear elevation', sectionKey: 'E/roof', sortOrder: 3 });
      });

      it('refuses a file that has the right first bytes but is not a picture', async () => {
        const fake = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.from('<?php system($_GET[0]); ?>')]);
        await expect(service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 'x.jpg', mimetype: 'image/jpeg', size: fake.length, buffer: fake }, mockUser)).rejects.toThrow(/not a valid image/);
        expect(mockStorageService.store).not.toHaveBeenCalled();
      });

      it('refuses a truncated photo', async () => {
        const cut = mockFile.buffer.subarray(0, Math.floor(mockFile.buffer.length / 2));
        await expect(service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 'x.jpg', mimetype: 'image/jpeg', size: cut.length, buffer: cut }, mockUser)).rejects.toThrow(BadRequestException);
        expect(mockStorageService.store).not.toHaveBeenCalled();
      });

      it('refuses a picture whose real format differs from the declared type', async () => {
        const png = await sharp({ create: { width: 64, height: 64, channels: 3, background: '#000' } }).png().toBuffer();
        await expect(service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 'x.jpg', mimetype: 'image/jpeg', size: png.length, buffer: png }, mockUser)).rejects.toThrow(BadRequestException);
      });

      it('refuses photos that are too small or too large in pixels', async () => {
        const tiny = await sharp({ create: { width: 8, height: 8, channels: 3, background: '#000' } }).jpeg().toBuffer();
        await expect(service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 't.jpg', mimetype: 'image/jpeg', size: tiny.length, buffer: tiny }, mockUser)).rejects.toThrow(/too small/);
        const wide = await sharp({ create: { width: 12100, height: 20, channels: 3, background: '#000' } }).png().toBuffer();
        await expect(service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 'w.png', mimetype: 'image/png', size: wide.length, buffer: wide }, mockUser)).rejects.toThrow(/too large/);
      });

      it('keeps a PNG a PNG and does not touch non-photo uploads', async () => {
        const png = await sharp({ create: { width: 64, height: 64, channels: 4, background: '#ff000080' } }).png().toBuffer();
        await service.upload(mockSurvey.id, MediaType.PHOTO, { originalname: 'p.png', mimetype: 'image/png', size: png.length, buffer: png }, mockUser);
        expect((await sharp(stored()).metadata()).format).toBe('png');
        mockStorageService.store.mockClear();
        const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4]);
        await service.upload(mockSurvey.id, MediaType.SIGNATURE, { originalname: 's.png', mimetype: 'image/png', size: sig.length, buffer: sig }, mockUser);
        expect(mockStorageService.store.mock.calls[0][2]).toBe(sig);
      });
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

      const result = await service.upload(mockSurvey.id, MediaType.PHOTO, mockFile, mockAdminUser);

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

    it('should reject a spoofed JPEG content type', async () => {
      mockPrismaService.survey.findUnique.mockResolvedValue(mockSurvey);
      const spoofedFile = {
        ...mockFile,
        buffer: Buffer.from('not-a-jpeg'),
      };

      await expect(
        service.upload(mockSurvey.id, MediaType.PHOTO, spoofedFile, mockUser),
      ).rejects.toThrow('File content does not match the declared file type');
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

      await expect(service.findOne(mockMedia.id, mockUser)).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException for non-existent media', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent', mockUser)).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException for deleted media', async () => {
      mockPrismaService.media.findUnique.mockResolvedValue({
        ...mockMedia,
        deletedAt: new Date(),
      });

      await expect(service.findOne(mockMedia.id, mockUser)).rejects.toThrow(NotFoundException);
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

      await expect(service.delete(mockMedia.id, mockUser)).rejects.toThrow(ForbiddenException);
    });
  });
});
