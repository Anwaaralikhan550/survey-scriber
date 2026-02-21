import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/permissions/permission.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../forms/presentation/providers/forms_provider.dart';
import '../../../../core/permissions/permission_providers.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../../shared/presentation/widgets/cached_avatar.dart';
import '../../../../shared/presentation/widgets/permission_widgets.dart';
import '../../domain/entities/app_preferences.dart';
import '../providers/preferences_provider.dart';
import '../widgets/settings_section_card.dart';
import 'static_content_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.dashboard),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            _ProfileSection(),
            _AppearanceSection(),
            _SurveyPreferencesSection(),
            _SyncSection(),
            _SecuritySection(),
            _StorageSection(),
            _AdminSection(),
            _AboutSection(),
            _LogoutSection(),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// Profile section showing current user info.
class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SettingsSectionCard(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: _buildAvatar(user, theme, colorScheme),
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Unknown User',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapVerticalXs,
                    const RoleBadge(compact: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        SettingsItem(
          title: 'Edit Profile',
          subtitle: 'Update your name and contact info',
          leading: Icon(
            Icons.edit_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => context.push(Routes.profile),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildAvatar(
    User? user,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => CachedAvatar(
      imageUrl: user?.avatarAbsoluteUrl,
      size: 64,
      initials: user?.initials,
      semanticLabel: 'Profile photo of ${user?.fullName ?? 'user'}',
    );
}

/// Appearance settings section.
class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return SettingsSectionCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      children: [
        SettingsSelectionItem<ThemePreference>(
          title: 'Theme',
          subtitle: 'Choose light, dark, or system theme',
          value: prefs.themeMode,
          options: ThemePreference.values
              .map((t) => (value: t, label: t.label))
              .toList(),
          onChanged: notifier.setThemeMode,
        ),
        SettingsSwitchItem(
          title: 'Dynamic Colors',
          subtitle: 'Use Material You colors from wallpaper',
          value: prefs.useDynamicColors,
          onChanged: notifier.setUseDynamicColors,
        ),
        SettingsSwitchItem(
          title: 'Compact Mode',
          subtitle: 'Show more content with smaller spacing',
          value: prefs.compactMode,
          onChanged: notifier.setCompactMode,
          showDivider: false,
        ),
      ],
    );
  }
}

/// Survey-specific preferences.
class _SurveyPreferencesSection extends ConsumerWidget {
  const _SurveyPreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return SettingsSectionCard(
      title: 'Survey Preferences',
      icon: Icons.assignment_outlined,
      children: [
        SettingsSelectionItem<String>(
          title: 'Default Survey Type',
          subtitle: 'Type used when creating new surveys',
          value: prefs.defaultSurveyType,
          options: const [
            (value: 'inspection', label: 'Inspection'),
            (value: 'valuation', label: 'Valuation'),
            (value: 'audit', label: 'Audit'),
          ],
          onChanged: notifier.setDefaultSurveyType,
        ),
        SettingsSelectionItem<int>(
          title: 'Auto-save Interval',
          subtitle: 'How often to save progress automatically',
          value: prefs.autoSaveInterval,
          options: const [
            (value: 0, label: 'Disabled'),
            (value: 15, label: '15 seconds'),
            (value: 30, label: '30 seconds'),
            (value: 60, label: '1 minute'),
            (value: 120, label: '2 minutes'),
          ],
          onChanged: notifier.setAutoSaveInterval,
        ),
        SettingsSwitchItem(
          title: 'Keep Screen Awake',
          subtitle: 'Prevent screen from sleeping during surveys',
          value: prefs.keepScreenAwake,
          onChanged: notifier.setKeepScreenAwake,
        ),
        SettingsSwitchItem(
          title: 'Completion Animations',
          subtitle: 'Show celebratory animations',
          value: prefs.showCompletionAnimations,
          onChanged: notifier.setShowCompletionAnimations,
          showDivider: false,
        ),
      ],
    );
  }
}

