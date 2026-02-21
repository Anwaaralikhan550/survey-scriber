import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/auth/data/models/user_model.dart';
import 'package:survey_scriber/features/auth/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    group('fromJson', () {
      test('should parse complete user JSON correctly', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
          'phone': '+1234567890',
          'organization': 'ACME Corp',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'role': 'SURVEYOR',
          'emailVerified': true,
          'createdAt': '2024-01-15T10:30:00.000Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.firstName, 'John');
        expect(user.lastName, 'Doe');
        expect(user.phone, '+1234567890');
        expect(user.organization, 'ACME Corp');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.role, UserRole.surveyor);
        expect(user.emailVerified, true);
        expect(user.createdAt, isNotNull);
      });

      test('should handle null firstName gracefully (returns empty string)', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'firstName': null,
          'lastName': 'Doe',
        };

        final user = UserModel.fromJson(json);

        expect(user.firstName, '');
        expect(user.lastName, 'Doe');
        expect(user.fullName, ' Doe'); // Expected: empty firstName + space + lastName
      });

      test('should handle null lastName gracefully (returns empty string)', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': null,
        };

        final user = UserModel.fromJson(json);

        expect(user.firstName, 'John');
        expect(user.lastName, '');
        expect(user.fullName, 'John '); // Expected: firstName + space + empty lastName
      });

      test('should handle both firstName and lastName being null', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          // No firstName or lastName in response
        };

        final user = UserModel.fromJson(json);

        expect(user.firstName, '');
        expect(user.lastName, '');
        expect(user.fullName, ' '); // Both empty with space between
      });

      test('should handle snake_case field names from legacy APIs', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'first_name': 'John',
          'last_name': 'Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'email_verified': true,
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final user = UserModel.fromJson(json);

        expect(user.firstName, 'John');
        expect(user.lastName, 'Doe');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.emailVerified, true);
        expect(user.createdAt, isNotNull);
      });

      test('should prefer camelCase over snake_case when both present', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'firstName': 'CamelCaseFirst',
          'first_name': 'SnakeCaseFirst',
          'lastName': 'CamelCaseLast',
          'last_name': 'SnakeCaseLast',
        };

        final user = UserModel.fromJson(json);

        expect(user.firstName, 'CamelCaseFirst');
        expect(user.lastName, 'CamelCaseLast');
      });

      test('should default role to surveyor when not provided', () {
        final json = {
          'id': 'user-123',
          'email': 'test@example.com',
          'firstName': 'John',
          'lastName': 'Doe',
        };

        final user = UserModel.fromJson(json);

        expect(user.role, UserRole.surveyor);
      });

      test('should parse all role types correctly', () {
        for (final role in ['ADMIN', 'MANAGER', 'SURVEYOR', 'VIEWER']) {
          final json = {
            'id': 'user-123',
            'email': 'test@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'role': role,
          };

          final user = UserModel.fromJson(json);
          expect(user.role.name, role.toLowerCase());
        }
      });
    });

    group('fullName getter', () {
      test('should concatenate firstName and lastName', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(user.fullName, 'John Doe');
      });

      test('should handle empty firstName', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: '',
          lastName: 'Doe',
        );

        expect(user.fullName, ' Doe');
      });

      test('should handle empty lastName', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: '',
        );

        expect(user.fullName, 'John ');
      });
    });

    group('initials getter', () {
      test('should return first letters of firstName and lastName', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(user.initials, 'JD');
      });

      test('should handle empty firstName', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: '',
          lastName: 'Doe',
        );

        expect(user.initials, 'D');
      });

      test('should handle empty lastName', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: '',
        );

        expect(user.initials, 'J');
      });
    });

    group('toJson', () {
      test('should serialize user to JSON correctly', () {
        const user = UserModel(
          id: 'user-123',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+1234567890',
          organization: 'ACME Corp',
          avatarUrl: 'https://example.com/avatar.jpg',
          role: UserRole.admin,
          emailVerified: true,
        );

        final json = user.toJson();

        expect(json['id'], 'user-123');
        expect(json['email'], 'test@example.com');
        expect(json['firstName'], 'John');
        expect(json['lastName'], 'Doe');
        expect(json['phone'], '+1234567890');
        expect(json['organization'], 'ACME Corp');
        expect(json['avatarUrl'], 'https://example.com/avatar.jpg');
        expect(json['role'], 'admin');
        expect(json['emailVerified'], true);
      });
    });
  });
}
