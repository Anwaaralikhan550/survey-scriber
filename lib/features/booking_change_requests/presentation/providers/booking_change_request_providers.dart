import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/booking_change_request_remote_datasource.dart';
import '../../data/repositories/booking_change_request_repository_impl.dart';
import '../../domain/entities/booking_change_request.dart';
import '../../domain/repositories/booking_change_request_repository.dart';

// ===========================
// Data Layer Providers
// ===========================

final bookingChangeRequestRemoteDataSourceProvider =
    Provider<BookingChangeRequestRemoteDataSource>((ref) => BookingChangeRequestRemoteDataSource(ref.watch(apiClientProvider)));

final bookingChangeRequestRepositoryProvider =
    Provider<BookingChangeRequestRepository>((ref) => BookingChangeRequestRepositoryImpl(
    ref.watch(bookingChangeRequestRemoteDataSourceProvider),
  ),);

// ===========================
// Client Change Requests State
// ===========================

class ClientChangeRequestsState {
  const ClientChangeRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
    this.statusFilter,
    this.typeFilter,
  });

  final List<BookingChangeRequest> requests;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;
  final BookingChangeRequestStatus? statusFilter;
  final BookingChangeRequestType? typeFilter;

  ClientChangeRequestsState copyWith({
    List<BookingChangeRequest>? requests,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
    BookingChangeRequestStatus? statusFilter,
    BookingChangeRequestType? typeFilter,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
  }) => ClientChangeRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
}

class ClientChangeRequestsNotifier
    extends StateNotifier<ClientChangeRequestsState> {
  ClientChangeRequestsNotifier(this._repository)
      : super(const ClientChangeRequestsState());

  final BookingChangeRequestRepository _repository;

  Future<void> loadRequests({
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
  }) async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      statusFilter: status,
      typeFilter: type,
      clearStatusFilter: status == null,
      clearTypeFilter: type == null,
    );
    try {
      final result = await _repository.getClientChangeRequests(
        status: status,
        type: type,
      );
      state = state.copyWith(
        requests: result.requests,
        isLoading: false,
        hasMore: result.hasMore,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.getClientChangeRequests(
        status: state.statusFilter,
        type: state.typeFilter,
        page: nextPage,
      );
      state = state.copyWith(
        requests: [...state.requests, ...result.requests],
        isLoading: false,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() {
    loadRequests(status: state.statusFilter, type: state.typeFilter);
  }
}

final clientChangeRequestsNotifierProvider = StateNotifierProvider<
    ClientChangeRequestsNotifier, ClientChangeRequestsState>((ref) => ClientChangeRequestsNotifier(
    ref.watch(bookingChangeRequestRepositoryProvider),
  ),);

// ===========================
// Create Change Request State
// ===========================

class CreateChangeRequestState {
  const CreateChangeRequestState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.createdRequest,
  });

  final bool isSubmitting;
  final String? error;
  final bool success;
  final BookingChangeRequest? createdRequest;

  CreateChangeRequestState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
    BookingChangeRequest? createdRequest,
  }) => CreateChangeRequestState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
      createdRequest: createdRequest ?? this.createdRequest,
    );
}

class CreateChangeRequestNotifier
    extends StateNotifier<CreateChangeRequestState> {
  CreateChangeRequestNotifier(this._repository)
      : super(const CreateChangeRequestState());

  final BookingChangeRequestRepository _repository;

  Future<bool> submit({
    required String bookingId,
    required BookingChangeRequestType type,
    DateTime? proposedDate,
    String? proposedStartTime,
    String? proposedEndTime,
    String? reason,
  }) async {
    state = state.copyWith(isSubmitting: true, success: false);
    try {
      final request = await _repository.createChangeRequest(
        bookingId: bookingId,
        type: type,
        proposedDate: proposedDate,
        proposedStartTime: proposedStartTime,
        proposedEndTime: proposedEndTime,
        reason: reason,
      );
      state = state.copyWith(
        isSubmitting: false,
        success: true,
        createdRequest: request,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const CreateChangeRequestState();
  }
}

final createChangeRequestNotifierProvider = StateNotifierProvider.autoDispose<
    CreateChangeRequestNotifier, CreateChangeRequestState>((ref) => CreateChangeRequestNotifier(
    ref.watch(bookingChangeRequestRepositoryProvider),
  ),);

// ===========================
// Staff Change Requests State
// ===========================

class StaffChangeRequestsState {
  const StaffChangeRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
    this.statusFilter,
    this.typeFilter,
  });

  final List<BookingChangeRequest> requests;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;
  final BookingChangeRequestStatus? statusFilter;
  final BookingChangeRequestType? typeFilter;

  StaffChangeRequestsState copyWith({
    List<BookingChangeRequest>? requests,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
    BookingChangeRequestStatus? statusFilter,
    BookingChangeRequestType? typeFilter,
    bool clearStatusFilter = false,
    bool clearTypeFilter = false,
  }) => StaffChangeRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
}

class StaffChangeRequestsNotifier
    extends StateNotifier<StaffChangeRequestsState> {
  StaffChangeRequestsNotifier(this._repository)
      : super(const StaffChangeRequestsState());

  final BookingChangeRequestRepository _repository;

  Future<void> loadRequests({
    BookingChangeRequestStatus? status,
    BookingChangeRequestType? type,
  }) async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      statusFilter: status,
      typeFilter: type,
      clearStatusFilter: status == null,
      clearTypeFilter: type == null,
    );
    try {
      final result = await _repository.getStaffChangeRequests(
        status: status,
        type: type,
      );
      state = state.copyWith(
        requests: result.requests,
        isLoading: false,
        hasMore: result.hasMore,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.getStaffChangeRequests(
        status: state.statusFilter,
        type: state.typeFilter,
        page: nextPage,
      );
      state = state.copyWith(
        requests: [...state.requests, ...result.requests],
        isLoading: false,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approveRequest(String id) async {
    try {
      final updated = await _repository.approveChangeRequest(id);
      state = state.copyWith(
        requests:
            state.requests.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String id, {String? reason}) async {
    try {
      final updated =
          await _repository.rejectChangeRequest(id, reason: reason);
      state = state.copyWith(
        requests:
            state.requests.map((r) => r.id == id ? updated : r).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void refresh() {
    loadRequests(status: state.statusFilter, type: state.typeFilter);
  }
}

final staffChangeRequestsNotifierProvider = StateNotifierProvider<
    StaffChangeRequestsNotifier, StaffChangeRequestsState>((ref) => StaffChangeRequestsNotifier(
    ref.watch(bookingChangeRequestRepositoryProvider),
  ),);

// ===========================
// Single Item Providers
// ===========================

final clientChangeRequestDetailProvider =
    FutureProvider.autoDispose.family<BookingChangeRequest, String>((ref, id) => ref
      .watch(bookingChangeRequestRepositoryProvider)
      .getClientChangeRequest(id),);

final staffChangeRequestDetailProvider =
    FutureProvider.autoDispose.family<BookingChangeRequest, String>((ref, id) => ref
      .watch(bookingChangeRequestRepositoryProvider)
      .getStaffChangeRequest(id),);
