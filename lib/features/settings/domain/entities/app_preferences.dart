import 'package:equatable/equatable.dart';

/// App-wide user preferences stored locally.
class AppPreferences extends Equatable {
  const AppPreferences({
    this.themeMode = ThemePreference.system,
    this.useDynamicColors = true,
    this.enableHapticFeedback = true,
    this.enableSounds = false,
    this.defaultSurveyType = 'inspection',
    this.autoSaveInterval = 30,
    this.showCompletionAnimations = true,
    this.compactMode = false,
    this.enableOfflineMode = true,
    this.syncOnWifiOnly = false,
    this.keepScreenAwake = false,
    this.enableBiometricLock = false,
    this.autoLockTimeout = 5,
    this.showSyncStatus = true,
  });

  /// Theme mode preference
  final ThemePreference themeMode;

  /// Use Material You dynamic colors
  final bool useDynamicColors;

  /// Enable haptic feedback on interactions
  final bool enableHapticFeedback;

  /// Enable sound effects
  final bool enableSounds;

  /// Default survey type when creating new surveys
  final String defaultSurveyType;

  /// Auto-save interval in seconds (0 = disabled)
  final int autoSaveInterval;

  /// Show animations on completion
  final bool showCompletionAnimations;

  /// Use compact mode for lists
  final bool compactMode;

  /// Enable offline mode capabilities
  final bool enableOfflineMode;

  /// Only sync when on WiFi
  final bool syncOnWifiOnly;

  /// Keep screen awake during surveys
  final bool keepScreenAwake;

  /// Enable biometric lock
  final bool enableBiometricLock;

  /// Auto-lock timeout in minutes (0 = disabled)
  final int autoLockTimeout;

  /// Show sync status in bottom bar
  final bool showSyncStatus;

  AppPreferences copyWith({
    ThemePreference? themeMode,
    bool? useDynamicColors,
    bool? enableHapticFeedback,
    bool? enableSounds,
    String? defaultSurveyType,
    int? autoSaveInterval,
    bool? showCompletionAnimations,
    bool? compactMode,
    bool? enableOfflineMode,
    bool? syncOnWifiOnly,
    bool? keepScreenAwake,
    bool? enableBiometricLock,
    int? autoLockTimeout,
    bool? showSyncStatus,
  }) => AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableSounds: enableSounds ?? this.enableSounds,
      defaultSurveyType: defaultSurveyType ?? this.defaultSurveyType,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      showCompletionAnimations:
          showCompletionAnimations ?? this.showCompletionAnimations,
      compactMode: compactMode ?? this.compactMode,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      enableBiometricLock: enableBiometricLock ?? this.enableBiometricLock,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      showSyncStatus: showSyncStatus ?? this.showSyncStatus,
    );

  @override
  List<Object?> get props => [
        themeMode,
        useDynamicColors,
        enableHapticFeedback,
        enableSounds,
        defaultSurveyType,
        autoSaveInterval,
        showCompletionAnimations,
        compactMode,
        enableOfflineMode,
        syncOnWifiOnly,
        keepScreenAwake,
        enableBiometricLock,
        autoLockTimeout,
        showSyncStatus,
      ];
}

/// Theme preference options
enum ThemePreference {
  system('System'),
  light('Light'),
  dark('Dark');

  const ThemePreference(this.label);
  final String label;
}
