import '../../domain/entities/availability_exception.dart';

class ExceptionModel {
  const ExceptionModel({
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

  factory ExceptionModel.fromJson(Map<String, dynamic> json) => ExceptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: json['date'] as String,
      isAvailable: json['isAvailable'] as bool? ?? false,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

  final String id;
  final String userId;
  final String date;
  final bool isAvailable;
  final String? startTime;
  final String? endTime;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilityException toEntity() => AvailabilityException(
        id: id,
        userId: userId,
        date: DateTime.parse(date),
        isAvailable: isAvailable,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
