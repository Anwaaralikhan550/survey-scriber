import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_state.dart';

export '../../../core/sync/sync_manager.dart' show syncStateProvider;
/// Re-export for backward compatibility
export '../../../core/sync/sync_state.dart';

/// Subtle sync status indicator for bottom nav or app bar
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({
    this.compact = false,
    super.key,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    // Hide if idle and synced (no pending changes)
    if (state.status == SyncStatus.idle && !state.hasPendingChanges && !compact) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showSyncDetails(context, ref, state),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(state, theme),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(state, theme),
            if (!compact && _shouldShowLabel(state)) ...[
              const SizedBox(width: 6),
              Text(
                _getStatusText(state),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getTextColor(state, theme),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowLabel(SyncState state) => state.status != SyncStatus.idle ||
        state.status == SyncStatus.success ||
        state.hasPendingChanges;

  Widget _buildIcon(SyncState state, ThemeData theme) {
    final color = _getIconColor(state, theme);
    final size = compact ? 14.0 : 16.0;

    switch (state.status) {
      case SyncStatus.idle:
        if (state.hasPendingChanges) {
          return _buildPendingBadge(state.pendingCount, color, size);
        }
        return Icon(Icons.cloud_done_rounded, size: size, color: color);
      case SyncStatus.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        );
      case SyncStatus.pending:
        return _buildPendingBadge(state.pendingCount, color, size);
      case SyncStatus.success:
        return Icon(Icons.cloud_done_rounded, size: size, color: color);
      case SyncStatus.offline:
        return Icon(Icons.cloud_off_rounded, size: size, color: color);
      case SyncStatus.error:
        return Icon(Icons.sync_problem_rounded, size: size, color: color);
    }
  }

  Widget _buildPendingBadge(int count, Color color, double size) => Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.cloud_upload_rounded, size: size, color: color),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );

  Color _getBackgroundColor(SyncState state, ThemeData theme) {
    if (state.isOffline) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    return switch (state.status) {
      SyncStatus.idle => state.hasPendingChanges
          ? AppColors.warning.withOpacity(0.12)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      SyncStatus.syncing => AppColors.info.withOpacity(0.12),
      SyncStatus.pending => AppColors.warning.withOpacity(0.12),
      SyncStatus.success => AppColors.success.withOpacity(0.12),
      SyncStatus.offline => theme.colorScheme.surfaceContainerHighest,
      SyncStatus.error => AppColors.error.withOpacity(0.12),
    };
  }

  Color _getIconColor(SyncState state, ThemeData theme) {
    if (state.isOffline) {
      return theme.colorScheme.onSurfaceVariant;
    }
    return switch (state.status) {
      SyncStatus.idle => state.hasPendingChanges
          ? AppColors.warning
          : theme.colorScheme.onSurfaceVariant,
      SyncStatus.syncing => AppColors.info,
      SyncStatus.pending => AppColors.warning,
      SyncStatus.success => AppColors.success,
      SyncStatus.offline => theme.colorScheme.onSurfaceVariant,
      SyncStatus.error => AppColors.error,
    };
  }

  Color _getTextColor(SyncState state, ThemeData theme) => _getIconColor(state, theme);

  String _getStatusText(SyncState state) {
    if (state.isOffline) return 'Offline';
    return switch (state.status) {
      SyncStatus.idle => state.hasPendingChanges
          ? '${state.pendingCount} pending'
          : 'Synced',
      SyncStatus.syncing => 'Syncing...',
      SyncStatus.pending => '${state.pendingCount} pending',
      SyncStatus.success => 'Synced',
      SyncStatus.offline => 'Offline',
      SyncStatus.error => 'Sync error',
    };
  }

  void _showSyncDetails(BuildContext context, WidgetRef ref, SyncState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SyncDetailsSheet(state: state),
    );
  }
}

/// Detailed sync status bottom sheet
class SyncDetailsSheet extends ConsumerStatefulWidget {
  const SyncDetailsSheet({required this.state, super.key});

  final SyncState state;

  @override
  ConsumerState<SyncDetailsSheet> createState() => _SyncDetailsSheetState();
}

class _SyncDetailsSheetState extends ConsumerState<SyncDetailsSheet> {
  bool _showFailedDetails = false;
  List<SyncQueueItem>? _failedItems;

