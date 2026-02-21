import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/domain/entities/ai_response.dart';

void main() {
  group('AiStatus', () {
    test('fromJson creates valid status when available', () {
      final json = {
        'available': true,
        'message': 'Service ready',
        'quotaRemaining': 80,
        'quotaLimit': 100,
      };

      final status = AiStatus.fromJson(json);

      expect(status.available, true);
      expect(status.message, 'Service ready');
      expect(status.quotaRemaining, 80);
      expect(status.quotaLimit, 100);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final status = AiStatus.fromJson(json);

      expect(status.available, false);
      expect(status.message, isNull);
      expect(status.quotaRemaining, isNull);
      expect(status.quotaLimit, isNull);
    });

    test('unavailable factory creates correct status', () {
      final status = AiStatus.unavailable('Network error');

      expect(status.available, false);
      expect(status.message, 'Network error');
    });

    test('quotaUsagePercent calculates correctly', () {
      const status = AiStatus(
        available: true,
        quotaRemaining: 25,
        quotaLimit: 100,
      );

      expect(status.quotaUsagePercent, 75.0);
    });

    test('quotaUsagePercent returns 0 when limit is null', () {
      const status = AiStatus(available: true);

      expect(status.quotaUsagePercent, 0);
    });

    test('quotaUsagePercent returns 0 when limit is 0', () {
      const status = AiStatus(
        available: true,
        quotaLimit: 0,
      );

      expect(status.quotaUsagePercent, 0);
    });
  });

  group('TokenUsage', () {
    test('fromJson creates valid usage', () {
      final json = {
        'inputTokens': 500,
        'outputTokens': 200,
      };

      final usage = TokenUsage.fromJson(json);

      expect(usage.inputTokens, 500);
      expect(usage.outputTokens, 200);
      expect(usage.totalTokens, 700);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final usage = TokenUsage.fromJson(json);

      expect(usage.inputTokens, 0);
      expect(usage.outputTokens, 0);
      expect(usage.totalTokens, 0);
    });
  });

  group('SectionNarrative', () {
    test('fromJson creates valid narrative', () {
      final json = {
        'sectionId': 'section-1',
        'sectionType': 'roof',
        'narrative': 'The roof appears to be in good condition.',
        'confidence': 0.95,
      };

      final narrative = SectionNarrative.fromJson(json);

      expect(narrative.sectionId, 'section-1');
      expect(narrative.sectionType, 'roof');
      expect(narrative.narrative, 'The roof appears to be in good condition.');
      expect(narrative.confidence, 0.95);
    });

    test('fromJson uses default confidence', () {
      final json = {
        'sectionId': 'section-1',
        'sectionType': 'roof',
        'narrative': 'Test',
      };

      final narrative = SectionNarrative.fromJson(json);

      expect(narrative.confidence, 0.8);
    });
  });

  group('AiReportResponse', () {
    test('fromJson creates valid response', () {
      final json = {
        'surveyId': 'survey-123',
        'promptVersion': '1.0.0',
        'sections': [
          {
            'sectionId': 'section-1',
            'sectionType': 'roof',
            'narrative': 'Roof narrative',
            'confidence': 0.9,
          },
        ],
        'executiveSummary': 'Overall summary',
        'fromCache': false,
        'disclaimer': 'AI generated content',
        'usage': {
          'inputTokens': 1000,
          'outputTokens': 500,
        },
      };

      final response = AiReportResponse.fromJson(json);

      expect(response.surveyId, 'survey-123');
      expect(response.promptVersion, '1.0.0');
      expect(response.sections.length, 1);
      expect(response.executiveSummary, 'Overall summary');
      expect(response.fromCache, false);
      expect(response.disclaimer, 'AI generated content');
      expect(response.usage.totalTokens, 1500);
    });

    test('getNarrativeForSection returns correct section', () {
      const response = AiReportResponse(
        surveyId: 'survey-123',
        promptVersion: '1.0.0',
        sections: [
          SectionNarrative(
            sectionId: 'section-1',
            sectionType: 'roof',
            narrative: 'Roof text',
          ),
          SectionNarrative(
            sectionId: 'section-2',
            sectionType: 'walls',
            narrative: 'Walls text',
          ),
        ],
        executiveSummary: 'Summary',
        fromCache: false,
        disclaimer: 'Disclaimer',
        usage: TokenUsage(inputTokens: 100, outputTokens: 50),
      );

      final narrative = response.getNarrativeForSection('section-2');

      expect(narrative?.sectionType, 'walls');
      expect(narrative?.narrative, 'Walls text');
    });

    test('getNarrativeForSection returns null for missing section', () {
      const response = AiReportResponse(
        surveyId: 'survey-123',
        promptVersion: '1.0.0',
        sections: [],
        executiveSummary: 'Summary',
        fromCache: false,
        disclaimer: 'Disclaimer',
        usage: TokenUsage(inputTokens: 100, outputTokens: 50),
      );

      final narrative = response.getNarrativeForSection('nonexistent');

      expect(narrative, isNull);
    });
  });

  group('AiRecommendation', () {
    test('fromJson creates valid recommendation', () {
      final json = {
        'issueId': 'issue-1',
        'priority': 'immediate',
        'action': 'Contact specialist immediately',
        'reasoning': 'Due to safety concerns',
        'specialistReferral': 'Structural Engineer',
        'urgencyExplanation': 'Potential structural damage',
      };

      final recommendation = AiRecommendation.fromJson(json);

      expect(recommendation.issueId, 'issue-1');
      expect(recommendation.priority, 'immediate');
      expect(recommendation.isImmediate, true);
      expect(recommendation.requiresSpecialist, true);
      expect(recommendation.specialistReferral, 'Structural Engineer');
    });

    test('priority helpers work correctly', () {
      expect(
        AiRecommendation.fromJson(const {'priority': 'immediate'}).isImmediate,
        true,
      );
      expect(
        AiRecommendation.fromJson(const {'priority': 'short_term'}).isShortTerm,
        true,
      );
      expect(
        AiRecommendation.fromJson(const {'priority': 'medium_term'}).isMediumTerm,
        true,
      );
      expect(
        AiRecommendation.fromJson(const {'priority': 'long_term'}).isLongTerm,
        true,
      );
      expect(
        AiRecommendation.fromJson(const {'priority': 'monitor'}).isMonitor,
        true,
      );
    });

    test('requiresSpecialist returns false when null', () {
      final recommendation = AiRecommendation.fromJson(const {
        'issueId': 'issue-1',
        'priority': 'monitor',
      });

      expect(recommendation.requiresSpecialist, false);
    });
  });

  group('RiskItem', () {
    test('fromJson creates valid risk item', () {
      final json = {
        'category': 'structural',
        'level': 'high',
        'description': 'Foundation issues detected',
        'relatedIds': ['issue-1', 'issue-2'],
      };

      final risk = RiskItem.fromJson(json);

      expect(risk.category, 'structural');
      expect(risk.level, 'high');
      expect(risk.isHighRisk, true);
      expect(risk.relatedIds?.length, 2);
    });

    test('risk level helpers work correctly', () {
      expect(RiskItem.fromJson(const {'level': 'high'}).isHighRisk, true);
      expect(RiskItem.fromJson(const {'level': 'medium'}).isMediumRisk, true);
      expect(RiskItem.fromJson(const {'level': 'low'}).isLowRisk, true);
    });
  });

  group('AiRiskSummaryResponse', () {
    test('fromJson creates valid response', () {
      final json = {
        'surveyId': 'survey-123',
        'promptVersion': '1.0.0',
        'overallRiskLevel': 'medium',
        'summary': 'Property has moderate issues',
        'keyRisks': [
          {'category': 'roof', 'level': 'high', 'description': 'Roof damage'},
          {'category': 'plumbing', 'level': 'low', 'description': 'Minor leak'},
        ],
        'keyPositives': ['Good foundation', 'Recent electrical work'],
        'fromCache': true,
        'disclaimer': 'AI generated',
        'usage': {'inputTokens': 500, 'outputTokens': 300},
      };

      final response = AiRiskSummaryResponse.fromJson(json);

      expect(response.overallRiskLevel, 'medium');
      expect(response.isMediumRisk, true);
      expect(response.highRiskCount, 1);
      expect(response.lowRiskCount, 1);
      expect(response.keyPositives.length, 2);
    });
  });

  group('ConsistencyIssue', () {
    test('fromJson creates valid issue', () {
      final json = {
        'type': 'contradiction',
        'severity': 'high',
        'description': 'Conflicting information',
        'sectionId': 'section-1',
        'fieldKey': 'condition',
        'suggestion': 'Review the condition field',
      };

      final issue = ConsistencyIssue.fromJson(json);

      expect(issue.type, 'contradiction');
      expect(issue.isContradiction, true);
      expect(issue.isHighSeverity, true);
      expect(issue.suggestion, 'Review the condition field');
    });

    test('type helpers work correctly', () {
      expect(
        ConsistencyIssue.fromJson(const {'type': 'missing_data'}).isMissingData,
        true,
      );
      expect(
        ConsistencyIssue.fromJson(const {'type': 'contradiction'}).isContradiction,
        true,
      );
      expect(
        ConsistencyIssue.fromJson(const {'type': 'compliance_risk'}).isComplianceRisk,
        true,
      );
      expect(
        ConsistencyIssue.fromJson(const {'type': 'incomplete'}).isIncomplete,
        true,
      );
    });
  });

  group('AiConsistencyResponse', () {
    test('fromJson creates valid response', () {
      final json = {
        'surveyId': 'survey-123',
        'promptVersion': '1.0.0',
        'score': 85,
        'issues': [
          {'type': 'missing_data', 'severity': 'high', 'description': 'Missing field'},
          {'type': 'incomplete', 'severity': 'low', 'description': 'Optional field empty'},
        ],
        'fromCache': false,
        'disclaimer': 'AI generated',
        'usage': {'inputTokens': 300, 'outputTokens': 150},
      };

      final response = AiConsistencyResponse.fromJson(json);

      expect(response.score, 85);
      expect(response.hasHighSeverityIssues, true);
      expect(response.highSeverityCount, 1);
      expect(response.lowSeverityCount, 1);
    });

    test('getIssuesForSection filters correctly', () {
      const response = AiConsistencyResponse(
        surveyId: 'survey-123',
        promptVersion: '1.0.0',
        score: 90,
        issues: [
          ConsistencyIssue(
            type: 'missing_data',
            severity: 'high',
            description: 'Issue 1',
            sectionId: 'section-1',
          ),
          ConsistencyIssue(
            type: 'incomplete',
            severity: 'low',
            description: 'Issue 2',
            sectionId: 'section-2',
          ),
          ConsistencyIssue(
            type: 'contradiction',
            severity: 'medium',
            description: 'Issue 3',
            sectionId: 'section-1',
          ),
        ],
        fromCache: false,
        disclaimer: 'Test',
        usage: TokenUsage(inputTokens: 100, outputTokens: 50),
      );

      final section1Issues = response.getIssuesForSection('section-1');

      expect(section1Issues.length, 2);
    });
  });

  group('PhotoTag', () {
    test('fromJson creates valid tag', () {
      final json = {
        'label': 'roof damage',
        'confidence': 0.92,
      };

      final tag = PhotoTag.fromJson(json);

      expect(tag.label, 'roof damage');
      expect(tag.confidence, 0.92);
      expect(tag.isHighConfidence, true);
    });

    test('confidence helpers work correctly', () {
      expect(PhotoTag.fromJson(const {'confidence': 0.9}).isHighConfidence, true);
      expect(PhotoTag.fromJson(const {'confidence': 0.6}).isMediumConfidence, true);
      expect(PhotoTag.fromJson(const {'confidence': 0.3}).isLowConfidence, true);
    });
  });

  group('AiPhotoTagsResponse', () {
    test('fromJson creates valid response', () {
      final json = {
        'surveyId': 'survey-123',
        'photoId': 'photo-456',
        'promptVersion': '1.0.0',
        'tags': [
          {'label': 'roof', 'confidence': 0.95},
          {'label': 'damage', 'confidence': 0.85},
          {'label': 'tiles', 'confidence': 0.4},
        ],
        'suggestedSection': 'roof_section',
        'description': 'Photo shows roof with damaged tiles',
        'fromCache': false,
        'disclaimer': 'AI generated',
        'usage': {'inputTokens': 200, 'outputTokens': 100},
      };

      final response = AiPhotoTagsResponse.fromJson(json);

      expect(response.photoId, 'photo-456');
      expect(response.tags.length, 3);
      expect(response.highConfidenceTags.length, 2);
      expect(response.tagsString, 'roof, damage, tiles');
      expect(response.suggestedSection, 'roof_section');
    });
  });
}
