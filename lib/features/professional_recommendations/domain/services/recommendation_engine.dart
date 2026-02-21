import 'package:uuid/uuid.dart';

import '../../../property_inspection/domain/models/inspection_models.dart';
import '../models/professional_recommendation.dart';

/// Local, offline-first rule engine that analyzes survey data against
/// RICS Level 2/3 professional standards.
///
/// This is a pure function with no I/O, no database, no network — designed
/// to run inside a `compute()` isolate for non-blocking analysis of large
/// surveys (465+ screens).
///
/// v2.0.0 enhancements:
///   - Every recommendation stamped with source, ruleVersion, auditHash
///   - Deterministic quality scoring (compliance / narrative / risk / overall)
///   - Cross-section contradiction detection
class RecommendationEngine {
  static const engineVersion = '2.0.0';
  static const _uuid = Uuid();

  /// Run all rule categories against the survey data.
  static ProfessionalRecommendationsResult analyze({
    required String surveyId,
    required InspectionTreePayload tree,
    required Map<String, Map<String, String>> allAnswers,
    required bool isValuation,
  }) {
    final recs = <ProfessionalRecommendation>[];

    recs.addAll(_complianceRules(tree, allAnswers));
    recs.addAll(_narrativeStrengthRules(tree, allAnswers));
    recs.addAll(_riskClarificationRules(tree, allAnswers));
    recs.addAll(_dataGapRules(tree, allAnswers));
    recs.addAll(_crossSectionContradictionRules(tree, allAnswers));
    if (isValuation) {
      recs.addAll(_valuationJustificationRules(tree, allAnswers));
    }

    // Sort: high first, then moderate, then low
    recs.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    // Compute quality scores from raw data (independent of recommendation count)
    final scores = _computeScores(tree, allAnswers, isValuation);

    return ProfessionalRecommendationsResult(
      surveyId: surveyId,
      recommendations: recs,
      generatedAt: DateTime.now(),
      engineVersion: engineVersion,
      scores: scores,
    );
  }

  // ─── Compliance Rules ───────────────────────────────────────────────

  static List<ProfessionalRecommendation> _complianceRules(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final recs = <ProfessionalRecommendation>[];

    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};

        // Rule C-001: Missing EPC reference in section D (About Property)
        if (section.key == 'D' && _isEpcRelated(node)) {
          final hasEpcContent = _hasAnyContent(node, answers);
          if (!hasEpcContent) {
            recs.add(_rec(
              category: RecommendationCategory.compliance,
              severity: RecommendationSeverity.high,
              screenId: node.id,
              reason:
                  'The Energy Performance Certificate (EPC) information '
                  'has not been documented in "${node.title}".',
              suggestedText:
                  'The current Energy Performance Certificate rating '
                  'and expiry date should be recorded. Where an EPC is '
                  'not available, this should be stated and the client '
                  'advised accordingly. Reference to energy efficiency '
                  'is a requirement under RICS Home Survey Standard.',
            ));
          }
        }

        if (answers.isEmpty) continue;

        final conditionRating = _findConditionRating(node, answers);
        final mainCondition = _findMainCondition(node, answers);

        // Rule C-002: Condition rating set without corresponding Main Condition
        if (conditionRating != null &&
            conditionRating.isNotEmpty &&
            mainCondition != null &&
            _fieldExists(node, mainCondition) &&
            (answers[mainCondition] ?? '').isEmpty) {
          recs.add(_rec(
            category: RecommendationCategory.compliance,
            severity: RecommendationSeverity.moderate,
            screenId: node.id,
            fieldId: mainCondition,
            reason:
                'A Condition Rating has been assigned on "${node.title}" '
                'but the Main Condition field has not been completed.',
            suggestedText:
                'The Main Condition assessment should be completed to '
                'provide appropriate context for the assigned Condition '
                'Rating, in accordance with RICS Home Survey Standard '
                'reporting requirements.',
          ));
        }