  SyncState get state => widget.state;

  Future<void> _loadFailedItems() async {
    final items = await ref.read(syncStateProvider.notifier).getFailedItems();
    if (mounted) {
      setState(() => _failedItems = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Status icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _getStatusContainerColor(theme),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        size: 32,
                        color: _getStatusIconColor(theme),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,
                    // Status title
                    Text(
                      _getStatusTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    AppSpacing.gapVerticalSm,
                    // Status description
                    Text(
                      _getStatusDescription(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapVerticalLg,
                    // Stats row
                    if (state.lastSyncedAt != null)
                      _buildInfoRow(
                        theme,
                        Icons.schedule_rounded,
                        'Last synced',
                        _formatLastSync(state.lastSyncedAt!),
                      ),
                    if (state.pendingCount > 0)
                      _buildInfoRow(
                        theme,
                        Icons.pending_rounded,
                        'Pending changes',
                        '${state.pendingCount} item${state.pendingCount > 1 ? 's' : ''}',
                      ),
                    if (state.failedCount > 0)
                      _buildFailedItemsSection(theme),
                    if (state.conflictCount > 0)
                      _buildInfoRow(
                        theme,
                        Icons.warning_amber_rounded,
                        'Needs review',
                        '${state.conflictCount}',
                        valueColor: AppColors.warning,
                      ),
                    AppSpacing.gapVerticalLg,
                    // Action buttons
                    _buildActionButtons(context, ref, theme),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }

  /// Build expandable section showing failed items with per-item errors.
  Widget _buildFailedItemsSection(ThemeData theme) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Failed count row — tappable to expand
        InkWell(
          onTap: () {
            setState(() => _showFailedDetails = !_showFailedDetails);
            if (_showFailedDetails && _failedItems == null) {
              _loadFailedItems();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                AppSpacing.gapHorizontalSm,
                Text(
                  'Failed items',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.failedCount}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showFailedDetails ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        // Expanded details
        if (_showFailedDetails) ...[
          if (_failedItems == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )),
            )
          else if (_failedItems!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No failed items found',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _failedItems!.length && i < 10; i++)
                    _buildFailedItemTile(theme, _failedItems![i]),
                  if (_failedItems!.length > 10)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '+ ${_failedItems!.length - 10} more items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );

  Widget _buildFailedItemTile(ThemeData theme, SyncQueueItem item) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _entityTypeIcon(item.entityType),
            size: 14,
            color: AppColors.error.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.entityType.name} (${item.action.name})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (item.errorMessage != null)
                  Text(
                    item.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

  static IconData _entityTypeIcon(SyncEntityType type) => switch (type) {
    SyncEntityType.survey => Icons.assignment_rounded,
    SyncEntityType.section => Icons.view_list_rounded,
    SyncEntityType.answer => Icons.edit_note_rounded,
    SyncEntityType.photo => Icons.photo_camera_rounded,
  };

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    if (state.status == SyncStatus.syncing) {
      return const SizedBox.shrink();
    }

    if (state.status == SyncStatus.pending ||
        state.status == SyncStatus.error ||
        state.hasPendingChanges) {
      return Column(
        children: [
          FilledButton.icon(
            onPressed: state.isOffline
                ? null
                : () {
                    ref.read(syncStateProvider.notifier).syncNow();
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.sync_rounded, size: 20),
            label: const Text(
              'Sync Now',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
          if (state.failedCount > 0) ...[
            AppSpacing.gapVerticalSm,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(syncStateProvider.notifier).retryFailed();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Retry Failed',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Failed Items?'),
                          content: Text(
                            'This removes ${state.failedCount} failed item${state.failedCount > 1 ? 's' : ''} from the sync queue. '
                            'They will be re-queued when you next edit the related surveys.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        ref.read(syncStateProvider.notifier).clearFailed();
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    label: const Text(
                      'Clear Failed',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    if (state.isOffline) {
      return OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.wifi_rounded, size: 20),
        label: const Text(
          'Waiting for Connection',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            AppSpacing.gapHorizontalSm,
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      );

  Color _getStatusContainerColor(ThemeData theme) {
    if (state.isOffline) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    return switch (state.status) {
      SyncStatus.idle => state.hasPendingChanges
          ? AppColors.warning.withOpacity(0.12)
          : AppColors.success.withOpacity(0.12),
      SyncStatus.syncing => AppColors.info.withOpacity(0.12),
      SyncStatus.pending => AppColors.warning.withOpacity(0.12),
      SyncStatus.success => AppColors.success.withOpacity(0.12),
      SyncStatus.offline => theme.colorScheme.surfaceContainerHighest,
      SyncStatus.error => AppColors.error.withOpacity(0.12),
    };
  }

  Color _getStatusIconColor(ThemeData theme) {
    if (state.isOffline) {
      return theme.colorScheme.onSurfaceVariant;
    }
    return switch (state.status) {
      SyncStatus.idle =>
        state.hasPendingChanges ? AppColors.warning : AppColors.success,
      SyncStatus.syncing => AppColors.info,
      SyncStatus.pending => AppColors.warning,
      SyncStatus.success => AppColors.success,
      SyncStatus.offline => theme.colorScheme.onSurfaceVariant,
      SyncStatus.error => AppColors.error,
    };
  }

  IconData _getStatusIcon() {
    if (state.isOffline) return Icons.cloud_off_rounded;
    return switch (state.status) {
      SyncStatus.idle => state.hasPendingChanges
          ? Icons.cloud_upload_rounded
          : Icons.cloud_done_rounded,
      SyncStatus.syncing => Icons.sync_rounded,
      SyncStatus.pending => Icons.cloud_upload_rounded,
      SyncStatus.success => Icons.cloud_done_rounded,
      SyncStatus.offline => Icons.cloud_off_rounded,
      SyncStatus.error => Icons.sync_problem_rounded,
    };
  }

  String _getStatusTitle() {
    if (state.isOffline) return 'Offline Mode';
    return switch (state.status) {
      SyncStatus.idle =>
        state.hasPendingChanges ? 'Changes Pending' : 'All Synced',
      SyncStatus.syncing => 'Syncing...',
      SyncStatus.pending => 'Changes Pending',
      SyncStatus.success => 'All Synced',
      SyncStatus.offline => 'Offline Mode',
      SyncStatus.error => 'Sync Failed',
    };
  }

  String _getStatusDescription() {
    if (state.isOffline) {
      return 'You\'re currently offline. Your changes are saved locally and will sync automatically when you\'re back online.';
    }
    return switch (state.status) {
      SyncStatus.idle => state.hasPendingChanges
          ? 'You have ${state.pendingCount} change${state.pendingCount > 1 ? 's' : ''} waiting to sync.'
          : 'All your data is up to date and synced with the cloud.',
      SyncStatus.syncing =>
        'Your changes are being synced to the cloud${state.currentItem != null ? ': ${state.currentItem}' : '...'}',
      SyncStatus.pending =>
        'You have ${state.pendingCount} change${state.pendingCount > 1 ? 's' : ''} waiting to sync.',
      SyncStatus.success =>
        'All your data is up to date and synced with the cloud.',
      SyncStatus.offline =>
        'You\'re currently offline. Your changes will sync automatically when you\'re back online.',
      SyncStatus.error => state.errorMessage ??
          'Something went wrong during sync. Please try again.',
    };
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
}

/// Offline mode banner - subtle top banner when offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    return AnimatedSlide(
      offset: state.isOffline ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: state.isOffline ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    'You\'re offline. Changes saved locally.',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (state.hasPendingChanges)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${state.pendingCount} pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small sync badge for survey cards
class SurveyCardSyncBadge extends ConsumerWidget {
  const SurveyCardSyncBadge({
    required this.surveyId,
    super.key,
  });

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Use FutureBuilder to check sync status
    return FutureBuilder<bool>(
      future: ref.read(syncStateProvider.notifier).hasPendingSync(surveyId),
      builder: (context, snapshot) {
        final isPending = snapshot.data ?? false;
        if (!isPending) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload_rounded, size: 12, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                'Pending',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Legacy provider for backward compatibility with old code
/// This redirects to the new syncStateProvider
@Deprecated('Use syncStateProvider instead')
final syncProvider = syncStateProvider;
