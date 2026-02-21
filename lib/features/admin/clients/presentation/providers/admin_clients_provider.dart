import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client.dart';
import '../../data/models/admin_client_model.dart';

/// State for admin clients list
class AdminClientsState {
  const AdminClientsState({
    this.clients = const [],
    this.filteredClients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedClient,
    this.apiNotAvailable = false,
  });

  final List<AdminClientModel> clients;
  final List<AdminClientModel> filteredClients;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final AdminClientModel? selectedClient;
  final bool apiNotAvailable;

  AdminClientsState copyWith({
    List<AdminClientModel>? clients,
    List<AdminClientModel>? filteredClients,
    bool? isLoading,
    String? error,
    String? searchQuery,
    AdminClientModel? selectedClient,
    bool? apiNotAvailable,
    bool clearError = false,
    bool clearSelectedClient = false,
  }) =>
      AdminClientsState(
        clients: clients ?? this.clients,
        filteredClients: filteredClients ?? this.filteredClients,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        searchQuery: searchQuery ?? this.searchQuery,
        selectedClient:
            clearSelectedClient ? null : (selectedClient ?? this.selectedClient),
        apiNotAvailable: apiNotAvailable ?? this.apiNotAvailable,
      );
}

class AdminClientsNotifier extends StateNotifier<AdminClientsState> {
  AdminClientsNotifier(this._apiClient) : super(const AdminClientsState());

  final ApiClient _apiClient;

  /// Load clients by extracting unique clients from invoices
  /// Note: This is a workaround since no dedicated clients API exists
  Future<void> loadClients() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch invoices to extract client information
      final response = await _apiClient.get<Map<String, dynamic>>(
        'invoices?limit=100',
      );

      final data = response.data!;
      final invoicesData = data['data'] as List<dynamic>? ?? [];

      // Extract unique clients from invoices
      final clientsMap = <String, AdminClientModel>{};
      final clientInvoiceCounts = <String, int>{};

      for (final invoiceJson in invoicesData) {
        final invoice = invoiceJson as Map<String, dynamic>;
        final clientId = invoice['clientId'] as String?;

        if (clientId != null && !clientsMap.containsKey(clientId)) {
          // Basic client info from invoice list
          // Note: Email is not available in invoice list, only clientName
          // Real email is fetched via loadClientDetails()
          final clientName = invoice['clientName'] as String? ?? 'Unknown';
          clientsMap[clientId] = AdminClientModel(
            id: clientId,
            email: '', // Email not available in list view - fetched on detail
            firstName: clientName, // Store clientName as firstName for display
          );
        }

        if (clientId != null) {
          clientInvoiceCounts[clientId] = (clientInvoiceCounts[clientId] ?? 0) + 1;
        }
      }

      // Update invoice counts
      final clients = clientsMap.values.map((client) => client.copyWith(
          invoiceCount: clientInvoiceCounts[client.id] ?? 0,
        ),).toList();

      // Sort by invoice count (most active first)
      clients.sort((a, b) => b.invoiceCount.compareTo(a.invoiceCount));

      state = AdminClientsState(
        clients: clients,
        filteredClients: clients,
        searchQuery: state.searchQuery,
      );

      // Apply any existing search filter
      if (state.searchQuery.isNotEmpty) {
        _applySearch(state.searchQuery);
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('Not Found')) {
        state = state.copyWith(
          isLoading: false,
          apiNotAvailable: true,
          error: 'Client management API is not available. '
              'Displaying clients from invoice data.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _parseError(e),
        );
      }
    }
  }

  /// Load a single client's details
  Future<void> loadClientDetails(String clientId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch invoices for this specific client to get more details
      final response = await _apiClient.get<Map<String, dynamic>>(
        'invoices?clientId=$clientId&limit=1',
      );

      final data = response.data!;
      final invoicesData = data['data'] as List<dynamic>? ?? [];

      if (invoicesData.isEmpty) {
        // Client exists but no invoices - try to find in existing list
        final existingClient = state.clients.firstWhere(
          (c) => c.id == clientId,
          orElse: () => AdminClientModel(id: clientId, email: 'Unknown'),
        );
        state = state.copyWith(
          selectedClient: existingClient,
          isLoading: false,
        );
        return;
      }

      // Get detailed invoice to extract full client info
      final invoiceId = invoicesData[0]['id'] as String;
      final detailResponse = await _apiClient.get<Map<String, dynamic>>(
        'invoices/$invoiceId',
      );

      final invoiceDetail = detailResponse.data!;
      final clientData = invoiceDetail['client'] as Map<String, dynamic>?;

      if (clientData != null) {
        // Count total invoices for this client
        final countResponse = await _apiClient.get<Map<String, dynamic>>(
          'invoices?clientId=$clientId&limit=100',
        );
        final allInvoices = (countResponse.data!['data'] as List<dynamic>?) ?? [];

        final client = AdminClientModel(
          id: clientData['id'] as String,
          email: clientData['email'] as String,
          firstName: clientData['firstName'] as String?,
          lastName: clientData['lastName'] as String?,
          company: clientData['company'] as String?,
          phone: clientData['phone'] as String?,
          invoiceCount: allInvoices.length,
        );

        state = state.copyWith(
          selectedClient: client,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not load client details',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  /// Search clients by name/email
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applySearch(query);
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredClients: state.clients);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = state.clients.where((client) => client.email.toLowerCase().contains(lowerQuery) ||
          client.displayName.toLowerCase().contains(lowerQuery) ||
          (client.company?.toLowerCase().contains(lowerQuery) ?? false) ||
          (client.phone?.contains(query) ?? false),).toList();

    state = state.copyWith(filteredClients: filtered);
  }

  /// Clear selected client
  void clearSelectedClient() {
    state = state.copyWith(clearSelectedClient: true);
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'Access denied. Admin privileges required.';
    }
    if (errorStr.contains('Network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load clients. Please try again.';
  }
}

final adminClientsProvider =
    StateNotifierProvider.autoDispose<AdminClientsNotifier, AdminClientsState>(
  (ref) => AdminClientsNotifier(ref.watch(apiClientProvider)),
);