        // Rule C-003: Damp-related screens with rating 3 but no evidence text
        if (_isDampRelated(node) && conditionRating == '3') {
          final hasEvidenceText = _hasSubstantialText(node, answers);
          if (!hasEvidenceText) {
            recs.add(_rec(
              category: RecommendationCategory.compliance,
              severity: RecommendationSeverity.high,
              screenId: node.id,
              reason:
                  'A Condition Rating 3 has been assigned to damp-related '
                  'element "${node.title}" without supporting evidence text.',
              suggestedText:
                  'The surveyor should document the extent and severity of '
                  'dampness observed, including any meter readings taken, '
                  'visible signs of moisture, and the likely source. This '
                  'supports the Condition Rating 3 designation and provides '
                  'the client with actionable information regarding '
                  'remediation requirements.',
            ));
          }
        }

        // Rule C-004: Main Condition set without condition rating
        if (conditionRating != null &&
            conditionRating.isEmpty &&
            mainCondition != null &&
            (answers[mainCondition] ?? '').isNotEmpty) {
          recs.add(_rec(
            category: RecommendationCategory.compliance,
            severity: RecommendationSeverity.moderate,
            screenId: node.id,
            reason:
                'A Main Condition has been selected on "${node.title}" '
                'but no Condition Rating has been assigned.',
            suggestedText:
                'Each inspected element should receive a Condition '
                'Rating (1, 2, or 3) alongside the Main Condition '
                'description, providing the client with a clear, '
                'standardised severity assessment.',
          ));
        }
      }
    }

    return recs;
  }

  // ─── Narrative Strength Rules ───────────────────────────────────────

  static List<ProfessionalRecommendation> _narrativeStrengthRules(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final recs = <ProfessionalRecommendation>[];

    for (final section in tree.sections) {
      // Skip non-inspection sections
      if (!_isInspectionSection(section.key)) continue;

      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};
        if (answers.isEmpty) continue;

        final conditionRating = _findConditionRating(node, answers);
        if (conditionRating == null) continue;

        final ratingNum = int.tryParse(conditionRating) ?? 0;
        if (ratingNum < 2) continue;

        // Check text fields for narrative depth
        for (final field in node.fields) {
          if (field.type != InspectionFieldType.text) continue;
          if (field.label.toLowerCase().contains('not inspected')) continue;

          final value = answers[field.id] ?? '';

          // Rule N-001: Empty text on condition 3 screen
          if (value.trim().isEmpty && ratingNum == 3) {
            recs.add(_rec(
              category: RecommendationCategory.narrativeStrength,
              severity: RecommendationSeverity.high,
              screenId: node.id,
              fieldId: field.id,
              reason:
                  'Condition Rating 3 assigned on "${node.title}" but '
                  'the "${field.label}" field is empty.',
              suggestedText:
                  'A Condition Rating 3 indicates a serious defect '
                  'requiring urgent attention. The surveyor should '
                  'describe the nature, extent, and potential '
                  'consequences of the deficiency observed, and indicate '
                  'any further specialist investigation or urgent '
                  'repairs required.',
            ));
          } else if (value.trim().isEmpty && ratingNum == 2) {
            // Rule N-002: Empty text on condition 2 screen
            recs.add(_rec(
              category: RecommendationCategory.narrativeStrength,
              severity: RecommendationSeverity.moderate,
              screenId: node.id,
              fieldId: field.id,
              reason:
                  'Condition Rating 2 assigned on "${node.title}" but '
                  'the "${field.label}" field is empty.',
              suggestedText:
                  'A Condition Rating 2 indicates defects that require '
                  'repair or replacement but are not considered urgent. '
                  'The surveyor should describe the nature of defects '
                  'observed and any repair or maintenance actions '
                  'recommended.',
            ));
          } else if (value.trim().length < 20 &&
              value.trim().isNotEmpty &&
              ratingNum >= 2) {
            // Rule N-003: Brief text on rated screen
            recs.add(_rec(
              category: RecommendationCategory.narrativeStrength,
              severity: RecommendationSeverity.low,
              screenId: node.id,
              fieldId: field.id,
              reason:
                  'The narrative for "${field.label}" on "${node.title}" '
                  'appears brief for a Condition Rating $conditionRating '
                  'element.',
              suggestedText:
                  'Consider elaborating on the condition observed, '
                  'including the specific nature of any defects, their '
                  'likely cause, and any implications for the property. '
                  'Fuller narrative supports the assigned Condition '
                  'Rating and aids client understanding.',
            ));
          }
        }
      }
    }

    return recs;
  }

  // ─── Risk Clarification Rules ───────────────────────────────────────

  static List<ProfessionalRecommendation> _riskClarificationRules(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final recs = <ProfessionalRecommendation>[];
    var condition3Count = 0;

    for (final section in tree.sections) {
      if (!_isInspectionSection(section.key)) continue;

      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};

        final conditionRating = _findConditionRating(node, answers);
        if (conditionRating != '3') continue;
        condition3Count++;

        // Rule R-001: Condition 3 without Repair field set
        final repairField = _findRepairField(node);
        if (repairField != null) {
          final repairValue = answers[repairField] ?? '';
          if (repairValue.isEmpty) {
            recs.add(_rec(
              category: RecommendationCategory.riskClarification,
              severity: RecommendationSeverity.high,
              screenId: node.id,
              fieldId: repairField,
              reason:
                  'Condition Rating 3 assigned on "${node.title}" without '
                  'a corresponding repair urgency selection.',
              suggestedText:
                  'Where a Condition Rating 3 is assigned, the report '
                  'should clearly indicate the urgency of repair '
                  'required. The surveyor should specify whether '
                  'immediate action ("Repair now") or prompt attention '
                  '("Repair soon") is recommended, in accordance with '
                  'RICS Level 2/3 reporting standards.',
            ));
          }

          // Rule R-002: "Repair now" without specialist referral mention
          if (repairValue == 'Repair now') {
            final hasSpecialistText = _mentionsSpecialist(node, answers);
            if (!hasSpecialistText) {
              recs.add(_rec(
                category: RecommendationCategory.riskClarification,
                severity: RecommendationSeverity.moderate,
                screenId: node.id,
                reason:
                    '"Repair now" selected on "${node.title}" but no '
                    'specialist referral is mentioned in the narrative.',
                suggestedText:
                    'Where urgent repair is recommended, the surveyor '
                    'should consider whether a specialist contractor or '
                    'further investigation by a qualified professional '
                    'is required, and advise the client accordingly.',
              ));
            }
          }
        }
      }
    }

    // Rule R-003: Multiple condition-3 items across sections without summary
    if (condition3Count >= 3) {
      recs.add(_rec(
        category: RecommendationCategory.riskClarification,
        severity: RecommendationSeverity.moderate,
        screenId: '_summary',
        reason:
            '$condition3Count elements have been assigned Condition '
            'Rating 3 across the survey. A consolidated risk overview '
            'may assist the client.',
        suggestedText:
            'Multiple significant defects have been identified across '
            'the property. The surveyor should consider providing a '
            'consolidated summary of the most critical findings, '
            'their potential interaction, and an overall assessment '
            'of the property\'s condition to aid client '
            'decision-making.',
      ));
    }

    return recs;
  }

  // ─── Data Gap Rules ─────────────────────────────────────────────────

  static List<ProfessionalRecommendation> _dataGapRules(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final recs = <ProfessionalRecommendation>[];

    for (final section in tree.sections) {
      if (!_isInspectionSection(section.key)) continue;

      // Track how many screens in this section have data
      final screenNodes = section.nodes
          .where((n) => n.type == InspectionNodeType.screen)
          .toList();
      final answeredCount = screenNodes
          .where((n) => _hasAnyContent(n, allAnswers[n.id] ?? {}))
          .length;

      // Only flag gaps if the section is partially completed
      if (answeredCount == 0 || answeredCount == screenNodes.length) continue;

      for (final node in screenNodes) {
        final answers = allAnswers[node.id] ?? {};

        // Rule D-001: Completely unanswered screen in a partially-complete section
        if (!_hasAnyContent(node, answers)) {
          recs.add(_rec(
            category: RecommendationCategory.dataGaps,
            severity: RecommendationSeverity.moderate,
            screenId: node.id,
            reason:
                '"${node.title}" in section "${section.title}" has not '
                'been completed, while other screens in the section '
                'contain data.',
            suggestedText:
                'This element should be inspected and documented, or '
                'a clear explanation provided if the element was not '
                'accessible or not present at the property. Incomplete '
                'sections may reduce the reliability and professional '
                'standing of the report.',
          ));
          continue;
        }

        // Rule D-002: Condition rating field present but not answered
        for (final field in node.fields) {
          if (!_isConditionRatingField(field)) continue;
          final value = answers[field.id] ?? '';
          if (value.isEmpty) {
            recs.add(_rec(
              category: RecommendationCategory.dataGaps,
              severity: RecommendationSeverity.high,
              screenId: node.id,
              fieldId: field.id,
              reason:
                  'The Condition Rating on "${node.title}" has not '
                  'been assigned, despite other fields being completed.',
              suggestedText:
                  'Every inspected element should receive an '
                  'appropriate Condition Rating (1, 2, or 3) in '
                  'accordance with RICS Home Survey Standard. The '
                  'Condition Rating provides the client with a clear, '
                  'standardised assessment of the element\'s condition.',
            ));
          }
        }
      }
    }

    return recs;
  }

  // ─── Cross-Section Contradiction Rules ──────────────────────────────

  /// Detects inconsistencies across sections — e.g. exterior roof rated 1
  /// but interior ceiling shows condition 3 damp, or external walls rated 1
  /// but interior damp-related items rated 3.
  static List<ProfessionalRecommendation> _crossSectionContradictionRules(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final recs = <ProfessionalRecommendation>[];

    // Build keyword → {sectionKey, screenId, title, rating} index
    final ratedScreens = <_RatedScreen>[];
    for (final section in tree.sections) {
      if (!_isInspectionSection(section.key)) continue;
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};
        final rating = _findConditionRating(node, answers);
        if (rating == null || rating.isEmpty) continue;
        final ratingNum = int.tryParse(rating);
        if (ratingNum == null) continue;
        ratedScreens.add(_RatedScreen(
          sectionKey: section.key,
          screenId: node.id,
          title: node.title,
          rating: ratingNum,
        ));
      }
    }

    // Check related element pairs across sections for rating contradictions
    for (final keyword in _crossSectionKeywords) {
      final matches = ratedScreens.where(
        (s) => s.title.toLowerCase().contains(keyword),
      ).toList();
      if (matches.length < 2) continue;

      // Find pairs in different sections with rating spread ≥ 2
      for (var i = 0; i < matches.length; i++) {
        for (var j = i + 1; j < matches.length; j++) {
          final a = matches[i];
          final b = matches[j];
          if (a.sectionKey == b.sectionKey) continue;

          final spread = (a.rating - b.rating).abs();
          if (spread < 2) continue;

          final better = a.rating < b.rating ? a : b;
          final worse = a.rating < b.rating ? b : a;

          recs.add(_rec(
            category: RecommendationCategory.riskClarification,
            severity: RecommendationSeverity.moderate,
            screenId: worse.screenId,
            reason:
                '"${better.title}" (section ${better.sectionKey}) is rated '
                'Condition ${better.rating} while "${worse.title}" '
                '(section ${worse.sectionKey}) is rated '
                'Condition ${worse.rating}. These related elements '
                'have a significant rating discrepancy.',
            suggestedText:
                'The surveyor should verify the consistency of '
                'condition assessments between related interior and '
                'exterior elements. Where a significant discrepancy '
                'exists, the narrative should explain the reason — '
                'for example, a recently repaired exterior may conceal '
                'historic damage visible internally.',
          ));
        }
      }
    }

    return recs;
  }

  /// Keywords used to match related elements across sections.
  static const _crossSectionKeywords = [
    'roof',
    'wall',
    'damp',
    'window',
    'chimney',
    'ceiling',
    'floor',
    'door',
  ];

  // ─── Valuation Justification Rules ──────────────────────────────────

  static List<ProfessionalRecommendation> _valuationJustificationRules(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    final recs = <ProfessionalRecommendation>[];

    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};
        final titleLower = node.title.toLowerCase();

        // Rule V-001: Missing or short comparables text
        if (titleLower.contains('comparable') ||
            titleLower.contains('comparison')) {
          final hasContent = _hasSubstantialText(node, answers, minLength: 30);
          if (!hasContent) {
            recs.add(_rec(
              category: RecommendationCategory.valuationJustification,
              severity: RecommendationSeverity.high,
              screenId: node.id,
              reason:
                  'The comparable evidence section "${node.title}" '
                  'lacks sufficient detail.',
              suggestedText:
                  'The valuation should be supported by appropriate '
                  'comparable evidence, including details of recent '
                  'transactions of similar properties in the locality. '
                  'Adequate comparable evidence is essential to '
                  'demonstrate the basis of the valuation figure and '
                  'comply with RICS Valuation Standards.',
            ));
          }
        }

        // Rule V-002: Missing market commentary
        if (titleLower.contains('market') ||
            titleLower.contains('local area')) {
          final hasContent = _hasSubstantialText(node, answers, minLength: 30);
          if (!hasContent) {
            recs.add(_rec(
              category: RecommendationCategory.valuationJustification,
              severity: RecommendationSeverity.moderate,
              screenId: node.id,
              reason:
                  'Market conditions commentary in "${node.title}" is '
                  'absent or brief.',
              suggestedText:
                  'The surveyor should provide commentary on prevailing '
                  'local market conditions, including supply and demand '
                  'dynamics, recent trends, and any factors that may '
                  'affect the property\'s marketability and value.',
            ));
          }
        }
      }
    }

    return recs;
  }

  // ─── Quality Scoring ────────────────────────────────────────────────

  /// Compute deterministic quality scores from raw survey data.
  ///
  /// Scores are percentages (0–100) derived from data completeness and
  /// correctness, NOT from recommendation count.
  static QualityScores _computeScores(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
    bool isValuation,
  ) {
    final compliance = _computeComplianceScore(tree, allAnswers);
    final narrative = _computeNarrativeScore(tree, allAnswers);
    final risk = _computeRiskScore(tree, allAnswers);
    final dataCompleteness = _computeDataCompletenessScore(tree, allAnswers);

    // Weighted average — compliance and narrative weighted highest as they
    // represent core RICS requirements. Risk weighted for safety-critical
    // elements. Data completeness as a baseline quality metric.
    final overall = compliance * 0.30 +
        narrative * 0.30 +
        risk * 0.25 +
        dataCompleteness * 0.15;

    return QualityScores(
      complianceScore: _round(compliance),
      narrativeScore: _round(narrative),
      riskScore: _round(risk),
      overallScore: _round(overall),
    );
  }

  /// Compliance score: % of required compliance items satisfied.
  ///
  /// Checks: EPC documented, condition ratings have main conditions,
  /// damp C3 items have evidence text.
  static double _computeComplianceScore(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    var checks = 0;
    var passes = 0;

    for (final section in tree.sections) {
      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};

        // Check: EPC documented in section D
        if (section.key == 'D' && _isEpcRelated(node)) {
          checks++;
          if (_hasAnyContent(node, answers)) passes++;
        }

        if (answers.isEmpty) continue;

        final conditionRating = _findConditionRating(node, answers);
        final mainCondition = _findMainCondition(node, answers);

        // Check: Condition rating has corresponding main condition
        if (conditionRating != null &&
            conditionRating.isNotEmpty &&
            mainCondition != null &&
            _fieldExists(node, mainCondition)) {
          checks++;
          if ((answers[mainCondition] ?? '').isNotEmpty) passes++;
        }

        // Check: Damp C3 has evidence text
        if (_isDampRelated(node) && conditionRating == '3') {
          checks++;
          if (_hasSubstantialText(node, answers)) passes++;
        }
      }
    }

    return checks == 0 ? 100.0 : (passes / checks) * 100;
  }

  /// Narrative score: % of condition-rated (≥2) screens with adequate text.
  static double _computeNarrativeScore(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    var totalRated = 0;
    var adequate = 0;

    for (final section in tree.sections) {
      if (!_isInspectionSection(section.key)) continue;

      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};

        final conditionRating = _findConditionRating(node, answers);
        if (conditionRating == null) continue;
        final ratingNum = int.tryParse(conditionRating) ?? 0;
        if (ratingNum < 2) continue;

        totalRated++;
        if (_hasSubstantialText(node, answers)) adequate++;
      }
    }

    return totalRated == 0 ? 100.0 : (adequate / totalRated) * 100;
  }

  /// Risk score: % of Condition 3 items with repair + specialist documentation.
  static double _computeRiskScore(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    var totalC3 = 0;
    double documented = 0;

    for (final section in tree.sections) {
      if (!_isInspectionSection(section.key)) continue;

      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        final answers = allAnswers[node.id] ?? {};

        final conditionRating = _findConditionRating(node, answers);
        if (conditionRating != '3') continue;
        totalC3++;

        final repairField = _findRepairField(node);
        final hasRepair = repairField != null &&
            (answers[repairField] ?? '').isNotEmpty;
        final hasNarrative = _hasSubstantialText(node, answers);

        if (hasRepair && hasNarrative) {
          documented++;
        } else if (hasRepair || hasNarrative) {
          // Partial credit — one of two requirements met
          documented += 0.5;
        }
      }
    }

    return totalC3 == 0 ? 100.0 : (documented / totalC3) * 100;
  }

  /// Data completeness: % of screens in inspection sections with any content.
  static double _computeDataCompletenessScore(
    InspectionTreePayload tree,
    Map<String, Map<String, String>> allAnswers,
  ) {
    var totalScreens = 0;
    var completed = 0;

    for (final section in tree.sections) {
      if (!_isInspectionSection(section.key)) continue;

      for (final node in section.nodes) {
        if (node.type != InspectionNodeType.screen) continue;
        totalScreens++;

        final answers = allAnswers[node.id] ?? {};
        if (_hasAnyContent(node, answers)) completed++;
      }
    }

    return totalScreens == 0 ? 100.0 : (completed / totalScreens) * 100;
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  static ProfessionalRecommendation _rec({
    required RecommendationCategory category,
    required RecommendationSeverity severity,
    required String screenId,
    String? fieldId,
    required String reason,
    required String suggestedText,
  }) {
    final auditHash = ProfessionalRecommendation.computeAuditHash(
      category: category.name,
      severity: severity.name,
      screenId: screenId,
      reason: reason,
      suggestedText: suggestedText,
      source: RecommendationSource.rule.key,
      ruleVersion: engineVersion,
    );

    return ProfessionalRecommendation(
      id: _uuid.v4(),
      category: category,
      severity: severity,
      screenId: screenId,
      fieldId: fieldId,
      reason: reason,
      suggestedText: suggestedText,
      source: RecommendationSource.rule,
      ruleVersion: engineVersion,
      auditHash: auditHash,
    );
  }

  /// Find the condition rating value for a screen.
  static String? _findConditionRating(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    for (final field in node.fields) {
      if (_isConditionRatingField(field)) {
        return answers[field.id];
      }
    }
    return null;
  }

  /// Check if a field is a condition rating dropdown.
  static bool _isConditionRatingField(InspectionFieldDefinition field) {
    if (field.type != InspectionFieldType.dropdown) return false;
    final label = field.label.toLowerCase();
    if (label.contains('condition rating')) return true;
    // Common field IDs for condition rating
    if (field.options != null &&
        field.options!.length == 3 &&
        field.options!.contains('1') &&
        field.options!.contains('2') &&
        field.options!.contains('3')) {
      return true;
    }
    return false;
  }

  /// Find the field ID for "Main Condition" on a screen.
  static String? _findMainCondition(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    for (final field in node.fields) {
      if (field.type == InspectionFieldType.dropdown &&
          field.label.toLowerCase().contains('main condition')) {
        return field.id;
      }
    }
    return null;
  }

  /// Find the field ID for the "Repair" dropdown on a screen.
  static String? _findRepairField(InspectionNodeDefinition node) {
    for (final field in node.fields) {
      if (field.type == InspectionFieldType.dropdown) {
        final label = field.label.toLowerCase();
        if (label.contains('repair')) return field.id;
      }
    }
    return null;
  }

  /// Check if a field exists on a node by field ID.
  static bool _fieldExists(InspectionNodeDefinition node, String fieldId) {
    return node.fields.any((f) => f.id == fieldId);
  }

  /// Whether the node title relates to damp/moisture.
  static bool _isDampRelated(InspectionNodeDefinition node) {
    final t = node.title.toLowerCase();
    return t.contains('damp') ||
        t.contains('moisture') ||
        t.contains('condensation');
  }

  /// Whether the node relates to EPC/energy.
  static bool _isEpcRelated(InspectionNodeDefinition node) {
    final t = node.title.toLowerCase();
    return t.contains('epc') ||
        t.contains('energy') ||
        t.contains('efficiency');
  }

  /// Whether a section key is an inspection section (E/F/G/H).
  static bool _isInspectionSection(String key) {
    return const {'E', 'F', 'G', 'H'}.contains(key);
  }

  /// Check if any non-label field on a screen has a value.
  static bool _hasAnyContent(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    for (final field in node.fields) {
      if (field.type == InspectionFieldType.label) continue;
      final value = answers[field.id] ?? '';
      if (value.trim().isNotEmpty) return true;
    }
    return false;
  }

  /// Check if any text field has substantial content (>= minLength chars).
  static bool _hasSubstantialText(
    InspectionNodeDefinition node,
    Map<String, String> answers, {
    int minLength = 20,
  }) {
    for (final field in node.fields) {
      if (field.type != InspectionFieldType.text) continue;
      final value = answers[field.id] ?? '';
      if (value.trim().length >= minLength) return true;
    }
    return false;
  }

  /// Check if any text field mentions a specialist.
  static bool _mentionsSpecialist(
    InspectionNodeDefinition node,
    Map<String, String> answers,
  ) {
    const keywords = [
      'specialist',
      'further investigation',
      'qualified',
      'contractor',
      'structural engineer',
      'damp specialist',
      'electrician',
      'plumber',
      'roofer',
    ];
    for (final field in node.fields) {
      if (field.type != InspectionFieldType.text) continue;
      final value = (answers[field.id] ?? '').toLowerCase();
      if (value.isEmpty) continue;
      for (final keyword in keywords) {
        if (value.contains(keyword)) return true;
      }
    }
    return false;
  }

  static double _round(double v) => (v * 10).roundToDouble() / 10;
}

/// Internal data class for cross-section analysis.
class _RatedScreen {
  const _RatedScreen({
    required this.sectionKey,
    required this.screenId,
    required this.title,
    required this.rating,
  });

  final String sectionKey;
  final String screenId;
  final String title;
  final int rating;
}
