import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/domain/entities/ai_response.dart';
import 'package:survey_scriber/features/ai/presentation/providers/ai_providers.dart';

void main() {
  group('AiReportState', () {
    test('initial state has correct defaults', () {
      const state = AiReportState();

      expect(state.response, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasResponse, false);
    });

    test('copyWith updates isLoading correctly', () {
      const state = AiReportState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, true);
      expect(updated.response, isNull);
      expect(updated.error, isNull);
    });

    test('copyWith updates response correctly', () {
      const state = AiReportState();
      const response = AiReportResponse(
        surveyId: 'survey-123',
        promptVersion: '1.0.0',
        sections: [],
        executiveSummary: 'Summary',
        fromCache: false,
        disclaimer: 'Disclaimer',
        usage: TokenUsage(inputTokens: 100, outputTokens: 50),
      );

      final updated = state.copyWith(response: response);

      expect(updated.hasResponse, true);
      expect(updated.response?.surveyId, 'survey-123');
    });

    test('copyWith clears error when set to null', () {
      const state = AiReportState(error: 'Previous error');
      final updated = state.copyWith();

      expect(updated.error, isNull);
    });
  });

  group('AiRecommendationsState', () {
    test('initial state has correct defaults', () {
      const state = AiRecommendationsState();

      expect(state.response, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasResponse, false);
    });

    test('copyWith updates all fields correctly', () {
      const state = AiRecommendationsState();
      const response = AiRecommendationsResponse(
        surveyId: 'survey-123',
        promptVersion: '1.0.0',
        recommendations: [
          AiRecommendation(
            issueId: 'issue-1',
            priority: 'immediate',
            action: 'Contact specialist',
            reasoning: 'Safety concern',
            urgencyExplanation: 'Urgent',
          ),
        ],
        fromCache: false,
        disclaimer: 'Disclaimer',
        usage: TokenUsage(inputTokens: 200, outputTokens: 100),
      );

      final updated = state.copyWith(
        response: response,
        isLoading: false,
      );

      expect(updated.hasResponse, true);
      expect(updated.response?.recommendations.length, 1);
    });
  });

  group('AiRiskSummaryState', () {
    test('initial state has correct defaults', () {
      const state = AiRiskSummaryState();

      expect(state.response, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasResponse, false);
    });

    test('copyWith preserves existing response when not updating', () {
      const response = AiRiskSummaryResponse(
        surveyId: 'survey-123',
        promptVersion: '1.0.0',
        overallRiskLevel: 'medium',
        summary: 'Summary',
        keyRisks: [],
        keyPositives: [],
        fromCache: false,
        disclaimer: 'Disclaimer',
        usage: TokenUsage(inputTokens: 150, outputTokens: 75),
      );

      const state = AiRiskSummaryState(response: response);
      final updated = state.copyWith(isLoading: false);

      expect(updated.response, response);
    });
  });

  group('AiConsistencyState', () {
    test('initial state has correct defaults', () {
      const state = AiConsistencyState();

      expect(state.response, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasResponse, false);
    });

    test('copyWith updates error correctly', () {
      const state = AiConsistencyState();
      final updated = state.copyWith(error: 'Network error');

      expect(updated.error, 'Network error');
      expect(updated.hasResponse, false);
    });
  });

  group('AiPhotoTagsState', () {
    test('initial state has correct defaults', () {
      const state = AiPhotoTagsState();

      expect(state.response, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasResponse, false);
    });

    test('copyWith updates response correctly', () {
      const state = AiPhotoTagsState();
      const response = AiPhotoTagsResponse(
        surveyId: 'survey-123',
        photoId: 'photo-456',
        promptVersion: '1.0.0',
        tags: [
          PhotoTag(label: 'roof', confidence: 0.95),
          PhotoTag(label: 'damage', confidence: 0.88),
        ],
        suggestedSection: 'roof_section',
        description: 'Photo shows roof damage',
        fromCache: false,
        disclaimer: 'Disclaimer',
        usage: TokenUsage(inputTokens: 300, outputTokens: 50),
      );

      final updated = state.copyWith(response: response);

      expect(updated.hasResponse, true);
      expect(updated.response?.tags.length, 2);
      expect(updated.response?.highConfidenceTags.length, 2);
    });

    test('loading state transition works correctly', () {
      const initial = AiPhotoTagsState();
      final loading = initial.copyWith(isLoading: true);
      const response = AiPhotoTagsResponse(
        surveyId: 'survey-123',
        photoId: 'photo-456',
        promptVersion: '1.0.0',
        tags: [],
        suggestedSection: '',
        description: '',
        fromCache: false,
        disclaimer: '',
        usage: TokenUsage(inputTokens: 0, outputTokens: 0),
      );
      final completed = loading.copyWith(
        response: response,
        isLoading: false,
      );

      expect(initial.isLoading, false);
      expect(loading.isLoading, true);
      expect(completed.isLoading, false);
      expect(completed.hasResponse, true);
    });

    test('error state transition works correctly', () {
      const initial = AiPhotoTagsState();
      final loading = initial.copyWith(isLoading: true);
      final error = loading.copyWith(
        isLoading: false,
        error: 'API quota exceeded',
      );

      expect(error.isLoading, false);
      expect(error.error, 'API quota exceeded');
      expect(error.hasResponse, false);
    });
  });

  group('State equality', () {
    test('AiReportState with same values are equal conceptually', () {
      const state1 = AiReportState(isLoading: true);
      const state2 = AiReportState(isLoading: true);

      // Both have same loading state
      expect(state1.isLoading, state2.isLoading);
      expect(state1.error, state2.error);
      expect(state1.hasResponse, state2.hasResponse);
    });

    test('AiPhotoTagsState with different responses are different', () {
      const response1 = AiPhotoTagsResponse(
        surveyId: 'survey-1',
        photoId: 'photo-1',
        promptVersion: '1.0.0',
        tags: [],
        suggestedSection: '',
        description: '',
        fromCache: false,
        disclaimer: '',
        usage: TokenUsage(inputTokens: 0, outputTokens: 0),
      );

      const response2 = AiPhotoTagsResponse(
        surveyId: 'survey-2',
        photoId: 'photo-2',
        promptVersion: '1.0.0',
        tags: [],
        suggestedSection: '',
        description: '',
        fromCache: false,
        disclaimer: '',
        usage: TokenUsage(inputTokens: 0, outputTokens: 0),
      );

      const state1 = AiPhotoTagsState(response: response1);
      const state2 = AiPhotoTagsState(response: response2);

      expect(state1.response?.surveyId, 'survey-1');
      expect(state2.response?.surveyId, 'survey-2');
    });
  });
}
