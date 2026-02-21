import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/daos/generated_reports_dao.dart';
import '../../../../core/database/database_providers.dart';
import '../../domain/models/generated_report.dart';

/// State for PDF history list.
class PdfHistoryState {
  const PdfHistoryState({
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<GeneratedReport> reports;
  final bool isLoading;
  final String? errorMessage;

  PdfHistoryState copyWith({
    List<GeneratedReport>? reports,
    bool? isLoading,
    String? errorMessage,
  }) =>
      PdfHistoryState(
        reports: reports ?? this.reports,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

/// Provider for PDF history.
final pdfHistoryProvider =
    StateNotifierProvider.autoDispose<PdfHistoryNotifier, PdfHistoryState>(
        (ref) {
  final dao = ref.watch(generatedReportsDaoProvider);
  return PdfHistoryNotifier(dao: dao);
});

/// Notifier for managing PDF history state.
class PdfHistoryNotifier extends StateNotifier<PdfHistoryState> {
  PdfHistoryNotifier({required this.dao})
      : super(const PdfHistoryState(isLoading: true)) {
    _load();
  }

  final GeneratedReportsDao dao;

  Future<void> _load() async {
    try {
      state = state.copyWith(isLoading: true);
      final data = await dao.getAllReports();
      final reports = data
          .map((d) => GeneratedReport(
                id: d.id,
                surveyId: d.surveyId,
                surveyTitle: d.surveyTitle,
                filePath: d.filePath,
                fileName: d.fileName,
                sizeBytes: d.sizeBytes,
                generatedAt: d.generatedAt,
                moduleType: d.moduleType,
                format: d.format,
                remoteUrl: d.remoteUrl,
                checksum: d.checksum,
              ),)
          .toList();
      state = PdfHistoryState(reports: reports);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load reports: $e',
      );
    }
  }

  /// Delete a report (removes DB record and file).
  Future<void> deleteReport(String reportId) async {
    try {
      final report = state.reports.firstWhere((r) => r.id == reportId);

      // Delete file.
      final file = File(report.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete DB record.
      await dao.deleteReport(reportId);

      state = state.copyWith(
        reports: state.reports.where((r) => r.id != reportId).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete report: $e');
    }
  }

  /// Open a report PDF for viewing/printing.
  Future<void> openReport(GeneratedReport report) async {
    try {
      final file = File(report.filePath);
      if (!await file.exists()) {
        state = state.copyWith(errorMessage: 'PDF file not found on device');
        return;
      }
      final bytes = await file.readAsBytes();
      await Printing.sharePdf(bytes: bytes, filename: report.fileName);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to open report: $e');
    }
  }

  /// Share a report PDF.
  Future<void> shareReport(GeneratedReport report) async {
    try {
      final file = File(report.filePath);
      if (!await file.exists()) {
        state = state.copyWith(errorMessage: 'PDF file not found on device');
        return;
      }
      await Share.shareXFiles(
        [XFile(report.filePath)],
        subject: 'Survey Report - ${report.surveyTitle}',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to share report: $e');
    }
  }

  /// Refresh the list.
  Future<void> refresh() async => _load();

  void clearError() {
    state = state.copyWith();
  }
}
