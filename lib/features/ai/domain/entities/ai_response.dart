import 'package:equatable/equatable.dart';

/// AI service availability status
class AiStatus extends Equatable {
  const AiStatus({
    required this.available,
    this.message,
    this.quotaRemaining,
    this.quotaLimit,
  });

  factory AiStatus.fromJson(Map<String, dynamic> json) => AiStatus(
        available: json['available'] as bool? ?? false,
        message: json['message'] as String?,
        quotaRemaining: json['quotaRemaining'] as int?,
        quotaLimit: json['quotaLimit'] as int?,
      );

  factory AiStatus.unavailable([String? message]) => AiStatus(
        available: false,
        message: message ?? 'AI service unavailable',
      );

  final bool available;
  final String? message;
  final int? quotaRemaining;
  final int? quotaLimit;

  double get quotaUsagePercent {
    if (quotaLimit == null || quotaLimit == 0) return 0;
    return ((quotaLimit! - (quotaRemaining ?? 0)) / quotaLimit!) * 100;
  }

  @override
  List<Object?> get props => [available, message, quotaRemaining, quotaLimit];
}

/// Token usage information
class TokenUsage extends Equatable {
  const TokenUsage({
    required this.inputTokens,
    required this.outputTokens,
  });

  factory TokenUsage.fromJson(Map<String, dynamic> json) => TokenUsage(
        inputTokens: json['inputTokens'] as int? ?? 0,
        outputTokens: json['outputTokens'] as int? ?? 0,
      );

  final int inputTokens;
  final int outputTokens;

  int get totalTokens => inputTokens + outputTokens;

  @override
  List<Object?> get props => [inputTokens, outputTokens];
}

/// Section narrative from AI report generation
class SectionNarrative extends Equatable {
  const SectionNarrative({
    required this.sectionId,
    required this.sectionType,
    required this.narrative,
    this.confidence = 0.8,
  });

  factory SectionNarrative.fromJson(Map<String, dynamic> json) =>
      SectionNarrative(
        sectionId: json['sectionId'] as String? ?? '',
        sectionType: json['sectionType'] as String? ?? '',
        narrative: json['narrative'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      );

  final String sectionId;
  final String sectionType;
  final String narrative;
  final double confidence;

  @override
  List<Object?> get props => [sectionId, sectionType, narrative, confidence];
}

/// Structured section payload for AST-native report rendering.
class AiReportAstSection extends Equatable {
  const AiReportAstSection({
    required this.sectionId,
    required this.title,
    this.conditionRating,
    this.limitations = const [],
    this.defaultParagraphs = const [],
    this.dynamicPhrases = const [],
    this.remarks = const [],
  });

