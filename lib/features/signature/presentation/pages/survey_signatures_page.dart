import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/signature_item.dart';
import '../providers/signature_provider.dart';
import '../widgets/signature_pad.dart';
import 'signature_capture_page.dart';

/// Page displaying all signatures for a survey
class SurveySignaturesPage extends ConsumerWidget {
  const SurveySignaturesPage({
    required this.surveyId,
    required this.surveyTitle,
    super.key,
  });

  final String surveyId;
  final String surveyTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(surveySignaturesProvider(surveyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(surveyTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addSignature(context),
            tooltip: 'Add signature',
          ),
          AppSpacing.gapHorizontalSm,
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? _buildErrorState(context, ref, state.errorMessage!)
              : state.signatures.isEmpty
                  ? _buildEmptyState(context)
                  : _buildSignaturesList(context, ref, state.signatures),
      bottomNavigationBar: state.signatures.isNotEmpty
          ? Container(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: FilledButton.icon(
                onPressed: () => _addSignature(context),
                icon: const Icon(Icons.draw_rounded),
                label: const Text('Add Signature'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.draw_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            AppSpacing.gapVerticalLg,
            Text(
              'No signatures yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'Capture signatures from surveyors, clients, or other parties involved in this survey.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalXl,
            FilledButton.icon(
              onPressed: () => _addSignature(context),
              icon: const Icon(Icons.draw_rounded),
              label: const Text('Add First Signature'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'Failed to load signatures',
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLg,
            OutlinedButton.icon(
              onPressed: () {
                ref.read(surveySignaturesProvider(surveyId).notifier).refresh();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignaturesList(
    BuildContext context,
    WidgetRef ref,
    List<SignatureItem> signatures,
  ) => ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: signatures.length,
      itemBuilder: (context, index) => _SignatureCard(
          signature: signatures[index],
          surveyId: surveyId,
          onDelete: () => _deleteSignature(context, ref, signatures[index]),
        ),
    );

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

    if (confirm == true) {
      ref
          .read(surveySignaturesProvider(surveyId).notifier)
          .deleteSignature(signature.id);
    }
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.signature,
    required this.surveyId,
    required this.onDelete,
  });

  final SignatureItem signature;
  final String surveyId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signature preview
          AspectRatio(
            aspectRatio: 16 / 7,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: _buildSignaturePreview(colorScheme),
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Signer info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (signature.signerName != null) ...[
                        Text(
                          signature.signerName!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (signature.signerRole != null)
                          Text(
                            _formatRole(signature.signerRole!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ] else
                        Text(
                          'Anonymous signature',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      AppSpacing.gapVerticalXs,
                      Text(
                        dateFormat.format(signature.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePreview(ColorScheme colorScheme) {
    // Try to show saved preview image first
    if (signature.previewPath != null) {
      final file = File(signature.previewPath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildStrokesPreview(),
              ),
            );
          }
          return _buildStrokesPreview();
        },
      );
    }

    return _buildStrokesPreview();
  }

  Widget _buildStrokesPreview() {
    // Render strokes directly
    if (signature.strokes.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
        child: SignaturePreview(
          strokes: signature.strokes,
          showBorder: false,
          borderRadius: 0,
        ),
      );
    }

    return const Center(
      child: Icon(
        Icons.draw_outlined,
        size: 32,
        color: Colors.grey,
      ),
    );
  }

  String _formatRole(String role) {
    if (role.isEmpty) return role;
    return role
        .replaceAllMapped(
          RegExp('([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
