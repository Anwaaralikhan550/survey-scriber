import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../../shared/presentation/widgets/bulk_action_bar.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/filter_presets.dart';
import '../../../../shared/presentation/widgets/filter_sort_bottom_sheet.dart';
import '../../../../shared/presentation/widgets/survey_card.dart';
import '../providers/forms_provider.dart';

class FormsPage extends ConsumerWidget {
  const FormsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(formsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.read(formsProvider.notifier).refresh(),
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildHeader(context, ref, theme, state),
                  _buildFilterChips(context, ref, state),
                  if (state.isLoading)
                    _buildLoadingState(theme)
                  else if (state.hasError)
                    _buildErrorState(context, ref, state.errorMessage!)
                  else if (state.filteredSurveys.isEmpty)
                    _buildEmptyState(state.filter)
                  else
                    _buildSurveyList(context, ref, state),
                  // Extra padding when bulk action bar is visible
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: state.isSelectionMode ? 180 : 100,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bulk action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BulkActionBar(
              selectedCount: state.selectedCount,
              onClearSelection: () =>
                  ref.read(formsProvider.notifier).clearSelection(),
              onAction: (action) =>
                  _handleBulkAction(context, ref, action),
              availableActions: const [
                BulkAction.changeStatus,
                BulkAction.export,
                BulkAction.delete,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBulkAction(
    BuildContext context,
    WidgetRef ref,
    BulkAction action,
  ) async {
    final notifier = ref.read(formsProvider.notifier);
    final state = ref.read(formsProvider);

    switch (action) {
      case BulkAction.delete:
        final confirmed = await showDeleteConfirmationDialog(
          context,
          itemCount: state.selectedCount,
        );
        if (confirmed) {
          final requested = state.selectedCount;
          final deleted = await notifier.deleteSelected();
          if (context.mounted) {
            final message = deleted == requested
                ? '$deleted survey(s) deleted'
                : deleted > 0
                    ? '$deleted of $requested survey(s) deleted'
                    : 'Failed to delete surveys';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      case BulkAction.changeStatus:
        final newStatus = await showStatusChangeBottomSheet(context);
        if (newStatus != null) {
          final status = SurveyStatus.values.firstWhere(
            (s) => s.name == newStatus,
            orElse: () => SurveyStatus.draft,
          );
          await notifier.changeStatusForSelected(status);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated for ${state.selectedCount} survey(s)'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      case BulkAction.export:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Export feature coming soon'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      case BulkAction.archive:
      case BulkAction.duplicate:
        // Not implemented yet
        break;
    }
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    FormsState state,
  ) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Forms',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your in-progress surveys',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort & Filter buttons only - compact on header
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionIconButton(
                        icon: Icons.sort_rounded,
                        onTap: () => _showSortSheet(context, ref, state),
                      ),
                      const SizedBox(width: 8),
                      _ActionIconButton(
                        icon: Icons.filter_list_rounded,
                        badge: state.hasActiveAdvancedFilters
                            ? state.advancedFilters.activeFilterCount
                            : null,
                        onTap: () => _showFilterSheet(context, ref, state),
                      ),
                    ],
                  ),
                ],
              ),
              // Presets chip row - separate row for better layout
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PresetChip(
                      onPresetSelected: (preset) {
                        ref.read(formsProvider.notifier).setAdvancedFilters(preset.filters);
                        ref.read(formsProvider.notifier).setSortOption(preset.sortOption);
                      },
                    ),
                    if (state.sortOption != SortOption.dateNewest) ...[
                      const SizedBox(width: 8),
                      _SortChip(
                        label: _getSortLabel(state.sortOption),
                        onClear: () => ref.read(formsProvider.notifier).setSortOption(SortOption.dateNewest),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  String _getSortLabel(SortOption sort) => switch (sort) {
        SortOption.dateNewest => 'Newest',
        SortOption.dateOldest => 'Oldest',
        SortOption.titleAz => 'A-Z',
        SortOption.titleZa => 'Z-A',
        SortOption.progressHigh => 'Progress ↓',
        SortOption.progressLow => 'Progress ↑',
      };

  Future<void> _showSortSheet(
    BuildContext context,
    WidgetRef ref,
    FormsState state,
  ) async {
    final newSort = await showSortBottomSheet(
      context,
      currentSort: state.sortOption,
    );
    if (newSort != null) {
      ref.read(formsProvider.notifier).setSortOption(newSort);
    }
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    FormsState state,
  ) async {
    final newFilters = await showFilterBottomSheet(
      context,
      currentFilters: state.advancedFilters,
      availableTypes: state.availableSurveyTypes,
      availableStatuses: state.availableStatuses,
    );
    if (newFilters != null) {
      ref.read(formsProvider.notifier).setAdvancedFilters(newFilters);
    }
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    FormsState state,
  ) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: FormsFilter.values.map((filter) {
            final isSelected = state.filter == filter;
            final label = switch (filter) {
              FormsFilter.all => 'All',
              FormsFilter.draft => 'Drafts',
              FormsFilter.inProgress => 'In Progress',
              FormsFilter.paused => 'Paused',
            };

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(formsProvider.notifier).setFilter(filter);
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : theme.colorScheme.outlineVariant.withOpacity(0.6),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) => SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnimatedShimmerCard(
                theme: theme,
                delay: index * 150,
              ),
            ),
            childCount: 4,
          ),
        ),
      );

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    final theme = Theme.of(context);

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(formsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(FormsFilter filter) {
    final (icon, title, description) = switch (filter) {
      FormsFilter.all => (
          Icons.assignment_rounded,
          'No forms yet',
          'Start a new survey to see it here',
        ),
      FormsFilter.draft => (
          Icons.drafts_rounded,
          'No drafts',
          'Draft surveys will appear here',
        ),
      FormsFilter.inProgress => (
          Icons.pending_actions_rounded,
          'No surveys in progress',
          'Surveys you\'re working on will appear here',
        ),
      FormsFilter.paused => (
          Icons.pause_circle_rounded,
          'No paused surveys',
          'Paused surveys will appear here',
        ),
    };

    return SliverFillRemaining(
      child: EmptyState(
        icon: icon,
        title: title,
        description: description,
        actionLabel: 'New Survey',
      ),
    );
  }

  Widget _buildSurveyList(
    BuildContext context,
    WidgetRef ref,
    FormsState state,
  ) =>
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final survey = state.filteredSurveys[index];
              final isSelected = state.selectedSurveyIds.contains(survey.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectableSurveyCard(
                  isSelected: isSelected,
                  isSelectionMode: state.isSelectionMode,
                  onToggleSelection: () =>
                      ref.read(formsProvider.notifier).toggleSelection(survey.id),
                  onLongPress: () =>
                      ref.read(formsProvider.notifier).toggleSelection(survey.id),
                  child: SurveyCard(
                    survey: survey,
                    onTap: () {
                      if (state.isSelectionMode) {
                        ref.read(formsProvider.notifier).toggleSelection(survey.id);
                      } else {
                        // Use surveyDetailPath to show the new layout with AI Assistant
                        context.push(Routes.surveyDetailPath(survey.id));
                      }
                    },
                  ),
                ),
              );
            },
            childCount: state.filteredSurveys.length,
          ),
        ),
      );
}

// Animated shimmer card for loading state
class _AnimatedShimmerCard extends StatefulWidget {
  const _AnimatedShimmerCard({
    required this.theme,
    this.delay = 0,
  });

  final ThemeData theme;
  final int delay;

  @override
  State<_AnimatedShimmerCard> createState() => _AnimatedShimmerCardState();
}

class _AnimatedShimmerCardState extends State<_AnimatedShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(42, 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(double.infinity, 16),
                        const SizedBox(height: 8),
                        _shimmerBox(120, 12),
                      ],
                    ),
                  ),
                  _shimmerBox(70, 24),
                ],
              ),
              const SizedBox(height: 14),
              _shimmerBox(200, 12),
              const SizedBox(height: 14),
              Row(
                children: [
                  _shimmerBox(40, 12),
                  const SizedBox(width: 14),
                  _shimmerBox(40, 12),
                  const Spacer(),
                  _shimmerBox(60, 12),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _shimmerBox(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.surfaceContainerHighest
              .withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

/// Compact action icon button with optional badge
class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              if (badge != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$badge',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sort indicator chip with clear button
class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4),
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sort_rounded,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
