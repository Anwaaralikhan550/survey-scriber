import 'package:equatable/equatable.dart';

/// Client entity representing a portal user
class Client extends Equatable {
  const Client({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.company,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? company;

  /// Full display name
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email.split('@').first;
  }

  /// Full name (alias for displayName)
  String get fullName => displayName;

  /// Initials for avatar
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    }
    if (lastName != null && lastName!.isNotEmpty) {
      return lastName![0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  /// Short greeting name
  String get greetingName => firstName ?? email.split('@').first;

  @override
  List<Object?> get props => [id, email, firstName, lastName, phone, company];
}
