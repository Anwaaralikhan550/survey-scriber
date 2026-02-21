import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/permission.dart';
import '../../../core/permissions/permission_providers.dart';
import '../../../features/auth/domain/entities/user.dart';

/// A widget that conditionally renders its child based on permission.
///
/// Unlike traditional guards that hide content, this widget follows
/// a "calm UI" approach:
/// - Content is always visible (never hidden)
/// - Disabled state is clearly communicated
/// - Tooltips explain why something is unavailable
///
/// Usage:
/// ```dart
/// PermissionGuard(
///   permission: Permission.createSurvey,
///   child: ElevatedButton(
///     onPressed: () => createSurvey(),
///     child: Text('Create Survey'),
///   ),
/// )
/// ```
class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    required this.permission,
    required this.child,
    this.fallback,
    this.hideWhenDenied = false,
    super.key,
  });

  /// The permission required to enable this widget.
  final Permission permission;

  /// The child widget to render.
  final Widget child;

  /// Optional fallback widget when permission is denied and hideWhenDenied is true.
  final Widget? fallback;

  /// If true, hides the widget entirely when permission is denied.
  /// Default is false (shows disabled state with tooltip).
  final bool hideWhenDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(permissionCheckProvider(permission));

    if (!check.hasPermission && hideWhenDenied) {
      return fallback ?? const SizedBox.shrink();
    }

    if (check.hasPermission) {
      return child;
    }

    // Wrap in tooltip and disable interactions
    return Tooltip(
      message: check.denialReason ?? 'Permission required',
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: child,
        ),
      ),
    );
  }
}

/// A permission-aware button that disables itself and shows a tooltip
/// when the user lacks the required permission.
///
/// Usage:
/// ```dart
/// PermissionButton(
///   permission: Permission.deleteSurvey,
///   onPressed: () => deleteSurvey(),
///   child: Text('Delete'),
/// )
/// ```
class PermissionButton extends ConsumerWidget {
  const PermissionButton({
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
    this.icon,
    super.key,
  });

  final Permission permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final Widget? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(permissionCheckProvider(permission));

    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: check.hasPermission ? onPressed : null,
            style: style,
            icon: icon,
            label: child,
          )
        : ElevatedButton(
            onPressed: check.hasPermission ? onPressed : null,
            style: style,
            child: child,
          );

    if (!check.hasPermission && check.denialReason != null) {
      return Tooltip(
        message: check.denialReason,
        child: button,
      );
    }

    return button;
  }
}

/// A permission-aware icon button.
///
/// Usage:
/// ```dart
/// PermissionIconButton(
///   permission: Permission.editSurvey,
///   icon: Icon(Icons.edit),
///   onPressed: () => editSurvey(),
///   tooltip: 'Edit survey',
/// )
/// ```
class PermissionIconButton extends ConsumerWidget {
  const PermissionIconButton({
    required this.permission,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size,
    super.key,
  });

  final Permission permission;
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(permissionCheckProvider(permission));

    final effectiveTooltip = check.hasPermission
        ? tooltip
        : check.denialReason ?? 'Permission required';

    return IconButton(
      icon: icon,
      onPressed: check.hasPermission ? onPressed : null,
      tooltip: effectiveTooltip,
      color: color,
      iconSize: size,
    );
  }
}

/// A permission-aware floating action button.
///
/// Usage:
/// ```dart
/// PermissionFAB(
///   permission: Permission.createSurvey,
///   onPressed: () => createSurvey(),
///   child: Icon(Icons.add),
///   tooltip: 'Create new survey',
/// )
/// ```
class PermissionFAB extends ConsumerWidget {
  const PermissionFAB({
    required this.permission,
    required this.onPressed,
    this.child,
    this.tooltip,
    this.heroTag,
    this.mini = false,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final Permission permission;
  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final Object? heroTag;
  final bool mini;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(permissionCheckProvider(permission));
    final theme = Theme.of(context);

    final effectiveTooltip = check.hasPermission
        ? tooltip
        : check.denialReason ?? 'Permission required';

    return Tooltip(
      message: effectiveTooltip ?? '',
      child: FloatingActionButton(
        onPressed: check.hasPermission ? onPressed : null,
        heroTag: heroTag,
        mini: mini,
        backgroundColor: check.hasPermission
            ? backgroundColor
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: check.hasPermission
            ? foregroundColor
            : theme.colorScheme.onSurfaceVariant,
        child: child,
      ),
    );
  }
}

/// A permission-aware popup menu item.
///
/// Usage in PopupMenuButton:
/// ```dart
/// PopupMenuButton(
///   itemBuilder: (context) => [
///     PermissionPopupMenuItem(
///       permission: Permission.editSurvey,
///       value: 'edit',
///       child: Text('Edit'),
///     ),
///     PermissionPopupMenuItem(
///       permission: Permission.deleteSurvey,
///       value: 'delete',
///       child: Text('Delete'),
///     ),
///   ],
/// )
/// ```
class PermissionPopupMenuItem<T> extends ConsumerWidget {
  const PermissionPopupMenuItem({
    required this.permission,
    required this.value,
    required this.child,
    this.hideWhenDenied = false,
    super.key,
  });

