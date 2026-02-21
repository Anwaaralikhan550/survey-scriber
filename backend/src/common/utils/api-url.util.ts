import { ConfigService } from '@nestjs/config';

/**
 * API URL Builder Utility
 *
 * Centralizes URL construction to avoid hardcoded paths like '/api/v1/...'
 * throughout the codebase. Uses configured API_PREFIX and API_VERSION.
 *
 * Usage:
 *   const urlBuilder = new ApiUrlBuilder(configService);
 *   const url = urlBuilder.build('/auth/profile/image', storagePath);
 *   // Returns: /api/v1/auth/profile/image/profiles/userId/file.jpg
 */
export class ApiUrlBuilder {
  private readonly prefix: string;
  private readonly version: string;

  constructor(configService: ConfigService) {
    this.prefix = configService.get<string>('API_PREFIX', 'api');
    this.version = configService.get<string>('API_VERSION', '1');
  }

  /**
   * Build a full API URL path
   * @param path - The endpoint path (e.g., '/auth/profile/image')
   * @param segments - Additional path segments to append
   * @returns Full URL path (e.g., '/api/v1/auth/profile/image/...')
   */
  build(path: string, ...segments: string[]): string {
    const basePath = `/${this.prefix}/v${this.version}${path}`;
    if (segments.length === 0) {
      return basePath;
    }
    return `${basePath}/${segments.join('/')}`;
  }

  /**
   * Get the base API prefix (e.g., '/api/v1')
   */
  getBasePrefix(): string {
    return `/${this.prefix}/v${this.version}`;
  }
}

/**
 * Static helper for cases where ConfigService is not available.
 * Uses default values - prefer ApiUrlBuilder when ConfigService is accessible.
 *
 * @deprecated Use ApiUrlBuilder with ConfigService for production code
 */
export function buildApiUrl(path: string, ...segments: string[]): string {
  const basePath = `/api/v1${path}`;
  if (segments.length === 0) {
    return basePath;
  }
  return `${basePath}/${segments.join('/')}`;
}
