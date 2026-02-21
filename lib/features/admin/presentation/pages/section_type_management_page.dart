import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../config/data/models/section_type_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_error_state.dart';
import '../widgets/admin_loading_state.dart';

/// All known survey type backend strings used for chip selection in dialogs.
const _allSurveyTypes = ['LEVEL_2', 'LEVEL_3', 'SNAGGING', 'VALUATION'];

/// Inspection survey type backend strings (includes legacy aliases from SQL migrations).
const _inspectionSurveyTypes = {
  'LEVEL_2', 'LEVEL_3', 'SNAGGING', 'REINSPECTION',
  // Legacy aliases from SQL migrations (pre-normalization)
  'homebuyer', 'building',
};

/// Valuation survey type backend strings (includes legacy aliases).
const _valuationSurveyTypes = {
  'VALUATION',
  // Legacy alias from SQL migrations (pre-normalization)
  'valuation',
};

/// Maps legacy survey type values to their canonical enum equivalents.
/// Used to pre-populate the edit dialog chips correctly when the DB
/// still has old migration values.
String _normalizeSurveyType(String value) => switch (value) {
      'homebuyer' => 'LEVEL_2',
      'building' => 'LEVEL_3',
      'valuation' => 'VALUATION',
      _ => value,
    };

class SectionTypeManagementPage extends ConsumerStatefulWidget {
  const SectionTypeManagementPage({super.key});

  @override
  ConsumerState<SectionTypeManagementPage> createState() =>
      _SectionTypeManagementPageState();
}

