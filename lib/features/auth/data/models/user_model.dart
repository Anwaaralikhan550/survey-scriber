import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    super.phone,
    super.organization,
    super.avatarUrl,
    super.role,
    super.status,
    super.emailVerified,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        // FIX: Handle null firstName/lastName gracefully (backend may return undefined)
        firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
        lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
        phone: json['phone'] as String?,
        organization: json['organization'] as String?,
        avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
        role: _parseRole(json['role'] as String?),
        status: _parseStatus(json['status'] as String?),
        emailVerified:
            json['emailVerified'] as bool? ??
            json['email_verified'] as bool? ??
            false,
        createdAt:
            json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'] as String)
                : json['created_at'] != null
                    ? DateTime.tryParse(json['created_at'] as String)
                    : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'organization': organization,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'status': status.name,
        'emailVerified': emailVerified,
        'createdAt': createdAt?.toIso8601String(),
      };

  static UserRole _parseRole(String? role) {
    if (role == null) return UserRole.surveyor;
    final roleLower = role.toLowerCase();
    return UserRole.values.firstWhere(
      (e) => e.name == roleLower,
      orElse: () => UserRole.surveyor,
    );
  }

  static UserStatus _parseStatus(String? status) {
    if (status == null) return UserStatus.active;
    return UserStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => UserStatus.active,
    );
  }
}
