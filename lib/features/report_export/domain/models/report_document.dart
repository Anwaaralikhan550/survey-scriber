/// Format-agnostic intermediate model consumed by both PDF and DOCX renderers.
///
/// The [ReportBuilder] produces a [ReportDocument] from raw survey data,
/// and each renderer reads it without needing to understand the tree JSON
/// or conditional-visibility logic.

enum ReportFieldType { text, number, checkbox, dropdown, label }

enum ReportType { inspection, valuation }

class ReportAstPayload {
  const ReportAstPayload({
    this.title,
    this.sectionTitle,
    this.sections = const [],
  });

  final String? title;
  final String? sectionTitle;
  final List<ReportAstSection> sections;

  ReportAstSection? sectionFor(String sectionKey) {
    final normalized = sectionKey.trim().toUpperCase();
    for (final section in sections) {
      if (section.sectionId.trim().toUpperCase() == normalized) {
        return section;
      }
    }
    return null;
  }
}

class ReportAstSection {
  const ReportAstSection({
    required this.sectionId,
    required this.title,
    this.conditionRating,
    this.limitations = const [],
    this.defaultParagraphs = const [],
    this.dynamicPhrases = const [],
    this.remarks = const [],
  });

  final String sectionId;
  final String title;
  final String? conditionRating;
  final List<String> limitations;
  final List<String> defaultParagraphs;
  final List<String> dynamicPhrases;
  final List<String> remarks;

  bool get hasAnyContent =>
      (conditionRating?.trim().isNotEmpty ?? false) ||
      limitations.isNotEmpty ||
      defaultParagraphs.isNotEmpty ||
      dynamicPhrases.isNotEmpty ||
      remarks.isNotEmpty;

  List<String> get orderedParagraphs => [
        ...limitations,
        ...defaultParagraphs,
        ...dynamicPhrases,
        ...remarks,
      ];
}

class ReportDocument {
  const ReportDocument({
    required this.reportType,
    required this.title,
    required this.generatedAt,
    required this.surveyMeta,
    required this.sections,
    this.signatures = const [],
    this.photoFilePaths = const [],
    this.aiExecutiveSummary,
    this.aiSectionNarratives = const {},
    this.aiAstPayload,
    this.aiDisclaimer,
    this.recommendationItems = const [],
  });

  final ReportType reportType;
  final String title;
  final DateTime generatedAt;
  final SurveyMeta surveyMeta;
  final List<ReportSection> sections;
  final List<ReportSignature> signatures;
  final List<String> photoFilePaths;

  /// AI-generated executive summary (null if AI not used).
  final String? aiExecutiveSummary;

  /// AI-generated narratives per section key (e.g. 'E' → narrative text).
  final Map<String, String> aiSectionNarratives;

  /// Structured AI payload for AST-native rendering.
  final ReportAstPayload? aiAstPayload;

  /// AI disclaimer text (e.g. "AI-generated content — verify independently").
  final String? aiDisclaimer;

  /// Accepted professional recommendations to include in the report.
  final List<ReportRecommendationItem> recommendationItems;

  bool get hasAiContent =>
      aiExecutiveSummary != null ||
      aiSectionNarratives.isNotEmpty ||
      (aiAstPayload?.sections.isNotEmpty ?? false);

  bool get hasRecommendations => recommendationItems.isNotEmpty;

  int get totalFields =>
      sections.fold<int>(0, (s, sec) => s + sec.screens.fold<int>(0, (s2, sc) => s2 + sc.fields.length));

  int get totalScreens =>
      sections.fold<int>(0, (s, sec) => s + sec.screens.length);

