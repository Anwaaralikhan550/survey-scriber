import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Export entity types
enum ExportEntityType {
  bookings,
  invoices,
  reports,
}

/// Query parameters for export requests
class ExportQueryParams {
  const ExportQueryParams({
    this.startDate,
    this.endDate,
    this.status,
    this.limit = 5000,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;
  final int limit;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'limit': limit.toString(),
    };

    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String().split('T')[0];
    }
    if (status != null && status!.isNotEmpty) {
      params['status'] = status;
    }

    return params;
  }
}

/// Result of an export operation
class ExportResult {
  const ExportResult({
    required this.data,
    required this.filename,
  });

  final Uint8List data;
  final String filename;
}

/// Data source for export API calls
abstract class ExportsDataSource {
  /// Export bookings to CSV
  Future<ExportResult> exportBookings(ExportQueryParams params);

  /// Export invoices to CSV
  Future<ExportResult> exportInvoices(ExportQueryParams params);

  /// Export reports to CSV
  Future<ExportResult> exportReports(ExportQueryParams params);
}

class ExportsDataSourceImpl implements ExportsDataSource {
  const ExportsDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ExportResult> exportBookings(ExportQueryParams params) =>
      _downloadExport('exports/bookings', params, 'bookings');

  @override
  Future<ExportResult> exportInvoices(ExportQueryParams params) =>
      _downloadExport('exports/invoices', params, 'invoices');

  @override
  Future<ExportResult> exportReports(ExportQueryParams params) =>
      _downloadExport('exports/reports', params, 'reports');

  Future<ExportResult> _downloadExport(
    String endpoint,
    ExportQueryParams params,
    String filenamePrefix,
  ) async {
    final response = await _dio.get<List<int>>(
      endpoint,
      queryParameters: params.toQueryParams(),
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'text/csv',
        },
      ),
    );

    // Extract filename from Content-Disposition header or generate one
    final contentDisposition = response.headers['content-disposition']?.first;
    String filename;

    if (contentDisposition != null && contentDisposition.contains('filename=')) {
      // Parse filename from header: attachment; filename="bookings_2024-01-15.csv"
      final match = RegExp('filename="?([^"]+)"?').firstMatch(contentDisposition);
      filename = match?.group(1) ?? _generateFilename(filenamePrefix);
    } else {
      filename = _generateFilename(filenamePrefix);
    }

    return ExportResult(
      data: Uint8List.fromList(response.data!),
      filename: filename,
    );
  }

  String _generateFilename(String prefix) {
    final date = DateTime.now().toIso8601String().split('T')[0];
    return '${prefix}_$date.csv';
  }
}
