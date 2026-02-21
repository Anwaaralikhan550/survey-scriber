import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/booking_request_remote_datasource.dart';
import '../../data/repositories/booking_request_repository_impl.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/repositories/booking_request_repository.dart';

// ===========================
// Data Layer Providers
// ===========================

final bookingRequestRemoteDataSourceProvider =
    Provider<BookingRequestRemoteDataSource>((ref) => BookingRequestRemoteDataSource(ref.watch(apiClientProvider)));

final bookingRequestRepositoryProvider =
    Provider<BookingRequestRepository>((ref) => BookingRequestRepositoryImpl(
    ref.watch(bookingRequestRemoteDataSourceProvider),
  ),);

// ===========================
// Client Booking Requests State
// ===========================

class ClientBookingRequestsState {
  const ClientBookingRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
    this.statusFilter,
  });

  final List<BookingRequest> requests;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;
  final BookingRequestStatus? statusFilter;

  ClientBookingRequestsState copyWith({
    List<BookingRequest>? requests,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
    BookingRequestStatus? statusFilter,
    bool clearFilter = false,
  }) => ClientBookingRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
}

class ClientBookingRequestsNotifier
    extends StateNotifier<ClientBookingRequestsState> {
  ClientBookingRequestsNotifier(this._repository)
      : super(const ClientBookingRequestsState());

  final BookingRequestRepository _repository;

  Future<void> loadRequests({BookingRequestStatus? status}) async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      statusFilter: status,
      clearFilter: status == null,
    );
    try {
      final result = await _repository.getClientBookingRequests(
        status: status,
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
      final result = await _repository.getClientBookingRequests(
        status: state.statusFilter,
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
    loadRequests(status: state.statusFilter);
  }
}

final clientBookingRequestsNotifierProvider = StateNotifierProvider<
    ClientBookingRequestsNotifier, ClientBookingRequestsState>((ref) => ClientBookingRequestsNotifier(
    ref.watch(bookingRequestRepositoryProvider),
  ),);

// ===========================
// Create Booking Request State
// ===========================

class CreateBookingRequestState {
  const CreateBookingRequestState({
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.createdRequest,
  });

  final bool isSubmitting;
  final String? error;
  final bool success;
  final BookingRequest? createdRequest;

  CreateBookingRequestState copyWith({
    bool? isSubmitting,
    String? error,
    bool? success,
    BookingRequest? createdRequest,
  }) => CreateBookingRequestState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
      createdRequest: createdRequest ?? this.createdRequest,
    );
}

class CreateBookingRequestNotifier
    extends StateNotifier<CreateBookingRequestState> {
  CreateBookingRequestNotifier(this._repository)
      : super(const CreateBookingRequestState());

  final BookingRequestRepository _repository;

  Future<bool> submit({
    required String propertyAddress,
    required DateTime preferredStartDate,
    required DateTime preferredEndDate,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, success: false);
    try {
      final request = await _repository.createBookingRequest(
        propertyAddress: propertyAddress,
        preferredStartDate: preferredStartDate,
        preferredEndDate: preferredEndDate,
        notes: notes,
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
    state = const CreateBookingRequestState();
  }
}

final createBookingRequestNotifierProvider = StateNotifierProvider.autoDispose<
    CreateBookingRequestNotifier, CreateBookingRequestState>((ref) => CreateBookingRequestNotifier(
    ref.watch(bookingRequestRepositoryProvider),
  ),);

// ===========================
// Staff Booking Requests State
// ===========================

class StaffBookingRequestsState {
  const StaffBookingRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
    this.statusFilter,
  });

  final List<BookingRequest> requests;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;
  final BookingRequestStatus? statusFilter;

  StaffBookingRequestsState copyWith({
    List<BookingRequest>? requests,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
    BookingRequestStatus? statusFilter,
    bool clearFilter = false,
  }) => StaffBookingRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
}

class StaffBookingRequestsNotifier
    extends StateNotifier<StaffBookingRequestsState> {
  StaffBookingRequestsNotifier(this._repository)
      : super(const StaffBookingRequestsState());

  final BookingRequestRepository _repository;

  Future<void> loadRequests({BookingRequestStatus? status}) async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      statusFilter: status,
      clearFilter: status == null,
    );
    try {
      final result = await _repository.getStaffBookingRequests(
        status: status,
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
      final result = await _repository.getStaffBookingRequests(
        status: state.statusFilter,
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
      final updated = await _repository.approveBookingRequest(id);
      state = state.copyWith(
        requests: state.requests
            .map((r) => r.id == id ? updated : r)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String id, {String? reason}) async {
    try {
      final updated = await _repository.rejectBookingRequest(id, reason: reason);
      state = state.copyWith(
        requests: state.requests
            .map((r) => r.id == id ? updated : r)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void refresh() {
    loadRequests(status: state.statusFilter);
  }
}

final staffBookingRequestsNotifierProvider = StateNotifierProvider<
    StaffBookingRequestsNotifier, StaffBookingRequestsState>((ref) => StaffBookingRequestsNotifier(
    ref.watch(bookingRequestRepositoryProvider),
  ),);

// ===========================
// Single Item Provider
// ===========================

final clientBookingRequestDetailProvider =
    FutureProvider.autoDispose.family<BookingRequest, String>((ref, id) => ref.watch(bookingRequestRepositoryProvider).getClientBookingRequest(id));

final staffBookingRequestDetailProvider =
    FutureProvider.autoDispose.family<BookingRequest, String>((ref, id) => ref.watch(bookingRequestRepositoryProvider).getStaffBookingRequest(id));
