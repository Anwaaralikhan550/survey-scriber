import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ai/pii_redactor.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/generated_reports_dao.dart';
import '../../../../core/database/daos/survey_recommendations_dao.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/presentation/widgets/survey_duration_timer.dart';
import '../../../ai/domain/services/ai_client.dart';
import '../../../../../../../shared/services/pdf_upload_service.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import 'docx_generator_service.dart';
import 'pdf_generator_service.dart';
import 'report_builder.dart';
import 'report_data_service.dart';

/// Orchestrates the full V2 export pipeline:
/// load data -> build document -> render (PDF/DOCX) -> save record -> upload.
class ExportService {
  ExportService({
    required this.dataService,
    required this.builder,
    required this.reportsDao,
    required this.uploadService,
    required this.syncManager,
    this.aiClient,
    this.piiRedactor,
    this.recommendationsDao,
  });

  final ReportDataService dataService;
  final ReportBuilder builder;
  final GeneratedReportsDao reportsDao;
  final PdfUploadService uploadService;
  final SyncManager syncManager;

  /// Optional AI client — only used when config.includeAiNarrative is true.
  final AiInspectionClient? aiClient;

  /// PII redactor for un-redacting AI responses before embedding in report.
  final PiiRedactor? piiRedactor;

  /// Optional DAO for loading accepted professional recommendations.
  final SurveyRecommendationsDao? recommendationsDao;

  /// Export an Inspection survey.
  Future<ExportResult> exportInspection(
    String surveyId,
    ExportConfig config, {
    void Function(ExportProgress)? onProgress,
  }) async {
    _lastAiWarning = null;

    onProgress?.call(const ExportProgress(
      stage: 'Loading', percent: 0.05, message: 'Loading survey data...'));

    final rawData = await dataService.loadInspectionData(surveyId);

    onProgress?.call(const ExportProgress(
      stage: 'Building', percent: 0.20, message: 'Building report...'));

    final duration = await _readTimerDuration(surveyId);
    var document = builder.build(rawData, config, surveyDuration: duration);

    if (config.includeAiNarrative) {
      document = await _enrichWithAi(document, rawData, onProgress);
    }

    if (config.includeRecommendations) {
      document = await _attachRecommendations(surveyId, document);
    }

    return _renderAndSave(surveyId, document, config, onProgress);
  }

  /// Export a Valuation survey.
  Future<ExportResult> exportValuation(
    String surveyId,
    ExportConfig config, {
    void Function(ExportProgress)? onProgress,
  }) async {
    _lastAiWarning = null;

    onProgress?.call(const ExportProgress(
      stage: 'Loading', percent: 0.05, message: 'Loading survey data...'));

    final rawData = await dataService.loadValuationData(surveyId);

    onProgress?.call(const ExportProgress(
      stage: 'Building', percent: 0.20, message: 'Building report...'));

    final duration = await _readTimerDuration(surveyId);
    var document = builder.build(rawData, config, surveyDuration: duration);

    if (config.includeAiNarrative) {
      document = await _enrichWithAi(document, rawData, onProgress);
    }

    if (config.includeRecommendations) {
      document = await _attachRecommendations(surveyId, document);
    }

    return _renderAndSave(surveyId, document, config, onProgress);
  }

  /// Maximum number of AI retry attempts (initial + retries).
  static const _maxAiAttempts = 3;

  /// Base delay for exponential backoff between AI retries.
  static const _aiRetryBaseDelay = Duration(seconds: 2);

