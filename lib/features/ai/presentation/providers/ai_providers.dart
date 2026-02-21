import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/repositories/ai_repository.dart';

/// Client-side safety timeout for AI generation requests.
/// This catches cases where the HTTP call hangs beyond the Dio timeout.
/// Must be above the backend timeout (120s) and Dio receiveTimeout (120s)
/// to let normal timeouts fire first; this is a last-resort catch.
const _clientSafetyTimeout = Duration(seconds: 150);

// ============================================
// Dependency Injection Providers
// ============================================

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>(
  (ref) => AiRemoteDataSource(ref.watch(apiClientProvider)),
);

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepositoryImpl(ref.watch(aiRemoteDataSourceProvider)),
);

// ============================================
// Status Provider with Caching
// ============================================

/// Cache TTL for AI status (5 minutes)
const _aiStatusCacheTtl = Duration(minutes: 5);

/// State class for AI status with caching support
class AiStatusState {
  const AiStatusState({
    this.status,
    this.isLoading = false,
    this.error,
    this.lastFetchedAt,
  });

  final AiStatus? status;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchedAt;

  /// Whether the cached status is still valid
  bool get isCacheValid {
    if (status == null || lastFetchedAt == null) return false;
    return DateTime.now().difference(lastFetchedAt!) < _aiStatusCacheTtl;
  }

  /// Convenience getter for availability
  bool get isAvailable => status?.available ?? false;

  AiStatusState copyWith({
    AiStatus? status,
    bool? isLoading,
    String? error,
    DateTime? lastFetchedAt,
  }) =>
      AiStatusState(
        status: status ?? this.status,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      );
}

/// Notifier for AI status that persists across navigation
class AiStatusNotifier extends StateNotifier<AiStatusState> {
  AiStatusNotifier(this._repository) : super(const AiStatusState()) {
    // Fetch immediately on creation
    fetchStatus();
  }

  final AiRepository _repository;

  /// Fetch AI status, using cache if valid
  Future<void> fetchStatus({bool forceRefresh = false}) async {
    // Return cached value if valid and not forcing refresh
    if (!forceRefresh && state.isCacheValid) {
      return;
    }

    // Don't refetch if already loading
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final status = await _repository.getStatus();
      state = AiStatusState(
        status: status,
        lastFetchedAt: DateTime.now(),
      );
    } catch (e) {
      // On error, keep old status if available, mark as unavailable otherwise
      state = AiStatusState(
        status: state.status ?? AiStatus.unavailable(e.toString()),
        error: e.toString(),
        lastFetchedAt: state.lastFetchedAt,
      );
    }
  }

  /// Force refresh the status (for manual retry)
  Future<void> refresh() => fetchStatus(forceRefresh: true);
}

/// Provider for AI status - persists across navigation (no autoDispose)
final aiStatusNotifierProvider =
    StateNotifierProvider<AiStatusNotifier, AiStatusState>(
  (ref) => AiStatusNotifier(ref.watch(aiRepositoryProvider)),
);

/// Convenience provider that returns AsyncValue for backward compatibility
/// This allows existing widgets to use .when() pattern
final aiStatusProvider = Provider<AsyncValue<AiStatus>>((ref) {
  final state = ref.watch(aiStatusNotifierProvider);

  if (state.isLoading && state.status == null) {
    return const AsyncValue.loading();
  }

  if (state.status != null) {
    return AsyncValue.data(state.status!);
  }

  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }

  // Default: loading state
  return const AsyncValue.loading();
});

// ============================================
// Report Generation Provider
// ============================================

class AiReportState {
  const AiReportState({
    this.response,
    this.isLoading = false,
    this.error,
    this.isServiceUnavailable = false,
  });

  final AiReportResponse? response;
  final bool isLoading;
  final String? error;
  /// True if error was due to AI service being unavailable (503, timeout)
  final bool isServiceUnavailable;

  AiReportState copyWith({
    AiReportResponse? response,
    bool? isLoading,
    String? error,
    bool? isServiceUnavailable,
  }) =>
      AiReportState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isServiceUnavailable: isServiceUnavailable ?? this.isServiceUnavailable,
      );

  bool get hasResponse => response != null;
}

class AiReportNotifier extends StateNotifier<AiReportState> {
  AiReportNotifier(this._repository) : super(const AiReportState());

  final AiRepository _repository;

  Future<void> generateReport(GenerateReportRequest request) async {
    // Prevent duplicate requests while one is in flight
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, isServiceUnavailable: false);

