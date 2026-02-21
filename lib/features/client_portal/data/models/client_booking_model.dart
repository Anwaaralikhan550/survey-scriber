import '../../domain/entities/client_booking.dart';

/// Surveyor summary model
class SurveyorSummaryModel extends SurveyorSummary {
  const SurveyorSummaryModel({
    required super.firstName,
    required super.lastName,
    super.phone,
  });

  factory SurveyorSummaryModel.fromJson(Map<String, dynamic> json) => SurveyorSummaryModel(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String?,
    );
}

/// Client booking model
class ClientBookingModel extends ClientBooking {
  const ClientBookingModel({
    required super.id,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.surveyor,
    required super.createdAt,
    super.propertyAddress,
    super.notes,
  });

  factory ClientBookingModel.fromJson(Map<String, dynamic> json) => ClientBookingModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: _parseStatus(json['status'] as String),
      surveyor: SurveyorSummaryModel.fromJson(
        json['surveyor'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      propertyAddress: json['propertyAddress'] as String?,
      notes: json['notes'] as String?,
    );

  static ClientBookingStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return ClientBookingStatus.pending;
      case 'CONFIRMED':
        return ClientBookingStatus.confirmed;
      case 'CANCELLED':
        return ClientBookingStatus.cancelled;
      case 'COMPLETED':
        return ClientBookingStatus.completed;
      default:
        return ClientBookingStatus.pending;
    }
  }
}

/// Bookings list response model
class ClientBookingsResponseModel {
  const ClientBookingsResponseModel({
    required this.bookings,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ClientBookingsResponseModel.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return ClientBookingsResponseModel(
      bookings: (json['data'] as List)
          .map((e) => ClientBookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }

  final List<ClientBookingModel> bookings;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
