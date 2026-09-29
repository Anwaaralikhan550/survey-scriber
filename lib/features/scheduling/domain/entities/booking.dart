import 'package:equatable/equatable.dart';

import 'booking_status.dart';

/// The survey type a booking is for. Chosen on the combined Create-Booking
/// screen (App-Edit brief: "Create Booking – 1. Home Surveys 2. Valuations"),
/// replacing the separate "Select Survey Type" step.
enum BookingSurveyType {
  homeSurvey,
  valuation;

  String get wireValue => this == BookingSurveyType.valuation
      ? 'valuation'
      : 'home_survey';

  String get label =>
      this == BookingSurveyType.valuation ? 'Valuation' : 'Home Survey';

  static BookingSurveyType fromWire(String? v) =>
      v == 'valuation' ? BookingSurveyType.valuation : BookingSurveyType.homeSurvey;
}

/// How the surveyor gains access to the property.
enum BookingAccessType {
  directAccess,
  collectKeys;

  String get wireValue =>
      this == BookingAccessType.collectKeys ? 'collect_keys' : 'direct';

  String get label =>
      this == BookingAccessType.collectKeys ? 'Collect Keys' : 'Direct Access';

  static BookingAccessType? fromWire(String? v) {
    if (v == 'collect_keys') return BookingAccessType.collectKeys;
    if (v == 'direct') return BookingAccessType.directAccess;
    return null;
  }
}

/// Surveyor info embedded in booking
class SurveyorInfo extends Equatable {
  const SurveyorInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, firstName, lastName, email];
}

/// Booking/appointment entity
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.surveyorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.surveyType = BookingSurveyType.homeSurvey,
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

  final String id;
  final String surveyorId;
  final DateTime date;
  final String startTime; // "HH:MM" format
  final String endTime; // "HH:MM" format
  final BookingStatus status;

  /// Which survey this booking is for (Home Survey or Valuation).
  final BookingSurveyType surveyType;
  final String? jobRef;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? propertyType; // House / Flat / Bungalow / Other
  final String? yearBuilt;

  /// Legacy single-line address, kept for back-compat. New bookings also
  /// populate the structured fields below.
  final String? propertyAddress;
  final String? addressLine;
  final String? city;
  final String? town;
  final String? postcode;
  final String? county;

  /// Client's notes about the property/appointment.
  final String? notes;

  /// Access arrangement; the estate-agent block applies when [collectKeys].
  final BookingAccessType? accessType;
  final String? estateAgentName;
  final String? estateAgentPhone;
  final String? estateAgentAddress;
  final String? estateAgentNotes;

  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SurveyorInfo? surveyor;

  /// Get formatted time range
  String get timeRange => '$startTime - $endTime';

  /// Check if booking is in the past
  bool get isPast {
    final now = DateTime.now();
    try {
      final parts = endTime.split(':');
      if (parts.length < 2) return false;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final bookingDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      return bookingDateTime.isBefore(now);
    } catch (_) {
      // If time parsing fails, treat as not past (safe default)
      return false;
    }
  }

  /// Check if booking is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Booking copyWith({
    String? id,
    String? surveyorId,
    DateTime? date,
    String? startTime,
    String? endTime,
    BookingStatus? status,
    BookingSurveyType? surveyType,
    String? jobRef,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? propertyType,
    String? yearBuilt,
    String? propertyAddress,
    String? addressLine,
    String? city,
    String? town,
    String? postcode,
    String? county,
    String? notes,
    BookingAccessType? accessType,
    String? estateAgentName,
    String? estateAgentPhone,
    String? estateAgentAddress,
    String? estateAgentNotes,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    SurveyorInfo? surveyor,
  }) =>
      Booking(
        id: id ?? this.id,
        surveyorId: surveyorId ?? this.surveyorId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        surveyType: surveyType ?? this.surveyType,
        jobRef: jobRef ?? this.jobRef,
        clientName: clientName ?? this.clientName,
        clientPhone: clientPhone ?? this.clientPhone,
        clientEmail: clientEmail ?? this.clientEmail,
        propertyType: propertyType ?? this.propertyType,
        yearBuilt: yearBuilt ?? this.yearBuilt,
        propertyAddress: propertyAddress ?? this.propertyAddress,
        addressLine: addressLine ?? this.addressLine,
        city: city ?? this.city,
        town: town ?? this.town,
        postcode: postcode ?? this.postcode,
        county: county ?? this.county,
        notes: notes ?? this.notes,
        accessType: accessType ?? this.accessType,
        estateAgentName: estateAgentName ?? this.estateAgentName,
        estateAgentPhone: estateAgentPhone ?? this.estateAgentPhone,
        estateAgentAddress: estateAgentAddress ?? this.estateAgentAddress,
        estateAgentNotes: estateAgentNotes ?? this.estateAgentNotes,
        createdById: createdById ?? this.createdById,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        surveyor: surveyor ?? this.surveyor,
      );

  @override
  List<Object?> get props => [
        id,
        surveyorId,
        date,
        startTime,
        endTime,
        status,
        surveyType,
        jobRef,
        clientName,
        clientPhone,
        clientEmail,
        propertyType,
        yearBuilt,
        propertyAddress,
        addressLine,
        city,
        town,
        postcode,
        county,
        notes,
        accessType,
        estateAgentName,
        estateAgentPhone,
        estateAgentAddress,
        estateAgentNotes,
        createdById,
        createdAt,
        updatedAt,
        surveyor,
      ];
}
