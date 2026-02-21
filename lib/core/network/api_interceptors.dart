import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../storage/storage_service.dart';
import 'certificate_pinning.dart';
import 'not_found_handler.dart';

/// Logger configured for environment-appropriate verbosity.
/// - Debug/Profile builds: Full logging (debug, warning, error)
/// - Release builds: Errors only (no request/response logging)
final _logger = Logger(
  level: kReleaseMode ? Level.error : Level.debug,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    noBoxingByDefault: true,
  ),
);

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Show full URI and auth header presence (NOT the token value) for debugging
    final hasAuth = options.headers['Authorization'] != null;
    _logger.d(
      'REQUEST[${options.method}] => ${options.uri} [auth=$hasAuth]',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.d(
      'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Show full URI for errors to help diagnose 404s and other URL issues
    _logger.e(
      'ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri}',
    );
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      'API Error',
      error: err.message,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }
}

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required this.dio,
    this.onTokenRefreshFailed,
  });

  final Dio dio;
  final void Function()? onTokenRefreshFailed;

  bool _isRefreshing = false;
  final List<_RequestRetry> _pendingRequests = [];

  /// Timeout for pending requests waiting on a token refresh.
  static const _pendingTimeout = Duration(seconds: 30);

  static const _authEndpoints = [
    'auth/login',
    'auth/register',
    'auth/refresh',
    'auth/logout',
    'auth/forgot-password',
    'auth/reset-password',
  ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestPath = err.requestOptions.path;

    if (response?.statusCode != 401 ||
        _authEndpoints.any(requestPath.contains)) {
      return handler.next(err);
    }

    final refreshToken = StorageService.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      _logger.w('No refresh token available - triggering graceful logout');
      // CRITICAL: No refresh token means user is logged out or session is invalid
      // Trigger graceful logout instead of throwing error to prevent 401 loops
      onTokenRefreshFailed?.call();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: 'Session expired - no refresh token available',
          type: DioExceptionType.cancel,
        ),
      );
    }

    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _pendingRequests.add(_RequestRetry(
        requestOptions: err.requestOptions,
        completer: completer,
      ),);
      try {
        final response = await completer.future.timeout(
          _pendingTimeout,
          onTimeout: () => throw TimeoutException(
            'Token refresh timed out for pending request',
            _pendingTimeout,
          ),
        );
        return handler.resolve(response);
      } catch (e) {
        return handler.next(DioException(
          requestOptions: err.requestOptions,
          error: e,
        ),);
      }
    }

    _isRefreshing = true;
    _logger.d('Starting token refresh');

    try {
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),);

      // SECURITY: Apply certificate pinning to refresh requests as well
      CertificatePinning.configure(refreshDio);

      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        'auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = refreshResponse.data;
      if (data == null) {
        throw Exception('Empty refresh response');
      }

      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        throw Exception('Invalid refresh response');
      }

      await StorageService.setAuthToken(newAccessToken);
      await StorageService.setRefreshToken(newRefreshToken);

      _logger.d('Token refresh successful');

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await dio.fetch<dynamic>(retryOptions);

      // Retry all pending requests with the new token
      final pending = List<_RequestRetry>.from(_pendingRequests);
      _pendingRequests.clear();
      _isRefreshing = false;

      for (final req in pending) {
        req.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        try {
          final response = await dio.fetch<dynamic>(req.requestOptions);
          req.completer.complete(response);
        } catch (e) {
          req.completer.completeError(e);
        }
      }

      return handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      _logger.e('Token refresh failed: ${refreshError.message}');
      await _handleRefreshFailure();
      return handler.next(err);
    } catch (e) {
      _logger.e('Token refresh error: $e');
      await _handleRefreshFailure();
      return handler.next(err);
    }
  }

  Future<void> _handleRefreshFailure() async {
    await StorageService.setAuthToken(null);
    await StorageService.setRefreshToken(null);

    for (final pending in _pendingRequests) {
      pending.completer.completeError(
        DioException(
          requestOptions: pending.requestOptions,
          message: 'Token refresh failed',
        ),
      );
    }

    _isRefreshing = false;
    _pendingRequests.clear();
    onTokenRefreshFailed?.call();
  }
}

class _RequestRetry {
  _RequestRetry({required this.requestOptions, required this.completer});
  final RequestOptions requestOptions;
  final Completer<Response<dynamic>> completer;
}

/// Interceptor that handles 404 Not Found errors globally.
/// Shows a user-friendly snackbar and optionally pops the navigation.
///
/// This interceptor extracts resource information from the URL path
/// and emits stale resource events for providers to clean up their state.
class NotFoundInterceptor extends Interceptor {
  NotFoundInterceptor({
    this.shouldPopOnNotFound = true,
  });

  /// Whether to automatically pop the current route on 404.
  /// Set to false for list screens, true for detail screens.
  final bool shouldPopOnNotFound;

  /// Patterns for extracting resource type and ID from URLs.
  /// Format: /resource-type/{id} or /resource-type/{id}/sub-resource
  static final _resourcePatterns = [
    // Booking endpoints
    RegExp('scheduling/bookings/([a-f0-9-]+)'),
    // Survey endpoints
    RegExp('surveys/([a-f0-9-]+)'),
    // Report endpoints
    RegExp('reports/([a-f0-9-]+)'),
    // Notification endpoints
    RegExp('notifications/([a-f0-9-]+)'),
    // Generic pattern for any UUID-based resource
    RegExp(r'([a-z-]+)/([a-f0-9-]+)(?:/|$)'),
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 404) {
      final resourceInfo = _extractResourceInfo(err.requestOptions.path);

      if (resourceInfo != null) {
        _logger.w(
          'Resource not found: ${resourceInfo.type}/${resourceInfo.id}',
        );

        // Handle the 404 with user feedback
        NotFoundHandler.instance.handleNotFound(
          resourceType: resourceInfo.type,
          resourceId: resourceInfo.id,
          message: _extractErrorMessage(err.response?.data),
          shouldPop: shouldPopOnNotFound,
        );
      }
    }

    // Continue with error handling chain
    handler.next(err);
  }

  /// Extracts resource type and ID from the request path.
  _ResourceInfo? _extractResourceInfo(String path) {
    // Try specific patterns first
    for (final pattern in _resourcePatterns) {
      final match = pattern.firstMatch(path);
      if (match != null) {
        if (match.groupCount >= 2) {
          // Pattern with both type and ID (generic pattern)
          return _ResourceInfo(
            type: match.group(1)!,
            id: match.group(2)!,
          );
        } else if (match.groupCount >= 1) {
          // Pattern with just ID, type from URL structure
          final pathParts = path.split('/');
          final resourceIndex = pathParts.indexOf(match.group(1)!) - 1;
          if (resourceIndex >= 0) {
            return _ResourceInfo(
              type: _normalizeResourceType(pathParts[resourceIndex]),
              id: match.group(1)!,
            );
          }
        }
      }
    }

    return null;
  }

  /// Normalizes resource type to a consistent format.
  String _normalizeResourceType(String type) {
    // Remove 'scheduling/' prefix for bookings
    if (type == 'scheduling') return 'booking';
    // Convert plural to singular
    if (type.endsWith('s')) return type.substring(0, type.length - 1);
    return type;
  }

  /// Extracts error message from response data if available.
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }
}

class _ResourceInfo {
  const _ResourceInfo({required this.type, required this.id});
  final String type;
  final String id;
}
