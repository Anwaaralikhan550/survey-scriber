abstract final class StorageKeys {
  static const String isDarkMode = 'is_dark_mode';
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String offlineQueueCount = 'offline_queue_count';
  static const String selectedLanguage = 'selected_language';

  // Client portal tokens (secure storage)
  static const String clientAccessToken = 'client_access_token';
  static const String clientRefreshToken = 'client_refresh_token';

  // Sync pull cursor
  static const String lastPullTimestamp = 'last_pull_timestamp';

  // API base URL tracking (for detecting backend changes)
  static const String lastUsedBaseUrl = 'last_used_base_url';
}
