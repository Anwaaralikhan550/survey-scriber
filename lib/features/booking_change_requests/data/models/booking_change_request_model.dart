import '../../domain/entities/booking_change_request.dart';

/// Model for parsing booking change request from API
class BookingChangeRequestModel {
  const BookingChangeRequestModel({
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

  factory BookingChangeRequestModel.fromJson(Map<String, dynamic> json) => BookingChangeRequestModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      clientId: json['clientId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      proposedDate: json['proposedDate'] != null
          ? DateTime.parse(json['proposedDate'] as String)
          : null,
      proposedStartTime: json['proposedStartTime'] as String?,
      proposedEndTime: json['proposedEndTime'] as String?,
      reason: json['reason'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedById: json['reviewedById'] as String?,
      booking: json['booking'] != null
          ? ChangeRequestBookingModel.fromJson(
              json['booking'] as Map<String, dynamic>,)
          : null,
      client: json['client'] != null
          ? ChangeRequestClientModel.fromJson(
              json['client'] as Map<String, dynamic>,)
          : null,
      reviewedBy: json['reviewedBy'] != null
          ? ChangeRequestReviewerModel.fromJson(
              json['reviewedBy'] as Map<String, dynamic>,)
          : null,
    );

  final String id;
  final String bookingId;
  final String clientId;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? proposedDate;
  final String? proposedStartTime;
  final String? proposedEndTime;
  final String? reason;
  final DateTime? reviewedAt;
  final String? reviewedById;
  final ChangeRequestBookingModel? booking;
  final ChangeRequestClientModel? client;
  final ChangeRequestReviewerModel? reviewedBy;

  BookingChangeRequest toEntity() => BookingChangeRequest(
      id: id,
      bookingId: bookingId,
      clientId: clientId,
      type: _parseType(type),
      status: _parseStatus(status),
      createdAt: createdAt,
      proposedDate: proposedDate,
      proposedStartTime: proposedStartTime,
      proposedEndTime: proposedEndTime,
      reason: reason,
      reviewedAt: reviewedAt,
      reviewedById: reviewedById,
      booking: booking?.toEntity(),
      client: client?.toEntity(),
      reviewedBy: reviewedBy?.toEntity(),
    );

  static BookingChangeRequestType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'RESCHEDULE':
        return BookingChangeRequestType.reschedule;
      case 'CANCEL':
        return BookingChangeRequestType.cancel;
      default:
        return BookingChangeRequestType.cancel;
    }
  }

  static BookingChangeRequestStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return BookingChangeRequestStatus.requested;
      case 'APPROVED':
        return BookingChangeRequestStatus.approved;
      case 'REJECTED':
        return BookingChangeRequestStatus.rejected;
      default:
        return BookingChangeRequestStatus.requested;
    }
  }
}

/// Model for booking summary in change request
class ChangeRequestBookingModel {
  const ChangeRequestBookingModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.propertyAddress,
  });

  factory ChangeRequestBookingModel.fromJson(Map<String, dynamic> json) => ChangeRequestBookingModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String,
      propertyAddress: json['propertyAddress'] as String?,
    );

  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? propertyAddress;

  ChangeRequestBooking toEntity() => ChangeRequestBooking(
      id: id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status,
      propertyAddress: propertyAddress,
    );
}

/// Model for client summary in change request
class ChangeRequestClientModel {
  const ChangeRequestClientModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  factory ChangeRequestClientModel.fromJson(Map<String, dynamic> json) => ChangeRequestClientModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
    );

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;

  ChangeRequestClient toEntity() => ChangeRequestClient(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
}

/// Model for reviewer summary in change request
class ChangeRequestReviewerModel {
  const ChangeRequestReviewerModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory ChangeRequestReviewerModel.fromJson(Map<String, dynamic> json) => ChangeRequestReviewerModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  ChangeRequestReviewer toEntity() => ChangeRequestReviewer(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
}

/// Model for paginated change requests response
class BookingChangeRequestsResultModel {
  const BookingChangeRequestsResultModel({
    required this.requests,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory BookingChangeRequestsResultModel.fromJson(Map<String, dynamic> json) => BookingChangeRequestsResultModel(
      requests: (json['requests'] as List<dynamic>)
          .map((e) =>
              BookingChangeRequestModel.fromJson(e as Map<String, dynamic>),)
          .toList(),
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );

  final List<BookingChangeRequestModel> requests;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  BookingChangeRequestsResult toEntity() => BookingChangeRequestsResult(
      requests: requests.map((e) => e.toEntity()).toList(),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
}
