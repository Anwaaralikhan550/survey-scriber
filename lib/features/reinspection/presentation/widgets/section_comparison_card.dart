import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/comparison_result.dart';

/// Card displaying section-level comparison with changed fields
class SectionComparisonCard extends StatelessWidget {
  const SectionComparisonCard({
    required this.sectionDiff,
    this.onTap,
    this.expanded = false,
    super.key,
  });

  final SectionDiff sectionDiff;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(
          color: _getBorderColor(colorScheme),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _ChangeTypeIndicator(changeType: sectionDiff.changeType),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: Text(
                      sectionDiff.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (sectionDiff.totalChanges > 0)
                    _ChangeBadge(count: sectionDiff.totalChanges),
                  AppSpacing.gapHorizontalSm,
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              // Summary row
              if (!expanded && sectionDiff.totalChanges > 0) ...[
                AppSpacing.gapVerticalSm,
                _buildSummaryRow(theme, colorScheme),
              ],

              // Expanded content
              if (expanded) ...[
                AppSpacing.gapVerticalMd,
                const Divider(height: 1),
                AppSpacing.gapVerticalMd,
                if (sectionDiff.answerDiffs.isNotEmpty)
                  _buildAnswerDiffs(theme, colorScheme),
                if (sectionDiff.mediaDiffs.isNotEmpty) ...[
                  if (sectionDiff.answerDiffs.isNotEmpty)
                    AppSpacing.gapVerticalMd,
                  _buildMediaSummary(theme, colorScheme),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(ColorScheme colorScheme) => switch (sectionDiff.changeType) {
      ChangeType.added => colorScheme.primary.withOpacity(0.5),
      ChangeType.modified => colorScheme.tertiary.withOpacity(0.5),
      ChangeType.removed => colorScheme.error.withOpacity(0.5),
      ChangeType.unchanged => colorScheme.outlineVariant,
    };

  Widget _buildSummaryRow(ThemeData theme, ColorScheme colorScheme) {
    final changedFields = sectionDiff.changedAnswers.length;
    final changedMedia = sectionDiff.changedMedia.length;

    final items = <String>[];
    if (changedFields > 0) {
      items.add('$changedFields field${changedFields > 1 ? 's' : ''} changed');
    }
    if (changedMedia > 0) {
      items.add('$changedMedia photo${changedMedia > 1 ? 's' : ''} changed');
    }

    return Text(
      items.join(' • '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildAnswerDiffs(ThemeData theme, ColorScheme colorScheme) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Changes',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVerticalSm,
        ...sectionDiff.answerDiffs.map(
          (diff) => _AnswerDiffRow(diff: diff),
        ),
      ],
    );

  Widget _buildMediaSummary(ThemeData theme, ColorScheme colorScheme) {
    final added = sectionDiff.mediaDiffs
        .where((d) => d.changeType == ChangeType.added)
        .length;
    final modified = sectionDiff.mediaDiffs
        .where((d) => d.changeType == ChangeType.modified)
        .length;
    final removed = sectionDiff.mediaDiffs
        .where((d) => d.changeType == ChangeType.removed)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Changes',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVerticalSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (added > 0)
              _MediaChangeChip(
                label: '+$added added',
                color: colorScheme.primary,
              ),
            if (modified > 0)
              _MediaChangeChip(
                label: '$modified modified',
                color: colorScheme.tertiary,
              ),
            if (removed > 0)
              _MediaChangeChip(
                label: '-$removed removed',
                color: colorScheme.error,
              ),
          ],
        ),
      ],
    );
  }
}

class _ChangeTypeIndicator extends StatelessWidget {
  const _ChangeTypeIndicator({required this.changeType});

  final ChangeType changeType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = switch (changeType) {
      ChangeType.added => (Icons.add_circle_rounded, colorScheme.primary),
      ChangeType.modified => (Icons.edit_rounded, colorScheme.tertiary),
      ChangeType.removed => (Icons.remove_circle_rounded, colorScheme.error),
      ChangeType.unchanged => (
          Icons.check_circle_rounded,
          colorScheme.onSurfaceVariant
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _AnswerDiffRow extends StatelessWidget {
  const _AnswerDiffRow({required this.diff});

  final AnswerDiff diff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChangeTypeIndicator(changeType: diff.changeType),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    diff.fieldLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (diff.changeType != ChangeType.unchanged) ...[
              AppSpacing.gapVerticalSm,
              if (diff.previousValue != null &&
                  diff.changeType != ChangeType.added)
                _ValueDisplay(
                  label: 'Before',
                  value: diff.previousValue!,
                  isOld: true,
                ),
              if (diff.currentValue != null &&
                  diff.changeType != ChangeType.removed)
                _ValueDisplay(
                  label: 'After',
                  value: diff.currentValue!,
                  isOld: false,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  const _ValueDisplay({
    required this.label,
    required this.value,
    required this.isOld,
  });

  final String label;
  final String value;
  final bool isOld;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isOld
                  ? colorScheme.errorContainer.withOpacity(0.5)
                  : colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: AppSpacing.borderRadiusXs,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isOld
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AppSpacing.gapHorizontalSm,
          Expanded(
            child: Text(
              value.isEmpty ? '(empty)' : value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: value.isEmpty
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
                fontStyle: value.isEmpty ? FontStyle.italic : null,
                decoration: isOld ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaChangeChip extends StatelessWidget {
  const _MediaChangeChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
}