class _SectionTypeManagementPageState
    extends ConsumerState<SectionTypeManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSectionTypesProvider.notifier).loadSectionTypes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter section types based on the selected tab index.
  List<SectionTypeModel> _filterByTab(List<SectionTypeModel> types) {
    switch (_tabController.index) {
      case 1: // Inspection
        return types
            .where((t) =>
                t.surveyTypes.isEmpty ||
                t.surveyTypes.any(_inspectionSurveyTypes.contains),)
            .toList();
      case 2: // Valuation
        return types
            .where((t) =>
                t.surveyTypes.isEmpty ||
                t.surveyTypes.any(_valuationSurveyTypes.contains),)
            .toList();
      default: // All
        return types;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(adminSectionTypesProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Section Types'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Inspection'),
            Tab(text: 'Valuation'),
          ],
        ),
        actions: [
          if (state.isSaving)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminSectionTypesProvider.notifier).loadSectionTypes(),
        child: _buildBody(state, theme, colorScheme),
      ),
    );
  }

  Widget _buildBody(
    AdminSectionTypesState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.sectionTypes.isEmpty) {
      return const AdminLoadingState(message: 'Loading section types...');
    }

    if (state.error != null && state.sectionTypes.isEmpty) {
      return AdminErrorState(
        message: state.error!,
        onRetry: () =>
            ref.read(adminSectionTypesProvider.notifier).loadSectionTypes(),
      );
    }

    if (state.sectionTypes.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.view_module_outlined,
        title: 'No Section Types',
        subtitle: 'Create section types to define survey structure',
      );
    }

    final sorted = List<SectionTypeModel>.from(state.sectionTypes)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final filtered = _filterByTab(sorted);

    if (filtered.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.filter_list_off,
        title: 'No Matching Section Types',
        subtitle: 'No section types match the selected filter',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: filtered.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(adminSectionTypesProvider.notifier)
            .reorderSectionTypes(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final sectionType = filtered[index];
        return _SectionTypeCard(
          key: ValueKey(sectionType.id),
          sectionType: sectionType,
          onEdit: () => _showEditDialog(context, sectionType),
          onToggle: () => ref
              .read(adminSectionTypesProvider.notifier)
              .toggleSectionType(sectionType),
          onDelete: () => _confirmDelete(context, sectionType),
        );
      },
    );
  }

  /// Normalize a key to kebab-case (the format used by apiSectionType).
  /// Converts underscores and spaces to hyphens, lowercases, and trims.
  static String _normalizeKey(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
      .replaceAll(RegExp('-{2,}'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _showCreateDialog(BuildContext context) async {
    final keyController = TextEditingController();
    final labelController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedSurveyTypes = <String>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Section Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    hintText: 'e.g. about-property',
                    helperText: 'Use kebab-case (hyphens, e.g. about-property)',
                  ),
                ),
                AppSpacing.gapVerticalSm,
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. About Property',
                  ),
                ),
                AppSpacing.gapVerticalSm,
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                AppSpacing.gapVerticalMd,
                Text(
                  'Survey Types',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AppSpacing.gapVerticalSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _allSurveyTypes.map((type) {
                    final selected = selectedSurveyTypes.contains(type);
                    return _buildSurveyTypeChip(
                      context: context,
                      type: type,
                      selected: selected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedSurveyTypes.add(type);
                          } else {
                            selectedSurveyTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final key = _normalizeKey(keyController.text);
      final label = labelController.text.trim();
      if (key.isEmpty || label.isEmpty) return;

      final success =
          await ref.read(adminSectionTypesProvider.notifier).createSectionType(
                key: key,
                label: label,
                description: descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
                surveyTypes: selectedSurveyTypes.isNotEmpty
                    ? selectedSurveyTypes.toList()
                    : null,
              );

      if (mounted && !success) {
        final error = ref.read(adminSectionTypesProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to create section type')),
        );
      }
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    SectionTypeModel sectionType,
  ) async {
    final labelController = TextEditingController(text: sectionType.label);
    final descriptionController =
        TextEditingController(text: sectionType.description ?? '');
    final selectedSurveyTypes = <String>{
      ...sectionType.surveyTypes.map(_normalizeSurveyType),
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit: ${sectionType.key}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(labelText: 'Label'),
                ),
                AppSpacing.gapVerticalSm,
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                AppSpacing.gapVerticalMd,
                Text(
                  'Survey Types',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AppSpacing.gapVerticalSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _allSurveyTypes.map((type) {
                    final selected = selectedSurveyTypes.contains(type);
                    return _buildSurveyTypeChip(
                      context: context,
                      type: type,
                      selected: selected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedSurveyTypes.add(type);
                          } else {
                            selectedSurveyTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final label = labelController.text.trim();
      if (label.isEmpty) return;

      await ref.read(adminSectionTypesProvider.notifier).updateSectionType(
            sectionType.id,
            label: label,
            description: descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : null,
            surveyTypes: selectedSurveyTypes.toList(),
          );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SectionTypeModel sectionType,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section Type'),
        content: Text(
          'Are you sure you want to delete "${sectionType.label}"?\n\n'
          'This action cannot be undone and may affect existing surveys '
          'that use this section type.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deleted = await ref
        .read(adminSectionTypesProvider.notifier)
        .deleteSectionType(sectionType.id);

    if (!mounted) return;

    if (deleted != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${sectionType.label}"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref
                  .read(adminSectionTypesProvider.notifier)
                  .restoreSectionType(deleted);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(adminSectionTypesProvider).error ??
                'Failed to delete section type',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Builds a survey-type filter chip with explicit contrast colors that
/// work in both light and dark themes.
Widget _buildSurveyTypeChip({
  required BuildContext context,
  required String type,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return FilterChip(
    label: Text(
      _surveyTypeLabel(type),
      style: TextStyle(
        color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
    selected: selected,
    showCheckmark: false,
    backgroundColor: colorScheme.surfaceContainerHighest,
    selectedColor: colorScheme.primary,
    side: BorderSide(
      color: selected
          ? colorScheme.primary
          : colorScheme.outline.withOpacity(0.5),
    ),
    onSelected: onSelected,
  );
}

/// Human-readable label for a backend survey type string.
String _surveyTypeLabel(String backendType) => switch (backendType) {
      'LEVEL_2' => 'Level 2',
      'LEVEL_3' => 'Level 3',
      'SNAGGING' => 'Snagging',
      'REINSPECTION' => 'Reinspection',
      'VALUATION' => 'Valuation',
      _ => backendType,
    };

/// Determines the category label for a section type's survey types list.
String _surveyTypeCategoryLabel(List<String> surveyTypes) {
  if (surveyTypes.isEmpty) return 'Shared';
  final hasInspection = surveyTypes.any(_inspectionSurveyTypes.contains);
  final hasValuation = surveyTypes.any(_valuationSurveyTypes.contains);
  if (hasInspection && hasValuation) return 'Shared';
  if (hasInspection) return 'Inspection';
  if (hasValuation) return 'Valuation';
  return 'Shared';
}

class _SectionTypeCard extends StatelessWidget {
  const _SectionTypeCard({
    super.key,
    required this.sectionType,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final SectionTypeModel sectionType;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = sectionType.isActive;
    final categoryLabel = _surveyTypeCategoryLabel(sectionType.surveyTypes);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.surface : colorScheme.surfaceContainerHigh,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isActive
              ? colorScheme.outlineVariant.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.view_module_rounded,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + subtitle — must expand to fill available space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sectionType.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive ? null : colorScheme.onSurfaceVariant,
                      decoration:
                          isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        sectionType.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      _SurveyTypeBadge(label: categoryLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Actions — fixed width, never overflows
            Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
              onPressed: onDelete,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
            const Icon(Icons.drag_handle_rounded),
          ],
        ),
      ),
    );
  }
}

/// Small colored badge indicating which survey type category a section belongs to.
class _SurveyTypeBadge extends StatelessWidget {
  const _SurveyTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg) = switch (label) {
      'Inspection' => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      'Valuation' => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      _ => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
