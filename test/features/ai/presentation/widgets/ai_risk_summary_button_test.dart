import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/ai/domain/entities/ai_response.dart';
import 'package:survey_scriber/features/ai/domain/repositories/ai_repository.dart';
import 'package:survey_scriber/features/ai/presentation/providers/ai_providers.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_action_button.dart';
import 'package:survey_scriber/features/ai/presentation/widgets/ai_risk_summary_button.dart';

void main() {
  group('AiRiskSummaryButton', () {
    Widget buildTestWidget({
      required AsyncValue<AiStatus> statusOverride,
      AiRiskSummaryState? riskStateOverride,
      bool isCompact = false,
    }) => ProviderScope(
        overrides: [
          aiStatusProvider.overrideWith((ref) => statusOverride),
          if (riskStateOverride != null)
            aiRiskSummaryNotifierProvider.overrideWith(
              (ref) => _MockAiRiskSummaryNotifier(riskStateOverride),
            ),
        ],
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: AiRiskSummaryButton(
              surveyId: 'survey-123',
              propertyAddress: '123 Test Street',
              propertyType: 'detached_house',
              sections: const [
                SectionAnswersInput(
                  sectionId: 's1',
                  sectionType: 'roof',
                  title: 'Roof',
                  answers: {'condition': 'fair'},
                ),
              ],
              issues: const [
                IssueInput(id: 'i1', title: 'Cracked tiles'),
              ],
              isCompact: isCompact,
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

      testWidgets('shows checking availability tooltip', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.loading(),
        ),);

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'Checking AI availability...');
      });
    });

    group('When AI status is available', () {
      testWidgets('shows enabled AI Risk Summary button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
        ),);

        expect(find.byType(AiActionButton), findsOneWidget);
        expect(find.text('AI Risk Summary'), findsOneWidget);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.onPressed, isNotNull);
        expect(button.icon, Icons.shield_outlined);
        expect(button.isOutlined, isTrue);
      });

      testWidgets('shows tooltip with action description', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
        ),);

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'Generate AI risk summary');
      });
    });

    group('When AI status is unavailable', () {
      testWidgets('shows disabled button with unavailable tooltip', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(
            AiStatus(available: false, message: 'Service unavailable'),
          ),
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.onPressed, isNull);

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'AI service unavailable');
      });
    });

    group('When AI status has error', () {
      testWidgets('shows disabled button with unavailable tooltip', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: AsyncValue.error('Connection failed', StackTrace.current),
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.onPressed, isNull);

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'AI service unavailable');
      });
    });

    group('When generation is loading', () {
      testWidgets('shows loading state on button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
          riskStateOverride: const AiRiskSummaryState(isLoading: true),
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.isLoading, isTrue);
        expect(find.text('Generating...'), findsOneWidget);
      });
    });

    group('Compact mode', () {
      testWidgets('renders compact button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
          isCompact: true,
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.isCompact, isTrue);
      });

      testWidgets('shows compact skeleton when loading status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.loading(),
          isCompact: true,
        ),);

        final skeleton = tester.widget<AiButtonSkeleton>(find.byType(AiButtonSkeleton));
        expect(skeleton.isCompact, isTrue);
      });
    });
  });

  group('AiRecommendationsButton', () {
    Widget buildTestWidget({
      required AsyncValue<AiStatus> statusOverride,
      AiRecommendationsState? recStateOverride,
      List<IssueInput> issues = const [],
      List<SectionAnswersInput> sections = const [],
      bool isCompact = false,
    }) => ProviderScope(
        overrides: [
          aiStatusProvider.overrideWith((ref) => statusOverride),
          if (recStateOverride != null)
            aiRecommendationsNotifierProvider.overrideWith(
              (ref) => _MockAiRecommendationsNotifier(recStateOverride),
            ),
        ],
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: AiRecommendationsButton(
              surveyId: 'survey-123',
              propertyAddress: '123 Test Street',
              propertyType: 'detached_house',
              issues: issues,
              sections: sections,
              isCompact: isCompact,
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
      });
    });

    group('When AI status is available', () {
      group('and has issues', () {
        testWidgets('shows enabled AI Recommendations button', (tester) async {
          await tester.pumpWidget(buildTestWidget(
            statusOverride: const AsyncValue.data(AiStatus(available: true)),
            issues: const [IssueInput(id: 'i1', title: 'Test issue')],
          ),);

          expect(find.byType(AiActionButton), findsOneWidget);
          expect(find.text('AI Recommendations'), findsOneWidget);

          final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
          expect(button.onPressed, isNotNull);
          expect(button.icon, Icons.lightbulb_outline);
        });

        testWidgets('shows tooltip with action description', (tester) async {
          await tester.pumpWidget(buildTestWidget(
            statusOverride: const AsyncValue.data(AiStatus(available: true)),
            issues: const [IssueInput(id: 'i1', title: 'Test issue')],
          ),);

          final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
          expect(tooltip.message, 'Generate AI recommendations');
        });
      });

      group('and has no issues or sections', () {
        testWidgets('shows disabled button with no data tooltip', (tester) async {
          await tester.pumpWidget(buildTestWidget(
            statusOverride: const AsyncValue.data(AiStatus(available: true)),
          ),);

          final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
          expect(button.onPressed, isNull);

          final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
          expect(tooltip.message, 'Add inspection data to get recommendations');
        });
      });

      group('and has no issues but has sections', () {
        testWidgets('shows enabled button', (tester) async {
          await tester.pumpWidget(buildTestWidget(
            statusOverride: const AsyncValue.data(AiStatus(available: true)),
            sections: const [
              SectionAnswersInput(
                sectionId: 's1',
                sectionType: 'roof',
                title: 'Roof',
                answers: {'condition': 'fair'},
              ),
            ],
          ),);

          final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
          expect(button.onPressed, isNotNull);
        });
      });
    });

    group('When AI status is unavailable', () {
      testWidgets('shows disabled button even with issues', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(
            AiStatus(available: false, message: 'Service unavailable'),
          ),
          issues: const [IssueInput(id: 'i1', title: 'Test issue')],
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.onPressed, isNull);

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, 'AI service unavailable');
      });
    });

    group('When generation is loading', () {
      testWidgets('shows loading state on button', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusOverride: const AsyncValue.data(AiStatus(available: true)),
          recStateOverride: const AiRecommendationsState(isLoading: true),
          issues: const [IssueInput(id: 'i1', title: 'Test issue')],
        ),);

        final button = tester.widget<AiActionButton>(find.byType(AiActionButton));
        expect(button.isLoading, isTrue);
      });
    });
  });
}

class _MockAiRiskSummaryNotifier extends AiRiskSummaryNotifier {
  _MockAiRiskSummaryNotifier(this._initialState) : super(_MockAiRepository());

  final AiRiskSummaryState _initialState;

  @override
  AiRiskSummaryState get state => _initialState;
}

class _MockAiRecommendationsNotifier extends AiRecommendationsNotifier {
  _MockAiRecommendationsNotifier(this._initialState) : super(_MockAiRepository());

  final AiRecommendationsState _initialState;

  @override
  AiRecommendationsState get state => _initialState;
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
