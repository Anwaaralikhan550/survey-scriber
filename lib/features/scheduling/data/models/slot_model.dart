import '../../domain/entities/time_slot.dart';

class TimeSlotModel {
  const TimeSlotModel({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.bookingId,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) => TimeSlotModel(
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isAvailable: json['isAvailable'] as bool,
      bookingId: json['bookingId'] as String?,
    );

  final String date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String? bookingId;

  TimeSlot toEntity() => TimeSlot(
        date: DateTime.parse(date),
        startTime: startTime,
        endTime: endTime,
        isAvailable: isAvailable,
        bookingId: bookingId,
      );
}

class DaySlotsModel {
  const DaySlotsModel({
    required this.date,
    required this.dayOfWeek,
    required this.isWorkingDay,
    this.exceptionReason,
    required this.slots,
  });

  factory DaySlotsModel.fromJson(Map<String, dynamic> json) => DaySlotsModel(
      date: json['date'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      isWorkingDay: json['isWorkingDay'] as bool,
      exceptionReason: json['exceptionReason'] as String?,
      slots: (json['slots'] as List)
          .map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

  final String date;
  final int dayOfWeek;
  final bool isWorkingDay;
  final String? exceptionReason;
  final List<TimeSlotModel> slots;

  DaySlots toEntity() => DaySlots(
        date: DateTime.parse(date),
        dayOfWeek: dayOfWeek,
        isWorkingDay: isWorkingDay,
        exceptionReason: exceptionReason,
        slots: slots.map((s) => s.toEntity()).toList(),
      );
}

class SlotsResponseModel {
  const SlotsResponseModel({
    required this.surveyorId,
    required this.startDate,
    required this.endDate,
    required this.slotDuration,
    required this.days,
  });

  factory SlotsResponseModel.fromJson(Map<String, dynamic> json) => SlotsResponseModel(
      surveyorId: json['surveyorId'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      slotDuration: json['slotDuration'] as int,
      days: (json['days'] as List)
          .map((e) => DaySlotsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

  final String surveyorId;
  final String startDate;
  final String endDate;
  final int slotDuration;
  final List<DaySlotsModel> days;

  SlotsResponse toEntity() => SlotsResponse(
        surveyorId: surveyorId,
        startDate: DateTime.parse(startDate),
        endDate: DateTime.parse(endDate),
        slotDuration: slotDuration,
        days: days.map((d) => d.toEntity()).toList(),
      );
}
