import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/domain/entities/survey_section.dart';
import '../../../config/domain/entities/field_definition.dart';
import '../../../config/domain/entities/phrase_category.dart';
import '../../../config/presentation/helpers/config_aware_fields.dart';
import '../../../config/presentation/providers/config_providers.dart';
import '../providers/admin_providers.dart';

class FieldManagementPage extends ConsumerStatefulWidget {
  const FieldManagementPage({super.key});

  @override
  ConsumerState<FieldManagementPage> createState() =>
      _FieldManagementPageState();
}

class _FieldManagementPageState extends ConsumerState<FieldManagementPage> {
  /// Selected section key (API format, e.g. 'about-property').
  String? _selectedSectionKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminFieldsProvider.notifier).loadAllFields();
      ref.read(adminPhrasesProvider.notifier).loadCategories();
    });
  }

  /// Build the merged list of section dropdown entries.
  /// Combines hardcoded SectionType enum values with any additional
  /// section types from config that have non-matching keys.
  List<_SectionDropdownEntry> _buildSectionEntries() {
    // Hardcoded enum-based entries
    final hardcodedKeys = <String>{};
    final entries = <_SectionDropdownEntry>[];

    for (final type in SectionType.values) {
      final key = type.apiSectionType;
      hardcodedKeys.add(key);
      entries.add(_SectionDropdownEntry(
        key: key,
        label: _sectionTypeDisplayName(type),
        icon: _getSectionIcon(type),
      ),);
    }

    // Append dynamic section types from config whose keys aren't already covered
    final configState = ref.read(configProvider);
    for (final st in configState.sectionTypes) {
      if (st.isActive && !hardcodedKeys.contains(st.key)) {
        entries.add(_SectionDropdownEntry(
          key: st.key,
          label: st.label,
          icon: Icons.view_module_outlined,
        ),);
      }
    }

    return entries;
  }

  String _sectionTypeDisplayName(SectionType type) {
    switch (type) {
      case SectionType.aboutInspection:
        return 'About Inspection';
      case SectionType.aboutProperty:
        return 'About Property';
      case SectionType.construction:
        return 'Construction';
      case SectionType.externalItems:
        return 'External Items';
      case SectionType.internalItems:
        return 'Internal Items';
      case SectionType.exterior:
        return 'Exterior';
      case SectionType.interior:
        return 'Interior';
      case SectionType.rooms:
        return 'Rooms';
      case SectionType.services:
        return 'Services';
      case SectionType.issuesAndRisks:
        return 'Issues & Risks';
      case SectionType.photos:
        return 'Photos';
      case SectionType.notes:
        return 'Notes';
      case SectionType.signature:
        return 'Signature';
      case SectionType.aboutValuation:
        return 'About Valuation';
      case SectionType.propertySummary:
        return 'Property Summary';
      case SectionType.marketAnalysis:
        return 'Market Analysis';
      case SectionType.comparables:
        return 'Comparables';
      case SectionType.adjustments:
        return 'Adjustments';
      case SectionType.valuation:
        return 'Valuation';
      case SectionType.summary:
        return 'Summary';
    }
  }

  IconData _getSectionIcon(SectionType type) {
    switch (type) {
      case SectionType.aboutInspection:
        return Icons.assignment_outlined;
      case SectionType.construction:
        return Icons.foundation_outlined;
      case SectionType.externalItems:
        return Icons.landscape_outlined;
      case SectionType.internalItems:
        return Icons.door_sliding_outlined;
      case SectionType.exterior:
        return Icons.roofing_outlined;
      case SectionType.interior:
        return Icons.chair_outlined;
      case SectionType.rooms:
        return Icons.meeting_room_outlined;
      case SectionType.services:
        return Icons.plumbing_outlined;
      case SectionType.issuesAndRisks:
        return Icons.warning_amber_outlined;
      case SectionType.aboutProperty:
        return Icons.home_outlined;
      case SectionType.photos:
        return Icons.photo_library_outlined;
      case SectionType.notes:
        return Icons.note_outlined;
      case SectionType.signature:
        return Icons.draw_outlined;
      case SectionType.aboutValuation:
        return Icons.assignment_outlined;
      case SectionType.propertySummary:
        return Icons.home_work_outlined;
      case SectionType.marketAnalysis:
        return Icons.analytics_outlined;
      case SectionType.comparables:
        return Icons.compare_arrows_outlined;
      case SectionType.adjustments:
        return Icons.tune_outlined;
      case SectionType.valuation:
        return Icons.price_check_outlined;
      case SectionType.summary:
        return Icons.summarize_outlined;
    }
  }

  /// Try to resolve a section key to its display name.
  String _displayNameForKey(String key) {
    // Try hardcoded enum first
    for (final type in SectionType.values) {
      if (type.apiSectionType == key) {
        return _sectionTypeDisplayName(type);
      }
    }
    // Fall back to config section type label
    final configState = ref.read(configProvider);
    for (final st in configState.sectionTypes) {
      if (st.key == key) return st.label;
    }
    // Last resort: humanize the key
    return key.replaceAll('-', ' ').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fieldsState = ref.watch(adminFieldsProvider);
    final phrasesState = ref.watch(adminPhrasesProvider);

    // Get fields for selected section, falling back to hardcoded defaults
    List<FieldDefinition> sectionFields;
    if (_selectedSectionKey != null) {
      sectionFields = ref.read(adminFieldsProvider.notifier).getFieldsForSection(
            _selectedSectionKey!,
          );
      // If no API fields, try to generate from hardcoded section field config
      // If no API fields, show empty state (admin can add fields)
      if (sectionFields.isEmpty) {
        // No default fields — admin must create them via the API
      }
    } else {
      sectionFields = <FieldDefinition>[];
    }

    // Listen for errors
    ref.listen<AdminFieldsState>(adminFieldsProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Field Management'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (fieldsState.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: fieldsState.isLoading && fieldsState.fields.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Section selector
                _SectionKeySelector(
                  selectedKey: _selectedSectionKey,
                  entries: _buildSectionEntries(),
                  onKeySelected: (key) {
                    setState(() => _selectedSectionKey = key);
                    ref.read(adminFieldsProvider.notifier).selectSection(key);
                  },
                ),

                // Fields list
                Expanded(
                  child: _selectedSectionKey == null
                      ? _buildNoSectionSelected(theme, colorScheme)
                      : _FieldsList(
                          fields: sectionFields,
                          categories: phrasesState.categories,
                          onEditField: _showEditFieldDialog,
                          onToggleField: _toggleField,
                          onReorder: _reorderFields,
                        ),
                ),

                // Add button at bottom
                if (_selectedSectionKey != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: fieldsState.isSaving ? null : _showAddFieldDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Field'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildNoSectionSelected(ThemeData theme, ColorScheme colorScheme) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.view_list_rounded,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapVerticalLg,
          Text(
            'Select a section',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'Choose a survey section to manage its fields',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

  /// Resolve a section key to the hardcoded SectionType enum, or null.
  SectionType? _enumFromKey(String key) {
    for (final type in SectionType.values) {
      if (type.apiSectionType == key) return type;
    }
    return null;
  }

  Future<void> _showAddFieldDialog() async {
    if (_selectedSectionKey == null) return;

    final phrasesState = ref.read(adminPhrasesProvider);
    final sectionType = _selectedSectionKey!;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FieldAddSheet(
        sectionType: sectionType,
        sectionName: _displayNameForKey(sectionType),
        categories: phrasesState.categories,
      ),
    );

    if (result != null && mounted) {
      final success = await ref.read(adminFieldsProvider.notifier).createField(
            sectionType: sectionType,
            fieldKey: result['fieldKey'] as String,
            fieldType: result['fieldType'] as FieldType,
            label: result['label'] as String,
            placeholder: result['placeholder'] as String?,
            hint: result['hint'] as String?,
            isRequired: result['isRequired'] as bool?,
            phraseCategoryId: result['phraseCategoryId'] as String?,
            fieldGroup: result['fieldGroup'] as String?,
            conditionalOn: result['conditionalOn'] as String?,
            conditionalValue: result['conditionalValue'] as String?,
            description: result['description'] as String?,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${result['label']}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditFieldDialog(FieldDefinition field) async {
    final phrasesState = ref.read(adminPhrasesProvider);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FieldEditSheet(
        field: field,
        categories: phrasesState.categories,
      ),
    );

    if (result != null && mounted) {
      final success = await ref.read(adminFieldsProvider.notifier).updateField(
            field.id,
            fieldType: result['fieldType'] as FieldType?,
            label: result['label'] as String?,
            placeholder: result['placeholder'] as String?,
            hint: result['hint'] as String?,
            isRequired: result['isRequired'] as bool?,
            phraseCategoryId: result['phraseCategoryId'] as String?,
            fieldGroup: result['fieldGroup'] as String?,
            conditionalOn: result['conditionalOn'] as String?,
            conditionalValue: result['conditionalValue'] as String?,
            description: result['description'] as String?,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${result['label'] ?? field.label}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleField(FieldDefinition field) async {
    final action = field.isActive ? 'Disable' : 'Enable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Field'),
        content: Text(
          '$action "${field.label}"? ${field.isActive ? 'It will be hidden from survey forms.' : 'It will appear in survey forms again.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: field.isActive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(adminFieldsProvider.notifier).toggleField(field);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${field.isActive ? 'Disabled' : 'Enabled'} "${field.label}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reorderFields(int oldIndex, int newIndex) async {
    if (_selectedSectionKey == null) return;

    final sectionType = _selectedSectionKey!;
    final success = await ref.read(adminFieldsProvider.notifier).reorderFields(
          sectionType,
          oldIndex,
          newIndex,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fields reordered'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// A dropdown entry that pairs a section key with a display label and icon.
class _SectionDropdownEntry {
  const _SectionDropdownEntry({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class _SectionKeySelector extends StatelessWidget {
  const _SectionKeySelector({
    required this.selectedKey,
    required this.entries,
    required this.onKeySelected,
  });

  final String? selectedKey;
  final List<_SectionDropdownEntry> entries;
  final ValueChanged<String> onKeySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Survey Section',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.gapVerticalSm,
          DropdownButtonFormField<String>(
            value: selectedKey,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              hintText: 'Select a section',
            ),
            isExpanded: true,
            items: entries.map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(entry.icon, size: 18, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entry.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),).toList(),
            onChanged: (key) {
              if (key != null) {
                onKeySelected(key);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _FieldsList extends StatelessWidget {
  const _FieldsList({
    required this.fields,
    required this.categories,
    required this.onEditField,
    required this.onToggleField,
    required this.onReorder,
  });

  final List<FieldDefinition> fields;
  final List<PhraseCategory> categories;
  final ValueChanged<FieldDefinition> onEditField;
  final ValueChanged<FieldDefinition> onToggleField;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (fields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.text_fields_rounded,
                size: 32,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalLg,
            Text(
              'No fields configured',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'Add fields to this section',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: fields.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final field = fields[index];
        return _FieldCard(
          key: ValueKey(field.id),
          field: field,
          index: index,
          categories: categories,
          onEdit: () => onEditField(field),
          onToggle: () => onToggleField(field),
        );
      },
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    super.key,
    required this.field,
    required this.index,
    required this.categories,
    required this.onEdit,
    required this.onToggle,
  });

  final FieldDefinition field;
  final int index;
  final List<PhraseCategory> categories;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  String _getFieldTypeLabel(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Text';
      case FieldType.number:
        return 'Number';
      case FieldType.dropdown:
        return 'Dropdown';
      case FieldType.radio:
        return 'Radio';
      case FieldType.checkbox:
        return 'Checkbox';
      case FieldType.date:
        return 'Date';
      case FieldType.signature:
        return 'Signature';
      case FieldType.textarea:
        return 'Text Area';
    }
  }

  IconData _getFieldTypeIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.text_fields_rounded;
      case FieldType.number:
        return Icons.numbers_rounded;
      case FieldType.dropdown:
        return Icons.arrow_drop_down_circle_outlined;
      case FieldType.radio:
        return Icons.radio_button_checked_rounded;
      case FieldType.checkbox:
        return Icons.check_box_outlined;
      case FieldType.date:
        return Icons.calendar_today_rounded;
      case FieldType.signature:
        return Icons.draw_rounded;
      case FieldType.textarea:
        return Icons.notes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final linkedCategory = field.phraseCategoryId != null
        ? categories.cast<PhraseCategory>().firstWhere(
            (c) => c.id == field.phraseCategoryId,
            orElse: () => const PhraseCategory(
              id: '',
              slug: '',
              displayName: 'Unknown',
              isSystem: false,
              isActive: false,
              displayOrder: 0,
            ),
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: field.isActive
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.gapHorizontalMd,

                // Field type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(
                    _getFieldTypeIcon(field.fieldType),
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                AppSpacing.gapHorizontalMd,

                // Field info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              field.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: field.isActive
                                    ? null
                                    : colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                          if (field.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.gapVerticalXs,
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getFieldTypeLabel(field.fieldType),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (linkedCategory != null &&
                              linkedCategory.id.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                AppSpacing.gapHorizontalXs,
                                Flexible(
                                  child: Text(
                                    linkedCategory.displayName,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.tertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (!field.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Disabled',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                IconButton(
                  icon: Icon(
                    field.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: onToggle,
                  tooltip: field.isActive ? 'Disable' : 'Enable',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldAddSheet extends StatefulWidget {
  const _FieldAddSheet({
    required this.sectionType,
    required this.sectionName,
    required this.categories,
  });

  final String sectionType;
  final String sectionName;
  final List<PhraseCategory> categories;

  @override
  State<_FieldAddSheet> createState() => _FieldAddSheetState();
}

class _FieldAddSheetState extends State<_FieldAddSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fieldKeyController;
  late TextEditingController _labelController;
  late TextEditingController _placeholderController;
  late TextEditingController _hintController;
  late TextEditingController _groupController;
  late TextEditingController _conditionalOnController;
  late TextEditingController _conditionalValueController;
  late TextEditingController _descriptionController;
  FieldType _fieldType = FieldType.text;
  bool _isRequired = false;
  String? _linkedCategoryId;

  @override
  void initState() {
    super.initState();
    _fieldKeyController = TextEditingController();
    _labelController = TextEditingController();
    _placeholderController = TextEditingController();
    _hintController = TextEditingController();
    _groupController = TextEditingController();
    _conditionalOnController = TextEditingController();
    _conditionalValueController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _fieldKeyController.dispose();
    _labelController.dispose();
    _placeholderController.dispose();
    _hintController.dispose();
    _groupController.dispose();
    _conditionalOnController.dispose();
    _conditionalValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canLinkCategory =>
      _fieldType == FieldType.dropdown ||
      _fieldType == FieldType.radio ||
      _fieldType == FieldType.checkbox;

  String _generateFieldKey(String label) => label
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Add Field',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                AppSpacing.gapHorizontalSm,
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'fieldKey': _fieldKeyController.text.isNotEmpty
                            ? _fieldKeyController.text
                            : _generateFieldKey(_labelController.text),
                        'fieldType': _fieldType,
                        'label': _labelController.text,
                        'placeholder': _placeholderController.text.isNotEmpty
                            ? _placeholderController.text
                            : null,
                        'hint': _hintController.text.isNotEmpty
                            ? _hintController.text
                            : null,
                        'isRequired': _isRequired,
                        'phraseCategoryId': _linkedCategoryId,
                        'fieldGroup': _groupController.text.isNotEmpty
                            ? _groupController.text
                            : null,
                        'conditionalOn': _conditionalOnController.text.isNotEmpty
                            ? _conditionalOnController.text
                            : null,
                        'conditionalValue': _conditionalValueController.text.isNotEmpty
                            ? _conditionalValueController.text
                            : null,
                        'description': _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : null,
                      });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section: ${widget.sectionName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label *',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onChanged: (v) {
                        if (_fieldKeyController.text.isEmpty) {
                          setState(() {});
                        }
                      },
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _fieldKeyController,
                      decoration: InputDecoration(
                        labelText: 'Field Key',
                        hintText: _labelController.text.isNotEmpty
                            ? _generateFieldKey(_labelController.text)
                            : 'Auto-generated from label',
                        border: const OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    DropdownButtonFormField<FieldType>(
                      value: _fieldType,
                      decoration: const InputDecoration(
                        labelText: 'Field Type *',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                      items: FieldType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        ),).toList(),
                      onChanged: (type) {
                        if (type != null) {
                          setState(() {
                            _fieldType = type;
                            if (!_canLinkCategory) {
                              _linkedCategoryId = null;
                            }
                          });
                        }
                      },
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _placeholderController,
                      decoration: const InputDecoration(
                        labelText: 'Placeholder',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _hintController,
                      decoration: const InputDecoration(
                        labelText: 'Hint/Helper Text',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    SwitchListTile(
                      title: const Text('Required Field'),
                      subtitle: const Text('User must fill this field'),
                      value: _isRequired,
                      onChanged: (value) => setState(() => _isRequired = value),
                      contentPadding: EdgeInsets.zero,
                    ),

                    if (_canLinkCategory) ...[
                      AppSpacing.gapVerticalMd,
                      DropdownButtonFormField<String?>(
                        value: _linkedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Linked Phrase Category',
                          helperText: 'Options will come from this category',
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            child: Text('None'),
                          ),
                          ...widget.categories.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),),
                        ],
                        onChanged: (value) {
                          setState(() => _linkedCategoryId = value);
                        },
                      ),
                    ],

                    // Group, Conditional, Description fields
                    AppSpacing.gapVerticalLg,
                    Text(
                      'Advanced',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapVerticalSm,

                    TextFormField(
                      controller: _groupController,
                      decoration: const InputDecoration(
                        labelText: 'Group',
                        helperText: 'UI group within the section (e.g., "Property Type")',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _conditionalOnController,
                      decoration: const InputDecoration(
                        labelText: 'Conditional On (Field Key)',
                        helperText: 'Show this field only when another field has a value',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _conditionalValueController,
                      decoration: const InputDecoration(
                        labelText: 'Conditional Value',
                        helperText: 'The value the above field must have',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    AppSpacing.gapVerticalMd,

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        helperText: 'Extended help text shown below the field',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldEditSheet extends StatefulWidget {
  const _FieldEditSheet({
    required this.field,
    required this.categories,
  });

  final FieldDefinition field;
  final List<PhraseCategory> categories;

  @override
  State<_FieldEditSheet> createState() => _FieldEditSheetState();
}

class _FieldEditSheetState extends State<_FieldEditSheet> {
  late TextEditingController _labelController;
  late TextEditingController _placeholderController;
  late TextEditingController _hintController;
  late TextEditingController _groupController;
  late TextEditingController _conditionalOnController;
  late TextEditingController _conditionalValueController;
  late TextEditingController _descriptionController;
  late FieldType _fieldType;
  late bool _isRequired;
  late String? _linkedCategoryId;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _placeholderController = TextEditingController(text: widget.field.placeholder);
    _hintController = TextEditingController(text: widget.field.helperText);
    _groupController = TextEditingController(text: widget.field.fieldGroup);
    _conditionalOnController = TextEditingController(text: widget.field.conditionalOn);
    _conditionalValueController = TextEditingController(text: widget.field.conditionalValue);
    _descriptionController = TextEditingController(text: widget.field.description);
    _fieldType = widget.field.fieldType;
    _isRequired = widget.field.isRequired;
    _linkedCategoryId = widget.field.phraseCategoryId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _hintController.dispose();
    _groupController.dispose();
    _conditionalOnController.dispose();
    _conditionalValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canLinkCategory =>
      _fieldType == FieldType.dropdown ||
      _fieldType == FieldType.radio ||
      _fieldType == FieldType.checkbox;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Edit Field',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                AppSpacing.gapHorizontalSm,
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'fieldType': _fieldType != widget.field.fieldType ? _fieldType : null,
                      'label': _labelController.text != widget.field.label
                          ? _labelController.text
                          : null,
                      'placeholder': _placeholderController.text != widget.field.placeholder
                          ? _placeholderController.text
                          : null,
                      'hint': _hintController.text != widget.field.helperText
                          ? _hintController.text
                          : null,
                      'isRequired': _isRequired != widget.field.isRequired ? _isRequired : null,
                      'phraseCategoryId': _linkedCategoryId != widget.field.phraseCategoryId
                          ? _linkedCategoryId
                          : null,
                      'fieldGroup': _groupController.text != (widget.field.fieldGroup ?? '')
                          ? (_groupController.text.isNotEmpty ? _groupController.text : null)
                          : null,
                      'conditionalOn': _conditionalOnController.text != (widget.field.conditionalOn ?? '')
                          ? (_conditionalOnController.text.isNotEmpty ? _conditionalOnController.text : null)
                          : null,
                      'conditionalValue': _conditionalValueController.text != (widget.field.conditionalValue ?? '')
                          ? (_conditionalValueController.text.isNotEmpty ? _conditionalValueController.text : null)
                          : null,
                      'description': _descriptionController.text != (widget.field.description ?? '')
                          ? (_descriptionController.text.isNotEmpty ? _descriptionController.text : null)
                          : null,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field Key: ${widget.field.fieldKey}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  DropdownButtonFormField<FieldType>(
                    value: _fieldType,
                    decoration: const InputDecoration(
                      labelText: 'Field Type',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                    items: FieldType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      ),).toList(),
                    onChanged: (type) {
                      if (type != null) {
                        setState(() {
                          _fieldType = type;
                          if (!_canLinkCategory) {
                            _linkedCategoryId = null;
                          }
                        });
                      }
                    },
                  ),
                  AppSpacing.gapVerticalMd,

                  TextField(
                    controller: _placeholderController,
                    decoration: const InputDecoration(
                      labelText: 'Placeholder (optional)',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  TextField(
                    controller: _hintController,
                    decoration: const InputDecoration(
                      labelText: 'Hint/Helper Text (optional)',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  SwitchListTile(
                    title: const Text('Required Field'),
                    subtitle: const Text('User must fill this field'),
                    value: _isRequired,
                    onChanged: (value) => setState(() => _isRequired = value),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_canLinkCategory) ...[
                    AppSpacing.gapVerticalMd,
                    DropdownButtonFormField<String?>(
                      value: _linkedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Linked Phrase Category',
                        helperText: 'Options will come from this category',
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderRadiusMd,
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          child: Text('None (hardcoded options)'),
                        ),
                        ...widget.categories.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),),
                      ],
                      onChanged: (value) {
                        setState(() => _linkedCategoryId = value);
                      },
                    ),
                  ],

                  // Group, Conditional, Description fields
                  AppSpacing.gapVerticalLg,
                  Text(
                    'Advanced',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapVerticalSm,

                  TextField(
                    controller: _groupController,
                    decoration: const InputDecoration(
                      labelText: 'Group',
                      helperText: 'UI group within the section (e.g., "Property Type")',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  TextField(
                    controller: _conditionalOnController,
                    decoration: const InputDecoration(
                      labelText: 'Conditional On (Field Key)',
                      helperText: 'Show this field only when another field has a value',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  TextField(
                    controller: _conditionalValueController,
                    decoration: const InputDecoration(
                      labelText: 'Conditional Value',
                      helperText: 'The value the above field must have',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  AppSpacing.gapVerticalMd,

                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      helperText: 'Extended help text shown below the field',
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
