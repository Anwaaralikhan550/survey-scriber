import 'dart:convert';

import 'package:equatable/equatable.dart';

class SurveyAnswer extends Equatable {
  const SurveyAnswer({
    required this.id,
    required this.surveyId,
    required this.sectionId,
    required this.fieldKey,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String surveyId;
  final String sectionId;
  final String fieldKey;
  final String? value;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Parse value as JSON map if possible
  Map<String, dynamic>? get valueAsMap {
    if (value == null || value!.isEmpty) return null;
    try {
      return json.decode(value!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Parse value as JSON list if possible
  List<dynamic>? get valueAsList {
    if (value == null || value!.isEmpty) return null;
    try {
      return json.decode(value!) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  SurveyAnswer copyWith({
    String? id,
    String? surveyId,
    String? sectionId,
    String? fieldKey,
    String? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SurveyAnswer(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionId: sectionId ?? this.sectionId,
        fieldKey: fieldKey ?? this.fieldKey,
        value: value ?? this.value,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        surveyId,
        sectionId,
        fieldKey,
        value,
        createdAt,
        updatedAt,
      ];
}

/// Container for all answers in a section
class SectionAnswers {
  SectionAnswers({
    required this.sectionId,
    Map<String, String>? answers,
  }) : _answers = answers ?? {};

  factory SectionAnswers.fromJson(String sectionId, Map<String, dynamic> json) => SectionAnswers(
      sectionId: sectionId,
      answers: json.map((key, value) => MapEntry(key, value.toString())),
    );

  final String sectionId;
  final Map<String, String> _answers;

  Map<String, String> get answers => Map.unmodifiable(_answers);

  String? getValue(String key) => _answers[key];

  void setValue(String key, String value) {
    _answers[key] = value;
  }

  bool get isEmpty => _answers.isEmpty;
  bool get isNotEmpty => _answers.isNotEmpty;

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_answers);
}
