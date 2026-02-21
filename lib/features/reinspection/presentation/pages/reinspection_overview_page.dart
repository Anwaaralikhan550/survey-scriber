import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/comparison_result.dart';
import '../providers/comparison_provider.dart';
import '../widgets/comparison_toggle.dart';
import '../widgets/section_comparison_card.dart';

/// Page for viewing re-inspection comparison results
class ReinspectionOverviewPage extends ConsumerStatefulWidget {
  const ReinspectionOverviewPage({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  @override
  ConsumerState<ReinspectionOverviewPage> createState() =>
      _ReinspectionOverviewPageState();
}

class _ReinspectionOverviewPageState
    extends ConsumerState<ReinspectionOverviewPage> {
  final Set<String> _expandedSections = {};
  final _dateFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(comparisonProvider(widget.surveyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparison'),
        actions: [
          if (state.hasComparison)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.read(comparisonProvider(widget.surveyId).notifier).refresh();
              },
            ),
        ],
      ),
      body: _buildBody(theme, colorScheme, state),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    ComparisonState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return _buildErrorState(theme, colorScheme, state.errorMessage!);
    }

    if (!state.isReinspection) {
      return _buildNoComparisonState(theme, colorScheme);
    }

    if (!state.hasComparison) {
      return _buildLoadingComparison(theme, colorScheme);
    }

    return _buildComparisonView(theme, colorScheme, state);
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme colorScheme,
    String message,
  ) => Center(
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
            AppSpacing.gapVerticalLg,
            Text(
              'Unable to load comparison',
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLg,
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(comparisonProvider(widget.surveyId).notifier)
                    .refresh();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );

  Widget _buildNoComparisonState(ThemeData theme, ColorScheme colorScheme) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapVerticalLg,
            Text(
              'No Previous Inspection',
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'This is an original inspection.\nCreate a re-inspection to compare changes.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  Widget _buildLoadingComparison(ThemeData theme, ColorScheme colorScheme) => const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          AppSpacing.gapVerticalMd,
          Text('Loading comparison data...'),
        ],
      ),
    );

  Widget _buildComparisonView(
    ThemeData theme,
    ColorScheme colorScheme,
    ComparisonState state,
  ) {
    final result = state.result!;

    return Column(
      children: [
        // Toggle bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              ComparisonToggle(
                currentMode: state.viewMode,
                onModeChanged: (mode) {
                  ref
                      .read(comparisonProvider(widget.surveyId).notifier)
                      .setViewMode(mode);
                },
              ),
              AppSpacing.gapVerticalSm,
              _buildDateRange(theme, colorScheme, result),
            ],
          ),
        ),

        // Content based on view mode
        Expanded(
          child: switch (state.viewMode) {
            ComparisonViewMode.compare => _buildCompareView(result),
            ComparisonViewMode.current => _buildSingleSurveyView(
                result.sectionDiffs,
                showCurrent: true,
              ),
            ComparisonViewMode.previous => _buildSingleSurveyView(
                result.sectionDiffs,
                showCurrent: false,
              ),
          },
        ),
      ],
    );
  }

  Widget _buildDateRange(
    ThemeData theme,
    ColorScheme colorScheme,
    ComparisonResult result,
  ) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DateChip(
          label: 'Previous',
          date: _dateFormat.format(result.previousSurvey.createdAt),
          color: colorScheme.error,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        _DateChip(
          label: 'Current',
          date: _dateFormat.format(result.currentSurvey.createdAt),
          color: colorScheme.primary,
        ),
      ],
    );

  Widget _buildCompareView(ComparisonResult result) => CustomScrollView(
      slivers: [
        // Summary card
        SliverToBoxAdapter(
          child: _buildSummaryCard(result),
        ),

        // Section comparisons
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final sectionDiff = result.sectionDiffs[index];
                final isExpanded = _expandedSections.contains(sectionDiff.sectionId);

                return SectionComparisonCard(
                  sectionDiff: sectionDiff,
                  expanded: isExpanded,
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedSections.remove(sectionDiff.sectionId);
                      } else {
                        _expandedSections.add(sectionDiff.sectionId);
                      }
                    });
                  },
                );
              },
              childCount: result.sectionDiffs.length,
            ),
          ),
        ),

        // Signature changes
        if (result.signatureDiffs.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildSignatureSection(result.signatureDiffs),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xl),
        ),
      ],
    );

  Widget _buildSummaryCard(ComparisonResult result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = result.summary;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  'Comparison Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Expanded(
                  child: _SummaryStatTile(
                    label: 'Sections',
                    value: '${summary.sectionsWithChanges}/${summary.totalSections}',
                    subtitle: 'changed',
                    color: colorScheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _SummaryStatTile(
                    label: 'Fields',
                    value: '${summary.totalAnswerChanges}',
                    subtitle: 'modified',
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _SummaryStatTile(
                    label: 'Photos',
                    value: '${summary.totalMediaChanges}',
                    subtitle: 'changed',
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSurveyView(
    List<SectionDiff> sectionDiffs, {
    required bool showCurrent,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sectionDiffs.length,
      itemBuilder: (context, index) {
        final sectionDiff = sectionDiffs[index];
        final section = showCurrent
            ? sectionDiff.currentSection
            : sectionDiff.previousSection;

        if (section == null) {
          return const SizedBox.shrink();
        }

        final answers = showCurrent
            ? sectionDiff.answerDiffs
                .where((d) => d.currentValue != null)
                .toList()
            : sectionDiff.answerDiffs
                .where((d) => d.previousValue != null)
                .toList();

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapVerticalMd,
                ...answers.map((diff) {
                  final value = showCurrent ? diff.currentValue : diff.previousValue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            diff.fieldLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value ?? '-',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignatureSection(List<SignatureDiff> signatureDiffs) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.draw_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  'Signature Changes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            ...signatureDiffs.map((diff) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    _ChangeIcon(changeType: diff.changeType),
                    AppSpacing.gapHorizontalSm,
                    Expanded(
                      child: Text(
                        diff.displaySignature?.signerRole ??
                            diff.displaySignature?.signerName ??
                            'Unknown',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      diff.changeType.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.date,
    required this.color,
  });

  final String label;
  final String date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            date,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChangeIcon extends StatelessWidget {
  const _ChangeIcon({required this.changeType});

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

    return Icon(icon, size: 18, color: color);
  }
}
