import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import 'permission.dart';

/// Provider for the PermissionResolver singleton.
final permissionResolverProvider = Provider<PermissionResolver>((ref) => PermissionResolver.instance);

/// Provider for the current user's role.
/// Returns null if not authenticated.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.role;
});

/// Provider for checking a specific permission.
/// Usage: ref.watch(hasPermissionProvider(Permission.createSurvey))
final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final role = ref.watch(currentUserRoleProvider);
  final resolver = ref.watch(permissionResolverProvider);
  return resolver.can(role, permission);
});

/// Provider for checking multiple permissions (ALL required).
/// Usage: ref.watch(hasAllPermissionsProvider([Permission.editSurvey, Permission.deleteSurvey]))
final hasAllPermissionsProvider =
    Provider.family<bool, List<Permission>>((ref, permissions) {
  final role = ref.watch(currentUserRoleProvider);
  final resolver = ref.watch(permissionResolverProvider);
  return resolver.canAll(role, permissions);
});

/// Provider for checking multiple permissions (ANY required).
/// Usage: ref.watch(hasAnyPermissionProvider([Permission.approveSurvey, Permission.rejectSurvey]))
final hasAnyPermissionProvider =
    Provider.family<bool, List<Permission>>((ref, permissions) {
  final role = ref.watch(currentUserRoleProvider);
  final resolver = ref.watch(permissionResolverProvider);
  return resolver.canAny(role, permissions);
});

/// Provider for checking if user is at least a certain role.
/// Usage: ref.watch(isAtLeastRoleProvider(UserRole.manager))
final isAtLeastRoleProvider = Provider.family<bool, UserRole>((ref, minimumRole) {
  final role = ref.watch(currentUserRoleProvider);
  final resolver = ref.watch(permissionResolverProvider);
  return resolver.isAtLeast(role, minimumRole);
});

/// Provider for getting all permissions for the current user.
final currentPermissionsProvider = Provider<Set<Permission>>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  final resolver = ref.watch(permissionResolverProvider);
  return resolver.getPermissions(role);
});

/// Provider for permission check with detailed info (for UI hints).
/// Returns a record with permission status and help text.
final permissionCheckProvider =
    Provider.family<PermissionCheckResult, Permission>((ref, permission) {
  final role = ref.watch(currentUserRoleProvider);
  final resolver = ref.watch(permissionResolverProvider);
  final hasPermission = resolver.can(role, permission);

  String? denialReason;
  if (!hasPermission) {
    if (role == null) {
      denialReason = 'Please sign in to access this feature';
    } else {
      denialReason =
          '${resolver.getRoleName(role)}s cannot ${resolver.getPermissionName(permission).toLowerCase()}';
    }
  }

  return PermissionCheckResult(
    hasPermission: hasPermission,
    denialReason: denialReason,
    requiredPermission: permission,
    currentRole: role,
  );
});

/// Result of a permission check with UI-friendly information.
class PermissionCheckResult {
  const PermissionCheckResult({
    required this.hasPermission,
    required this.requiredPermission,
    this.denialReason,
    this.currentRole,
  });

  final bool hasPermission;
  final String? denialReason;
  final Permission requiredPermission;
  final UserRole? currentRole;

  /// Whether to show the element (even if disabled).
  /// Elements are always shown but may be disabled.
  bool get shouldShow => true;

  /// Whether the element should be enabled.
  bool get isEnabled => hasPermission;
}
