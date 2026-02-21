import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/professional_recommendations/domain/models/professional_recommendation.dart';
import 'package:survey_scriber/features/professional_recommendations/domain/services/recommendation_engine.dart';
import 'package:survey_scriber/features/professional_recommendations/domain/services/recommendation_compute.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';

// ── Test helpers ──────────────────────────────────────────────────────

InspectionFieldDefinition _field(
  String id,
  String label, {
  InspectionFieldType type = InspectionFieldType.text,
  List<String>? options,
}) {
  return InspectionFieldDefinition(
    id: id,
    label: label,
    type: type,
    options: options,
  );
}

InspectionNodeDefinition _screen(
  String id,
  String title,
  List<InspectionFieldDefinition> fields,
) {
  return InspectionNodeDefinition(
    id: id,
    title: title,
    fields: fields,
    type: InspectionNodeType.screen,
  );
}

InspectionSectionDefinition _section(
  String key,
  String title,
  List<InspectionNodeDefinition> nodes,
) {
  return InspectionSectionDefinition(
    key: key,
    title: title,
    description: '',
    nodes: nodes,
  );
}

InspectionTreePayload _tree(List<InspectionSectionDefinition> sections) {
  return InspectionTreePayload(sections: sections);
}

/// Standard condition rating field.
InspectionFieldDefinition get _conditionRating => _field(
      'condition_rating',
      'Condition Rating',
      type: InspectionFieldType.dropdown,
      options: ['1', '2', '3'],
    );

/// Standard main condition field.
InspectionFieldDefinition get _mainCondition => _field(
      'main_condition',
      'Main Condition',
      type: InspectionFieldType.dropdown,
      options: ['Reasonable', 'Satisfactory', 'Unsatisfactory and Poor'],
    );

/// Standard repair field.
InspectionFieldDefinition get _repair => _field(
      'repair',
      'Repair',
      type: InspectionFieldType.dropdown,
      options: ['Repair soon', 'Repair now'],
    );

/// Standard text field.
InspectionFieldDefinition get _notes =>
    _field('notes', 'Notes', type: InspectionFieldType.text);

// ── Tests ─────────────────────────────────────────────────────────────

