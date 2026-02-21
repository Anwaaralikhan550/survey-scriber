import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../data/tree_admin_repository.dart';
import '../providers/tree_admin_providers.dart';

/// Consistent M3 input decoration for all admin panel TextFields.
/// Ensures visible border in both enabled and focused states.
InputDecoration _adminInputDecoration(
  ThemeData theme, {
  String? labelText,
  String? hintText,
  bool isDense = true,
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    isDense: isDense,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerLowest,
    labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.error,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.error,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// Consistent Cancel button style for admin panel.
ButtonStyle _adminCancelButtonStyle(ThemeData theme) {
  return OutlinedButton.styleFrom(
    side: BorderSide(
      color: theme.colorScheme.outline,
      width: 1,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// Consistent primary action button style for admin panel.
ButtonStyle _adminPrimaryButtonStyle(ThemeData theme) {
  return FilledButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// Main admin page for browsing and managing survey trees.
/// Supports both Inspection and Valuation.
class TreeBrowserPage extends ConsumerWidget {
  const TreeBrowserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(treeAdminSelectedTreeTypeProvider);
    final treeAsync = ref.watch(treeAdminTreeProvider);
    final statsAsync = ref.watch(treeAdminTreeStatsProvider);
    final adminState = ref.watch(treeAdminNotifierProvider);
    final theme = Theme.of(context);

    final hasOverride =
        ref.watch(treeAdminHasOverrideProvider).valueOrNull ?? false;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Survey Tree Manager'),
            actions: [
              // Publish button — only shown when local override exists
              if (hasOverride)
                IconButton(
                  icon: const Icon(Icons.cloud_upload_rounded),
                  tooltip: 'Publish to Server',
                  onPressed: adminState.isPublishing
                      ? null
                      : () => _showPublishDialog(context, ref, selectedType),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) async {
                  final notifier = ref.read(treeAdminNotifierProvider.notifier);
                  if (value == 'reset') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset to Original'),
                        content: Text(
                          'This will discard all admin edits for ${selectedType.displayName} '
                          'and restore the bundled version. A backup will be created.',
                        ),
                        actions: [
                          OutlinedButton(
                            style: _adminCancelButtonStyle(theme),
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await notifier.resetToAsset();
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: ListTile(
                      leading: Icon(Icons.restore_rounded),
                      title: Text('Reset to Original'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tree type selector
                SegmentedButton<SurveyTreeType>(
                  segments: const [
                    ButtonSegment(
                      value: SurveyTreeType.inspection,
                      label: Text('Inspection'),
                      icon: Icon(Icons.assignment_outlined),
                    ),
                    ButtonSegment(
                      value: SurveyTreeType.valuation,
                      label: Text('Valuation'),
                      icon: Icon(Icons.assessment_outlined),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selected) {
                    ref.read(treeAdminSelectedTreeTypeProvider.notifier).state =
                        selected.first;
                    ref.read(treeAdminSelectedSectionProvider.notifier).state =
                        null;
                    ref.read(treeAdminSelectedScreenProvider.notifier).state =
                        null;
                  },
                ),
                const SizedBox(height: 16),

                // Stats card
                statsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (stats) => _StatsCard(stats: stats, theme: theme),
                ),
                const SizedBox(height: 16),

                // Publish banner (when local changes exist)
                if (hasOverride)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: adminState.isPublishing
                            ? null
                            : () => _showPublishDialog(
                                context, ref, selectedType),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_upload_rounded,
                                size: 22,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unpublished Changes',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.tertiary,
                                      ),
                                    ),
                                    Text(
                                      'Tap to publish ${selectedType.displayName} to server',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: theme.colorScheme.tertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Status bar
                if (adminState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        adminState.error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ),
                if (adminState.lastAction != null && adminState.error == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(adminState.lastAction!)),
                        ],
                      ),
                    ),
                  ),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.edit_note_rounded,
                        label: 'Phrase Templates',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _PhraseEditorPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.history_rounded,
                        label: 'Backups',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const _BackupsPage(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section list
                Text(
                  'Sections',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                treeAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('Failed to load tree: $e'),
                  data: (tree) => Column(
                    children: [
                      for (final section in tree.sections) ...[
                        _SectionTile(section: section),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Publishing overlay — locks the entire screen during upload
        if (adminState.isPublishing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Publishing to Server...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait. Do not close the app.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Show the publish confirmation dialog with safety warnings.
  void _showPublishDialog(
    BuildContext context,
    WidgetRef ref,
    SurveyTreeType selectedType,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 36,
          ),
          title: const Text('Publish Changes?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to publish ${selectedType.displayName} changes to the live server.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '  \u2022 Update live survey forms for ALL users\n'
                      '  \u2022 Take effect immediately\n'
                      '  \u2022 Cannot be undone from this device',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              style: _adminCancelButtonStyle(theme),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final error = await ref
                    .read(treeAdminNotifierProvider.notifier)
                    .publishChanges();
                if (error != null && context.mounted) {
                  showDialog<void>(
                    context: context,
                    builder: (errCtx) {
                      final errTheme = Theme.of(errCtx);
                      return AlertDialog(
                        icon: Icon(
                          Icons.error_outline,
                          color: errTheme.colorScheme.error,
                          size: 36,
                        ),
                        title: const Text('Publish Failed'),
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 320,
                            maxWidth: 400,
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                error,
                                style: errTheme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(errCtx),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${selectedType.displayName} published successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text('Publish Now'),
            ),
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.theme});

  final Map<String, dynamic> stats;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasOverride = stats['hasLocalOverride'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tree Statistics',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (hasOverride)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Modified',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Sections',
                value: '${stats['sections'] ?? 0}',
              ),
              _StatChip(
                label: 'Groups',
                value: '${stats['groups'] ?? 0}',
              ),
              _StatChip(
                label: 'Screens',
                value: '${stats['screens'] ?? 0}',
              ),
              _StatChip(
                label: 'Fields',
                value: '${stats['fields'] ?? 0}',
              ),
              _StatChip(
                label: 'Dropdowns',
                value: '${stats['dropdowns'] ?? 0}',
              ),
              _StatChip(
                label: 'Conditionals',
                value: '${stats['conditionals'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends ConsumerWidget {
  const _SectionTile({required this.section});

  final InspectionSectionDefinition section;

  /// Derive a 1–2 character abbreviation from the section title.
  /// Single-letter keys (inspection sections) are used as-is.
  /// Longer keys derive initials from the title words.
  static String _abbreviation(String key, String title) {
    // Single/double char keys (inspection: D, E, F, …) → use directly
    if (key.length <= 2) return key.toUpperCase();

    // Derive from title: take first letter of each significant word
    final words = title
        .replaceAll(RegExp(r'[&,/]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return key.substring(0, 2).toUpperCase();
    if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
    return words
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  /// Stable icon for each section, with fallback based on title keywords.
  static IconData _sectionIcon(String key, String title) {
    // Inspection sections by key
    switch (key) {
      case 'D': return Icons.home_outlined;
      case 'E': return Icons.roofing_outlined;
      case 'F': return Icons.door_back_door_outlined;
      case 'G': return Icons.electrical_services_outlined;
      case 'H': return Icons.park_outlined;
      case 'I': return Icons.report_problem_outlined;
      case 'J': return Icons.warning_amber_rounded;
      case 'K': return Icons.draw_outlined;
      case 'R': return Icons.meeting_room_outlined;
      case 'O': return Icons.summarize_outlined;
      case 'A': return Icons.assignment_outlined;
    }

    // Valuation sections by key
    switch (key) {
      case 'valuation_details': return Icons.description_outlined;
      case 'property_assessment': return Icons.home_work_outlined;
      case 'property_inspection': return Icons.fact_check_outlined;
      case 'condition_restrictions': return Icons.rule_outlined;
      case 'valuation_completion': return Icons.task_alt_outlined;
    }

    // Fallback: match title keywords
    final lower = title.toLowerCase();
    if (lower.contains('valuation')) return Icons.assessment_outlined;
    if (lower.contains('property')) return Icons.home_work_outlined;
    if (lower.contains('inspection')) return Icons.fact_check_outlined;
    if (lower.contains('condition')) return Icons.rule_outlined;
    return Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups =
        section.nodes.where((n) => n.type == InspectionNodeType.group).length;
    final screens =
        section.nodes.where((n) => n.type == InspectionNodeType.screen).length;
    final fields = section.nodes.fold<int>(
      0,
      (sum, n) => sum + n.fields.length,
    );

    final abbr = _abbreviation(section.key, section.title);
    final icon = _sectionIcon(section.key, section.title);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          ref.read(treeAdminSelectedSectionProvider.notifier).state =
              section.key;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _SectionDetailPage(section: section),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      Text(
                        abbr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$groups groups, $screens screens, $fields fields',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Detail Page ──────────────────────────────────────────

class _SectionDetailPage extends ConsumerWidget {
  const _SectionDetailPage({required this.section});

  final InspectionSectionDefinition section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Get top-level nodes (no parentId or parentId is section-level group)
    final topLevelNodes =
        section.nodes.where((n) => n.parentId == null).toList();
    final childMap = <String, List<InspectionNodeDefinition>>{};
    for (final node in section.nodes) {
      if (node.parentId != null) {
        childMap.putIfAbsent(node.parentId!, () => []).add(node);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('[${section.key}] ${section.title}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNodeSheet(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${section.nodes.length} nodes total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final node in topLevelNodes) ...[
              _NodeTile(
                node: node,
                childMap: childMap,
                allNodes: section.nodes,
                sectionKey: section.key,
                depth: 0,
              ),
              const SizedBox(height: 6),
            ],
            // Bottom padding for FAB
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  void _showAddNodeSheet(BuildContext context, WidgetRef ref) {
    // Build list of possible parent groups
    final groups = section.nodes
        .where((n) => n.type == InspectionNodeType.group)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddNodeSheet(
        sectionKey: section.key,
        groups: groups,
        onSaveScreen: (title, parentId) {
          ref.read(treeAdminNotifierProvider.notifier).addScreen(
                section.key,
                title,
                parentId: parentId,
              );
        },
        onSaveGroup: (title, parentId) {
          ref.read(treeAdminNotifierProvider.notifier).addGroup(
                section.key,
                title,
                parentId: parentId,
              );
        },
      ),
    );
  }
}

class _NodeTile extends ConsumerWidget {
  const _NodeTile({
    required this.node,
    required this.childMap,
    required this.allNodes,
    required this.sectionKey,
    required this.depth,
  });

  final InspectionNodeDefinition node;
  final Map<String, List<InspectionNodeDefinition>> childMap;
  final List<InspectionNodeDefinition> allNodes;
  final String sectionKey;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isGroup = node.type == InspectionNodeType.group;
    final children = childMap[node.id] ?? [];

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: isGroup
                ? theme.colorScheme.secondaryContainer.withOpacity(0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: isGroup
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ScreenEditorPage(screenId: node.id),
                        ),
                      ),
              onLongPress: () => _showNodeMenu(context, ref),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGroup
                        ? theme.colorScheme.secondary.withOpacity(0.3)
                        : theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isGroup
                          ? Icons.folder_outlined
                          : Icons.description_outlined,
                      size: 18,
                      color: isGroup
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isGroup ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (!isGroup)
                            Text(
                              '${node.fields.length} fields',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isGroup)
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (final child in children) ...[
              _NodeTile(
                node: child,
                childMap: childMap,
                allNodes: allNodes,
                sectionKey: sectionKey,
                depth: depth + 1,
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }

  void _showNodeMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                node.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text(
                'Delete Node',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: Text(
                node.type == InspectionNodeType.group
                    ? 'Removes group and all children'
                    : 'Removes this screen',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dlg) => AlertDialog(
                    title: const Text('Delete Node'),
                    content: Text(
                      'Delete "${node.title}" (${node.id})?\n\n'
                      'This will also remove all child nodes.',
                    ),
                    actions: [
                      OutlinedButton(
                        style: _adminCancelButtonStyle(theme),
                        onPressed: () => Navigator.pop(dlg, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(dlg, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref
                      .read(treeAdminNotifierProvider.notifier)
                      .removeNode(sectionKey, node.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen Editor Page ───────────────────────────────────────────

class ScreenEditorPage extends ConsumerWidget {
  const ScreenEditorPage({required this.screenId, super.key});

  final String screenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(treeAdminTreeProvider);
    final adminState = ref.watch(treeAdminNotifierProvider);
    final theme = Theme.of(context);

    return treeAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Screen Editor')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (tree) {
        InspectionNodeDefinition? screen;
        for (final section in tree.sections) {
          for (final node in section.nodes) {
            if (node.id == screenId) {
              screen = node;
              break;
            }
          }
          if (screen != null) break;
        }

        if (screen == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Screen Editor')),
            body: const Center(child: Text('Screen not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(screen.title),
            actions: [
              if (adminState.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddFieldSheet(context, ref, tree, screenId),
            child: const Icon(Icons.add_rounded),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Screen info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${screen.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                      if (screen.parentId != null)
                        Text(
                          'Parent: ${screen.parentId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      if (screen.inlinePosition != null)
                        Text(
                          'Inline: ${screen.inlinePosition}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title editor
                _EditableTitleRow(
                  title: screen.title,
                  onSave: (newTitle) {
                    ref.read(treeAdminNotifierProvider.notifier).updateScreenTitle(
                          screenId,
                          newTitle,
                        );
                  },
                ),
                const SizedBox(height: 16),

                // Fields list
                Text(
                  'Fields (${screen.fields.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < screen.fields.length; i++) ...[
                  _FieldTile(
                    field: screen.fields[i],
                    index: i,
                    screenId: screenId,
                  ),
                  const SizedBox(height: 6),
                ],
                // Bottom padding for FAB
                const SizedBox(height: 72),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddFieldSheet(
    BuildContext context,
    WidgetRef ref,
    InspectionTreePayload tree,
    String screenId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddFieldSheet(
        tree: tree,
        screenId: screenId,
        onSave: (field) {
          ref.read(treeAdminNotifierProvider.notifier).addField(screenId, field);
        },
      ),
    );
  }
}

class _EditableTitleRow extends StatefulWidget {
  const _EditableTitleRow({required this.title, required this.onSave});

  final String title;
  final ValueChanged<String> onSave;

  @override
  State<_EditableTitleRow> createState() => _EditableTitleRowState();
}

class _EditableTitleRowState extends State<_EditableTitleRow> {
  bool _editing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_editing) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Title: ${widget.title}',
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => setState(() => _editing = true),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            decoration: _adminInputDecoration(theme, labelText: 'Screen Title'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check_rounded, size: 20),
          onPressed: () {
            widget.onSave(_controller.text.trim());
            setState(() => _editing = false);
          },
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () {
            _controller.text = widget.title;
            setState(() => _editing = false);
          },
        ),
      ],
    );
  }
}

class _FieldTile extends ConsumerWidget {
  const _FieldTile({
    required this.field,
    required this.index,
    required this.screenId,
  });

  final InspectionFieldDefinition field;
  final int index;
  final String screenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typeColor = switch (field.type) {
      InspectionFieldType.checkbox => const Color(0xFF00796B),
      InspectionFieldType.dropdown => const Color(0xFF1565C0),
      InspectionFieldType.text => theme.colorScheme.primary,
      InspectionFieldType.number => const Color(0xFFE65100),
      InspectionFieldType.label => theme.colorScheme.secondary,
    };

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _showFieldEditor(context, ref),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  field.type.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      field.id,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                    if (field.conditionalOn != null)
                      Text(
                        'if: ${field.conditionalOn}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontSize: 10,
                        ),
                      ),
                    if (field.type == InspectionFieldType.dropdown &&
                        field.options != null)
                      Text(
                        '${field.options!.length} options',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1565C0),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFieldEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FieldEditorSheet(
        field: field,
        screenId: screenId,
        onSaveLabel: (newLabel) {
          ref.read(treeAdminNotifierProvider.notifier).updateFieldLabel(
                screenId,
                field.id,
                newLabel,
              );
        },
        onSaveOptions: (options) {
          ref.read(treeAdminNotifierProvider.notifier).updateDropdownOptions(
                screenId,
                field.id,
                options,
              );
        },
        onSaveCondition: (on, value, mode) {
          ref.read(treeAdminNotifierProvider.notifier).updateConditionalRule(
                screenId,
                field.id,
                conditionalOn: on,
                conditionalValue: value,
                conditionalMode: mode,
              );
        },
        onSavePhraseTemplate: (template) {
          ref
              .read(treeAdminNotifierProvider.notifier)
              .updateFieldPhraseTemplate(screenId, field.id, template);
        },
        onDelete: () {
          ref.read(treeAdminNotifierProvider.notifier).removeField(
                screenId,
                field.id,
              );
        },
      ),
    );
  }
}

// ─── Add Node Sheet ───────────────────────────────────────────────

class _AddNodeSheet extends StatefulWidget {
  const _AddNodeSheet({
    required this.sectionKey,
    required this.groups,
    required this.onSaveScreen,
    required this.onSaveGroup,
  });

  final String sectionKey;
  final List<InspectionNodeDefinition> groups;
  final void Function(String title, String? parentId) onSaveScreen;
  final void Function(String title, String? parentId) onSaveGroup;

  @override
  State<_AddNodeSheet> createState() => _AddNodeSheetState();
}

class _AddNodeSheetState extends State<_AddNodeSheet> {
  final _titleController = TextEditingController();
  bool _isGroup = false;
  String? _selectedParentId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New Node',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Node type toggle
            Text(
              'Node Type',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Screen'),
                  icon: Icon(Icons.description_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Group'),
                  icon: Icon(Icons.folder_outlined),
                ),
              ],
              selected: {_isGroup},
              onSelectionChanged: (selected) {
                setState(() => _isGroup = selected.first);
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: _adminInputDecoration(
                theme,
                labelText: _isGroup ? 'Group Title' : 'Screen Title',
                hintText: _isGroup ? 'e.g. New Category' : 'e.g. New Inspection Screen',
              ),
            ),
            const SizedBox(height: 16),

            // Parent selector
            Text(
              'Parent Group (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedParentId,
              decoration: _adminInputDecoration(
                theme,
                hintText: 'Top level (no parent)',
              ),
              dropdownColor: theme.colorScheme.surfaceContainerLowest,
              style: TextStyle(color: theme.colorScheme.onSurface),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Top level (no parent)'),
                ),
                ...widget.groups.map(
                  (g) => DropdownMenuItem<String?>(
                    value: g.id,
                    child: Text(
                      g.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedParentId = value);
              },
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: _adminCancelButtonStyle(theme),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: _adminPrimaryButtonStyle(theme),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;

                    if (_isGroup) {
                      widget.onSaveGroup(title, _selectedParentId);
                    } else {
                      widget.onSaveScreen(title, _selectedParentId);
                    }
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(_isGroup ? 'Add Group' : 'Add Screen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Field Sheet ──────────────────────────────────────────────

class _AddFieldSheet extends StatefulWidget {
  const _AddFieldSheet({
    required this.tree,
    required this.screenId,
    required this.onSave,
  });

  final InspectionTreePayload tree;
  final String screenId;
  final ValueChanged<InspectionFieldDefinition> onSave;

  @override
  State<_AddFieldSheet> createState() => _AddFieldSheetState();
}

class _AddFieldSheetState extends State<_AddFieldSheet> {
  final _labelController = TextEditingController();
  final _optionsController = TextEditingController();
  final _phraseTemplateController = TextEditingController();
  InspectionFieldType _selectedType = InspectionFieldType.text;
  String? _generatedId;
  bool _showPhraseTemplate = false;

  @override
  void dispose() {
    _labelController.dispose();
    _optionsController.dispose();
    _phraseTemplateController.dispose();
    super.dispose();
  }

  void _updateGeneratedId() {
    if (_labelController.text.trim().isEmpty) {
      setState(() => _generatedId = null);
      return;
    }
    final repo = TreeAdminRepository();
    final id = repo.generateUniqueFieldId(
      widget.tree,
      widget.screenId,
      _selectedType,
      _labelController.text.trim(),
    );
    setState(() => _generatedId = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDropdown = _selectedType == InspectionFieldType.dropdown;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New Field',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Field Type selector
            Text(
              'Field Type',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: InspectionFieldType.values.map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  label: Text(
                    type.name,
                    style: TextStyle(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: selected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  side: BorderSide(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedType = type);
                    _updateGeneratedId();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Label
            TextField(
              controller: _labelController,
              decoration: _adminInputDecoration(
                theme,
                labelText: 'Field Label',
                hintText: 'e.g. Condition Rating',
              ),
              onChanged: (_) => _updateGeneratedId(),
            ),
            const SizedBox(height: 8),

            // Auto-generated ID preview
            if (_generatedId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID: $_generatedId',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Dropdown options (only when dropdown is selected)
            if (isDropdown) ...[
              Text(
                'Dropdown Options (one per line)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _optionsController,
                maxLines: 6,
                decoration: _adminInputDecoration(
                  theme,
                  hintText: 'Option 1\nOption 2\nOption 3',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Phrase Template (collapsible)
            if (_selectedType != InspectionFieldType.label) ...[
              InkWell(
                onTap: () {
                  setState(() => _showPhraseTemplate = !_showPhraseTemplate);
                  // Auto-fill with {field_id} when first expanded and empty
                  if (_showPhraseTemplate &&
                      _phraseTemplateController.text.isEmpty &&
                      _generatedId != null) {
                    _phraseTemplateController.text = '{$_generatedId}';
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showPhraseTemplate
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Phrase Template',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(optional)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showPhraseTemplate) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _phraseTemplateController,
                  maxLines: 4,
                  decoration: _adminInputDecoration(
                    theme,
                    hintText:
                        'e.g. The {field_id} was observed to be in {condition_rating} condition.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 4),
                if (_generatedId != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                      label: Text(
                        'Insert {$_generatedId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
                      onPressed: () {
                        final tag = '{$_generatedId}';
                        final text = _phraseTemplateController.text;
                        final sel = _phraseTemplateController.selection;
                        if (sel.isValid && sel.baseOffset >= 0 && sel.baseOffset <= text.length) {
                          final before = text.substring(0, sel.baseOffset);
                          final after = text.substring(sel.extentOffset);
                          final newText = '$before$tag$after';
                          _phraseTemplateController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: sel.baseOffset + tag.length,
                            ),
                          );
                        } else {
                          _phraseTemplateController.text = '$text$tag';
                          _phraseTemplateController.selection = TextSelection.collapsed(
                            offset: _phraseTemplateController.text.length,
                          );
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Use {field_id} placeholders for answer substitution.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: _adminCancelButtonStyle(theme),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: _adminPrimaryButtonStyle(theme),
                  onPressed: () {
                    final label = _labelController.text.trim();
                    if (label.isEmpty) return;

                    final repo = TreeAdminRepository();
                    final id = repo.generateUniqueFieldId(
                      widget.tree,
                      widget.screenId,
                      _selectedType,
                      label,
                    );

                    List<String>? options;
                    if (isDropdown) {
                      options = _optionsController.text
                          .split('\n')
                          .map((o) => o.trim())
                          .where((o) => o.isNotEmpty)
                          .toList();
                      if (options.isEmpty) options = null;
                    }

                    final phraseTemplate =
                        _phraseTemplateController.text.trim().isEmpty
                            ? null
                            : _phraseTemplateController.text.trim();

                    final field = InspectionFieldDefinition(
                      id: id,
                      label: label,
                      type: _selectedType,
                      options: options,
                      phraseTemplate: phraseTemplate,
                    );
                    widget.onSave(field);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Field'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldEditorSheet extends StatefulWidget {
  const _FieldEditorSheet({
    required this.field,
    required this.screenId,
    required this.onSaveLabel,
    required this.onSaveOptions,
    required this.onSaveCondition,
    required this.onSavePhraseTemplate,
    required this.onDelete,
  });

  final InspectionFieldDefinition field;
  final String screenId;
  final ValueChanged<String> onSaveLabel;
  final ValueChanged<List<String>> onSaveOptions;
  final void Function(String?, String?, String?) onSaveCondition;
  final ValueChanged<String?> onSavePhraseTemplate;
  final VoidCallback onDelete;

  @override
  State<_FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<_FieldEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _optionsController;
  late final TextEditingController _condOnController;
  late final TextEditingController _condValueController;
  late final TextEditingController _condModeController;
  late final TextEditingController _phraseTemplateController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _optionsController = TextEditingController(
      text: widget.field.options?.join('\n') ?? '',
    );
    _condOnController =
        TextEditingController(text: widget.field.conditionalOn ?? '');
    _condValueController =
        TextEditingController(text: widget.field.conditionalValue ?? '');
    _condModeController =
        TextEditingController(text: widget.field.conditionalMode ?? 'show');
    _phraseTemplateController = TextEditingController(
      text: (widget.field.phraseTemplate ?? '').isEmpty
          ? '{${widget.field.id}}'
          : widget.field.phraseTemplate!,
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _optionsController.dispose();
    _condOnController.dispose();
    _condValueController.dispose();
    _condModeController.dispose();
    _phraseTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Edit Field',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.field.type.name} | ${widget.field.id}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),

            // Label
            TextField(
              controller: _labelController,
              decoration: _adminInputDecoration(theme, labelText: 'Label'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  widget.onSaveLabel(_labelController.text.trim());
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save Label'),
              ),
            ),
            const Divider(),

            // Dropdown options (if dropdown)
            if (widget.field.type == InspectionFieldType.dropdown) ...[
              Text(
                'Dropdown Options (one per line)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _optionsController,
                maxLines: 6,
                decoration: _adminInputDecoration(
                  theme,
                  hintText: 'Option 1\nOption 2\nOption 3',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final options = _optionsController.text
                        .split('\n')
                        .map((o) => o.trim())
                        .where((o) => o.isNotEmpty)
                        .toList();
                    widget.onSaveOptions(options);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Options'),
                ),
              ),
              const Divider(),
            ],

            // Conditional rules
            Text(
              'Conditional Visibility',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _condOnController,
              decoration: _adminInputDecoration(
                theme,
                labelText: 'conditionalOn (field ID or expression)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _condValueController,
              decoration: _adminInputDecoration(
                theme,
                labelText: 'conditionalValue',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _condModeController,
              decoration: _adminInputDecoration(
                theme,
                labelText: 'conditionalMode (show/hide)',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  final on = _condOnController.text.trim();
                  final val = _condValueController.text.trim();
                  final mode = _condModeController.text.trim();
                  widget.onSaveCondition(
                    on.isEmpty ? null : on,
                    val.isEmpty ? null : val,
                    mode.isEmpty ? null : mode,
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save Condition'),
              ),
            ),
            const Divider(),

            // Phrase Template
            if (widget.field.type != InspectionFieldType.label) ...[
              Text(
                'Phrase Template',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use {field_id} placeholders for answer substitution.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phraseTemplateController,
                maxLines: 4,
                decoration: _adminInputDecoration(
                  theme,
                  hintText:
                      'e.g. The {field_id} was observed to be in {condition_rating} condition.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                  label: Text(
                    'Insert {${widget.field.id}}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
                  onPressed: () {
                    final tag = '{${widget.field.id}}';
                    final text = _phraseTemplateController.text;
                    final sel = _phraseTemplateController.selection;
                    // Insert at cursor if valid, otherwise append
                    if (sel.isValid && sel.baseOffset >= 0 && sel.baseOffset <= text.length) {
                      final before = text.substring(0, sel.baseOffset);
                      final after = text.substring(sel.extentOffset);
                      final newText = '$before$tag$after';
                      _phraseTemplateController.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: sel.baseOffset + tag.length,
                        ),
                      );
                    } else {
                      _phraseTemplateController.text = '$text$tag';
                      _phraseTemplateController.selection = TextSelection.collapsed(
                        offset: _phraseTemplateController.text.length,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    final template =
                        _phraseTemplateController.text.trim().isEmpty
                            ? null
                            : _phraseTemplateController.text.trim();
                    widget.onSavePhraseTemplate(template);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Phrase'),
                ),
              ),
              const Divider(),
            ],

            // Delete field
            Center(
              child: TextButton.icon(
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  'Remove Field',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Phrase Editor Page ───────────────────────────────────────────

class _PhraseEditorPage extends ConsumerWidget {
  const _PhraseEditorPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phraseTextsAsync = ref.watch(treeAdminPhraseTextsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrase Templates'),
      ),
      body: phraseTextsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (texts) {
          final keys = texts.keys.toList()..sort();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final key = keys[index];
              final value = texts[key] ?? '';

              return Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _editPhrase(context, ref, key, value),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            theme.colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value.length > 120
                              ? '${value.substring(0, 120)}...'
                              : value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editPhrase(
    BuildContext context,
    WidgetRef ref,
    String key,
    String value,
  ) {
    final controller = TextEditingController(text: value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                key,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: _adminInputDecoration(
                  theme,
                  labelText: 'Template text',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: _adminCancelButtonStyle(theme),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: _adminPrimaryButtonStyle(theme),
                    onPressed: () {
                      ref
                          .read(treeAdminNotifierProvider.notifier)
                          .updatePhraseTemplate(
                            key,
                            controller.text,
                          );
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    // Dispose controller when sheet closes
  }
}

// ─── Backups Page ─────────────────────────────────────────────────

class _BackupsPage extends ConsumerWidget {
  const _BackupsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupsAsync = ref.watch(treeAdminBackupsProvider);
    final selectedType = ref.watch(treeAdminSelectedTreeTypeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${selectedType.displayName} Backups'),
      ),
      body: backupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (backups) {
          if (backups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No backups yet. Backups are created automatically when you edit the tree.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: backups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final backup = backups[index];
              final name = backup.path.split('/').last.split('\\').last;

              return ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.restore_rounded),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Restore Backup'),
                        content: Text('Restore from $name?'),
                        actions: [
                          OutlinedButton(
                            style: _adminCancelButtonStyle(theme),
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(treeAdminNotifierProvider.notifier)
                          .restoreBackup(backup);
                    }
                  },
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
