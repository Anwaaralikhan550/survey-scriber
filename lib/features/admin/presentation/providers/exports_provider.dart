import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/exports_datasource.dart';

// Data source provider
final exportsDataSourceProvider = Provider<ExportsDataSource>(
  (ref) => ExportsDataSourceImpl(ref.watch(dioProvider)),
);

// Export state
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.error,
    this.lastExportedFile,
  });

  final bool isExporting;
  final String? error;
  final String? lastExportedFile;

  ExportState copyWith({
    bool? isExporting,
    String? error,
    String? lastExportedFile,
  }) =>
      ExportState(
        isExporting: isExporting ?? this.isExporting,
        error: error,
        lastExportedFile: lastExportedFile ?? this.lastExportedFile,
      );
}

class ExportsNotifier extends StateNotifier<ExportState> {
  ExportsNotifier(this._dataSource) : super(const ExportState());

  final ExportsDataSource _dataSource;

  /// Export data and trigger share/save dialog
  Future<bool> exportData({
    required ExportEntityType entityType,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int limit = 5000,
  }) async {
    if (state.isExporting) return false;

    state = state.copyWith(isExporting: true);

    try {
      final params = ExportQueryParams(
        startDate: startDate,
        endDate: endDate,
        status: status,
        limit: limit,
      );

      final ExportResult result;

      switch (entityType) {
        case ExportEntityType.bookings:
          result = await _dataSource.exportBookings(params);
        case ExportEntityType.invoices:
          result = await _dataSource.exportInvoices(params);
        case ExportEntityType.reports:
          result = await _dataSource.exportReports(params);
      }

      // Save to temp directory and share
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${result.filename}');
      await file.writeAsBytes(result.data);

      // Trigger share dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exported ${entityType.name}',
        subject: result.filename,
      );

      state = state.copyWith(
        isExporting: false,
        lastExportedFile: result.filename,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: _parseError(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith();
  }

  String _parseError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('403')) {
      return 'Access denied. Admin or Manager role required.';
    }
    if (errorStr.contains('401')) {
      return 'Session expired. Please log in again.';
    }
    if (errorStr.contains('timeout') || errorStr.contains('Timeout')) {
      return 'Request timed out. Try reducing the date range or limit.';
    }
    return 'Export failed. Please try again.';
  }
}

final exportsProvider = StateNotifierProvider<ExportsNotifier, ExportState>(
  (ref) => ExportsNotifier(ref.watch(exportsDataSourceProvider)),
);
