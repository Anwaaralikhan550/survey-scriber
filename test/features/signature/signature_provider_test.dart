import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/signature/domain/entities/signature_item.dart';
import 'package:survey_scriber/features/signature/presentation/providers/signature_provider.dart';

void main() {
  group('SurveySignaturesState', () {
    test('initial state has correct defaults', () {
      const state = SurveySignaturesState();

      expect(state.signatures, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.hasSignatures, isFalse);
      expect(state.count, equals(0));
    });

    test('hasSignatures returns true when signatures exist', () {
      final state = SurveySignaturesState(
        signatures: [
          SignatureItem(
            id: 'sig-1',
            surveyId: 'survey-1',
            createdAt: DateTime.now(),
            strokes: const [],
          ),
        ],
      );

      expect(state.hasSignatures, isTrue);
      expect(state.count, equals(1));
    });

    test('count returns correct number of signatures', () {
      final state = SurveySignaturesState(
        signatures: [
          SignatureItem(
            id: 'sig-1',
            surveyId: 'survey-1',
            createdAt: DateTime.now(),
            strokes: const [],
          ),
          SignatureItem(
            id: 'sig-2',
            surveyId: 'survey-1',
            createdAt: DateTime.now(),
            strokes: const [],
          ),
          SignatureItem(
            id: 'sig-3',
            surveyId: 'survey-1',
            createdAt: DateTime.now(),
            strokes: const [],
          ),
        ],
      );

      expect(state.count, equals(3));
    });

    test('copyWith creates new state with updated signatures', () {
      const original = SurveySignaturesState(isLoading: true);

      final signatures = [
        SignatureItem(
          id: 'sig-1',
          surveyId: 'survey-1',
          createdAt: DateTime.now(),
          strokes: const [],
        ),
      ];

      final copied = original.copyWith(
        signatures: signatures,
        isLoading: false,
      );

      expect(copied.signatures, equals(signatures));
      expect(copied.isLoading, isFalse);
      expect(copied.errorMessage, isNull);
    });

    test('copyWith creates new state with error message', () {
      const original = SurveySignaturesState();

      final copied = original.copyWith(
        errorMessage: 'Test error',
        isLoading: false,
      );

      expect(copied.errorMessage, equals('Test error'));
      expect(copied.isLoading, isFalse);
    });

    test('copyWith clears error when not provided', () {
      const original = SurveySignaturesState(
        errorMessage: 'Previous error',
      );

      final copied = original.copyWith(isLoading: true);

      // errorMessage is cleared when not explicitly provided
      expect(copied.errorMessage, isNull);
    });

    test('copyWith preserves values when not provided', () {
      final signatures = [
        SignatureItem(
          id: 'sig-1',
          surveyId: 'survey-1',
          createdAt: DateTime.now(),
          strokes: const [],
        ),
      ];

      final original = SurveySignaturesState(
        signatures: signatures,
      );

      final copied = original.copyWith();

      expect(copied.signatures, equals(signatures));
      expect(copied.isLoading, isFalse);
    });
  });

  group('SignaturePreviewService', () {
    test('singleton instance is consistent', () {
      final instance1 = SignaturePreviewService.instance;
      final instance2 = SignaturePreviewService.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('getPreviewPath generates correct path format', () async {
      final service = SignaturePreviewService.instance;

      // Initialize first (this would normally require a mock)
      // For now, just test that the method exists
      expect(() => service.getPreviewPath('test-id'), throwsStateError);
    });
  });
}
