import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/logger.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import 'pdf_shared_utils.dart';

// ═══════════════════════════════════════════════════════════════════════
//  C1 FIX — Image compression constants
//
//  Photos displayed at 230×180 PDF points are resized to 2× (retina)
//  before embedding.  A 2048×2048 photo decoded as-is consumes ~16 MB
//  of raw bitmap inside the pdf library.  At 460×360 it's ~660 KB — a
//  24× reduction that prevents OOM on mid-range Android devices.
// ═══════════════════════════════════════════════════════════════════════
const _photoTargetWidth = 460;
const _photoTargetHeight = 360;
const _sigTargetWidth = 240;
const _sigTargetHeight = 100;

/// Maximum images to decompress concurrently during pre-loading.
const _imageBatchSize = 5;

// ═══════════════════════════════════════════════════════════════════════
//  C2 FIX — Isolate-safe payload + top-level build function
//
//  pw.Document captures Dart closures (MultiPage.build, Page.build)
//  which makes the object non-transferable across isolate boundaries.
//  Instead of trying to send the Document, we send all *data* to the
//  isolate and construct the entire Document + call save() there.
// ═══════════════════════════════════════════════════════════════════════

/// Isolate-transferable bundle of everything needed to build a PDF.
///
/// All fields are primitives, typed data, or plain Dart data classes
/// whose fields are themselves transferable via [SendPort.send].
class _PdfBuildPayload {
  const _PdfBuildPayload({
    required this.document,
    required this.config,
    required this.imageCache,
    required this.fontData,
  });

  final ReportDocument document;
  final ExportConfig config;
  final Map<String, Uint8List> imageCache;
  final PdfFontDataBundle fontData;
}

/// Top-level function for [compute] — builds the entire PDF off the
/// main thread and returns the raw PDF bytes.
///
/// This eliminates the ANR risk from [pw.Document.save], which performs
/// CPU-intensive layout + serialization that can take 2–10+ seconds for
/// large reports.
Future<Uint8List> _buildPdfIsolate(_PdfBuildPayload payload) async {
  // Reconstruct pw.Font objects from raw TTF bytes inside the isolate.
  final fonts = payload.fontData.toFontBundle();

  // Create a renderer with all data pre-loaded.
  final service = PdfGeneratorService(payload.config);
  service._fonts = fonts;
  service._imageCache = payload.imageCache;

  return service._buildPdfBytes(payload.document);
}

/// Generates a styled PDF from a [ReportDocument].
class PdfGeneratorService {
  PdfGeneratorService(this._config);

  final ExportConfig _config;
  late PdfFontBundle _fonts;

  /// Pre-loaded image bytes keyed by file path.
  Map<String, Uint8List> _imageCache = {};

  /// Sanitises text for PDF rendering.  Delegates to the shared
  /// [PdfSharedUtils.sanitize] (L2 fix: single source of truth).
  @visibleForTesting
  static String sanitize(String text) => PdfSharedUtils.sanitize(text);

  void Function(ExportProgress)? onProgress;

  /// Generate a PDF and return both the file path and raw bytes.
  ///
  /// The heavy work (widget layout + PDF serialization) runs entirely on
  /// a background isolate via [compute], keeping the UI thread responsive.
  ///
  /// Returning the bytes allows the caller to compute checksums without
  /// re-reading the file from disk (M6 fix).
  Future<GeneratedFileResult> generatePdf(ReportDocument doc) async {
    _reportProgress('Loading fonts', 0.05);
    final fontData = await PdfSharedUtils.loadStandardFontData();

    _reportProgress('Pre-loading images', 0.10);
    final imageCache = await _preloadAndCompressImages(doc);

    _reportProgress('Rendering pages', 0.30);

    // ── C2 FIX: Build + save PDF entirely off the main thread ────────
    final payload = _PdfBuildPayload(
      document: doc,
      config: _config,
      imageCache: imageCache,
      fontData: fontData,
    );

    final pdfBytes = await compute(_buildPdfIsolate, payload);

    _reportProgress('Saving file', 0.85);
    final path = await PdfSharedUtils.savePdfBytesToFile(pdfBytes, doc.title);

    _reportProgress('Complete', 1.0);
    AppLogger.d('PdfGen', 'PDF saved: $path (${doc.totalScreens} screens, ${doc.totalFields} fields)');
    return GeneratedFileResult(path: path, bytes: pdfBytes);
  }

