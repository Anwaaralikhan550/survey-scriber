import 'package:equatable/equatable.dart';
import 'client_booking.dart';

/// Survey type enum for client portal
enum ClientSurveyType {
  inspection,
  valuation,
  reinspection,
  other;

  String get displayName {
    switch (this) {
      case ClientSurveyType.inspection:
        return 'Property Inspection';
      case ClientSurveyType.valuation:
        return 'Property Valuation';
      case ClientSurveyType.reinspection:
        return 'Re-inspection';
      case ClientSurveyType.other:
        return 'Other';
    }
  }
}

/// Client report entity (approved survey visible to client)
class ClientReport extends Equatable {
  const ClientReport({
    required this.id,
    required this.title,
    required this.propertyAddress,
    required this.surveyor,
    required this.createdAt,
    required this.updatedAt,
    this.type,
    this.jobRef,
    this.sectionCount,
    this.photoCount,
  });

  final String id;
  final String title;
  final String propertyAddress;
  final SurveyorSummary surveyor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClientSurveyType? type;
  final String? jobRef;
  final int? sectionCount;
  final int? photoCount;

  /// Short description for list view
  String get shortDescription {
    if (type != null) return type!.displayName;
    return 'Survey Report';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        propertyAddress,
        surveyor,
        createdAt,
        updatedAt,
        type,
        jobRef,
        sectionCount,
        photoCount,
      ];
}
