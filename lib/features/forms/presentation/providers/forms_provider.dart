import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/presentation/widgets/filter_sort_bottom_sheet.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../surveys/domain/repositories/survey_repository.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';

enum FormsFilter {
  all,
  draft,
  inProgress,
  paused,
}

class FormsState {
  const FormsState({
    this.isLoading = true,
    this.surveys = const [],
    this.filter = FormsFilter.all,
    this.sortOption = SortOption.dateNewest,
    this.advancedFilters = FilterCriteria.empty,
    this.selectedSurveyIds = const {},
    this.errorMessage,
  });

  final bool isLoading;
  final List<Survey> surveys;
  final FormsFilter filter;
  final SortOption sortOption;
  final FilterCriteria advancedFilters;
  final Set<String> selectedSurveyIds;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasActiveAdvancedFilters => advancedFilters.hasActiveFilters;
  bool get isSelectionMode => selectedSurveyIds.isNotEmpty;
  int get selectedCount => selectedSurveyIds.length;

  List<Survey> get selectedSurveys =>
      surveys.where((s) => selectedSurveyIds.contains(s.id)).toList();

  List<Survey> get filteredSurveys {
    var result = List<Survey>.from(surveys);

    // Apply basic filter
    result = switch (filter) {
      FormsFilter.all => result,
      FormsFilter.draft =>
        result.where((s) => s.status == SurveyStatus.draft).toList(),
      FormsFilter.inProgress =>
        result.where((s) => s.status == SurveyStatus.inProgress).toList(),
      FormsFilter.paused =>
        result.where((s) => s.status == SurveyStatus.paused).toList(),
    };

    // Apply advanced filters
    if (advancedFilters.surveyTypes.isNotEmpty) {
      result = result
          .where((s) => advancedFilters.surveyTypes.contains(s.type.name))
          .toList();
    }

    if (advancedFilters.statuses.isNotEmpty) {
      result = result
          .where((s) => advancedFilters.statuses.contains(s.status.name))
          .toList();
    }

    if (advancedFilters.dateRange != null) {
      result = result.where((s) => s.createdAt.isAfter(advancedFilters.dateRange!.start) &&
            s.createdAt
                .isBefore(advancedFilters.dateRange!.end.add(const Duration(days: 1))),).toList();
    }

    if (advancedFilters.hasPhotos != null) {
      result = result.where((s) => advancedFilters.hasPhotos! ? s.photoCount > 0 : s.photoCount == 0).toList();
    }

    if (advancedFilters.hasNotes != null) {
      result = result.where((s) => advancedFilters.hasNotes! ? s.noteCount > 0 : s.noteCount == 0).toList();
    }

    // Apply sorting
    result.sort((a, b) => switch (sortOption) {
        SortOption.dateNewest => b.createdAt.compareTo(a.createdAt),
        SortOption.dateOldest => a.createdAt.compareTo(b.createdAt),
        SortOption.titleAz => a.title.compareTo(b.title),
        SortOption.titleZa => b.title.compareTo(a.title),
        SortOption.progressHigh => b.progress.compareTo(a.progress),
        SortOption.progressLow => a.progress.compareTo(b.progress),
      },);

    return result;
  }

  /// Get all unique survey types from loaded surveys
  List<String> get availableSurveyTypes =>
      surveys.map((s) => s.type.name).toSet().toList();

  /// Get all unique statuses from loaded surveys
  List<String> get availableStatuses =>
      surveys.map((s) => s.status.name).toSet().toList();

  FormsState copyWith({
    bool? isLoading,
    List<Survey>? surveys,
    FormsFilter? filter,
    SortOption? sortOption,
    FilterCriteria? advancedFilters,
    Set<String>? selectedSurveyIds,
    String? errorMessage,
  }) =>
      FormsState(
        isLoading: isLoading ?? this.isLoading,
        surveys: surveys ?? this.surveys,
        filter: filter ?? this.filter,
        sortOption: sortOption ?? this.sortOption,
        advancedFilters: advancedFilters ?? this.advancedFilters,
        selectedSurveyIds: selectedSurveyIds ?? this.selectedSurveyIds,
        errorMessage: errorMessage,
      );
}

class FormsNotifier extends StateNotifier<FormsState> {
  FormsNotifier(this._repository, this._ref) : super(const FormsState()) {
    loadForms();
  }

  final SurveyRepository _repository;
  final Ref _ref;

  Future<void> loadForms() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final surveys = await _repository.getInProgressSurveys();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        surveys: surveys,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load surveys',
      );
    }
  }

  void setFilter(FormsFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSortOption(SortOption sortOption) {
    state = state.copyWith(sortOption: sortOption);
  }

  void setAdvancedFilters(FilterCriteria filters) {
    state = state.copyWith(advancedFilters: filters);
  }

  void clearAdvancedFilters() {
    state = state.copyWith(advancedFilters: FilterCriteria.empty);
  }

  // Selection methods
  void toggleSelection(String surveyId) {
    final selected = Set<String>.from(state.selectedSurveyIds);
    if (selected.contains(surveyId)) {
      selected.remove(surveyId);
    } else {
      selected.add(surveyId);
    }
    state = state.copyWith(selectedSurveyIds: selected);
  }

  void selectAll() {
    final allIds = state.filteredSurveys.map((s) => s.id).toSet();
    state = state.copyWith(selectedSurveyIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedSurveyIds: {});
  }

  bool isSelected(String surveyId) => state.selectedSurveyIds.contains(surveyId);

  // Bulk actions
  Future<int> deleteSelected() async {
    final selectedIds = state.selectedSurveyIds;
    if (selectedIds.isEmpty) return 0;

    final deletedIds = <String>{};
    for (final id in selectedIds) {
      try {
        await _repository.deleteSurvey(id);
        deletedIds.add(id);
      } catch (_) {
        // Continue deleting remaining surveys on individual failure
      }
    }

    if (deletedIds.isNotEmpty && mounted) {
      final updatedSurveys = state.surveys
          .where((s) => !deletedIds.contains(s.id))
          .toList();
      state = state.copyWith(
        surveys: updatedSurveys,
        selectedSurveyIds: {},
      );

      // Invalidate other dependent providers (dashboard), but NOT formsProvider
      // since we already updated local state above.
      _ref.invalidate(dashboardProvider);
    }

    return deletedIds.length;
  }

  Future<void> changeStatusForSelected(SurveyStatus newStatus) async {
    final selectedIds = state.selectedSurveyIds;
    if (selectedIds.isEmpty) return;

    try {
      final updatedSurveys = state.surveys.map((s) {
        if (selectedIds.contains(s.id)) {
          return s.copyWith(status: newStatus);
        }
        return s;
      }).toList();

      // Update in repository
      for (final id in selectedIds) {
        final survey = state.surveys.firstWhere((s) => s.id == id);
        await _repository.updateSurvey(survey.copyWith(status: newStatus));
      }

      if (!mounted) return;
      state = state.copyWith(
        surveys: updatedSurveys,
        selectedSurveyIds: {},
      );

      // Invalidate dashboard only — local state is already updated above.
      _ref.invalidate(dashboardProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to update surveys');
    }
  }

  Future<void> refresh() async {
    await loadForms();
  }
}

final formsProvider = StateNotifierProvider<FormsNotifier, FormsState>((ref) {
  final repository = ref.watch(localSurveyRepositoryProvider);
  return FormsNotifier(repository, ref);
});