  /// Build and serialize the PDF document.  Called from the background
  /// isolate via [_buildPdfIsolate] — must not touch dart:ui or Flutter
  /// bindings.
  Future<Uint8List> _buildPdfBytes(ReportDocument doc) async {
    final pdf = pw.Document(
      title: doc.title,
      author: _config.companyName,
      creator: 'SurveyScriber',
      subject: '${doc.reportType.name} Report - ${doc.surveyMeta.jobRef ?? doc.surveyMeta.surveyId}',
      theme: pw.ThemeData.withFont(
        base: _fonts.base,
        bold: _fonts.bold,
        italic: _fonts.italic,
        fontFallback: _fonts.fallback,
      ),
    );

    final pages = _buildPages(doc);
    for (final page in pages) {
      pdf.addPage(page);
    }

    return await pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  C1 FIX — Image pre-loading with compression
  // ═══════════════════════════════════════════════════════════════════

  /// Pre-load and compress all signature + photo images.
  ///
  /// Photos are resized from their capture resolution (up to 2048×2048)
  /// down to 2× the PDF render dimensions.  This runs on the main thread
  /// using [dart:ui]'s hardware-accelerated platform codec, which is
  /// fast (a few ms per image).  The resized bytes are then sent to the
  /// background isolate for PDF assembly.
  ///
  /// Without this, a 2048×2048 JPEG decoded by the pdf library becomes
  /// ~16 MB of raw RGBA bitmap per image.  At 460×360 it's ~660 KB.
  /// For a 40-photo survey that's 640 MB → 26 MB — well within the
  /// Android 256 MB default heap limit.
  Future<Map<String, Uint8List>> _preloadAndCompressImages(
    ReportDocument doc,
  ) async {
    final cache = <String, Uint8List>{};

    // Collect all paths with their target resize dimensions.
    final entries = <({String path, int maxW, int maxH})>[];

    for (final sig in doc.signatures) {
      if (sig.filePath.isNotEmpty) {
        entries.add((
          path: sig.filePath,
          maxW: _sigTargetWidth,
          maxH: _sigTargetHeight,
        ));
      }
    }

    if (_config.includePhotos) {
      var photoPaths = doc.photoFilePaths;
      if (photoPaths.length > PdfSharedUtils.maxPhotosInPdf) {
        AppLogger.w('PdfGen',
            'Capping photos from ${photoPaths.length} to '
            '${PdfSharedUtils.maxPhotosInPdf} to prevent OOM');
        photoPaths = photoPaths.sublist(0, PdfSharedUtils.maxPhotosInPdf);
      }
      for (final path in photoPaths) {
        entries.add((
          path: path,
          maxW: _photoTargetWidth,
          maxH: _photoTargetHeight,
        ));
      }
    }

    // Process in batches to limit concurrent memory pressure from
    // multiple simultaneous image decodes.
    for (var i = 0; i < entries.length; i += _imageBatchSize) {
      final batch = entries.skip(i).take(_imageBatchSize);
      await Future.wait(batch.map((entry) async {
        try {
          final file = File(entry.path);
          if (!await file.exists()) return;
          final rawBytes = await file.readAsBytes();
          cache[entry.path] = await _compressImageForPdf(
            rawBytes,
            maxWidth: entry.maxW,
            maxHeight: entry.maxH,
          );
        } catch (_) {
          // Skip unreadable files — _tryLoadImage shows a placeholder
        }
      }));
    }

    return cache;
  }

  /// Resize an image to fit within [maxWidth]×[maxHeight] using the
  /// platform's hardware-accelerated image codec.
  ///
  /// [instantiateImageCodec] performs sub-sample decoding for JPEG: it
  /// reads the file header and decodes directly at the reduced resolution
  /// in a single pass, so it's both fast and memory-efficient.
  ///
  /// Returns PNG-encoded bytes of the resized image, or the original
  /// bytes if the image is already small enough or decoding fails.
  static Future<Uint8List> _compressImageForPdf(
    Uint8List inputBytes, {
    required int maxWidth,
    required int maxHeight,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        inputBytes,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // instantiateImageCodec never upscales.  If the decoded image is
      // smaller than the target on both axes, the original was already
      // within bounds — return the original bytes which are likely JPEG
      // (more compact than the PNG we would produce).
      if (image.width < maxWidth && image.height < maxHeight) {
        image.dispose();
        codec.dispose();
        return inputBytes;
      }

      // Re-encode the resized image as PNG.  The pdf library decodes
      // both JPEG and PNG to raw RGBA, so the on-disk format only
      // affects transfer size, not in-memory pixel count.
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      codec.dispose();
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (_) {
      // Fall back to original bytes — still works, just uses more memory
    }
    return inputBytes;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PAGE BUILDING (runs inside the background isolate)
  // ═══════════════════════════════════════════════════════════════════

  List<pw.Page> _buildPages(ReportDocument doc) {
    final dateFormat = DateFormat('d MMMM yyyy');
    final accent = _config.accentColor;
    final pages = <pw.Page>[];

    // Cover page
    pages.add(_coverPage(doc, dateFormat, accent));

    // Table of contents
    if (_config.showTableOfContents) {
      pages.add(_tocPage(doc, accent));
    }

    // Content pages
    pages.add(pw.MultiPage(
      pageFormat: _config.pageFormat,
      margin: const pw.EdgeInsets.all(40),
      maxPages: PdfSharedUtils.maxTotalPages,
      header: (context) => _pageHeader(doc, accent),
      footer: _config.showPageNumbers
          ? (context) => _pageFooter(context, accent)
          : null,
      build: (context) {
        final widgets = <pw.Widget>[];

        // AI Executive Summary
        if (doc.aiExecutiveSummary != null &&
            doc.aiExecutiveSummary!.isNotEmpty) {
          widgets.addAll(_aiSummary(doc.aiExecutiveSummary!, accent));
        }

        for (var si = 0; si < doc.sections.length; si++) {
          final section = doc.sections[si];

          // Subtle separator line between sections (skip before first)
          if (si > 0 || (doc.aiExecutiveSummary != null && doc.aiExecutiveSummary!.isNotEmpty)) {
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Divider(
              color: PdfSharedUtils.mediumGrey,
              thickness: 0.5,
              height: 1,
            ));
            widgets.add(pw.SizedBox(height: 10));
          }

          // Section header bar (per-section color)
          final sectionClr =
              PdfSharedUtils.sectionColor(section.key, accent);
          widgets.add(pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: sectionClr,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(section.title,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: PdfColors.white)),
          ));
          widgets.add(pw.SizedBox(height: 8));

          // AI section narrative
          final aiNarrative = doc.aiSectionNarratives[section.key];
          if (aiNarrative != null && aiNarrative.isNotEmpty) {
            widgets.addAll(_aiNarrative(aiNarrative, accent));
            widgets.add(pw.SizedBox(height: 8));
          }

          for (final screen in section.screens) {
            if (screen.isMergedGroup) {
              // ── Merged group (e.g. "E1 Chimney") — accent sub-header
              //    with flowing paragraphs ─────────────────────────────
              widgets.add(pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F5F5'),
                  border: pw.Border(left: pw.BorderSide(color: sectionClr, width: 3)),
                ),
                child: pw.Text(screen.title,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ));
              widgets.add(pw.SizedBox(height: 4));

              if (screen.phrases.isNotEmpty && _config.includePhrases) {
                for (final phrase in screen.phrases) {
                  widgets.add(pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(8, 2, 8, 2),
                    child: pw.Text(sanitize(phrase),
                        style: const pw.TextStyle(fontSize: 11, lineSpacing: 2.5)),
                  ));
                }
              }
            } else {
              // ── Individual screen — lighter heading ─────────────────
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, top: 4, bottom: 2),
                child: pw.Text(screen.title,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfSharedUtils.headerDark)),
              ));

              // Suppress field table when phrases exist — phrases already
              // express the data in professional surveyor language.
              if (screen.phrases.isNotEmpty && _config.includePhrases) {
                widgets.add(pw.SizedBox(height: 2));
                for (final phrase in screen.phrases) {
                  widgets.add(pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(8, 2, 8, 2),
                    child: pw.Text(sanitize(phrase),
                        style: const pw.TextStyle(fontSize: 11, lineSpacing: 2.5)),
                  ));
                }
              } else if (screen.fields.isNotEmpty) {
                widgets.add(_fieldsTable(screen.fields));
              }
            }

            // Surveyor's custom note
            if (screen.userNote.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E3F2FD'),
                ),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: "Surveyor's Note: ",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.TextSpan(
                        text: sanitize(screen.userNote),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            }
            widgets.add(pw.SizedBox(height: 6));
          }
        }

        // AI Disclaimer
        if (doc.hasAiContent && doc.aiDisclaimer != null) {
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF3E0'),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColor.fromHex('#FFE0B2')),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('\u26A0 ',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Expanded(
                  child: pw.Text(
                    sanitize(doc.aiDisclaimer!),
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfSharedUtils.grey,
                    ),
                  ),
                ),
              ],
            ),
          ));
        }

        // Professional Observations & Recommendations
        if (_config.includeRecommendations && doc.hasRecommendations) {
          widgets.addAll(_recommendationsSection(doc.recommendationItems));
        }

        // Signatures
        if (_config.includeSignatures && doc.signatures.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 16));
          widgets.add(pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text('Signatures',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    color: PdfColors.white)),
          ));
          widgets.add(pw.SizedBox(height: 10));
          for (final sig in doc.signatures) {
            widgets.add(_signatureCard(sig, accent));
          }
        }

        return widgets;
      },
    ));

    // Photo pages
    if (_config.includePhotos && doc.photoFilePaths.isNotEmpty) {
      final cappedPaths = doc.photoFilePaths.length > PdfSharedUtils.maxPhotosInPdf
          ? doc.photoFilePaths.sublist(0, PdfSharedUtils.maxPhotosInPdf)
          : doc.photoFilePaths;
      pages.addAll(_buildPhotoPages(cappedPaths));
    }

    return pages;
  }

  pw.Page _coverPage(
    ReportDocument doc,
    DateFormat dateFormat,
    PdfColor accent,
  ) {
    final meta = doc.surveyMeta;
    final isInspection = doc.reportType == ReportType.inspection;
    final mainTitle = isInspection
        ? 'RICS HomeBuyer Report'
        : 'Valuation Report';
    final subtitle = isInspection
        ? 'Level 2 Home Survey'
        : 'Mortgage Valuation Report';
    final ricsLine = isInspection
        ? 'Prepared in accordance with RICS Home Survey Standard (4th Edition)'
        : 'Prepared in accordance with RICS Valuation Standards';

    // Build the property details table rows.
    final tableRows = <_CoverTableEntry>[
      _CoverTableEntry('Property Address', meta.address ?? meta.title),
      if (meta.clientName != null)
        _CoverTableEntry('Client Name', meta.clientName!),
      if (meta.jobRef != null)
        _CoverTableEntry('Job Reference', meta.jobRef!),
      if (meta.inspectionDate != null)
        _CoverTableEntry(
            'Inspection Date', dateFormat.format(meta.inspectionDate!)),
      _CoverTableEntry(
          'Report Generated', DateFormat('d MMMM yyyy, h:mm a').format(doc.generatedAt)),
      if (meta.surveyDuration != null)
        _CoverTableEntry('Survey Duration', _formatDuration(meta.surveyDuration!)),
    ];

    return pw.Page(
      pageFormat: _config.pageFormat,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── Full-width accent banner ───────────────────────────
            pw.Container(
              width: double.infinity,
              height: 80,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(mainTitle,
                      style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(subtitle,
                      style: const pw.TextStyle(
                          fontSize: 14, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(ricsLine,
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // ── Property name ──────────────────────────────────────
            pw.Text(meta.title,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfSharedUtils.headerDark)),
            if (meta.address != null && meta.address != meta.title) ...[
              pw.SizedBox(height: 6),
              pw.Text(meta.address!,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfSharedUtils.grey)),
            ],

            pw.SizedBox(height: 30),

            // ── Property details table ─────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfSharedUtils.lightGrey, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                for (var i = 0; i < tableRows.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i.isEven
                          ? PdfSharedUtils.lightGrey
                          : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        child: pw.Text(tableRows[i].label,
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfSharedUtils.grey)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        child: pw.Text(tableRows[i].value,
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfSharedUtils.textDark)),
                      ),
                    ],
                  ),
              ],
            ),

            pw.Spacer(),

            // ── Bottom disclaimer ──────────────────────────────────
            pw.Text(
              'This report is for the sole use of the named client and should '
              'not be relied upon by any third party.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfSharedUtils.grey),
            ),
            pw.SizedBox(height: 10),
            pw.Text('SurveyScriber Professional Report',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: accent)),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) => PdfSharedUtils.formatDuration(d);

  pw.Page _tocPage(ReportDocument doc, PdfColor accent) {
    return pw.MultiPage(
      pageFormat: _config.pageFormat,
      margin: const pw.EdgeInsets.all(40),
      maxPages: 3,
      build: (context) {
        return [
          pw.Text('Table of Contents',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 16),
          pw.Divider(color: accent, thickness: 1),
          pw.SizedBox(height: 12),
          for (var i = 0; i < doc.sections.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(children: [
                pw.Container(
                  width: 24,
                  height: 24,
                  decoration: pw.BoxDecoration(
                    color: PdfSharedUtils.sectionColor(
                        doc.sections[i].key, accent),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Center(
                    child: pw.Text('${i + 1}',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(doc.sections[i].title,
                      style: const pw.TextStyle(fontSize: 11)),
                ),
                pw.Text('${doc.sections[i].screens.length} items',
                    style: const pw.TextStyle(fontSize: 9, color: PdfSharedUtils.grey)),
              ]),
            ),
        ];
      },
    );
  }

  pw.Widget _pageHeader(ReportDocument doc, PdfColor accent) {
    final reportLabel = doc.reportType == ReportType.inspection
        ? 'RICS HomeBuyer Report'
        : 'RICS Property Valuation';
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(reportLabel,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: accent)),
          pw.Expanded(
            child: pw.Text(doc.surveyMeta.title,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfSharedUtils.headerDark)),
          ),
          pw.Text(_config.companyName,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfSharedUtils.headerDark)),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(pw.Context context, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: accent, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by SurveyScriber',
              style: const pw.TextStyle(fontSize: 7, color: PdfSharedUtils.headerDark)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfSharedUtils.headerDark)),
        ],
      ),
    );
  }

  pw.Widget _fieldsTable(List<ReportField> fields) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfSharedUtils.lightGrey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        for (var i = 0; i < fields.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? PdfColors.white : PdfColor.fromHex('#F9F9F9'),
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Text(sanitize(fields[i].label),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Text(
                  fields[i].displayValue.isEmpty
                      ? '-'
                      : sanitize(fields[i].displayValue),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _fieldValueColor(fields[i]),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _signatureCard(ReportSignature sig, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfSharedUtils.lightGrey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(children: [
        _tryLoadImage(sig.filePath, width: 120, height: 50),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(sig.signerName,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(sig.signerRole,
                style: pw.TextStyle(fontSize: 9, color: accent)),
            pw.Text(DateFormat('d MMM yyyy, h:mm a').format(sig.signedAt),
                style: const pw.TextStyle(fontSize: 8, color: PdfSharedUtils.grey)),
          ],
        ),
      ]),
    );
  }

  // ── AI Widgets ──────────────────────────────────────────────────────

  List<pw.Widget> _aiSummary(String summary, PdfColor accent) {
    final cleanText = sanitize(summary);
    // Split into paragraphs so each Container fits within a single page.
    // pw.Container is NOT a SpanningWidget — it can't break across pages.
    final paragraphs = cleanText
        .split(RegExp(r'\n\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final bodyDecor = pw.BoxDecoration(
      color: PdfColor.fromHex('#F8F9FA'),
      border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
    );
    const bodyStyle = pw.TextStyle(fontSize: 9, lineSpacing: 3.5);

    return [
      // Header bar (fixed height — safe)
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: accent,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(children: [
          pw.Text('Executive Summary',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  color: PdfColors.white)),
          pw.SizedBox(width: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text('AI',
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: accent)),
          ),
        ]),
      ),
      pw.SizedBox(height: 8),
      // Each paragraph in its own Container so MultiPage can break between them
      for (var i = 0; i < paragraphs.length; i++)
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.fromLTRB(
            12, i == 0 ? 12 : 4, 12, i == paragraphs.length - 1 ? 12 : 4,
          ),
          decoration: bodyDecor,
          child: pw.Text(paragraphs[i], style: bodyStyle),
        ),
      pw.SizedBox(height: 16),
    ];
  }

  List<pw.Widget> _aiNarrative(String narrative, PdfColor accent) {
    final cleanText = sanitize(narrative);
    final paragraphs = cleanText
        .split(RegExp(r'\n\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final bodyDecor = pw.BoxDecoration(
      color: PdfColor.fromHex('#F8F9FA'),
      border: pw.Border(left: pw.BorderSide(color: accent, width: 2)),
    );
    const bodyStyle = pw.TextStyle(fontSize: 8, lineSpacing: 2.5);

    return [
      // Label row
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 2),
        decoration: bodyDecor,
        child: pw.Text('AI Narrative',
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: accent)),
      ),
      // Body paragraphs — each in its own Container for page-safe rendering
      for (var i = 0; i < paragraphs.length; i++)
        pw.Container(
          width: double.infinity,
          padding: pw.EdgeInsets.fromLTRB(
            10, 4, 10, i == paragraphs.length - 1 ? 10 : 4,
          ),
          decoration: bodyDecor,
          child: pw.Text(paragraphs[i], style: bodyStyle),
        ),
    ];
  }

  // ── Recommendations Widgets ────────────────────────────────────────

  static const _tealAccent = PdfColor(0.0, 0.41, 0.36); // #00695C

  List<pw.Widget> _recommendationsSection(
    List<ReportRecommendationItem> items,
  ) {
    final widgets = <pw.Widget>[];

    widgets.add(pw.SizedBox(height: 16));

    // Section header bar — teal
    widgets.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _tealAccent,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text('Professional Observations & Recommendations',
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: PdfColors.white)),
    ));
    widgets.add(pw.SizedBox(height: 10));

    // Group by category
    final grouped = <String, List<ReportRecommendationItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    for (final entry in grouped.entries) {
      // Category sub-header
      widgets.add(pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#E0F2F1'),
          border: pw.Border(
              left: const pw.BorderSide(color: _tealAccent, width: 3)),
        ),
        child: pw.Text(entry.key,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: _tealAccent)),
      ));
      widgets.add(pw.SizedBox(height: 4));

      // Table: Severity | Screen | Observation | Recommendation
      widgets.add(pw.Table(
        border:
            pw.TableBorder.all(color: PdfSharedUtils.lightGrey, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(55),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(2.5),
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColor(0.95, 0.95, 0.95),
            ),
            children: [
              _recHeaderCell('Severity'),
              _recHeaderCell('Screen'),
              _recHeaderCell('Observation'),
              _recHeaderCell('Recommendation'),
            ],
          ),
          // Data rows
          for (var i = 0; i < entry.value.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i.isEven
                    ? PdfColors.white
                    : PdfColor.fromHex('#F9F9F9'),
              ),
              children: [
                _recSeverityCell(entry.value[i].severity),
                _recDataCell(entry.value[i].screenTitle),
                _recDataCell(entry.value[i].reason),
                _recDataCell(entry.value[i].suggestedText),
              ],
            ),
        ],
      ));
      widgets.add(pw.SizedBox(height: 8));
    }

    // Footer
    widgets.add(pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        'Based on RICS Home Survey Standard guidelines.',
        style: const pw.TextStyle(fontSize: 7, color: PdfSharedUtils.grey),
      ),
    ));

    return widgets;
  }

  pw.Widget _recHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _recDataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(sanitize(text), style: const pw.TextStyle(fontSize: 8)),
    );
  }

  pw.Widget _recSeverityCell(String severity) {
    final color = switch (severity) {
      'High' => PdfColor.fromHex('#C62828'),
      'Moderate' => PdfColor.fromHex('#E65100'),
      _ => PdfColor.fromHex('#1565C0'),
    };
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(severity,
          style: pw.TextStyle(
              fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════

  PdfColor _fieldValueColor(ReportField field) {
    // Color-code condition ratings
    if (field.type == ReportFieldType.dropdown &&
        field.rawValue != null &&
        ['1', '2', '3'].contains(field.rawValue)) {
      return PdfSharedUtils.conditionColor(field.rawValue!);
    }
    return PdfSharedUtils.textDark;
  }

  pw.Widget _tryLoadImage(String filePath, {required double width, required double height}) {
    final bytes = _imageCache[filePath];
    if (bytes != null) {
      final image = pw.MemoryImage(bytes);
      return pw.Image(image, width: width, height: height, fit: pw.BoxFit.contain);
    }
    return pw.Container(
      width: width,
      height: height,
      color: PdfSharedUtils.lightGrey,
      child: pw.Center(
        child: pw.Text('Image unavailable', style: const pw.TextStyle(fontSize: 7)),
      ),
    );
  }

  List<pw.Page> _buildPhotoPages(List<String> photoPaths) {
    final pages = <pw.Page>[];
    const photosPerPage = 4;

    for (var i = 0; i < photoPaths.length; i += photosPerPage) {
      final batch = photoPaths.skip(i).take(photosPerPage).toList();
      pages.add(pw.Page(
        pageFormat: _config.pageFormat,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            children: [
              pw.Text('Photos (${i ~/ photosPerPage + 1})',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in batch)
                    _tryLoadImage(path, width: 230, height: 180),
                ],
              ),
            ],
          );
        },
      ));
    }

    return pages;
  }

  void _reportProgress(String stage, double percent) {
    onProgress?.call(ExportProgress(
      stage: stage,
      percent: percent,
      message: stage,
    ));
  }
}

/// Label–value pair for the cover page property details table.
class _CoverTableEntry {
  const _CoverTableEntry(this.label, this.value);
  final String label;
  final String value;
}
