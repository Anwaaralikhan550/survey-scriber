import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import 'permission.dart';

/// Configuration for route-level permission requirements.
///
/// This class defines which routes require which permissions,
/// providing centralized route access control.
class RoutePermissions {
  const RoutePermissions._();

  /// Map of routes to their required permissions.
  /// Routes not in this map are accessible to all authenticated users.
  static const Map<String, Permission> _routePermissions = {
    Routes.reports: Permission.viewReports,
    Routes.adminUsers: Permission.manageUsers,
    Routes.adminAuditLogs: Permission.viewAuditLog,
    Routes.adminWebhooks: Permission.manageSettings,
    Routes.adminWebhooksCreate: Permission.manageSettings,
    Routes.adminExports: Permission.exportBulk,
  };

  /// Map of routes to their minimum required role.
  /// This is an alternative to permission-based checks for simpler cases.
  static const Map<String, UserRole> _routeMinimumRoles = {
    // Example: '/admin': UserRole.admin,
    // '/audit-log': UserRole.manager,
  };

  /// Check if a user can access a specific route.
  static bool canAccess(String route, UserRole? role) {
    if (role == null) return false;

    // Check permission-based restriction
    final requiredPermission = _routePermissions[route];
    if (requiredPermission != null) {
      return PermissionResolver.instance.can(role, requiredPermission);
    }

    // Check role-based restriction
    final minimumRole = _routeMinimumRoles[route];
    if (minimumRole != null) {
      return PermissionResolver.instance.isAtLeast(role, minimumRole);
    }

    // No restriction - allow access
    return true;
  }

  /// Get the redirect path if access is denied.
  /// Returns null if access is allowed.
  static String? getRedirectIfDenied(String route, UserRole? role) {
    if (canAccess(route, role)) return null;

    // Redirect to dashboard if access denied
    return Routes.dashboard;
  }

  /// Get a user-friendly message explaining why access was denied.
  static String? getDenialMessage(String route, UserRole? role) {
    if (canAccess(route, role)) return null;

    final requiredPermission = _routePermissions[route];
    if (requiredPermission != null) {
      return 'You need "${PermissionResolver.instance.getPermissionName(requiredPermission)}" permission to access this page';
    }

    final minimumRole = _routeMinimumRoles[route];
    if (minimumRole != null) {
      return 'This page requires ${PermissionResolver.instance.getRoleName(minimumRole)} access or higher';
    }

    return 'Access denied';
  }
}

/// Extension on GoRouter redirect for permission checks.
///
/// Usage in app_router.dart:
/// ```dart
/// redirect: (context, state) {
///   // ... existing auth checks ...
///
///   // Permission check
///   final permissionRedirect = checkRoutePermission(context, state, authState.user?.role);
///   if (permissionRedirect != null) return permissionRedirect;
///
///   return null;
/// }
/// ```
String? checkRoutePermission(
  BuildContext context,
  GoRouterState state,
  UserRole? role,
) => RoutePermissions.getRedirectIfDenied(state.matchedLocation, role);

/// A page wrapper that shows an access denied message if the user
/// lacks permission, instead of just redirecting.
///
/// Use this for a calmer UX when you want to explain why access is denied
/// rather than silently redirecting.
class PermissionPage extends ConsumerWidget {
  const PermissionPage({
    required this.permission,
    required this.child,
    this.redirectOnDenied = false,
    this.redirectPath,
    super.key,
  });

  /// The permission required to view this page.
  final Permission permission;

  /// The page content to show if permission is granted.
  final Widget child;

  /// If true, redirects instead of showing access denied message.
  final bool redirectOnDenied;

  /// Custom redirect path (defaults to dashboard).
  final String? redirectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.user?.role;
    final hasPermission = PermissionResolver.instance.can(role, permission);

    if (hasPermission) {
      return child;
    }

    if (redirectOnDenied) {
      // Schedule redirect for after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(redirectPath ?? Routes.dashboard);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show access denied message
    return _AccessDeniedPage(
      permission: permission,
      role: role,
    );
  }
}

/// A page wrapper that requires a minimum role level.
class RoleGatedPage extends ConsumerWidget {
  const RoleGatedPage({
    required this.minimumRole,
    required this.child,
    this.redirectOnDenied = false,
    this.redirectPath,
    super.key,
  });

  final UserRole minimumRole;
  final Widget child;
  final bool redirectOnDenied;
  final String? redirectPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.user?.role;
    final hasAccess = PermissionResolver.instance.isAtLeast(role, minimumRole);

    if (hasAccess) {
      return child;
    }

    if (redirectOnDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(redirectPath ?? Routes.dashboard);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _RoleDeniedPage(
      minimumRole: minimumRole,
      currentRole: role,
    );
  }
}

/// Access denied page for permission-based denial.
class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({
    required this.permission,
    required this.role,
  });

  final Permission permission;
  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const resolver = PermissionResolver.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Restricted'),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.dashboard),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Permission Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You need "${resolver.getPermissionName(permission)}" permission to access this page.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (role != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Your current role: ${resolver.getRoleName(role!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Access denied page for role-based denial.
class _RoleDeniedPage extends StatelessWidget {
  const _RoleDeniedPage({
    required this.minimumRole,
    required this.currentRole,
  });

  final UserRole minimumRole;
  final UserRole? currentRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const resolver = PermissionResolver.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Restricted'),
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.dashboard),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Higher Access Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This page requires ${resolver.getRoleName(minimumRole)} access or higher.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (currentRole != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Your current role: ${resolver.getRoleName(currentRole!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
