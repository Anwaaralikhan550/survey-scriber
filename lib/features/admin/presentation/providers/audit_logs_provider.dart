import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/audit_log_model.dart';

/// State for audit logs list with filters and pagination
class AuditLogsState {
  const AuditLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.actorTypeFilter,
    this.entityTypeFilter,
    this.actionFilter,
    this.startDate,
    this.endDate,
  });

  final List<AuditLogModel> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int totalPages;
  final int total;

  // Filters
  final AuditActorType? actorTypeFilter;
  final AuditEntityType? entityTypeFilter;
  final String? actionFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasMore => page < totalPages;
  bool get hasFilters =>
      actorTypeFilter != null ||
      entityTypeFilter != null ||
      (actionFilter != null && actionFilter!.isNotEmpty) ||
      startDate != null ||
      endDate != null;

  AuditLogsState copyWith({
    List<AuditLogModel>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    int? totalPages,
    int? total,
    AuditActorType? actorTypeFilter,
    AuditEntityType? entityTypeFilter,
    String? actionFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool clearFilters = false,
    bool clearError = false,
  }) => AuditLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      actorTypeFilter: clearFilters ? null : (actorTypeFilter ?? this.actorTypeFilter),
      entityTypeFilter: clearFilters ? null : (entityTypeFilter ?? this.entityTypeFilter),
      actionFilter: clearFilters ? null : (actionFilter ?? this.actionFilter),
      startDate: clearFilters ? null : (startDate ?? this.startDate),
      endDate: clearFilters ? null : (endDate ?? this.endDate),
    );
}

class AuditLogsNotifier extends StateNotifier<AuditLogsState> {
  AuditLogsNotifier(this._apiClient) : super(const AuditLogsState());

  final ApiClient _apiClient;

  /// Load audit logs (page 1, resets list)
  Future<void> loadLogs() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _fetchLogs(page: 1);
      state = AuditLogsState(
        logs: response.logs,
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
        actorTypeFilter: state.actorTypeFilter,
        entityTypeFilter: state.entityTypeFilter,
        actionFilter: state.actionFilter,
        startDate: state.startDate,
        endDate: state.endDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  /// Load more logs (next page, appends to list)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _fetchLogs(page: state.page + 1);
      state = state.copyWith(
        logs: [...state.logs, ...response.logs],
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: _parseError(e),
      );
    }
  }

  /// Apply filters and reload
  void setFilters({
    AuditActorType? actorType,
    AuditEntityType? entityType,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    state = state.copyWith(
      actorTypeFilter: actorType,
      entityTypeFilter: entityType,
      actionFilter: action,
      startDate: startDate,
      endDate: endDate,
    );
    loadLogs();
  }

  /// Clear all filters and reload
  void clearFilters() {
    state = state.copyWith(clearFilters: true);
    loadLogs();
  }

  Future<AuditLogsResponse> _fetchLogs({required int page}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': '30',
    };

    if (state.actorTypeFilter != null) {
      queryParams['actorType'] = state.actorTypeFilter!.apiValue;
    }
    if (state.entityTypeFilter != null) {
      queryParams['entityType'] = state.entityTypeFilter!.apiValue;
    }
    if (state.actionFilter != null && state.actionFilter!.isNotEmpty) {
      queryParams['action'] = Uri.encodeQueryComponent(state.actionFilter!);
    }
    if (state.startDate != null) {
      queryParams['startDate'] = state.startDate!.toUtc().toIso8601String();
    }
    if (state.endDate != null) {
      queryParams['endDate'] = state.endDate!.toUtc().toIso8601String();
    }

    final queryString =
        queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    final response = await _apiClient.get<Map<String, dynamic>>(
      'audit-logs?$queryString',
    );

    return AuditLogsResponse.fromJson(response.data!);
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'Access denied. Admin privileges required.';
    }
    if (errorStr.contains('Network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load audit logs. Please try again.';
  }
}

final auditLogsProvider =
    StateNotifierProvider.autoDispose<AuditLogsNotifier, AuditLogsState>(
  (ref) => AuditLogsNotifier(ref.watch(apiClientProvider)),
);
