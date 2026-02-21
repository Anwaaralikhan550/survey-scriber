import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

/// Sort options for surveys
enum SortOption {
  dateNewest,
  dateOldest,
  titleAz,
  titleZa,
  progressHigh,
  progressLow,
}

/// Filter criteria for advanced filtering
class FilterCriteria {
  const FilterCriteria({
    this.surveyTypes = const {},
    this.statuses = const {},
    this.dateRange,
    this.hasPhotos,
    this.hasNotes,
    this.clientName,
  });

  final Set<String> surveyTypes;
  final Set<String> statuses;
  final DateTimeRange? dateRange;
  final bool? hasPhotos;
  final bool? hasNotes;
  final String? clientName;

  bool get hasActiveFilters =>
      surveyTypes.isNotEmpty ||
      statuses.isNotEmpty ||
      dateRange != null ||
      hasPhotos != null ||
      hasNotes != null ||
      (clientName?.isNotEmpty ?? false);

  int get activeFilterCount {
    var count = 0;
    if (surveyTypes.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (dateRange != null) count++;
    if (hasPhotos != null) count++;
    if (hasNotes != null) count++;
    if (clientName?.isNotEmpty ?? false) count++;
    return count;
  }

  FilterCriteria copyWith({
    Set<String>? surveyTypes,
    Set<String>? statuses,
    DateTimeRange? dateRange,
    bool? hasPhotos,
    bool? hasNotes,
    String? clientName,
    bool clearDateRange = false,
    bool clearHasPhotos = false,
    bool clearHasNotes = false,
    bool clearClientName = false,
  }) =>
      FilterCriteria(
        surveyTypes: surveyTypes ?? this.surveyTypes,
        statuses: statuses ?? this.statuses,
        dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
        hasPhotos: clearHasPhotos ? null : (hasPhotos ?? this.hasPhotos),
        hasNotes: clearHasNotes ? null : (hasNotes ?? this.hasNotes),
        clientName: clearClientName ? null : (clientName ?? this.clientName),
      );

  static const empty = FilterCriteria();
}

/// Bottom sheet for sorting options
class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({
    required this.currentSort,
    required this.onSortChanged,
    super.key,
  });

  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;

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
                  'Sort by',
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
          // Sort options
          ...SortOption.values.map((option) => _SortOptionTile(
                option: option,
                isSelected: currentSort == option,
                onTap: () {
                  onSortChanged(option);
                  Navigator.pop(context);
                },
              ),),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SortOption option;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label => switch (option) {
        SortOption.dateNewest => 'Date (Newest first)',
        SortOption.dateOldest => 'Date (Oldest first)',
        SortOption.titleAz => 'Title (A-Z)',
        SortOption.titleZa => 'Title (Z-A)',
        SortOption.progressHigh => 'Progress (High to Low)',
        SortOption.progressLow => 'Progress (Low to High)',
      };

  IconData get _icon => switch (option) {
        SortOption.dateNewest => Icons.arrow_downward_rounded,
        SortOption.dateOldest => Icons.arrow_upward_rounded,
        SortOption.titleAz => Icons.sort_by_alpha_rounded,
        SortOption.titleZa => Icons.sort_by_alpha_rounded,
        SortOption.progressHigh => Icons.trending_down_rounded,
        SortOption.progressLow => Icons.trending_up_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(
          _icon,
          size: 20,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        _label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

/// Bottom sheet for advanced filters
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    required this.currentFilters,
    required this.onFiltersChanged,
    this.availableTypes = const [],
    this.availableStatuses = const [],
    super.key,
  });

  final FilterCriteria currentFilters;
  final ValueChanged<FilterCriteria> onFiltersChanged;
  final List<String> availableTypes;
  final List<String> availableStatuses;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterCriteria _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  void _toggleType(String type) {
    final types = Set<String>.from(_filters.surveyTypes);
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    setState(() {
      _filters = _filters.copyWith(surveyTypes: types);
    });
  }

  void _toggleStatus(String status) {
    final statuses = Set<String>.from(_filters.statuses);
    if (statuses.contains(status)) {
      statuses.remove(status);
    } else {
      statuses.add(status);
    }
    setState(() {
      _filters = _filters.copyWith(statuses: statuses);
    });
  }

  void _toggleHasPhotos() {
    setState(() {
      if (_filters.hasPhotos == null) {
        _filters = _filters.copyWith(hasPhotos: true);
      } else if (_filters.hasPhotos == true) {
        _filters = _filters.copyWith(hasPhotos: false);
      } else {
        _filters = _filters.copyWith(clearHasPhotos: true);
      }
    });
  }