  final Permission permission;
  final T value;
  final Widget child;
  final bool hideWhenDenied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(permissionCheckProvider(permission));

    if (!check.hasPermission && hideWhenDenied) {
      return const SizedBox.shrink();
    }

    if (!check.hasPermission) {
      return PopupMenuItem<T>(
        enabled: false,
        child: Tooltip(
          message: check.denialReason ?? 'Permission required',
          child: Opacity(
            opacity: 0.5,
            child: child,
          ),
        ),
      );
    }

    return PopupMenuItem<T>(
      value: value,
      child: child,
    );
  }
}

/// A widget that shows different content based on role.
///
/// This is useful for showing role-specific UI without
/// hardcoding role checks in the UI.
///
/// Usage:
/// ```dart
/// RoleBasedContent(
///   admin: AdminDashboard(),
///   manager: ManagerDashboard(),
///   surveyor: SurveyorDashboard(),
///   viewer: ViewerDashboard(),
///   fallback: GuestView(),
/// )
/// ```
class RoleBasedContent extends ConsumerWidget {
  const RoleBasedContent({
    this.admin,
    this.manager,
    this.surveyor,
    this.viewer,
    this.fallback,
    super.key,
  });

  final Widget? admin;
  final Widget? manager;
  final Widget? surveyor;
  final Widget? viewer;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);

    final widget = switch (role) {
      UserRole.admin => admin,
      UserRole.manager => manager,
      UserRole.surveyor => surveyor,
      UserRole.viewer => viewer,
      null => null,
    };

    return widget ?? fallback ?? const SizedBox.shrink();
  }
}

/// A builder widget that provides permission check result.
///
/// Use this when you need more control over how to render
/// based on permission state.
///
/// Usage:
/// ```dart
/// PermissionBuilder(
///   permission: Permission.approveSurvey,
///   builder: (context, check) {
///     return TextButton(
///       onPressed: check.hasPermission ? approve : null,
///       child: Text(
///         check.hasPermission ? 'Approve' : 'Approval requires manager role',
///       ),
///     );
///   },
/// )
/// ```
class PermissionBuilder extends ConsumerWidget {
  const PermissionBuilder({
    required this.permission,
    required this.builder,
    super.key,
  });

  final Permission permission;
  final Widget Function(BuildContext context, PermissionCheckResult check)
      builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(permissionCheckProvider(permission));
    return builder(context, check);
  }
}

/// A widget that shows a subtle indicator of the user's role.
///
/// Useful in app bars or profile sections.
class RoleBadge extends ConsumerWidget {
  const RoleBadge({
    this.showIcon = true,
    this.compact = false,
    super.key,
  });

  final bool showIcon;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final theme = Theme.of(context);

    if (role == null) return const SizedBox.shrink();

    final (icon, color) = switch (role) {
      UserRole.admin => (Icons.admin_panel_settings, theme.colorScheme.error),
      UserRole.manager => (Icons.manage_accounts, theme.colorScheme.primary),
      UserRole.surveyor => (Icons.assignment_ind, theme.colorScheme.secondary),
      UserRole.viewer => (Icons.visibility, theme.colorScheme.outline),
    };

    if (compact) {
      return Tooltip(
        message: role.displayName,
        child: Icon(icon, color: color, size: 20),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
          ],
          Text(
            role.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
