import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/presentation/widgets/analytics_cards.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../surveys/domain/repositories/survey_repository.dart';
import '../../../surveys/presentation/providers/survey_providers.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalSurveys,
    required this.inProgress,
    required this.completed,
  });

  final int totalSurveys;
  final int inProgress;
  final int completed;

  static const empty = DashboardStats(
    totalSurveys: 0,
    inProgress: 0,
    completed: 0,
  );
}

class DashboardState {
  const DashboardState({
    this.isLoading = true,
    this.stats = DashboardStats.empty,
    this.recentSurveys = const [],
    this.analytics = const AnalyticsData(),
    this.errorMessage,
  });

  final bool isLoading;
  final DashboardStats stats;
  final List<Survey> recentSurveys;
  final AnalyticsData analytics;
  final String? errorMessage;

  bool get hasError => errorMessage != null;

  DashboardState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    List<Survey>? recentSurveys,
    AnalyticsData? analytics,
    String? errorMessage,
  }) =>
      DashboardState(
        isLoading: isLoading ?? this.isLoading,
        stats: stats ?? this.stats,
        recentSurveys: recentSurveys ?? this.recentSurveys,
        analytics: analytics ?? this.analytics,
        errorMessage: errorMessage,
      );
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier(this._repository) : super(const DashboardState()) {
    loadDashboard();
  }

  final SurveyRepository _repository;

  Future<void> loadDashboard() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      final results = await Future.wait([
        _repository.getTotalSurveyCount(),
        _repository.getInProgressCount(),
        _repository.getCompletedCount(),
        _repository.getRecentSurveys(),
        _repository.getAllSurveys(),
      ]);
      if (!mounted) return;

      final stats = DashboardStats(
        totalSurveys: results[0] as int,
        inProgress: results[1] as int,
        completed: results[2] as int,
      );

      // Compute analytics from all surveys
      final allSurveys = results[4] as List<Survey>;
      final analytics = _computeAnalytics(allSurveys, stats);

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        recentSurveys: results[3] as List<Survey>,
        analytics: analytics,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard data',
      );
    }
  }

  AnalyticsData _computeAnalytics(List<Survey> surveys, DashboardStats stats) {
    // Completion rate
    final completionRate = stats.totalSurveys > 0
        ? stats.completed / stats.totalSurveys
        : 0.0;

    // Weekly progress (last 7 days)
    final now = DateTime.now();
    final weeklyProgress = <double>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final surveysOnDay = surveys.where((s) {
        final updated = s.updatedAt ?? s.createdAt;
        return updated.isAfter(dayStart) && updated.isBefore(dayEnd);
      }).length;

      // Normalize to 0-1 range (max 5 surveys per day for full bar)
      weeklyProgress.add((surveysOnDay / 5).clamp(0.0, 1.0));
    }

    // Status distribution
    final statusDistribution = <String, int>{};
    for (final survey in surveys) {
      final status = survey.status.name;
      statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;
    }

    // Surveys this week vs last week
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    final surveysThisWeek = surveys.where((s) {
      final date = s.createdAt;
      return date.isAfter(weekStart);
    }).length;

    final surveysLastWeek = surveys.where((s) {
      final date = s.createdAt;
      return date.isAfter(lastWeekStart) && date.isBefore(weekStart);
    }).length;

    return AnalyticsData(
      completionRate: completionRate,
      weeklyProgress: weeklyProgress,
      statusDistribution: statusDistribution,
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
