import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

enum UserRole { admin, manager, surveyor, viewer }

enum UserStatus { active, inactive, pending, suspended }

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.organization,
    this.avatarUrl,
    this.role = UserRole.surveyor,
    this.status = UserStatus.active,
    this.emailVerified = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? organization;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final bool emailVerified;
  final DateTime? createdAt;

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  /// Returns the absolute URL for the avatar image.
  /// Converts relative path like `/api/v1/auth/profile/image/...` to full URL.
  String? get avatarAbsoluteUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;

    // If already absolute, return as-is
    if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
      return avatarUrl;
    }

    // Extract origin (scheme + host + port) from base URL
    // baseUrl is like: http://host:port/api/v1/
    final baseUri = Uri.parse(AppConstants.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';

    // avatarUrl is like: /api/v1/auth/profile/image/profiles/{userId}/{file}.jpg
    return '$origin$avatarUrl';
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        organization,
        avatarUrl,
        role,
        status,
        emailVerified,
        createdAt,
      ];
}
