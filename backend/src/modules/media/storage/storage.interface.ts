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
   * Store a file atomically and prove it: the bytes go to a temporary file, are renamed into place, and the stored
   * size and SHA-256 are read back and compared with what was sent. Used for report documents (Remote Editor v1.4).
   * @returns relative storage path, size and lower-case hex SHA-256
   * @throws if the stored file does not match what was written (nothing is left behind)
   */
  storeVerified(directory: string, fileId: string, buffer: Buffer, extension: string): Promise<{ storagePath: string; size: number; sha256: string }>;

  /** SHA-256 (lower-case hex) of a stored file, read from disk. */
  checksum(storagePath: string): Promise<string>;

  /**
   * Get the full absolute path for a storage path
   * Used for streaming files
   */
  getAbsolutePath(storagePath: string): string;
}

export const STORAGE_SERVICE = 'STORAGE_SERVICE';
