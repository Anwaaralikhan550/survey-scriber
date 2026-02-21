import 'package:equatable/equatable.dart';

/// Booking request status enum matching backend
enum BookingRequestStatus {
  requested,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case BookingRequestStatus.requested:
        return 'Pending Review';
      case BookingRequestStatus.approved:
        return 'Approved';
      case BookingRequestStatus.rejected:
        return 'Declined';
    }
  }

  bool get isPending => this == BookingRequestStatus.requested;
  bool get isApproved => this == BookingRequestStatus.approved;
  bool get isRejected => this == BookingRequestStatus.rejected;
}

/// Client summary for staff view
class BookingRequestClient extends Equatable {
  const BookingRequestClient({
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

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email;
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, phone, company];
}

/// Reviewer summary
class BookingRequestReviewer extends Equatable {
  const BookingRequestReviewer({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email;
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName];
}

/// Booking request entity
class BookingRequest extends Equatable {
  const BookingRequest({
    required this.id,
    required this.clientId,
    required this.propertyAddress,
    required this.preferredStartDate,
    required this.preferredEndDate,
    required this.status,
    required this.createdAt,
    this.notes,
    this.reviewedAt,
    this.reviewedById,
    this.client,
    this.reviewedBy,
  });

  final String id;
  final String clientId;
  final String propertyAddress;
  final DateTime preferredStartDate;
  final DateTime preferredEndDate;
  final BookingRequestStatus status;
  final DateTime createdAt;
  final String? notes;
  final DateTime? reviewedAt;
  final String? reviewedById;
  final BookingRequestClient? client;
  final BookingRequestReviewer? reviewedBy;

  /// Formatted date range
  String get dateRange {
    final startStr = '${preferredStartDate.day}/${preferredStartDate.month}/${preferredStartDate.year}';
    final endStr = '${preferredEndDate.day}/${preferredEndDate.month}/${preferredEndDate.year}';
    if (startStr == endStr) return startStr;
    return '$startStr - $endStr';
  }

  @override
  List<Object?> get props => [
        id,
        clientId,
        propertyAddress,
        preferredStartDate,
        preferredEndDate,
        status,
        createdAt,
        notes,
        reviewedAt,
        reviewedById,
        client,
        reviewedBy,
      ];
}

/// Paginated booking requests result
class BookingRequestsResult {
  const BookingRequestsResult({
    required this.requests,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<BookingRequest> requests;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
