import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../invoices/domain/entities/invoice.dart';
import '../../data/datasources/client_portal_remote_datasource.dart';
import 'client_portal_providers.dart';

/// State for client invoices list
class ClientInvoicesState {
  const ClientInvoicesState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  final List<Invoice> invoices;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  ClientInvoicesState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) => ClientInvoicesState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
}

/// Notifier for client invoices list
class ClientInvoicesNotifier extends StateNotifier<ClientInvoicesState> {
  ClientInvoicesNotifier(this._datasource) : super(const ClientInvoicesState());

  final ClientPortalRemoteDataSource _datasource;

  static const _pageSize = 20;

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _datasource.getInvoices();

      final invoices = result.data.map((m) => m.toEntity()).toList();
      state = state.copyWith(
        invoices: invoices,
        isLoading: false,
        hasMore: invoices.length >= _pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _datasource.getInvoices(
        page: nextPage,
      );

      final invoices = result.data.map((m) => m.toEntity()).toList();
      state = state.copyWith(
        invoices: [...state.invoices, ...invoices],
        isLoading: false,
        hasMore: invoices.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

/// Provider for client invoices notifier
final clientInvoicesNotifierProvider =
    StateNotifierProvider<ClientInvoicesNotifier, ClientInvoicesState>((ref) {
  final datasource = ref.watch(clientPortalRemoteDataSourceProvider);
  return ClientInvoicesNotifier(datasource);
});

/// Provider for fetching a single client invoice detail
final clientInvoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceDetail, String>((ref, invoiceId) async {
  final datasource = ref.watch(clientPortalRemoteDataSourceProvider);
  final model = await datasource.getInvoice(invoiceId);
  return model.toEntity();
});
