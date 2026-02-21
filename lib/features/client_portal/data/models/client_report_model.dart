import '../../domain/entities/client_report.dart';
import 'client_booking_model.dart';

/// Client report model
class ClientReportModel extends ClientReport {
  const ClientReportModel({
    required super.id,
    required super.title,
    required super.propertyAddress,
    required super.surveyor,
    required super.createdAt,
    required super.updatedAt,
    super.type,
    super.jobRef,
    super.sectionCount,
    super.photoCount,
  });

  factory ClientReportModel.fromJson(Map<String, dynamic> json) => ClientReportModel(
      id: json['id'] as String,
      title: json['title'] as String,
      propertyAddress: json['propertyAddress'] as String,
      surveyor: SurveyorSummaryModel.fromJson(
        json['surveyor'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      type: _parseType(json['type'] as String?),
      jobRef: json['jobRef'] as String?,
      sectionCount: json['sectionCount'] as int?,
      photoCount: json['photoCount'] as int?,
    );

  static ClientSurveyType? _parseType(String? type) {
    if (type == null) return null;
    switch (type.toUpperCase()) {
      case 'INSPECTION':
      case 'LEVEL_2':
      case 'LEVEL_3':
      case 'INSPECTION_V2':
        return ClientSurveyType.inspection;
      case 'VALUATION':
      case 'VALUATION_V2':
        return ClientSurveyType.valuation;
      case 'SNAGGING': // Legacy — mapped to inspection
        return ClientSurveyType.inspection;
      case 'REINSPECTION':
        return ClientSurveyType.reinspection;
      case 'OTHER':
        return ClientSurveyType.other;
      default:
        return null;
    }
  }
}

/// Reports list response model
class ClientReportsResponseModel {
  const ClientReportsResponseModel({
    required this.reports,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ClientReportsResponseModel.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return ClientReportsResponseModel(
      reports: (json['data'] as List)
          .map((e) => ClientReportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }

  final List<ClientReportModel> reports;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}