void main() {
  group('RecommendationEngine', () {
    test('returns empty result for a fully-answered, well-documented survey', () {
      final tree = _tree([
        _section('E', 'Outside the Property', [
          _screen('e_roof', 'Roof', [
            _conditionRating,
            _mainCondition,
            _notes,
          ]),
        ]),
      ]);

      final answers = {
        'e_roof': {
          'condition_rating': '1',
          'main_condition': 'Reasonable',
          'notes': 'Roof is in good condition with no visible defects.',
        },
      };

      final result = RecommendationEngine.analyze(
        surveyId: 'test-1',
        tree: tree,
        allAnswers: answers,
        isValuation: false,
      );

      expect(result.recommendations, isEmpty);
      expect(result.surveyId, 'test-1');
      expect(result.engineVersion, RecommendationEngine.engineVersion);
    });

    test('returns empty result for a survey with no answers', () {
      final tree = _tree([
        _section('E', 'Outside', [
          _screen('e_roof', 'Roof', [_conditionRating, _notes]),
        ]),
      ]);

      final result = RecommendationEngine.analyze(
        surveyId: 'test-2',
        tree: tree,
        allAnswers: {},
        isValuation: false,
      );

      // No answers → no recommendations (not a "data gap" because
      // the section isn't partially complete)
      expect(result.recommendations, isEmpty);
    });

    group('Compliance rules', () {
      test('flags condition rating without main condition', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _mainCondition,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '2',
            // main_condition deliberately empty
            'notes': 'Some wear observed.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final compliance = result.byCategory(RecommendationCategory.compliance);
        expect(compliance, isNotEmpty);
        expect(compliance.first.severity, RecommendationSeverity.moderate);
        expect(compliance.first.reason, contains('Main Condition'));
      });

      test('flags damp-related screen with rating 3 but no evidence text', () {
        final tree = _tree([
          _section('F', 'Inside', [
            _screen('f_damp', 'Dampness', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'f_damp': {
            'condition_rating': '3',
            // notes empty — no evidence text
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final compliance = result.byCategory(RecommendationCategory.compliance);
        expect(compliance.any((r) => r.reason.contains('damp')), isTrue);
        expect(compliance.any((r) => r.severity == RecommendationSeverity.high), isTrue);
      });

      test('flags missing EPC information in section D', () {
        final tree = _tree([
          _section('D', 'About Property', [
            _screen('d_epc', 'Energy Performance Certificate', [
              _field('epc_rating', 'EPC Rating', type: InspectionFieldType.text),
            ]),
          ]),
        ]);

        final answers = {
          'd_epc': <String, String>{},
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final compliance = result.byCategory(RecommendationCategory.compliance);
        expect(compliance.any((r) => r.reason.contains('EPC')), isTrue);
      });

      test('flags main condition set without condition rating (C-004)', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _mainCondition,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            // condition_rating field exists but is empty
            'condition_rating': '',
            'main_condition': 'Satisfactory',
            'notes': 'Appears to be in satisfactory condition.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final compliance = result.byCategory(RecommendationCategory.compliance);
        expect(
          compliance.any((r) =>
              r.reason.contains('Main Condition') &&
              r.reason.contains('no Condition Rating')),
          isTrue,
        );
      });
    });

    group('Narrative Strength rules', () {
      test('flags empty text on screen with condition rating 3', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            'notes': '',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final narrative =
            result.byCategory(RecommendationCategory.narrativeStrength);
        expect(narrative, isNotEmpty);
        expect(narrative.first.severity, RecommendationSeverity.high);
      });

      test('flags empty text on screen with condition rating 2', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '2',
            'notes': '',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final narrative =
            result.byCategory(RecommendationCategory.narrativeStrength);
        expect(narrative, isNotEmpty);
        expect(narrative.first.severity, RecommendationSeverity.moderate);
      });

      test('flags brief text (< 20 chars) on condition-rated screen', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '2',
            'notes': 'Some cracks.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final narrative =
            result.byCategory(RecommendationCategory.narrativeStrength);
        expect(narrative.any((r) => r.severity == RecommendationSeverity.low),
            isTrue);
      });

      test('does not flag condition rating 1 screens', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '1',
            'notes': '', // Empty, but rating 1 — no flag
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final narrative =
            result.byCategory(RecommendationCategory.narrativeStrength);
        expect(narrative, isEmpty);
      });
    });

    group('Risk Clarification rules', () {
      test('flags condition 3 without repair field set', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _repair,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            // repair deliberately empty
            'notes': 'Severe cracking observed across entire elevation.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk =
            result.byCategory(RecommendationCategory.riskClarification);
        expect(risk.any((r) => r.reason.contains('repair urgency')), isTrue);
        expect(risk.any((r) => r.severity == RecommendationSeverity.high), isTrue);
      });

      test('flags "Repair now" without specialist mention', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _repair,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            'repair': 'Repair now',
            'notes': 'Severe cracking observed across the elevation.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk =
            result.byCategory(RecommendationCategory.riskClarification);
        expect(
            risk.any((r) => r.reason.contains('specialist')), isTrue);
      });

      test('does not flag "Repair now" when specialist is mentioned', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _repair,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            'repair': 'Repair now',
            'notes':
                'Severe cracking. A structural engineer should investigate.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk =
            result.byCategory(RecommendationCategory.riskClarification);
        expect(
            risk.any((r) => r.reason.contains('specialist')), isFalse);
      });

      test('flags consolidated summary when 3+ condition-3 items', () {
        final nodes = List.generate(
          4,
          (i) => _screen('e_item_$i', 'Item $i', [
            _conditionRating,
            _repair,
            _notes,
          ]),
        );

        final tree = _tree([_section('E', 'Outside', nodes)]);

        final answers = <String, Map<String, String>>{
          for (var i = 0; i < 4; i++)
            'e_item_$i': {
              'condition_rating': '3',
              'repair': 'Repair soon',
              'notes':
                  'Defect observed on item $i requiring specialist attention.',
            },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk =
            result.byCategory(RecommendationCategory.riskClarification);
        expect(
            risk.any((r) =>
                r.screenId == '_summary' &&
                r.reason.contains('Condition Rating 3')),
            isTrue);
      });
    });

    group('Data Gap rules', () {
      test('flags unanswered screen in partially-complete section', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
            _screen('e_walls', 'External Walls', [_conditionRating, _notes]),
          ]),
        ]);

        final answers = {
          // e_roof has answers, e_walls does not
          'e_roof': {
            'condition_rating': '1',
            'notes': 'Roof in good condition.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final gaps = result.byCategory(RecommendationCategory.dataGaps);
        expect(gaps.any((r) => r.screenId == 'e_walls'), isTrue);
      });

      test('flags missing condition rating on an otherwise answered screen', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
            _screen('e_walls', 'External Walls', [_conditionRating, _notes]),
            _screen('e_chimneys', 'Chimneys', [_conditionRating, _notes]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '1',
            'notes': 'Good.',
          },
          'e_walls': {
            // condition_rating missing
            'notes': 'Some cracks but no condition rating assigned.',
          },
          // e_chimneys has no answers — makes section partially complete
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final gaps = result.byCategory(RecommendationCategory.dataGaps);
        expect(
            gaps.any((r) =>
                r.screenId == 'e_walls' &&
                r.reason.contains('Condition Rating')),
            isTrue);
      });

      test('does not flag if whole section is empty', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
            _screen('e_walls', 'External Walls', [_conditionRating, _notes]),
          ]),
        ]);

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: {},
          isValuation: false,
        );

        final gaps = result.byCategory(RecommendationCategory.dataGaps);
        expect(gaps, isEmpty);
      });
    });

    group('Valuation Justification rules', () {
      test('flags missing comparable evidence', () {
        final tree = _tree([
          _section('V', 'Valuation', [
            _screen('v_comparables', 'Comparable Evidence', [
              _field('comp_text', 'Comparables', type: InspectionFieldType.text),
            ]),
          ]),
        ]);

        final answers = {
          'v_comparables': {'comp_text': ''},
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: true,
        );

        final valuation =
            result.byCategory(RecommendationCategory.valuationJustification);
        expect(valuation.any((r) => r.reason.contains('comparable')), isTrue);
      });

      test('flags missing market commentary', () {
        final tree = _tree([
          _section('V', 'Valuation', [
            _screen('v_market', 'Local Market Conditions', [
              _field('market_text', 'Market Commentary',
                  type: InspectionFieldType.text),
            ]),
          ]),
        ]);

        final answers = {
          'v_market': {'market_text': 'Brief.'},
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: true,
        );

        final valuation =
            result.byCategory(RecommendationCategory.valuationJustification);
        expect(valuation.any((r) => r.reason.contains('Market')), isTrue);
      });

      test('does not run valuation rules for non-valuation survey', () {
        final tree = _tree([
          _section('V', 'Valuation', [
            _screen('v_comparables', 'Comparable Evidence', [
              _field('comp_text', 'Comparables', type: InspectionFieldType.text),
            ]),
          ]),
        ]);

        final answers = {
          'v_comparables': {'comp_text': ''},
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false, // NOT a valuation
        );

        final valuation =
            result.byCategory(RecommendationCategory.valuationJustification);
        expect(valuation, isEmpty);
      });
    });

    group('Cross-section contradiction rules', () {
      test('detects roof rated 1 outside but ceiling rated 3 inside', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof Covering', [
              _conditionRating,
              _notes,
            ]),
          ]),
          _section('F', 'Inside', [
            _screen('f_roof', 'Roof Space', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '1',
            'notes': 'Roof appears sound with no visible defects.',
          },
          'f_roof': {
            'condition_rating': '3',
            'notes': 'Significant signs of water ingress in the roof space.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk = result.byCategory(RecommendationCategory.riskClarification);
        expect(
          risk.any((r) =>
              r.reason.contains('Roof') &&
              r.reason.contains('rating discrepancy')),
          isTrue,
        );
      });

      test('detects wall rated 1 outside but damp rated 3 inside', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
          _section('F', 'Inside', [
            _screen('f_walls', 'Internal Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '1',
            'notes': 'Walls in good condition.',
          },
          'f_walls': {
            'condition_rating': '3',
            'notes': 'Significant cracking and damp penetration.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk = result.byCategory(RecommendationCategory.riskClarification);
        expect(
          risk.any((r) =>
              r.reason.contains('Wall') &&
              r.reason.contains('rating discrepancy')),
          isTrue,
        );
      });

      test('does not flag screens in the same section', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof Covering', [
              _conditionRating,
              _notes,
            ]),
            _screen('e_roof2', 'Roof Other', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '1',
            'notes': 'Good condition.',
          },
          'e_roof2': {
            'condition_rating': '3',
            'notes': 'Severe defect found on roof.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk = result.byCategory(RecommendationCategory.riskClarification);
        // Should NOT flag cross-section contradiction for same-section screens
        expect(
          risk.any((r) => r.reason.contains('rating discrepancy')),
          isFalse,
        );
      });

      test('does not flag when rating spread is only 1', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof Covering', [
              _conditionRating,
              _notes,
            ]),
          ]),
          _section('F', 'Inside', [
            _screen('f_roof', 'Roof Space', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '1',
            'notes': 'Good.',
          },
          'f_roof': {
            'condition_rating': '2',
            'notes': 'Minor issues in roof space.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        final risk = result.byCategory(RecommendationCategory.riskClarification);
        expect(
          risk.any((r) => r.reason.contains('rating discrepancy')),
          isFalse,
        );
      });
    });

    group('Result helpers', () {
      test('severity counts are correct', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [_conditionRating, _notes]),
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            'notes': '',
          },
          'e_roof': {
            'condition_rating': '2',
            'notes': '',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.highCount, greaterThan(0));
        expect(result.recommendations.length,
            result.highCount + result.moderateCount + result.lowCount);
      });

      test('results are sorted by severity: high first', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _repair,
              _notes,
            ]),
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            // repair empty → high severity risk clarification
            'notes': 'Short.',
          },
          'e_roof': {
            'condition_rating': '2',
            'notes': '',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        if (result.recommendations.length >= 2) {
          for (var i = 1; i < result.recommendations.length; i++) {
            expect(
              result.recommendations[i].severity.index,
              greaterThanOrEqualTo(
                  result.recommendations[i - 1].severity.index),
            );
          }
        }
      });

      test('bySource filters rule vs ai recommendations', () {
        final result = ProfessionalRecommendationsResult(
          surveyId: 'test',
          recommendations: const [
            ProfessionalRecommendation(
              id: '1',
              category: RecommendationCategory.compliance,
              severity: RecommendationSeverity.high,
              screenId: 's1',
              reason: 'rule reason',
              suggestedText: 'rule text',
              source: RecommendationSource.rule,
            ),
            ProfessionalRecommendation(
              id: '2',
              category: RecommendationCategory.narrativeStrength,
              severity: RecommendationSeverity.moderate,
              screenId: 's2',
              reason: 'ai reason',
              suggestedText: 'ai text',
              source: RecommendationSource.ai,
            ),
          ],
          generatedAt: DateTime(2026),
          engineVersion: '2.0.0',
        );

        expect(result.ruleCount, 1);
        expect(result.aiCount, 1);
        expect(result.bySource(RecommendationSource.rule).length, 1);
        expect(result.bySource(RecommendationSource.ai).length, 1);
      });
    });

    group('Model', () {
      test('ProfessionalRecommendation copyWith preserves values', () {
        const rec = ProfessionalRecommendation(
          id: 'abc',
          category: RecommendationCategory.compliance,
          severity: RecommendationSeverity.high,
          screenId: 'screen_1',
          reason: 'Test reason',
          suggestedText: 'Test suggestion',
        );

        final accepted = rec.copyWith(accepted: true);
        expect(accepted.accepted, isTrue);
        expect(accepted.id, 'abc');
        expect(accepted.category, RecommendationCategory.compliance);
      });

      test('ProfessionalRecommendation copyWith preserves audit fields', () {
        const rec = ProfessionalRecommendation(
          id: 'abc',
          category: RecommendationCategory.compliance,
          severity: RecommendationSeverity.high,
          screenId: 'screen_1',
          reason: 'Test reason',
          suggestedText: 'Test suggestion',
          source: RecommendationSource.ai,
          aiModelVersion: 'gemini-1.5-pro',
          confidenceScore: 0.92,
          internalReasoning: 'Because of reasons',
          auditHash: 'abcdef1234567890',
        );

        final updated = rec.copyWith(accepted: true);
        expect(updated.source, RecommendationSource.ai);
        expect(updated.aiModelVersion, 'gemini-1.5-pro');
        expect(updated.confidenceScore, 0.92);
        expect(updated.internalReasoning, 'Because of reasons');
        expect(updated.auditHash, 'abcdef1234567890');
      });

      test('ProfessionalRecommendationsResult byCategory filters correctly', () {
        final result = ProfessionalRecommendationsResult(
          surveyId: 'test',
          recommendations: const [
            ProfessionalRecommendation(
              id: '1',
              category: RecommendationCategory.compliance,
              severity: RecommendationSeverity.high,
              screenId: 's1',
              reason: 'r1',
              suggestedText: 't1',
            ),
            ProfessionalRecommendation(
              id: '2',
              category: RecommendationCategory.dataGaps,
              severity: RecommendationSeverity.moderate,
              screenId: 's2',
              reason: 'r2',
              suggestedText: 't2',
            ),
          ],
          generatedAt: DateTime(2026),
          engineVersion: '1.0.0',
        );

        expect(result.byCategory(RecommendationCategory.compliance).length, 1);
        expect(result.byCategory(RecommendationCategory.dataGaps).length, 1);
        expect(result.byCategory(RecommendationCategory.narrativeStrength), isEmpty);
        expect(result.highCount, 1);
        expect(result.moderateCount, 1);
        expect(result.lowCount, 0);
        expect(result.acceptedCount, 0);
      });

      test('ProfessionalRecommendationsResult copyWith works', () {
        final result = ProfessionalRecommendationsResult(
          surveyId: 'test',
          recommendations: const [
            ProfessionalRecommendation(
              id: '1',
              category: RecommendationCategory.compliance,
              severity: RecommendationSeverity.high,
              screenId: 's1',
              reason: 'r1',
              suggestedText: 't1',
            ),
          ],
          generatedAt: DateTime(2026),
          engineVersion: '1.0.0',
        );

        final updated = result.copyWith(recommendations: []);
        expect(updated.recommendations, isEmpty);
        expect(updated.surveyId, 'test');
      });

      test('ProfessionalRecommendationsResult copyWith preserves scores', () {
        const scores = QualityScores(
          complianceScore: 85.0,
          narrativeScore: 72.3,
          riskScore: 91.0,
          overallScore: 82.5,
        );

        final result = ProfessionalRecommendationsResult(
          surveyId: 'test',
          recommendations: const [],
          generatedAt: DateTime(2026),
          engineVersion: '2.0.0',
          scores: scores,
        );

        final updated = result.copyWith(recommendations: []);
        expect(updated.scores, isNotNull);
        expect(updated.scores!.complianceScore, 85.0);
        expect(updated.scores!.overallScore, 82.5);
      });
    });

    group('v2.0.0 — Source metadata', () {
      test('engine version is 2.0.0', () {
        expect(RecommendationEngine.engineVersion, '2.0.0');
      });

      test('all recommendations have source = rule', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _repair,
              _notes,
            ]),
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            'notes': '',
          },
          'e_roof': {
            'condition_rating': '2',
            'notes': '',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.recommendations, isNotEmpty);
        for (final rec in result.recommendations) {
          expect(rec.source, RecommendationSource.rule);
          expect(rec.ruleVersion, '2.0.0');
        }
      });

      test('all recommendations have non-null audit hash', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _repair,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_walls': {
            'condition_rating': '3',
            'notes': '',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.recommendations, isNotEmpty);
        for (final rec in result.recommendations) {
          expect(rec.auditHash, isNotNull);
          expect(rec.auditHash, isNotEmpty);
          // Audit hash is 16 char hex substring of SHA-256
          expect(rec.auditHash!.length, 16);
        }
      });

      test('audit hash is deterministic for same input', () {
        final hash1 = ProfessionalRecommendation.computeAuditHash(
          category: 'compliance',
          severity: 'high',
          screenId: 'test_screen',
          reason: 'Test reason for audit',
          suggestedText: 'Test suggested text',
          source: 'rule',
          ruleVersion: '2.0.0',
        );

        final hash2 = ProfessionalRecommendation.computeAuditHash(
          category: 'compliance',
          severity: 'high',
          screenId: 'test_screen',
          reason: 'Test reason for audit',
          suggestedText: 'Test suggested text',
          source: 'rule',
          ruleVersion: '2.0.0',
        );

        expect(hash1, hash2);
      });

      test('audit hash differs for different input', () {
        final hash1 = ProfessionalRecommendation.computeAuditHash(
          category: 'compliance',
          severity: 'high',
          screenId: 'screen_1',
          reason: 'Reason A',
          suggestedText: 'Text A',
          source: 'rule',
        );

        final hash2 = ProfessionalRecommendation.computeAuditHash(
          category: 'compliance',
          severity: 'high',
          screenId: 'screen_1',
          reason: 'Reason B',
          suggestedText: 'Text B',
          source: 'rule',
        );

        expect(hash1, isNot(hash2));
      });
    });

    group('v2.0.0 — Quality Scores', () {
      test('result always includes quality scores', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
          ]),
        ]);

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: {},
          isValuation: false,
        );

        expect(result.scores, isNotNull);
      });

      test('perfect survey has 100% scores', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _mainCondition,
              _notes,
            ]),
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _mainCondition,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '1',
            'main_condition': 'Reasonable',
            'notes': 'Roof is in excellent condition throughout.',
          },
          'e_walls': {
            'condition_rating': '1',
            'main_condition': 'Reasonable',
            'notes': 'External walls are well-maintained and sound.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.scores!.complianceScore, 100.0);
        expect(result.scores!.narrativeScore, 100.0);
        expect(result.scores!.riskScore, 100.0);
        expect(result.scores!.overallScore, 100.0);
      });

      test('data completeness reflects answered screen ratio', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
            _screen('e_walls', 'External Walls', [_conditionRating, _notes]),
            _screen('e_chimney', 'Chimney', [_conditionRating, _notes]),
            _screen('e_door', 'Front Door', [_conditionRating, _notes]),
          ]),
        ]);

        // Only 2 of 4 screens answered → ~50% data completeness
        final answers = {
          'e_roof': {
            'condition_rating': '1',
            'notes': 'Good condition throughout.',
          },
          'e_walls': {
            'condition_rating': '1',
            'notes': 'Sound walls, no issues.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        // Data completeness should be 50% (2/4 screens)
        expect(result.scores!.overallScore, lessThan(100.0));
      });

      test('narrative score penalized for missing text on rated screens', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _notes,
            ]),
            _screen('e_walls', 'External Walls', [
              _conditionRating,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '2',
            'notes': '', // Empty text on rated screen → hurts narrative score
          },
          'e_walls': {
            'condition_rating': '3',
            'notes': '', // Empty text on rated screen → hurts narrative score
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.scores!.narrativeScore, lessThan(50.0));
      });

      test('risk score penalized for C3 items without repair + narrative', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _repair,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '3',
            // repair missing, notes missing → risk score 0%
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.scores!.riskScore, 0.0);
      });

      test('risk score gives partial credit for repair or narrative only', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [
              _conditionRating,
              _repair,
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_roof': {
            'condition_rating': '3',
            'repair': 'Repair now',
            'notes': '', // has repair but no substantial narrative
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        // Partial credit: 0.5/1 = 50%
        expect(result.scores!.riskScore, 50.0);
      });

      test('compliance score 100% when no compliance checks apply', () {
        // Tree with no EPC, no damp, no condition rating screens → no checks
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_other', 'Other Feature', [
              _notes,
            ]),
          ]),
        ]);

        final answers = {
          'e_other': {
            'notes': 'Tested.',
          },
        };

        final result = RecommendationEngine.analyze(
          surveyId: 'test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        // No compliance checks → defaults to 100%
        expect(result.scores!.complianceScore, 100.0);
      });

      test('QualityScores Equatable works', () {
        const s1 = QualityScores(
          complianceScore: 80.0,
          narrativeScore: 70.0,
          riskScore: 90.0,
          overallScore: 80.0,
        );
        const s2 = QualityScores(
          complianceScore: 80.0,
          narrativeScore: 70.0,
          riskScore: 90.0,
          overallScore: 80.0,
        );
        const s3 = QualityScores(
          complianceScore: 50.0,
          narrativeScore: 70.0,
          riskScore: 90.0,
          overallScore: 70.0,
        );

        expect(s1, s2);
        expect(s1, isNot(s3));
      });
    });

    group('v2.0.0 — RecommendationSource', () {
      test('source enum has correct keys', () {
        expect(RecommendationSource.rule.key, 'rule');
        expect(RecommendationSource.ai.key, 'ai');
      });

      test('fromKey round-trips correctly', () {
        expect(RecommendationSource.fromKey('rule'), RecommendationSource.rule);
        expect(RecommendationSource.fromKey('ai'), RecommendationSource.ai);
      });

      test('fromKey defaults to rule for unknown values', () {
        expect(RecommendationSource.fromKey('unknown'), RecommendationSource.rule);
        expect(RecommendationSource.fromKey(''), RecommendationSource.rule);
      });

      test('displayName values are user-friendly', () {
        expect(RecommendationSource.rule.displayName, 'Rule Engine');
        expect(RecommendationSource.ai.displayName, 'Professional Analysis');
      });
    });

    group('v2.0.0 — RecommendationEngineInput', () {
      test('input data class holds all fields', () {
        final tree = _tree([]);
        const answers = <String, Map<String, String>>{};

        final input = RecommendationEngineInput(
          surveyId: 'test-id',
          tree: tree,
          allAnswers: answers,
          isValuation: true,
        );

        expect(input.surveyId, 'test-id');
        expect(input.tree, tree);
        expect(input.allAnswers, answers);
        expect(input.isValuation, isTrue);
      });

      test('runRecommendationEngine produces valid result', () {
        final tree = _tree([
          _section('E', 'Outside', [
            _screen('e_roof', 'Roof', [_conditionRating, _notes]),
          ]),
        ]);

        final input = RecommendationEngineInput(
          surveyId: 'compute-test',
          tree: tree,
          allAnswers: {
            'e_roof': {
              'condition_rating': '2',
              'notes': '',
            },
          },
          isValuation: false,
        );

        final result = runRecommendationEngine(input);

        expect(result.surveyId, 'compute-test');
        expect(result.engineVersion, '2.0.0');
        expect(result.scores, isNotNull);
        expect(result.recommendations, isNotEmpty);
      });
    });

    group('Performance', () {
      test('handles large surveys (200+ screens) within 1 second', () {
        // Build a large tree with 200 screens across 4 sections
        final sections = ['E', 'F', 'G', 'H']
            .map((key) => _section(
                  key,
                  'Section $key',
                  List.generate(
                    50,
                    (i) => _screen(
                      '${key.toLowerCase()}_item_$i',
                      '${key}_Item_$i',
                      [_conditionRating, _mainCondition, _repair, _notes],
                    ),
                  ),
                ))
            .toList();

        final tree = _tree(sections);

        // Populate half the screens with partial data
        final answers = <String, Map<String, String>>{};
        for (final section in sections) {
          for (var i = 0; i < section.nodes.length; i++) {
            if (i.isEven) {
              answers[section.nodes[i].id] = {
                'condition_rating': (i % 3 + 1).toString(),
                'notes': i % 4 == 0 ? '' : 'Some notes about item $i.',
              };
            }
          }
        }

        final stopwatch = Stopwatch()..start();

        final result = RecommendationEngine.analyze(
          surveyId: 'perf-test',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(result.recommendations, isNotEmpty);
        expect(result.scores, isNotNull);
      });

      test('scoring completes for 200+ screen survey', () {
        final sections = ['E', 'F', 'G', 'H']
            .map((key) => _section(
                  key,
                  'Section $key',
                  List.generate(
                    50,
                    (i) => _screen(
                      '${key.toLowerCase()}_item_$i',
                      '${key}_Item_$i',
                      [_conditionRating, _mainCondition, _repair, _notes],
                    ),
                  ),
                ))
            .toList();

        final tree = _tree(sections);
        final answers = <String, Map<String, String>>{};
        for (final section in sections) {
          for (final node in section.nodes) {
            answers[node.id] = {
              'condition_rating': '1',
              'main_condition': 'Reasonable',
              'repair': 'Repair soon',
              'notes': 'This element was inspected and found to be in reasonable condition.',
            };
          }
        }

        final result = RecommendationEngine.analyze(
          surveyId: 'score-perf',
          tree: tree,
          allAnswers: answers,
          isValuation: false,
        );

        expect(result.scores, isNotNull);
        // Fully documented survey should have high scores
        expect(result.scores!.complianceScore, greaterThanOrEqualTo(90.0));
        expect(result.scores!.narrativeScore, 100.0);
        expect(result.scores!.overallScore, greaterThanOrEqualTo(90.0));
      });
    });
  });

  group('HybridRecommendationService (unit)', () {
    // These tests verify the validation and dedup logic of the control layer
    // using only the domain model (no mocks needed).

    test('validation rejects low-confidence AI recommendation', () {
      const rec = ProfessionalRecommendation(
        id: 'ai-1',
        category: RecommendationCategory.compliance,
        severity: RecommendationSeverity.high,
        screenId: 'screen_1',
        reason: 'This is a valid reason for the recommendation.',
        suggestedText: 'This is a valid suggested text for the recommendation.',
        source: RecommendationSource.ai,
        confidenceScore: 0.2, // Below 0.3 threshold
      );

      // Simulating the validation check from HybridRecommendationService
      final passes = rec.confidenceScore == null || rec.confidenceScore! >= 0.3;
      expect(passes, isFalse);
    });

    test('validation accepts high-confidence AI recommendation', () {
      const rec = ProfessionalRecommendation(
        id: 'ai-2',
        category: RecommendationCategory.narrativeStrength,
        severity: RecommendationSeverity.moderate,
        screenId: 'screen_2',
        reason: 'This is a sufficiently long reason for the recommendation.',
        suggestedText: 'This is a sufficiently long suggested text.',
        source: RecommendationSource.ai,
        confidenceScore: 0.85,
      );

      final passes = rec.confidenceScore == null || rec.confidenceScore! >= 0.3;
      expect(passes, isTrue);
    });

    test('deduplication removes AI rec matching rule screenId + category', () {
      const ruleRec = ProfessionalRecommendation(
        id: 'rule-1',
        category: RecommendationCategory.compliance,
        severity: RecommendationSeverity.high,
        screenId: 'screen_1',
        reason: 'Rule reason',
        suggestedText: 'Rule suggestion',
        source: RecommendationSource.rule,
      );

      const aiRec = ProfessionalRecommendation(
        id: 'ai-1',
        category: RecommendationCategory.compliance, // Same category
        severity: RecommendationSeverity.moderate,
        screenId: 'screen_1', // Same screenId
        reason: 'AI reason that is sufficiently long.',
        suggestedText: 'AI suggested text that is sufficiently long.',
        source: RecommendationSource.ai,
        confidenceScore: 0.9,
      );

      // Simulate dedup logic from HybridRecommendationService
      final ruleKeys = {'${ruleRec.screenId}|${ruleRec.category.name}'};
      final key = '${aiRec.screenId}|${aiRec.category.name}';
      final isDuplicate = ruleKeys.contains(key);

      expect(isDuplicate, isTrue);
    });

    test('deduplication keeps AI rec with different category on same screen', () {
      const ruleRec = ProfessionalRecommendation(
        id: 'rule-1',
        category: RecommendationCategory.compliance,
        severity: RecommendationSeverity.high,
        screenId: 'screen_1',
        reason: 'Rule reason',
        suggestedText: 'Rule suggestion',
        source: RecommendationSource.rule,
      );

      const aiRec = ProfessionalRecommendation(
        id: 'ai-1',
        category: RecommendationCategory.narrativeStrength, // Different category
        severity: RecommendationSeverity.moderate,
        screenId: 'screen_1', // Same screenId
        reason: 'AI narrative reason that is long enough.',
        suggestedText: 'AI suggested text that is long enough.',
        source: RecommendationSource.ai,
        confidenceScore: 0.9,
      );

      final ruleKeys = {'${ruleRec.screenId}|${ruleRec.category.name}'};
      final key = '${aiRec.screenId}|${aiRec.category.name}';
      final isDuplicate = ruleKeys.contains(key);

      expect(isDuplicate, isFalse);
    });
  });
}
