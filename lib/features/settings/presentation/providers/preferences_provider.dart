import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/preferences_local_datasource.dart';
import '../../domain/entities/app_preferences.dart';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// Provider for the preferences data source.
final preferencesDataSourceProvider = Provider<PreferencesLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesLocalDataSource(prefs);
});

/// Provider for app preferences state.
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, AppPreferences>((ref) {
  final dataSource = ref.watch(preferencesDataSourceProvider);
  return PreferencesNotifier(dataSource);
});

/// Notifier for managing app preferences state.
class PreferencesNotifier extends StateNotifier<AppPreferences> {
  PreferencesNotifier(this._dataSource)
      : super(_dataSource.loadPreferences());

  final PreferencesLocalDataSource _dataSource;

  /// Update theme mode.
  Future<void> setThemeMode(ThemePreference mode) async {
    await _dataSource.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  /// Toggle dynamic colors.
  Future<void> setUseDynamicColors(bool value) async {
    await _dataSource.setUseDynamicColors(value);
    state = state.copyWith(useDynamicColors: value);
  }

  /// Toggle haptic feedback.
  Future<void> setEnableHapticFeedback(bool value) async {
    await _dataSource.setEnableHapticFeedback(value);
    state = state.copyWith(enableHapticFeedback: value);
  }

  /// Toggle sounds.
  Future<void> setEnableSounds(bool value) async {
    await _dataSource.setEnableSounds(value);
    state = state.copyWith(enableSounds: value);
  }

  /// Set default survey type.
  Future<void> setDefaultSurveyType(String value) async {
    await _dataSource.setDefaultSurveyType(value);
    state = state.copyWith(defaultSurveyType: value);
  }

  /// Set auto-save interval.
  Future<void> setAutoSaveInterval(int seconds) async {
    await _dataSource.setAutoSaveInterval(seconds);
    state = state.copyWith(autoSaveInterval: seconds);
  }

  /// Toggle completion animations.
  Future<void> setShowCompletionAnimations(bool value) async {
    await _dataSource.setShowCompletionAnimations(value);
    state = state.copyWith(showCompletionAnimations: value);
  }

  /// Toggle compact mode.
  Future<void> setCompactMode(bool value) async {
    await _dataSource.setCompactMode(value);
    state = state.copyWith(compactMode: value);
  }

  /// Toggle offline mode.
  Future<void> setEnableOfflineMode(bool value) async {
    await _dataSource.setEnableOfflineMode(value);
    state = state.copyWith(enableOfflineMode: value);
  }

  /// Toggle WiFi-only sync.
  Future<void> setSyncOnWifiOnly(bool value) async {
    await _dataSource.setSyncOnWifiOnly(value);
    state = state.copyWith(syncOnWifiOnly: value);
  }

  /// Toggle keep screen awake.
  Future<void> setKeepScreenAwake(bool value) async {
    await _dataSource.setKeepScreenAwake(value);
    state = state.copyWith(keepScreenAwake: value);
  }

  /// Toggle biometric lock.
  Future<void> setEnableBiometricLock(bool value) async {
    await _dataSource.setEnableBiometricLock(value);
    state = state.copyWith(enableBiometricLock: value);
  }

  /// Set auto-lock timeout.
  Future<void> setAutoLockTimeout(int minutes) async {
    await _dataSource.setAutoLockTimeout(minutes);
    state = state.copyWith(autoLockTimeout: minutes);
  }

  /// Toggle sync status display.
  Future<void> setShowSyncStatus(bool value) async {
    await _dataSource.setShowSyncStatus(value);
    state = state.copyWith(showSyncStatus: value);
  }

  /// Reset all preferences to defaults.
  Future<void> resetToDefaults() async {
    await _dataSource.clearAll();
    state = const AppPreferences();
  }
}
