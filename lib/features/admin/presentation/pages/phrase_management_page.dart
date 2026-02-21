import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../config/domain/entities/phrase.dart';
import '../../../config/domain/entities/phrase_category.dart';
import '../providers/admin_providers.dart';

class PhraseManagementPage extends ConsumerStatefulWidget {
  const PhraseManagementPage({super.key});

  @override
  ConsumerState<PhraseManagementPage> createState() =>
      _PhraseManagementPageState();
}

class _PhraseManagementPageState extends ConsumerState<PhraseManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminPhrasesProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final phrasesState = ref.watch(adminPhrasesProvider);

    // Listen for errors and show snackbar
    ref.listen<AdminPhrasesState>(adminPhrasesProvider, (previous, next) {
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
        title: const Text('Phrase Management'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Add Category button
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: phrasesState.isSaving ? null : _showAddCategoryDialog,
            tooltip: 'Add Category',
          ),
          if (phrasesState.isSaving)
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
      // Handle keyboard properly - don't resize when keyboard opens
      resizeToAvoidBottomInset: true,
      body: phrasesState.isLoading && phrasesState.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Category selector (fixed at top)
                  _CategorySelector(
                    categories: phrasesState.categories,
                    selectedCategory: phrasesState.selectedCategory,
                    onCategorySelected: (category) {
                      ref.read(adminPhrasesProvider.notifier).selectCategory(category);
                    },
                    // Show indicator if selected category is a seed/placeholder
                    isSeedCategory: phrasesState.selectedCategory?.id.startsWith('seed-') ?? false,
                    onEditCategory: phrasesState.selectedCategory != null &&
                            !phrasesState.selectedCategory!.id.startsWith('seed-')
                        ? () => _showEditCategoryDialog(phrasesState.selectedCategory!)
                        : null,
                    onDeleteCategory: phrasesState.selectedCategory != null &&
                            !phrasesState.selectedCategory!.id.startsWith('seed-') &&
                            !phrasesState.selectedCategory!.isSystem
                        ? () => _confirmDeleteCategory(phrasesState.selectedCategory!)
                        : null,
                  ),

                  // Phrases list (scrollable, takes remaining space)
                  Expanded(
                    child: phrasesState.selectedCategory == null
                        ? _buildNoCategorySelected(theme, colorScheme)
                        : phrasesState.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _PhrasesList(
                                phrases: phrasesState.phrases,
                                categoryName: phrasesState.selectedCategory!.displayName,
                                isSeedCategory: phrasesState.selectedCategory!.id.startsWith('seed-'),
                                onAddPhrase: _showAddPhraseDialog,
                                onEditPhrase: _showEditPhraseDialog,
                                onTogglePhrase: _togglePhrase,
                                onReorder: _reorderPhrases,
                              ),
                  ),

                  // Add button at bottom with keyboard-safe padding
                  if (phrasesState.selectedCategory != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.md + MediaQuery.of(context).viewInsets.bottom * 0.1,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: phrasesState.isSaving ? null : _showAddPhraseDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Phrase'),
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
            ),
    );
  }

  Widget _buildNoCategorySelected(ThemeData theme, ColorScheme colorScheme) => Center(
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
              Icons.category_outlined,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapVerticalLg,
          Text(
            'Select a category',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'Choose a phrase category to manage its options',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

  Future<void> _showAddCategoryDialog() async {
    final result = await showDialog<({String name, String? description})>(
      context: context,
      builder: (context) => const _CategoryDialog(),
    );

    if (result != null && result.name.isNotEmpty && mounted) {
      final success = await ref.read(adminPhrasesProvider.notifier).createCategory(
        displayName: result.name,
        description: result.description,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created category "${result.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditCategoryDialog(PhraseCategory category) async {
    final nameController = TextEditingController(text: category.displayName);
    final descController = TextEditingController(text: category.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusMd),
                ),
              ),
              AppSpacing.gapVerticalMd,
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: AppSpacing.borderRadiusMd),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final name = nameController.text.trim();
      if (name.isEmpty) return;

      final success = await ref.read(adminPhrasesProvider.notifier).updateCategory(
            category.id,
            displayName: name,
            description: descController.text.trim().isNotEmpty
                ? descController.text.trim()
                : null,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated category "$name"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteCategory(PhraseCategory category) async {
    final deleted = await ref.read(adminPhrasesProvider.notifier).deleteCategory(category.id);

    if (!mounted) return;

    if (deleted != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${category.displayName}"'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref
                  .read(adminPhrasesProvider.notifier)
                  .restoreCategory(deleted);
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(adminPhrasesProvider).error ??
                'Failed to delete category',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAddPhraseDialog() async {
    final phrasesState = ref.read(adminPhrasesProvider);
    if (phrasesState.selectedCategory == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _PhraseDialog(
        title: 'Add Phrase',
        categoryName: phrasesState.selectedCategory!.displayName,
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final success = await ref.read(adminPhrasesProvider.notifier).createPhrase(result);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$result"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditPhraseDialog(Phrase phrase) async {
    final phrasesState = ref.read(adminPhrasesProvider);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _PhraseDialog(
        title: 'Edit Phrase',
        categoryName: phrasesState.selectedCategory!.displayName,
        initialValue: phrase.value,
      ),
    );

    if (result != null && result.isNotEmpty && result != phrase.value && mounted) {
      final success = await ref.read(adminPhrasesProvider.notifier).updatePhrase(
        phrase.id,
        value: result,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated to "$result"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _togglePhrase(Phrase phrase) async {
    final action = phrase.isActive ? 'Disable' : 'Enable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Phrase'),
        content: Text(
          '$action "${phrase.value}"? ${phrase.isActive ? 'It will no longer appear in dropdowns.' : 'It will appear in dropdowns again.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: phrase.isActive
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
      final success = await ref.read(adminPhrasesProvider.notifier).togglePhrase(phrase);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${phrase.isActive ? 'Disabled' : 'Enabled'} "${phrase.value}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _reorderPhrases(int oldIndex, int newIndex) async {
    final success = await ref.read(adminPhrasesProvider.notifier).reorderPhrases(oldIndex, newIndex);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phrases reordered'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.isSeedCategory = false,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  final List<PhraseCategory> categories;
  final PhraseCategory? selectedCategory;
  final ValueChanged<PhraseCategory> onCategorySelected;
  final bool isSeedCategory;
  final VoidCallback? onEditCategory;
  final VoidCallback? onDeleteCategory;

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
            'Phrase Category',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.gapVerticalSm,
          // Warning banner for seed/placeholder categories
          if (isSeedCategory) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.5),
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(
                  color: colorScheme.tertiary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a placeholder category. Create a new category using the folder icon to add phrases.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          DropdownButtonFormField<String>(
            value: selectedCategory?.id,
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
              hintText: 'Select a category',
            ),
            items: categories.map((category) => DropdownMenuItem(
                value: category.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category.isSystem)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        category.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!category.isActive)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Inactive',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),).toList(),
            onChanged: (id) {
              if (id != null) {
                final category = categories.firstWhere((c) => c.id == id);
                onCategorySelected(category);
              }
            },
          ),
          if (onEditCategory != null || onDeleteCategory != null) ...[
            AppSpacing.gapVerticalSm,
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onEditCategory != null)
                  TextButton.icon(
                    onPressed: onEditCategory,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Category'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (onDeleteCategory != null)
                  TextButton.icon(
                    onPressed: onDeleteCategory,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: colorScheme.error,
                    ),
                    label: Text(
                      'Delete Category',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PhrasesList extends StatelessWidget {
  const _PhrasesList({
    required this.phrases,
    required this.categoryName,
    required this.onAddPhrase,
    required this.onEditPhrase,
    required this.onTogglePhrase,
    required this.onReorder,
    this.isSeedCategory = false,
  });

  final List<Phrase> phrases;
  final String categoryName;
  final VoidCallback onAddPhrase;
  final ValueChanged<Phrase> onEditPhrase;
  final ValueChanged<Phrase> onTogglePhrase;
  final void Function(int oldIndex, int newIndex) onReorder;
  final bool isSeedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show placeholder message for seed categories
    if (isSeedCategory) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 32,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              AppSpacing.gapVerticalLg,
              Text(
                'Placeholder Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapVerticalSm,
              Text(
                '"$categoryName" is a placeholder category.\n'
                'Create a new category to add custom phrases.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapVerticalLg,
              Text(
                'Tap the folder icon in the top bar to create a new category.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (phrases.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                  Icons.format_quote_rounded,
                  size: 32,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapVerticalLg,
              Text(
                'No phrases yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapVerticalSm,
              Text(
                'Add phrases to $categoryName',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapVerticalLg,
              FilledButton.icon(
                onPressed: onAddPhrase,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Phrase'),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: phrases.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final phrase = phrases[index];
        return _PhraseCard(
          key: ValueKey(phrase.id),
          phrase: phrase,
          index: index,
          onEdit: () => onEditPhrase(phrase),
          onToggle: () => onTogglePhrase(phrase),
        );
      },
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    super.key,
    required this.phrase,
    required this.index,
    required this.onEdit,
    required this.onToggle,
  });

  final Phrase phrase;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: phrase.isActive
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: phrase.isActive
              ? colorScheme.outlineVariant.withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  size: 22,
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phrase value
                    Text(
                      phrase.value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: phrase.isActive
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
                        decoration: phrase.isActive ? null : TextDecoration.lineThrough,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Tags row
                    if (phrase.isDefault || !phrase.isActive) ...[
                      AppSpacing.gapVerticalXs,
                      Row(
                        children: [
                          if (phrase.isDefault)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (!phrase.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Disabled',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: onEdit,
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                phrase.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: phrase.isActive
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
              onPressed: onToggle,
              tooltip: phrase.isActive ? 'Disable' : 'Enable',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhraseDialog extends StatefulWidget {
  const _PhraseDialog({
    required this.title,
    required this.categoryName,
    this.initialValue,
  });

  final String title;
  final String categoryName;
  final String? initialValue;

  @override
  State<_PhraseDialog> createState() => _PhraseDialogState();
}

class _PhraseDialogState extends State<_PhraseDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: ${widget.categoryName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalMd,
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Phrase Value',
                hintText: 'Enter phrase text',
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => Navigator.pop(context, _controller.text.trim()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.initialValue != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog();

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('Create Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a new phrase category for dropdown options',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalMd,
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Property Type',
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            AppSpacing.gapVerticalMd,
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this category used for?',
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (
              name: name,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
            ),);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
