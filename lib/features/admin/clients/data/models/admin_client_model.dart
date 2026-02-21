/// Admin Client Model
/// Used for displaying client information in the admin panel
/// Note: No dedicated client management API exists in the backend.
/// Client data is extracted from invoice responses.
library;

class AdminClientModel {
  const AdminClientModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.company,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.invoiceCount = 0,
    this.bookingCount = 0,
  });

  factory AdminClientModel.fromInvoiceClient(Map<String, dynamic> json) =>
      AdminClientModel(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        company: json['company'] as String?,
        phone: json['phone'] as String?,
      );

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final int invoiceCount;
  final int bookingCount;

  String get displayName {
    if (company != null && company!.isNotEmpty) {
      return company!;
    }
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return email;
  }

  String get fullName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return email;
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (company != null && company!.isNotEmpty) {
      final words = company!.split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      }
      return company![0].toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }

  AdminClientModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? company,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    int? invoiceCount,
    int? bookingCount,
  }) =>
      AdminClientModel(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        company: company ?? this.company,
        phone: phone ?? this.phone,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        invoiceCount: invoiceCount ?? this.invoiceCount,
        bookingCount: bookingCount ?? this.bookingCount,
      );
}