  /// Call AI to generate executive summary + section narratives, then
  /// produce a new [ReportDocument] with AI fields populated.
  ///
  /// Retries up to [_maxAiAttempts] times with exponential backoff.
  /// On final failure, returns the original document without AI content
  /// and sets [_lastAiWarning] so the caller can surface a warning.
  Future<ReportDocument> _enrichWithAi(
    ReportDocument document,
    V2RawReportData rawData,
    void Function(ExportProgress)? onProgress,
  ) async {
    if (aiClient == null) {
      _lastAiWarning = 'AI client not available. Report generated without AI.';
      return document;
    }

    for (var attempt = 1; attempt <= _maxAiAttempts; attempt++) {
      final isLastAttempt = attempt == _maxAiAttempts;

      onProgress?.call(ExportProgress(
        stage: 'AI',
        percent: 0.30,
        message: attempt == 1
            ? 'Generating AI narrative...'
            : 'Retrying AI generation (attempt $attempt/$_maxAiAttempts)...',
      ));

      try {
        final result = await aiClient!.generateReport(
          surveyId: rawData.survey.id,
          survey: rawData.survey,
          tree: rawData.tree,
          allAnswers: rawData.allAnswers,
        );

        final response = result.response;
        final mapping = result.redactionMapping;

        onProgress?.call(const ExportProgress(
          stage: 'AI', percent: 0.40, message: 'Processing AI response...'));

        // Un-redact AI text so the exported report contains real names/addresses.
        final redactor = piiRedactor ?? PiiRedactor();
        final executiveSummary = redactor.unredact(
          response.executiveSummary,
          mapping,
        );

        final sectionNarratives = <String, String>{};
        for (final sn in response.sections) {
          sectionNarratives[sn.sectionId] = redactor.unredact(
            sn.narrative,
            mapping,
          );
        }

        onProgress?.call(const ExportProgress(
          stage: 'AI', percent: 0.45, message: 'AI narrative complete'));

        _lastAiWarning = null;
        return document.copyWith(
          aiExecutiveSummary: executiveSummary,
          aiSectionNarratives: sectionNarratives,
          aiDisclaimer: response.disclaimer,
        );
      } catch (e) {
        AppLogger.w('Export',
            'AI enrichment attempt $attempt/$_maxAiAttempts failed: $e');

        if (isLastAttempt) {
          // All retries exhausted — fall back to non-AI export.
          _lastAiWarning =
              'AI narrative could not be generated. Report exported without AI content.';
          onProgress?.call(const ExportProgress(
            stage: 'AI',
            percent: 0.45,
            message: 'AI unavailable — continuing without AI...',
          ));
          return document;
        }

        // Exponential backoff before next attempt.
        final delay = _aiRetryBaseDelay * (1 << (attempt - 1));
        onProgress?.call(ExportProgress(
          stage: 'AI',
          percent: 0.30,
          message: 'AI generation failed. Retrying in ${delay.inSeconds}s...',
        ));
        await Future<void>.delayed(delay);
      }
    }

    // Should not be reached but ensures compilation.
    return document;
  }

  /// Load accepted professional recommendations and attach to document.
  Future<ReportDocument> _attachRecommendations(
    String surveyId,
    ReportDocument document,
  ) async {
    if (recommendationsDao == null) return document;
    try {
      final rows = await recommendationsDao!.getAcceptedBySurvey(surveyId);
      if (rows.isEmpty) return document;

      // Build screenId → title map from document
      final screenTitles = <String, String>{};
      for (final section in document.sections) {
        for (final screen in section.screens) {
          screenTitles[screen.screenId] = screen.title;
        }
      }

      const categoryNames = {
        'compliance': 'Compliance',
        'narrativeStrength': 'Narrative Strength',
        'riskClarification': 'Risk Clarification',
        'dataGaps': 'Data Gaps',
        'valuationJustification': 'Valuation Justification',
      };

      const severityNames = {
        'high': 'High',
        'moderate': 'Moderate',
        'low': 'Low',
      };

      final items = rows
          .map((r) => ReportRecommendationItem(
                category: categoryNames[r.category] ?? r.category,
                severity: severityNames[r.severity] ?? r.severity,
                screenTitle: screenTitles[r.screenId] ?? r.screenId,
                reason: r.reason,
                suggestedText: r.suggestedText,
                source: r.sourceType,
                auditHash: r.auditHash,
              ))
          .toList();

      AppLogger.d('Export',
          'Attached ${items.length} accepted recommendations to report');
      return document.copyWith(recommendationItems: items);
    } catch (e) {
      AppLogger.w('Export', 'Failed to load recommendations: $e');
      return document;
    }
  }

