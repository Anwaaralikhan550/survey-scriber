import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/domain/entities/timeline_event.dart';
import '../providers/survey_timeline_provider.dart';

/// A card displaying the activity timeline for a survey.
///
/// Shows a vertical timeline of events with icons, titles, and timestamps.
class ActivityTimelineCard extends ConsumerWidget {
  const ActivityTimelineCard({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyTimelineProvider(surveyId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                'Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              AppSpacing.gapHorizontalSm,
              if (state.hasEvents)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                  child: Text(
                    '${state.eventCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (state.isLoading)
          _buildLoadingState(theme)
        else if (state.hasError)
          _buildErrorState(context, ref, state.errorMessage!)
        else if (state.isEmpty)
          _buildEmptyState(theme)
        else
          _buildTimeline(context, state.events),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) => Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: theme.colorScheme.error,
            ),
            AppSpacing.gapHorizontalSm,
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(surveyTimelineProvider(surveyId).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) => Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapHorizontalSm,
            Text(
              'No activity recorded yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildTimeline(BuildContext context, List<TimelineEvent> events) {
    // Limit to most recent 5 events to keep UI clean
    final displayEvents = events.take(5).toList();
    final hasMore = events.length > 5;

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          children: [
            ...displayEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isFirst = index == 0;
              final isLast = index == displayEvents.length - 1 && !hasMore;

              return _TimelineEventItem(
                event: event,
                isFirst: isFirst,
                isLast: isLast,
              );
            }),
            if (hasMore)
              _buildMoreIndicator(context, events.length - 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(BuildContext context, int remaining) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            '$remaining more events',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual timeline event item
class _TimelineEventItem extends StatelessWidget {
  const _TimelineEventItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _getEventIconAndColor(event.type);

    return Semantics(
      label: _getSemanticLabel(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline connector and icon
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Icon
                  ExcludeSemantics(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapHorizontalSm,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(event.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (event.hasDescription) ...[
                    AppSpacing.gapVerticalXs,
                    Text(
                      event.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSemanticLabel() {
    final dateStr = _formatTimestamp(event.timestamp);
    final description = event.hasDescription ? '. ${event.description}' : '';
    return '${event.title}$description. $dateStr';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  (IconData, Color) _getEventIconAndColor(TimelineEventType type) => switch (type) {
      TimelineEventType.created => (
          Icons.add_circle_outline_rounded,
          AppColors.statusDraft,
        ),
      TimelineEventType.sectionCompleted => (
          Icons.check_circle_outline_rounded,
          AppColors.statusCompleted,
        ),
      TimelineEventType.paused => (
          Icons.pause_circle_outline_rounded,
          AppColors.statusPendingReview,
        ),
      TimelineEventType.resumed => (
          Icons.play_circle_outline_rounded,
          AppColors.statusInProgress,
        ),
      TimelineEventType.completed => (
          Icons.task_alt_rounded,
          AppColors.statusCompleted,
        ),
      TimelineEventType.submittedForReview => (
          Icons.send_rounded,
          AppColors.statusPendingReview,
        ),
      TimelineEventType.approved => (
          Icons.verified_rounded,
          AppColors.statusApproved,
        ),
      TimelineEventType.rejected => (
          Icons.cancel_outlined,
          AppColors.statusRejected,
        ),
    };
}
