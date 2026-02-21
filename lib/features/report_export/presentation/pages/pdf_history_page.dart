import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/generated_report.dart';
import '../providers/pdf_history_provider.dart';

/// Page showing all locally generated PDF reports.
class PdfHistoryPage extends ConsumerWidget {
  const PdfHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(pdfHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(pdfHistoryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(context, ref, state, theme, colorScheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PdfHistoryState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No reports generated yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generated reports will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(pdfHistoryProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ReportCard(
          report: state.reports[index],
        ),
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});

  final GeneratedReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fileExists = File(report.filePath).existsSync();
    final formatLabel = report.isPdf ? 'PDF' : 'DOCX';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: fileExists
            ? () => context.push(Routes.reportPreviewPath(report.id))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Format icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fileExists
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  report.isPdf
                      ? Icons.picture_as_pdf_rounded
                      : Icons.description_outlined,
                  color: fileExists
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.surveyTitle.isNotEmpty
                          ? report.surveyTitle
                          : report.fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _FormatBadge(label: formatLabel, colorScheme: colorScheme),
                        const SizedBox(width: 4),
                        _ModuleTypeBadge(
                          moduleType: report.moduleType,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_formatDate(report.generatedAt)} · ${report.formattedSize}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!fileExists) ...[
                      const SizedBox(height: 4),
                      Text(
                        'File missing from device',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<_ReportAction>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                onSelected: (action) =>
                    _handleAction(context, ref, action),
                itemBuilder: (context) => [
                  if (fileExists) ...[
                    const PopupMenuItem(
                      value: _ReportAction.open,
                      child: ListTile(
                        leading: Icon(Icons.open_in_new_rounded),
                        title: Text('Open'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: _ReportAction.share,
                      child: ListTile(
                        leading: Icon(Icons.share_rounded),
                        title: Text('Share'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: _ReportAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, _ReportAction action) {
    final notifier = ref.read(pdfHistoryProvider.notifier);

    switch (action) {
      case _ReportAction.open:
        notifier.openReport(report);
      case _ReportAction.share:
        notifier.shareReport(report);
      case _ReportAction.delete:
        _confirmDelete(context, ref);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
          'This will permanently delete this PDF report from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(pdfHistoryProvider.notifier).deleteReport(report.id);
            },
            child: const Text('Delete'),
          ),
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

enum _ReportAction { open, share, delete }

class _FormatBadge extends StatelessWidget {
  const _FormatBadge({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _ModuleTypeBadge extends StatelessWidget {
  const _ModuleTypeBadge({
    required this.moduleType,
    required this.colorScheme,
  });

  final String moduleType;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isValuation = moduleType == 'valuation';
    final label = isValuation ? 'Valuation' : 'Inspection';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isValuation
            ? colorScheme.tertiaryContainer
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isValuation
              ? colorScheme.tertiary
              : colorScheme.secondary,
        ),
      ),
    );
  }
}
