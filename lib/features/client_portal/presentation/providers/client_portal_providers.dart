import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../data/datasources/client_portal_remote_datasource.dart';
import '../../data/repositories/client_portal_repository_impl.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/client_booking.dart';
import '../../domain/entities/client_report.dart';
import '../../domain/repositories/client_portal_repository.dart';

// ===========================
// Data Layer Providers
// ===========================

final clientPortalRemoteDataSourceProvider =
    Provider<ClientPortalRemoteDataSource>((ref) => ClientPortalRemoteDataSource(ref.watch(apiClientProvider)));

final clientPortalRepositoryProvider = Provider<ClientPortalRepository>((ref) => ClientPortalRepositoryImpl(
    ref.watch(clientPortalRemoteDataSourceProvider),
  ),);

// ===========================
// Auth State
// ===========================

/// F4 FIX: Added isInitializing flag to track async initialization state.
/// This prevents race conditions where the router checks auth before
/// storage-based initialization completes.
class ClientAuthState {
  const ClientAuthState({
    this.client,
    this.isLoading = false,
    this.isInitializing = true, // F4 FIX: Start as initializing
    this.error,
    this.magicLinkSent = false,
  });

  final Client? client;
  final bool isLoading;
  /// F4 FIX: True while async initialization from storage is in progress.
  /// Router should wait for this to be false before making redirect decisions.
  final bool isInitializing;
  final String? error;
  final bool magicLinkSent;

  bool get isAuthenticated => client != null;

  ClientAuthState copyWith({
    Client? client,
    bool? isLoading,
    bool? isInitializing,
    String? error,
    bool? magicLinkSent,
  }) => ClientAuthState(
      client: client ?? this.client,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
      magicLinkSent: magicLinkSent ?? this.magicLinkSent,
    );
}

class ClientAuthNotifier extends StateNotifier<ClientAuthState> {
  ClientAuthNotifier(this._repository) : super(const ClientAuthState()) {
    // Initialize from storage on creation
    _initializeFromStorage();
  }

  final ClientPortalRepository _repository;
  String? _refreshToken;

  /// Initialize auth state from stored tokens.
  /// This restores the session on app restart if tokens were previously saved.
  /// F4 FIX: Sets isInitializing=false when complete so router knows state is ready.
  Future<void> _initializeFromStorage() async {
    try {
      final accessToken = await StorageService.getClientAccessToken();
      final refreshToken = await StorageService.getClientRefreshToken();

      if (accessToken != null && refreshToken != null && accessToken.isNotEmpty) {
        _refreshToken = refreshToken;
        // Tokens exist - try to load profile to validate they're still valid
        state = state.copyWith(isLoading: true, isInitializing: true);
        try {
          final client = await _repository.getProfile();
          // F4 FIX: Mark initialization complete with authenticated state
          state = state.copyWith(
            isLoading: false,
            isInitializing: false,
            client: client,
          );
        } catch (e) {
          // Token likely expired or invalid - clear and start fresh
          await _clearTokens();
          // F4 FIX: Mark initialization complete with unauthenticated state
          state = const ClientAuthState(isInitializing: false);
        }
      } else {
        // F4 FIX: No tokens - mark initialization complete
        state = state.copyWith(isInitializing: false);
      }
    } catch (_) {
      // Storage read error - start with clean state
      // F4 FIX: Mark initialization complete even on error
      state = const ClientAuthState(isInitializing: false);
    }
  }

