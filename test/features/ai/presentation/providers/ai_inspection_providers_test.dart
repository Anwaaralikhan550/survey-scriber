import 'package:flutter_test/flutter_test.dart';

import 'package:survey_scriber/features/ai/domain/entities/ai_response.dart';
import 'package:survey_scriber/features/ai/presentation/providers/ai_inspection_providers.dart';

void main() {
  group('AiReportState', () {
    test('defaults are correct', () {
      const state = AiReportState();
      expect(state.isLoading, isFalse);
      expect(state.response, isNull);
      expect(state.error, isNull);
      expect(state.redactionMapping, isEmpty);
      expect(state.hasResponse, isFalse);
      expect(state.hasError, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = AiReportState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.response, isNull);
    });

    test('copyWith clears error when set to null', () {
      const state = AiReportState(error: 'Something failed');
      expect(state.hasError, isTrue);

      // copyWith with error: null clears it
      final updated = state.copyWith(isLoading: true);
      expect(updated.error, isNull);
      expect(updated.hasError, isFalse);
    });

    test('copyWith preserves response', () {
      const response = AiReportResponse(
        surveyId: 'test-1',
        promptVersion: 'v1',
        sections: [],
        executiveSummary: 'Summary',
        fromCache: false,
        disclaimer: 'AI generated',
        usage: TokenUsage(inputTokens: 100, outputTokens: 200),
      );
      const state = AiReportState(response: response);
      final updated = state.copyWith(isLoading: true);

      expect(updated.response, isNotNull);
      expect(updated.response!.executiveSummary, 'Summary');
    });
  });

  group('AiConsistencyState', () {
    test('defaults are correct', () {
      const state = AiConsistencyState();
      expect(state.isLoading, isFalse);
      expect(state.response, isNull);
      expect(state.error, isNull);
      expect(state.hasResponse, isFalse);
      expect(state.hasError, isFalse);
    });

    test('copyWith updates fields correctly', () {
      const state = AiConsistencyState();
      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);

      final withError = loading.copyWith(error: 'Timeout', isLoading: false);
      expect(withError.hasError, isTrue);
      expect(withError.isLoading, isFalse);
    });
  });

  group('AiRiskState', () {
    test('defaults are correct', () {
      const state = AiRiskState();
      expect(state.isLoading, isFalse);
      expect(state.response, isNull);
      expect(state.error, isNull);
      expect(state.hasResponse, isFalse);
      expect(state.hasError, isFalse);
    });

    test('copyWith updates redactionMapping', () {
      const state = AiRiskState();
      final updated = state.copyWith(
        redactionMapping: {'[EMAIL_0]': 'test@x.com'},
      );

      expect(updated.redactionMapping, hasLength(1));
      expect(updated.redactionMapping['[EMAIL_0]'], 'test@x.com');
    });
  });

  group('AiRecommendationsState', () {
    test('defaults are correct', () {
      const state = AiRecommendationsState();
      expect(state.isLoading, isFalse);
      expect(state.response, isNull);
      expect(state.error, isNull);
      expect(state.hasResponse, isFalse);
      expect(state.hasError, isFalse);
    });

    test('copyWith preserves other fields when updating one', () {
      const state = AiRecommendationsState(
        isLoading: true,
        redactionMapping: {'[NAME]': 'John'},
      );
      final updated = state.copyWith(error: 'Failed');

      expect(updated.isLoading, isTrue);
      expect(updated.hasError, isTrue);
      expect(updated.redactionMapping, hasLength(1));
    });
  });
}
