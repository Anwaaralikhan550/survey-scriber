import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/invoices_remote_datasource.dart';
import '../../data/models/invoice_model.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';

// ===========================
// DATA LAYER PROVIDERS
// ===========================

final invoicesRemoteDataSourceProvider = Provider<InvoicesRemoteDataSource>((ref) => InvoicesRemoteDataSource(ref.watch(apiClientProvider)));

// ===========================
// INVOICES LIST STATE
// ===========================

class InvoicesListState {
  const InvoicesListState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedStatus,
  });

  final List<Invoice> invoices;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final InvoiceStatus? selectedStatus;

  InvoicesListState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    InvoiceStatus? selectedStatus,
    bool clearError = false,
    bool clearStatus = false,
  }) => InvoicesListState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
}

class InvoicesListNotifier extends StateNotifier<InvoicesListState> {
  InvoicesListNotifier(this._dataSource) : super(const InvoicesListState());

  final InvoicesRemoteDataSource _dataSource;

  Future<void> loadInvoices({
    InvoiceStatus? status,
    String? clientId,
    int page = 1,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = const InvoicesListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final response = await _dataSource.getInvoices(
        status: status ?? state.selectedStatus,
        clientId: clientId,
        page: page,
      );

      state = state.copyWith(
        invoices: response.data.map((m) => m.toEntity()).toList(),
        isLoading: false,
        currentPage: response.pagination.page,
        totalPages: response.pagination.totalPages,
        selectedStatus: status,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStatusFilter(InvoiceStatus? status) {
    if (status == state.selectedStatus) return;
    loadInvoices(status: status, refresh: true);
  }

  void clearFilter() {
    state = state.copyWith(clearStatus: true);
    loadInvoices(refresh: true);
  }

  void refresh() {
    loadInvoices(status: state.selectedStatus, refresh: true);
  }
}

final invoicesListNotifierProvider =
    StateNotifierProvider<InvoicesListNotifier, InvoicesListState>((ref) => InvoicesListNotifier(ref.watch(invoicesRemoteDataSourceProvider)));

// ===========================
// SINGLE INVOICE DETAIL
// ===========================

final invoiceDetailProvider = FutureProvider.autoDispose.family<InvoiceDetail, String>((ref, id) async {
  final dataSource = ref.watch(invoicesRemoteDataSourceProvider);
  final model = await dataSource.getInvoice(id);
  return model.toEntity();
});

// ===========================
// INVOICE ACTIONS STATE
// ===========================

class InvoiceActionsState {
  const InvoiceActionsState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final String? error;
  final String? successMessage;

  InvoiceActionsState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) => InvoiceActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
}

class InvoiceActionsNotifier extends StateNotifier<InvoiceActionsState> {
  InvoiceActionsNotifier(this._dataSource, this._ref) : super(const InvoiceActionsState());

  final InvoicesRemoteDataSource _dataSource;
  final Ref _ref;

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<InvoiceDetail?> createInvoice({
    required String clientId,
    String? bookingId,
    required List<InvoiceItemModel> items,
    String? notes,
    double? taxRate,
    String? dueDate,
    String? paymentTerms,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final model = await _dataSource.createInvoice(
        clientId: clientId,
        bookingId: bookingId,
        items: items,
        notes: notes,
        taxRate: taxRate,
        dueDate: dueDate,
        paymentTerms: paymentTerms,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invoice ${model.invoiceNumber} created',
      );
      _ref.invalidate(invoicesListNotifierProvider);
      return model.toEntity();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<InvoiceDetail?> issueInvoice(String id) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final model = await _dataSource.issueInvoice(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invoice issued successfully',
      );
      _ref.invalidate(invoiceDetailProvider(id));
      _ref.invalidate(invoicesListNotifierProvider);
      return model.toEntity();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<InvoiceDetail?> markAsPaid(String id, {String? paidDate}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final model = await _dataSource.markAsPaid(id, paidDate: paidDate);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invoice marked as paid',
      );
      _ref.invalidate(invoiceDetailProvider(id));
      _ref.invalidate(invoicesListNotifierProvider);
      return model.toEntity();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<InvoiceDetail?> cancelInvoice(String id, String reason) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final model = await _dataSource.cancelInvoice(id, reason);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invoice cancelled',
      );
      _ref.invalidate(invoiceDetailProvider(id));
      _ref.invalidate(invoicesListNotifierProvider);
      return model.toEntity();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteInvoice(String id) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _dataSource.deleteInvoice(id);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Invoice deleted',
      );
      _ref.invalidate(invoicesListNotifierProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<List<int>?> downloadPdf(String id) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final bytes = await _dataSource.downloadPdf(id);
      state = state.copyWith(isLoading: false);
      return bytes;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final invoiceActionsNotifierProvider =
    StateNotifierProvider<InvoiceActionsNotifier, InvoiceActionsState>((ref) => InvoiceActionsNotifier(
    ref.watch(invoicesRemoteDataSourceProvider),
    ref,
  ),);
