import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/not_found_handler.dart';
import '../../../../core/utils/auto_refresh_mixin.dart';
import '../../data/datasources/scheduling_remote_datasource.dart';
import '../../data/repositories/scheduling_repository_impl.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/availability_exception.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/scheduling_repository.dart';

// ===========================
// DATA LAYER PROVIDERS
// ===========================

final schedulingRemoteDataSourceProvider = Provider<SchedulingRemoteDataSource>((ref) => SchedulingRemoteDataSource(ref.watch(apiClientProvider)));

final schedulingRepositoryProvider = Provider<SchedulingRepository>((ref) => SchedulingRepositoryImpl(ref.watch(schedulingRemoteDataSourceProvider)));

// ===========================
// AVAILABILITY STATE
// ===========================

class AvailabilityState {
  const AvailabilityState({
    this.availability = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Availability> availability;
  final bool isLoading;
  final String? error;

  AvailabilityState copyWith({
    List<Availability>? availability,
    bool? isLoading,
    String? error,
  }) => AvailabilityState(
      availability: availability ?? this.availability,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
}

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  AvailabilityNotifier(this._repository) : super(const AvailabilityState());

  final SchedulingRepository _repository;

  Future<void> loadAvailability() async {
    state = state.copyWith(isLoading: true);
    try {
      final availability = await _repository.getMyAvailability();
      state = state.copyWith(availability: availability, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveAvailability(List<DayAvailabilityInput> input) async {
    state = state.copyWith(isLoading: true);
    try {
      final availability = await _repository.setAvailability(input);
      state = state.copyWith(availability: availability, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final availabilityNotifierProvider =
    StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) => AvailabilityNotifier(ref.watch(schedulingRepositoryProvider)));

// ===========================
// EXCEPTIONS STATE
// ===========================

class ExceptionsState {
  const ExceptionsState({
    this.exceptions = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AvailabilityException> exceptions;
  final bool isLoading;
  final String? error;

  ExceptionsState copyWith({
    List<AvailabilityException>? exceptions,
    bool? isLoading,
    String? error,
  }) => ExceptionsState(
      exceptions: exceptions ?? this.exceptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
}

class ExceptionsNotifier extends StateNotifier<ExceptionsState> {
  ExceptionsNotifier(this._repository) : super(const ExceptionsState());

  final SchedulingRepository _repository;

  Future<void> loadExceptions({DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(isLoading: true);
    try {
      final exceptions = await _repository.getMyExceptions(
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(exceptions: exceptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createException({
    required DateTime date,
    required bool isAvailable,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final exception = await _repository.createException(
        date: date,
        isAvailable: isAvailable,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      state = state.copyWith(
        exceptions: [...state.exceptions, exception],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteException(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteException(id);
      state = state.copyWith(
        exceptions: state.exceptions.where((e) => e.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final exceptionsNotifierProvider =
    StateNotifierProvider<ExceptionsNotifier, ExceptionsState>((ref) => ExceptionsNotifier(ref.watch(schedulingRepositoryProvider)));

// ===========================
// SLOTS STATE
// ===========================

class SlotsState {
  const SlotsState({
    this.slotsResponse,
    this.isLoading = false,
    this.error,
  });

  final SlotsResponse? slotsResponse;
  final bool isLoading;
  final String? error;

  SlotsState copyWith({
    SlotsResponse? slotsResponse,
    bool? isLoading,
    String? error,
  }) => SlotsState(
      slotsResponse: slotsResponse ?? this.slotsResponse,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
}

class SlotsNotifier extends StateNotifier<SlotsState> {
  SlotsNotifier(this._repository) : super(const SlotsState());

  final SchedulingRepository _repository;

  Future<void> loadSlots({
    required String surveyorId,
    required DateTime startDate,
    required DateTime endDate,
    int slotDuration = 60,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repository.getSlots(
        surveyorId: surveyorId,
        startDate: startDate,
        endDate: endDate,
        slotDuration: slotDuration,
      );
      state = state.copyWith(slotsResponse: response, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSlots() {
    state = const SlotsState();
  }
}

final slotsNotifierProvider =
    StateNotifierProvider<SlotsNotifier, SlotsState>((ref) => SlotsNotifier(ref.watch(schedulingRepositoryProvider)));

// ===========================
// BOOKINGS STATE
// ===========================

class BookingsState {
  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Booking> bookings;
  final bool isLoading;
  final String? error;

  BookingsState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
  }) => BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
}

class BookingsNotifier extends StateNotifier<BookingsState>
    with AutoRefreshMixin<BookingsState> {
  BookingsNotifier(this._repository) : super(const BookingsState());

  final SchedulingRepository _repository;

  // Track last used filter params for silent refresh
  String? _lastSurveyorId;
  BookingStatus? _lastStatus;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;

  /// Enables auto-refresh with the current filter parameters.
  void enableAutoRefresh() {
    startAutoRefresh(
      interval: const Duration(seconds: 60),
      onRefresh: _silentRefresh,
    );
  }

  /// Silent refresh - updates state without showing loading indicator.
  Future<void> _silentRefresh() async {
    try {
      final bookings = await _repository.listBookings(
        surveyorId: _lastSurveyorId,
        status: _lastStatus,
        startDate: _lastStartDate,
        endDate: _lastEndDate,
      );
      state = state.copyWith(bookings: bookings);
    } catch (_) {
      // Silent failure on background refresh
    }
  }

  Future<void> loadBookings({
    String? surveyorId,
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Store filter params for silent refresh
    _lastSurveyorId = surveyorId;
    _lastStatus = status;
    _lastStartDate = startDate;
    _lastEndDate = endDate;

    state = state.copyWith(isLoading: true);
    try {
      final bookings = await _repository.listBookings(
        surveyorId: surveyorId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMyBookings({
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final bookings = await _repository.getMyBookings(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Booking?> createBooking({
    required String surveyorId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? propertyAddress,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final booking = await _repository.createBooking(
        surveyorId: surveyorId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        propertyAddress: propertyAddress,
        notes: notes,
      );
      state = state.copyWith(
        bookings: [booking, ...state.bookings],
        isLoading: false,
      );
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _repository.updateBookingStatus(id, status);
      state = state.copyWith(
        bookings: state.bookings.map((b) => b.id == id ? updated : b).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> cancelBooking(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _repository.cancelBooking(id);
      state = state.copyWith(
        bookings: state.bookings.map((b) => b.id == id ? updated : b).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Removes a stale booking from the local state.
  /// Called when a 404 is detected for a booking that's still in the list.
  void removeStaleBooking(String bookingId) {
    final updatedBookings = state.bookings.where((b) => b.id != bookingId).toList();
    if (updatedBookings.length != state.bookings.length) {
      state = state.copyWith(bookings: updatedBookings);
    }
  }
}

final bookingsNotifierProvider =
    StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final notifier = BookingsNotifier(ref.watch(schedulingRepositoryProvider));

  // Listen to stale resource events to remove deleted bookings from list
  final subscription = NotFoundHandler.instance.staleResourceStream.listen((staleResource) {
    if (staleResource.resourceType == 'booking') {
      notifier.removeStaleBooking(staleResource.resourceId);
    }
  });

  // Clean up subscription when provider is disposed
  ref.onDispose(subscription.cancel);

  return notifier;
});

// ===========================
// SINGLE BOOKING PROVIDER
// ===========================

/// State for single booking detail with proper error handling
class BookingDetailState {
  const BookingDetailState({
    this.booking,
    this.isLoading = false,
    this.error,
    this.isNotFound = false,
  });

  final Booking? booking;
  final bool isLoading;
  final String? error;
  /// True if booking was not found (404) - should not show retry button
  final bool isNotFound;

  bool get hasBooking => booking != null;
  bool get hasError => error != null;
  /// Errors that can be retried (network issues, server errors, but NOT 404)
  bool get isRetriableError => hasError && !isNotFound;
}

/// Provider for individual booking detail with caching and proper 404 handling.
/// Uses keepAlive to prevent repeated fetches on widget rebuilds.
final bookingDetailProvider = FutureProvider.autoDispose.family<Booking?, String>((ref, id) async {
  // Keep alive to prevent refetching on every rebuild
  ref.keepAlive();

  // Don't fetch if ID is empty or null-like
  if (id.isEmpty || id == 'null') {
    return null;
  }

  try {
    return await ref.watch(schedulingRepositoryProvider).getBooking(id);
  } catch (e) {
    // Check if it's a 404 - booking not found is a valid state, not an error to retry
    if (_isNotFoundError(e)) {
      // Return null instead of throwing - booking simply doesn't exist
      return null;
    }
    // Rethrow other errors (network, server, etc.) which are retriable
    rethrow;
  }
});

/// Helper to check if error is a 404 Not Found
bool _isNotFoundError(Object e) {
  final errorStr = e.toString().toLowerCase();
  return errorStr.contains('404') ||
      errorStr.contains('not found') ||
      errorStr.contains('notfoundexception');
}
