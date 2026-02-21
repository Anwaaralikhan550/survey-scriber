import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/webhook.dart';
import '../providers/webhooks_provider.dart';

class WebhooksListPage extends ConsumerStatefulWidget {
  const WebhooksListPage({super.key});

  @override
  ConsumerState<WebhooksListPage> createState() => _WebhooksListPageState();
}

class _WebhooksListPageState extends ConsumerState<WebhooksListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webhooksProvider.notifier).loadWebhooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(webhooksProvider);

    // Listen for errors
    ref.listen<WebhooksState>(webhooksProvider, (previous, next) {
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
        title: const Text('Webhooks'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isSaving)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.adminWebhooksCreate),
        icon: const Icon(Icons.add),
        label: const Text('Add Webhook'),
        shape: const StadiumBorder(),
      ),
      body: _buildBody(state, theme, colorScheme),
    );
  }

  Widget _buildBody(WebhooksState state, ThemeData theme, ColorScheme colorScheme) {
    if (state.isLoading && state.webhooks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.webhooks.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(webhooksProvider.notifier).loadWebhooks(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Warning card for advanced feature
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: colorScheme.tertiary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.tertiary,
                  size: 20,
                ),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    'Webhooks send real-time HTTP notifications to your specified URL when events occur.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Row(
            children: [
              _StatChip(
                label: 'Active',
                count: state.activeCount,
                color: colorScheme.primary,
              ),
              AppSpacing.gapHorizontalSm,
              _StatChip(
                label: 'Inactive',
                count: state.inactiveCount,
                color: colorScheme.outline,
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,

          // Webhooks list
          ...state.webhooks.map(
            (webhook) => _WebhookCard(
              webhook: webhook,
              onTap: () => context.push(Routes.webhookDetailPath(webhook.id)),
              onToggle: () => _confirmToggle(webhook),
            ),
          ),

          // Bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.webhook_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            AppSpacing.gapVerticalLg,
            Text(
              'No Webhooks Configured',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'Add a webhook to receive real-time notifications when events occur in your system.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLg,
            FilledButton.icon(
              onPressed: () => context.push(Routes.adminWebhooksCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Webhook'),
            ),
          ],
        ),
      ),
    );

  Future<void> _confirmToggle(Webhook webhook) async {
    final action = webhook.isActive ? 'Disable' : 'Enable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Webhook'),
        content: Text(
          webhook.isActive
              ? 'This webhook will stop receiving events. You can re-enable it later.'
              : 'This webhook will start receiving events again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: webhook.isActive
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
      final success = await ref.read(webhooksProvider.notifier).updateWebhook(
            webhook.id,
            isActive: !webhook.isActive,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Webhook ${webhook.isActive ? 'disabled' : 'enabled'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          AppSpacing.gapHorizontalXs,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebhookCard extends StatelessWidget {
  const _WebhookCard({
    required this.webhook,
    required this.onTap,
    required this.onToggle,
  });

  final Webhook webhook;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: webhook.isActive
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: webhook.isActive
                            ? Colors.green
                            : colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.gapHorizontalSm,
                    Expanded(
                      child: Text(
                        webhook.url,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: webhook.isActive
                              ? null
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) {
                        if (value == 'toggle') onToggle();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                webhook.isActive
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 20,
                              ),
                              AppSpacing.gapHorizontalSm,
                              Text(webhook.isActive ? 'Disable' : 'Enable'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AppSpacing.gapVerticalSm,
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: webhook.events.map((event) {
                    final eventType = WebhookEventType.fromValue(event);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        eventType?.displayName ?? event,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (!webhook.isActive) ...[
                  AppSpacing.gapVerticalSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Disabled',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
