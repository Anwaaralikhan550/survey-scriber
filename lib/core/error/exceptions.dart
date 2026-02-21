class ServerException implements Exception {
  const ServerException({this.message, this.statusCode, this.code});

  final String? message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  const CacheException({this.message});

  final String? message;

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection'});

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ValidationException implements Exception {
  const ValidationException({this.message, this.fieldErrors});

  final String? message;
  final Map<String, String>? fieldErrors;

  @override
  String toString() => 'ValidationException: $message';
}

class AuthException implements Exception {
  const AuthException({this.message = 'Authentication failed', this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException: $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException({this.message = 'Unauthorized access'});

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

class RateLimitException implements Exception {
  const RateLimitException({
    this.message = 'Too many requests',
    this.retryAfterSeconds,
  });

  final String message;

  /// Seconds to wait before retrying, parsed from the Retry-After header.
  /// Null if the server did not provide the header.
  final int? retryAfterSeconds;

  @override
  String toString() =>
      'RateLimitException: $message (retryAfter: ${retryAfterSeconds}s)';
}

class NotFoundException implements Exception {
  const NotFoundException({
    this.message = 'Resource not found',
    this.resourceType,
    this.resourceId,
  });

  final String message;

  /// Type of resource that was not found (e.g., 'booking', 'survey', 'report')
  final String? resourceType;

  /// ID of the resource that was not found
  final String? resourceId;

  @override
  String toString() =>
      'NotFoundException: $message (type: $resourceType, id: $resourceId)';
}
