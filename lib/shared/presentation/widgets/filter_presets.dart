import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'filter_sort_bottom_sheet.dart';

/// A saved filter preset
class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.name,
    required this.filters,
    required this.sortOption,
    this.icon,
    this.color,
    this.isDefault = false,
  });

  /// Create from JSON map
  factory FilterPreset.fromJson(Map<String, dynamic> json) => FilterPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      filters: FilterCriteria(
        surveyTypes: Set<String>.from(json['surveyTypes'] as List? ?? []),
        statuses: Set<String>.from(json['statuses'] as List? ?? []),
        hasPhotos: json['hasPhotos'] as bool?,
        hasNotes: json['hasNotes'] as bool?,
      ),
      sortOption: SortOption.values.firstWhere(
        (s) => s.name == json['sortOption'],
        orElse: () => SortOption.dateNewest,
      ),
      isDefault: json['isDefault'] as bool? ?? false,
    );

  final String id;
  final String name;
  final FilterCriteria filters;
  final SortOption sortOption;
  final IconData? icon;
  final Color? color;
  final bool isDefault;

  FilterPreset copyWith({
    String? id,
    String? name,
    FilterCriteria? filters,
    SortOption? sortOption,
    IconData? icon,
    Color? color,
    bool? isDefault,
  }) =>
      FilterPreset(
        id: id ?? this.id,
        name: name ?? this.name,
        filters: filters ?? this.filters,
        sortOption: sortOption ?? this.sortOption,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        isDefault: isDefault ?? this.isDefault,
      );

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surveyTypes': filters.surveyTypes.toList(),
        'statuses': filters.statuses.toList(),
        'hasPhotos': filters.hasPhotos,
        'hasNotes': filters.hasNotes,
        'sortOption': sortOption.name,
        'isDefault': isDefault,
      };
}

/// State for filter presets
class FilterPresetsState {
  const FilterPresetsState({
    this.presets = const [],
    this.activePresetId,
    this.isLoading = false,
  });

  final List<FilterPreset> presets;
  final String? activePresetId;
  final bool isLoading;

  FilterPreset? get activePreset =>
      activePresetId != null
          ? presets.firstWhere(
              (p) => p.id == activePresetId,
              orElse: () => presets.first,
            )
          : null;

