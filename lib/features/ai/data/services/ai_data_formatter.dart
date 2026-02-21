import '../../../../core/ai/pii_redactor.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_inspection/presentation/widgets/inspection_fields.dart'
    show shouldShowInspectionField;
import '../../../../shared/domain/entities/survey.dart';
import '../../domain/repositories/ai_repository.dart';

/// Converts survey tree + answers into the AI request payloads expected by
/// the existing [AiRepository] API.
///
/// The AI backend accepts sections with answers — this formatter
/// re-shapes the tree-based data into the flat section format.
class AiDataFormatter {
  AiDataFormatter({PiiRedactor? redactor}) : _redactor = redactor ?? PiiRedactor();

  final PiiRedactor _redactor;

  /// Format survey data for a report narrative request.
  AiFormattedRequest<GenerateReportRequest> formatForReport({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) {
    final formatted = _formatSections(tree, allAnswers);
    final addressResult = _redactor.redactAddress(survey.address ?? '');

    final request = GenerateReportRequest(
      surveyId: surveyId,
      propertyAddress: addressResult.redacted,
      sections: formatted.sections,
    );

    return AiFormattedRequest(
      request: request,
      redactionMapping: {
        ...addressResult.mapping,
        ...formatted.redactionMapping,
      },
    );
  }

  /// Format survey data for a risk summary request.
  AiFormattedRequest<GenerateRiskSummaryRequest> formatForRiskSummary({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) {
    final formatted = _formatSections(tree, allAnswers);
    final addressResult = _redactor.redactAddress(survey.address ?? '');

    final request = GenerateRiskSummaryRequest(
      surveyId: surveyId,
      propertyAddress: addressResult.redacted,
      sections: formatted.sections,
    );

    return AiFormattedRequest(
      request: request,
      redactionMapping: {
        ...addressResult.mapping,
        ...formatted.redactionMapping,
      },
    );
  }

  /// Format survey data for a consistency check request.
  AiFormattedRequest<ConsistencyCheckRequest> formatForConsistency({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) {
    final formatted = _formatSections(tree, allAnswers);

    final request = ConsistencyCheckRequest(
      surveyId: surveyId,
      sections: formatted.sections,
    );

    return AiFormattedRequest(
      request: request,
      redactionMapping: formatted.redactionMapping,
    );
  }

  /// Format survey data for a recommendations request.
  AiFormattedRequest<GenerateRecommendationsRequest> formatForRecommendations({
    required String surveyId,
    required Survey survey,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
  }) {
    final formatted = _formatSections(tree, allAnswers);
    final addressResult = _redactor.redactAddress(survey.address ?? '');

    final request = GenerateRecommendationsRequest(
      surveyId: surveyId,
      propertyAddress: addressResult.redacted,
      sections: formatted.sections,
    );

    return AiFormattedRequest(
      request: request,
      redactionMapping: {
        ...addressResult.mapping,
        ...formatted.redactionMapping,
      },
    );
  }

  /// Format answers for a single screen (used by per-screen AI features).
  AiFormattedRequest<SectionAnswersInput> formatSingleScreen({
    required InspectionNodeDefinition screenNode,
    required Map<String, String> answers,
    required String sectionTitle,
  }) {
    final mapResult = _redactor.redactAnswerMap(
      _filterVisibleAnswers(screenNode, answers),
    );

    final section = SectionAnswersInput(
      sectionId: screenNode.id,
      sectionType: 'screen',
      title: screenNode.title,
      answers: mapResult.redacted,
    );

    return AiFormattedRequest(
      request: section,
      redactionMapping: mapResult.mapping,
    );
  }

  /// Format survey data for professional narrative analysis (hybrid Layer 2).
  ///
  /// Includes existing rule engine recommendations as context so the AI
  /// can produce complementary (non-duplicate) professional insights.
  AiFormattedRequest<ProfessionalAnalysisRequest> formatForProfessionalAnalysis({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required List<Map<String, String>> ruleRecommendations,
    required bool isValuation,
  }) {
    final formatted = _formatSections(tree, allAnswers);

    final request = ProfessionalAnalysisRequest(
      surveyId: surveyId,
      sections: formatted.sections,
      ruleRecommendations: ruleRecommendations,
      isValuation: isValuation,
    );

    return AiFormattedRequest(
      request: request,
      redactionMapping: formatted.redactionMapping,
    );
  }

  // ── Internal ──────────────────────────────────────────────────

  /// Walk the survey tree and produce a flat list of [SectionAnswersInput]
  /// for each screen that has answers.
  _FormattedSections _formatSections(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final sections = <SectionAnswersInput>[];
    final combinedMapping = <String, String>{};

    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;

        final raw = allAnswers[node.id];
        if (raw == null || raw.isEmpty) continue;

        // Filter to only visible fields (respects conditional logic)
        final visible = _filterVisibleAnswers(node, raw);
        if (visible.isEmpty) continue;

        // Redact PII in answer values
        final mapResult = _redactor.redactAnswerMap(visible);
        combinedMapping.addAll(mapResult.mapping);

        sections.add(SectionAnswersInput(
          sectionId: node.id,
          sectionType: section.key,
          title: node.title,
          answers: mapResult.redacted,
        ));
      }
    }

    return _FormattedSections(
      sections: sections,
      redactionMapping: combinedMapping,
    );
  }

  /// Filter answers to only include fields that are currently visible
  /// (based on conditional rules), and use labels as keys for readability.
  Map<String, String> _filterVisibleAnswers(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    final visible = <String, String>{};

    for (final field in node.fields) {
      if (field.type == InspectionFieldType.label) continue;
      if (!shouldShowInspectionField(field, answers)) continue;

      final value = answers[field.id];
      if (value == null || value.isEmpty) continue;

      // Use the field label as key for better AI prompt readability
      visible[field.label] = value;
    }

    return visible;
  }
}

/// Holds a formatted AI request plus the PII redaction mapping
/// needed to restore tokens in the response.
class AiFormattedRequest<T> {
  const AiFormattedRequest({
    required this.request,
    required this.redactionMapping,
  });

  final T request;

  /// token → original PII value (used to restore AI responses).
  final Map<String, String> redactionMapping;
}

class _FormattedSections {
  const _FormattedSections({
    required this.sections,
    required this.redactionMapping,
  });

  final List<SectionAnswersInput> sections;
  final Map<String, String> redactionMapping;
}
