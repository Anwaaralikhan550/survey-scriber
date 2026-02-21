import 'package:equatable/equatable.dart';

import 'booking_status.dart';

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

  final String id;
  final String surveyorId;
  final DateTime date;
  final String startTime; // "HH:MM" format
  final String endTime; // "HH:MM" format
  final BookingStatus status;
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? propertyAddress;
  final String? notes;
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
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? propertyAddress,
    String? notes,
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
        clientName: clientName ?? this.clientName,
        clientPhone: clientPhone ?? this.clientPhone,
        clientEmail: clientEmail ?? this.clientEmail,
        propertyAddress: propertyAddress ?? this.propertyAddress,
        notes: notes ?? this.notes,
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
        clientName,
        clientPhone,
        clientEmail,
        propertyAddress,
        notes,
        createdById,
        createdAt,
        updatedAt,
        surveyor,
      ];
}
