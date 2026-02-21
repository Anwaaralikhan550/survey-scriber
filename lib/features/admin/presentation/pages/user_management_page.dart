import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/permissions/permission.dart';
import '../../../auth/domain/entities/user.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../providers/admin_providers.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersProvider.notifier).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final usersState = ref.watch(usersProvider);

    // Listen for error state changes and show snackbar
    ref.listen<UsersState>(usersProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showErrorSnackBar(context, theme, next.error!);
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(usersProvider.notifier).loadUsers(),
        child: _buildBody(usersState, theme, colorScheme),
      ),
    );
  }

  Widget _buildBody(UsersState state, ThemeData theme, ColorScheme colorScheme) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.users.isEmpty) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load users',
        subtitle: state.error!,
        action: FilledButton.icon(
          onPressed: () => ref.read(usersProvider.notifier).loadUsers(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }

    if (state.users.isEmpty) {
      return const _EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No users found',
        subtitle: 'Users will appear here once they register',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return _UserCard(
          user: user,
          canDemote: ref.read(usersProvider.notifier).canDemoteUser(user),
          onRoleChanged: (newRole) => _handleRoleChange(user, newRole),
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, ThemeData theme, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleRoleChange(AdminUserDto user, UserRole newRole) async {
    final confirmed = await _showConfirmDialog(user, newRole);
    if (!confirmed) return;

    final success = await ref.read(usersProvider.notifier).updateUserRole(
          user.id,
          newRole,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} is now ${newRole.displayName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update user role'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog(AdminUserDto user, UserRole newRole) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPromotion = _getRoleLevel(newRole) > _getRoleLevel(user.role);
    final isDemotion = _getRoleLevel(newRole) < _getRoleLevel(user.role);

    return await showDialog<bool>(
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
                    color: (isPromotion ? colorScheme.primary : colorScheme.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPromotion
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: isPromotion ? colorScheme.primary : colorScheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(isPromotion ? 'Promote User' : 'Change Role'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change ${user.fullName}\'s role from ${user.role.displayName} to ${newRole.displayName}?',
                ),
                if (newRole == UserRole.admin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin users have full system access',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: isDemotion
                    ? FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      )
                    : null,
                child: Text(isPromotion ? 'Promote' : 'Change'),
              ),
            ],
          ),
        ) ??
        false;
  }

  int _getRoleLevel(UserRole role) {
    switch (role) {
      case UserRole.viewer:
        return 0;
      case UserRole.surveyor:
        return 1;
      case UserRole.manager:
        return 2;
      case UserRole.admin:
        return 3;
    }
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.canDemote,
    required this.onRoleChanged,
  });

  final AdminUserDto user;
  final bool canDemote;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getRoleColor(user.role, colorScheme).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _getRoleColor(user.role, colorScheme),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            AppSpacing.gapHorizontalMd,

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapVerticalXs,
                  Text(
                    user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Role dropdown
            _RoleDropdown(
              currentRole: user.role,
              canDemote: canDemote,
              onChanged: onRoleChanged,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role, ColorScheme colorScheme) {
    switch (role) {
      case UserRole.admin:
        return colorScheme.error;
      case UserRole.manager:
        return colorScheme.primary;
      case UserRole.surveyor:
        return colorScheme.tertiary;
      case UserRole.viewer:
        return colorScheme.secondary;
    }
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.currentRole,
    required this.canDemote,
    required this.onChanged,
  });

  final UserRole currentRole;
  final bool canDemote;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getRoleColor(currentRole, colorScheme).withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: _getRoleColor(currentRole, colorScheme).withOpacity(0.3),
        ),
      ),
      child: PopupMenuButton<UserRole>(
        initialValue: currentRole,
        onSelected: (role) {
          if (role != currentRole) {
            onChanged(role);
          }
        },
        itemBuilder: (context) => UserRole.values.map((role) {
          final isDisabled = !canDemote &&
              currentRole == UserRole.admin &&
              role != UserRole.admin;

          return PopupMenuItem<UserRole>(
            value: role,
            enabled: !isDisabled,
            child: Row(
              children: [
                Icon(
                  _getRoleIcon(role),
                  size: 18,
                  color: isDisabled
                      ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                      : _getRoleColor(role, colorScheme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    role.displayName,
                    style: TextStyle(
                      color: isDisabled
                          ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (role == currentRole)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                if (isDisabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: 'Cannot remove last admin',
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getRoleIcon(currentRole),
              size: 16,
              color: _getRoleColor(currentRole, colorScheme),
            ),
            const SizedBox(width: 4),
            Text(
              currentRole.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _getRoleColor(currentRole, colorScheme),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: _getRoleColor(currentRole, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.manager:
        return Icons.manage_accounts_rounded;
      case UserRole.surveyor:
        return Icons.person_rounded;
      case UserRole.viewer:
        return Icons.visibility_rounded;
    }
  }

  Color _getRoleColor(UserRole role, ColorScheme colorScheme) {
    switch (role) {
      case UserRole.admin:
        return colorScheme.error;
      case UserRole.manager:
        return colorScheme.primary;
      case UserRole.surveyor:
        return colorScheme.tertiary;
      case UserRole.viewer:
        return colorScheme.secondary;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalLg,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              AppSpacing.gapVerticalLg,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
