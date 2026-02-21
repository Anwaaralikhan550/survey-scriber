import 'package:equatable/equatable.dart';

/// Booking change request type
enum BookingChangeRequestType {
  reschedule,
  cancel;

  String get displayName {
    switch (this) {
      case BookingChangeRequestType.reschedule:
        return 'Reschedule';
      case BookingChangeRequestType.cancel:
        return 'Cancellation';
    }
  }

  bool get isReschedule => this == BookingChangeRequestType.reschedule;
  bool get isCancel => this == BookingChangeRequestType.cancel;
}

/// Booking change request status
enum BookingChangeRequestStatus {
  requested,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case BookingChangeRequestStatus.requested:
        return 'Pending Review';
      case BookingChangeRequestStatus.approved:
        return 'Approved';
      case BookingChangeRequestStatus.rejected:
        return 'Declined';
    }
  }

  bool get isPending => this == BookingChangeRequestStatus.requested;
  bool get isApproved => this == BookingChangeRequestStatus.approved;
  bool get isRejected => this == BookingChangeRequestStatus.rejected;
}

/// Client summary for staff view
class ChangeRequestClient extends Equatable {
  const ChangeRequestClient({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email;
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, phone];
}

/// Reviewer summary
class ChangeRequestReviewer extends Equatable {
  const ChangeRequestReviewer({
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

/// Booking summary
class ChangeRequestBooking extends Equatable {
  const ChangeRequestBooking({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.propertyAddress,
  });

  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? propertyAddress;

  String get timeRange => '$startTime - $endTime';

  String get formattedDate => '${date.day}/${date.month}/${date.year}';

  @override
  List<Object?> get props =>
      [id, date, startTime, endTime, status, propertyAddress];
}

/// Booking change request entity
class BookingChangeRequest extends Equatable {
  const BookingChangeRequest({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.proposedDate,
    this.proposedStartTime,
    this.proposedEndTime,
    this.reason,
    this.reviewedAt,
    this.reviewedById,
    this.booking,
    this.client,
    this.reviewedBy,
  });

  final String id;
  final String bookingId;
  final String clientId;
  final BookingChangeRequestType type;
  final BookingChangeRequestStatus status;
  final DateTime createdAt;
  final DateTime? proposedDate;
  final String? proposedStartTime;
  final String? proposedEndTime;
  final String? reason;
  final DateTime? reviewedAt;
  final String? reviewedById;
  final ChangeRequestBooking? booking;
  final ChangeRequestClient? client;
  final ChangeRequestReviewer? reviewedBy;

  /// Formatted proposed date
  String? get formattedProposedDate {
    if (proposedDate == null) return null;
    return '${proposedDate!.day}/${proposedDate!.month}/${proposedDate!.year}';
  }

  /// Proposed time range
  String? get proposedTimeRange {
    if (proposedStartTime == null || proposedEndTime == null) return null;
    return '$proposedStartTime - $proposedEndTime';
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        clientId,
        type,
        status,
        createdAt,
        proposedDate,
        proposedStartTime,
        proposedEndTime,
        reason,
        reviewedAt,
        reviewedById,
        booking,
        client,
        reviewedBy,
      ];
}

/// Paginated change requests result
class BookingChangeRequestsResult {
  const BookingChangeRequestsResult({
    required this.requests,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<BookingChangeRequest> requests;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
