import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';

class AutomationGuidePage extends StatelessWidget {
  const AutomationGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Automation Guide'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.15),
                  Colors.deepOrange.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automate Your Workflow',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.gapVerticalXs,
                      Text(
                        'Connect Scriber to 5,000+ apps using webhooks with platforms like Zapier and Make.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.gapVerticalLg,

          // Quick Start
          Text(
            'Quick Start',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalSm,

          _StepCard(
            number: 1,
            title: 'Create a Webhook',
            description:
                'Set up a webhook endpoint in Scriber to send events to your automation platform.',
            action: FilledButton.icon(
              onPressed: () => context.push(Routes.adminWebhooksCreate),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Webhook'),
            ),
          ),

          const _StepCard(
            number: 2,
            title: 'Get Your Webhook URL',
            description:
                'Copy the webhook URL from your automation platform (Zapier or Make) to use in Scriber.',
            action: null,
          ),

          const _StepCard(
            number: 3,
            title: 'Verify with Test Event',
            description:
                'Send a test event from Scriber to verify your connection is working.',
            action: null,
          ),

          AppSpacing.gapVerticalLg,

          // Platform Guides
          Text(
            'Platform Guides',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalSm,

          const _PlatformGuide(
            name: 'Zapier',
            iconColor: Colors.orange,
            steps: [
              'Create a new Zap and choose "Webhooks by Zapier" as the trigger',
              'Select "Catch Hook" as the trigger event',
              'Copy the webhook URL provided by Zapier',
              'Create a webhook in Scriber with that URL',
              'Send a test event from Scriber to complete setup',
              'Add your desired actions (Gmail, Slack, Sheets, etc.)',
            ],
          ),

          AppSpacing.gapVerticalMd,

          const _PlatformGuide(
            name: 'Make (Integromat)',
            iconColor: Colors.purple,
            steps: [
              'Create a new scenario in Make',
              'Add a "Webhooks" module as the trigger',
              'Select "Custom webhook" and create a new webhook',
              'Copy the webhook URL provided by Make',
              'Create a webhook in Scriber with that URL',
              'Send a test event and run the scenario once to parse data',
              'Add your desired action modules',
            ],
          ),

          AppSpacing.gapVerticalLg,

          // Event Types Reference
          Text(
            'Available Events',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalSm,

          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                const _EventTypeRow(
                  category: 'Bookings',
                  events: [
                    ('BOOKING_CREATED', 'When a new booking is created'),
                    ('BOOKING_UPDATED', 'When a booking is modified'),
                    ('BOOKING_CANCELLED', 'When a booking is cancelled'),
                  ],
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
                const _EventTypeRow(
                  category: 'Booking Requests',
                  events: [
                    ('BOOKING_REQUEST_CREATED', 'When a client submits a request'),
                    ('BOOKING_REQUEST_APPROVED', 'When a request is approved'),
                    ('BOOKING_REQUEST_REJECTED', 'When a request is rejected'),
                  ],
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
                const _EventTypeRow(
                  category: 'Invoices',
                  events: [
                    ('INVOICE_CREATED', 'When an invoice is generated'),
                    ('INVOICE_PAID', 'When payment is received'),
                    ('INVOICE_OVERDUE', 'When payment is overdue'),
                  ],
                ),
              ],
            ),
          ),

          AppSpacing.gapVerticalLg,

          // Payload Example
          Text(
            'Example Payload',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapVerticalSm,

          const _CodeBlock(
            code: '''
{
  "event": "BOOKING_CREATED",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "id": "booking_abc123",
    "clientName": "John Smith",
    "service": "Consultation",
    "date": "2024-01-20",
    "time": "14:00",
    "duration": 60,
    "status": "confirmed"
  }
}''',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: colorScheme.tertiary,
                      size: 20,
                    ),
                    AppSpacing.gapHorizontalSm,
                    Text(
                      'Security',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVerticalSm,
                Text(
                  'All webhook payloads are signed with HMAC-SHA256. Use the signing secret (provided when you create a webhook) to verify requests are from Scriber.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                AppSpacing.gapVerticalSm,
                Text(
                  'Check for the X-Webhook-Signature header in incoming requests.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.action,
  });

  final int number;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapVerticalXs,
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (action != null) ...[
                  AppSpacing.gapVerticalSm,
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformGuide extends StatelessWidget {
  const _PlatformGuide({
    required this.name,
    required this.iconColor,
    required this.steps,
  });

  final String name;
  final Color iconColor;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Icon(
            Icons.integration_instructions_rounded,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${steps.length} steps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          ...steps.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: Text(
                      step,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EventTypeRow extends StatelessWidget {
  const _EventTypeRow({
    required this.category,
    required this.events,
  });

  final String category;
  final List<(String code, String description)> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          AppSpacing.gapVerticalSm,
          ...events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      event.$1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: Text(
                      event.$2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'JSON',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  tooltip: 'Copy',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // Code
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              code,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
