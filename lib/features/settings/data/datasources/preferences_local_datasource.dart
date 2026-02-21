import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_preferences.dart';

/// Keys for SharedPreferences storage
abstract final class PreferenceKeys {
  static const String themeMode = 'pref_theme_mode';
  static const String useDynamicColors = 'pref_use_dynamic_colors';
  static const String enableHapticFeedback = 'pref_enable_haptic_feedback';
  static const String enableSounds = 'pref_enable_sounds';
  static const String defaultSurveyType = 'pref_default_survey_type';
  static const String autoSaveInterval = 'pref_auto_save_interval';
  static const String showCompletionAnimations =
      'pref_show_completion_animations';
  static const String compactMode = 'pref_compact_mode';
  static const String enableOfflineMode = 'pref_enable_offline_mode';
  static const String syncOnWifiOnly = 'pref_sync_on_wifi_only';
  static const String keepScreenAwake = 'pref_keep_screen_awake';
  static const String enableBiometricLock = 'pref_enable_biometric_lock';
  static const String autoLockTimeout = 'pref_auto_lock_timeout';
  static const String showSyncStatus = 'pref_show_sync_status';
}

/// Local data source for app preferences using SharedPreferences.
class PreferencesLocalDataSource {
  PreferencesLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// Load all preferences from local storage.
  AppPreferences loadPreferences() => AppPreferences(
      themeMode: _loadThemeMode(),
      useDynamicColors:
          _prefs.getBool(PreferenceKeys.useDynamicColors) ?? true,
      enableHapticFeedback:
          _prefs.getBool(PreferenceKeys.enableHapticFeedback) ?? true,
      enableSounds: _prefs.getBool(PreferenceKeys.enableSounds) ?? false,
      defaultSurveyType:
          _prefs.getString(PreferenceKeys.defaultSurveyType) ?? 'inspection',
      autoSaveInterval: _prefs.getInt(PreferenceKeys.autoSaveInterval) ?? 30,
      showCompletionAnimations:
          _prefs.getBool(PreferenceKeys.showCompletionAnimations) ?? true,
      compactMode: _prefs.getBool(PreferenceKeys.compactMode) ?? false,
      enableOfflineMode:
          _prefs.getBool(PreferenceKeys.enableOfflineMode) ?? true,
      syncOnWifiOnly: _prefs.getBool(PreferenceKeys.syncOnWifiOnly) ?? false,
      keepScreenAwake: _prefs.getBool(PreferenceKeys.keepScreenAwake) ?? false,
      enableBiometricLock:
          _prefs.getBool(PreferenceKeys.enableBiometricLock) ?? false,
      autoLockTimeout: _prefs.getInt(PreferenceKeys.autoLockTimeout) ?? 5,
      showSyncStatus: _prefs.getBool(PreferenceKeys.showSyncStatus) ?? true,
    );

  ThemePreference _loadThemeMode() {
    final value = _prefs.getString(PreferenceKeys.themeMode);
    return ThemePreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemePreference.system,
    );
  }

  /// Save a single preference.
  Future<void> setThemeMode(ThemePreference mode) async {
    await _prefs.setString(PreferenceKeys.themeMode, mode.name);
  }

  Future<void> setUseDynamicColors(bool value) async {
    await _prefs.setBool(PreferenceKeys.useDynamicColors, value);
  }

  Future<void> setEnableHapticFeedback(bool value) async {
    await _prefs.setBool(PreferenceKeys.enableHapticFeedback, value);
  }

  Future<void> setEnableSounds(bool value) async {
    await _prefs.setBool(PreferenceKeys.enableSounds, value);
  }

  Future<void> setDefaultSurveyType(String value) async {
    await _prefs.setString(PreferenceKeys.defaultSurveyType, value);
  }

  Future<void> setAutoSaveInterval(int value) async {
    await _prefs.setInt(PreferenceKeys.autoSaveInterval, value);
  }

  Future<void> setShowCompletionAnimations(bool value) async {
    await _prefs.setBool(PreferenceKeys.showCompletionAnimations, value);
  }

  Future<void> setCompactMode(bool value) async {
    await _prefs.setBool(PreferenceKeys.compactMode, value);
  }

  Future<void> setEnableOfflineMode(bool value) async {
    await _prefs.setBool(PreferenceKeys.enableOfflineMode, value);
  }

  Future<void> setSyncOnWifiOnly(bool value) async {
    await _prefs.setBool(PreferenceKeys.syncOnWifiOnly, value);
  }

  Future<void> setKeepScreenAwake(bool value) async {
    await _prefs.setBool(PreferenceKeys.keepScreenAwake, value);
  }

  Future<void> setEnableBiometricLock(bool value) async {
    await _prefs.setBool(PreferenceKeys.enableBiometricLock, value);
  }

  Future<void> setAutoLockTimeout(int value) async {
    await _prefs.setInt(PreferenceKeys.autoLockTimeout, value);
  }

  Future<void> setShowSyncStatus(bool value) async {
    await _prefs.setBool(PreferenceKeys.showSyncStatus, value);
  }

  /// Clear all preferences (reset to defaults).
  Future<void> clearAll() async {
    for (final key in [
      PreferenceKeys.themeMode,
      PreferenceKeys.useDynamicColors,
      PreferenceKeys.enableHapticFeedback,
      PreferenceKeys.enableSounds,
      PreferenceKeys.defaultSurveyType,
      PreferenceKeys.autoSaveInterval,
      PreferenceKeys.showCompletionAnimations,
      PreferenceKeys.compactMode,
      PreferenceKeys.enableOfflineMode,
      PreferenceKeys.syncOnWifiOnly,
      PreferenceKeys.keepScreenAwake,
      PreferenceKeys.enableBiometricLock,
      PreferenceKeys.autoLockTimeout,
      PreferenceKeys.showSyncStatus,
    ]) {
      await _prefs.remove(key);
    }
  }
}