  void _toggleHasNotes() {
    setState(() {
      if (_filters.hasNotes == null) {
        _filters = _filters.copyWith(hasNotes: true);
      } else if (_filters.hasNotes == true) {
        _filters = _filters.copyWith(hasNotes: false);
      } else {
        _filters = _filters.copyWith(clearHasNotes: true);
      }
    });
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _filters.dateRange,
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
          child: child!,
        ),
    );
    if (range != null) {
      setState(() {
        _filters = _filters.copyWith(dateRange: range);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filters = FilterCriteria.empty;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
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
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_filters.hasActiveFilters) ...[
                  AppSpacing.gapHorizontalSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${_filters.activeFilterCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_filters.hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Survey Type section
                  if (widget.availableTypes.isNotEmpty) ...[
                    _FilterSection(
                      title: 'Survey Type',
                      icon: Icons.category_rounded,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: widget.availableTypes.map((type) {
                          final isSelected = _filters.surveyTypes.contains(type);
                          return FilterChip(
                            label: Text(_formatLabel(type)),
                            selected: isSelected,
                            onSelected: (_) => _toggleType(type),
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.primary,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    AppSpacing.gapVerticalLg,
                  ],
                  // Status section
                  if (widget.availableStatuses.isNotEmpty) ...[
                    _FilterSection(
                      title: 'Status',
                      icon: Icons.flag_rounded,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: widget.availableStatuses.map((status) {
                          final isSelected = _filters.statuses.contains(status);
                          return FilterChip(
                            label: Text(_formatLabel(status)),
                            selected: isSelected,
                            onSelected: (_) => _toggleStatus(status),
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.primary,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    AppSpacing.gapVerticalLg,
                  ],
                  // Date Range section
                  _FilterSection(
                    title: 'Date Range',
                    icon: Icons.calendar_today_rounded,
                    child: InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: _filters.dateRange != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filters.dateRange != null
                                    ? '${_formatDate(_filters.dateRange!.start)} - ${_formatDate(_filters.dateRange!.end)}'
                                    : 'Select date range',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _filters.dateRange != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (_filters.dateRange != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _filters = _filters.copyWith(clearDateRange: true);
                                  });
                                },
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalLg,
                  // Content filters
                  _FilterSection(
                    title: 'Content',
                    icon: Icons.folder_rounded,
                    child: Column(
                      children: [
                        _TriStateFilterTile(
                          label: 'Has photos',
                          icon: Icons.photo_camera_rounded,
                          value: _filters.hasPhotos,
                          onTap: _toggleHasPhotos,
                        ),
                        AppSpacing.gapVerticalSm,
                        _TriStateFilterTile(
                          label: 'Has notes',
                          icon: Icons.notes_rounded,
                          value: _filters.hasNotes,
                          onTap: _toggleHasNotes,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _applyFilters,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                _filters.hasActiveFilters
                    ? 'Apply ${_filters.activeFilterCount} filter${_filters.activeFilterCount > 1 ? 's' : ''}'
                    : 'Apply filters',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String value) {
    // Convert camelCase/snake_case to readable format
    return value
        .replaceAllMapped(
          RegExp('([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '',)
        .join(' ');
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapHorizontalSm,
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalMd,
        child,
      ],
    );
  }
}

class _TriStateFilterTile extends StatelessWidget {
  const _TriStateFilterTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool? value;
  final VoidCallback onTap;

  String get _stateLabel => switch (value) {
        true => 'Yes',
        false => 'No',
        null => 'Any',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = value != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            AppSpacing.gapHorizontalMd,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                _stateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the sort bottom sheet
Future<SortOption?> showSortBottomSheet(
  BuildContext context, {
  required SortOption currentSort,
}) async {
  SortOption? selectedSort;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SortBottomSheet(
      currentSort: currentSort,
      onSortChanged: (sort) {
        selectedSort = sort;
      },
    ),
  );
  return selectedSort;
}

/// Helper function to show the filter bottom sheet
Future<FilterCriteria?> showFilterBottomSheet(
  BuildContext context, {
  required FilterCriteria currentFilters,
  List<String> availableTypes = const [],
  List<String> availableStatuses = const [],
}) async {
  FilterCriteria? result;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(
      currentFilters: currentFilters,
      availableTypes: availableTypes,
      availableStatuses: availableStatuses,
      onFiltersChanged: (filters) {
        result = filters;
      },
    ),
  );
  return result;
}
