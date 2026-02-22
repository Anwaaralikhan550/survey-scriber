import 'package:equatable/equatable.dart';

enum SurveyStatus {
  draft,
  inProgress,
  paused,
  completed,
  pendingReview,
  approved,
  rejected;

  /// Convert to backend string format (e.g., 'IN_PROGRESS')
  String toBackendString() {
    switch (this) {
      case SurveyStatus.draft:
        return 'DRAFT';
      case SurveyStatus.inProgress:
        return 'IN_PROGRESS';
      case SurveyStatus.paused:
        return 'PAUSED';
      case SurveyStatus.completed:
        return 'COMPLETED';
      case SurveyStatus.pendingReview:
        return 'PENDING_REVIEW';
      case SurveyStatus.approved:
        return 'APPROVED';
      case SurveyStatus.rejected:
        return 'REJECTED';
    }
  }

  /// Parse from backend string format
  static SurveyStatus fromBackendString(String value) {
    switch (value.toUpperCase()) {
      case 'DRAFT':
        return SurveyStatus.draft;
      case 'IN_PROGRESS':
        return SurveyStatus.inProgress;
      case 'PAUSED':
        return SurveyStatus.paused;
      case 'COMPLETED':
        return SurveyStatus.completed;
      case 'PENDING_REVIEW':
        return SurveyStatus.pendingReview;
      case 'APPROVED':
        return SurveyStatus.approved;
      case 'REJECTED':
        return SurveyStatus.rejected;
      default:
        return SurveyStatus.draft;
    }
  }
}

/// Survey types — unified after V1 deprecation.
/// Backend values: INSPECTION, VALUATION, REINSPECTION, OTHER
enum SurveyType {
  inspection,
  valuation,
  reinspection,
  other;

  /// Convert to backend string format (e.g., 'INSPECTION')
  String toBackendString() {
    switch (this) {
      case SurveyType.inspection:
        return 'INSPECTION';
      case SurveyType.valuation:
        return 'VALUATION';
      case SurveyType.reinspection:
        return 'REINSPECTION';
      case SurveyType.other:
        return 'OTHER';
    }
  }

  /// Whether this is an inspection-type survey.
  bool get isInspection => switch (this) {
        SurveyType.inspection ||
        SurveyType.reinspection =>
          true,
        _ => false,
      };

  /// Whether this is a valuation-type survey.
  bool get isValuation => this == SurveyType.valuation;

  /// User-facing display name.
  String get displayName => switch (this) {
        SurveyType.inspection => 'Property Inspection',
        SurveyType.valuation => 'Property Valuation',
        SurveyType.reinspection => 'Re-inspection',
        SurveyType.other => 'Other Survey',
      };

  /// Parse from backend string format.
  /// Accepts both old (LEVEL_2, INSPECTION_V2, SNAGGING, etc.) and new formats
  /// for backwards compatibility with existing backend data.
  static SurveyType fromBackendString(String value) {
    switch (value.toUpperCase()) {
      case 'INSPECTION':
      case 'LEVEL_2':
      case 'LEVEL_3':
      case 'INSPECTION_V2':
      case 'SNAGGING': // Legacy — mapped to inspection
        return SurveyType.inspection;
      case 'VALUATION':
      case 'VALUATION_V2':
        return SurveyType.valuation;
      case 'REINSPECTION':
        return SurveyType.reinspection;
      case 'OTHER':
      default:
        return SurveyType.other;
    }
  }
}

class Survey extends Equatable {
  const Survey({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.jobRef,
    this.address,
    this.clientName,
    this.progress = 0.0,
    this.photoCount = 0,
    this.noteCount = 0,
    this.totalSections = 0,
    this.completedSections = 0,
    this.parentSurveyId,
    this.reinspectionNumber = 0,
    this.aiSummary,
    this.riskSummary,
    this.repairRecommendations,
    this.deletedAt,
  });

  final String id;
  final String title;
  final SurveyType type;
  final SurveyStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? jobRef;
  final String? address;
  final String? clientName;
  final double progress;
  final int photoCount;
  final int noteCount;
  final int totalSections;
  final int completedSections;

  /// Parent survey ID for re-inspections (links to original survey)
  final String? parentSurveyId;

  /// Re-inspection number (1, 2, 3...) for tracking iteration
  final int reinspectionNumber;

  /// AI-generated executive summary text (persisted when user accepts)
  final String? aiSummary;

  /// AI-generated risk summary text (persisted when user accepts)
  final String? riskSummary;

  /// AI-generated repair recommendations text (persisted when user accepts)
  final String? repairRecommendations;

  /// Soft delete timestamp — null means active, non-null means deleted.
  final DateTime? deletedAt;

  /// Whether this survey has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  bool get isDraft => status == SurveyStatus.draft;
  bool get isInProgress => status == SurveyStatus.inProgress;
  bool get isPaused => status == SurveyStatus.paused;
  bool get isCompleted => status == SurveyStatus.completed;
  bool get isPendingReview => status == SurveyStatus.pendingReview;

  /// Whether this survey is a re-inspection of another survey
  bool get isReinspection => parentSurveyId != null;

  /// Calculate progress percentage from completed sections
  double get progressPercent =>
      totalSections > 0 ? (completedSections / totalSections) * 100 : 0;

  Survey copyWith({
    String? id,
    String? title,
    SurveyType? type,
    SurveyStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? jobRef,
    String? address,
    String? clientName,
    double? progress,
    int? photoCount,
    int? noteCount,
    int? totalSections,
    int? completedSections,
    String? parentSurveyId,
    int? reinspectionNumber,
    String? aiSummary,
    String? riskSummary,
    String? repairRecommendations,
    DateTime? deletedAt,
  }) =>
      Survey(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        jobRef: jobRef ?? this.jobRef,
        address: address ?? this.address,
        clientName: clientName ?? this.clientName,
        progress: progress ?? this.progress,
        photoCount: photoCount ?? this.photoCount,
        noteCount: noteCount ?? this.noteCount,
        totalSections: totalSections ?? this.totalSections,
        completedSections: completedSections ?? this.completedSections,
        parentSurveyId: parentSurveyId ?? this.parentSurveyId,
        reinspectionNumber: reinspectionNumber ?? this.reinspectionNumber,
        aiSummary: aiSummary ?? this.aiSummary,
        riskSummary: riskSummary ?? this.riskSummary,
        repairRecommendations: repairRecommendations ?? this.repairRecommendations,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        status,
        createdAt,
        updatedAt,
        startedAt,
        completedAt,
        jobRef,
        address,
        clientName,
        progress,
        photoCount,
        noteCount,
        totalSections,
        completedSections,
        parentSurveyId,
        reinspectionNumber,
        aiSummary,
        riskSummary,
        repairRecommendations,
        deletedAt,
      ];
}