    final stopwatch = Stopwatch()..start();
    AppLogger.d('AiReport', 'Generating for survey=${request.surveyId}, '
        'sections=${request.sections.length}, '
        'issues=${request.issues?.length ?? 0}');

    try {
      final response = await _repository.generateReport(request)
          .timeout(_clientSafetyTimeout, onTimeout: () {
        throw TimeoutException(
          'AI report generation timed out after ${_clientSafetyTimeout.inSeconds}s',
        );
      });
      stopwatch.stop();
      AppLogger.d('AiReport', 'Completed in ${stopwatch.elapsedMilliseconds}ms');
      if (mounted) {
        state = state.copyWith(response: response, isLoading: false);
      }
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.e('AiReport', 'Failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      developer.log(
        'AiReport: failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'ai',
        error: e,
        stackTrace: stack,
      );
      final isUnavailable = _isServiceUnavailableError(e);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          isServiceUnavailable: isUnavailable,
        );
      }
    }
  }

  /// Checks if the error indicates service unavailability (503, timeout, etc.)
  bool _isServiceUnavailableError(Object e) {
    if (e is TimeoutException) return true;
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('503') ||
        errorStr.contains('service unavailable') ||
        errorStr.contains('temporarily unavailable') ||
        errorStr.contains('timeout') ||
        errorStr.contains('timed out');
  }

  void clearResponse() {
    state = const AiReportState();
  }
}

final aiReportNotifierProvider =
    StateNotifierProvider.autoDispose<AiReportNotifier, AiReportState>(
  (ref) => AiReportNotifier(ref.watch(aiRepositoryProvider)),
);

// ============================================
// Recommendations Provider
// ============================================

class AiRecommendationsState {
  const AiRecommendationsState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  final AiRecommendationsResponse? response;
  final bool isLoading;
  final String? error;

  AiRecommendationsState copyWith({
    AiRecommendationsResponse? response,
    bool? isLoading,
    String? error,
  }) =>
      AiRecommendationsState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get hasResponse => response != null;
}

class AiRecommendationsNotifier
    extends StateNotifier<AiRecommendationsState> {
  AiRecommendationsNotifier(this._repository)
      : super(const AiRecommendationsState());

  final AiRepository _repository;

  Future<void> generateRecommendations(
      GenerateRecommendationsRequest request,) async {
    // Prevent duplicate requests while one is in flight
    if (state.isLoading) return;

    developer.log(
      'AiRecommendations: generating for survey=${request.surveyId}, '
      'issues=${request.issues.length}, '
      'sections=${request.sections?.length ?? 0}',
      name: 'ai',
    );
    state = state.copyWith(isLoading: true);

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _repository.generateRecommendations(request)
          .timeout(_clientSafetyTimeout, onTimeout: () {
        throw TimeoutException(
          'AI recommendations generation timed out after ${_clientSafetyTimeout.inSeconds}s',
        );
      });
      stopwatch.stop();
      AppLogger.d('AiRecommendations',
        'Received ${response.recommendations.length} recommendations '
        '(fromCache=${response.fromCache}) in ${stopwatch.elapsedMilliseconds}ms');
      if (mounted) {
        state = state.copyWith(response: response, isLoading: false);
      }
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.e('AiRecommendations',
        'Error after ${stopwatch.elapsedMilliseconds}ms: $e');
      developer.log(
        'AiRecommendations: error after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'ai',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void clearResponse() {
    state = const AiRecommendationsState();
  }
}

final aiRecommendationsNotifierProvider = StateNotifierProvider.autoDispose<
    AiRecommendationsNotifier, AiRecommendationsState>(
  (ref) => AiRecommendationsNotifier(ref.watch(aiRepositoryProvider)),
);

// ============================================
// Risk Summary Provider
// ============================================

class AiRiskSummaryState {
  const AiRiskSummaryState({
    this.response,
    this.isLoading = false,
    this.error,
    this.isServiceUnavailable = false,
  });

  final AiRiskSummaryResponse? response;
  final bool isLoading;
  final String? error;
  /// True if error was due to AI service being unavailable (503)
  final bool isServiceUnavailable;

  AiRiskSummaryState copyWith({
    AiRiskSummaryResponse? response,
    bool? isLoading,
    String? error,
    bool? isServiceUnavailable,
  }) =>
      AiRiskSummaryState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isServiceUnavailable: isServiceUnavailable ?? this.isServiceUnavailable,
      );

  bool get hasResponse => response != null;
}

