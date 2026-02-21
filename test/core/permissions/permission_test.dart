import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/permissions/permission.dart';
import 'package:survey_scriber/features/auth/domain/entities/user.dart';

void main() {
  late PermissionResolver resolver;

  setUp(() {
    resolver = PermissionResolver.instance;
  });

  group('Permission enum', () {
    test('all permissions are defined', () {
      expect(Permission.values.length, 17);
      expect(Permission.values, contains(Permission.createSurvey));
      expect(Permission.values, contains(Permission.editSurvey));
      expect(Permission.values, contains(Permission.deleteSurvey));
      expect(Permission.values, contains(Permission.viewSurvey));
      expect(Permission.values, contains(Permission.submitReview));
      expect(Permission.values, contains(Permission.approveSurvey));
      expect(Permission.values, contains(Permission.rejectSurvey));
      expect(Permission.values, contains(Permission.exportSurvey));
      expect(Permission.values, contains(Permission.exportBulk));
      expect(Permission.values, contains(Permission.importSurvey));
      expect(Permission.values, contains(Permission.viewAnalytics));
      expect(Permission.values, contains(Permission.viewReports));
      expect(Permission.values, contains(Permission.viewAllSurveys));
      expect(Permission.values, contains(Permission.manageUsers));
      expect(Permission.values, contains(Permission.manageRoles));
      expect(Permission.values, contains(Permission.manageSettings));
      expect(Permission.values, contains(Permission.viewAuditLog));
    });
  });

  group('PermissionResolver.can', () {
    test('returns false for null role', () {
      expect(resolver.can(null, Permission.viewSurvey), false);
      expect(resolver.can(null, Permission.createSurvey), false);
    });

    group('admin role', () {
      test('has all permissions', () {
        for (final permission in Permission.values) {
          expect(
            resolver.can(UserRole.admin, permission),
            true,
            reason: 'Admin should have $permission',
          );
        }
      });
    });

    group('manager role', () {
      test('can create, edit, delete surveys', () {
        expect(resolver.can(UserRole.manager, Permission.createSurvey), true);
        expect(resolver.can(UserRole.manager, Permission.editSurvey), true);
        expect(resolver.can(UserRole.manager, Permission.deleteSurvey), true);
        expect(resolver.can(UserRole.manager, Permission.viewSurvey), true);
      });

      test('can approve and reject surveys', () {
        expect(resolver.can(UserRole.manager, Permission.approveSurvey), true);
        expect(resolver.can(UserRole.manager, Permission.rejectSurvey), true);
        expect(resolver.can(UserRole.manager, Permission.submitReview), true);
      });

      test('can view all surveys and analytics', () {
        expect(resolver.can(UserRole.manager, Permission.viewAllSurveys), true);
        expect(resolver.can(UserRole.manager, Permission.viewAnalytics), true);
        expect(resolver.can(UserRole.manager, Permission.viewReports), true);
      });

      test('can export but not import', () {
        expect(resolver.can(UserRole.manager, Permission.exportSurvey), true);
        expect(resolver.can(UserRole.manager, Permission.exportBulk), true);
        expect(resolver.can(UserRole.manager, Permission.importSurvey), false);
      });

      test('cannot manage users or roles', () {
        expect(resolver.can(UserRole.manager, Permission.manageUsers), false);
        expect(resolver.can(UserRole.manager, Permission.manageRoles), false);
      });

      test('cannot manage settings but can view audit log', () {
        expect(resolver.can(UserRole.manager, Permission.manageSettings), false);
        expect(resolver.can(UserRole.manager, Permission.viewAuditLog), true);
      });
    });

    group('surveyor role', () {
      test('can create, edit, view surveys', () {
        expect(resolver.can(UserRole.surveyor, Permission.createSurvey), true);
        expect(resolver.can(UserRole.surveyor, Permission.editSurvey), true);
        expect(resolver.can(UserRole.surveyor, Permission.viewSurvey), true);
      });

      test('cannot delete surveys', () {
        expect(resolver.can(UserRole.surveyor, Permission.deleteSurvey), false);
      });

      test('can submit for review but cannot approve', () {
        expect(resolver.can(UserRole.surveyor, Permission.submitReview), true);
        expect(resolver.can(UserRole.surveyor, Permission.approveSurvey), false);
        expect(resolver.can(UserRole.surveyor, Permission.rejectSurvey), false);
      });

      test('can export own surveys but not bulk', () {
        expect(resolver.can(UserRole.surveyor, Permission.exportSurvey), true);
        expect(resolver.can(UserRole.surveyor, Permission.exportBulk), false);
      });

      test('cannot view all surveys or analytics', () {
        expect(resolver.can(UserRole.surveyor, Permission.viewAllSurveys), false);
        expect(resolver.can(UserRole.surveyor, Permission.viewAnalytics), false);
      });

      test('can view reports', () {
        expect(resolver.can(UserRole.surveyor, Permission.viewReports), true);
      });

      test('cannot manage users, roles, or settings', () {
        expect(resolver.can(UserRole.surveyor, Permission.manageUsers), false);
        expect(resolver.can(UserRole.surveyor, Permission.manageRoles), false);
        expect(resolver.can(UserRole.surveyor, Permission.manageSettings), false);
      });
    });

    group('viewer role', () {
      test('can only view surveys and reports', () {
        expect(resolver.can(UserRole.viewer, Permission.viewSurvey), true);
        expect(resolver.can(UserRole.viewer, Permission.viewReports), true);
      });

      test('cannot create, edit, or delete', () {
        expect(resolver.can(UserRole.viewer, Permission.createSurvey), false);
        expect(resolver.can(UserRole.viewer, Permission.editSurvey), false);
        expect(resolver.can(UserRole.viewer, Permission.deleteSurvey), false);
      });

      test('cannot submit or approve', () {
        expect(resolver.can(UserRole.viewer, Permission.submitReview), false);
        expect(resolver.can(UserRole.viewer, Permission.approveSurvey), false);
        expect(resolver.can(UserRole.viewer, Permission.rejectSurvey), false);
      });

      test('cannot export', () {
        expect(resolver.can(UserRole.viewer, Permission.exportSurvey), false);
        expect(resolver.can(UserRole.viewer, Permission.exportBulk), false);
      });

      test('cannot view analytics or all surveys', () {
        expect(resolver.can(UserRole.viewer, Permission.viewAnalytics), false);
        expect(resolver.can(UserRole.viewer, Permission.viewAllSurveys), false);
      });
    });
  });

  group('PermissionResolver.canAll', () {
    test('returns true when role has all permissions', () {
      expect(
        resolver.canAll(
          UserRole.admin,
          [Permission.createSurvey, Permission.deleteSurvey],
        ),
        true,
      );
    });

    test('returns false when role lacks any permission', () {
      expect(
        resolver.canAll(
          UserRole.surveyor,
          [Permission.createSurvey, Permission.deleteSurvey],
        ),
        false,
      );
    });

    test('returns false for null role', () {
      expect(
        resolver.canAll(null, [Permission.viewSurvey]),
        false,
      );
    });

    test('returns true for empty permission list', () {
      expect(resolver.canAll(UserRole.viewer, []), true);
    });
  });

  group('PermissionResolver.canAny', () {
    test('returns true when role has at least one permission', () {
      expect(
        resolver.canAny(
          UserRole.surveyor,
          [Permission.createSurvey, Permission.deleteSurvey],
        ),
        true,
      );
    });

    test('returns false when role has none of the permissions', () {
      expect(
        resolver.canAny(
          UserRole.viewer,
          [Permission.createSurvey, Permission.deleteSurvey],
        ),
        false,
      );
    });

    test('returns false for null role', () {
      expect(
        resolver.canAny(null, [Permission.viewSurvey]),
        false,
      );
    });

    test('returns false for empty permission list', () {
      expect(resolver.canAny(UserRole.admin, []), false);
    });
  });

  group('PermissionResolver.getPermissions', () {
    test('returns empty set for null role', () {
      expect(resolver.getPermissions(null), isEmpty);
    });

    test('returns all permissions for admin', () {
      final permissions = resolver.getPermissions(UserRole.admin);
      expect(permissions.length, Permission.values.length);
    });

    test('returns limited permissions for viewer', () {
      final permissions = resolver.getPermissions(UserRole.viewer);
      expect(permissions.length, 2);
      expect(permissions, contains(Permission.viewSurvey));
      expect(permissions, contains(Permission.viewReports));
    });
  });

  group('PermissionResolver.isAtLeast', () {
    test('returns false for null role', () {
      expect(resolver.isAtLeast(null, UserRole.viewer), false);
    });

    test('admin is at least any role', () {
      expect(resolver.isAtLeast(UserRole.admin, UserRole.admin), true);
      expect(resolver.isAtLeast(UserRole.admin, UserRole.manager), true);
      expect(resolver.isAtLeast(UserRole.admin, UserRole.surveyor), true);
      expect(resolver.isAtLeast(UserRole.admin, UserRole.viewer), true);
    });

    test('manager is at least manager, surveyor, viewer', () {
      expect(resolver.isAtLeast(UserRole.manager, UserRole.admin), false);
      expect(resolver.isAtLeast(UserRole.manager, UserRole.manager), true);
      expect(resolver.isAtLeast(UserRole.manager, UserRole.surveyor), true);
      expect(resolver.isAtLeast(UserRole.manager, UserRole.viewer), true);
    });

    test('surveyor is at least surveyor, viewer', () {
      expect(resolver.isAtLeast(UserRole.surveyor, UserRole.admin), false);
      expect(resolver.isAtLeast(UserRole.surveyor, UserRole.manager), false);
      expect(resolver.isAtLeast(UserRole.surveyor, UserRole.surveyor), true);
      expect(resolver.isAtLeast(UserRole.surveyor, UserRole.viewer), true);
    });

    test('viewer is only at least viewer', () {
      expect(resolver.isAtLeast(UserRole.viewer, UserRole.admin), false);
      expect(resolver.isAtLeast(UserRole.viewer, UserRole.manager), false);
      expect(resolver.isAtLeast(UserRole.viewer, UserRole.surveyor), false);
      expect(resolver.isAtLeast(UserRole.viewer, UserRole.viewer), true);
    });
  });

  group('PermissionResolver.getRoleName', () {
    test('returns correct names', () {
      expect(resolver.getRoleName(UserRole.admin), 'Administrator');
      expect(resolver.getRoleName(UserRole.manager), 'Manager');
      expect(resolver.getRoleName(UserRole.surveyor), 'Surveyor');
      expect(resolver.getRoleName(UserRole.viewer), 'Viewer');
    });
  });

  group('PermissionResolver.getRoleDescription', () {
    test('returns descriptions for all roles', () {
      for (final role in UserRole.values) {
        expect(resolver.getRoleDescription(role), isNotEmpty);
      }
    });
  });

  group('PermissionResolver.getPermissionName', () {
    test('returns names for all permissions', () {
      for (final permission in Permission.values) {
        expect(resolver.getPermissionName(permission), isNotEmpty);
      }
    });
  });

  group('UserRole extensions', () {
    test('can() works correctly', () {
      expect(UserRole.admin.can(Permission.manageUsers), true);
      expect(UserRole.viewer.can(Permission.manageUsers), false);
    });

    test('canAll() works correctly', () {
      expect(
        UserRole.manager.canAll([Permission.approveSurvey, Permission.rejectSurvey]),
        true,
      );
      expect(
        UserRole.surveyor.canAll([Permission.approveSurvey, Permission.rejectSurvey]),
        false,
      );
    });

    test('canAny() works correctly', () {
      expect(
        UserRole.surveyor.canAny([Permission.createSurvey, Permission.manageUsers]),
        true,
      );
      expect(
        UserRole.viewer.canAny([Permission.createSurvey, Permission.manageUsers]),
        false,
      );
    });

    test('isAtLeast() works correctly', () {
      expect(UserRole.manager.isAtLeast(UserRole.surveyor), true);
      expect(UserRole.surveyor.isAtLeast(UserRole.manager), false);
    });

    test('displayName returns correct value', () {
      expect(UserRole.admin.displayName, 'Administrator');
      expect(UserRole.viewer.displayName, 'Viewer');
    });

    test('description returns non-empty value', () {
      for (final role in UserRole.values) {
        expect(role.description, isNotEmpty);
      }
    });
  });

  group('User extensions', () {
    test('can() checks user role permission', () {
      const adminUser = User(
        id: '1',
        email: 'admin@test.com',
        firstName: 'Admin',
        lastName: 'User',
        role: UserRole.admin,
      );

      const viewerUser = User(
        id: '2',
        email: 'viewer@test.com',
        firstName: 'Viewer',
        lastName: 'User',
        role: UserRole.viewer,
      );

      expect(adminUser.can(Permission.manageUsers), true);
      expect(viewerUser.can(Permission.manageUsers), false);
    });

    test('canAll() checks multiple permissions', () {
      const managerUser = User(
        id: '1',
        email: 'manager@test.com',
        firstName: 'Manager',
        lastName: 'User',
        role: UserRole.manager,
      );

      expect(
        managerUser.canAll([Permission.approveSurvey, Permission.viewAllSurveys]),
        true,
      );
      expect(
        managerUser.canAll([Permission.approveSurvey, Permission.manageUsers]),
        false,
      );
    });

    test('canAny() checks any permission', () {
      const surveyorUser = User(
        id: '1',
        email: 'surveyor@test.com',
        firstName: 'Survey',
        lastName: 'User',
      );

      expect(
        surveyorUser.canAny([Permission.createSurvey, Permission.manageUsers]),
        true,
      );
      expect(
        surveyorUser.canAny([Permission.approveSurvey, Permission.manageUsers]),
        false,
      );
    });
  });
}
