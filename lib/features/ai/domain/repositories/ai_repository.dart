import '../entities/ai_response.dart';

/// Request models for AI features
class GenerateReportRequest {
  const GenerateReportRequest({
    required this.surveyId,
    required this.propertyAddress,
    this.propertyType,
    required this.sections,
    this.issues,
    this.skipCache = false,
  });

  final String surveyId;
  final String propertyAddress;
  final String? propertyType;
  final List<SectionAnswersInput> sections;
  final List<IssueInput>? issues;
  final bool skipCache;

  Map<String, dynamic> toJson() => {
        'surveyId': surveyId,
        'propertyAddress': propertyAddress,
        if (propertyType != null) 'propertyType': propertyType,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (issues != null) 'issues': issues!.map((i) => i.toJson()).toList(),
        if (skipCache) 'skipCache': skipCache,
      };
}

class SectionAnswersInput {
  const SectionAnswersInput({
    required this.sectionId,
    required this.sectionType,
    required this.title,
    required this.answers,
  });

  final String sectionId;
  final String sectionType;
  final String title;
  final Map<String, String> answers;

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'sectionType': sectionType,
        'title': title,
        'answers': answers,
      };
}

class IssueInput {
  const IssueInput({
    required this.id,
    required this.title,
    this.category,
    this.severity,
    this.location,
    this.description,
  });

  final String id;
  final String title;
  final String? category;
  final String? severity;
  final String? location;
  final String? description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (category != null) 'category': category,
        if (severity != null) 'severity': severity,
        if (location != null) 'location': location,
        if (description != null) 'description': description,
      };
}

class GenerateRecommendationsRequest {
  const GenerateRecommendationsRequest({
    required this.surveyId,
    required this.propertyAddress,
    this.propertyType,
    this.issues = const [],
    this.sections,
    this.skipCache = false,
  });

  final String surveyId;
  final String propertyAddress;
  final String? propertyType;
  final List<IssueInput> issues;
  final List<SectionAnswersInput>? sections;
  final bool skipCache;

  Map<String, dynamic> toJson() => {
        'surveyId': surveyId,
        'propertyAddress': propertyAddress,
        if (propertyType != null) 'propertyType': propertyType,
        if (issues.isNotEmpty) 'issues': issues.map((i) => i.toJson()).toList(),
        if (sections != null) 'sections': sections!.map((s) => s.toJson()).toList(),
        if (skipCache) 'skipCache': skipCache,
      };
}

class GenerateRiskSummaryRequest {
  const GenerateRiskSummaryRequest({
    required this.surveyId,
    required this.propertyAddress,
    this.propertyType,
    required this.sections,
    this.issues,
    this.skipCache = false,
  });

  final String surveyId;
  final String propertyAddress;
  final String? propertyType;
  final List<SectionAnswersInput> sections;
  final List<IssueInput>? issues;
  final bool skipCache;

  Map<String, dynamic> toJson() => {
        'surveyId': surveyId,
        'propertyAddress': propertyAddress,
        if (propertyType != null) 'propertyType': propertyType,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (issues != null) 'issues': issues!.map((i) => i.toJson()).toList(),
        if (skipCache) 'skipCache': skipCache,
      };
}

class ConsistencyCheckRequest {
  const ConsistencyCheckRequest({
    required this.surveyId,
    required this.sections,
    this.issues,
    this.skipCache = false,
  });

  final String surveyId;
  final List<SectionAnswersInput> sections;
  final List<IssueInput>? issues;
  final bool skipCache;

  Map<String, dynamic> toJson() => {
        'surveyId': surveyId,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (issues != null) 'issues': issues!.map((i) => i.toJson()).toList(),
        if (skipCache) 'skipCache': skipCache,
      };
}

/// Request for AI professional narrative analysis (hybrid Layer 2).
///
/// Sends survey data plus existing rule engine recommendations as context,
/// so the AI can produce complementary narrative recommendations.
class ProfessionalAnalysisRequest {
  const ProfessionalAnalysisRequest({
    required this.surveyId,
    required this.sections,
    this.ruleRecommendations = const [],
    this.isValuation = false,
    this.skipCache = false,
  });

  final String surveyId;
  final List<SectionAnswersInput> sections;

  /// Existing rule engine recommendations — provided as context so the AI
  /// avoids duplicating them and instead adds complementary insight.
  final List<Map<String, String>> ruleRecommendations;

  final bool isValuation;
  final bool skipCache;

  Map<String, dynamic> toJson() => {
        'surveyId': surveyId,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (ruleRecommendations.isNotEmpty)
          'ruleRecommendations': ruleRecommendations,
        'isValuation': isValuation,
        if (skipCache) 'skipCache': skipCache,
      };
}

class PhotoTagsRequest {
  const PhotoTagsRequest({
    required this.surveyId,
    required this.photoId,
    required this.imageData,
    this.existingCaption,
    this.sectionContext,
    this.skipCache = false,
  });

  final String surveyId;
  final String photoId;
  final String imageData; // Base64 encoded or data URL
  final String? existingCaption;
  final String? sectionContext;
  final bool skipCache;

  Map<String, dynamic> toJson() => {
        'surveyId': surveyId,
        'photoId': photoId,
        'imageData': imageData,
        if (existingCaption != null) 'existingCaption': existingCaption,
        if (sectionContext != null) 'sectionContext': sectionContext,
        if (skipCache) 'skipCache': skipCache,
      };
}

/// Abstract AI repository interface
abstract class AiRepository {
  /// Check AI service status and quota
  Future<AiStatus> getStatus();

  /// Generate AI narrative report sections
  Future<AiReportResponse> generateReport(GenerateReportRequest request);

  /// Generate recommendations from issues
  Future<AiRecommendationsResponse> generateRecommendations(
      GenerateRecommendationsRequest request,);

  /// Generate client-friendly risk summary
  Future<AiRiskSummaryResponse> generateRiskSummary(
      GenerateRiskSummaryRequest request,);

  /// Check survey data consistency
  Future<AiConsistencyResponse> checkConsistency(
      ConsistencyCheckRequest request,);

  /// Generate photo tags
  Future<AiPhotoTagsResponse> generatePhotoTags(PhotoTagsRequest request);

  /// Professional narrative analysis (hybrid Layer 2)
  Future<AiProfessionalAnalysisResponse> analyzeProfessionally(
    ProfessionalAnalysisRequest request,
  );
}
