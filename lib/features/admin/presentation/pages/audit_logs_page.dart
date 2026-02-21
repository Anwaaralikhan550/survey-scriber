import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../data/models/audit_log_model.dart';
import '../providers/audit_logs_provider.dart';
import '../widgets/admin_widgets.dart';

class AuditLogsPage extends ConsumerStatefulWidget {
  const AuditLogsPage({super.key});

  @override
  ConsumerState<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<AuditLogsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogsProvider.notifier).loadLogs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditLogsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: state.hasFilters,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(state, theme, colorScheme),
    );
  }

  Widget _buildBody(
    AuditLogsState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.logs.isEmpty) {
      return const AdminLoadingState(message: 'Loading audit logs...');
    }

    if (state.error != null && state.logs.isEmpty) {
      return AdminErrorState(
        message: state.error!,
        onRetry: () => ref.read(auditLogsProvider.notifier).loadLogs(),
      );
    }

    if (state.logs.isEmpty) {
      return AdminEmptyState(
        icon: Icons.history_rounded,
        title: 'No Audit Logs',
        subtitle: state.hasFilters
            ? 'No logs match your filters. Try adjusting your criteria.'
            : 'System activity will appear here.',
        actionLabel: state.hasFilters ? 'Clear Filters' : null,
        onAction: state.hasFilters
            ? () => ref.read(auditLogsProvider.notifier).clearFilters()
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(auditLogsProvider.notifier).loadLogs(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.logs.length + 2, // +1 for header, +1 for loading
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(state, theme, colorScheme);
          }

          if (index == state.logs.length + 1) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            if (!state.hasMore) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(
                    'End of logs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final log = state.logs[index - 1];
          return _AuditLogCard(log: log);
        },
      ),
    );
  }

  Widget _buildHeader(
    AuditLogsState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                AppSpacing.gapHorizontalSm,
                Text(
                  '${state.total} entries',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (state.hasFilters) ...[
            AppSpacing.gapHorizontalSm,
            TextButton.icon(
              onPressed: () =>
                  ref.read(auditLogsProvider.notifier).clearFilters(),
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear filters'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );

  void _showFilterSheet(BuildContext context) {
    final state = ref.read(auditLogsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FilterSheet(
        initialActorType: state.actorTypeFilter,
        initialEntityType: state.entityTypeFilter,
        initialAction: state.actionFilter,
        initialStartDate: state.startDate,
        initialEndDate: state.endDate,
        onApply: (actorType, entityType, action, startDate, endDate) {
          ref.read(auditLogsProvider.notifier).setFilters(
                actorType: actorType,
                entityType: entityType,
                action: action,
                startDate: startDate,
                endDate: endDate,
              );
        },
        onClear: () {
          ref.read(auditLogsProvider.notifier).clearFilters();
        },
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogModel log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActorIcon(colorScheme),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.formattedAction,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapVerticalXs,
                      Text(
                        '${log.actorType.displayName}${log.actorId != null ? ' • ${_truncateId(log.actorId!)}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTimestamp(theme, colorScheme),
              ],
            ),

            AppSpacing.gapVerticalSm,

            // Entity info
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _buildChip(
                  log.entityType.displayName,
                  colorScheme.secondaryContainer,
                  colorScheme.onSecondaryContainer,
                  theme,
                ),
                if (log.entityId != null)
                  _buildChip(
                    _truncateId(log.entityId!),
                    colorScheme.surfaceContainerHighest,
                    colorScheme.onSurfaceVariant,
                    theme,
                  ),
              ],
            ),

            // IP & User Agent info (if available)
            if (log.ip != null || log.userAgent != null) ...[
              AppSpacing.gapVerticalSm,
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log.ip != null)
                      Row(
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          AppSpacing.gapHorizontalXs,
                          Text(
                            log.ip!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    if (log.ip != null && log.userAgent != null)
                      AppSpacing.gapVerticalXs,
                    if (log.userAgent != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.devices_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          AppSpacing.gapHorizontalXs,
                          Expanded(
                            child: Text(
                              _formatUserAgent(log.userAgent!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatUserAgent(String userAgent) {
    // Extract browser/app name from user agent string for readability
    if (userAgent.contains('Chrome')) return 'Chrome Browser';
    if (userAgent.contains('Firefox')) return 'Firefox Browser';
    if (userAgent.contains('Safari') && !userAgent.contains('Chrome')) {
      return 'Safari Browser';
    }
    if (userAgent.contains('Edge')) return 'Edge Browser';
    if (userAgent.contains('Dart')) return 'Mobile App';
    if (userAgent.length > 50) return '${userAgent.substring(0, 47)}...';
    return userAgent;
  }

  Widget _buildActorIcon(ColorScheme colorScheme) {
    final IconData icon;
    final Color color;

    switch (log.actorType) {
      case AuditActorType.staff:
        icon = Icons.admin_panel_settings_outlined;
        color = colorScheme.primary;
      case AuditActorType.client:
        icon = Icons.person_outline_rounded;
        color = colorScheme.tertiary;
      case AuditActorType.system:
        icon = Icons.settings_rounded;
        color = colorScheme.secondary;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildTimestamp(ThemeData theme, ColorScheme colorScheme) {
    final now = DateTime.now();
    final diff = now.difference(log.createdAt);

    String timeText;
    if (diff.inMinutes < 1) {
      timeText = 'Just now';
    } else if (diff.inHours < 1) {
      timeText = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      timeText = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      timeText = '${diff.inDays}d ago';
    } else {
      timeText = DateFormat('MMM d').format(log.createdAt);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          DateFormat('HH:mm').format(log.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String text,
    Color backgroundColor,
    Color textColor,
    ThemeData theme,
  ) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    this.initialActorType,
    this.initialEntityType,
    this.initialAction,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
    required this.onClear,
  });

  final AuditActorType? initialActorType;
  final AuditEntityType? initialEntityType;
  final String? initialAction;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final void Function(AuditActorType?, AuditEntityType?, String?, DateTime?, DateTime?) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  AuditActorType? _actorType;
  AuditEntityType? _entityType;
  final _actionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _actorType = widget.initialActorType;
    _entityType = widget.initialEntityType;
    _actionController.text = widget.initialAction ?? '';
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  bool get hasFilters =>
      _actorType != null ||
      _entityType != null ||
      _actionController.text.isNotEmpty ||
      _startDate != null ||
      _endDate != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate max height: 90% of screen height for responsive layout
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle for Material Design compliance
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header (fixed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Filter Audit Logs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (hasFilters)
                    TextButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable content area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Actor Type
                    _buildSectionLabel('Actor Type', theme, colorScheme),
                    AppSpacing.gapVerticalSm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _filterChip(
                          'All',
                          _actorType == null,
                          () => setState(() => _actorType = null),
                        ),
                        ...AuditActorType.values.map(
                          (type) => _filterChip(
                            type.displayName,
                            _actorType == type,
                            () => setState(() => _actorType = type),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalLg,

                    // Entity Type
                    _buildSectionLabel('Entity Type', theme, colorScheme),
                    AppSpacing.gapVerticalSm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _filterChip(
                          'All',
                          _entityType == null,
                          () => setState(() => _entityType = null),
                        ),
                        ...AuditEntityType.values.map(
                          (type) => _filterChip(
                            type.displayName,
                            _entityType == type,
                            () => setState(() => _entityType = type),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalLg,

                    // Action search
                    _buildSectionLabel('Action (contains)', theme, colorScheme),
                    AppSpacing.gapVerticalSm,
                    TextField(
                      controller: _actionController,
                      decoration: InputDecoration(
                        hintText: 'e.g., login, created, approved',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalLg,

                    // Date Range
                    _buildSectionLabel('Date Range', theme, colorScheme),
                    AppSpacing.gapVerticalSm,
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerButton(
                            label: 'From',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                            onClear: _startDate != null
                                ? () => setState(() => _startDate = null)
                                : null,
                          ),
                        ),
                        AppSpacing.gapHorizontalSm,
                        Expanded(
                          child: _DatePickerButton(
                            label: 'To',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                            onClear: _endDate != null
                                ? () => setState(() => _endDate = null)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Fixed footer with Apply button
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md + bottomPadding,
              ),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(
                      _actorType,
                      _entityType,
                      _actionController.text.isEmpty ? null : _actionController.text,
                      _startDate,
                      _endDate,
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeData theme, ColorScheme colorScheme) => Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surface,
      labelStyle: TextStyle(
        color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final firstDate = DateTime(2020);
    final lastDate = now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          // Set end date to end of day
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDate = date != null;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: hasDate ? colorScheme.primaryContainer.withOpacity(0.3) : colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: hasDate ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: hasDate ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapHorizontalSm,
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('MMM d, y').format(date!)
                    : label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasDate
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: hasDate ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
