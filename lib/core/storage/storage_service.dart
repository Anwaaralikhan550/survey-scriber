import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import 'storage_keys.dart';

/// Storage service that uses:
/// - flutter_secure_storage for sensitive data (tokens)
/// - SharedPreferences for non-sensitive data (preferences)
/// - Hive for complex settings
abstract final class StorageService {
  static late SharedPreferences _prefs;
  static late Box<dynamic> _settingsBox;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // In-memory cache for tokens (avoid async calls on every request)
  static String? _cachedAuthToken;
  static String? _cachedRefreshToken;

  // Initialization flag + mutex to prevent concurrent init() calls
  static bool _isInitialized = false;
  static Completer<void>? _initCompleter;

  /// Check if storage service has been initialized
  static bool get isInitialized => _isInitialized;

  // Legacy key for migration from SharedPreferences
  static const String _legacyRefreshTokenKey = 'refresh_token';

  static Future<void> init() async {
    if (_isInitialized) return;

    // If another init() is already in progress, wait for it instead of running a second one
    if (_initCompleter != null) {
      AppLogger.d('StorageService', 'init() already in progress, waiting...');
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      AppLogger.d('StorageService', 'Initializing storage service');
      _prefs = await SharedPreferences.getInstance();
      _settingsBox = await Hive.openBox<dynamic>('settings');

      // Pre-load tokens into memory cache from secure storage
      _cachedAuthToken = await _secureStorage.read(key: StorageKeys.authToken);
      _cachedRefreshToken = await _secureStorage.read(key: StorageKeys.refreshToken);

      // MIGRATION: Check for refresh token in old SharedPreferences location
      if (_cachedRefreshToken == null) {
        final legacyRefreshToken = _prefs.getString(_legacyRefreshTokenKey);
        if (legacyRefreshToken != null && legacyRefreshToken.isNotEmpty) {
          AppLogger.d('StorageService', 'Migrating refresh token from SharedPreferences to secure storage');
          await setRefreshToken(legacyRefreshToken);
          await _prefs.remove(_legacyRefreshTokenKey);
          AppLogger.d('StorageService', 'Migration complete');
        }
      }

      // BACKEND SWITCH DETECTION: Clear tokens if baseUrl changed
      // This prevents stale tokens from a different backend causing 401 errors
      await _handleBaseUrlChange();

      _isInitialized = true;
      _initCompleter!.complete();
      AppLogger.d('StorageService', 'Storage initialized: '
          'accessToken=${_cachedAuthToken != null ? "exists" : "null"}, '
          'refreshToken=${_cachedRefreshToken != null ? "exists" : "null"}');
    } catch (e, st) {
      AppLogger.e('StorageService', 'init() failed: $e\n$st');
      _initCompleter!.completeError(e, st);
      rethrow;
    } finally {
      _initCompleter = null;
    }
  }

  static SharedPreferences get prefs => _prefs;
  static Box<dynamic> get settingsBox => _settingsBox;

  // Theme preference (non-sensitive - SharedPreferences)
  static bool get isDarkMode => _prefs.getBool(StorageKeys.isDarkMode) ?? false;

  static Future<bool> setDarkMode({required bool value}) =>
      _prefs.setBool(StorageKeys.isDarkMode, value);

  // Auth token - SECURE STORAGE
  static String? get authToken => _cachedAuthToken;

  static Future<void> setAuthToken(String? token) async {
    _cachedAuthToken = token;
    if (token == null) {
      await _secureStorage.delete(key: StorageKeys.authToken);
    } else {
      await _secureStorage.write(key: StorageKeys.authToken, value: token);
    }
  }

  // Refresh token - SECURE STORAGE
  static String? get refreshToken => _cachedRefreshToken;

  static Future<void> setRefreshToken(String? token) async {
    _cachedRefreshToken = token;
    if (token == null) {
      await _secureStorage.delete(key: StorageKeys.refreshToken);
    } else {
      await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
    }
  }

  // Client portal access token - SECURE STORAGE
  static Future<String?> getClientAccessToken() async => _secureStorage.read(key: StorageKeys.clientAccessToken);