  factory AiReportAstSection.fromJson(Map<String, dynamic> json) =>
      AiReportAstSection(
        sectionId: json['sectionId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        conditionRating: json['conditionRating'] as String?,
        limitations: (json['limitations'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        defaultParagraphs:
            (json['defaultParagraphs'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        dynamicPhrases: (json['dynamicPhrases'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        remarks: (json['remarks'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  final String sectionId;
  final String title;
  final String? conditionRating;
  final List<String> limitations;
  final List<String> defaultParagraphs;
  final List<String> dynamicPhrases;
  final List<String> remarks;

  @override
  List<Object?> get props => [
        sectionId,
        title,
        conditionRating,
        limitations,
        defaultParagraphs,
        dynamicPhrases,
        remarks,
      ];
}

/// Root AST payload emitted by backend phrase engine.
class AiReportAstPayload extends Equatable {
  const AiReportAstPayload({
    this.title,
    this.sectionTitle,
    this.sections = const [],
  });

  factory AiReportAstPayload.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? const {};
    return AiReportAstPayload(
      title: json['title'] as String? ??
          metadata['title'] as String? ??
          metadata['reportTitle'] as String?,
      sectionTitle: json['sectionTitle'] as String? ??
          metadata['sectionTitle'] as String?,
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((e) => AiReportAstSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String? title;
  final String? sectionTitle;
  final List<AiReportAstSection> sections;

  @override
  List<Object?> get props => [title, sectionTitle, sections];
}

/// AI-generated report response
class AiReportResponse extends Equatable {
  const AiReportResponse({
    required this.surveyId,
    required this.promptVersion,
    required this.sections,
    required this.executiveSummary,
    required this.fromCache,
    required this.disclaimer,
    required this.usage,
    this.ast,
  });

  factory AiReportResponse.fromJson(Map<String, dynamic> json) =>
      AiReportResponse(
        surveyId: json['surveyId'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) =>
                    SectionNarrative.fromJson(e as Map<String, dynamic>),)
                .toList() ??
            [],
        executiveSummary: json['executiveSummary'] as String? ?? '',
        fromCache: json['fromCache'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        usage: TokenUsage.fromJson(
            json['usage'] as Map<String, dynamic>? ?? {},),
        ast: json['ast'] is Map<String, dynamic>
            ? AiReportAstPayload.fromJson(
                json['ast'] as Map<String, dynamic>,
              )
            : null,
      );

  final String surveyId;
  final String promptVersion;
  final List<SectionNarrative> sections;
  final String executiveSummary;
  final bool fromCache;
  final String disclaimer;
  final TokenUsage usage;
  final AiReportAstPayload? ast;

  /// Get narrative for a specific section
  SectionNarrative? getNarrativeForSection(String sectionId) {
    try {
      return sections.firstWhere((s) => s.sectionId == sectionId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        surveyId,
        promptVersion,
        sections,
        executiveSummary,
        fromCache,
        disclaimer,
        usage,
        ast,
      ];
}

/// AI-generated recommendation
class AiRecommendation extends Equatable {
  const AiRecommendation({
    required this.issueId,
    required this.priority,
    required this.action,
    required this.reasoning,
    this.specialistReferral,
    required this.urgencyExplanation,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) =>
      AiRecommendation(
        issueId: json['issueId'] as String? ?? '',
        priority: json['priority'] as String? ?? 'monitor',
        action: json['action'] as String? ?? '',
        reasoning: json['reasoning'] as String? ?? '',
        specialistReferral: json['specialistReferral'] as String?,
        urgencyExplanation: json['urgencyExplanation'] as String? ?? '',
      );

  final String issueId;
  final String priority; // immediate, short_term, medium_term, long_term, monitor
  final String action;
  final String reasoning;
  final String? specialistReferral;
  final String urgencyExplanation;

  bool get isImmediate => priority == 'immediate';
  bool get isShortTerm => priority == 'short_term';
  bool get isMediumTerm => priority == 'medium_term';
  bool get isLongTerm => priority == 'long_term';
  bool get isMonitor => priority == 'monitor';

  bool get requiresSpecialist => specialistReferral != null && specialistReferral!.isNotEmpty;

  @override
  List<Object?> get props => [
        issueId,
        priority,
        action,
        reasoning,
        specialistReferral,
        urgencyExplanation,
      ];
}

/// AI recommendations response
class AiRecommendationsResponse extends Equatable {
  const AiRecommendationsResponse({
    required this.surveyId,
    required this.promptVersion,
    required this.recommendations,
    required this.fromCache,
    required this.disclaimer,
    required this.usage,
  });

  factory AiRecommendationsResponse.fromJson(Map<String, dynamic> json) =>
      AiRecommendationsResponse(
        surveyId: json['surveyId'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        recommendations: (json['recommendations'] as List<dynamic>?)
                ?.map(
                    (e) => AiRecommendation.fromJson(e as Map<String, dynamic>),)
                .toList() ??
            [],
        fromCache: json['fromCache'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        usage: TokenUsage.fromJson(
            json['usage'] as Map<String, dynamic>? ?? {},),
      );

  final String surveyId;
  final String promptVersion;
  final List<AiRecommendation> recommendations;
  final bool fromCache;
  final String disclaimer;
  final TokenUsage usage;

  /// Get recommendation for a specific issue
  AiRecommendation? getRecommendationForIssue(String issueId) {
    try {
      return recommendations.firstWhere((r) => r.issueId == issueId);
    } catch (_) {
      return null;
    }
  }

  /// Get recommendations by priority
  List<AiRecommendation> getByPriority(String priority) =>
      recommendations.where((r) => r.priority == priority).toList();

  @override
  List<Object?> get props => [
        surveyId,
        promptVersion,
        recommendations,
        fromCache,
        disclaimer,
        usage,
      ];
}

/// Risk item in summary
class RiskItem extends Equatable {
  const RiskItem({
    required this.category,
    required this.level,
    required this.description,
    this.relatedIds,
  });

  factory RiskItem.fromJson(Map<String, dynamic> json) => RiskItem(
        category: json['category'] as String? ?? '',
        level: json['level'] as String? ?? 'medium',
        description: json['description'] as String? ?? '',
        relatedIds: (json['relatedIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  final String category;
  final String level; // high, medium, low
  final String description;
  final List<String>? relatedIds;

  bool get isHighRisk => level == 'high';
  bool get isMediumRisk => level == 'medium';
  bool get isLowRisk => level == 'low';

  @override
  List<Object?> get props => [category, level, description, relatedIds];
}

/// Risk assessment for a specific category
class RiskByCategory extends Equatable {
  const RiskByCategory({
    required this.category,
    required this.risk,
    required this.evidence,
    required this.verifyNext,
  });

  factory RiskByCategory.fromJson(Map<String, dynamic> json) =>
      RiskByCategory(
        category: json['category'] as String? ?? '',
        risk: json['risk'] as String? ?? 'medium',
        evidence: (json['evidence'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        verifyNext: (json['verifyNext'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  final String category;
  final String risk; // high, medium, low
  final List<String> evidence;
  final List<String> verifyNext;

  bool get isHighRisk => risk == 'high';
  bool get isMediumRisk => risk == 'medium';
  bool get isLowRisk => risk == 'low';

  @override
  List<Object?> get props => [category, risk, evidence, verifyNext];
}

/// AI risk summary response
class AiRiskSummaryResponse extends Equatable {
  const AiRiskSummaryResponse({
    required this.surveyId,
    required this.promptVersion,
    required this.overallRiskLevel,
    this.overallRationale = const [],
    required this.summary,
    this.keyRiskDrivers = const [],
    required this.keyRisks,
    required this.keyPositives,
    this.riskByCategory = const [],
    this.immediateActions = const [],
    this.shortTermActions = const [],
    this.longTermActions = const [],
    this.dataGaps = const [],
    required this.fromCache,
    required this.disclaimer,
    required this.usage,
  });

  factory AiRiskSummaryResponse.fromJson(Map<String, dynamic> json) =>
      AiRiskSummaryResponse(
        surveyId: json['surveyId'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        overallRiskLevel: json['overallRiskLevel'] as String? ?? 'medium',
        overallRationale: (json['overallRationale'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        summary: json['summary'] as String? ?? '',
        keyRiskDrivers: (json['keyRiskDrivers'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        keyRisks: (json['keyRisks'] as List<dynamic>?)
                ?.map((e) => RiskItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        keyPositives: (json['keyPositives'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        riskByCategory: (json['riskByCategory'] as List<dynamic>?)
                ?.map((e) =>
                    RiskByCategory.fromJson(e as Map<String, dynamic>),)
                .toList() ??
            [],
        immediateActions: (json['immediateActions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        shortTermActions: (json['shortTermActions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        longTermActions: (json['longTermActions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        dataGaps: (json['dataGaps'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        fromCache: json['fromCache'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        usage: TokenUsage.fromJson(
            json['usage'] as Map<String, dynamic>? ?? {},),
      );

  final String surveyId;
  final String promptVersion;
  final String overallRiskLevel; // high, medium, low
  final List<String> overallRationale;
  final String summary;
  final List<String> keyRiskDrivers;
  final List<RiskItem> keyRisks;
  final List<String> keyPositives;
  final List<RiskByCategory> riskByCategory;
  final List<String> immediateActions;
  final List<String> shortTermActions;
  final List<String> longTermActions;
  final List<String> dataGaps;
  final bool fromCache;
  final String disclaimer;
  final TokenUsage usage;

  bool get isHighRisk => overallRiskLevel == 'high';
  bool get isMediumRisk => overallRiskLevel == 'medium';
  bool get isLowRisk => overallRiskLevel == 'low';

  int get highRiskCount => keyRisks.where((r) => r.isHighRisk).length;
  int get mediumRiskCount => keyRisks.where((r) => r.isMediumRisk).length;
  int get lowRiskCount => keyRisks.where((r) => r.isLowRisk).length;

  @override
  List<Object?> get props => [
        surveyId,
        promptVersion,
        overallRiskLevel,
        overallRationale,
        summary,
        keyRiskDrivers,
        keyRisks,
        keyPositives,
        riskByCategory,
        immediateActions,
        shortTermActions,
        longTermActions,
        dataGaps,
        fromCache,
        disclaimer,
        usage,
      ];
}

/// Consistency issue found
class ConsistencyIssue extends Equatable {
  const ConsistencyIssue({
    required this.type,
    required this.severity,
    required this.description,
    this.sectionId,
    this.fieldKey,
    this.suggestion,
  });

  factory ConsistencyIssue.fromJson(Map<String, dynamic> json) =>
      ConsistencyIssue(
        type: json['type'] as String? ?? 'incomplete',
        severity: json['severity'] as String? ?? 'medium',
        description: json['description'] as String? ?? '',
        sectionId: json['sectionId'] as String?,
        fieldKey: json['fieldKey'] as String?,
        suggestion: json['suggestion'] as String?,
      );

  final String type; // missing_data, contradiction, compliance_risk, incomplete
  final String severity; // high, medium, low
  final String description;
  final String? sectionId;
  final String? fieldKey;
  final String? suggestion;

  bool get isMissingData => type == 'missing_data';
  bool get isContradiction => type == 'contradiction';
  bool get isComplianceRisk => type == 'compliance_risk';
  bool get isIncomplete => type == 'incomplete';

  bool get isHighSeverity => severity == 'high';
  bool get isMediumSeverity => severity == 'medium';
  bool get isLowSeverity => severity == 'low';

  @override
  List<Object?> get props =>
      [type, severity, description, sectionId, fieldKey, suggestion];
}

/// AI consistency check response
class AiConsistencyResponse extends Equatable {
  const AiConsistencyResponse({
    required this.surveyId,
    required this.promptVersion,
    required this.score,
    required this.issues,
    required this.fromCache,
    required this.disclaimer,
    required this.usage,
  });

  factory AiConsistencyResponse.fromJson(Map<String, dynamic> json) =>
      AiConsistencyResponse(
        surveyId: json['surveyId'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        issues: (json['issues'] as List<dynamic>?)
                ?.map(
                    (e) => ConsistencyIssue.fromJson(e as Map<String, dynamic>),)
                .toList() ??
            [],
        fromCache: json['fromCache'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        usage: TokenUsage.fromJson(
            json['usage'] as Map<String, dynamic>? ?? {},),
      );

  final String surveyId;
  final String promptVersion;
  final int score; // 0-100
  final List<ConsistencyIssue> issues;
  final bool fromCache;
  final String disclaimer;
  final TokenUsage usage;

  bool get hasHighSeverityIssues => issues.any((i) => i.isHighSeverity);
  int get highSeverityCount => issues.where((i) => i.isHighSeverity).length;
  int get mediumSeverityCount => issues.where((i) => i.isMediumSeverity).length;
  int get lowSeverityCount => issues.where((i) => i.isLowSeverity).length;

  /// Get issues for a specific section
  List<ConsistencyIssue> getIssuesForSection(String sectionId) =>
      issues.where((i) => i.sectionId == sectionId).toList();

  @override
  List<Object?> get props => [
        surveyId,
        promptVersion,
        score,
        issues,
        fromCache,
        disclaimer,
        usage,
      ];
}

// ─── Professional Analysis (Hybrid Intelligence Layer 2) ───────────

/// A single AI-generated professional recommendation.
class AiProfessionalRecommendationItem extends Equatable {
  const AiProfessionalRecommendationItem({
    required this.screenId,
    this.fieldId,
    required this.category,
    required this.severity,
    required this.reason,
    required this.suggestedText,
    required this.confidence,
    this.reasoning,
  });

  factory AiProfessionalRecommendationItem.fromJson(
    Map<String, dynamic> json,
  ) =>
      AiProfessionalRecommendationItem(
        screenId: json['screenId'] as String? ?? '',
        fieldId: json['fieldId'] as String?,
        category: json['category'] as String? ?? 'narrativeStrength',
        severity: json['severity'] as String? ?? 'moderate',
        reason: json['reason'] as String? ?? '',
        suggestedText: json['suggestedText'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        reasoning: json['reasoning'] as String?,
      );

  final String screenId;
  final String? fieldId;
  final String category; // matches RecommendationCategory.name
  final String severity; // matches RecommendationSeverity.name
  final String reason;
  final String suggestedText;
  final double confidence; // 0.0–1.0
  final String? reasoning; // internal chain-of-thought for audit trail

  @override
  List<Object?> get props => [
        screenId,
        fieldId,
        category,
        severity,
        reason,
        suggestedText,
        confidence,
        reasoning,
      ];
}

/// AI professional analysis response — structured narrative recommendations.
class AiProfessionalAnalysisResponse extends Equatable {
  const AiProfessionalAnalysisResponse({
    required this.surveyId,
    required this.promptVersion,
    required this.modelVersion,
    required this.recommendations,
    required this.fromCache,
    required this.disclaimer,
    required this.usage,
  });

  factory AiProfessionalAnalysisResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      AiProfessionalAnalysisResponse(
        surveyId: json['surveyId'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        modelVersion: json['modelVersion'] as String? ?? '',
        recommendations: (json['recommendations'] as List<dynamic>?)
                ?.map(
                  (e) => AiProfessionalRecommendationItem.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
        fromCache: json['fromCache'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        usage: TokenUsage.fromJson(
          json['usage'] as Map<String, dynamic>? ?? {},
        ),
      );

  final String surveyId;
  final String promptVersion;
  final String modelVersion; // e.g. "gemini-2.5-pro"
  final List<AiProfessionalRecommendationItem> recommendations;
  final bool fromCache;
  final String disclaimer;
  final TokenUsage usage;

  @override
  List<Object?> get props => [
        surveyId,
        promptVersion,
        modelVersion,
        recommendations,
        fromCache,
        disclaimer,
        usage,
      ];
}

/// Photo tag
class PhotoTag extends Equatable {
  const PhotoTag({
    required this.label,
    required this.confidence,
  });

  factory PhotoTag.fromJson(Map<String, dynamic> json) => PhotoTag(
        label: json['label'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      );

  final String label;
  final double confidence;

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.5;

  @override
  List<Object?> get props => [label, confidence];
}

/// AI photo tags response
class AiPhotoTagsResponse extends Equatable {
  const AiPhotoTagsResponse({
    required this.surveyId,
    required this.photoId,
    required this.promptVersion,
    required this.tags,
    required this.suggestedSection,
    required this.description,
    required this.fromCache,
    required this.disclaimer,
    required this.usage,
  });

  factory AiPhotoTagsResponse.fromJson(Map<String, dynamic> json) =>
      AiPhotoTagsResponse(
        surveyId: json['surveyId'] as String? ?? '',
        photoId: json['photoId'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => PhotoTag.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        suggestedSection: json['suggestedSection'] as String? ?? '',
        description: json['description'] as String? ?? '',
        fromCache: json['fromCache'] as bool? ?? false,
        disclaimer: json['disclaimer'] as String? ?? '',
        usage: TokenUsage.fromJson(
            json['usage'] as Map<String, dynamic>? ?? {},),
      );

  final String surveyId;
  final String photoId;
  final String promptVersion;
  final List<PhotoTag> tags;
  final String suggestedSection;
  final String description;
  final bool fromCache;
  final String disclaimer;
  final TokenUsage usage;

  /// Get high confidence tags only
  List<PhotoTag> get highConfidenceTags =>
      tags.where((t) => t.isHighConfidence).toList();

  /// Get tags as comma-separated string
  String get tagsString => tags.map((t) => t.label).join(', ');

  @override
  List<Object?> get props => [
        surveyId,
        photoId,
        promptVersion,
        tags,
        suggestedSection,
        description,
        fromCache,
        disclaimer,
        usage,
      ];
}
