import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/domain/entities/ai_response.dart';
import 'package:survey_scriber/features/ai/domain/repositories/ai_repository.dart';
import 'package:survey_scriber/features/ai/presentation/providers/ai_providers.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_action_button.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_result_sheet.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_summary_section.dart';

void main() {
  group('AiSummaryCard', () {
    Widget buildTestWidget({
      required AsyncValue<AiStatus> statusOverride,
      AiReportState? reportStateOverride,
    }) => ProviderScope(
        overrides: [
          aiStatusProvider.overrideWith((ref) => statusOverride),
          if (reportStateOverride != null)
            aiReportNotifierProvider.overrideWith(
              (ref) => _MockAiReportNotifier(reportStateOverride),
            ),
        ],
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: AiSummaryCard(
                title: 'Executive Summary',
                surveyId: 'survey-123',
                propertyAddress: '123 Test Street',
                propertyType: 'detached_house',
              ),
            ),
          ),
        ),
      );

    group('When AI status is loading', () {
      testWidgets('shows skeleton button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.loading(),
        ),);

        expect(find.byType(AiButtonSkeleton), findsOneWidget);
        expect(find.byType(AiActionButton), findsNothing);
      });
    });

    group('When AI status is available', () {
      testWidgets('shows enabled Generate AI Summary button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
        ),);

        expect(find.byType(AiActionButton), findsOneWidget);
        expect(find.text('Generate AI Summary'), findsOneWidget);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('shows card with proper title and description', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
        ),);

        expect(find.text('Executive Summary'), findsOneWidget);
        expect(find.text('Powered by AI'), findsOneWidget);
        expect(
          find.textContaining('Generate an AI-assisted summary'),
          findsOneWidget,
        );
      });
    });

    group('When AI status is unavailable', () {
      testWidgets('shows AiUnavailableMessage', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(
            AiStatus(available: false, message: 'Service unavailable'),
          ),
        ),);

        expect(find.byType(AiUnavailableMessage), findsOneWidget);
        expect(find.byType(AiActionButton), findsNothing);
      });
    });

    group('When AI status has error', () {
      testWidgets('shows AiUnavailableMessage', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: AsyncValue.error('Connection failed', StackTrace.current),
        ),);

        expect(find.byType(AiUnavailableMessage), findsOneWidget);
      });
    });

    group('When report generation is loading', () {
      testWidgets('shows loading state on button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
          reportStateOverride: const AiReportState(isLoading: true),
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.isLoading, isTrue);
        expect(find.text('Generating...'), findsOneWidget);
      });
    });

    group('When report generation has error', () {
      testWidgets('shows error message below button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
          reportStateOverride: const AiReportState(
            error: 'API quota exceeded',
          ),
        ),);

        // Error is formatted by _formatError: 'quota' → 'AI usage quota exceeded...'
        expect(find.text('AI usage quota exceeded. Please try again later.'), findsOneWidget);
        // Retry button is shown alongside the error
        expect(find.text('Retry'), findsOneWidget);
        // Error icon is shown
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });
  });

  group('AiUnavailableMessage', () {
    testWidgets('renders default message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiUnavailableMessage(),
          ),
        ),
      );

      expect(
        find.text('AI features are temporarily unavailable. Please try again later.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('renders custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: AiUnavailableMessage(message: 'Custom unavailable message'),
          ),
        ),
      );

      expect(find.text('Custom unavailable message'), findsOneWidget);
    });
  });
}

class _MockAiReportNotifier extends AiReportNotifier {
  _MockAiReportNotifier(this._initialState) : super(_MockAiRepository());

  final AiReportState _initialState;

  @override
  AiReportState get state => _initialState;
}

class _MockAiRepository implements AiRepository {
  @override
  Future<AiStatus> getStatus() async => const AiStatus(available: true);

  @override
  Future<AiReportResponse> generateReport(GenerateReportRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<AiRecommendationsResponse> generateRecommendations(
    GenerateRecommendationsRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AiRiskSummaryResponse> generateRiskSummary(
    GenerateRiskSummaryRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AiConsistencyResponse> checkConsistency(
    ConsistencyCheckRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AiPhotoTagsResponse> generatePhotoTags(
    PhotoTagsRequest request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AiProfessionalAnalysisResponse> analyzeProfessionally(
    ProfessionalAnalysisRequest request,
  ) async {
    throw UnimplementedError();
  }
}
