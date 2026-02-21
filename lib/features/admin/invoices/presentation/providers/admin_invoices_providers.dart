import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../invoices/data/datasources/invoices_remote_datasource.dart';
import '../../../../invoices/data/models/invoice_model.dart';
import '../../../../invoices/domain/entities/invoice.dart';
import '../../../../invoices/domain/entities/invoice_status.dart';
import '../../../../scheduling/data/datasources/scheduling_remote_datasource.dart';
import '../../../../scheduling/domain/entities/booking.dart';

// ===========================
// DATA LAYER PROVIDERS
// ===========================

final adminInvoicesDataSourceProvider = Provider<InvoicesRemoteDataSource>((ref) => InvoicesRemoteDataSource(ref.watch(apiClientProvider)));

final adminSchedulingDataSourceProvider = Provider<SchedulingRemoteDataSource>((ref) => SchedulingRemoteDataSource(ref.watch(apiClientProvider)));

// ===========================
// ADMIN INVOICES LIST STATE
// ===========================

class AdminInvoicesListState {
  const AdminInvoicesListState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.selectedStatus,
  });

  final List<Invoice> invoices;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int total;
  final InvoiceStatus? selectedStatus;

  bool get hasMore => currentPage < totalPages;

  AdminInvoicesListState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? total,
    InvoiceStatus? selectedStatus,
    bool clearError = false,
    bool clearStatus = false,
  }) => AdminInvoicesListState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
}

class AdminInvoicesListNotifier extends StateNotifier<AdminInvoicesListState> {
  AdminInvoicesListNotifier(this._dataSource) : super(const AdminInvoicesListState());

  final InvoicesRemoteDataSource _dataSource;

