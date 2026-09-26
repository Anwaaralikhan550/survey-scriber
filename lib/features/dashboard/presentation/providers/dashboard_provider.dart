import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/presentation/widgets/analytics_cards.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../surveys/domain/repositories/survey_repository.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';

/// The dashboard is split into two independent segments per the client's
/// App-Edit brief — Home Surveys and Valuations — and every metric below is
/// computed for the currently selected segment only (never combined).
enum HomeSegment {
  homeSurveys,
  valuations;

  String get label =>
      this == HomeSegment.valuations ? 'Valuations' : 'Home Surveys';

  /// A survey belongs to this segment. Valuations are the valuation type;
  /// Home Surveys covers inspection / re-inspection / other.
  bool matches(Survey s) =>
      this == HomeSegment.valuations ? s.type.isValuation : !s.type.isValuation;
}

/// Status filters used by the metric cards and the "This week" card when they
/// open the jobs list screen.
enum JobFilter {
  all,
  live,
  inProgress,
  completed,
  thisWeek;

  String get title => switch (this) {
        JobFilter.all => 'All',
        JobFilter.live => 'Live Bookings',
        JobFilter.inProgress => 'In Progress',
        JobFilter.completed => 'Completed',
        JobFilter.thisWeek => 'This Week',
      };

  /// Whether a survey matches this status filter.
  bool matches(Survey s) {
    switch (this) {
      // "All" — every survey in the segment, no status restriction (client's
      // App-Edit brief: the Survey Folder "View all" offers All / Live / In
      // Progress / Completed).
      case JobFilter.all:
        return true;
      // "Live bookings" = new instructions not yet started: anything that is
      // neither in progress nor completed (client's definition).
      case JobFilter.live:
        return s.status != SurveyStatus.inProgress &&
            s.status != SurveyStatus.completed;
      case JobFilter.inProgress:
        return s.status == SurveyStatus.inProgress;
      case JobFilter.completed:
        return s.status == SurveyStatus.completed;
      case JobFilter.thisWeek:
        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final updated = s.updatedAt ?? s.createdAt;
        return !updated.isBefore(weekStart);
    }
  }
}

class DashboardStats {
  const DashboardStats({
    required this.live,
    required this.inProgress,
    required this.completed,
  });

  /// "Total" card value — live bookings (new instructions not yet started).
  final int live;
  final int inProgress;
  final int completed;

  static const empty = DashboardStats(live: 0, inProgress: 0, completed: 0);
}

class DashboardState {
  const DashboardState({
    this.isLoading = true,
    this.segment = HomeSegment.homeSurveys,
    this.stats = DashboardStats.empty,
    this.recentSurveys = const [],
    this.analytics = const AnalyticsData(),
    this.totalAllSurveys = 0,
    this.homeSurveysCount = 0,
    this.valuationsCount = 0,
    this.errorMessage,
  });

  final bool isLoading;
  final HomeSegment segment;
  final DashboardStats stats;
  final List<Survey> recentSurveys;
  final AnalyticsData analytics;

  /// Total across BOTH segments — used only for the "restore/empty" gate,
  /// which should not depend on the selected segment.
  final int totalAllSurveys;

