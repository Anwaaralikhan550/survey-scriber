import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/domain/entities/survey.dart';

/// Search filter for survey type
enum SearchFilterType {
  all,
  inspection,
  valuation,
  reinspection,
}

/// Search filter for survey status
enum SearchFilterStatus {
  all,
  draft,
  inProgress,
  paused,
  completed,
  pendingReview,
  approved,
  rejected,
}

/// Date range filter
class DateRangeFilter {
  const DateRangeFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  bool get hasFilter => from != null || to != null;

  DateRangeFilter copyWith({DateTime? from, DateTime? to, bool clearFrom = false, bool clearTo = false}) =>
      DateRangeFilter(
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );
}

/// All search filters combined
class SearchFilters {
  const SearchFilters({
    this.type = SearchFilterType.all,
    this.status = SearchFilterStatus.all,
    this.dateRange = const DateRangeFilter(),
    this.clientName,
  });

  final SearchFilterType type;
  final SearchFilterStatus status;
  final DateRangeFilter dateRange;
  final String? clientName;

  bool get hasActiveFilters =>
      type != SearchFilterType.all ||
      status != SearchFilterStatus.all ||
      dateRange.hasFilter ||
      (clientName != null && clientName!.isNotEmpty);

  int get activeFilterCount {
    var count = 0;
    if (type != SearchFilterType.all) count++;
    if (status != SearchFilterStatus.all) count++;
    if (dateRange.hasFilter) count++;
    if (clientName != null && clientName!.isNotEmpty) count++;
    return count;
  }

  SearchFilters copyWith({
    SearchFilterType? type,
    SearchFilterStatus? status,
    DateRangeFilter? dateRange,
    String? clientName,
    bool clearClientName = false,
  }) =>
      SearchFilters(
        type: type ?? this.type,
        status: status ?? this.status,
        dateRange: dateRange ?? this.dateRange,
        clientName: clearClientName ? null : (clientName ?? this.clientName),
      );

  SearchFilters clear() => const SearchFilters();
}

/// Search error types for proper error handling
enum SearchErrorType {
  network,
  server,
  unknown,
}

/// Search state
class SearchState {
  const SearchState({
    this.query = '',
    this.isSearching = false,
    this.results = const [],
    this.filters = const SearchFilters(),
    this.hasSearched = false,
    this.errorMessage,
    this.errorType,
    this.totalResults = 0,
    this.currentPage = 1,
    this.hasMorePages = false,
  });

  final String query;
  final bool isSearching;
  final List<Survey> results;
  final SearchFilters filters;
  final bool hasSearched;
  final String? errorMessage;
  final SearchErrorType? errorType;
  final int totalResults;
  final int currentPage;
  final bool hasMorePages;

  bool get hasResults => results.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get canRetry => hasError && errorType == SearchErrorType.network;

  SearchState copyWith({
    String? query,
    bool? isSearching,
    List<Survey>? results,
    SearchFilters? filters,
    bool? hasSearched,
    String? errorMessage,
    SearchErrorType? errorType,
    bool clearError = false,
    int? totalResults,
    int? currentPage,
    bool? hasMorePages,
  }) =>
      SearchState(
        query: query ?? this.query,
        isSearching: isSearching ?? this.isSearching,
        results: results ?? this.results,
        filters: filters ?? this.filters,
        hasSearched: hasSearched ?? this.hasSearched,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        errorType: clearError ? null : (errorType ?? this.errorType),
        totalResults: totalResults ?? this.totalResults,
        currentPage: currentPage ?? this.currentPage,
        hasMorePages: hasMorePages ?? this.hasMorePages,
      );
}