  Future<void> loadInvoices({
    InvoiceStatus? status,
    int page = 1,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    if (refresh) {
      state = AdminInvoicesListState(
        isLoading: true,
        selectedStatus: status,
      );
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final response = await _dataSource.getInvoices(
        status: status ?? state.selectedStatus,
        page: page,
      );

      state = state.copyWith(
        invoices: response.data.map((m) => m.toEntity()).toList(),
        isLoading: false,
        currentPage: response.pagination.page,
        totalPages: response.pagination.totalPages,
        total: response.pagination.total,
        selectedStatus: status ?? state.selectedStatus,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
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

  Future<void> refresh() async {
    await loadInvoices(status: state.selectedStatus, refresh: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadInvoices(page: state.currentPage + 1);
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('401')) return 'Unauthorized access';
    if (errorStr.contains('403')) return 'You don\'t have permission';
    if (errorStr.contains('404')) return 'Resource not found';
    if (errorStr.contains('500')) return 'Server error. Please try again.';
    return 'Failed to load invoices';
  }
}

final adminInvoicesListProvider =
    StateNotifierProvider<AdminInvoicesListNotifier, AdminInvoicesListState>((ref) => AdminInvoicesListNotifier(ref.watch(adminInvoicesDataSourceProvider)));

// ===========================
// ADMIN INVOICE DETAIL STATE
// ===========================

class AdminInvoiceDetailState {
  const AdminInvoiceDetailState({
    this.invoice,
    this.isLoading = false,
    this.isActioning = false,
    this.error,
    this.actionSuccess,
  });

  final InvoiceDetail? invoice;
  final bool isLoading;
  final bool isActioning;
  final String? error;
  final String? actionSuccess;

  AdminInvoiceDetailState copyWith({
    InvoiceDetail? invoice,
    bool? isLoading,
    bool? isActioning,
    String? error,
    String? actionSuccess,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearInvoice = false,
  }) => AdminInvoiceDetailState(
      invoice: clearInvoice ? null : (invoice ?? this.invoice),
      isLoading: isLoading ?? this.isLoading,
      isActioning: isActioning ?? this.isActioning,
      error: clearError ? null : (error ?? this.error),
      actionSuccess: clearSuccess ? null : (actionSuccess ?? this.actionSuccess),
    );
}

class AdminInvoiceDetailNotifier extends StateNotifier<AdminInvoiceDetailState> {
  AdminInvoiceDetailNotifier(this._dataSource, this._ref)
      : super(const AdminInvoiceDetailState());

  final InvoicesRemoteDataSource _dataSource;
  final Ref _ref;

  Future<void> loadInvoice(String id) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final model = await _dataSource.getInvoice(id);
      state = state.copyWith(
        invoice: model.toEntity(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  Future<bool> issueInvoice() async {
    final invoice = state.invoice;
    if (invoice == null) return false;

    state = state.copyWith(isActioning: true, clearError: true, clearSuccess: true);

    try {
      final model = await _dataSource.issueInvoice(invoice.id);
      state = state.copyWith(
        invoice: model.toEntity(),
        isActioning: false,
        actionSuccess: 'Invoice issued successfully',
      );
      _ref.invalidate(adminInvoicesListProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActioning: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> markAsPaid({String? paidDate}) async {
    final invoice = state.invoice;
    if (invoice == null) return false;

    state = state.copyWith(isActioning: true, clearError: true, clearSuccess: true);

    try {
      final model = await _dataSource.markAsPaid(invoice.id, paidDate: paidDate);
      state = state.copyWith(
        invoice: model.toEntity(),
        isActioning: false,
        actionSuccess: 'Invoice marked as paid',
      );
      _ref.invalidate(adminInvoicesListProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActioning: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> cancelInvoice(String reason) async {
    final invoice = state.invoice;
    if (invoice == null) return false;

    state = state.copyWith(isActioning: true, clearError: true, clearSuccess: true);

    try {
      final model = await _dataSource.cancelInvoice(invoice.id, reason);
      state = state.copyWith(
        invoice: model.toEntity(),
        isActioning: false,
        actionSuccess: 'Invoice cancelled',
      );
      _ref.invalidate(adminInvoicesListProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActioning: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  Future<File?> downloadPdf() async {
    final invoice = state.invoice;
    if (invoice == null) return null;

    state = state.copyWith(isActioning: true, clearError: true, clearSuccess: true);

    try {
      final bytes = await _dataSource.downloadPdf(invoice.id);

      // Save to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/invoice_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);

      state = state.copyWith(isActioning: false);
      return file;
    } catch (e) {
      state = state.copyWith(
        isActioning: false,
        error: 'Failed to download PDF',
      );
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('401')) return 'Unauthorized access';
    if (errorStr.contains('403')) return 'You don\'t have permission';
    if (errorStr.contains('404')) return 'Invoice not found';
    if (errorStr.contains('409')) return 'Invalid operation for this invoice status';
    if (errorStr.contains('500')) return 'Server error. Please try again.';
    return 'An error occurred';
  }
}

final adminInvoiceDetailProvider =
    StateNotifierProvider.autoDispose<AdminInvoiceDetailNotifier, AdminInvoiceDetailState>((ref) => AdminInvoiceDetailNotifier(
    ref.watch(adminInvoicesDataSourceProvider),
    ref,
  ),);

// ===========================
// CREATE INVOICE STATE
// ===========================

class CreateInvoiceLineItem {
  const CreateInvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String description;
  final int quantity;
  final int unitPrice; // in pence

  int get amount => quantity * unitPrice;

  CreateInvoiceLineItem copyWith({
    String? description,
    int? quantity,
    int? unitPrice,
  }) => CreateInvoiceLineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );

  InvoiceItemModel toModel() => InvoiceItemModel(
      id: '', // Will be assigned by backend
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      amount: amount,
    );
}

class CreateInvoiceState {
  const CreateInvoiceState({
    this.selectedBooking,
    this.clientId,
    this.clientName,
    this.clientEmail,
    this.items = const [],
    this.taxRate = 20.0,
    this.notes,
    this.dueDate,
    this.paymentTerms,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.createdInvoice,
    this.availableBookings = const [],
    this.isLoadingBookings = false,
  });

  final Booking? selectedBooking;
  final String? clientId;
  final String? clientName;
  final String? clientEmail;
  final List<CreateInvoiceLineItem> items;
  final double taxRate;
  final String? notes;
  final DateTime? dueDate;
  final String? paymentTerms;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final InvoiceDetail? createdInvoice;
  final List<Booking> availableBookings;
  final bool isLoadingBookings;

  int get subtotal => items.fold(0, (sum, item) => sum + item.amount);
  int get taxAmount => (subtotal * taxRate / 100).round();
  int get total => subtotal + taxAmount;

  bool get canSave =>
      clientId != null &&
      clientId!.isNotEmpty &&
      items.isNotEmpty &&
      items.every((item) => item.description.isNotEmpty && item.quantity > 0);

  CreateInvoiceState copyWith({
    Booking? selectedBooking,
    String? clientId,
    String? clientName,
    String? clientEmail,
    List<CreateInvoiceLineItem>? items,
    double? taxRate,
    String? notes,
    DateTime? dueDate,
    String? paymentTerms,
    bool? isLoading,
    bool? isSaving,
    String? error,
    InvoiceDetail? createdInvoice,
    List<Booking>? availableBookings,
    bool? isLoadingBookings,
    bool clearError = false,
    bool clearBooking = false,
    bool clearCreated = false,
  }) => CreateInvoiceState(
      selectedBooking: clearBooking ? null : (selectedBooking ?? this.selectedBooking),
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      createdInvoice: clearCreated ? null : (createdInvoice ?? this.createdInvoice),
      availableBookings: availableBookings ?? this.availableBookings,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
    );
}

class CreateInvoiceNotifier extends StateNotifier<CreateInvoiceState> {
  CreateInvoiceNotifier(this._invoicesDataSource, this._schedulingDataSource, this._ref)
      : super(const CreateInvoiceState());

  final InvoicesRemoteDataSource _invoicesDataSource;
  final SchedulingRemoteDataSource _schedulingDataSource;
  final Ref _ref;

  Future<void> loadBookings() async {
    state = state.copyWith(isLoadingBookings: true);

    try {
      final response = await _schedulingDataSource.listBookings(
        limit: 100,
      );
      state = state.copyWith(
        availableBookings: response.data.map((m) => m.toEntity()).toList(),
        isLoadingBookings: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingBookings: false);
    }
  }

  void selectBooking(Booking? booking) {
    if (booking == null) {
      state = state.copyWith(
        clearBooking: true,
      );
    } else {
      // When a booking is selected, we use client info from booking
      // Note: The backend may auto-create/link client from booking
      state = state.copyWith(
        selectedBooking: booking,
        clientName: booking.clientName,
        clientEmail: booking.clientEmail,
        // clientId will be set by backend when creating invoice with bookingId
      );
    }
  }

  void setClientInfo({String? id, String? name, String? email}) {
    state = state.copyWith(
      clientId: id,
      clientName: name,
      clientEmail: email,
    );
  }

  void addLineItem() {
    state = state.copyWith(
      items: [
        ...state.items,
        const CreateInvoiceLineItem(
          description: '',
          quantity: 1,
          unitPrice: 0,
        ),
      ],
    );
  }

  void updateLineItem(int index, CreateInvoiceLineItem item) {
    if (index < 0 || index >= state.items.length) return;
    final items = [...state.items];
    items[index] = item;
    state = state.copyWith(items: items);
  }

  void removeLineItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final items = [...state.items];
    items.removeAt(index);
    state = state.copyWith(items: items);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void setDueDate(DateTime? date) {
    state = state.copyWith(dueDate: date);
  }

  void setPaymentTerms(String? terms) {
    state = state.copyWith(paymentTerms: terms);
  }

  Future<bool> createInvoice() async {
    if (!state.canSave && state.selectedBooking == null) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Please add at least one line item');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // Determine clientId - either from manual input or extracted from booking
      var clientId = state.clientId;

      // If no explicit clientId, try to use booking's client email as lookup key
      if ((clientId == null || clientId.isEmpty) && state.selectedBooking != null) {
        // Only use clientEmail as a valid lookup key - not arbitrary strings
        if (state.clientEmail != null && state.clientEmail!.isNotEmpty) {
          clientId = state.clientEmail;
        }
      }

      // Require valid client identification (not placeholder strings)
      if (clientId == null || clientId.isEmpty) {
        state = state.copyWith(
          isSaving: false,
          error: state.selectedBooking != null
              ? 'Booking has no client email. Please select a client manually.'
              : 'Client information is required',
        );
        return false;
      }

      final model = await _invoicesDataSource.createInvoice(
        clientId: clientId,
        bookingId: state.selectedBooking?.id,
        items: state.items.map((e) => e.toModel()).toList(),
        notes: state.notes,
        taxRate: state.taxRate,
        dueDate: state.dueDate?.toIso8601String().split('T').first,
        paymentTerms: state.paymentTerms,
      );

      state = state.copyWith(
        isSaving: false,
        createdInvoice: model.toEntity(),
      );

      _ref.invalidate(adminInvoicesListProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  void reset() {
    state = const CreateInvoiceState();
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('400')) return 'Invalid invoice data';
    if (errorStr.contains('401')) return 'Unauthorized';
    if (errorStr.contains('403')) return 'Permission denied';
    if (errorStr.contains('404')) return 'Client or booking not found';
    if (errorStr.contains('409')) return 'Conflict - invoice may already exist';
    return 'Failed to create invoice';
  }
}

final createInvoiceProvider =
    StateNotifierProvider.autoDispose<CreateInvoiceNotifier, CreateInvoiceState>((ref) => CreateInvoiceNotifier(
    ref.watch(adminInvoicesDataSourceProvider),
    ref.watch(adminSchedulingDataSourceProvider),
    ref,
  ),);
