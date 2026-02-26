import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared PDF utilities reused by the V2 PDF generator.
/// Mirrors font-loading and color patterns from the V1 PdfGeneratorService.
class PdfSharedUtils {
  PdfSharedUtils._();

  // ── Font cache ──────────────────────────────────────────────────────
  static String? _fontCacheDir;

  /// Load a font, caching the raw TTF bytes to the local filesystem.
  ///
  /// On first call the font is downloaded via [googleFontLoader] and the
  /// raw TTF bytes are written to `~app-docs/fonts/<fontName>.ttf`.
  /// Subsequent calls read directly from the cache file, avoiding a
  /// network round-trip.
  static Future<pw.Font> loadFontCached(
    String fontName,
    Future<pw.Font> Function() googleFontLoader,
  ) async {
    try {
      if (!kIsWeb) {
        _fontCacheDir ??= (await getApplicationDocumentsDirectory()).path;
        final cacheFile = File('$_fontCacheDir/fonts/$fontName.ttf');

        if (cacheFile.existsSync()) {
          try {
            final bytes = await cacheFile.readAsBytes();
            if (bytes.length > 100) {
              return pw.Font.ttf(bytes.buffer.asByteData());
            }
          } catch (_) {
            // Cache corrupted — fall through to download
          }
        }

        // Download via the printing package's Google Fonts loader
        final font = await googleFontLoader();
        try {
          // Persist the raw TTF bytes so future loads are offline-capable.
          final byteData = _extractFontBytes(font);
          if (byteData != null) {
            await cacheFile.parent.create(recursive: true);
            await cacheFile.writeAsBytes(
              byteData.buffer.asUint8List(
                byteData.offsetInBytes,
                byteData.lengthInBytes,
              ),
            );
          }
        } catch (_) {
          // Non-fatal: caching failed but font is loaded
        }
        return font;
      }
    } catch (_) {
      // Fall through to direct load
    }
    return googleFontLoader();
  }

  /// Load the standard Noto Sans font set + fallback symbols.
  static Future<PdfFontBundle> loadStandardFonts() async {
    final baseFont = await loadFontCached('NotoSans-Regular', PdfGoogleFonts.notoSansRegular);
    final boldFont = await loadFontCached('NotoSans-Bold', PdfGoogleFonts.notoSansBold);
    final italicFont = await loadFontCached('NotoSans-Italic', PdfGoogleFonts.notoSansItalic);
    final symbolFont =
        await loadFontCached('NotoSansSymbols-Regular', PdfGoogleFonts.notoSansSymbolsRegular);
    final symbols2Font =
        await loadFontCached('NotoSansSymbols2-Regular', PdfGoogleFonts.notoSansSymbols2Regular);
    final emojiFont =
        await loadFontCached('NotoEmoji-Regular', PdfGoogleFonts.notoEmojiRegular);

    return PdfFontBundle(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
      fallback: [symbolFont, symbols2Font, emojiFont],
    );
  }

  /// Load standard font set and return raw TTF [ByteData] for each font.
  ///
  /// This is used for isolate-based PDF generation: raw bytes are
  /// transferable across isolates, while [pw.Font] objects are not
  /// (they capture internal state that can't be serialized).
  static Future<PdfFontDataBundle> loadStandardFontData() async {
    final baseFont = await loadFontCached('NotoSans-Regular', PdfGoogleFonts.notoSansRegular);
    final boldFont = await loadFontCached('NotoSans-Bold', PdfGoogleFonts.notoSansBold);
    final italicFont = await loadFontCached('NotoSans-Italic', PdfGoogleFonts.notoSansItalic);
    final symbolFont =
        await loadFontCached('NotoSansSymbols-Regular', PdfGoogleFonts.notoSansSymbolsRegular);
    final symbols2Font =
        await loadFontCached('NotoSansSymbols2-Regular', PdfGoogleFonts.notoSansSymbols2Regular);
    final emojiFont =
        await loadFontCached('NotoEmoji-Regular', PdfGoogleFonts.notoEmojiRegular);

    return PdfFontDataBundle(
      base: _extractFontBytes(baseFont)!,
      bold: _extractFontBytes(boldFont)!,
      italic: _extractFontBytes(italicFont)!,
      fallbacks: [
        _extractFontBytes(symbolFont)!,
        _extractFontBytes(symbols2Font)!,
        _extractFontBytes(emojiFont)!,
      ],
    );
  }