/// Search notifier with debouncing and API integration
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._apiClient) : super(const SearchState());

  final ApiClient _apiClient;
  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  /// F8 FIX: Track disposal state to prevent callbacks after dispose
  bool _isDisposed = false;

  static const _debounceMs = 300;
  static const _pageSize = 20;

  @override
  void dispose() {
    _isDisposed = true; // F8 FIX: Mark as disposed first
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  /// Debounced search - waits 300ms before executing
  void search(String query) {
    _debounceTimer?.cancel();

    // F8 FIX: Don't proceed if disposed
    if (_isDisposed) return;

    // Update query immediately for UI responsiveness
    state = state.copyWith(query: query, clearError: true);

    if (query.trim().isEmpty && !state.filters.hasActiveFilters) {
      state = state.copyWith(
        results: [],
        hasSearched: false,
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    _debounceTimer = Timer(const Duration(milliseconds: _debounceMs), () {
      // F8 FIX: Check disposed state before executing callback
      if (_isDisposed) return;
      _executeSearch(query.trim());
    });
  }

  /// Execute search immediately (used by filters)
  Future<void> searchNow() async {
    _debounceTimer?.cancel();
    await _executeSearch(state.query.trim());
  }

  /// Execute the actual search
  Future<void> _executeSearch(String query, {int page = 1}) async {
    // Cancel any pending request
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(isSearching: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': _pageSize,
      };

      // Add search query
      if (query.isNotEmpty) {
        queryParams['q'] = query;
      }

      // Add type filter
      if (state.filters.type != SearchFilterType.all) {
        queryParams['type'] = _mapTypeToBackend(state.filters.type);
      }

      // Add status filter
      if (state.filters.status != SearchFilterStatus.all) {
        queryParams['status'] = _mapStatusToBackend(state.filters.status);
      }

      // Add date range filter
      if (state.filters.dateRange.from != null) {
        queryParams['createdFrom'] = state.filters.dateRange.from!.toIso8601String();
      }
      if (state.filters.dateRange.to != null) {
        queryParams['createdTo'] = state.filters.dateRange.to!.toIso8601String();
      }

      // Add client name filter
      if (state.filters.clientName != null && state.filters.clientName!.isNotEmpty) {
        queryParams['clientName'] = state.filters.clientName;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        'surveys',
        queryParameters: queryParams,
        cancelToken: _cancelToken,
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from server');
      }

      final surveyList = (data['data'] as List<dynamic>?) ?? [];
      final meta = data['meta'] as Map<String, dynamic>?;

      final surveys = surveyList.map((json) => _mapSurveyFromJson(json as Map<String, dynamic>)).toList();

      state = state.copyWith(
        isSearching: false,
        results: surveys,
        hasSearched: true,
        totalResults: meta?['total'] as int? ?? surveys.length,
        currentPage: meta?['page'] as int? ?? 1,
        hasMorePages: meta?['hasNext'] as bool? ?? false,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Request was cancelled, ignore
        return;
      }

      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        results: [],
        errorMessage: e.type == DioExceptionType.connectionError
            ? 'No internet connection. Please check your network.'
            : 'Failed to search surveys. Please try again.',
        errorType: e.type == DioExceptionType.connectionError
            ? SearchErrorType.network
            : SearchErrorType.server,
      );
    } on Exception {
      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        results: [],
        errorMessage: 'An unexpected error occurred. Please try again.',
        errorType: SearchErrorType.unknown,
      );
    }
  }

  /// Retry the last search
  Future<void> retry() async {
    await _executeSearch(state.query);
  }

  /// Set type filter and re-search
  void setTypeFilter(SearchFilterType type) {
    state = state.copyWith(
      filters: state.filters.copyWith(type: type),
    );
    if (state.query.isNotEmpty || state.filters.hasActiveFilters) {
      searchNow();
    }
  }

  /// Set status filter and re-search
  void setStatusFilter(SearchFilterStatus status) {
    state = state.copyWith(
      filters: state.filters.copyWith(status: status),
    );
    if (state.query.isNotEmpty || state.filters.hasActiveFilters) {
      searchNow();
    }
  }

  /// Set date range filter and re-search
  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        dateRange: DateRangeFilter(from: from, to: to),
      ),
    );
    if (state.query.isNotEmpty || state.filters.hasActiveFilters) {
      searchNow();
    }
  }

  /// Set client name filter and re-search
  void setClientFilter(String? clientName) {
    state = state.copyWith(
      filters: state.filters.copyWith(
        clientName: clientName,
        clearClientName: clientName == null || clientName.isEmpty,
      ),
    );
    if (state.query.isNotEmpty || state.filters.hasActiveFilters) {
      searchNow();
    }
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      filters: const SearchFilters(),
    );
    if (state.query.isNotEmpty) {
      searchNow();
    } else {
      state = state.copyWith(
        results: [],
        hasSearched: false,
      );
    }
  }

  /// Clear search completely
  void clearSearch() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    state = const SearchState();
  }

  /// Map filter type to backend enum
  String _mapTypeToBackend(SearchFilterType type) => switch (type) {
        SearchFilterType.inspection => 'INSPECTION',
        SearchFilterType.valuation => 'VALUATION',
        SearchFilterType.reinspection => 'REINSPECTION',
        SearchFilterType.all => '',
      };

  /// Map filter status to backend enum
  String _mapStatusToBackend(SearchFilterStatus status) => switch (status) {
        SearchFilterStatus.draft => 'DRAFT',
        SearchFilterStatus.inProgress => 'IN_PROGRESS',
        SearchFilterStatus.paused => 'PAUSED',
        SearchFilterStatus.completed => 'COMPLETED',
        SearchFilterStatus.pendingReview => 'PENDING_REVIEW',
        SearchFilterStatus.approved => 'APPROVED',
        SearchFilterStatus.rejected => 'REJECTED',
        SearchFilterStatus.all => '',
      };

  /// Map JSON response to Survey entity
  Survey _mapSurveyFromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'DRAFT';
    final typeStr = json['type'] as String? ?? 'LEVEL_2';

    return Survey(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Survey',
      type: SurveyType.fromBackendString(typeStr),
      status: _mapStatusFromBackend(statusStr),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      jobRef: json['jobRef'] as String?,
      address: json['propertyAddress'] as String?,
      clientName: json['clientName'] as String?,
    );
  }

  /// Map backend status to SurveyStatus enum
  SurveyStatus _mapStatusFromBackend(String status) => switch (status.toUpperCase()) {
        'DRAFT' => SurveyStatus.draft,
        'IN_PROGRESS' => SurveyStatus.inProgress,
        'PAUSED' => SurveyStatus.paused,
        'COMPLETED' => SurveyStatus.completed,
        'PENDING_REVIEW' => SurveyStatus.pendingReview,
        'APPROVED' => SurveyStatus.approved,
        'REJECTED' => SurveyStatus.rejected,
        _ => SurveyStatus.draft,
      };
}

/// Provider for search functionality
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchNotifier(apiClient);
});
