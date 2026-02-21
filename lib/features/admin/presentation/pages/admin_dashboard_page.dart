import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../config/presentation/providers/config_providers.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load config on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(configProvider.notifier).loadConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final configState = ref.watch(configProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(configProvider.notifier).refreshConfig();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Config Version Card
            _ConfigVersionCard(configState: configState),
            AppSpacing.gapVerticalMd,

            // Admin Tools Section
            Text(
              'Admin Tools',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapVerticalSm,

            // User Management
            _AdminToolCard(
              icon: Icons.people_outline_rounded,
              iconColor: colorScheme.primary,
              title: 'User Management',
              subtitle: 'Manage users and roles',
              onTap: () => context.push(Routes.adminUsers),
            ),

            // Client Management
            _AdminToolCard(
              icon: Icons.business_center_outlined,
              iconColor: Colors.cyan,
              title: 'Client Management',
              subtitle: 'View client accounts and details',
              onTap: () => context.push(Routes.adminClients),
            ),

            // V2 Tree Manager — single source of truth for inspection & valuation
            _AdminToolCard(
              icon: Icons.account_tree_rounded,
              iconColor: Colors.green,
              title: 'Survey Trees',
              subtitle: 'Manage inspection & valuation trees, fields, phrases, and sections',
              onTap: () => context.push(Routes.adminTrees),
            ),

            // Data Export
            _AdminToolCard(
              icon: Icons.download_rounded,
              iconColor: Colors.teal,
              title: 'Data Export',
              subtitle: 'Export bookings, invoices, and reports to CSV',
              onTap: () => context.push(Routes.adminExports),
            ),

            // Integrations
            _AdminToolCard(
              icon: Icons.hub_rounded,
              iconColor: Colors.orange,
              title: 'Integrations',
              subtitle: 'Webhooks, automation, and external connections',
              onTap: () => context.push(Routes.adminIntegrations),
            ),

            // Billing & Invoices
            _AdminToolCard(
              icon: Icons.receipt_long_rounded,
              iconColor: Colors.indigo,
              title: 'Billing & Invoices',
              subtitle: 'Create, issue, and manage client invoices',
              onTap: () => context.push(Routes.adminInvoices),
            ),

            // Audit Logs
            _AdminToolCard(
              icon: Icons.history_rounded,
              iconColor: Colors.blueGrey,
              title: 'Audit Logs',
              subtitle: 'View system activity and changes',
              onTap: () => context.push(Routes.adminAuditLogs),
            ),

            // TEMP: Remove after client portal testing
            _AdminToolCard(
              icon: Icons.open_in_new_rounded,
              iconColor: Colors.deepPurple,
              title: 'Client Portal (Preview)',
              subtitle: 'Test the client-facing portal experience',
              onTap: () => context.push(Routes.clientLogin),
            ),

            AppSpacing.gapVerticalXxl,
          ],
        ),
      ),
    );
  }
}

class _ConfigVersionCard extends ConsumerWidget {
  const _ConfigVersionCard({required this.configState});

  final ConfigState configState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasError = configState.error != null;
    final isLoading = configState.isLoading;
    final isLoaded = configState.isLoaded;

    // Determine card colors based on state
    final gradientColors = hasError
        ? [
            colorScheme.errorContainer.withOpacity(0.4),
            colorScheme.errorContainer.withOpacity(0.2),
          ]
        : [
            colorScheme.primaryContainer.withOpacity(0.5),
            colorScheme.primaryContainer.withOpacity(0.3),
          ];

    final borderColor = hasError
        ? colorScheme.error.withOpacity(0.3)
        : colorScheme.primary.withOpacity(0.2);

    final iconBgColor = hasError
        ? colorScheme.error.withOpacity(0.15)
        : colorScheme.primary.withOpacity(0.15);

    final iconColor = hasError ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Icon(
              hasError
                  ? Icons.warning_amber_rounded
                  : Icons.settings_applications_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
          AppSpacing.gapHorizontalMd,

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapVerticalXs,
                if (isLoading)
                  Text(
                    'Loading configuration...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else if (hasError)
                  Text(
                    'Unable to load config',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  )
                else if (isLoaded)
                  Text(
                    'Version ${configState.version?.version ?? 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'Not loaded',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          // Trailing indicator/action
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            )
          else if (hasError)
            IconButton(
              onPressed: () => ref.read(configProvider.notifier).loadConfig(),
              icon: const Icon(Icons.refresh_rounded),
              color: colorScheme.error,
              tooltip: 'Retry',
              visualDensity: VisualDensity.compact,
            )
          else if (isLoaded)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref.read(configProvider.notifier).refreshConfig(),
                  icon: const Icon(Icons.sync_rounded),
                  color: colorScheme.primary,
                  tooltip: 'Reload configuration',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            )
          else
            IconButton(
              onPressed: () => ref.read(configProvider.notifier).loadConfig(),
              icon: const Icon(Icons.refresh_rounded),
              color: colorScheme.onSurfaceVariant,
              tooltip: 'Load configuration',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _AdminToolCard extends StatelessWidget {
  const _AdminToolCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
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
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and label
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              AppSpacing.gapHorizontalSm,
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,

          // Value with loading state handling
          if (value == '-') Container(
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ) else Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
        ],
      ),
    );
  }
}