  FilterPresetsState copyWith({
    List<FilterPreset>? presets,
    String? activePresetId,
    bool? isLoading,
    bool clearActivePreset = false,
  }) =>
      FilterPresetsState(
        presets: presets ?? this.presets,
        activePresetId: clearActivePreset ? null : (activePresetId ?? this.activePresetId),
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Notifier for filter presets
class FilterPresetsNotifier extends StateNotifier<FilterPresetsState> {
  FilterPresetsNotifier() : super(const FilterPresetsState()) {
    _loadPresets();
  }

  void _loadPresets() {
    // Load default presets (in real app, load from storage)
    state = state.copyWith(
      presets: _defaultPresets,
      isLoading: false,
    );
  }

  void setActivePreset(String? presetId) {
    state = state.copyWith(
      activePresetId: presetId,
      clearActivePreset: presetId == null,
    );
  }

  void addPreset(FilterPreset preset) {
    state = state.copyWith(
      presets: [...state.presets, preset],
    );
  }

  void updatePreset(FilterPreset preset) {
    final updated = state.presets.map((p) {
      if (p.id == preset.id) return preset;
      return p;
    }).toList();
    state = state.copyWith(presets: updated);
  }

  void deletePreset(String presetId) {
    final updated = state.presets.where((p) => p.id != presetId).toList();
    state = state.copyWith(
      presets: updated,
      activePresetId: state.activePresetId == presetId ? null : state.activePresetId,
      clearActivePreset: state.activePresetId == presetId,
    );
  }

  void setDefaultPreset(String presetId) {
    final updated = state.presets.map((p) => p.copyWith(isDefault: p.id == presetId)).toList();
    state = state.copyWith(presets: updated);
  }

  static final _defaultPresets = [
    const FilterPreset(
      id: 'recent',
      name: 'Recent Activity',
      filters: FilterCriteria.empty,
      sortOption: SortOption.dateNewest,
      icon: Icons.schedule_rounded,
      color: AppColors.info,
      isDefault: true,
    ),
    const FilterPreset(
      id: 'in_progress',
      name: 'In Progress',
      filters: FilterCriteria(
        statuses: {'inProgress'},
      ),
      sortOption: SortOption.progressLow,
      icon: Icons.pending_actions_rounded,
      color: AppColors.statusInProgress,
    ),
    const FilterPreset(
      id: 'needs_attention',
      name: 'Needs Attention',
      filters: FilterCriteria(
        statuses: {'draft', 'paused'},
      ),
      sortOption: SortOption.dateOldest,
      icon: Icons.priority_high_rounded,
      color: AppColors.warning,
    ),
    const FilterPreset(
      id: 'with_photos',
      name: 'With Photos',
      filters: FilterCriteria(hasPhotos: true),
      sortOption: SortOption.dateNewest,
      icon: Icons.photo_library_rounded,
      color: AppColors.success,
    ),
  ];
}

final filterPresetsProvider =
    StateNotifierProvider<FilterPresetsNotifier, FilterPresetsState>((ref) => FilterPresetsNotifier());

/// Filter presets selection bottom sheet
class FilterPresetsBottomSheet extends ConsumerWidget {
  const FilterPresetsBottomSheet({
    required this.onPresetSelected,
    required this.currentFilters,
    required this.currentSort,
    super.key,
  });

  final ValueChanged<FilterPreset> onPresetSelected;
  final FilterCriteria currentFilters;
  final SortOption currentSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(filterPresetsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
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
                  'Filter Presets',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showSavePresetDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Save Current'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
          // Presets list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: state.presets.length,
              itemBuilder: (context, index) {
                final preset = state.presets[index];
                final isActive = preset.id == state.activePresetId;

                return _PresetCard(
                  preset: preset,
                  isActive: isActive,
                  onTap: () {
                    ref.read(filterPresetsProvider.notifier).setActivePreset(preset.id);
                    onPresetSelected(preset);
                    Navigator.pop(context);
                  },
                  onDelete: preset.isDefault
                      ? null
                      : () {
                          ref.read(filterPresetsProvider.notifier).deletePreset(preset.id);
                        },
                );
              },
            ),
          ),
          // Clear preset button - extra bottom padding to avoid FAB overlap
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.paddingOf(context).bottom + 80,
            ),
            child: OutlinedButton(
              onPressed: () {
                ref.read(filterPresetsProvider.notifier).setActivePreset(null);
                onPresetSelected(const FilterPreset(
                  id: '',
                  name: '',
                  filters: FilterCriteria.empty,
                  sortOption: SortOption.dateNewest,
                ),);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                'Clear Preset',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Save Preset',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save your current filters and sort options as a preset.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            AppSpacing.gapVerticalMd,
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g., My Custom Filter',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final newPreset = FilterPreset(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  filters: currentFilters,
                  sortOption: currentSort,
                  icon: Icons.filter_list_rounded,
                  color: AppColors.primary,
                );
                ref.read(filterPresetsProvider.notifier).addPreset(newPreset);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Preset "${newPreset.name}" saved'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.isActive,
    required this.onTap,
    this.onDelete,
  });

  final FilterPreset preset;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = preset.color ?? AppColors.primary;
    final description = _getPresetDescription();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: isActive,
        label: '${preset.name}${preset.isDefault ? ', default preset' : ''}. $description${isActive ? ', currently active' : ''}',
        child: Material(
          color: isActive
              ? color.withOpacity(0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isActive
                      ? color
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon (decorative)
                  ExcludeSemantics(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        preset.icon ?? Icons.filter_list_rounded,
                        size: 22,
                        color: color,
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalMd,
                  // Content
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  preset.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? color : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (preset.isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Active indicator or delete button
                  if (isActive)
                    ExcludeSemantics(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: color,
                        size: 22,
                      ),
                    )
                  else if (onDelete != null)
                    Semantics(
                      button: true,
                      label: 'Delete ${preset.name} preset',
                      child: IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.error.withOpacity(0.7),
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPresetDescription() {
    final parts = <String>[];

    if (preset.filters.statuses.isNotEmpty) {
      parts.add('${preset.filters.statuses.length} status filter${preset.filters.statuses.length > 1 ? 's' : ''}');
    }
    if (preset.filters.surveyTypes.isNotEmpty) {
      parts.add('${preset.filters.surveyTypes.length} type${preset.filters.surveyTypes.length > 1 ? 's' : ''}');
    }
    if (preset.filters.hasPhotos != null) {
      parts.add(preset.filters.hasPhotos! ? 'With photos' : 'No photos');
    }
    if (preset.filters.hasNotes != null) {
      parts.add(preset.filters.hasNotes! ? 'With notes' : 'No notes');
    }

    final sortLabel = switch (preset.sortOption) {
      SortOption.dateNewest => 'Newest first',
      SortOption.dateOldest => 'Oldest first',
      SortOption.titleAz => 'A-Z',
      SortOption.titleZa => 'Z-A',
      SortOption.progressHigh => 'Progress ↓',
      SortOption.progressLow => 'Progress ↑',
    };
    parts.add(sortLabel);

    return parts.isEmpty ? 'All surveys' : parts.join(' • ');
  }
}

/// Quick preset chip for inline display
class PresetChip extends ConsumerWidget {
  const PresetChip({
    required this.onPresetSelected,
    super.key,
  });

  final ValueChanged<FilterPreset> onPresetSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(filterPresetsProvider);
    final activePreset = state.activePreset;
    final color = activePreset?.color ?? AppColors.primary;

    return Semantics(
      button: true,
      label: activePreset != null
          ? 'Filter preset: ${activePreset.name}. Tap to change'
          : 'Filter presets. Tap to select a preset',
      child: Material(
        color: activePreset != null
            ? color.withOpacity(0.12)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          onTap: () => _showPresetsSheet(context, ref),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: activePreset != null
                    ? color
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activePreset?.icon ?? Icons.tune_rounded,
                    size: 14,
                    color: activePreset != null
                        ? color
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      activePreset?.name ?? 'Presets',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: activePreset != null
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: activePreset != null
                        ? color
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPresetsSheet(BuildContext context, WidgetRef ref) {
    // Get current filters from forms provider (would need to be passed or accessed)
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPresetsBottomSheet(
        onPresetSelected: onPresetSelected,
        currentFilters: FilterCriteria.empty,
        currentSort: SortOption.dateNewest,
      ),
    );
  }
}

/// Helper function to show presets bottom sheet
Future<FilterPreset?> showFilterPresetsBottomSheet(
  BuildContext context, {
  required FilterCriteria currentFilters,
  required SortOption currentSort,
}) async {
  FilterPreset? selectedPreset;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterPresetsBottomSheet(
      onPresetSelected: (preset) {
        selectedPreset = preset;
      },
      currentFilters: currentFilters,
      currentSort: currentSort,
    ),
  );
  return selectedPreset;
}