/// Sync and offline settings.
///
/// Exposes user preferences for controlling sync behavior.
/// The sync engine runs automatically in the background - these toggles
/// allow users to customize when and how sync occurs.
class _SyncSection extends ConsumerWidget {
  const _SyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return SettingsSectionCard(
      title: 'Sync & Offline',
      icon: Icons.sync_rounded,
      subtitle: 'Automatic sync enabled',
      children: [
        SettingsSwitchItem(
          title: 'Enable Offline Mode',
          subtitle: 'Queue changes when offline for later sync',
          value: prefs.enableOfflineMode,
          onChanged: notifier.setEnableOfflineMode,
        ),
        SettingsSwitchItem(
          title: 'Sync on WiFi Only',
          subtitle: 'Only sync when connected to WiFi',
          value: prefs.syncOnWifiOnly,
          onChanged: notifier.setSyncOnWifiOnly,
        ),
        SettingsSwitchItem(
          title: 'Show Sync Status',
          subtitle: 'Display sync indicator in navigation bar',
          value: prefs.showSyncStatus,
          onChanged: notifier.setShowSyncStatus,
          showDivider: false,
        ),
      ],
    );
  }
}

/// Security settings section.
class _SecuritySection extends ConsumerStatefulWidget {
  const _SecuritySection();

