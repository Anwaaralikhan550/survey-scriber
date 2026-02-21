import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/timeline_event.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';
import '../../data/repositories/survey_timeline_repository_impl.dart';
import '../../domain/repositories/survey_timeline_repository.dart';

/// State for the survey timeline
class SurveyTimelineState {
  const SurveyTimelineState({
    this.events = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<TimelineEvent> events;
  final bool isLoading;
  final String? errorMessage;

  /// Whether the timeline has an error
  bool get hasError => errorMessage != null;

  /// Whether the timeline is empty (no events)
  bool get isEmpty => !isLoading && !hasError && events.isEmpty;

  /// Whether the timeline has events to display
  bool get hasEvents => !isLoading && !hasError && events.isNotEmpty;

  /// Number of events in the timeline
  int get eventCount => events.length;

  SurveyTimelineState copyWith({
    List<TimelineEvent>? events,
    bool? isLoading,
    String? errorMessage,
  }) =>
      SurveyTimelineState(
        events: events ?? this.events,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

/// StateNotifier for managing survey timeline state
class SurveyTimelineNotifier extends StateNotifier<SurveyTimelineState> {
  SurveyTimelineNotifier(this._repository, this._surveyId)
      : super(const SurveyTimelineState()) {
    loadTimeline();
  }

  final SurveyTimelineRepository _repository;
  final String _surveyId;

  /// Load timeline events for the survey
  Future<void> loadTimeline() async {
    state = state.copyWith(isLoading: true);

    try {
      final events = await _repository.getTimelineEvents(_surveyId);

      state = state.copyWith(
        isLoading: false,
        events: events,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load activity timeline',
      );
    }
  }

  /// Refresh the timeline
  Future<void> refresh() async {
    await loadTimeline();
  }
}

/// Provider for the timeline repository
final surveyTimelineRepositoryProvider =
    Provider.autoDispose.family<SurveyTimelineRepository, String>(
  (ref, surveyId) {
    final surveyRepository = ref.watch(localSurveyRepositoryProvider);
    return SurveyTimelineRepositoryImpl(surveyRepository: surveyRepository);
  },
);

/// Provider for SurveyTimelineNotifier
final surveyTimelineProvider = StateNotifierProvider.autoDispose
    .family<SurveyTimelineNotifier, SurveyTimelineState, String>(
  (ref, surveyId) {
    final repository = ref.watch(surveyTimelineRepositoryProvider(surveyId));
    return SurveyTimelineNotifier(repository, surveyId);
  },
);
