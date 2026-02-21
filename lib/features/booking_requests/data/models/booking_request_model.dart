import '../../domain/entities/booking_request.dart';

/// Model for BookingRequest with JSON serialization
class BookingRequestModel extends BookingRequest {
  const BookingRequestModel({
    required super.id,
    required super.clientId,
    required super.propertyAddress,
    required super.preferredStartDate,
    required super.preferredEndDate,
    required super.status,
    required super.createdAt,
    super.notes,
    super.reviewedAt,
    super.reviewedById,
    super.client,
    super.reviewedBy,
  });

  factory BookingRequestModel.fromJson(Map<String, dynamic> json) => BookingRequestModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      propertyAddress: json['propertyAddress'] as String,
      preferredStartDate: DateTime.parse(json['preferredStartDate'] as String),
      preferredEndDate: DateTime.parse(json['preferredEndDate'] as String),
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedById: json['reviewedById'] as String?,
      client: json['client'] != null
          ? BookingRequestClientModel.fromJson(
              json['client'] as Map<String, dynamic>,
            )
          : null,
      reviewedBy: json['reviewedBy'] != null
          ? BookingRequestReviewerModel.fromJson(
              json['reviewedBy'] as Map<String, dynamic>,
            )
          : null,
    );

  static BookingRequestStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return BookingRequestStatus.requested;
      case 'APPROVED':
        return BookingRequestStatus.approved;
      case 'REJECTED':
        return BookingRequestStatus.rejected;
      default:
        return BookingRequestStatus.requested;
    }
  }
}

class BookingRequestClientModel extends BookingRequestClient {
  const BookingRequestClientModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.phone,
    super.company,
  });

  factory BookingRequestClientModel.fromJson(Map<String, dynamic> json) => BookingRequestClientModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
    );
}

class BookingRequestReviewerModel extends BookingRequestReviewer {
  const BookingRequestReviewerModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
  });

  factory BookingRequestReviewerModel.fromJson(Map<String, dynamic> json) => BookingRequestReviewerModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
}

/// Response model for list of booking requests
class BookingRequestsResponseModel {
  const BookingRequestsResponseModel({
    required this.requests,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory BookingRequestsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return BookingRequestsResponseModel(
      requests: data
          .map(
            (e) => BookingRequestModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }

  final List<BookingRequestModel> requests;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