  /// Extract raw TTF [ByteData] from a loaded [pw.Font].
  ///
  /// [pw.TtfFont] (created by [pw.Font.ttf]) exposes a public `data`
  /// field containing the original TTF bytes.  Returns null for built-in
  /// Type1 fonts (Helvetica, Courier, etc.) which don't have TTF data.
  static ByteData? _extractFontBytes(pw.Font font) {
    if (font is pw.TtfFont) {
      return font.data;
    }
    return null;
  }

  // ── Text sanitization ──────────────────────────────────────────────

  /// Regex matching HTML numeric character references: &#DDD; and &#xHH;
  static final _numericEntityRegex = RegExp(r'&#(x?)([0-9a-fA-F]+);');

  /// Sanitise text for report rendering (shared by PDF and DOCX generators).
  ///
  /// Phrase templates and user input may contain literal escape sequences
  /// (`\r\n`, `\n`, `\r`), residual HTML (`<br>`, `<strong>`, `&nbsp;`),
  /// or stray control characters.  This converts them all to clean text.
  static String sanitize(String text) {
    var s = text;
    // 1. <br> tags → newline (before stripping other HTML)
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // 2. Strip remaining HTML tags
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    // 3. Named HTML entities
    s = s.replaceAll('&nbsp;', ' ')
         .replaceAll('&amp;', '&')
         .replaceAll('&lt;', '<')
         .replaceAll('&gt;', '>')
         .replaceAll('&quot;', '"')
         .replaceAll('&#39;', "'");
    // 4. Numeric HTML entities (L1 fix): &#169; → ©, &#x2014; → —
    s = s.replaceAllMapped(_numericEntityRegex, (m) {
      final radix = m[1] == 'x' ? 16 : 10;
      final codePoint = int.tryParse(m[2]!, radix: radix);
      if (codePoint != null && codePoint > 0 && codePoint <= 0x10FFFF) {
        return String.fromCharCode(codePoint);
      }
      return m[0]!; // Leave malformed entities as-is
    });
    // 5. Literal escape sequences (two-char strings) → real chars
    s = s.replaceAll('\\r\\n', '\n');
    s = s.replaceAll('\\r', '\n');
    s = s.replaceAll('\\n', '\n');
    s = s.replaceAll('\\t', ' ');
    // 6. Collapse runs of 3+ newlines to 2
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    // 7. Trim leading/trailing whitespace from each line
    s = s.split('\n').map((l) => l.trim()).join('\n').trim();
    return s;
  }

  /// Format a [Duration] as "Xh YYm" or "Xm".
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  // ── Colors ──────────────────────────────────────────────────────────
  static const accentBlue = PdfColor(0.08, 0.38, 0.75);
  static const textDark = PdfColor(0.13, 0.13, 0.13);
  static const headerDark = PdfColor(0.2, 0.2, 0.2);   // #333333
  static const grey = PdfColor(0.6, 0.6, 0.6);
  static const lightGrey = PdfColor(0.93, 0.93, 0.93);
  static const mediumGrey = PdfColor(0.8, 0.8, 0.8);

  static const conditionGood = PdfColor(0.18, 0.49, 0.20); // #2E7D32
  static const conditionFair = PdfColor(0.90, 0.32, 0.0);  // #E65100
  static const conditionPoor = PdfColor(0.78, 0.16, 0.16); // #C62828

