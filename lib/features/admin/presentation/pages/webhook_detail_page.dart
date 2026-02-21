import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../data/datasources/webhooks_datasource.dart';
import '../../domain/entities/webhook.dart';
import '../providers/webhooks_provider.dart';

class WebhookDetailPage extends ConsumerStatefulWidget {
  const WebhookDetailPage({
    super.key,
    required this.webhookId,
  });

  final String webhookId;

  @override
  ConsumerState<WebhookDetailPage> createState() => _WebhookDetailPageState();
}

class _WebhookDetailPageState extends ConsumerState<WebhookDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webhookDetailProvider.notifier).loadWebhook(widget.webhookId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(webhookDetailProvider);

    // Listen for errors
    ref.listen<WebhookDetailState>(webhookDetailProvider, (previous, next) {
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
        title: const Text('Webhook Details'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.webhook != null) ...[
            // Visible Edit button for better discoverability
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showEditDialog(state.webhook!),
              tooltip: 'Edit Webhook',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) => _handleMenuAction(value, state.webhook!),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      AppSpacing.gapHorizontalSm,
                      Text('Edit Webhook'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        state.webhook!.isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      AppSpacing.gapHorizontalSm,
                      Text(state.webhook!.isActive ? 'Disable' : 'Enable'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: state.webhook != null
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Deliveries'),
                ],
              )
            : null,
      ),
      body: _buildBody(state, theme, colorScheme),
    );
  }

  Widget _buildBody(
    WebhookDetailState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.webhook == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.webhook == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'Webhook not found',
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalSm,
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _OverviewTab(
          webhook: state.webhook!,
          isSendingTest: state.isSendingTest,
          testResult: state.testResult,
          onSendTest: _showTestEventDialog,
        ),
        _DeliveriesTab(
          deliveries: state.deliveries,
          isLoading: state.isLoadingDeliveries,
          hasMore: state.hasMoreDeliveries,
          onLoadMore: () =>
              ref.read(webhookDetailProvider.notifier).loadMoreDeliveries(),
          onRefresh: () => ref
              .read(webhookDetailProvider.notifier)
              .loadDeliveries(widget.webhookId),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Webhook webhook) {
    switch (action) {
      case 'edit':
        _showEditDialog(webhook);
        break;
      case 'toggle':
        _confirmToggle(webhook);
        break;
    }
  }

  void _showEditDialog(Webhook webhook) {
    final urlController = TextEditingController(text: webhook.url);
    final selectedEvents = List<String>.from(webhook.events);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            title: const Text('Edit Webhook'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // URL field
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'Endpoint URL',
                      hintText: 'https://example.com/webhook',
                      prefixIcon: const Icon(Icons.link_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  AppSpacing.gapVerticalLg,
                  Text(
                    'Subscribed Events',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.gapVerticalSm,
                  // Events selection
                  ...WebhookEventType.values.map((eventType) {
                    final isSelected =
                        selectedEvents.contains(eventType.value);
                    return CheckboxListTile(
                      title: Text(eventType.displayName),
                      subtitle: Text(
                        eventType.value,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: isSelected,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedEvents.add(eventType.value);
                          } else {
                            selectedEvents.remove(eventType.value);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedEvents.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        final success = await ref
                            .read(webhooksProvider.notifier)
                            .updateWebhook(
                              webhook.id,
                              url: urlController.text,
                              events: selectedEvents,
                            );

                        if (success && mounted) {
                          ref
                              .read(webhookDetailProvider.notifier)
                              .loadWebhook(widget.webhookId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Webhook updated'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

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
        // Reload detail
        ref.read(webhookDetailProvider.notifier).loadWebhook(widget.webhookId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Webhook ${webhook.isActive ? 'disabled' : 'enabled'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTestEventDialog() {
    final webhook = ref.read(webhookDetailProvider).webhook;
    if (webhook == null) return;

    showDialog(
      context: context,
      builder: (context) => _TestEventDialog(
        events: webhook.events,
        onSend: (eventType) async {
          Navigator.pop(context);
          final success = await ref
              .read(webhookDetailProvider.notifier)
              .sendTestEvent(eventType);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Test event sent successfully'
                      : 'Failed to send test event',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: success ? Colors.green : null,
              ),
            );
          }
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.webhook,
    required this.isSendingTest,
    required this.testResult,
    required this.onSendTest,
  });

  final Webhook webhook;
  final bool isSendingTest;
  final TestEventResult? testResult;
  final VoidCallback onSendTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Status Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: webhook.isActive ? Colors.green : colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    webhook.isActive ? 'Active' : 'Inactive',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: webhook.isActive ? Colors.green : colorScheme.outline,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalMd,
              _DetailRow(
                label: 'Endpoint',
                value: webhook.url,
                isMonospace: true,
              ),
              AppSpacing.gapVerticalSm,
              _DetailRow(
                label: 'Created',
                value: dateFormat.format(webhook.createdAt),
              ),
              AppSpacing.gapVerticalSm,
              _DetailRow(
                label: 'Last Updated',
                value: dateFormat.format(webhook.updatedAt),
              ),
            ],
          ),
        ),

        AppSpacing.gapVerticalMd,

        // Events Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subscribed Events',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.gapVerticalMd,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: webhook.events.map((event) {
                  final eventType = WebhookEventType.fromValue(event);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      eventType?.displayName ?? event,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        AppSpacing.gapVerticalMd,

        // Test Event Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'Test Webhook',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalSm,
              Text(
                'Send a test event to verify your webhook is configured correctly.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapVerticalMd,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: webhook.isActive && !isSendingTest ? onSendTest : null,
                  icon: isSendingTest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(isSendingTest ? 'Sending...' : 'Send Test Event'),
                ),
              ),
              if (testResult != null) ...[
                AppSpacing.gapVerticalSm,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: testResult!.success
                        ? Colors.green.withOpacity(0.1)
                        : colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        testResult!.success
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 16,
                        color: testResult!.success ? Colors.green : colorScheme.error,
                      ),
                      AppSpacing.gapHorizontalSm,
                      Expanded(
                        child: Text(
                          testResult!.success
                              ? 'Test event delivered successfully'
                              : 'Test event delivery failed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: testResult!.success
                                ? Colors.green
                                : colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.gapVerticalXs,
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _DeliveriesTab extends StatelessWidget {
  const _DeliveriesTab({
    required this.deliveries,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final List<WebhookDelivery> deliveries;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (deliveries.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: colorScheme.outline,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'No Deliveries Yet',
              style: theme.textTheme.titleMedium,
            ),
            AppSpacing.gapVerticalXs,
            Text(
              'Delivery logs will appear here when events are sent.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: deliveries.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == deliveries.length) {
            // Load more button
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: onLoadMore,
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final delivery = deliveries[index];
          return _DeliveryCard(delivery: delivery);
        },
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final WebhookDelivery delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd().add_jm();

    final isSuccess = delivery.status == WebhookDeliveryStatus.success;
    final eventType = WebhookEventType.fromValue(delivery.event);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSuccess
                ? Colors.green.withOpacity(0.1)
                : colorScheme.errorContainer.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSuccess ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: isSuccess ? Colors.green : colorScheme.error,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                eventType?.displayName ?? delivery.event,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (delivery.isTest)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TEST',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          dateFormat.format(delivery.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Status Code',
                  value: delivery.responseStatusCode?.toString() ?? 'N/A',
                ),
                if (delivery.attempts > 1)
                  _InfoRow(
                    label: 'Attempts',
                    value: delivery.attempts.toString(),
                  ),
                if (delivery.lastError != null)
                  _InfoRow(
                    label: 'Error',
                    value: delivery.lastError!,
                    isError: true,
                  ),
                if (delivery.responseBody != null &&
                    delivery.responseBody!.isNotEmpty)
                  _InfoRow(
                    label: 'Response',
                    value: delivery.responseBody!,
                    isCode: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isError = false,
    this.isCode = false,
  });

  final String label;
  final String value;
  final bool isError;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError ? colorScheme.error : null,
                fontFamily: isCode ? 'monospace' : null,
                fontSize: isCode ? 11 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestEventDialog extends StatefulWidget {
  const _TestEventDialog({
    required this.events,
    required this.onSend,
  });

  final List<String> events;
  final void Function(String eventType) onSend;

  @override
  State<_TestEventDialog> createState() => _TestEventDialogState();
}

class _TestEventDialogState extends State<_TestEventDialog> {
  String? _selectedEvent;

  @override
  void initState() {
    super.initState();
    if (widget.events.isNotEmpty) {
      _selectedEvent = widget.events.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Send Test Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select an event type to send:',
            style: theme.textTheme.bodyMedium,
          ),
          AppSpacing.gapVerticalMd,
          ...widget.events.map((event) {
            final eventType = WebhookEventType.fromValue(event);
            return RadioListTile<String>(
              title: Text(eventType?.displayName ?? event),
              subtitle: Text(
                event,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              value: event,
              groupValue: _selectedEvent,
              onChanged: (value) => setState(() => _selectedEvent = value),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedEvent != null
              ? () => widget.onSend(_selectedEvent!)
              : null,
          child: const Text('Send'),
        ),
      ],
    );
  }
}
