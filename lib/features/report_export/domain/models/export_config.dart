import 'dart:typed_data';

import 'package:pdf/pdf.dart';

enum ExportFormat { pdf, docx }

class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.pdf,
    this.pageFormat = PdfPageFormat.a4,
    this.includePhotos = true,
    this.includeSignatures = true,
    this.includeEmptyScreens = false,
    this.includePhrases = true,
    this.includeAiNarrative = false,
    this.includeRecommendations = true,
    this.companyName = 'SurveyScriber',
    this.accentColor = const PdfColor(0.08, 0.38, 0.75), // #1565C0
    this.showPageNumbers = true,
    this.showTableOfContents = true,
  });

  final ExportFormat format;
  final PdfPageFormat pageFormat;
  final bool includePhotos;
  final bool includeSignatures;
  final bool includeEmptyScreens;
  final bool includePhrases;

  /// When true, calls the AI backend to generate an executive summary and
  /// per-section narratives that are embedded in the exported report.
  final bool includeAiNarrative;

  /// When true, includes accepted professional recommendations in the report.
  final bool includeRecommendations;

  final String companyName;
  final PdfColor accentColor;
  final bool showPageNumbers;
  final bool showTableOfContents;

  ExportConfig copyWith({
    ExportFormat? format,
    PdfPageFormat? pageFormat,
    bool? includePhotos,
    bool? includeSignatures,
    bool? includeEmptyScreens,
    bool? includePhrases,
    bool? includeAiNarrative,
    bool? includeRecommendations,
    String? companyName,
    PdfColor? accentColor,
    bool? showPageNumbers,
    bool? showTableOfContents,
  }) =>
      ExportConfig(
        format: format ?? this.format,
        pageFormat: pageFormat ?? this.pageFormat,
        includePhotos: includePhotos ?? this.includePhotos,
        includeSignatures: includeSignatures ?? this.includeSignatures,
        includeEmptyScreens: includeEmptyScreens ?? this.includeEmptyScreens,
        includePhrases: includePhrases ?? this.includePhrases,
        includeAiNarrative: includeAiNarrative ?? this.includeAiNarrative,
        includeRecommendations: includeRecommendations ?? this.includeRecommendations,
        companyName: companyName ?? this.companyName,
        accentColor: accentColor ?? this.accentColor,
        showPageNumbers: showPageNumbers ?? this.showPageNumbers,
        showTableOfContents: showTableOfContents ?? this.showTableOfContents,
      );
}

class ExportProgress {
  const ExportProgress({
    required this.stage,
    required this.percent,
    required this.message,
  });

  final String stage;
  final double percent;
  final String message;
}

/// Result from a PDF or DOCX generator, carrying both the file path and
/// the raw bytes so the caller can compute a checksum without re-reading
/// the file from disk.
class GeneratedFileResult {
  const GeneratedFileResult({
    required this.path,
    required this.bytes,
  });

  final String path;
  final Uint8List bytes;

  int get fileSize => bytes.length;
}

class ExportResult {
  const ExportResult({
    required this.reportId,
    required this.surveyId,
    required this.outputPath,
    required this.format,
    this.uploadedToBackend = false,
    this.remoteUrl,
    this.warningMessage,
  });

  final String reportId;
  final String surveyId;
  final String outputPath;
  final ExportFormat format;
  final bool uploadedToBackend;
  final String? remoteUrl;
  final String? warningMessage;
}
