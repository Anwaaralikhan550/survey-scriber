/**
 * Storage Service Interface
 * Abstracts file storage for media uploads
 * Implementations: LocalStorageService (default), S3StorageService (future)
 */
export interface StorageService {
  /**
   * Store a file and return the storage path
   * @param surveyId - Survey UUID for path organization
   * @param fileId - Unique file UUID
   * @param buffer - File content
   * @param extension - File extension (e.g., 'jpg', 'mp3')
   * @returns Relative storage path
   */
  store(surveyId: string, fileId: string, buffer: Buffer, extension: string): Promise<string>;

  /**
   * Retrieve a file by its storage path
   * @param storagePath - Relative path from store()
   * @returns File buffer
   * @throws NotFoundException if file doesn't exist
   */
  retrieve(storagePath: string): Promise<Buffer>;

  /**
   * Delete a file by its storage path
   * @param storagePath - Relative path from store()
   * @returns true if deleted, false if not found
   */
  delete(storagePath: string): Promise<boolean>;

  /**
   * Check if a file exists
   * @param storagePath - Relative path from store()
   */
  exists(storagePath: string): Promise<boolean>;

  /**
   * Get the full absolute path for a storage path
   * Used for streaming files
   */
  getAbsolutePath(storagePath: string): string;
}

export const STORAGE_SERVICE = 'STORAGE_SERVICE';
