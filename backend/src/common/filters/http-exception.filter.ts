import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';

interface ErrorResponse {
  success: false;
  statusCode: number;
  message: string;
  error: string;
  details?: unknown;
  timestamp: string;
  path: string;
  requestId: string;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  /** The 4xx status of an http-errors style error (body-parser), or 0 when it is not one. */
  private clientErrorStatus(exception: unknown): number {
    if (typeof exception !== 'object' || exception === null) return 0;
    const e = exception as { status?: unknown; statusCode?: unknown; type?: unknown };
    const status = typeof e.status === 'number' ? e.status : typeof e.statusCode === 'number' ? e.statusCode : 0;
    return status >= 400 && status < 500 && typeof e.type === 'string' ? status : 0;
  }

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const requestId = (request.headers['x-request-id'] as string) || uuidv4();

    let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';
    let error = 'InternalServerError';
    let details: unknown = undefined;

    if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'string') {
        message = exceptionResponse;
      } else if (typeof exceptionResponse === 'object') {
        const responseObj = exceptionResponse as Record<string, unknown>;
        message = (responseObj.message as string) || message;
        error = (responseObj.error as string) || exception.name;
        details = responseObj.details || responseObj.errors;

        // Handle validation errors from class-validator
        if (Array.isArray(responseObj.message)) {
          message = 'Validation failed';
          details = responseObj.message;
        }
      }
    } else if (this.clientErrorStatus(exception)) {
      // Errors from the body parser (http-errors): a body that is too large or not valid JSON is the caller's mistake.
      statusCode = this.clientErrorStatus(exception) as number;
      message = statusCode === HttpStatus.PAYLOAD_TOO_LARGE ? 'The request is too large' : 'The request could not be read';
      error = statusCode === HttpStatus.PAYLOAD_TOO_LARGE ? 'PayloadTooLarge' : 'BadRequest';
    } else if (exception instanceof Error) {
      // SEC-M4: Never expose raw error messages to clients — they may contain
      // internal paths, SQL fragments, or stack details useful to attackers.
      // The real message is logged server-side for debugging.
      error = 'InternalServerError';

      // Log the real error server-side (with stack trace)
      this.logger.error(
        `Unexpected error: ${exception.message}`,
        exception.stack,
        `RequestId: ${requestId}`,
      );
    }

    const errorResponse: ErrorResponse = {
      success: false,
      statusCode,
      message,
      error,
      ...(details !== undefined ? { details } : {}),
      timestamp: new Date().toISOString(),
      path: request.url,
      requestId,
    };

    // Log error (skip 4xx in production)
    if (statusCode >= 500 || process.env.NODE_ENV !== 'production') {
      this.logger.warn(
        `[${requestId}] ${request.method} ${request.url} - ${statusCode} ${message}`,
      );

      // Log validation details for 400 errors to aid debugging
      if (statusCode === HttpStatus.BAD_REQUEST && details) {
        this.logger.warn(
          `[${requestId}] Validation details: ${JSON.stringify(details)}`,
        );
      }

      // Log request body in development for 4xx errors, except on the report editing routes: those bodies are report text and
      // comments (and tokens), which must not reach a log file in any environment.
      const carriesReportText = /\/(editor|reports)(\/|$|\?)/.test(request.url);
      if (process.env.NODE_ENV !== 'production' && statusCode >= 400 && statusCode < 500 && request.body && !carriesReportText) {
        this.logger.debug(
          `[${requestId}] Request body: ${JSON.stringify(request.body)}`,
        );
      }
    }

    response.status(statusCode).json(errorResponse);
  }
}
