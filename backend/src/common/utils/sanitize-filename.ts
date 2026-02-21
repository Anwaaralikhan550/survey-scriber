/**
 * Sanitizes a filename to prevent XSS and header injection attacks.
 * Removes special characters, replaces spaces with underscores, and limits length.
 */
export function sanitizeFilename(filename: string): string {
  return filename
    .replace(/[^a-zA-Z0-9\s._-]/g, '') // Allow only alphanumeric, spaces, dots, underscores, hyphens
    .replace(/\s+/g, '_') // Replace spaces with underscores
    .replace(/\.{2,}/g, '.') // Prevent directory traversal via multiple dots
    .substring(0, 100); // Limit length
}
