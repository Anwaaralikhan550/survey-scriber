import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/settings/presentation/providers/preferences_provider.dart';
import '../../shared/presentation/widgets/sync_indicator.dart';
import '../router/routes.dart';
import '../theme/app_spacing.dart';

class MainShell extends ConsumerWidget {
  const MainShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncStateProvider);
    final prefs = ref.watch(preferencesProvider);

    // F8 FIX: Check if auth is still resolving (initial or loading state)
    // Show loading overlay to prevent dashboard flash before auth is confirmed
    final authState = ref.watch(authNotifierProvider);
    final isAuthResolving = authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading;

    // If auth is resolving, show a loading screen instead of the shell content
    if (isAuthResolving) {
      return _AuthResolvingScreen(colorScheme: colorScheme);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Offline indicator bar (animated visibility)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: syncState.isOffline ? 44 : 0,
                  child: syncState.isOffline
                      ? SafeArea(
                          bottom: false,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.errorContainer.withOpacity(0.9),
                              border: Border(
                                bottom: BorderSide(
                                  color: colorScheme.error.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 16,
                                  color: colorScheme.onErrorContainer,
                                ),
                                AppSpacing.gapHorizontalSm,
                                Text(
                                  'You\'re offline',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (syncState.hasPendingChanges) ...[
                                  AppSpacing.gapHorizontalSm,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${syncState.pendingCount} pending',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Navigation shell content
                Expanded(child: navigationShell),
              ],
            ),
            if (prefs.showSyncStatus &&
                (!syncState.isFullySynced || syncState.hasPendingChanges))
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 72,
                  ),
                  child: const SyncStatusIndicator(compact: true),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildFAB(context, colorScheme),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomNav(context, theme, ref),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, ColorScheme colorScheme) =>
      DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push(Routes.newSurvey),
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      );

  Widget _buildBottomNav(BuildContext context, ThemeData theme, WidgetRef ref) {
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Navigation items
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.grid_view_outlined,
                      selectedIcon: Icons.grid_view_rounded,
                      label: 'Dashboard',
                      isSelected: navigationShell.currentIndex == 0,
                      onTap: () => _onNavTap(context, 0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.assignment_outlined,
                      selectedIcon: Icons.assignment_rounded,
                      label: 'Forms',
                      isSelected: navigationShell.currentIndex == 1,
                      onTap: () => _onNavTap(context, 1),
                    ),
                  ),
                  const SizedBox(width: 56), // Space for FAB
                  Expanded(
                    child: _NavItem(
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      isSelected: navigationShell.currentIndex == 2,
                      onTap: () => _onNavTap(context, 2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.search_outlined,
                      selectedIcon: Icons.search_rounded,
                      label: 'Search',
                      isSelected: navigationShell.currentIndex == 3,
                      onTap: () => _onNavTap(context, 3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    // Kill any ghost keyboard by unfocusing before navigation
    FocusScope.of(context).unfocus();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading screen shown while auth state is being resolved.
/// Prevents dashboard flash by showing a clean loading indicator
/// until auth status is definitively known.
class _AuthResolvingScreen extends StatelessWidget {
  const _AuthResolvingScreen({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular loading indicator matching app theme
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
}
