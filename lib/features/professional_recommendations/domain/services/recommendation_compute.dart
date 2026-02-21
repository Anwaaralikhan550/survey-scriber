import '../../../property_inspection/domain/models/inspection_models.dart';
import '../models/professional_recommendation.dart';
import 'recommendation_engine.dart';

/// Input data class for the background isolate.
///
/// All fields are plain data objects that can be passed across isolate
/// boundaries without serialization issues.
class RecommendationEngineInput {
  const RecommendationEngineInput({
    required this.surveyId,
    required this.tree,
    required this.allAnswers,
    required this.isValuation,
  });

  final String surveyId;
  final InspectionTreePayload tree;
  final Map<String, Map<String, String>> allAnswers;
  final bool isValuation;
}

/// Top-level function for `compute()` — must be a top-level or static
/// function (not a closure or instance method) for Dart isolate support.
ProfessionalRecommendationsResult runRecommendationEngine(
  RecommendationEngineInput input,
) {
  return RecommendationEngine.analyze(
    surveyId: input.surveyId,
    tree: input.tree,
    allAnswers: input.allAnswers,
    isValuation: input.isValuation,
  );
}
