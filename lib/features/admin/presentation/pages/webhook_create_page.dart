import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/webhook.dart';
import '../providers/webhooks_provider.dart';

class WebhookCreatePage extends ConsumerStatefulWidget {
  const WebhookCreatePage({super.key});

  @override
  ConsumerState<WebhookCreatePage> createState() => _WebhookCreatePageState();
}

class _WebhookCreatePageState extends ConsumerState<WebhookCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final Set<String> _selectedEvents = {};
  bool _showSecret = false;

  @override
  void dispose() {
    _urlController.dispose();
    // Clear any lingering secret from state when navigating away
    // This ensures secrets don't persist in memory after leaving the page
    ref.read(webhooksProvider.notifier).clearLastCreated();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(webhooksProvider);

    // Listen for successful creation
    ref.listen<WebhooksState>(webhooksProvider, (previous, next) {
      if (next.lastCreatedWebhook != null &&
          previous?.lastCreatedWebhook != next.lastCreatedWebhook) {
        setState(() => _showSecret = true);
      }
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

    // Show secret dialog after creation
    if (_showSecret && state.lastCreatedWebhook?.secret != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSecretDialog(state.lastCreatedWebhook!);
      });
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Create Webhook'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
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
            )
          else
            TextButton(
              onPressed: _selectedEvents.isEmpty ? null : _createWebhook,
              child: const Text('Create'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // URL Field
            Text(
              'Endpoint URL',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapVerticalSm,
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://your-server.com/webhook',
                prefixIcon: const Icon(Icons.link_rounded),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: const OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide(color: colorScheme.error),
                ),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'URL is required';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return 'Please enter a valid URL';
                }
                if (uri.scheme != 'https' && uri.scheme != 'http') {
                  return 'URL must use HTTP or HTTPS';
                }
                return null;
              },
            ),
            AppSpacing.gapVerticalXs,
            Text(
              'We\'ll send POST requests to this URL when events occur.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            AppSpacing.gapVerticalLg,

            // Events Selection
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Events to Subscribe',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedEvents.length ==
                          WebhookEventType.values.length) {
                        _selectedEvents.clear();
                      } else {
                        _selectedEvents.addAll(
                          WebhookEventType.values.map((e) => e.value),
                        );
                      }
                    });
                  },
                  child: Text(
                    _selectedEvents.length == WebhookEventType.values.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,

            // Event categories
            _buildEventCategory(
              theme,
              colorScheme,
              'Bookings',
              Icons.calendar_today_rounded,
              [
                WebhookEventType.bookingCreated,
                WebhookEventType.bookingUpdated,
                WebhookEventType.bookingCancelled,
              ],
            ),
            AppSpacing.gapVerticalSm,
            _buildEventCategory(
              theme,
              colorScheme,
              'Booking Requests & Changes',
              Icons.pending_actions_rounded,
              [
                WebhookEventType.bookingRequestCreated,
                WebhookEventType.bookingRequestApproved,
                WebhookEventType.bookingChangeApproved,
              ],
            ),
            AppSpacing.gapVerticalSm,
            _buildEventCategory(
              theme,
              colorScheme,
              'Invoices',
              Icons.receipt_long_rounded,
              [
                WebhookEventType.invoiceIssued,
                WebhookEventType.invoicePaid,
              ],
            ),
            AppSpacing.gapVerticalSm,
            _buildEventCategory(
              theme,
              colorScheme,
              'Reports',
              Icons.description_rounded,
              [
                WebhookEventType.reportApproved,
              ],
            ),

            AppSpacing.gapVerticalLg,

            // Security Note
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: colorScheme.tertiary.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: colorScheme.tertiary,
                    size: 20,
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Webhook Security',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.gapVerticalXs,
                        Text(
                          'A signing secret will be generated when you create this webhook. Use it to verify that requests are coming from us.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCategory(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
    List<WebhookEventType> events,
  ) {
    final allSelected = events.every((e) => _selectedEvents.contains(e.value));
    final someSelected = events.any((e) => _selectedEvents.contains(e.value));

    return DecoratedBox(
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
          // Category header
          InkWell(
            onTap: () {
              setState(() {
                if (allSelected) {
                  for (final event in events) {
                    _selectedEvents.remove(event.value);
                  }
                } else {
                  for (final event in events) {
                    _selectedEvents.add(event.value);
                  }
                }
              });
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colorScheme.primary),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (_) {
                      setState(() {
                        if (allSelected) {
                          for (final event in events) {
                            _selectedEvents.remove(event.value);
                          }
                        } else {
                          for (final event in events) {
                            _selectedEvents.add(event.value);
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          // Event items
          ...events.map((event) => _buildEventItem(theme, colorScheme, event)),
        ],
      ),
    );
  }

  Widget _buildEventItem(
    ThemeData theme,
    ColorScheme colorScheme,
    WebhookEventType event,
  ) {
    final isSelected = _selectedEvents.contains(event.value);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedEvents.remove(event.value);
          } else {
            _selectedEvents.add(event.value);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            AppSpacing.gapHorizontalLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.displayName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    event.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (_) {
                setState(() {
                  if (isSelected) {
                    _selectedEvents.remove(event.value);
                  } else {
                    _selectedEvents.add(event.value);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createWebhook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one event'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(webhooksProvider.notifier).createWebhook(
          url: _urlController.text.trim(),
          events: _selectedEvents.toList(),
        );
  }

  void _showSecretDialog(Webhook webhook) {
    setState(() => _showSecret = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SecretDialog(
        secret: webhook.secret!,
        onDone: () {
          ref.read(webhooksProvider.notifier).clearLastCreated();
          Navigator.pop(context);
          context.pop();
        },
      ),
    );
  }
}

class _SecretDialog extends StatefulWidget {
  const _SecretDialog({
    required this.secret,
    required this.onDone,
  });

  final String secret;
  final VoidCallback onDone;

  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  bool _copied = false;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.green,
          size: 32,
        ),
      ),
      title: const Text('Webhook Created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your webhook has been created successfully. Save the signing secret below - you won\'t be able to see it again.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapVerticalMd,
          Text(
            'Signing Secret',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalXs,
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _revealed ? widget.secret : '••••••••••••••••••••••••',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _revealed
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _revealed = !_revealed),
                  tooltip: _revealed ? 'Hide' : 'Reveal',
                ),
                IconButton(
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 20,
                    color: _copied ? Colors.green : null,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.secret));
                    setState(() => _copied = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          AppSpacing.gapVerticalSm,
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colorScheme.error,
                ),
                AppSpacing.gapHorizontalXs,
                Expanded(
                  child: Text(
                    'This secret will not be shown again',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: widget.onDone,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