  ReportDocument copyWith({
    ReportType? reportType,
    String? title,
    DateTime? generatedAt,
    SurveyMeta? surveyMeta,
    List<ReportSection>? sections,
    List<ReportSignature>? signatures,
    List<String>? photoFilePaths,
    String? aiExecutiveSummary,
    Map<String, String>? aiSectionNarratives,
    ReportAstPayload? aiAstPayload,
    String? aiDisclaimer,
    List<ReportRecommendationItem>? recommendationItems,
  }) {
    return ReportDocument(
      reportType: reportType ?? this.reportType,
      title: title ?? this.title,
      generatedAt: generatedAt ?? this.generatedAt,
      surveyMeta: surveyMeta ?? this.surveyMeta,
      sections: sections ?? this.sections,
      signatures: signatures ?? this.signatures,
      photoFilePaths: photoFilePaths ?? this.photoFilePaths,
      aiExecutiveSummary: aiExecutiveSummary ?? this.aiExecutiveSummary,
      aiSectionNarratives: aiSectionNarratives ?? this.aiSectionNarratives,
      aiAstPayload: aiAstPayload ?? this.aiAstPayload,
      aiDisclaimer: aiDisclaimer ?? this.aiDisclaimer,
      recommendationItems: recommendationItems ?? this.recommendationItems,
    );
  }
}

class SurveyMeta {
  const SurveyMeta({
    required this.surveyId,
    required this.title,
    this.address,
    this.jobRef,
    this.clientName,
    this.inspectionDate,
    this.surveyorName,
    this.startedAt,
    this.completedAt,
    this.surveyDuration,
  });

  final String surveyId;
  final String title;
  final String? address;
  final String? jobRef;
  final String? clientName;
  final DateTime? inspectionDate;
  final String? surveyorName;

  /// When the surveyor first started (draft → inProgress).
  final DateTime? startedAt;

  /// When the survey was marked complete.
  final DateTime? completedAt;

  /// Active time-on-site tracked by SurveyDurationTimer.
  final Duration? surveyDuration;
}

class ReportSection {
  const ReportSection({
    required this.key,
    required this.title,
    required this.description,
    required this.screens,
    required this.displayOrder,
  });

  final String key;
  final String title;
  final String description;
  final List<ReportScreen> screens;
  final int displayOrder;
}

class ReportScreen {
  const ReportScreen({
    required this.screenId,
    required this.title,
    required this.fields,
    this.phrases = const [],
    this.userNote = '',
    this.parentId,
    this.isCompleted = false,
    this.isMergedGroup = false,
  });

  final String screenId;
  final String title;
  final List<ReportField> fields;
  final List<String> phrases;
  final String userNote;
  final String? parentId;
  final bool isCompleted;

  /// True when this entry represents a merged group (e.g. "E1 Chimney") whose
  /// phrases come from multiple descendant screens.  Renderers use this to
  /// output flowing paragraphs instead of bullet points and to suppress the
  /// field data table.
  final bool isMergedGroup;

  bool get hasData =>
      fields.any((f) => f.displayValue.isNotEmpty) ||
      phrases.isNotEmpty ||
      userNote.isNotEmpty;
}

class ReportField {
  const ReportField({
    required this.fieldId,
    required this.label,
    required this.type,
    required this.displayValue,
    this.rawValue,
    this.options,
    this.isConditional = false,
  });

  final String fieldId;
  final String label;
  final ReportFieldType type;
  final String displayValue;
  final String? rawValue;
  final List<String>? options;
  final bool isConditional;
}

class ReportRecommendationItem {
  const ReportRecommendationItem({
    required this.category,
    required this.severity,
    required this.screenTitle,
    required this.reason,
    required this.suggestedText,
    this.source,
    this.auditHash,
  });

  /// Display name: "Compliance", "Narrative Strength", etc.
  final String category;

  /// "High", "Moderate", or "Low".
  final String severity;

  /// Title of the screen that triggered this recommendation.
  final String screenTitle;

  /// Why this was flagged.
  final String reason;

  /// RICS-compliant suggested narrative text.
  final String suggestedText;

  /// Source identifier: "rule" or "ai" — for audit trail, NOT displayed.
  final String? source;

  /// SHA-256 audit hash for legal defensibility — NOT displayed.
  final String? auditHash;
}

class ReportSignature {
  const ReportSignature({
    required this.signerName,
    required this.signerRole,
    required this.filePath,
    required this.signedAt,
  });

  final String signerName;
  final String signerRole;
  final String filePath;
  final DateTime signedAt;
}
