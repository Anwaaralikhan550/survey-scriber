import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import '../storage/storage_service.dart';
import 'api_interceptors.dart';
import 'certificate_pinning.dart';
import 'not_found_handler.dart';
import 'session_expiry_handler.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // SECURITY: Configure certificate pinning for production HTTPS connections.
  // This MUST be called before adding interceptors to ensure the HTTP adapter is set.
  // Pinning is automatically disabled for development (debug builds, HTTP URLs).
  CertificatePinning.configure(dio);

  // Link NotFoundHandler keys to SessionExpiryHandler for shared snackbar/navigator access
  NotFoundHandler.instance.scaffoldMessengerKey =
      SessionExpiryHandler.instance.scaffoldMessengerKey;
  NotFoundHandler.instance.navigatorKey =
      SessionExpiryHandler.instance.navigatorKey;

  // Add interceptors in order:
  // 1. AuthInterceptor - adds auth token to requests
  // 2. TokenRefreshInterceptor - handles 401 and refreshes tokens
  // 3. NotFoundInterceptor - handles 404 with user feedback
  // 4. LoggingInterceptor - logs requests/responses
  // 5. ErrorInterceptor - handles remaining errors
  dio.interceptors.addAll([
    AuthInterceptor(),
    TokenRefreshInterceptor(
      dio: dio,
      onTokenRefreshFailed: SessionExpiryHandler.instance.handleSessionExpired,
    ),
    NotFoundInterceptor(),
    LoggingInterceptor(),
    ErrorInterceptor(),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Dio get dio => _dio;

  /// Sanitizes API path to prevent leading-slash issues with Dio.
  ///
  /// When baseUrl has a path component (e.g., "http://api.com/v1/"),
  /// a leading slash in the path causes Dio to ignore the baseUrl path.
  /// Example: baseUrl "http://api.com/v1/" + path "/users" = "http://api.com/users" (WRONG)
  ///
  /// This method strips leading slashes and asserts in debug mode.
  String _sanitizePath(String path) {
    assert(
      !path.startsWith('/'),
      'API path "$path" should not start with "/" - this causes baseUrl path to be ignored. '
      'Use "${ path.substring(1)}" instead.',
    );
    return path.startsWith('/') ? path.substring(1) : path;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        _sanitizePath(path),
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        _sanitizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        _sanitizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        _sanitizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        _sanitizePath(path),
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Request timed out');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return _handleResponseError(e.response);
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request cancelled');
      default:
        return ServerException(
          message: e.message ?? 'An unexpected error occurred',
        );
    }
  }

  Exception _handleResponseError(Response<dynamic>? response) {
    if (response == null) {
      return const ServerException(message: 'No response from server');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    // Extract error message from response body.
    // Handles: JSON with 'details' array, 'message' string/array, or non-JSON.
    final message = _extractErrorMessage(data);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: message ?? 'Bad request',
          fieldErrors:
              data is Map<String, dynamic>
                  ? (data['errors'] as Map<String, dynamic>?)?.map(
                    (key, value) => MapEntry(key, value.toString()),
                  )
                  : null,
        );
      case 401:
        return AuthException(message: message ?? 'Authentication required');
      case 403:
        return const UnauthorizedException();
      case 404:
        return NotFoundException(message: message ?? 'Resource not found');
      case 409:
        return ServerException(
          message: message ?? 'Conflict',
          statusCode: statusCode,
        );
      case 413:
        return ValidationException(
          message: message ?? 'Request payload too large. Reduce tree size and retry.',
        );
      case 429:
        // Parse Retry-After from header or response body
        final retryAfterHeader = response.headers.value('retry-after');
        var retryAfterSeconds =
            retryAfterHeader != null ? int.tryParse(retryAfterHeader) : null;
        // Fallback: custom rate-limit guards include retryAfter in body
        if (retryAfterSeconds == null && data is Map<String, dynamic>) {
          final bodyRetryAfter = data['retryAfter'];
          if (bodyRetryAfter is int) {
            retryAfterSeconds = bodyRetryAfter;
          }
        }
        return RateLimitException(
          message: message ?? 'Too many requests',
          retryAfterSeconds: retryAfterSeconds,
        );
      case 422:
        return ValidationException(message: message ?? 'Validation failed');
      case 500:
      case 502:
      case 503:
        return ServerException(
          message: message ?? 'Server error',
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: message ?? 'An error occurred',
          statusCode: statusCode,
        );
    }
  }

  /// Extracts a human-readable error message from a response body.
  ///
  /// Supports NestJS response formats:
  /// - `{ "details": ["err1", "err2"] }` (ValidationPipe array)
  /// - `{ "message": "some error" }` (BadRequestException string)
  /// - `{ "message": ["err1", "err2"] }` (raw ValidationPipe before filter)
  /// - Plain string body (Express/body-parser HTML error)
  static String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // 1. Check 'details' array (HttpExceptionFilter normalised form)
      final details = data['details'];
      if (details is List && details.isNotEmpty) {
        return details.map((e) => e.toString()).join('\n');
      }

      // 2. Check 'message' — can be String or List<String>
      final msg = data['message'];
      if (msg is List && msg.isNotEmpty) {
        return msg.map((e) => e.toString()).join('\n');
      }
      if (msg is String && msg.isNotEmpty) {
        return msg;
      }
    }

    // 3. Non-JSON body (e.g. Express HTML error page) — extract text
    if (data is String && data.isNotEmpty) {
      // Strip HTML tags if present
      final stripped = data.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
      if (stripped.length <= 200) return stripped;
      return '${stripped.substring(0, 200)}…';
    }

    return null;
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageService.authToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
