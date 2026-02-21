import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feature_flags/feature_flag_providers.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/report_document.dart';
import '../providers/export_providers.dart';
import 'export_dialog.dart';

/// Modal bottom sheet for choosing export format/style and options.
class ExportBottomSheet extends ConsumerStatefulWidget {
  const ExportBottomSheet({
    required this.surveyId,
    required this.surveyTitle,
    required this.reportType,
    super.key,
  });

  final String surveyId;
  final String surveyTitle;
  final ReportType reportType;

  static Future<void> show(
    BuildContext context, {
    required String surveyId,
    required String surveyTitle,
    required ReportType reportType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExportBottomSheet(
        surveyId: surveyId,
        surveyTitle: surveyTitle,
        reportType: reportType,
      ),
    );
  }

  @override
  ConsumerState<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends ConsumerState<ExportBottomSheet> {
  ExportFormat _format = ExportFormat.pdf;
  bool _includePhotos = true;
  bool _includePhrases = true;
  bool _includeSignatures = true;
  bool _includeAiNarrative = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Export Report',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.surveyTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Format grid
          Text(
            'Format',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FormatTile(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  isSelected: _format == ExportFormat.pdf,
                  onTap: () => setState(() => _format = ExportFormat.pdf),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FormatTile(
                  label: 'DOCX',
                  icon: Icons.description_rounded,
                  isSelected: _format == ExportFormat.docx,
                  onTap: () => setState(() => _format = ExportFormat.docx),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Options
          Text(
            'Options',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _OptionSwitch(
            label: 'Include Photos',
            value: _includePhotos,
            onChanged: (v) => setState(() => _includePhotos = v),
          ),
          _OptionSwitch(
            label: 'Include Phrases',
            value: _includePhrases,
            onChanged: (v) => setState(() => _includePhrases = v),
          ),
          _OptionSwitch(
            label: 'Include Signatures',
            value: _includeSignatures,
            onChanged: (v) => setState(() => _includeSignatures = v),
          ),
          if (ref.watch(aiFeatureEnabledProvider(AiFeature.aiEnhancedExport)))
            _AiNarrativeSwitch(
              value: _includeAiNarrative,
              onChanged: (v) => setState(() => _includeAiNarrative = v),
            ),
          const SizedBox(height: 16),

          // Export button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startExport,
              icon: const Icon(Icons.file_download_outlined),
              label: Text('Export ${_format == ExportFormat.pdf ? 'PDF' : 'DOCX'}'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _startExport() {
    final config = ExportConfig(
      format: _format,
      includePhotos: _includePhotos,
      includePhrases: _includePhrases,
      includeSignatures: _includeSignatures,
      includeAiNarrative: _includeAiNarrative,
    );

    // Reset export state before the dialog mounts — ensures the provider
    // starts clean even if a previous export left stale state behind.
    ref.read(exportProvider.notifier).reset();

    // Capture the root navigator BEFORE popping, so we can show the dialog
    // on a context that's still in the widget tree.
    final navigator = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();

    // Use the navigator's overlay context (which survives the bottom sheet
    // being removed) to show the export progress dialog.
    final overlayContext = navigator.overlay?.context;
    if (overlayContext != null) {
      ExportDialog.show(
        overlayContext,
        surveyId: widget.surveyId,
        surveyTitle: widget.surveyTitle,
        reportType: widget.reportType,
        config: config,
      );
    }
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: enabled ? null : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            )
          : null,
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _AiNarrativeSwitch extends StatelessWidget {
  const _AiNarrativeSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Row(
        children: [
          Text('AI Enhanced Report', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'AI',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        'Adds AI-generated executive summary and section narratives',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
