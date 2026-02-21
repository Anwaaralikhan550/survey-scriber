import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/safe_parsers.dart';
import '../../domain/entities/invoice_status.dart';
import '../models/invoice_model.dart';

class InvoicesRemoteDataSource {
  const InvoicesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  static const _basePath = 'invoices';

  // ===========================
  // LIST & GET
  // ===========================

  Future<InvoiceListResponse> getInvoices({
    InvoiceStatus? status,
    String? clientId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status.toBackendString();
    if (clientId != null) queryParams['clientId'] = clientId;
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;

    final response = await _apiClient.get<Map<String, dynamic>>(
      _basePath,
      queryParameters: queryParams,
    );
    return InvoiceListResponse.fromJson(response.requireData('getInvoices'));
  }

  Future<InvoiceDetailModel> getInvoice(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/$id',
    );
    return InvoiceDetailModel.fromJson(response.requireData('getInvoice'));
  }

  // ===========================
  // CREATE & UPDATE
  // ===========================

  Future<InvoiceDetailModel> createInvoice({
    required String clientId,
    String? bookingId,
    required List<InvoiceItemModel> items,
    String? notes,
    double? taxRate,
    String? dueDate,
    String? paymentTerms,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _basePath,
      data: {
        'clientId': clientId,
        if (bookingId != null) 'bookingId': bookingId,
        'items': items.map((e) => e.toJson()).toList(),
        if (notes != null) 'notes': notes,
        if (taxRate != null) 'taxRate': taxRate,
        if (dueDate != null) 'dueDate': dueDate,
        if (paymentTerms != null) 'paymentTerms': paymentTerms,
      },
    );
    return InvoiceDetailModel.fromJson(response.requireData('createInvoice'));
  }

  Future<InvoiceDetailModel> updateInvoice(
    String id, {
    List<InvoiceItemModel>? items,
    String? notes,
    double? taxRate,
    String? dueDate,
    String? paymentTerms,
  }) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '$_basePath/$id',
      data: {
        if (items != null) 'items': items.map((e) => e.toJson()).toList(),
        if (notes != null) 'notes': notes,
        if (taxRate != null) 'taxRate': taxRate,
        if (dueDate != null) 'dueDate': dueDate,
        if (paymentTerms != null) 'paymentTerms': paymentTerms,
      },
    );
    return InvoiceDetailModel.fromJson(response.requireData('updateInvoice'));
  }

  Future<void> deleteInvoice(String id) async {
    await _apiClient.delete('$_basePath/$id');
  }

  // ===========================
  // STATUS ACTIONS
  // ===========================

  Future<InvoiceDetailModel> issueInvoice(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/$id/issue',
    );
    return InvoiceDetailModel.fromJson(response.requireData('issueInvoice'));
  }

  Future<InvoiceDetailModel> markAsPaid(String id, {String? paidDate}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/$id/mark-paid',
      data: {
        if (paidDate != null) 'paidDate': paidDate,
      },
    );
    return InvoiceDetailModel.fromJson(response.requireData('markAsPaid'));
  }

  Future<InvoiceDetailModel> cancelInvoice(String id, String reason) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/$id/cancel',
      data: {'reason': reason},
    );
    return InvoiceDetailModel.fromJson(response.requireData('cancelInvoice'));
  }

  // ===========================
  // PDF DOWNLOAD
  // ===========================

  Future<List<int>> downloadPdf(String id) async {
    final response = await _apiClient.get<List<int>>(
      '$_basePath/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.requireData('downloadPdf');
  }

  // ===========================
  // CLIENT PORTAL METHODS
  // ===========================

  Future<InvoiceListResponse> getClientInvoices({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'client/invoices',
      queryParameters: {'page': page, 'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return InvoiceListResponse.fromJson(response.requireData('getClientInvoices'));
  }

  Future<InvoiceDetailModel> getClientInvoiceById(
    String id, {
    required String token,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      'client/invoices/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return InvoiceDetailModel.fromJson(response.requireData('getClientInvoiceById'));
  }
}
