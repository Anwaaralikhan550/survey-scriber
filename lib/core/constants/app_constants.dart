/// Authentication mode for the app
enum AuthMode {
  /// Use mock authentication (local-only, no API calls)
  mock,

  /// Use real API authentication
  api,
}

abstract final class AppConstants {
  static const String appName = 'SurveyScriber';
  static const String appVersion = '1.0.0';

  // ============================================
  // ENVIRONMENT-AGNOSTIC API CONFIGURATION
  // ============================================
  // API Base URL is now injected via build-time environment variables.
  // This enables Docker, CI/CD, and different build flavors without code changes.
  //
  // Usage Examples:
  //   # Local development (emulator)
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
  //
  //   # Local development (physical device on LAN)
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000/api/v1
  //
  //   # Production build
  //   flutter build apk (uses production URL below by default)
  //
  // Default: Production VPS URL
  // For local development, override via: --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.95.33.150:3000/api/v1',
  );
  // Ensure base URL always ends with a slash for proper path joining
  static String get baseUrl => _rawBaseUrl.endsWith('/') ? _rawBaseUrl : '$_rawBaseUrl/';

  // ============================================
  // AUTHENTICATION MODE - HARDCODED TO API
  // ============================================
  // SECURITY: Mock mode has been DISABLED.
  // All authentication MUST go through the real backend API.
  // This prevents fake logins with random credentials.
  static const AuthMode authMode = AuthMode.api;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheMaxAge = Duration(hours: 24);
  static const int maxCacheSize = 100;

  // Offline
  static const int maxOfflineQueueSize = 1000;
  static const Duration syncInterval = Duration(minutes: 15);

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 4);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 2000;

  // File Upload
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
}
