import 'package:equatable/equatable.dart';

/// Single time slot
class TimeSlot extends Equatable {
  const TimeSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.bookingId,
  });

  final DateTime date;
  final String startTime; // "HH:MM" format
  final String endTime; // "HH:MM" format
  final bool isAvailable;
  final String? bookingId;

  /// Get formatted time range
  String get timeRange => '$startTime - $endTime';

  @override
  List<Object?> get props => [
        date,
        startTime,
        endTime,
        isAvailable,
        bookingId,
      ];
}

/// Day with its slots
class DaySlots extends Equatable {
  const DaySlots({
    required this.date,
    required this.dayOfWeek,
    required this.isWorkingDay,
    this.exceptionReason,
    required this.slots,
  });

  final DateTime date;
  final int dayOfWeek; // 0=Sunday, 6=Saturday
  final bool isWorkingDay;
  final String? exceptionReason;
  final List<TimeSlot> slots;

  /// Get available slots only
  List<TimeSlot> get availableSlots =>
      slots.where((s) => s.isAvailable).toList();

  /// Check if any slots are available
  bool get hasAvailableSlots => availableSlots.isNotEmpty;

  @override
  List<Object?> get props => [
        date,
        dayOfWeek,
        isWorkingDay,
        exceptionReason,
        slots,
      ];
}

/// Slots response for a date range
class SlotsResponse extends Equatable {
  const SlotsResponse({
    required this.surveyorId,
    required this.startDate,
    required this.endDate,
    required this.slotDuration,
    required this.days,
  });

  final String surveyorId;
  final DateTime startDate;
  final DateTime endDate;
  final int slotDuration;
  final List<DaySlots> days;

  @override
  List<Object?> get props => [
        surveyorId,
        startDate,
        endDate,
        slotDuration,
        days,
      ];
}
