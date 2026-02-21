import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

/// Bulk action types available for surveys
enum BulkAction {
  delete,
  archive,
  export,
  changeStatus,
  duplicate,
}

/// Contextual bottom action bar for bulk operations
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    required this.selectedCount,
    required this.onAction,
    required this.onClearSelection,
    this.availableActions = const [
      BulkAction.delete,
      BulkAction.archive,
      BulkAction.export,
      BulkAction.changeStatus,
    ],
    super.key,
  });

  final int selectedCount;
  final ValueChanged<BulkAction> onAction;
  final VoidCallback onClearSelection;
  final List<BulkAction> availableActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSlide(
      offset: selectedCount > 0 ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: selectedCount > 0 ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selection info row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '$selectedCount selected',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onClearSelection,
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVerticalMd,
                // Action buttons row
                Row(
                  children: availableActions.map((action) {
                    final isDestructive = action == BulkAction.delete;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: action != availableActions.last
                              ? AppSpacing.sm
                              : 0,
                        ),
                        child: _BulkActionButton(
                          action: action,
                          isDestructive: isDestructive,
                          onTap: () => onAction(action),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.action,
    required this.onTap,
    this.isDestructive = false,
  });

  final BulkAction action;
  final VoidCallback onTap;
  final bool isDestructive;

  String get _label => switch (action) {
        BulkAction.delete => 'Delete',
        BulkAction.archive => 'Archive',
        BulkAction.export => 'Export',
        BulkAction.changeStatus => 'Status',
        BulkAction.duplicate => 'Duplicate',
      };

  IconData get _icon => switch (action) {
        BulkAction.delete => Icons.delete_outline_rounded,
        BulkAction.archive => Icons.archive_outlined,
        BulkAction.export => Icons.file_download_outlined,
        BulkAction.changeStatus => Icons.flag_outlined,
        BulkAction.duplicate => Icons.copy_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final bgColor = isDestructive
        ? theme.colorScheme.errorContainer.withOpacity(0.3)
        : theme.colorScheme.surfaceContainerHighest;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                _label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A survey card wrapper that adds selection capability
class SelectableSurveyCard extends StatelessWidget {
  const SelectableSurveyCard({
    required this.child,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onToggleSelection,
    required this.onLongPress,
    super.key,
  });

  final Widget child;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onToggleSelection;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // The wrapped card with modified tap behavior
            AbsorbPointer(
              absorbing: isSelectionMode,
              child: child,
            ),
            // Selection overlay when in selection mode
            if (isSelectionMode)
              Positioned.fill(
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: InkWell(
                    onTap: onToggleSelection,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            // Selection checkbox
            if (isSelectionMode)
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedScale(
                  scale: isSelectionMode ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for changing status of selected surveys
class StatusChangeBottomSheet extends StatelessWidget {
  const StatusChangeBottomSheet({
    required this.onStatusSelected,
    super.key,
  });

  final ValueChanged<String> onStatusSelected;

  static const _statuses = [
    ('draft', 'Draft', Icons.edit_outlined),
    ('inProgress', 'In Progress', Icons.play_arrow_rounded),
    ('paused', 'Paused', Icons.pause_rounded),
    ('completed', 'Completed', Icons.check_circle_outline_rounded),
    ('pendingReview', 'Pending Review', Icons.hourglass_empty_rounded),
  ];

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
          // Header
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
                  'Change Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Status options
          ..._statuses.map((status) => ListTile(
                onTap: () {
                  onStatusSelected(status.$1);
                  Navigator.pop(context);
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    status.$3,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  status.$2,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
              ),),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

/// Helper function to show status change bottom sheet
Future<String?> showStatusChangeBottomSheet(BuildContext context) async {
  String? selectedStatus;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatusChangeBottomSheet(
      onStatusSelected: (status) {
        selectedStatus = status;
      },
    ),
  );
  return selectedStatus;
}

/// Helper function to show delete confirmation dialog
Future<bool> showDeleteConfirmationDialog(
  BuildContext context, {
  required int itemCount,
}) async {
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Delete Surveys',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      content: Text(
        'Are you sure you want to delete $itemCount survey${itemCount > 1 ? 's' : ''}? This action cannot be undone.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