  @override
  ConsumerState<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<_SecuritySection> {
  BiometricStatus? _biometricStatus;
  bool _checkingBiometric = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    setState(() => _checkingBiometric = true);

    final status = await BiometricService.instance.getStatus(forceRefresh: true);

    if (mounted) {
      setState(() {
        _biometricStatus = status;
        _checkingBiometric = false;
      });

      // If biometric was enabled but is no longer available, disable it
      final prefs = ref.read(preferencesProvider);
      if (prefs.enableBiometricLock && !status.canAuthenticate) {
        await ref.read(preferencesProvider.notifier).setEnableBiometricLock(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric lock disabled: ${_getStatusReason(status)}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _getStatusReason(BiometricStatus status) {
    if (status.errorMessage != null) return status.errorMessage!;
    if (!status.isHardwareAvailable) return 'Hardware not available';
    if (!status.isDeviceSupported) return 'Device not supported';
    if (!status.hasEnrolledBiometrics) return 'No biometrics enrolled';
    return 'Unknown';
  }

  String _getBiometricSubtitle() {
    if (_checkingBiometric) {
      return 'Checking availability...';
    }

    final status = _biometricStatus;
    if (status == null) {
      return 'Unable to check biometric status';
    }

    if (status.errorMessage != null) {
      return status.errorMessage!;
    }

    if (!status.isHardwareAvailable) {
      return 'Biometric hardware not detected on this device';
    }

    if (!status.isDeviceSupported) {
      return 'This device does not support biometric authentication';
    }

    if (!status.hasEnrolledBiometrics) {
      return 'No fingerprint or face enrolled. Set up in device settings';
    }

    // Biometrics available - show what's available
    return 'Use ${status.biometricDescription.toLowerCase()} to unlock app';
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (_isAuthenticating) return;

    if (value) {
      // Re-check status before enabling
      setState(() => _isAuthenticating = true);

      final status = await BiometricService.instance.getStatus(forceRefresh: true);

      if (!mounted) return;

      setState(() {
        _biometricStatus = status;
      });

      if (!status.canAuthenticate) {
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getStatusReason(status)),
            behavior: SnackBarBehavior.floating,
            action: status.hasEnrolledBiometrics
                ? null
                : SnackBarAction(
                    label: 'Retry',
                    onPressed: _checkBiometricStatus,
                  ),
          ),
        );
        return;
      }

      // Authenticate to verify user can use biometrics
      final result = await BiometricService.instance.authenticate(
        reason: 'Verify your identity to enable biometric lock',
      );

      if (!mounted) return;

      setState(() => _isAuthenticating = false);

      if (result == BiometricResult.cancelled) {
        // User cancelled - don't show error, just return
        return;
      }

      if (result != BiometricResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(BiometricService.instance.getResultMessage(result)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Success - enable biometric lock
      await ref.read(preferencesProvider.notifier).setEnableBiometricLock(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric lock enabled'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Disabling - no authentication needed
      await ref.read(preferencesProvider.notifier).setEnableBiometricLock(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final canEnable = _biometricStatus?.canAuthenticate ?? false;
    final isEnabled = prefs.enableBiometricLock && canEnable;

    return SettingsSectionCard(
      title: 'Security',
      icon: Icons.security_rounded,
      children: [
        SettingsSwitchItem(
          title: 'Biometric Lock',
          subtitle: _getBiometricSubtitle(),
          value: isEnabled,
          onChanged: canEnable && !_isAuthenticating ? _handleBiometricToggle : null,
          enabled: canEnable && !_checkingBiometric && !_isAuthenticating,
        ),
        SettingsSelectionItem<int>(
          title: 'Auto-lock Timeout',
          subtitle: 'Lock app after inactivity',
          value: prefs.autoLockTimeout,
          options: const [
            (value: 0, label: 'Disabled'),
            (value: 1, label: '1 minute'),
            (value: 5, label: '5 minutes'),
            (value: 15, label: '15 minutes'),
            (value: 30, label: '30 minutes'),
          ],
          onChanged: notifier.setAutoLockTimeout,
          enabled: isEnabled,
          disabledReason: isEnabled ? null : 'Enable biometric lock first',
        ),
        SettingsItem(
          title: 'Change Password',
          subtitle: 'Update your account password',
          leading: Icon(
            Icons.lock_outline_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => context.push(Routes.changePassword),
          showDivider: false,
        ),
      ],
    );
  }
}

/// Storage settings section.
class _StorageSection extends ConsumerStatefulWidget {
  const _StorageSection();

  @override
  ConsumerState<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends ConsumerState<_StorageSection> {
  bool _isClearing = false;

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Clear Cache',
      message: 'This will clear cached images and temporary files. '
          'Your surveys and settings will not be affected.',
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);
      try {
        await StorageService.clearCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear cache: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isClearing = false);
        }
      }
    }
  }

  Future<void> _clearStorage() async {
    // Check for unsynced data BEFORE showing the confirmation dialog.
    final syncState = ref.read(syncStateProvider);
    final pending = syncState.pendingCount;
    final failed = syncState.failedCount;
    final unsyncedTotal = pending + failed;

    final baseMessage = 'This will delete all local data including offline surveys, '
        'cached files, and local settings. You will need to log in again. '
        'This action cannot be undone.';

    final message = unsyncedTotal > 0
        ? 'WARNING: You have $unsyncedTotal unsynced change${unsyncedTotal == 1 ? '' : 's'} '
          '($pending pending, $failed failed) that have NOT been uploaded to '
          'the server. These will be permanently lost.\n\n$baseMessage'
        : baseMessage;

    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Clear All Storage',
      message: message,
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() => _isClearing = true);
      try {
        // 1. Wipe all database rows (Drift connection stays alive so the
        //    appDatabaseProvider singleton remains usable after re-login).
        final db = ref.read(appDatabaseProvider);
        await db.deleteEverything();

        // 2. Clear cached files (temp + app cache directories).
        await StorageService.clearCache();

        // 3. Invalidate data-dependent providers BEFORE logout triggers
        //    navigation — prevents ghost surveys on the dashboard.
        ref.invalidate(dashboardProvider);
        ref.invalidate(formsProvider);

        // 4. Logout: revokes server token (refresh token is still intact at
        //    this point), clears auth state, router navigates to login.
        await ref.read(authNotifierProvider.notifier).logout();

        // 5. Clear remaining non-auth storage (preferences, Hive, secure
        //    storage). These are static calls safe to run after navigation.
        await StorageService.clearAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear storage: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isClearing = false);
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
                : null,
            child: Text(isDestructive ? 'Clear All' : 'Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSectionCard(
      title: 'Storage',
      icon: Icons.storage_rounded,
      subtitle: 'Manage local data',
      children: [
        SettingsItem(
          title: 'Clear Cache',
          subtitle: 'Remove cached images and temporary files',
          leading: _isClearing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(
                  Icons.cleaning_services_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
          onTap: _isClearing ? null : _clearCache,
        ),
        SettingsItem(
          title: 'Clear All Storage',
          subtitle: 'Delete all local data and log out',
          leading: Icon(
            Icons.delete_forever_rounded,
            color: colorScheme.error,
          ),
          onTap: _isClearing ? null : _clearStorage,
          showDivider: false,
        ),
      ],
    );
  }
}

/// Admin section (permission-guarded).
class _AdminSection extends ConsumerWidget {
  const _AdminSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAdminAccess = ref.watch(hasPermissionProvider(Permission.manageUsers));
    final colorScheme = Theme.of(context).colorScheme;

    // Only show if user has any admin permissions
    if (!hasAdminAccess) {
      return const SizedBox.shrink();
    }

    return SettingsSectionCard(
      title: 'Administration',
      icon: Icons.admin_panel_settings_outlined,
      subtitle: 'System management',
      children: [
        PermissionGuard(
          permission: Permission.manageUsers,
          child: SettingsItem(
            title: 'Admin Dashboard',
            subtitle: 'Manage configuration and users',
            leading: Icon(
              Icons.dashboard_customize_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => context.push(Routes.adminDashboard),
          ),
        ),
        PermissionGuard(
          permission: Permission.manageUsers,
          child: SettingsItem(
            title: 'User Management',
            subtitle: 'Manage user roles and access',
            leading: Icon(
              Icons.people_outline_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => context.push(Routes.adminUsers),
          ),
        ),
        PermissionGuard(
          permission: Permission.manageSettings,
          child: SettingsItem(
            title: 'Survey Trees',
            subtitle: 'Manage inspection & valuation trees, fields, and phrases',
            leading: Icon(
              Icons.account_tree_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => context.push(Routes.adminTrees),
            showDivider: false,
          ),
        ),
      ],
    );
  }
}

/// About section with app info.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifier = ref.read(preferencesProvider.notifier);

    return SettingsSectionCard(
      title: 'About',
      icon: Icons.info_outline_rounded,
      children: [
        SettingsItem(
          title: 'About SurveyScriber',
          subtitle: 'Version 1.0.0 (Build 1)',
          leading: Icon(
            Icons.info_outline_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StaticContentPage(
                title: 'About SurveyScriber',
                content: StaticContent.about,
                icon: Icons.edit_document,
              ),
            ),
          ),
        ),
        SettingsItem(
          title: 'Privacy Policy',
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StaticContentPage(
                title: 'Privacy Policy',
                content: StaticContent.privacyPolicy,
                icon: Icons.privacy_tip_outlined,
                lastUpdated: 'December 2024',
              ),
            ),
          ),
        ),
        SettingsItem(
          title: 'Terms of Service',
          leading: Icon(
            Icons.description_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const StaticContentPage(
                title: 'Terms of Service',
                content: StaticContent.termsOfService,
                icon: Icons.description_outlined,
                lastUpdated: 'December 2024',
              ),
            ),
          ),
        ),
        SettingsItem(
          title: 'Open Source Licenses',
          leading: Icon(
            Icons.code_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'SurveyScriber',
            applicationVersion: '1.0.0',
          ),
        ),
        SettingsItem(
          title: 'Reset All Settings',
          subtitle: 'Restore default preferences',
          leading: Icon(
            Icons.restart_alt_rounded,
            color: colorScheme.error,
          ),
          onTap: () => _confirmReset(context, notifier),
          showDivider: false,
        ),
      ],
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    PreferencesNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will restore all preferences to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Logout section.
class _LogoutSection extends ConsumerWidget {
  const _LogoutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Log Out. Sign out of your account',
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: colorScheme.error.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: () => _confirmLogout(context, ref),
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.error.withOpacity(0.1),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Out',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                        Text(
                          'Sign out of your account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.error.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: colorScheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? You will need to sign in again to access your surveys.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}