  Future<void> requestMagicLink(String email) async {
    state = state.copyWith(isLoading: true, magicLinkSent: false);
    try {
      await _repository.requestMagicLink(email);
      state = state.copyWith(isLoading: false, magicLinkSent: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> verifyMagicLink(String token) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.verifyMagicLink(token);
      _refreshToken = result.refreshToken;
      await _saveTokens(result.accessToken, result.refreshToken);
      state = state.copyWith(isLoading: false, client: result.client);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      try {
        await _repository.logout(_refreshToken!);
      } catch (_) {
        // Ignore logout errors
      }
    }
    await _clearTokens();
    state = const ClientAuthState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final client = await _repository.getProfile();
      state = state.copyWith(isLoading: false, client: client);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void resetMagicLinkSent() {
    state = state.copyWith(magicLinkSent: false);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await StorageService.setClientAccessToken(accessToken);
    await StorageService.setClientRefreshToken(refreshToken);
  }

  Future<void> _clearTokens() async {
    await StorageService.clearClientAuthData();
  }
}

final clientAuthNotifierProvider =
    StateNotifierProvider<ClientAuthNotifier, ClientAuthState>((ref) => ClientAuthNotifier(ref.watch(clientPortalRepositoryProvider)));

// ===========================
// Bookings State
// ===========================

class ClientBookingsState {
  const ClientBookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
  });

  final List<ClientBooking> bookings;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;

  ClientBookingsState copyWith({
    List<ClientBooking>? bookings,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
  }) => ClientBookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
}

class ClientBookingsNotifier extends StateNotifier<ClientBookingsState> {
  ClientBookingsNotifier(this._repository) : super(const ClientBookingsState());

  final ClientPortalRepository _repository;

  Future<void> loadBookings({ClientBookingStatus? status}) async {
    state = state.copyWith(isLoading: true, page: 1);
    try {
      final result = await _repository.getBookings(status: status);
      state = state.copyWith(
        bookings: result.bookings,
        isLoading: false,
        hasMore: result.hasMore,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({ClientBookingStatus? status}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.getBookings(
        status: status,
        page: nextPage,
      );
      state = state.copyWith(
        bookings: [...state.bookings, ...result.bookings],
        isLoading: false,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final clientBookingsNotifierProvider =
    StateNotifierProvider<ClientBookingsNotifier, ClientBookingsState>((ref) => ClientBookingsNotifier(ref.watch(clientPortalRepositoryProvider)));

// ===========================
// Reports State
// ===========================

class ClientReportsState {
  const ClientReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
  });

  final List<ClientReport> reports;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;

  ClientReportsState copyWith({
    List<ClientReport>? reports,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? page,
  }) => ClientReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
}

class ClientReportsNotifier extends StateNotifier<ClientReportsState> {
  ClientReportsNotifier(this._repository) : super(const ClientReportsState());

  final ClientPortalRepository _repository;

  Future<void> loadReports() async {
    state = state.copyWith(isLoading: true, page: 1);
    try {
      final result = await _repository.getReports();
      state = state.copyWith(
        reports: result.reports,
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
      final result = await _repository.getReports(page: nextPage);
      state = state.copyWith(
        reports: [...state.reports, ...result.reports],
        isLoading: false,
        hasMore: result.hasMore,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final clientReportsNotifierProvider =
    StateNotifierProvider<ClientReportsNotifier, ClientReportsState>((ref) => ClientReportsNotifier(ref.watch(clientPortalRepositoryProvider)));

// ===========================
// Single Item Providers
// ===========================

/// Provider for individual client booking detail with caching and proper 404 handling.
/// Uses keepAlive to prevent repeated fetches on widget rebuilds.
final clientBookingDetailProvider =
    FutureProvider.autoDispose.family<ClientBooking?, String>((ref, id) async {
  // Keep alive to prevent refetching on every rebuild
  ref.keepAlive();

  // Don't fetch if ID is empty or null-like
  if (id.isEmpty || id == 'null') {
    return null;
  }

  try {
    return await ref.watch(clientPortalRepositoryProvider).getBooking(id);
  } catch (e) {
    // Check if it's a 404 - booking not found is a valid state, not an error to retry
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('404') ||
        errorStr.contains('not found') ||
        errorStr.contains('notfoundexception')) {
      // Return null instead of throwing - booking simply doesn't exist
      return null;
    }
    // Rethrow other errors (network, server, etc.) which are retriable
    rethrow;
  }
});

final clientReportDetailProvider =
    FutureProvider.autoDispose.family<ClientReport, String>((ref, id) => ref.watch(clientPortalRepositoryProvider).getReport(id));
