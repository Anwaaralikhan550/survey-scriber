import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../domain/entities/client_booking.dart';
import '../models/client_booking_model.dart';
import '../models/client_model.dart';
import '../models/client_report_model.dart';

/// Remote data source for Client Portal API
class ClientPortalRemoteDataSource {
  const ClientPortalRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;
  static const _basePath = 'client';

  // ===========================
  // Authentication
  // ===========================

  Future<void> requestMagicLink(String email) async {
    await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/auth/request-magic-link',
      data: {'email': email},
    );
  }

  Future<ClientAuthResponseModel> verifyMagicLink(String token) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/auth/verify',
      queryParameters: {'token': token},
    );
    return ClientAuthResponseModel.fromJson(response.data!);
  }

  Future<ClientAuthResponseModel> refreshToken(String refreshToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return ClientAuthResponseModel.fromJson(response.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<ClientModel> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/auth/me',
    );
    return ClientModel.fromJson(response.data!);
  }

  // ===========================
  // Bookings
  // ===========================

  Future<ClientBookingsResponseModel> getBookings({
    ClientBookingStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status.name.toUpperCase();
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/bookings',
      queryParameters: queryParams,
    );
    return ClientBookingsResponseModel.fromJson(response.data!);
  }

  Future<ClientBookingModel> getBooking(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/bookings/$id',
    );
    return ClientBookingModel.fromJson(response.data!);
  }

  // ===========================
  // Reports
  // ===========================

  Future<ClientReportsResponseModel> getReports({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/reports',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return ClientReportsResponseModel.fromJson(response.data!);
  }

  Future<ClientReportModel> getReport(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/reports/$id',
    );
    return ClientReportModel.fromJson(response.data!);
  }

  /// Download report PDF.
  /// Returns the PDF bytes if available, or null if not yet generated.
  Future<List<int>?> downloadReportPdf(String id) async {
    try {
      final response = await _apiClient.get<List<int>>(
        '$_basePath/reports/$id/download',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      // If 404, PDF not yet available
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  // ===========================
  // Invoices
  // ===========================

  Future<InvoiceListResponse> getInvoices({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/invoices',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return InvoiceListResponse.fromJson(response.data!);
  }

  Future<InvoiceDetailModel> getInvoice(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_basePath/invoices/$id',
    );
    return InvoiceDetailModel.fromJson(response.data!);
  }

  Future<List<int>> downloadInvoicePdf(String id) async {
    final response = await _apiClient.get<List<int>>(
      '$_basePath/invoices/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}
