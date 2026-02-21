import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/database/database_providers.dart';
import '../../domain/models/generated_report.dart';
import '../widgets/email_compose_sheet.dart';

/// Provider that loads a single report by ID from the database.
final reportByIdProvider =
    FutureProvider.autoDispose.family<GeneratedReport?, String>(
  (ref, reportId) async {
    final dao = ref.watch(generatedReportsDaoProvider);
    final data = await dao.getReportById(reportId);
    if (data == null) return null;
    return GeneratedReport(
      id: data.id,
      surveyId: data.surveyId,
      surveyTitle: data.surveyTitle,
      filePath: data.filePath,
      fileName: data.fileName,
      sizeBytes: data.sizeBytes,
      generatedAt: data.generatedAt,
      moduleType: data.moduleType,
      format: data.format,
      remoteUrl: data.remoteUrl,
      checksum: data.checksum,
    );
  },
);

/// Full-screen report preview page.
/// - PDF: renders in-app via PdfPreview
/// - DOCX: shows info card with open/share actions
class ReportPreviewPage extends ConsumerWidget {
  const ReportPreviewPage({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReport = ref.watch(reportByIdProvider(reportId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return asyncReport.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Report Preview')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Report Preview')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load report', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(e.toString(), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
      data: (report) {
        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Report Preview')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.find_in_page_outlined,
                      size: 48, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Report not found',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _navigateBack(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final fileExists = File(report.filePath).existsSync();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Report Preview'),
            leading: BackButton(onPressed: () => _navigateBack(context)),
          ),
          body: Column(
            children: [
              // Header — constrained so it never steals too much from the PDF viewer
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.18,
                ),
                child: SingleChildScrollView(
                  child: _ReportHeader(report: report, fileExists: fileExists),
                ),
              ),
              const Divider(height: 1),
              // Body — Expanded gives all remaining space to the PDF viewer
              Expanded(
                child: fileExists
                    ? report.isPdf
                        ? _PdfPreviewBody(filePath: report.filePath)
                        : _DocxInfoBody(report: report)
                    : _FileMissingBody(theme: theme, colorScheme: colorScheme),
              ),
              // Action bar at bottom — inside body to avoid bottomNavigationBar sizing issues
              if (fileExists) _ReportActionBar(report: report),
            ],
          ),
        );
      },
    );
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.forms);
    }
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report, required this.fileExists});

  final GeneratedReport report;
  final bool fileExists;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formatLabel = report.isPdf ? 'PDF' : 'DOCX';
    final moduleLabel = report.moduleType == 'valuation' ? 'Valuation' : 'Inspection';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.surveyTitle.isNotEmpty ? report.surveyTitle : report.fileName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Badge(label: formatLabel, color: colorScheme.primary),
              _Badge(label: moduleLabel, color: colorScheme.secondary),
              if (report.remoteUrl != null)
                _Badge(
                  label: 'Uploaded',
                  color: colorScheme.primary,
                  icon: Icons.cloud_done_outlined,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDate(report.generatedAt)} · ${report.formattedSize}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (!fileExists) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
                const SizedBox(width: 4),
                Text(
                  'File missing from device',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfPreviewBody extends StatelessWidget {
  const _PdfPreviewBody({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: useActions must be false to prevent overflow.
    //
    // PdfPreview internally builds a Column containing:
    //   1. An Expanded PDF page ListView
    //   2. An action bar row (print/share/page-format buttons)
    //
    // When useActions is true (default), that internal action bar competes
    // for vertical space with our BottomAppBar. The combined height of:
    //   AppBar + Header + PdfPreview's internal actions + BottomAppBar
    //   + system navigation bar insets
    // exceeds the screen height → "BOTTOM OVERFLOWED BY XX PIXELS".
    //
    // Setting useActions: false removes PdfPreview's internal toolbar
    // entirely, so only our BottomAppBar occupies the bottom slot.
    return PdfPreview(
      build: (_) => File(filePath).readAsBytes(),
      useActions: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowPrinting: false,
      allowSharing: false,
      padding: EdgeInsets.zero,
      pdfFileName: filePath.split(Platform.pathSeparator).last,
    );
  }
}

/// DOCX info card that auto-launches the file in the native viewer.
///
/// DOCX files are complex ZIP archives of XML, styles, and media.
/// Rendering them in-app requires a full word-processing engine.
/// The industry-standard approach: delegate to the OS native viewer
/// (Microsoft Word, Google Docs, etc.) via OpenFilex.open().
///
/// On screen entry, the file is automatically opened in the device's
/// default document viewer. A fallback button is shown in case the
/// auto-launch fails or the user dismisses the viewer and wants to
/// re-open.
class _DocxInfoBody extends StatefulWidget {
  const _DocxInfoBody({required this.report});

  final GeneratedReport report;

  @override
  State<_DocxInfoBody> createState() => _DocxInfoBodyState();
}

class _DocxInfoBodyState extends State<_DocxInfoBody> {
  bool _isOpening = true;
  String? _openError;

  @override
  void initState() {
    super.initState();
    // Auto-launch after the first frame so context is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _autoOpen();
    });
  }

  Future<void> _autoOpen() async {
    setState(() {
      _isOpening = true;
      _openError = null;
    });

    try {
      final result = await OpenFilex.open(widget.report.filePath);
      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _isOpening = false;
          _openError = result.message;
        });
      } else {
        setState(() => _isOpening = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOpening = false;
        _openError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Word Document',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.report.fileName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.report.formattedSize,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_isOpening) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Opening document in external viewer...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              if (_openError != null) ...[
                Text(
                  'Could not open automatically.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _autoOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open in Word / Docs'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'DOCX files are best viewed in Microsoft Word,\nGoogle Docs, or your device\'s document viewer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileMissingBody extends StatelessWidget {
  const _FileMissingBody({required this.theme, required this.colorScheme});

  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.file_present_rounded, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'File Not Found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The report file has been deleted from this device.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportActionBar extends StatelessWidget {
  const _ReportActionBar({required this.report});

  final GeneratedReport report;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onPressed: () => _share(context),
            ),
            _ActionButton(
              icon: Icons.email_outlined,
              label: 'Email',
              onPressed: () => _email(context),
            ),
            _ActionButton(
              icon: Icons.open_in_new_rounded,
              label: 'Open',
              onPressed: () => _open(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      final mimeType = report.isPdf
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      await Share.shareXFiles(
        [XFile(report.filePath, mimeType: mimeType)],
        subject: 'Survey Report - ${report.surveyTitle}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _email(BuildContext context) async {
    EmailComposeSheet.show(
      context,
      reportInfo: EmailReportInfo.fromGeneratedReport(report),
    );
  }

  Future<void> _open(BuildContext context) async {
    try {
      if (report.isPdf) {
        final bytes = await File(report.filePath).readAsBytes();
        await Printing.sharePdf(bytes: bytes, filename: report.fileName);
      } else {
        final result = await OpenFilex.open(report.filePath);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open: $e')),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
