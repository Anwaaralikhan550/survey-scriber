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
    this.surveyType,
    this.jobRef,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.propertyType,
    this.yearBuilt,
    this.propertyAddress,
    this.addressLine,
    this.city,
    this.town,
    this.postcode,
    this.county,
    this.notes,
    this.accessType,
    this.estateAgentName,
    this.estateAgentPhone,
    this.estateAgentAddress,
    this.estateAgentNotes,
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
      surveyType: json['surveyType'] as String?,
      jobRef: json['jobRef'] as String?,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      clientEmail: json['clientEmail'] as String?,
      propertyType: json['propertyType'] as String?,
      yearBuilt: json['yearBuilt'] as String?,
      propertyAddress: json['propertyAddress'] as String?,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      town: json['town'] as String?,
      postcode: json['postcode'] as String?,
      county: json['county'] as String?,
      notes: json['notes'] as String?,
      accessType: json['accessType'] as String?,
      estateAgentName: json['estateAgentName'] as String?,
      estateAgentPhone: json['estateAgentPhone'] as String?,
      estateAgentAddress: json['estateAgentAddress'] as String?,
      estateAgentNotes: json['estateAgentNotes'] as String?,
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
  final String? surveyType;
  final String? jobRef;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? propertyType;
  final String? yearBuilt;
  final String? propertyAddress;
  final String? addressLine;
  final String? city;
  final String? town;
  final String? postcode;
  final String? county;
  final String? notes;
  final String? accessType;
  final String? estateAgentName;
  final String? estateAgentPhone;
  final String? estateAgentAddress;
  final String? estateAgentNotes;
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
        surveyType: BookingSurveyType.fromWire(surveyType),
        jobRef: jobRef,
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        propertyType: propertyType,
        yearBuilt: yearBuilt,
        propertyAddress: propertyAddress,
        addressLine: addressLine,
        city: city,
        town: town,
        postcode: postcode,
        county: county,
        notes: notes,
        accessType: BookingAccessType.fromWire(accessType),
        estateAgentName: estateAgentName,
        estateAgentPhone: estateAgentPhone,
        estateAgentAddress: estateAgentAddress,
        estateAgentNotes: estateAgentNotes,
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