class AiRiskSummaryNotifier extends StateNotifier<AiRiskSummaryState> {
  AiRiskSummaryNotifier(this._repository)
      : super(const AiRiskSummaryState());

  final AiRepository _repository;

  Future<void> generateRiskSummary(GenerateRiskSummaryRequest request) async {
    // Prevent duplicate requests while one is in flight
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, isServiceUnavailable: false);

    final stopwatch = Stopwatch()..start();
    developer.log(
      'AiRiskSummary: generating for survey=${request.surveyId}',
      name: 'ai',
    );

    try {
      final response = await _repository.generateRiskSummary(request)
          .timeout(_clientSafetyTimeout, onTimeout: () {
        throw TimeoutException(
          'AI risk summary generation timed out after ${_clientSafetyTimeout.inSeconds}s',
        );
      });
      stopwatch.stop();
      AppLogger.d('AiRiskSummary',
        'Completed in ${stopwatch.elapsedMilliseconds}ms '
        '(risk=${response.overallRiskLevel})');
      if (mounted) {
        state = state.copyWith(response: response, isLoading: false);
      }
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.e('AiRiskSummary',
        'Failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      developer.log(
        'AiRiskSummary: failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        name: 'ai',
        error: e,
        stackTrace: stack,
      );
      // Check if this is a service unavailable error (503)
      final isUnavailable = _isServiceUnavailableError(e);
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: e.toString(),
          isServiceUnavailable: isUnavailable,
        );
      }
    }
  }

  /// Checks if the error indicates service unavailability (503, timeout, etc.)
  bool _isServiceUnavailableError(Object e) {
    final errorStr = e.toString().toLowerCase();
    return errorStr.contains('503') ||
        errorStr.contains('service unavailable') ||
        errorStr.contains('temporarily unavailable') ||
        errorStr.contains('timeout') ||
        errorStr.contains('timed out');
  }

  void clearResponse() {
    state = const AiRiskSummaryState();
  }
}

final aiRiskSummaryNotifierProvider =
    StateNotifierProvider.autoDispose<AiRiskSummaryNotifier, AiRiskSummaryState>(
  (ref) => AiRiskSummaryNotifier(ref.watch(aiRepositoryProvider)),
);

// ============================================
// Consistency Check Provider
// ============================================

class AiConsistencyState {
  const AiConsistencyState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  final AiConsistencyResponse? response;
  final bool isLoading;
  final String? error;

  AiConsistencyState copyWith({
    AiConsistencyResponse? response,
    bool? isLoading,
    String? error,
  }) =>
      AiConsistencyState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get hasResponse => response != null;
}

class AiConsistencyNotifier extends StateNotifier<AiConsistencyState> {
  AiConsistencyNotifier(this._repository)
      : super(const AiConsistencyState());

  final AiRepository _repository;

  Future<void> checkConsistency(ConsistencyCheckRequest request) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _repository.checkConsistency(request);
      state = state.copyWith(response: response, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearResponse() {
    state = const AiConsistencyState();
  }
}

final aiConsistencyNotifierProvider =
    StateNotifierProvider.autoDispose<AiConsistencyNotifier, AiConsistencyState>(
  (ref) => AiConsistencyNotifier(ref.watch(aiRepositoryProvider)),
);

// ============================================
// Photo Tags Provider
// ============================================

class AiPhotoTagsState {
  const AiPhotoTagsState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  final AiPhotoTagsResponse? response;
  final bool isLoading;
  final String? error;

  AiPhotoTagsState copyWith({
    AiPhotoTagsResponse? response,
    bool? isLoading,
    String? error,
  }) =>
      AiPhotoTagsState(
        response: response ?? this.response,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get hasResponse => response != null;
}

class AiPhotoTagsNotifier extends StateNotifier<AiPhotoTagsState> {
  AiPhotoTagsNotifier(this._repository) : super(const AiPhotoTagsState());

  final AiRepository _repository;

  Future<void> generateTags(PhotoTagsRequest request) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _repository.generatePhotoTags(request);
      state = state.copyWith(response: response, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearResponse() {
    state = const AiPhotoTagsState();
  }
}

final aiPhotoTagsNotifierProvider =
    StateNotifierProvider.autoDispose<AiPhotoTagsNotifier, AiPhotoTagsState>(
  (ref) => AiPhotoTagsNotifier(ref.watch(aiRepositoryProvider)),
);
