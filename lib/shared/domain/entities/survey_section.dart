import 'package:equatable/equatable.dart';

import 'survey_answer.dart';

enum SectionType {
  // Inspection specific (new)
  aboutInspection,
  // Property details
  aboutProperty,
  construction,
  // Inspection items (new)
  externalItems,
  internalItems,
  // Room & services
  rooms,
  exterior,
  interior,
  services,
  // Issues tracking (new)
  issuesAndRisks,
  // Documentation
  photos,
  notes,
  signature,
  // Valuation specific
  aboutValuation,
  propertySummary,
  marketAnalysis,
  comparables,
  adjustments,
  valuation,
  summary,
}

class SurveySection extends Equatable {
  const SurveySection({
    required this.id,
    required this.surveyId,
    required this.sectionType,
    required this.title,
    required this.order,
    this.isCompleted = false,
    this.answers = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String surveyId;
  final SectionType sectionType;
  final String title;
  final int order;
  final bool isCompleted;
  final List<SurveyAnswer> answers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SurveySection copyWith({
    String? id,
    String? surveyId,
    SectionType? sectionType,
    String? title,
    int? order,
    bool? isCompleted,
    List<SurveyAnswer>? answers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SurveySection(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionType: sectionType ?? this.sectionType,
        title: title ?? this.title,
        order: order ?? this.order,
        isCompleted: isCompleted ?? this.isCompleted,
        answers: answers ?? this.answers,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        surveyId,
        sectionType,
        title,
        order,
        isCompleted,
        answers,
        createdAt,
        updatedAt,
      ];
}

/// Template sections for different survey types
class SectionTemplates {
  /// Returns the default sections for a new property inspection survey.
  /// This is the industry-standard comprehensive inspection flow.
  static List<(SectionType, String)> getInspectionSections() => [
        (SectionType.aboutInspection, 'About This Inspection'),
        (SectionType.aboutProperty, 'About Property'),
        (SectionType.construction, 'Construction Details'),
        (SectionType.externalItems, 'External Inspection'),
        (SectionType.internalItems, 'Internal Inspection'),
        (SectionType.rooms, 'Room Details'),
        (SectionType.services, 'Services & Utilities'),
        (SectionType.issuesAndRisks, 'Issues & Risks'),
        (SectionType.photos, 'Photo Documentation'),
        (SectionType.notes, 'Additional Notes'),
        (SectionType.signature, 'Sign Off'),
      ];

  /// Returns the legacy inspection sections for backward compatibility.
  /// Used for existing surveys that don't have the new sections.
  static List<(SectionType, String)> getLegacyInspectionSections() => [
        (SectionType.aboutProperty, 'About Property'),
        (SectionType.construction, 'Construction Details'),
        (SectionType.exterior, 'Exterior Assessment'),
        (SectionType.interior, 'Interior Assessment'),
        (SectionType.rooms, 'Room Details'),
        (SectionType.services, 'Services & Utilities'),
        (SectionType.photos, 'Photo Documentation'),
        (SectionType.notes, 'Additional Notes'),
        (SectionType.signature, 'Sign Off'),
      ];

  /// Returns the enhanced valuation sections (9 sections).
  /// This is the industry-standard professional valuation flow.
  static List<(SectionType, String)> getValuationSections() => [
        (SectionType.aboutValuation, 'About Valuation'),
        (SectionType.propertySummary, 'Property Summary'),
        (SectionType.marketAnalysis, 'Market Analysis'),
        (SectionType.comparables, 'Comparable Properties'),
        (SectionType.adjustments, 'Value Adjustments'),
        (SectionType.valuation, 'Final Valuation'),
        (SectionType.summary, 'Notes & Assumptions'),
        (SectionType.photos, 'Photo Evidence'),
        (SectionType.signature, 'Sign Off'),
      ];

  /// Returns the legacy valuation sections for backward compatibility.
  /// Used for existing valuation surveys that don't have the enhanced sections.
  static List<(SectionType, String)> getLegacyValuationSections() => [
        (SectionType.aboutProperty, 'Property Information'),
        (SectionType.marketAnalysis, 'Market Analysis'),
        (SectionType.comparables, 'Comparable Properties'),
        (SectionType.valuation, 'Valuation Assessment'),
        (SectionType.photos, 'Photo Evidence'),
        (SectionType.summary, 'Summary & Conclusion'),
        (SectionType.signature, 'Sign Off'),
      ];

  /// Get section icon based on section type
  static String getSectionIcon(SectionType type) => switch (type) {
        SectionType.aboutInspection => 'clipboard_check',
        SectionType.aboutProperty => 'home',
        SectionType.construction => 'construction',
        SectionType.externalItems => 'landscape',
        SectionType.internalItems => 'door_open',
        SectionType.exterior => 'landscape',
        SectionType.interior => 'weekend',
        SectionType.rooms => 'meeting_room',
        SectionType.services => 'electrical_services',
        SectionType.issuesAndRisks => 'warning',
        SectionType.photos => 'camera_alt',
        SectionType.notes => 'note',
        SectionType.signature => 'draw',
        SectionType.aboutValuation => 'assignment',
        SectionType.propertySummary => 'home_work',
        SectionType.marketAnalysis => 'analytics',
        SectionType.comparables => 'compare',
        SectionType.adjustments => 'tune',
        SectionType.valuation => 'price_check',
        SectionType.summary => 'summarize',
      };
}
