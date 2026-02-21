import '../../features/auth/domain/entities/user.dart';

/// All permissions available in the application.
/// These are atomic capabilities that can be checked.
enum Permission {
  // Survey lifecycle
  createSurvey,
  editSurvey,
  deleteSurvey,
  viewSurvey,

  // Review workflow
  submitReview,
  approveSurvey,
  rejectSurvey,

  // Data operations
  exportSurvey,
  exportBulk,
  importSurvey,

  // Analytics & reports
  viewAnalytics,
  viewReports,
  viewAllSurveys, // See surveys from all users

  // User management (admin only)
  manageUsers,
  manageRoles,

  // Settings
  manageSettings,
  viewAuditLog,
}

/// Permission resolver - single source of truth for role-based access control.
///
/// This class defines the permission matrix and provides a clean API
/// for checking if a role has a specific permission.
///
/// Role hierarchy (from most to least privileged):
/// - admin: Full access to everything
/// - manager: Can approve, view all, export, but not manage users
/// - surveyor: Can create/edit own surveys, submit for review
/// - viewer: Read-only access
class PermissionResolver {
  const PermissionResolver._();

  /// Singleton instance
  static const instance = PermissionResolver._();

  /// Permission matrix defining which roles have which permissions.
  /// This is the single source of truth for all permission checks.
  static const Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.admin: {
      // Full access
      Permission.createSurvey,
      Permission.editSurvey,
      Permission.deleteSurvey,
      Permission.viewSurvey,
      Permission.submitReview,
      Permission.approveSurvey,
      Permission.rejectSurvey,
      Permission.exportSurvey,
      Permission.exportBulk,
      Permission.importSurvey,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.viewAllSurveys,
      Permission.manageUsers,
      Permission.manageRoles,
      Permission.manageSettings,
      Permission.viewAuditLog,
    },
    UserRole.manager: {
      // Can manage workflow but not users
      Permission.createSurvey,
      Permission.editSurvey,
      Permission.deleteSurvey,
      Permission.viewSurvey,
      Permission.submitReview,
      Permission.approveSurvey,
      Permission.rejectSurvey,
      Permission.exportSurvey,
      Permission.exportBulk,
      Permission.viewAnalytics,
      Permission.viewReports,
      Permission.viewAllSurveys,
      Permission.viewAuditLog,
    },
    UserRole.surveyor: {
      // Can work on surveys but not approve
      Permission.createSurvey,
      Permission.editSurvey,
      Permission.viewSurvey,
      Permission.submitReview,
      Permission.exportSurvey,
      Permission.viewReports,
    },
    UserRole.viewer: {
      // Read-only
      Permission.viewSurvey,
      Permission.viewReports,
    },
  };

  /// Check if a role has a specific permission.
  ///
  /// Returns false for null role (unauthenticated user).
  bool can(UserRole? role, Permission permission) {
    if (role == null) return false;
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Check if a role has ALL of the specified permissions.
  bool canAll(UserRole? role, List<Permission> permissions) {
    if (role == null) return false;
    return permissions.every((p) => can(role, p));
  }

  /// Check if a role has ANY of the specified permissions.
  bool canAny(UserRole? role, List<Permission> permissions) {
    if (role == null) return false;
    return permissions.any((p) => can(role, p));
  }

  /// Get all permissions for a role.
  Set<Permission> getPermissions(UserRole? role) {
    if (role == null) return {};
    return _rolePermissions[role] ?? {};
  }

  /// Check if role1 has higher or equal privilege than role2.
  bool isAtLeast(UserRole? role, UserRole minimumRole) {
    if (role == null) return false;

    const hierarchy = [
      UserRole.viewer,
      UserRole.surveyor,
      UserRole.manager,
      UserRole.admin,
    ];

    final roleIndex = hierarchy.indexOf(role);
    final minimumIndex = hierarchy.indexOf(minimumRole);

    return roleIndex >= minimumIndex;
  }

  /// Get human-readable name for a role.
  String getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.manager:
        return 'Manager';
      case UserRole.surveyor:
        return 'Surveyor';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  /// Get description for a role.
  String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full system access including user management';
      case UserRole.manager:
        return 'Can approve surveys and view all data';
      case UserRole.surveyor:
        return 'Can create and submit surveys for review';
      case UserRole.viewer:
        return 'Read-only access to assigned surveys';
    }
  }

  /// Get human-readable name for a permission.
  String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.createSurvey:
        return 'Create surveys';
      case Permission.editSurvey:
        return 'Edit surveys';
      case Permission.deleteSurvey:
        return 'Delete surveys';
      case Permission.viewSurvey:
        return 'View surveys';
      case Permission.submitReview:
        return 'Submit for review';
      case Permission.approveSurvey:
        return 'Approve surveys';
      case Permission.rejectSurvey:
        return 'Reject surveys';
      case Permission.exportSurvey:
        return 'Export surveys';
      case Permission.exportBulk:
        return 'Bulk export';
      case Permission.importSurvey:
        return 'Import surveys';
      case Permission.viewAnalytics:
        return 'View analytics';
      case Permission.viewReports:
        return 'View reports';
      case Permission.viewAllSurveys:
        return 'View all surveys';
      case Permission.manageUsers:
        return 'Manage users';
      case Permission.manageRoles:
        return 'Manage roles';
      case Permission.manageSettings:
        return 'Manage settings';
      case Permission.viewAuditLog:
        return 'View audit log';
    }
  }
}

/// Extension on UserRole for convenient permission checking.
extension UserRolePermissions on UserRole {
  /// Check if this role has a specific permission.
  bool can(Permission permission) =>
      PermissionResolver.instance.can(this, permission);

  /// Check if this role has ALL of the specified permissions.
  bool canAll(List<Permission> permissions) =>
      PermissionResolver.instance.canAll(this, permissions);

  /// Check if this role has ANY of the specified permissions.
  bool canAny(List<Permission> permissions) =>
      PermissionResolver.instance.canAny(this, permissions);

  /// Check if this role has higher or equal privilege than another role.
  bool isAtLeast(UserRole minimumRole) =>
      PermissionResolver.instance.isAtLeast(this, minimumRole);

  /// Get the display name for this role.
  String get displayName => PermissionResolver.instance.getRoleName(this);

  /// Get the description for this role.
  String get description => PermissionResolver.instance.getRoleDescription(this);
}

/// Extension on User for convenient permission checking.
extension UserPermissions on User {
  /// Check if this user has a specific permission.
  bool can(Permission permission) =>
      PermissionResolver.instance.can(role, permission);

  /// Check if this user has ALL of the specified permissions.
  bool canAll(List<Permission> permissions) =>
      PermissionResolver.instance.canAll(role, permissions);

  /// Check if this user has ANY of the specified permissions.
  bool canAny(List<Permission> permissions) =>
      PermissionResolver.instance.canAny(role, permissions);
}
