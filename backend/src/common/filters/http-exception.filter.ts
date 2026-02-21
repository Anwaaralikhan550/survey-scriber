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

      // Log request body in development for 4xx errors
      if (process.env.NODE_ENV !== 'production' && statusCode >= 400 && statusCode < 500 && request.body) {
        this.logger.debug(
          `[${requestId}] Request body: ${JSON.stringify(request.body)}`,
        );
      }
    }

    response.status(statusCode).json(errorResponse);
  }
}
