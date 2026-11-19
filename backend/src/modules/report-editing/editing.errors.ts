import { HttpException, HttpStatus } from '@nestjs/common';

/** Error codes of the client spec v1.3, section 16. The code is returned in the `error` field. */
export type EditingErrorCode =
  | 'ACTIVE_LINK_EXISTS'
  | 'LINK_EXPIRED'
  | 'LINK_REVOKED'
  | 'LINK_INVALID'
  | 'REPORT_FINALISED'
  | 'VERSION_CONFLICT'
  | 'FORBIDDEN'
  | 'VALIDATION_ERROR'
  | 'NOT_FOUND'
  | 'CSRF_INVALID'
  | 'INVALID_STATE'
  | 'AI_UNAVAILABLE'
  | 'FILE_INVALID'
  | 'FILE_TOO_LARGE'
  | 'FILE_EXISTS';

export function editingError(status: HttpStatus, code: EditingErrorCode, message: string, details?: unknown): HttpException {
  return new HttpException({ error: code, message, ...(details !== undefined ? { details } : {}) }, status);
}

export const Errors = {
  activeLinkExists: () => editingError(HttpStatus.CONFLICT, 'ACTIVE_LINK_EXISTS', 'A live edit link already exists for this report'),
  linkExpired: () => editingError(HttpStatus.GONE, 'LINK_EXPIRED', 'This link has expired. Please contact the report owner.'),
  linkRevoked: () => editingError(HttpStatus.GONE, 'LINK_REVOKED', 'This link is no longer active. Please contact the report owner.'),
  linkInvalid: () => editingError(HttpStatus.NOT_FOUND, 'LINK_INVALID', 'This link is not valid. Please contact the report owner.'),
  finalised: () => editingError(HttpStatus.FORBIDDEN, 'REPORT_FINALISED', 'This report has been finalised and can no longer be edited'),
  conflict: (serverVersion: number) =>
    editingError(HttpStatus.CONFLICT, 'VERSION_CONFLICT', 'The report has newer changes. Reload the latest version.', { serverVersion }),
  forbidden: () => editingError(HttpStatus.FORBIDDEN, 'FORBIDDEN', 'You do not have permission for this action'),
  notFound: () => editingError(HttpStatus.NOT_FOUND, 'NOT_FOUND', 'Report not found'),
  validation: (message: string, path: string) => editingError(HttpStatus.BAD_REQUEST, 'VALIDATION_ERROR', message, { path }),
  aiUnavailable: (message = 'The AI assistant is not available right now. Your report is unchanged; please edit it by hand or try again later.') =>
    editingError(HttpStatus.SERVICE_UNAVAILABLE, 'AI_UNAVAILABLE', message),
  fileInvalid: (message: string) => editingError(HttpStatus.UNPROCESSABLE_ENTITY, 'FILE_INVALID', message),
  fileTooLarge: (maxMb: number) => editingError(HttpStatus.PAYLOAD_TOO_LARGE, 'FILE_TOO_LARGE', `The file is larger than ${maxMb} MB`),
  fileExists: (message: string, details?: unknown) => editingError(HttpStatus.CONFLICT, 'FILE_EXISTS', message, details),
  csrf: () => editingError(HttpStatus.FORBIDDEN, 'CSRF_INVALID', 'Missing or wrong CSRF token'),
};
