import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../data/repositories/comparison_repository.dart';
import '../../domain/entities/comparison_result.dart';

/// Provider for the comparison repository
final comparisonRepositoryProvider = Provider<ComparisonRepository>((ref) => ComparisonRepository(
    surveysDao: ref.watch(surveysDaoProvider),
    sectionsDao: ref.watch(surveySectionsDaoProvider),
    answersDao: ref.watch(surveyAnswersDaoProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    signatureDao: ref.watch(signatureDaoProvider),
  ),);

/// View mode for the comparison page
enum ComparisonViewMode {
  current,
  previous,
  compare,
}

/// State for the comparison view
class ComparisonState {
  const ComparisonState({
    this.isLoading = false,
    this.viewMode = ComparisonViewMode.compare,
    this.result,
    this.parentSurvey,
    this.currentSurvey,
    this.inspectionHistory = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final ComparisonViewMode viewMode;
  final ComparisonResult? result;
  final Survey? parentSurvey;
  final Survey? currentSurvey;
  final List<Survey> inspectionHistory;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasComparison => result != null;
  bool get isReinspection => parentSurvey != null;

  ComparisonState copyWith({
    bool? isLoading,
    ComparisonViewMode? viewMode,
    ComparisonResult? result,
    Survey? parentSurvey,
    Survey? currentSurvey,
    List<Survey>? inspectionHistory,
    String? errorMessage,
  }) => ComparisonState(
      isLoading: isLoading ?? this.isLoading,
      viewMode: viewMode ?? this.viewMode,
      result: result ?? this.result,
      parentSurvey: parentSurvey ?? this.parentSurvey,
      currentSurvey: currentSurvey ?? this.currentSurvey,
      inspectionHistory: inspectionHistory ?? this.inspectionHistory,
      errorMessage: errorMessage,
    );
}

/// Notifier for managing comparison state
class ComparisonNotifier extends StateNotifier<ComparisonState> {
  ComparisonNotifier({
    required this.repository,
    required this.surveyId,
  }) : super(const ComparisonState()) {
    _initialize();
  }

  final ComparisonRepository repository;
  final String surveyId;

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load the current survey info
      final history = await repository.getInspectionHistory(surveyId);

      if (history.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Survey not found',
        );
        return;
      }

      // Find current survey in history
      final currentSurvey = history.firstWhere(
        (s) => s.id == surveyId,
        orElse: () => history.last,
      );

      // Find parent survey (if this is a re-inspection)
      Survey? parentSurvey;
      if (currentSurvey.parentSurveyId != null) {
        parentSurvey = history.firstWhere(
          (s) => s.id == currentSurvey.parentSurveyId,
          orElse: () => history.first,
        );
      }

      state = state.copyWith(
        isLoading: false,
        currentSurvey: currentSurvey,
        parentSurvey: parentSurvey,
        inspectionHistory: history,
      );

      // If this is a re-inspection, load comparison automatically
      if (parentSurvey != null) {
        await loadComparison(parentSurvey.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load survey: $e',
      );
    }
  }

  /// Load comparison between current and specified previous survey
  Future<void> loadComparison(String previousSurveyId) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await repository.compareSurveys(
        previousSurveyId: previousSurveyId,
        currentSurveyId: surveyId,
      );

      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load comparison data',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        result: result,
        viewMode: ComparisonViewMode.compare,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to compare surveys: $e',
      );
    }
  }

  /// Change the view mode
  void setViewMode(ComparisonViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith();
  }

  /// Refresh comparison data
  Future<void> refresh() async {
    if (state.parentSurvey != null) {
      await loadComparison(state.parentSurvey!.id);
    } else {
      await _initialize();
    }
  }
}

/// Provider family for comparison state by survey ID
final comparisonProvider = StateNotifierProvider.autoDispose
    .family<ComparisonNotifier, ComparisonState, String>((ref, surveyId) => ComparisonNotifier(
    repository: ref.watch(comparisonRepositoryProvider),
    surveyId: surveyId,
  ),);

/// Provider for checking if a survey has re-inspections
final hasReinspectionsProvider =
    FutureProvider.family<bool, String>((ref, surveyId) async {
  final repository = ref.watch(comparisonRepositoryProvider);
  return repository.hasReinspections(surveyId);
});

/// Provider for getting the parent survey
final parentSurveyProvider =
    FutureProvider.family<Survey?, String>((ref, surveyId) async {
  final repository = ref.watch(comparisonRepositoryProvider);
  return repository.getParentSurvey(surveyId);
});

/// Provider for getting inspection history
final inspectionHistoryProvider =
    FutureProvider.family<List<Survey>, String>((ref, surveyId) async {
  final repository = ref.watch(comparisonRepositoryProvider);
  return repository.getInspectionHistory(surveyId);
});