  static Future<void> setClientAccessToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: StorageKeys.clientAccessToken);
    } else {
      await _secureStorage.write(key: StorageKeys.clientAccessToken, value: token);
    }
  }

  // Client portal refresh token - SECURE STORAGE
  static Future<String?> getClientRefreshToken() async => _secureStorage.read(key: StorageKeys.clientRefreshToken);

  static Future<void> setClientRefreshToken(String? token) async {
    if (token == null) {
      await _secureStorage.delete(key: StorageKeys.clientRefreshToken);
    } else {
      await _secureStorage.write(key: StorageKeys.clientRefreshToken, value: token);
    }
  }

  // Clear client portal auth data
  static Future<void> clearClientAuthData() async {
    await _secureStorage.delete(key: StorageKeys.clientAccessToken);
    await _secureStorage.delete(key: StorageKeys.clientRefreshToken);
  }

  // User ID (non-sensitive - SharedPreferences)
  static String? get userId => _prefs.getString(StorageKeys.userId);

  static Future<bool> setUserId(String? id) {
    if (id == null) {
      return _prefs.remove(StorageKeys.userId);
    }
    return _prefs.setString(StorageKeys.userId, id);
  }

  // Onboarding completed (non-sensitive - SharedPreferences)
  static bool get isOnboardingCompleted =>
      _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;

  static Future<bool> setOnboardingCompleted({required bool value}) =>
      _prefs.setBool(StorageKeys.onboardingCompleted, value);

  // Last sync timestamp (non-sensitive - SharedPreferences)
  static DateTime? get lastSyncTime {
    final timestamp = _prefs.getInt(StorageKeys.lastSyncTimestamp);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  static Future<bool> setLastSyncTime(DateTime? time) {
    if (time == null) {
      return _prefs.remove(StorageKeys.lastSyncTimestamp);
    }
    return _prefs.setInt(
      StorageKeys.lastSyncTimestamp,
      time.millisecondsSinceEpoch,
    );
  }

  // Last pull timestamp for sync pull cursor (non-sensitive - SharedPreferences)
  static String? get lastPullTimestamp =>
      _prefs.getString(StorageKeys.lastPullTimestamp);

  static Future<bool> setLastPullTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null) {
      return _prefs.remove(StorageKeys.lastPullTimestamp);
    }
    return _prefs.setString(StorageKeys.lastPullTimestamp, isoTimestamp);
  }

  // Clear all data (for logout)
  static Future<void> clearAll() async {
    // Clear secure storage (tokens)
    _cachedAuthToken = null;
    _cachedRefreshToken = null;
    await _secureStorage.deleteAll();

    // Clear preferences
    await _prefs.clear();

    // Clear Hive settings
    await _settingsBox.clear();
  }

  // Clear only auth data (for session expiry)
  static Future<void> clearAuthData() async {
    _cachedAuthToken = null;
    _cachedRefreshToken = null;
    await _secureStorage.delete(key: StorageKeys.authToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
    await _prefs.remove(StorageKeys.userId);
  }

  // ============================================
  // Backend URL Change Detection
  // ============================================

  /// Detect if the API baseUrl has changed since last run.
  /// If changed, clear auth tokens to prevent stale token errors.
  static Future<void> _handleBaseUrlChange() async {
    final currentBaseUrl = AppConstants.baseUrl;
    final lastUsedBaseUrl = _prefs.getString(StorageKeys.lastUsedBaseUrl);

    AppLogger.d('StorageService', 'BaseUrl check: current=$currentBaseUrl, last=$lastUsedBaseUrl');

    if (lastUsedBaseUrl != null && lastUsedBaseUrl != currentBaseUrl) {
      // Backend URL changed - clear auth tokens
      AppLogger.w('StorageService',
        'Backend URL changed from $lastUsedBaseUrl to $currentBaseUrl. '
        'Clearing stale auth tokens to prevent 401 errors.');

      _cachedAuthToken = null;
      _cachedRefreshToken = null;
      await _secureStorage.delete(key: StorageKeys.authToken);
      await _secureStorage.delete(key: StorageKeys.refreshToken);
      await _prefs.remove(StorageKeys.userId);
    }

    // Always update the last used base URL
    await _prefs.setString(StorageKeys.lastUsedBaseUrl, currentBaseUrl);
  }

  // ============================================
  // Cache & Storage Clearing
  // ============================================

  /// Clear cached files (images, temporary files).
  /// Does not affect auth tokens, user data, or settings.
  static Future<void> clearCache() async {
    AppLogger.d('StorageService', 'Clearing cache');
    try {
      // Clear app cache directory
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await _clearDirectory(cacheDir);
      }

      // Also clear application cache if available
      try {
        final appCacheDir = await getApplicationCacheDirectory();
        if (await appCacheDir.exists()) {
          await _clearDirectory(appCacheDir);
        }
      } catch (e) {
        // getApplicationCacheDirectory might not be available on all platforms
        AppLogger.d('StorageService', 'App cache directory not available: $e');
      }

      AppLogger.d('StorageService', 'Cache cleared successfully');
    } catch (e) {
      AppLogger.e('StorageService', 'Failed to clear cache: $e');
      rethrow;
    }
  }

  /// Clear all local storage including database rows, cache, Hive,
  /// SharedPreferences, and secure storage.
  ///
  /// This is a destructive operation — the user will need to log in again.
  ///
  /// [database] is used to delete all rows via [deleteEverything()].
  /// The Drift connection is intentionally kept alive so that the
  /// [appDatabaseProvider] singleton remains valid — closing it would leave
  /// a dead isolate channel that crashes on any subsequent query.
  static Future<void> clearAllStorage({AppDatabase? database}) async {
    AppLogger.d('StorageService', 'Clearing all storage');
    try {
      // 1. Wipe all Drift database rows in a transaction.
      //    Do NOT close the connection — the provider still references this
      //    instance and closing it causes:
      //    "Bad state: Tried to send Request over isolate channel, but
      //    the connection was closed!"
      if (database != null) {
        try {
          await database.deleteEverything();
          AppLogger.d('StorageService', 'Database rows cleared');
        } catch (e) {
          AppLogger.e('StorageService', 'Failed to clear database: $e');
          // Continue — we still want to clear everything else
        }
      }

      // 2. Clear cache (temp + app cache directories)
      await clearCache();

      // 3. Clear Hive boxes
      await _settingsBox.clear();

      // 4. Clear SharedPreferences
      await _prefs.clear();

      // 5. Clear secure storage (tokens)
      _cachedAuthToken = null;
      _cachedRefreshToken = null;
      await _secureStorage.deleteAll();

      // NOTE: App documents/support directories are NOT deleted.
      // The SQLite database file lives there and must remain intact so the
      // still-open Drift connection can function.  deleteEverything() already
      // wiped all data — the file is just an empty schema.

      AppLogger.d('StorageService', 'All storage cleared successfully');
    } catch (e) {
      AppLogger.e('StorageService', 'Failed to clear all storage: $e');
      rethrow;
    }
  }

  /// Helper to clear all files in a directory without deleting the directory itself.
  static Future<void> _clearDirectory(Directory dir) async {
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      try {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      } catch (e) {
        // Log but continue - some files might be in use
        AppLogger.d('StorageService', 'Could not delete ${entity.path}: $e');
      }
    }
  }
}
