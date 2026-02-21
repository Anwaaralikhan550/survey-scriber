import 'package:equatable/equatable.dart';

/// Weekly availability entity for a surveyor
class Availability extends Equatable {
  const Availability({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final int dayOfWeek; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String startTime; // "HH:MM" format
  final String endTime; // "HH:MM" format
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Get day name
  String get dayName {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[dayOfWeek];
  }

  /// Get short day name
  String get shortDayName {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }

  Availability copyWith({
    String? id,
    String? userId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Availability(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        dayOfWeek,
        startTime,
        endTime,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Data for setting a day's availability
class DayAvailabilityInput {
  const DayAvailabilityInput({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isActive': isActive,
      };
}
