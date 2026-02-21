import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Inject,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole, MediaType } from '@prisma/client';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService, STORAGE_SERVICE } from './storage/storage.interface';
import { MediaResponseDto, DeleteMediaResponseDto } from './dto';
import { ApiUrlBuilder } from '../../common/utils/api-url.util';

interface AuthenticatedUser {
  id: string;
  role: UserRole;
}

interface UploadedFile {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);
  private readonly maxSizePhoto: number;
  private readonly maxSizeAudio: number;
  private readonly maxSizeSignature: number;
  private readonly allowedMimePhoto: string[];
  private readonly allowedMimeAudio: string[];
  private readonly allowedMimeSignature: string[];
  private readonly urlBuilder: ApiUrlBuilder;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    @Inject(STORAGE_SERVICE) private readonly storageService: StorageService,
  ) {
    // Convert MB to bytes
    this.maxSizePhoto = (this.configService.get<number>('MAX_UPLOAD_MB_PHOTO', 10)) * 1024 * 1024;
    this.maxSizeAudio = (this.configService.get<number>('MAX_UPLOAD_MB_AUDIO', 30)) * 1024 * 1024;
    this.maxSizeSignature = (this.configService.get<number>('MAX_UPLOAD_MB_SIGNATURE', 5)) * 1024 * 1024;

    this.allowedMimePhoto = this.configService.get<string>('ALLOWED_MIME_PHOTO', 'image/jpeg,image/png').split(',');
    this.allowedMimeAudio = this.configService.get<string>('ALLOWED_MIME_AUDIO', 'audio/mpeg,audio/wav').split(',');
    this.allowedMimeSignature = this.configService.get<string>('ALLOWED_MIME_SIGNATURE', 'image/png').split(',');
    this.urlBuilder = new ApiUrlBuilder(configService);
  }

  async upload(
    surveyId: string,
    type: MediaType,
    file: UploadedFile,
    user: AuthenticatedUser,
  ): Promise<MediaResponseDto> {
    // 1. Verify survey access
    await this.verifySurveyAccess(surveyId, user);

    // 2. Validate file size and mime type
    this.validateFile(type, file);

    // 3. Generate file ID and extract extension
    const fileId = this.generateUuid();
    const extension = this.getExtension(file.originalname, file.mimetype);

    // 4. Store file
    const storagePath = await this.storageService.store(
      surveyId,
      fileId,
      file.buffer,
      extension,
    );

    // 5. Create DB record
    const media = await this.prisma.media.create({
      data: {
        id: fileId,
        surveyId,
        type,
        fileName: file.originalname,
        mimeType: file.mimetype,
        size: file.size,
        storagePath,
      },
    });

    this.logger.log('Media uploaded: ' + media.id + ' for survey: ' + surveyId);

    return this.mapToResponse(media);
  }

  async findOne(id: string, user: AuthenticatedUser): Promise<MediaResponseDto> {
    const media = await this.prisma.media.findUnique({
      where: { id },
      include: { survey: { select: { userId: true, deletedAt: true } } },
    });

    if (!media || media.deletedAt !== null) {
      throw new NotFoundException('Media not found');
    }

    if (media.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (media.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this media');
    }

    return this.mapToResponse(media);
  }

  async getFilePath(id: string, user: AuthenticatedUser): Promise<{ path: string; mimeType: string; fileName: string }> {
    const media = await this.prisma.media.findUnique({
      where: { id },
      include: { survey: { select: { userId: true, deletedAt: true } } },
    });

    if (!media || media.deletedAt !== null) {
      throw new NotFoundException('Media not found');
    }

    if (media.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (media.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this media');
    }

    const absolutePath = this.storageService.getAbsolutePath(media.storagePath);

    return {
      path: absolutePath,
      mimeType: media.mimeType,
      fileName: media.fileName,
    };
  }

  async delete(id: string, user: AuthenticatedUser): Promise<DeleteMediaResponseDto> {
    const media = await this.prisma.media.findUnique({
      where: { id },
      include: { survey: { select: { userId: true, deletedAt: true } } },
    });

    if (!media || media.deletedAt !== null) {
      throw new NotFoundException('Media not found');
    }

    if (media.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (media.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this media');
    }

    // Hard delete: remove file from storage
    await this.storageService.delete(media.storagePath);

    // Hard delete: remove DB record
    await this.prisma.media.delete({ where: { id } });

    this.logger.log('Media deleted: ' + id);

    return { success: true, id };
  }

  private async verifySurveyAccess(surveyId: string, user: AuthenticatedUser): Promise<void> {
    const survey = await this.prisma.survey.findUnique({
      where: { id: surveyId },
      select: { userId: true, deletedAt: true },
    });

    if (!survey || survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }
  }

  private validateFile(type: MediaType, file: UploadedFile): void {
    let maxSize: number;
    let allowedMimes: string[];
    let typeName: string;

    switch (type) {
      case MediaType.PHOTO:
        maxSize = this.maxSizePhoto;
        allowedMimes = this.allowedMimePhoto;
        typeName = 'photo';
        break;
      case MediaType.AUDIO:
        maxSize = this.maxSizeAudio;
        allowedMimes = this.allowedMimeAudio;
        typeName = 'audio';
        break;
      case MediaType.SIGNATURE:
        maxSize = this.maxSizeSignature;
        allowedMimes = this.allowedMimeSignature;
        typeName = 'signature';
        break;
      default:
        throw new BadRequestException('Invalid media type');
    }

    if (file.size > maxSize) {
      throw new BadRequestException(
        'File too large for ' + typeName + '. Maximum size: ' + (maxSize / 1024 / 1024) + 'MB'
      );
    }

    if (!allowedMimes.includes(file.mimetype)) {
      throw new BadRequestException(
        'Invalid file type for ' + typeName + '. Allowed types: ' + allowedMimes.join(', ')
      );
    }

    // SEC-L11: Verify file magic bytes match claimed MIME type.
    // Prevents uploading executables/scripts disguised with a spoofed Content-Type header.
    if (!this.verifyMagicBytes(file.buffer, file.mimetype)) {
      throw new BadRequestException(
        'File content does not match the declared file type'
      );
    }
  }

  /**
   * Verify that the first bytes of the file match known magic byte signatures
   * for the declared MIME type. Returns true if verified or if the type has
   * no known signature (conservative: allow unknown types that passed MIME whitelist).
   */
  private verifyMagicBytes(buffer: Buffer, mimetype: string): boolean {
    if (buffer.length < 4) return false;

    const signatures: Record<string, number[][]> = {
      'image/jpeg': [[0xFF, 0xD8, 0xFF]],
      'image/png':  [[0x89, 0x50, 0x4E, 0x47]],
      'image/webp': [[0x52, 0x49, 0x46, 0x46]], // RIFF header
      'audio/mpeg': [[0xFF, 0xFB], [0xFF, 0xF3], [0xFF, 0xF2], [0x49, 0x44, 0x33]], // MP3 frames or ID3 tag
      'audio/wav':  [[0x52, 0x49, 0x46, 0x46]], // RIFF header
      'audio/mp4':  [[0x00, 0x00, 0x00]], // ftyp box (variable offset)
      'audio/aac':  [[0xFF, 0xF1], [0xFF, 0xF9]],
      'audio/ogg':  [[0x4F, 0x67, 0x67, 0x53]], // OggS
      'image/svg+xml': [[0x3C]], // < (XML start)
    };

    const expected = signatures[mimetype];
    if (!expected) return true; // No known signature — trust MIME whitelist

    return expected.some(sig =>
      sig.every((byte, i) => buffer[i] === byte)
    );
  }

  private getExtension(originalName: string, mimeType: string): string {
    // Try to get extension from original filename
    const ext = path.extname(originalName).toLowerCase().replace('.', '');
    if (ext && /^[a-zA-Z0-9]{1,10}$/.test(ext)) {
      return ext;
    }

    // Fallback to mime type mapping
    const mimeToExt: Record<string, string> = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
      'image/heic': 'heic',
      'image/svg+xml': 'svg',
      'audio/mpeg': 'mp3',
      'audio/wav': 'wav',
      'audio/mp4': 'm4a',
      'audio/aac': 'aac',
      'audio/ogg': 'ogg',
    };

    return mimeToExt[mimeType] || 'bin';
  }

  private generateUuid(): string {
    // Use crypto for UUID generation
    const { randomUUID } = require('crypto');
    return randomUUID();
  }

  private mapToResponse(media: {
    id: string;
    surveyId: string;
    type: MediaType;
    fileName: string;
    mimeType: string;
    size: number;
    createdAt: Date;
    updatedAt: Date;
  }): MediaResponseDto {
    return {
      id: media.id,
      surveyId: media.surveyId,
      type: media.type,
      fileName: media.fileName,
      mimeType: media.mimeType,
      size: media.size,
      url: this.urlBuilder.build('/media', media.id, 'file'),
      createdAt: media.createdAt,
      updatedAt: media.updatedAt,
    };
  }
}
