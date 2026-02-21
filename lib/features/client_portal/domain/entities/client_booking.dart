import 'package:equatable/equatable.dart';

/// Booking status enum matching backend
enum ClientBookingStatus {
  pending,
  confirmed,
  cancelled,
  completed;

  String get displayName {
    switch (this) {
      case ClientBookingStatus.pending:
        return 'Pending';
      case ClientBookingStatus.confirmed:
        return 'Confirmed';
      case ClientBookingStatus.cancelled:
        return 'Cancelled';
      case ClientBookingStatus.completed:
        return 'Completed';
    }
  }

  bool get isActive =>
      this == ClientBookingStatus.pending ||
      this == ClientBookingStatus.confirmed;
}

/// Surveyor summary for client view
class SurveyorSummary extends Equatable {
  const SurveyorSummary({
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String? phone;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [firstName, lastName, phone];
}

/// Client booking entity
class ClientBooking extends Equatable {
  const ClientBooking({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.surveyor,
    required this.createdAt,
    this.propertyAddress,
    this.notes,
  });

  final String id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final ClientBookingStatus status;
  final SurveyorSummary surveyor;
  final DateTime createdAt;
  final String? propertyAddress;
  final String? notes;

  /// Formatted time range
  String get timeRange => '$startTime - $endTime';

  /// Check if booking is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final bookingDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return bookingDate.isAfter(today) ||
        (bookingDate.isAtSameMomentAs(today) && status.isActive);
  }

  @override
  List<Object?> get props => [
        id,
        date,
        startTime,
        endTime,
        status,
        surveyor,
        createdAt,
        propertyAddress,
        notes,
      ];
}
