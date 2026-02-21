import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../config/presentation/helpers/config_aware_fields.dart';
import '../../../config/presentation/providers/config_providers.dart';
import '../../domain/repositories/survey_repository.dart';
import 'survey_invalidation.dart';
import 'survey_providers.dart';

class SurveyDetailState {
  const SurveyDetailState({
    this.isLoading = true,
    this.survey,
    this.sections = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final Survey? survey;
  final List<SurveySection> sections;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get hasSurvey => survey != null;

  int get completedSectionsCount =>
      sections.where((s) => s.isCompleted).length;

  double get progressPercent =>
      sections.isNotEmpty ? (completedSectionsCount / sections.length) * 100 : 0;

  SurveyDetailState copyWith({
    bool? isLoading,
    Survey? survey,
    List<SurveySection>? sections,
    String? errorMessage,
  }) =>
      SurveyDetailState(
        isLoading: isLoading ?? this.isLoading,
        survey: survey ?? this.survey,
        sections: sections ?? this.sections,
        errorMessage: errorMessage,
      );
}

class SurveyDetailNotifier extends StateNotifier<SurveyDetailState> {
  SurveyDetailNotifier(this._repository, this._surveyId, this._ref)
      : super(const SurveyDetailState()) {
    loadSurvey();
  }

  final SurveyRepository _repository;
  final String _surveyId;
  final Ref _ref;

  Future<void> loadSurvey() async {
    if (!mounted) return;
    // Only show full loading spinner on initial load (no data yet).
    // Subsequent reloads (from sync pull invalidation, etc.) silently
    // refresh in the background to avoid scroll position resets.
    final isInitialLoad = !state.hasSurvey;
    if (isInitialLoad) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final survey = await _repository.getSurveyById(_surveyId);
      if (!mounted) return;
      if (survey == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Survey not found',
        );
        return;
      }

      var sections = await _repository.getSectionsForSurvey(_surveyId);
      if (!mounted) return;

      // Deduplicate sections: sync pull can create duplicates when the server
      // assigns new IDs to sections that already exist locally.  Keep the
      // first occurrence per (sectionType, order) pair — the list is already
      // sorted by order from the DAO, so this preserves the intended ordering.
      // Uses sectionType.name instead of title because titles can vary slightly.
      final seen = <String>{};
      sections = sections.where((s) {
        final key = '${s.sectionType.name}::${s.order}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();

      // Always exclude legacy section types that have been superseded:
      //   exterior → externalItems (External Inspection)
      //   interior → internalItems (Internal Inspection)
      // This must run unconditionally (even when config isn't loaded) so
      // that surveys created before the legacy exclusion don't show them.
      const legacySectionTypes = {SectionType.exterior, SectionType.interior};
      sections = sections
          .where((s) => !legacySectionTypes.contains(s.sectionType))
          .toList();

      // For valuation surveys, hide inspection-only section types that were
      // incorrectly added when the backend classified them as SHARED.
      // These have valuation equivalents (about-valuation, property-summary, etc.).
      if (survey.type.isValuation) {
        const inspectionOnlySectionTypes = {
          SectionType.aboutProperty,
          SectionType.aboutInspection,
          SectionType.construction,
          SectionType.externalItems,
          SectionType.internalItems,
          SectionType.rooms,
          SectionType.services,
          SectionType.issuesAndRisks,
          SectionType.notes,
        };
        final filtered = sections
            .where((s) => !inspectionOnlySectionTypes.contains(s.sectionType))
            .toList();
        // Safety: only apply if it doesn't empty the list
        if (filtered.isNotEmpty) {
          sections = filtered;
        }
      }

      // Filter displayed sections by active section types for this survey type.
      // Safety: never filter existing sections down to zero — if the config
      // filter would remove everything, skip filtering and show all sections.
      final backendType = survey.type.toBackendString();
      final activeSectionTypes =
          _ref.read(activeSectionTypesForSurveyProvider(backendType));
      if (activeSectionTypes != null && activeSectionTypes.isNotEmpty) {
        final filtered = sections
            .where((s) => activeSectionTypes.contains(s.sectionType.apiSectionType))
            .toList();
        if (filtered.isNotEmpty) {
          sections = filtered;
        }
      }

      state = state.copyWith(
        isLoading: false,
        survey: survey,
        sections: sections,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load survey: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadSurvey();
  }

  Future<void> updateStatus(SurveyStatus status) async {
    if (state.survey == null) return;

    try {
      await _repository.updateSurveyStatus(_surveyId, status);
      if (!mounted) return;

      // Invalidate all dependent providers for reactive UI updates
      SurveyInvalidation.afterSurveyMutation(
        _ref,
        _surveyId,
        invalidateSurveyDetail: false,
      );

      await loadSurvey();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: 'Failed to update status: $e',
      );
    }
  }

  Future<void> deleteSurvey() async {
    try {
      await _repository.deleteSurvey(_surveyId);
      if (!mounted) return;

      // Invalidate list providers for reactive UI updates
      SurveyInvalidation.afterBulkMutation(_ref);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: 'Failed to delete survey: $e',
      );
    }
  }
}

/// Provider family for survey details by ID
final surveyDetailProvider = StateNotifierProvider.autoDispose
    .family<SurveyDetailNotifier, SurveyDetailState, String>(
  (ref, surveyId) {
    final repository = ref.watch(localSurveyRepositoryProvider);
    return SurveyDetailNotifier(repository, surveyId, ref);
  },
);