  /// Read accumulated timer seconds from SharedPreferences.
  Future<Duration?> _readTimerDuration(String surveyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt(SurveyDurationTimer.accumulatedSecondsKey(surveyId));
      if (seconds != null && seconds > 0) return Duration(seconds: seconds);
    } catch (_) {
      // Timer data is optional — don't block export
    }
    return null;
  }

  /// Warning from the last AI enrichment attempt, if it failed.
  String? _lastAiWarning;

  Future<ExportResult> _renderAndSave(
    String surveyId,
    ReportDocument document,
    ExportConfig config,
    void Function(ExportProgress)? onProgress,
  ) async {
    GeneratedFileResult generated;

    if (config.format == ExportFormat.pdf) {
      final pdfGen = PdfGeneratorService(config);
      pdfGen.onProgress = onProgress;
      generated = await pdfGen.generatePdf(document);
    } else {
      final docxGen = DocxGeneratorService(config);
      docxGen.onProgress = onProgress;
      generated = await docxGen.generateDocx(document);
    }

    final outputPath = generated.path;

    // Generate report ID and compute checksum from already-available bytes
    // (M6 fix: avoids re-reading the entire file from disk).
    final reportId = const Uuid().v4();
    String checksumHex = '';

    // Save report record to local DB
    try {
      final fileSize = generated.fileSize;
      final fileName = outputPath.split(Platform.pathSeparator).last;
      checksumHex = await compute(_computeSha256, generated.bytes);

      final moduleType = document.reportType == ReportType.valuation
          ? 'valuation'
          : 'inspection';

      await reportsDao.insertReport(GeneratedReportsCompanion.insert(
        id: reportId,
        surveyId: surveyId,
        surveyTitle: Value(document.title),
        filePath: outputPath,
        fileName: fileName,
        sizeBytes: Value(fileSize),
        generatedAt: DateTime.now(),
        moduleType: Value(moduleType),
        format: Value(config.format == ExportFormat.pdf ? 'pdf' : 'docx'),
        style: const Value('premium'),
        checksum: Value(checksumHex),
      ));
    } catch (e) {
      AppLogger.w('Export', 'Failed to save report record: $e');
    }

    // Best-effort upload for PDF only
    var uploaded = false;
    String? remoteUrl;
    String? uploadWarning;
    if (config.format == ExportFormat.pdf) {
      onProgress?.call(const ExportProgress(
        stage: 'Uploading', percent: 0.85, message: 'Syncing survey data...'));

      try {
        // Ensure the survey is fully synced to the server before uploading
        await _ensureSurveySynced(surveyId, onProgress);

        onProgress?.call(const ExportProgress(
          stage: 'Uploading', percent: 0.92, message: 'Uploading PDF...'));

        uploaded = await uploadService.uploadReportPdf(
          surveyId: surveyId,
          pdfPath: outputPath,
        );
      } on SurveyNotFoundOnServerException {
        // Survey still not on server after sync attempt — force resync and retry once
        AppLogger.w('Export',
          'Survey $surveyId not found on server after initial sync. '
          'Force-resyncing and retrying upload...');

        onProgress?.call(const ExportProgress(
          stage: 'Uploading', percent: 0.90, message: 'Syncing survey to server...'));

        try {
          await syncManager.forceResyncSurvey(
            surveyId: surveyId,
            surveyPayload: null, // Let forceResyncSurvey read from local DB
          );
          // S1+S2 fix: use scoped sync (only this survey's items)
          final syncResult = await syncManager.processQueueForSurvey(surveyId);
          if (!syncResult.success) {
            AppLogger.w('Export', 'Force resync failed: ${syncResult.errorMessage}');
            uploadWarning = 'Survey sync failed. Please sync the survey and try uploading again.';
          } else {
            // S1 fix: verify no items remain pending before retrying upload.
            // processQueueForSurvey returning success means zero failures,
            // but items deferred as retryable don't count as failures.
            // A hasPendingSync check confirms the full tree is on the server.
            final stillPending = await syncManager.hasPendingSync(surveyId);
            if (stillPending) {
              AppLogger.w('Export',
                'Survey $surveyId still has pending sync items after force resync. '
                'Skipping upload retry.');
              uploadWarning = 'Survey partially synced. Please sync fully and retry upload from report history.';
            } else {
              onProgress?.call(const ExportProgress(
                stage: 'Uploading', percent: 0.95, message: 'Retrying upload...'));

              uploaded = await uploadService.uploadReportPdf(
                surveyId: surveyId,
                pdfPath: outputPath,
              );
            }
          }
        } catch (retryError) {
          AppLogger.w('Export', 'Retry upload after force resync failed: $retryError');
          uploadWarning = 'Could not upload report. Please sync the survey first.';
        }
      } catch (e) {
        // S3 fix: surface the warning to the user instead of silently swallowing
        AppLogger.w('Export', 'Upload failed (non-fatal): $e');
        uploadWarning = 'Report saved locally but upload failed. You can retry from report history.';
      }

      if (uploaded) {
        remoteUrl = 'surveys/$surveyId/report-pdf';
        try {
          await reportsDao.updateReport(
            reportId,
            GeneratedReportsCompanion(remoteUrl: Value(remoteUrl)),
          );
        } catch (e) {
          AppLogger.w('Export', 'Failed to update remoteUrl: $e');
        }
      }
    }

    onProgress?.call(const ExportProgress(
      stage: 'Complete', percent: 1.0, message: 'Export complete'));

    AppLogger.d('Export',
        'Export complete: ${config.format.name}, '
        '${document.totalScreens} screens, uploaded=$uploaded');

    // Merge AI warning and upload warning into a single message.
    final warnings = [
      if (_lastAiWarning != null) _lastAiWarning!,
      if (uploadWarning != null) uploadWarning,
    ];

    return ExportResult(
      reportId: reportId,
      surveyId: surveyId,
      outputPath: outputPath,
      format: config.format,
      uploadedToBackend: uploaded,
      remoteUrl: remoteUrl,
      warningMessage: warnings.isEmpty ? null : warnings.join(' '),
    );
  }

  /// Ensure the survey and its children are synced to the server.
  ///
  /// Checks if there are any pending sync items for this survey. If so,
  /// processes **only this survey's** sync items (S2 fix: scoped sync)
  /// rather than the entire queue across all surveys.
  ///
  /// This prevents the 404 "Survey not found" error when uploading a PDF
  /// for a survey that was created offline and hasn't been pushed yet.
  Future<void> _ensureSurveySynced(
    String surveyId,
    void Function(ExportProgress)? onProgress,
  ) async {
    final hasPending = await syncManager.hasPendingSync(surveyId);
    if (!hasPending) return;

    AppLogger.d('Export', 'Survey $surveyId has pending sync items — syncing before upload');
    onProgress?.call(const ExportProgress(
      stage: 'Uploading', percent: 0.87, message: 'Syncing survey data...'));

    final result = await syncManager.processQueueForSurvey(surveyId);
    if (result.success) {
      AppLogger.d('Export', 'Pre-upload sync complete: ${result.syncedCount} items synced');
    } else {
      AppLogger.w('Export',
        'Pre-upload sync had failures (${result.failedCount} failed). '
        'Upload will proceed — server may still have the survey from a prior sync.');
    }
  }
}

/// Top-level function for compute() — runs SHA-256 off the main thread.
String _computeSha256(Uint8List bytes) {
  return sha256.convert(bytes).toString();
}
