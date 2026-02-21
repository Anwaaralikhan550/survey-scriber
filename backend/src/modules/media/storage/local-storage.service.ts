import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs/promises';
import * as fsSync from 'fs';
import * as path from 'path';
import { StorageService } from './storage.interface';

/**
 * Local filesystem storage implementation
 * Stores files in: {MEDIA_LOCAL_ROOT}/{surveyId}/{fileId}.{ext}
 *
 * Security considerations:
 * - Path traversal prevention via UUID validation
 * - Files stored outside web root
 * - Served only through authenticated API endpoints
 */
@Injectable()
export class LocalStorageService implements StorageService {
  private readonly logger = new Logger(LocalStorageService.name);
  private readonly rootPath: string;

  constructor(private readonly configService: ConfigService) {
    const mediaRoot = this.configService.get<string>('MEDIA_LOCAL_ROOT', 'storage');
    // Resolve to absolute path from project root
    this.rootPath = path.resolve(process.cwd(), mediaRoot);
    this.ensureRootExists();
  }

  private ensureRootExists(): void {
    if (!fsSync.existsSync(this.rootPath)) {
      fsSync.mkdirSync(this.rootPath, { recursive: true });
      this.logger.log('Created media storage directory: ' + this.rootPath);
    }
  }

  /**
   * Validate that a path component is a valid UUID to prevent traversal attacks
   */
  private isValidUuid(value: string): boolean {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    return uuidRegex.test(value);
  }

  /**
   * Validate file extension (alphanumeric only, max 10 chars)
   */
  private isValidExtension(ext: string): boolean {
    return /^[a-zA-Z0-9]{1,10}$/.test(ext);
  }

  /**
   * Validate directory path format for security.
   * Allows: UUID, or prefix/UUID (e.g., "profiles/uuid-here")
   * Prevents: path traversal, invalid characters
   */
  private isValidDirectoryPath(dirPath: string): boolean {
    // Prevent path traversal
    if (dirPath.includes('..') || dirPath.startsWith('/') || dirPath.startsWith('\\')) {
      return false;
    }

    const segments = dirPath.split('/');

    // Last segment must be a valid UUID (the actual ID)
    const lastSegment = segments[segments.length - 1];
    if (!this.isValidUuid(lastSegment)) {
      return false;
    }

    // Prefix segments (if any) must be alphanumeric with underscores/hyphens
    const prefixSegments = segments.slice(0, -1);
    const validPrefixPattern = /^[a-zA-Z0-9_-]+$/;
    for (const segment of prefixSegments) {
      if (!validPrefixPattern.test(segment)) {
        return false;
      }
    }

    return true;
  }

  async store(
    directory: string,
    fileId: string,
    buffer: Buffer,
    extension: string,
  ): Promise<string> {
    // Security: Validate inputs to prevent path traversal
    if (!this.isValidDirectoryPath(directory)) {
      throw new BadRequestException('Invalid directory format');
    }
    if (!this.isValidUuid(fileId)) {
      throw new BadRequestException('Invalid fileId format');
    }
    if (!this.isValidExtension(extension)) {
      throw new BadRequestException('Invalid file extension');
    }

    const targetDir = path.join(this.rootPath, directory);
    const fileName = fileId + '.' + extension;
    const filePath = path.join(targetDir, fileName);

    // Create directory if it doesn't exist
    await fs.mkdir(targetDir, { recursive: true });

    // Write file
    await fs.writeFile(filePath, buffer);

    // Return relative path (for storage in DB)
    const storagePath = directory + '/' + fileName;
    this.logger.log('Stored file: ' + storagePath + ' (' + buffer.length + ' bytes)');

    return storagePath;
  }

  async retrieve(storagePath: string): Promise<Buffer> {
    const absolutePath = this.getAbsolutePath(storagePath);

    try {
      return await fs.readFile(absolutePath);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'ENOENT') {
        throw new NotFoundException('File not found: ' + storagePath);
      }
      throw error;
    }
  }

  async delete(storagePath: string): Promise<boolean> {
    const absolutePath = this.getAbsolutePath(storagePath);

    try {
      await fs.unlink(absolutePath);
      this.logger.log('Deleted file: ' + storagePath);
      return true;
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'ENOENT') {
        this.logger.warn('File not found for deletion: ' + storagePath);
        return false;
      }
      throw error;
    }
  }

  async exists(storagePath: string): Promise<boolean> {
    const absolutePath = this.getAbsolutePath(storagePath);
    try {
      await fs.access(absolutePath);
      return true;
    } catch {
      return false;
    }
  }

  getAbsolutePath(storagePath: string): string {
    // Security: Ensure the path doesn't escape the root
    const normalizedPath = path.normalize(storagePath);
    if (normalizedPath.includes('..')) {
      throw new BadRequestException('Invalid storage path');
    }

    return path.join(this.rootPath, normalizedPath);
  }
}
