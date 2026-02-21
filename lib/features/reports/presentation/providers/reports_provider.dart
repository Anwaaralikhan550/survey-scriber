import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../surveys/domain/repositories/survey_repository.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';

class ReportsState {
  const ReportsState({
    this.isLoading = true,
    this.surveys = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Survey> surveys;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  ReportsState copyWith({
    bool? isLoading,
    List<Survey>? surveys,
    String? errorMessage,
  }) =>
      ReportsState(
        isLoading: isLoading ?? this.isLoading,
        surveys: surveys ?? this.surveys,
        errorMessage: errorMessage,
      );
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  ReportsNotifier(this._repository) : super(const ReportsState()) {
    loadReports();
  }

  final SurveyRepository _repository;

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true);

    try {
      final surveys = await _repository.getCompletedSurveys();
      state = state.copyWith(
        isLoading: false,
        surveys: surveys,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load reports',
      );
    }
  }

  Future<void> refresh() async {
    await loadReports();
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final repository = ref.watch(localSurveyRepositoryProvider);
  return ReportsNotifier(repository);
});