  /// Survey Folder card counts — per category, independent of the selected
  /// segment (the folder always shows both).
  final int homeSurveysCount;
  final int valuationsCount;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  DashboardState copyWith({
    bool? isLoading,
    HomeSegment? segment,
    DashboardStats? stats,
    List<Survey>? recentSurveys,
    AnalyticsData? analytics,
    int? totalAllSurveys,
    int? homeSurveysCount,
    int? valuationsCount,
    String? errorMessage,
  }) =>
      DashboardState(
        isLoading: isLoading ?? this.isLoading,
        segment: segment ?? this.segment,
        stats: stats ?? this.stats,
        recentSurveys: recentSurveys ?? this.recentSurveys,
        analytics: analytics ?? this.analytics,
        totalAllSurveys: totalAllSurveys ?? this.totalAllSurveys,
        homeSurveysCount: homeSurveysCount ?? this.homeSurveysCount,
        valuationsCount: valuationsCount ?? this.valuationsCount,
        errorMessage: errorMessage,
      );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._repository) : super(const DashboardState()) {
    loadDashboard();
  }

  final SurveyRepository _repository;

  /// Cached across segment switches so toggling doesn't re-hit the database.
  List<Survey> _allSurveys = const [];

  Future<void> loadDashboard() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      _allSurveys = await _repository.getAllSurveys();
      if (!mounted) return;
      _recompute();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data',
      );
    }
  }

  /// Switch between Home Surveys and Valuations. Recomputes from the cached
  /// survey list — no network/database round-trip.
  void setSegment(HomeSegment segment) {
    if (segment == state.segment) return;
    state = state.copyWith(segment: segment);
    _recompute();
  }

  void _recompute() {
    final segment = state.segment;
    final scoped = _allSurveys.where(segment.matches).toList();

    final stats = DashboardStats(
      live: scoped.where(JobFilter.live.matches).length,
      inProgress: scoped.where(JobFilter.inProgress.matches).length,
      completed: scoped.where(JobFilter.completed.matches).length,
    );

    final recent = [...scoped]..sort((a, b) {
        final ad = a.updatedAt ?? a.createdAt;
        final bd = b.updatedAt ?? b.createdAt;
        return bd.compareTo(ad);
      });

    state = state.copyWith(
      isLoading: false,
      stats: stats,
      recentSurveys: recent.take(5).toList(),
      analytics: _computeAnalytics(scoped),
      totalAllSurveys: _allSurveys.length,
      homeSurveysCount:
          _allSurveys.where(HomeSegment.homeSurveys.matches).length,
      valuationsCount:
          _allSurveys.where(HomeSegment.valuations.matches).length,
    );
  }

  AnalyticsData _computeAnalytics(List<Survey> surveys) {
    final now = DateTime.now();

    // Weekly progress (last 7 days) — for the retained "This week" card.
    final weeklyProgress = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final surveysOnDay = surveys.where((s) {
        final updated = s.updatedAt ?? s.createdAt;
        return updated.isAfter(dayStart) && updated.isBefore(dayEnd);
      }).length;
      weeklyProgress.add((surveysOnDay / 5).clamp(0.0, 1.0));
    }

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final surveysThisWeek =
        surveys.where((s) => s.createdAt.isAfter(weekStart)).length;
    final surveysLastWeek = surveys
        .where((s) =>
            s.createdAt.isAfter(lastWeekStart) &&
            s.createdAt.isBefore(weekStart))
        .length;

    return AnalyticsData(
      weeklyProgress: weeklyProgress,
      surveysThisWeek: surveysThisWeek,
      surveysLastWeek: surveysLastWeek,
    );
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(localSurveyRepositoryProvider);
  return DashboardNotifier(repository);
});

/// Jobs filtered by segment + status, for the clickable metric-card list
/// screens. Keyed by a record so Riverpod caches per (segment, filter).
final jobsListProvider = FutureProvider.family<List<Survey>,
    ({HomeSegment segment, JobFilter filter})>((ref, key) async {
  final repository = ref.watch(localSurveyRepositoryProvider);
  final all = await repository.getAllSurveys();
  final result =
      all.where(key.segment.matches).where(key.filter.matches).toList()
        ..sort((a, b) {
          final ad = a.updatedAt ?? a.createdAt;
          final bd = b.updatedAt ?? b.createdAt;
          return bd.compareTo(ad);
        });
  return result;
});

// Greeting provider based on time of day
final greetingProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;

  if (hour < 12) {
    return 'Good morning';
  } else if (hour < 17) {
    return 'Good afternoon';
  } else {
    return 'Good evening';
  }
});

// User name provider - gets the real user's first name from auth state
final userNameProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  if (user != null && user.firstName.isNotEmpty) {
    return user.firstName;
  }
  return 'Surveyor';
});

// User initials provider - gets the real user's initials from auth state
final userInitialsProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  if (user != null) {
    return user.initials;
  }
  return 'S';
});
