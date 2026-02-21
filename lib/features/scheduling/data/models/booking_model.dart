import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';

class SurveyorInfoModel {
  const SurveyorInfoModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory SurveyorInfoModel.fromJson(Map<String, dynamic> json) => SurveyorInfoModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String,
    );

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  SurveyorInfo toEntity() => SurveyorInfo(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.surveyorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.propertyAddress,
    this.notes,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.surveyor,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
      id: json['id'] as String,
      surveyorId: json['surveyorId'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      clientEmail: json['clientEmail'] as String?,
      propertyAddress: json['propertyAddress'] as String?,
      notes: json['notes'] as String?,
      createdById: json['createdById'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      surveyor: json['surveyor'] != null
          ? SurveyorInfoModel.fromJson(json['surveyor'] as Map<String, dynamic>)
          : null,
    );

  final String id;
  final String surveyorId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? propertyAddress;
  final String? notes;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SurveyorInfoModel? surveyor;

  Booking toEntity() => Booking(
        id: id,
        surveyorId: surveyorId,
        date: DateTime.parse(date),
        startTime: startTime,
        endTime: endTime,
        status: BookingStatus.fromBackendString(status),
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        propertyAddress: propertyAddress,
        notes: notes,
        createdById: createdById,
        createdAt: createdAt,
        updatedAt: updatedAt,
        surveyor: surveyor?.toEntity(),
      );
}

class BookingListResponse {
  const BookingListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) => BookingListResponse(
      data: (json['data'] as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );

  final List<BookingModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
}
