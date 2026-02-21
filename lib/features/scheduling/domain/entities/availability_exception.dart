import 'package:equatable/equatable.dart';

/// Date-specific availability exception
class AvailabilityException extends Equatable {
  const AvailabilityException({
    required this.id,
    required this.userId,
    required this.date,
    required this.isAvailable,
    this.startTime,
    this.endTime,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final bool isAvailable;
  final String? startTime; // "HH:MM" format (if available)
  final String? endTime; // "HH:MM" format (if available)
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilityException copyWith({
    String? id,
    String? userId,
    DateTime? date,
    bool? isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AvailabilityException(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        isAvailable: isAvailable ?? this.isAvailable,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        reason: reason ?? this.reason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        isAvailable,
        startTime,
        endTime,
        reason,
        createdAt,
        updatedAt,
      ];
}