  static PdfColor conditionColor(String rating) {
    return switch (rating) {
      '1' => conditionGood,
      '2' => conditionFair,
      '3' => conditionPoor,
      _ => textDark,
    };
  }

  // ── Per-section colors ──────────────────────────────────────────────
  /// Inspection section key → color for section headers, TOC circles, etc.
  static const sectionColors = <String, PdfColor>{
    'D': PdfColor(0.08, 0.40, 0.75), // Blue
    'E': PdfColor(0.18, 0.49, 0.20), // Green
    'F': PdfColor(0.61, 0.15, 0.69), // Purple
    'G': PdfColor(1.0, 0.44, 0.0), // Orange
    'H': PdfColor(0.0, 0.47, 0.42), // Teal
    'R': PdfColor(0.40, 0.23, 0.72), // Deep Purple
    'A': PdfColor(0.22, 0.28, 0.31), // Blue Grey
    'I': PdfColor(0.76, 0.09, 0.36), // Pink
    'J': PdfColor(0.83, 0.18, 0.18), // Red
    'K': PdfColor(0.27, 0.35, 0.39), // Slate
  };

  /// Valuation section key → color.
  static const valuationSectionColors = <String, PdfColor>{
    'valuation_details': PdfColor(0.0, 0.30, 0.25), // Deep Teal
    'property_assessment': PdfColor(0.08, 0.40, 0.75), // Blue
    'property_inspection': PdfColor(0.18, 0.49, 0.20), // Green
    'condition_restrictions': PdfColor(0.83, 0.18, 0.18), // Red
    'valuation_completion': PdfColor(0.40, 0.23, 0.72), // Deep Purple
  };

  /// Look up the color for a section key, falling back to [fallback].
  static PdfColor sectionColor(String key, PdfColor fallback) {
    return sectionColors[key] ?? valuationSectionColors[key] ?? fallback;
  }

  // ── Safety limits ──────────────────────────────────────────────────
  static const int maxTotalPages = 1000;
  static const int maxFieldTextLength = 50000;

  /// Maximum photos to include in a single PDF.  Beyond this, memory
  /// pressure makes the export unreliable on mid-range devices.
  static const int maxPhotosInPdf = 200;

  // ── File saving ────────────────────────────────────────────────────

  /// Write pre-built PDF bytes to the reports directory.
  ///
  /// Use this instead of [savePdfToFile] when the PDF was generated in
  /// an isolate and you already have the raw bytes.
  static Future<String> savePdfBytesToFile(
    Uint8List bytes,
    String titlePrefix,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final sanitized = titlePrefix
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = '${sanitized}_v2_$timestamp.pdf';

    final file = File('${reportsDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

/// Constructed [pw.Font] objects ready for direct use in PDF widgets.
class PdfFontBundle {
  const PdfFontBundle({
    required this.base,
    required this.bold,
    required this.italic,
    required this.fallback,
  });

  final pw.Font base;
  final pw.Font bold;
  final pw.Font italic;
  final List<pw.Font> fallback;
}

/// Raw TTF [ByteData] for each font, safe to transfer across isolates.
///
/// Use [toFontBundle] inside the target isolate to construct [pw.Font]
/// objects from the raw bytes.
class PdfFontDataBundle {
  const PdfFontDataBundle({
    required this.base,
    required this.bold,
    required this.italic,
    required this.fallbacks,
  });

  final ByteData base;
  final ByteData bold;
  final ByteData italic;
  final List<ByteData> fallbacks;

  /// Reconstruct [pw.Font] objects from raw bytes.  Call this inside the
  /// target isolate — [pw.Font.ttf] is a pure Dart constructor that works
  /// without the Flutter engine.
  PdfFontBundle toFontBundle() => PdfFontBundle(
        base: pw.Font.ttf(base),
        bold: pw.Font.ttf(bold),
        italic: pw.Font.ttf(italic),
        fallback: fallbacks.map((b) => pw.Font.ttf(b)).toList(),
      );
}
