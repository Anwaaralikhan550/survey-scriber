import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import 'pdf_shared_utils.dart';

/// Generates DOCX files from [ReportDocument] using pure Dart XML +
/// the `archive` package for ZIP compression.
///
/// DOCX is essentially a ZIP containing XML files following the Open XML spec.
class DocxGeneratorService {
  DocxGeneratorService(this._config);

  final ExportConfig _config;

  void Function(ExportProgress)? onProgress;

  Future<GeneratedFileResult> generateDocx(ReportDocument doc) async {
    _reportProgress('Loading images', 0.05);
    final images = await _preloadImages(doc);

    _reportProgress('Building document structure', 0.15);

    final archive = Archive();

    // [Content_Types].xml — includes image MIME types when images are present
    _addContentTypes(archive, images);

    // _rels/.rels
    _addRels(archive);

    // word/_rels/document.xml.rels — includes image relationships
    _addDocumentRels(archive, images);

    // word/media/ — embedded image files
    _addMediaFiles(archive, images);

    // word/styles.xml
    _addStyles(archive);

    _reportProgress('Generating content', 0.35);

    // word/document.xml — references images via DrawingML
    _addDocumentXml(archive, doc, images);

    _reportProgress('Compressing', 0.70);

    // Extract archive entries into isolate-safe format and encode off main thread
    final entries = archive.files
        .map((f) => _ArchiveEntry(f.name, f.size, Uint8List.fromList(f.content as List<int>)))
        .toList();
    final zipBytes = await compute(_encodeZipIsolate, entries);

    _reportProgress('Saving file', 0.85);

    final docxBytes = Uint8List.fromList(zipBytes);
    final path = await _saveDocx(docxBytes, doc.title);

    _reportProgress('Complete', 1.0);
    AppLogger.d('DocxGen', 'DOCX saved: $path');
    return GeneratedFileResult(path: path, bytes: docxBytes);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ARCHIVE STRUCTURE
  // ═══════════════════════════════════════════════════════════════════

  void _addContentTypes(Archive archive, _DocxImageBundle images) {
    final buf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
      ..write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
      ..write('<Default Extension="xml" ContentType="application/xml"/>');
    if (images.hasPng) {
      buf.write('<Default Extension="png" ContentType="image/png"/>');
    }
    if (images.hasJpeg) {
      buf.write('<Default Extension="jpeg" ContentType="image/jpeg"/>');
    }
    buf
      ..write('<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>')
      ..write('<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>')
      ..write('</Types>');

    final xml = buf.toString();
    archive.addFile(ArchiveFile(
      '[Content_Types].xml',
      utf8.encode(xml).length,
      utf8.encode(xml),
    ));
  }

  void _addRels(Archive archive) {
    const xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';

    archive.addFile(ArchiveFile(
      '_rels/.rels',
      utf8.encode(xml).length,
      utf8.encode(xml),
    ));
  }

  void _addDocumentRels(Archive archive, _DocxImageBundle images) {
    final buf = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
      ..write('<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>');
    for (final ref in images.allImages) {
      buf.write('<Relationship Id="${ref.relId}" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
          'Target="${ref.mediaPath}"/>');
    }
    buf.write('</Relationships>');

    final xml = buf.toString();
    archive.addFile(ArchiveFile(
      'word/_rels/document.xml.rels',
      utf8.encode(xml).length,
      utf8.encode(xml),
    ));
  }

  /// Add pre-loaded image files into the word/media/ folder of the ZIP.
  void _addMediaFiles(Archive archive, _DocxImageBundle images) {
    for (final ref in images.allImages) {
      archive.addFile(ArchiveFile(
        'word/${ref.mediaPath}',
        ref.bytes.length,
        ref.bytes,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  STYLES
  // ═══════════════════════════════════════════════════════════════════

  void _addStyles(Archive archive) {
    const fontName = 'Calibri';
    final accentHex = _pdfColorToHex(_config.accentColor);

    final buf = StringBuffer();
    buf.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.write('<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');

    // Default style
    buf.write('<w:docDefaults><w:rPrDefault><w:rPr>');
    buf.write('<w:rFonts w:ascii="$fontName" w:hAnsi="$fontName"/>');
    buf.write('<w:sz w:val="22"/>');
    buf.write('</w:rPr></w:rPrDefault></w:docDefaults>');

    // Normal
    buf.write('<w:style w:type="paragraph" w:styleId="Normal" w:default="1">');
    buf.write('<w:name w:val="Normal"/>');
    buf.write('<w:pPr><w:spacing w:after="120"/></w:pPr>');
    buf.write('</w:style>');

    // Heading 1
    buf.write('<w:style w:type="paragraph" w:styleId="Heading1">');
    buf.write('<w:name w:val="heading 1"/>');
    buf.write('<w:pPr><w:spacing w:before="360" w:after="120"/>');
    buf.write('<w:outlineLvl w:val="0"/></w:pPr>');
    buf.write('<w:rPr><w:b/><w:sz w:val="32"/>');
    buf.write('<w:color w:val="$accentHex"/>');
    buf.write('</w:rPr></w:style>');

    // Heading 2
    buf.write('<w:style w:type="paragraph" w:styleId="Heading2">');
    buf.write('<w:name w:val="heading 2"/>');
    buf.write('<w:pPr><w:spacing w:before="240" w:after="80"/>');
    buf.write('<w:outlineLvl w:val="1"/></w:pPr>');
    buf.write('<w:rPr><w:b/><w:sz w:val="28"/>');
    buf.write('<w:color w:val="$accentHex"/>');
    buf.write('</w:rPr></w:style>');

    // Heading 3
    buf.write('<w:style w:type="paragraph" w:styleId="Heading3">');
    buf.write('<w:name w:val="heading 3"/>');
    buf.write('<w:pPr><w:spacing w:before="200" w:after="60"/>');
    buf.write('<w:outlineLvl w:val="2"/></w:pPr>');
    buf.write('<w:rPr><w:b/><w:sz w:val="24"/>');
    buf.write('<w:color w:val="$accentHex"/>');
    buf.write('</w:rPr></w:style>');

    // Table style
    buf.write('<w:style w:type="table" w:styleId="ReportTable">');
    buf.write('<w:name w:val="Report Table"/>');
    buf.write('<w:tblPr>');
    buf.write('<w:tblBorders>');
    buf.write('<w:top w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>');
    buf.write('<w:left w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>');
    buf.write('<w:bottom w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>');
    buf.write('<w:right w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>');
    buf.write('<w:insideH w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>');
    buf.write('<w:insideV w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>');
    buf.write('</w:tblBorders>');
    // Cell padding: 8pt horizontal (160 twips), 5pt vertical (100 twips)
    buf.write('<w:tblCellMar>');
    buf.write('<w:top w:w="100" w:type="dxa"/>');
    buf.write('<w:left w:w="160" w:type="dxa"/>');
    buf.write('<w:bottom w:w="100" w:type="dxa"/>');
    buf.write('<w:right w:w="160" w:type="dxa"/>');
    buf.write('</w:tblCellMar>');
    buf.write('</w:tblPr></w:style>');

    buf.write('</w:styles>');

    final xml = buf.toString();
    archive.addFile(ArchiveFile(
      'word/styles.xml',
      utf8.encode(xml).length,
      utf8.encode(xml),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DOCUMENT BODY
  // ═══════════════════════════════════════════════════════════════════

  void _addDocumentXml(Archive archive, ReportDocument doc, _DocxImageBundle images) {
    final buf = StringBuffer();
    buf.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.write('<w:document'
        ' xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
        ' xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"'
        ' xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
        ' xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">');
    buf.write('<w:body>');

    final dateFormat = DateFormat('d MMMM yyyy');

    // Title / Header
    _writeHeader(buf, doc, dateFormat);

    // AI Executive Summary (if present)
    if (doc.aiExecutiveSummary != null &&
        doc.aiExecutiveSummary!.isNotEmpty) {
      _writeHeading(buf, 'Executive Summary', 'Heading1');
      _writeAiNarrativeParagraph(buf, doc.aiExecutiveSummary!);
    }

    // Sections
    for (final section in doc.sections) {
      _writeHeading(buf, section.title, 'Heading1');

      // AI section narrative (if present)
      final aiNarrative = doc.aiSectionNarratives[section.key];
      if (aiNarrative != null && aiNarrative.isNotEmpty) {
        _writeAiNarrativeParagraph(buf, aiNarrative);
      }

      for (final screen in section.screens) {
        if (screen.isMergedGroup) {
          // ── Merged group (e.g. "E1 Chimney") — flowing paragraphs ──
          _writeHeading(buf, screen.title, 'Heading2');

          if (screen.phrases.isNotEmpty && _config.includePhrases) {
            for (final phrase in screen.phrases) {
              _writeParagraph(buf, phrase);
            }
          }
        } else {
          // ── Individual screen ──
          _writeHeading(buf, screen.title, 'Heading3');

          // Suppress field table when phrases exist — the phrases already
          // express the data in professional surveyor language.
          if (screen.phrases.isNotEmpty && _config.includePhrases) {
            for (final phrase in screen.phrases) {
              _writeParagraph(buf, phrase);
            }
          } else if (screen.fields.isNotEmpty) {
            _writeFieldsTable(buf, screen.fields);
          }
        }

        // Surveyor's custom note
        if (screen.userNote.isNotEmpty) {
          _writeSurveyorNote(buf, screen.userNote);
        }
      }
    }

    // AI Disclaimer
    if (doc.hasAiContent && doc.aiDisclaimer != null) {
      buf.write('<w:p/>'); // blank line
      _writeStyledParagraph(buf, doc.aiDisclaimer!,
          fontSize: 16, color: '888888');
    }

    // Professional Observations & Recommendations
    if (_config.includeRecommendations && doc.hasRecommendations) {
      _writeRecommendationsSection(buf, doc.recommendationItems);
    }

    // Signatures section — embeds signature images when available
    if (_config.includeSignatures && doc.signatures.isNotEmpty) {
      _writeHeading(buf, 'Signatures', 'Heading1');
      var sigImgId = 1;
      for (final sig in doc.signatures) {
        final imgRef = images.signatureLookup[sig.filePath];
        if (imgRef != null) {
          _writeInlineImage(buf, imgRef, sigImgId++);
        }
        _writeParagraph(buf,
            '${sig.signerName} (${sig.signerRole}) - ${dateFormat.format(sig.signedAt)}');
      }
    }

    // Property photos section
    if (_config.includePhotos && images.photoImages.isNotEmpty) {
      // Page break before photos
      buf.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      _writeHeading(buf, 'Property Photos', 'Heading1');
      var photoImgId = 1000; // Offset to avoid signature ID collisions
      for (final imgRef in images.photoImages) {
        _writeInlineImage(buf, imgRef, photoImgId++);
        buf.write('<w:p/>'); // spacing between photos
      }
    }

    buf.write('</w:body></w:document>');

    final xml = buf.toString();
    archive.addFile(ArchiveFile(
      'word/document.xml',
      utf8.encode(xml).length,
      utf8.encode(xml),
    ));
  }

  void _writeHeader(StringBuffer buf, ReportDocument doc, DateFormat fmt) {
    final meta = doc.surveyMeta;
    final reportLabel = doc.reportType == ReportType.inspection
        ? 'Inspection Report'
        : 'Valuation Report';
    final accentHex = _pdfColorToHex(_config.accentColor);

    _writeStyledParagraph(buf, reportLabel, fontSize: 36, bold: true, color: accentHex);
    _writeStyledParagraph(buf, meta.title, fontSize: 24);
    if (meta.address != null && meta.address!.isNotEmpty) {
      _writeStyledParagraph(buf, meta.address!, fontSize: 18, color: '888888');
    }
    buf.write('<w:p/>'); // blank line
    if (meta.jobRef != null) _writeParagraph(buf, 'Reference: ${meta.jobRef}');
    if (meta.clientName != null) _writeParagraph(buf, 'Client: ${meta.clientName}');
    _writeParagraph(buf, 'Date: ${fmt.format(doc.generatedAt)}');
    _writeParagraph(buf, 'Prepared by: ${_config.companyName}');
    if (meta.startedAt != null) {
      _writeParagraph(buf, 'Started: ${DateFormat('d MMM yyyy HH:mm').format(meta.startedAt!)}');
    }
    if (meta.completedAt != null) {
      _writeParagraph(buf, 'Completed: ${DateFormat('d MMM yyyy HH:mm').format(meta.completedAt!)}');
    }
    if (meta.surveyDuration != null) {
      _writeParagraph(buf, 'Duration: ${PdfSharedUtils.formatDuration(meta.surveyDuration!)}');
    }
    // Page break
    buf.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
  }

  void _writeHeading(StringBuffer buf, String text, String style) {
    buf.write('<w:p><w:pPr><w:pStyle w:val="$style"/></w:pPr>');
    buf.write('<w:r><w:t xml:space="preserve">');
    buf.write(_escapeXml(text));
    buf.write('</w:t></w:r></w:p>');
  }

  void _writeParagraph(StringBuffer buf, String text) {
    buf.write('<w:p><w:r><w:t xml:space="preserve">');
    buf.write(_escapeXml(text));
    buf.write('</w:t></w:r></w:p>');
  }

  void _writeStyledParagraph(
    StringBuffer buf,
    String text, {
    int fontSize = 22,
    bool bold = false,
    String? color,
  }) {
    buf.write('<w:p><w:r><w:rPr>');
    buf.write('<w:sz w:val="${fontSize}"/>');
    if (bold) buf.write('<w:b/>');
    if (color != null) buf.write('<w:color w:val="$color"/>');
    buf.write('</w:rPr><w:t xml:space="preserve">');
    buf.write(_escapeXml(text));
    buf.write('</w:t></w:r></w:p>');
  }

  void _writeBulletParagraph(StringBuffer buf, String text) {
    buf.write('<w:p><w:pPr>');
    buf.write('<w:ind w:left="720" w:hanging="360"/>');
    buf.write('</w:pPr>');
    buf.write('<w:r><w:t xml:space="preserve">\u2022 ');
    buf.write(_escapeXml(text));
    buf.write('</w:t></w:r></w:p>');
  }

  /// Write a surveyor's custom note with bold prefix and italic body.
  void _writeSurveyorNote(StringBuffer buf, String note) {
    buf.write('<w:p><w:pPr><w:shd w:val="clear" w:color="auto" w:fill="E3F2FD"/></w:pPr>');
    // Bold prefix
    buf.write('<w:r><w:rPr><w:b/><w:sz w:val="20"/></w:rPr>');
    buf.write("<w:t xml:space=\"preserve\">Surveyor's Note: </w:t></w:r>");
    // Italic body
    buf.write('<w:r><w:rPr><w:i/><w:sz w:val="20"/></w:rPr>');
    buf.write('<w:t xml:space="preserve">');
    buf.write(_escapeXml(note));
    buf.write('</w:t></w:r></w:p>');
  }

  /// Write an inline image using OOXML DrawingML markup.
  ///
  /// The image must already be added to the ZIP at `word/{ref.mediaPath}`
  /// and its relationship must exist in `word/_rels/document.xml.rels`.
  void _writeInlineImage(StringBuffer buf, _DocxImageRef ref, int docPrId) {
    buf.write('<w:p><w:r><w:drawing>');
    buf.write('<wp:inline distT="0" distB="0" distL="0" distR="0">');
    buf.write('<wp:extent cx="${ref.widthEmu}" cy="${ref.heightEmu}"/>');
    buf.write('<wp:docPr id="$docPrId" name="Image $docPrId"/>');
    buf.write('<wp:cNvGraphicFramePr>');
    buf.write('<a:graphicFrameLocks noChangeAspect="1"/>');
    buf.write('</wp:cNvGraphicFramePr>');
    buf.write('<a:graphic>');
    buf.write('<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">');
    buf.write('<pic:pic>');
    buf.write('<pic:nvPicPr>');
    buf.write('<pic:cNvPr id="$docPrId" name="Image $docPrId"/>');
    buf.write('<pic:cNvPicPr/>');
    buf.write('</pic:nvPicPr>');
    buf.write('<pic:blipFill>');
    buf.write('<a:blip r:embed="${ref.relId}"/>');
    buf.write('<a:stretch><a:fillRect/></a:stretch>');
    buf.write('</pic:blipFill>');
    buf.write('<pic:spPr>');
    buf.write('<a:xfrm>');
    buf.write('<a:off x="0" y="0"/>');
    buf.write('<a:ext cx="${ref.widthEmu}" cy="${ref.heightEmu}"/>');
    buf.write('</a:xfrm>');
    buf.write('<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>');
    buf.write('</pic:spPr>');
    buf.write('</pic:pic>');
    buf.write('</a:graphicData>');
    buf.write('</a:graphic>');
    buf.write('</wp:inline>');
    buf.write('</w:drawing></w:r></w:p>');
  }

  void _writeAiNarrativeParagraph(
    StringBuffer buf,
    String narrative,
  ) {
    final accentHex = _pdfColorToHex(_config.accentColor);

    // AI label
    buf.write('<w:p><w:r><w:rPr>');
    buf.write('<w:sz w:val="16"/>');
    buf.write('<w:i/>');
    buf.write('<w:color w:val="$accentHex"/>');
    buf.write('</w:rPr><w:t xml:space="preserve">AI-Generated Narrative</w:t></w:r></w:p>');

    // Narrative text — split by newlines for proper paragraphing
    final paragraphs = narrative.split('\n').where((p) => p.trim().isNotEmpty);
    for (final para in paragraphs) {
      buf.write('<w:p><w:pPr>');
      buf.write('<w:ind w:left="240"/>');
      buf.write('<w:pBdr><w:left w:val="single" w:sz="12" w:space="8" '
          'w:color="$accentHex"/></w:pBdr>');
      buf.write('</w:pPr>');
      buf.write('<w:r><w:rPr><w:sz w:val="18"/></w:rPr>');
      buf.write('<w:t xml:space="preserve">');
      buf.write(_escapeXml(para.trim()));
      buf.write('</w:t></w:r></w:p>');
    }
  }

  void _writeRecommendationsSection(
    StringBuffer buf,
    List<ReportRecommendationItem> items,
  ) {
    _writeHeading(buf, 'Professional Observations & Recommendations', 'Heading1');

    // Group by category
    final grouped = <String, List<ReportRecommendationItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    for (final entry in grouped.entries) {
      _writeHeading(buf, entry.key, 'Heading2');

      // Table: Severity | Screen | Observation | Recommendation
      buf.write('<w:tbl>');
      buf.write('<w:tblPr>');
      buf.write('<w:tblStyle w:val="ReportTable"/>');
      buf.write('<w:tblW w:w="5000" w:type="pct"/>');
      buf.write('</w:tblPr>');

      buf.write('<w:tblGrid>');
      buf.write('<w:gridCol w:w="1200"/>');
      buf.write('<w:gridCol w:w="2200"/>');
      buf.write('<w:gridCol w:w="2800"/>');
      buf.write('<w:gridCol w:w="3800"/>');
      buf.write('</w:tblGrid>');

      // Header row
      buf.write('<w:tr>');
      _writeTableCell(buf, 'Severity', bold: true, shading: 'E0F2F1');
      _writeTableCell(buf, 'Screen', bold: true, shading: 'E0F2F1');
      _writeTableCell(buf, 'Observation', bold: true, shading: 'E0F2F1');
      _writeTableCell(buf, 'Recommendation', bold: true, shading: 'E0F2F1');
      buf.write('</w:tr>');

      // Data rows
      for (var i = 0; i < entry.value.length; i++) {
        final item = entry.value[i];
        final rowShading = i.isOdd ? 'F5F5F5' : null;
        buf.write('<w:tr>');
        _writeRecommendationSeverityCell(buf, item.severity, shading: rowShading);
        _writeTableCell(buf, item.screenTitle, shading: rowShading);
        _writeTableCell(buf, item.reason, shading: rowShading);
        _writeTableCell(buf, item.suggestedText, shading: rowShading);
        buf.write('</w:tr>');
      }

      buf.write('</w:tbl>');
      buf.write('<w:p/>'); // space after table
    }

    // Footer
    _writeStyledParagraph(buf,
        'Based on RICS Home Survey Standard guidelines.',
        fontSize: 16, color: '888888');
  }

  void _writeRecommendationSeverityCell(
    StringBuffer buf,
    String severity, {
    String? shading,
  }) {
    final color = switch (severity) {
      'High' => 'C62828',
      'Moderate' => 'E65100',
      _ => '1565C0',
    };
    buf.write('<w:tc>');
    if (shading != null) {
      buf.write('<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$shading"/></w:tcPr>');
    }
    buf.write('<w:p><w:r><w:rPr><w:b/><w:color w:val="$color"/></w:rPr>');
    buf.write('<w:t xml:space="preserve">');
    buf.write(_escapeXml(severity));
    buf.write('</w:t></w:r></w:p></w:tc>');
  }

  void _writeFieldsTable(
    StringBuffer buf,
    List<ReportField> fields,
  ) {
    buf.write('<w:tbl>');
    buf.write('<w:tblPr>');
    buf.write('<w:tblStyle w:val="ReportTable"/>');
    buf.write('<w:tblW w:w="5000" w:type="pct"/>');
    buf.write('</w:tblPr>');

    // Column widths
    buf.write('<w:tblGrid>');
    buf.write('<w:gridCol w:w="3500"/>');
    buf.write('<w:gridCol w:w="5500"/>');
    buf.write('</w:tblGrid>');

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final shadingHex = i.isOdd ? 'F5F5F5' : null;

      buf.write('<w:tr>');

      // Label cell
      _writeTableCell(buf, field.label, bold: true, shading: shadingHex);

      // Value cell
      final displayVal = field.displayValue.isEmpty ? '-' : field.displayValue;
      _writeTableCell(buf, displayVal, shading: shadingHex);

      buf.write('</w:tr>');
    }

    buf.write('</w:tbl>');
    // Space after table
    buf.write('<w:p/>');
  }

  void _writeTableCell(
    StringBuffer buf,
    String text, {
    bool bold = false,
    String? shading,
  }) {
    buf.write('<w:tc>');
    if (shading != null) {
      buf.write('<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$shading"/></w:tcPr>');
    }
    buf.write('<w:p><w:r>');
    if (bold) buf.write('<w:rPr><w:b/></w:rPr>');
    buf.write('<w:t xml:space="preserve">');
    buf.write(_escapeXml(text));
    buf.write('</w:t></w:r></w:p></w:tc>');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  IMAGE PRE-LOADING
  // ═══════════════════════════════════════════════════════════════════

  /// Display dimensions in EMU (English Metric Units).
  /// 1 inch = 914400 EMU.  At 96 DPI, 1 pixel = 9525 EMU.
  static const _photoWidthEmu = 4500000; // ~4.92 inches
  static const _photoHeightEmu = 3375000; // ~3.69 inches (4:3)
  static const _sigWidthEmu = 1800000; // ~1.97 inches
  static const _sigHeightEmu = 750000; // ~0.82 inches
  static const _maxDocxPhotos = 100;

  /// Pre-load signature and photo images from disk into byte arrays.
  ///
  /// Each image gets a unique relationship ID and is assigned a path
  /// inside the ZIP's `word/media/` folder.  The returned bundle is
  /// passed through the archive-building pipeline.
  Future<_DocxImageBundle> _preloadImages(ReportDocument doc) async {
    final allImages = <_DocxImageRef>[];
    final sigLookup = <String, _DocxImageRef>{};
    final photoImages = <_DocxImageRef>[];
    var imageIdx = 1;
    var relIdx = 2; // rId1 = styles; images start at rId2

    // Signature images
    if (_config.includeSignatures) {
      for (final sig in doc.signatures) {
        if (sig.filePath.isEmpty) continue;
        final file = File(sig.filePath);
        if (!await file.exists()) continue;
        try {
          final bytes = await file.readAsBytes();
          final ext = _detectImageFormat(bytes);
          final ref = _DocxImageRef(
            relId: 'rId$relIdx',
            mediaPath: 'media/image$imageIdx.$ext',
            bytes: bytes,
            extension: ext,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            widthEmu: _sigWidthEmu,
            heightEmu: _sigHeightEmu,
          );
          allImages.add(ref);
          sigLookup[sig.filePath] = ref;
          imageIdx++;
          relIdx++;
        } catch (e) {
          AppLogger.w('DocxGen', 'Failed to load signature image: $e');
        }
      }
    }

    // Photo images
    if (_config.includePhotos) {
      var paths = doc.photoFilePaths;
      if (paths.length > _maxDocxPhotos) {
        AppLogger.w('DocxGen',
            'Capping photos from ${paths.length} to $_maxDocxPhotos');
        paths = paths.sublist(0, _maxDocxPhotos);
      }
      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) continue;
        try {
          final bytes = await file.readAsBytes();
          final ext = _detectImageFormat(bytes);
          final ref = _DocxImageRef(
            relId: 'rId$relIdx',
            mediaPath: 'media/image$imageIdx.$ext',
            bytes: bytes,
            extension: ext,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            widthEmu: _photoWidthEmu,
            heightEmu: _photoHeightEmu,
          );
          allImages.add(ref);
          photoImages.add(ref);
          imageIdx++;
          relIdx++;
        } catch (e) {
          AppLogger.w('DocxGen', 'Failed to load photo: $e');
        }
      }
    }

    AppLogger.d('DocxGen',
        'Pre-loaded ${allImages.length} images '
        '(${sigLookup.length} signatures, ${photoImages.length} photos)');

    return _DocxImageBundle(
      allImages: allImages,
      signatureLookup: sigLookup,
      photoImages: photoImages,
    );
  }

  /// Detect image format from magic bytes.
  ///
  /// Returns `'png'` for PNG files (magic: 89 50 4E 47), `'jpeg'` for
  /// everything else (JPEG is the most common format for photos).
  static String _detectImageFormat(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    return 'jpeg';
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  /// XML-escape text for safe embedding in OOXML.
  ///
  /// Delegates to [PdfSharedUtils.sanitize] first (strips HTML, decodes
  /// entities including numeric refs, normalises whitespace) then applies
  /// the five XML character escapes.
  String _escapeXml(String text) {
    return PdfSharedUtils.sanitize(text)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _pdfColorToHex(PdfColor color) {
    final r = (color.red * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.green * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.blue * 255).round().toRadixString(16).padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }

  Future<String> _saveDocx(Uint8List bytes, String title) async {
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final sanitized = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = '${sanitized}_v2_$timestamp.docx';

    final file = File('${reportsDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _reportProgress(String stage, double percent) {
    onProgress?.call(ExportProgress(
      stage: stage,
      percent: percent,
      message: stage,
    ));
  }
}

/// Reference to an image embedded in the DOCX ZIP archive.
class _DocxImageRef {
  const _DocxImageRef({
    required this.relId,
    required this.mediaPath,
    required this.bytes,
    required this.extension,
    required this.contentType,
    required this.widthEmu,
    required this.heightEmu,
  });

  /// Relationship ID (e.g. "rId2") used in DrawingML `r:embed` attributes.
  final String relId;

  /// Path inside the ZIP (e.g. "media/image1.png").
  final String mediaPath;

  final Uint8List bytes;

  /// File extension without dot: "png" or "jpeg".
  final String extension;

  /// MIME type: "image/png" or "image/jpeg".
  final String contentType;

  /// Display width in EMU (English Metric Units).
  final int widthEmu;

  /// Display height in EMU.
  final int heightEmu;
}

/// Bundle of pre-loaded images for the DOCX generator.
class _DocxImageBundle {
  const _DocxImageBundle({
    required this.allImages,
    required this.signatureLookup,
    required this.photoImages,
  });

  /// Every image ref (signatures + photos), used for content types and rels.
  final List<_DocxImageRef> allImages;

  /// Signature image refs keyed by original file path.
  final Map<String, _DocxImageRef> signatureLookup;

  /// Photo image refs in display order.
  final List<_DocxImageRef> photoImages;

  bool get hasImages => allImages.isNotEmpty;
  bool get hasPng => allImages.any((r) => r.extension == 'png');
  bool get hasJpeg => allImages.any((r) => r.extension == 'jpeg');
}

/// Isolate-safe representation of an archive file entry.
class _ArchiveEntry {
  const _ArchiveEntry(this.name, this.size, this.content);
  final String name;
  final int size;
  final Uint8List content;
}

/// Top-level function for compute() — ZIP-encodes archive entries off main thread.
List<int> _encodeZipIsolate(List<_ArchiveEntry> entries) {
  final archive = Archive();
  for (final entry in entries) {
    archive.addFile(ArchiveFile(entry.name, entry.size, entry.content));
  }
  final encoded = ZipEncoder().encode(archive);
  if (encoded == null) {
    throw StateError(
      'DOCX ZIP encoding failed: ZipEncoder returned null '
      '(${entries.length} entries, '
      '${entries.fold<int>(0, (sum, e) => sum + e.size)} bytes total)',
    );
  }
  return encoded;
}
