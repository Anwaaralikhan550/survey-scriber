import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/router/routes.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import '../providers/export_providers.dart';
import 'email_compose_sheet.dart';

/// Progress / result dialog for report exports.
///
/// Shows a preparing indicator, then progress, then on success shows a
/// professional action-based modal matching industry-standard UX.
class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({
    required this.surveyId,
    required this.surveyTitle,
    required this.reportType,
    required this.config,
    super.key,
  });

  final String surveyId;
  final String surveyTitle;
  final ReportType reportType;
  final ExportConfig config;

  static Future<void> show(
    BuildContext context, {
    required String surveyId,
    required String surveyTitle,
    required ReportType reportType,
    required ExportConfig config,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => ExportDialog(
        surveyId: surveyId,
        surveyTitle: surveyTitle,
        reportType: reportType,
        config: config,
      ),
    );
  }

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  bool _exportStarted = false;

  @override
  void initState() {
    super.initState();
    // Schedule export start after the first build completes.
    // Using addPostFrameCallback guarantees that build() has run first,
    // establishing the ref.watch listener on the provider before the
    // export mutates state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_exportStarted) _startExport();
    });
  }

  void _startExport() {
    if (_exportStarted) return;
    _exportStarted = true;
    try {
      final notifier = ref.read(exportProvider.notifier);
      // Ensure we start from a clean state (provider is not autoDispose,
      // so stale state from a cancelled/previous export may linger).
      notifier.reset();
      if (widget.reportType == ReportType.inspection) {
        notifier.exportInspection(widget.surveyId, config: widget.config);
      } else {
        notifier.exportValuation(widget.surveyId, config: widget.config);
      }
    } catch (e) {
      // If provider access fails (should not happen), force a rebuild so the
      // user sees the Preparing state with a Cancel button instead of a freeze.
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportProvider);
    final theme = Theme.of(context);

    // Safety net: if the post-frame callback hasn't fired the export yet
    // and the state is still idle, trigger it now via a microtask.
    // This handles edge cases where addPostFrameCallback is delayed during
    // complex route transitions (bottom sheet pop → dialog mount).
    if (!_exportStarted && !state.isExporting && !state.isComplete && !state.hasError) {
      Future.microtask(() {
        if (mounted && !_exportStarted) _startExport();
      });
    }

    // Success state uses a custom Dialog layout (no AlertDialog actions).
    if (state.isComplete) {
      return _SuccessDialog(
        result: state.result!,
        surveyTitle: widget.surveyTitle,
        reportType: widget.reportType,
      );
    }

    // Preparing / progress / error states use a compact AlertDialog.
    final Widget content;
    if (state.isExporting) {
      content = _buildProgress(state, theme);
    } else if (state.hasError) {
      content = _buildError(state, theme);
    } else {
      content = _buildPreparing(theme);
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [content],
        ),
      ),
      actions: _buildActions(state),
    );
  }

  Widget _buildPreparing(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
        const SizedBox(height: 16),
        Text(
          'Preparing...',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Setting up export',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProgress(ExportState state, ThemeData theme) {
    final progress = state.progress;
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            value: progress?.percent,
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          progress?.stage ?? 'Preparing...',
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          progress?.message ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress.percent * 100).round()}%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildError(ExportState state, ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.error_outline_rounded,
            size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Text(
          'Export Failed',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.errorMessage ?? 'An unknown error occurred.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget>? _buildActions(ExportState state) {
    if (state.isExporting || (!state.isComplete && !state.hasError)) {
      return [
        TextButton(
          onPressed: () {
            ref.read(exportProvider.notifier).reset();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ];
    }

    if (state.hasError) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            _exportStarted = false;
            ref.read(exportProvider.notifier).reset();
            _startExport();
          },
          child: const Text('Retry'),
        ),
      ];
    }

    return null;
  }
}

// ── Professional Export Success Dialog ──────────────────────────────────

