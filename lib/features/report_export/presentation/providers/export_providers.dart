import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/services/pdf_upload_service.dart';
import '../../../ai/presentation/providers/ai_inspection_providers.dart';
import '../../../property_inspection/presentation/providers/inspection_providers.dart';
import '../../../property_valuation/presentation/providers/valuation_providers.dart';
import '../../data/services/export_service.dart';
import '../../data/services/report_builder.dart';
import '../../data/services/report_data_service.dart';
import '../../domain/models/export_config.dart';

// ── PDF upload provider (moved from deleted pdf_export_provider.dart) ─────

final pdfUploadServiceProvider = Provider<PdfUploadService>((ref) {
  return PdfUploadService(ref.watch(apiClientProvider));
});

// ── Service providers ────────────────────────────────────────────────

final reportDataServiceProvider = Provider<ReportDataService>((ref) {
  return ReportDataService(
    inspectionRepo: ref.watch(inspectionRepositoryProvider),
    valuationRepo: ref.watch(valuationRepositoryProvider),
    surveysDao: ref.watch(surveysDaoProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    signatureDao: ref.watch(signatureDaoProvider),
  );
});

final reportBuilderProvider = Provider<ReportBuilder>((ref) {
  return ReportBuilder(
    inspectionPhraseEngine: ref.watch(inspectionPhraseEngineProvider),
    valuationPhraseEngine: ref.watch(valuationPhraseEngineProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    dataService: ref.watch(reportDataServiceProvider),
    builder: ref.watch(reportBuilderProvider),
    reportsDao: ref.watch(generatedReportsDaoProvider),
    uploadService: ref.watch(pdfUploadServiceProvider),
    syncManager: ref.watch(syncManagerProvider),
    aiClient: ref.watch(aiInspectionClientProvider),
    piiRedactor: ref.watch(piiRedactorProvider),
    recommendationsDao: ref.watch(surveyRecommendationsDaoProvider),
  );
});

// ── State ────────────────────────────────────────────────────────────

class ExportState {
  const ExportState({
    this.isExporting = false,
    this.progress,
    this.result,
    this.errorMessage,
  });

  final bool isExporting;
  final ExportProgress? progress;
  final ExportResult? result;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get isComplete => result != null;

  ExportState copyWith({
    bool? isExporting,
    ExportProgress? progress,
    ExportResult? result,
    String? errorMessage,
  }) =>
      ExportState(
        isExporting: isExporting ?? this.isExporting,
        progress: progress ?? this.progress,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────

class ExportNotifier extends StateNotifier<ExportState> {
  ExportNotifier(this._ref) : super(const ExportState());

  final Ref _ref;
  bool _cancelled = false;

  /// Read the export service on demand (lazy).
  ///
  /// This is intentionally NOT passed via constructor + ref.watch because
  /// [exportServiceProvider] has a deep dependency chain (8+ providers
  /// including a FutureProvider for phrase texts).  When ANY dependency
  /// stabilises after async init — auth token loading, phrase text asset
  /// loading, database init — ref.watch would invalidate this notifier,
  /// destroying in-flight export state and causing the "Preparing..." hang
  /// on first tap after app open.  Reading on demand breaks the chain.
  ExportService get _exportService => _ref.read(exportServiceProvider);

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  void _setState(ExportState newState) {
    if (mounted) state = newState;
  }

  void _updateState(ExportState Function(ExportState) updater) {
    if (mounted) state = updater(state);
  }

  Future<String?> exportInspection(
    String surveyId, {
    ExportConfig config = const ExportConfig(),
  }) async {
    return _export(
      () => _exportService.exportInspection(
        surveyId,
        config,
        onProgress: (p) => _updateState((s) => s.copyWith(progress: p)),
      ),
    );
  }

  Future<String?> exportValuation(
    String surveyId, {
    ExportConfig config = const ExportConfig(),
  }) async {
    return _export(
      () => _exportService.exportValuation(
        surveyId,
        config,
        onProgress: (p) => _updateState((s) => s.copyWith(progress: p)),
      ),
    );
  }

  Future<String?> _export(Future<ExportResult> Function() doExport) async {
    if (state.isExporting) return null;

    _cancelled = false;
    _setState(const ExportState(isExporting: true));

    try {
      final result = await doExport();
      if (_cancelled) return result.outputPath;

      _setState(ExportState(result: result));
      return result.outputPath;
    } catch (e) {
      AppLogger.e('Export', 'Export failed: $e');
      final hint = e.toString();
      final message = hint.contains("won't fit") || hint.contains('exceed a page')
          ? 'Report content too large for a single page. '
            'Please try reducing AI narrative length or splitting sections.'
          : hint.contains('timeout') || hint.contains('Timeout')
              ? 'Export timed out. Please check your connection and try again.'
              : hint.contains('No space') || hint.contains('storage')
                  ? 'Not enough storage space to generate the report.'
                  : 'Failed to export report. Please try again.';
      _setState(ExportState(errorMessage: message));
      return null;
    } finally {
      // Guarantee loading state is reset even if _setState was skipped
      // (e.g. notifier disposed during async export).
      if (mounted && state.isExporting) {
        _setState(const ExportState(
          errorMessage: 'Export interrupted unexpectedly.',
        ));
      }
    }
  }

  void reset() => _setState(const ExportState());
}

// ── Provider ─────────────────────────────────────────────────────────

// Not autoDispose — the export is a long-running operation that must survive
// navigation transitions (bottom sheet pop → dialog mount).  The dialog calls
// reset() explicitly before each new export to ensure a clean state.
//
// Uses ref (not ref.watch(exportServiceProvider)) so the notifier is NEVER
// invalidated by upstream dependency changes during an in-flight export.
// See ExportNotifier._exportService getter for full explanation.
final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  return ExportNotifier(ref);
});
