import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/media/presentation/widgets/photo_grid.dart';
import '../../../features/signature/domain/entities/signature_item.dart';
import '../../../features/signature/presentation/pages/signature_capture_page.dart';
import '../../../features/signature/presentation/providers/signature_provider.dart';
import '../../../features/signature/presentation/widgets/signature_pad.dart';

/// Unified page combining photo/sketch attachments and signature capture.
/// Used by both Inspection and Valuation modules.
class AttachmentsSignaturesPage extends ConsumerWidget {
  const AttachmentsSignaturesPage({
    required this.surveyId,
    required this.surveyTitle,
    super.key,
  });

  final String surveyId;
  final String surveyTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sigState = ref.watch(surveySignaturesProvider(surveyId));
    final photoSectionId = 'survey_attachments_$surveyId';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attachments & Signatures'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Photos / Sketches Section ─────────────────────────────
          _SectionHeader(
            icon: Icons.photo_library_outlined,
            title: 'Photos & Sketches',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture floor plans, site sketches, and supporting photographs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          PhotoGrid(
            surveyId: surveyId,
            sectionId: photoSectionId,
            maxPhotos: 20,
            crossAxisCount: 3,
            showAddButton: true,
          ),

          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 16),

          // ── Signatures Section ────────────────────────────────────
          _SectionHeader(
            icon: Icons.draw_rounded,
            title: 'Signatures',
            color: const Color(0xFF1565C0),
            trailing: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addSignature(context),
              tooltip: 'Add signature',
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture surveyor, client, or other party signatures.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          if (sigState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (sigState.errorMessage != null)
            _SignatureErrorCard(
              error: sigState.errorMessage!,
              onRetry: () =>
                  ref.read(surveySignaturesProvider(surveyId).notifier).refresh(),
            )
          else if (sigState.signatures.isEmpty)
            _SignatureEmptyCard(onAdd: () => _addSignature(context))
          else
            ...sigState.signatures.map(
              (sig) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompactSignatureCard(
                  signature: sig,
                  onDelete: () => _deleteSignature(context, ref, sig),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addSignature(BuildContext context) async {
    await Navigator.of(context).push<SignatureItem>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SignatureCapturePage(surveyId: surveyId),
      ),
    );
  }

  Future<void> _deleteSignature(
    BuildContext context,
    WidgetRef ref,
    SignatureItem signature,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete signature?'),
        content: Text(
          signature.signerName != null
              ? 'Delete signature from ${signature.signerName}?'
              : 'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ref
          .read(surveySignaturesProvider(surveyId).notifier)
          .deleteSignature(signature.id);
    }
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, size: 20, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SignatureEmptyCard extends StatelessWidget {
  const _SignatureEmptyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.draw_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No signatures yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.draw_rounded, size: 18),
            label: const Text('Add Signature'),
          ),
        ],
      ),
    );
  }
}

class _SignatureErrorCard extends StatelessWidget {
  const _SignatureErrorCard({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
      ),
      child: Column(
        children: [
          Text(
            'Failed to load signatures',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CompactSignatureCard extends StatelessWidget {
  const _CompactSignatureCard({
    required this.signature,
    required this.onDelete,
  });

  final SignatureItem signature;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy \u2022 h:mm a');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signature preview
          AspectRatio(
            aspectRatio: 16 / 6,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: _buildPreview(colorScheme),
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signature.signerName ?? 'Anonymous',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (signature.signerRole != null)
                        Text(
                          _formatRole(signature.signerRole!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        dateFormat.format(signature.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme colorScheme) {
    if (signature.previewPath != null) {
      final file = File(signature.previewPath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildStrokesPreview(),
            );
          }
          return _buildStrokesPreview();
        },
      );
    }
    return _buildStrokesPreview();
  }

  Widget _buildStrokesPreview() {
    if (signature.strokes.isNotEmpty) {
      return SignaturePreview(
        strokes: signature.strokes,
        showBorder: false,
        borderRadius: 0,
      );
    }
    return const Center(
      child: Icon(Icons.draw_outlined, size: 28, color: Colors.grey),
    );
  }

  String _formatRole(String role) {
    if (role.isEmpty) return role;
    return role
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