/// Full-screen success dialog matching the reference design:
/// Header (icon + title + subtitle) → Checkmark → "PDF Created" →
/// 3 action tiles → Send Report → View All Reports → Done.
class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog({
    required this.result,
    required this.surveyTitle,
    required this.reportType,
  });

  final ExportResult result;
  final String surveyTitle;
  final ReportType reportType;

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  /// Tracks which action is currently in-flight (null = idle).
  /// Prevents double-taps from firing multiple OS intents.
  String? _busyAction;

  ExportResult get result => widget.result;
  String get surveyTitle => widget.surveyTitle;
  ReportType get reportType => widget.reportType;

  bool get _isPdf => result.format == ExportFormat.pdf;
  String get _formatLabel => _isPdf ? 'PDF' : 'DOCX';
  String get _reportTypeLabel =>
      reportType == ReportType.inspection ? 'Inspection' : 'Valuation';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header: format icon + title + survey title ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.description_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export $_formatLabel',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$_reportTypeLabel - $surveyTitle',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Checkmark circle ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                ),
                child: Icon(Icons.check_rounded, size: 40, color: primary),
              ),

              const SizedBox(height: 16),

              // ── Title + subtitle ──
              Text(
                '$_formatLabel Created',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your report is ready to view or share.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              // ── Warning banner (AI failed, upload failed, etc.) ──
              if (result.warningMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.warningMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Three action tiles: Preview / Share / Print ──
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.visibility_outlined,
                      label: 'Preview',
                      enabled: _busyAction == null,
                      onTap: () => _guardedAction('preview', () => _onPreview(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      enabled: _busyAction == null,
                      onTap: () => _guardedAction('share', () => _onShare(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.print_outlined,
                      label: 'Print',
                      enabled: _busyAction == null,
                      onTap: () => _guardedAction('print', () => _onPrint(context)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Send Report button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _onSendReport(context),
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: const Text('Send Report'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── View All Reports ──
              TextButton.icon(
                onPressed: () => _onViewAllReports(context),
                icon: Icon(Icons.history_rounded, size: 20, color: primary),
                label: Text(
                  'View All Reports',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Done button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),

              // ── Upload confirmation (subtle) ──
              if (result.uploadedToBackend) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 13, color: primary),
                    const SizedBox(width: 4),
                    Text(
                      'Synced to server',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Action handlers ────────────────────────────────────────────────

  /// Execute [action] only if no other action is in-flight.
  Future<void> _guardedAction(String name, Future<void> Function() action) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = name);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  /// Verify the exported file still exists on disk.  Returns false and
  /// shows a snackbar when the file has been removed (OS storage cleanup,
  /// user deletion, etc.).
  bool _verifyFileExists(BuildContext context) {
    if (File(result.outputPath).existsSync()) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report file is no longer available. Please re-export.'),
      ),
    );
    return false;
  }

  /// Open file with system viewer.
  Future<void> _onPreview(BuildContext context) async {
    if (!_verifyFileExists(context)) return;
    await OpenFilex.open(result.outputPath);
  }

  /// Open OS share sheet with the file attached.
  Future<void> _onShare(BuildContext context) async {
    if (!_verifyFileExists(context)) return;
    await Share.shareXFiles(
      [XFile(result.outputPath)],
      subject: '$_reportTypeLabel Report - $surveyTitle',
    );
  }

  /// Print the file.
  Future<void> _onPrint(BuildContext context) async {
    if (!_verifyFileExists(context)) return;
    if (_isPdf) {
      final bytes = await File(result.outputPath).readAsBytes();
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } else {
      // DOCX has no direct print API — open with system to let user print.
      await OpenFilex.open(result.outputPath);
    }
  }

  /// Open email compose sheet for sending the report.
  Future<void> _onSendReport(BuildContext context) async {
    final reportInfo = EmailReportInfo.fromExportResult(
      result,
      surveyTitle: surveyTitle,
      reportType: reportType,
    );
    await EmailComposeSheet.show(context, reportInfo: reportInfo);
  }

  /// Navigate to report history.
  void _onViewAllReports(BuildContext context) {
    Navigator.of(context).pop();
    GoRouter.of(context).push(Routes.pdfHistory);
  }
}

// ── Action tile widget ─────────────────────────────────────────────────

/// Outlined icon + label card used for the Preview / Share / Print row.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: fgColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
