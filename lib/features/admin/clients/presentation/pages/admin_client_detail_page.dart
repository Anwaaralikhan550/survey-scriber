import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../providers/admin_clients_provider.dart';

class AdminClientDetailPage extends ConsumerStatefulWidget {
  const AdminClientDetailPage({
    super.key,
    required this.clientId,
  });

  final String clientId;

  @override
  ConsumerState<AdminClientDetailPage> createState() =>
      _AdminClientDetailPageState();
}

class _AdminClientDetailPageState extends ConsumerState<AdminClientDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminClientsProvider.notifier).loadClientDetails(widget.clientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(adminClientsProvider);
    final client = state.selectedClient;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(client?.displayName ?? 'Client Details'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(adminClientsProvider.notifier).clearSelectedClient();
            context.pop();
          },
        ),
      ),
      body: _buildBody(state, theme, colorScheme),
    );
  }

  Widget _buildBody(
    AdminClientsState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.selectedClient == null) {
      return _ErrorState(
        error: state.error!,
        onRetry: () => ref
            .read(adminClientsProvider.notifier)
            .loadClientDetails(widget.clientId),
      );
    }

    final client = state.selectedClient;
    if (client == null) {
      return const _ErrorState(
        error: 'Client not found',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminClientsProvider.notifier).loadClientDetails(widget.clientId),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Read-only notice
          _ReadOnlyBanner(colorScheme: colorScheme, theme: theme),
          AppSpacing.gapVerticalMd,

          // Client Avatar Card
          _ClientHeaderCard(client: client),
          AppSpacing.gapVerticalMd,

          // Contact Information
          const _SectionHeader(title: 'Contact Information'),
          AppSpacing.gapVerticalSm,
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: client.email,
                onCopy: () => _copyToClipboard(context, client.email, 'Email'),
              ),
              if (client.phone != null && client.phone!.isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: client.phone!,
                  onCopy: () => _copyToClipboard(context, client.phone!, 'Phone'),
                ),
              if (client.company != null && client.company!.isNotEmpty)
                _InfoRow(
                  icon: Icons.business_outlined,
                  label: 'Company',
                  value: client.company!,
                ),
            ],
          ),
          AppSpacing.gapVerticalMd,

          // Activity Summary
          const _SectionHeader(title: 'Activity'),
          AppSpacing.gapVerticalSm,
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoices',
                  value: '${client.invoiceCount}',
                  color: colorScheme.primary,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Bookings',
                  value: '${client.bookingCount}',
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,

          // Client ID (for reference)
          const _SectionHeader(title: 'System Information'),
          AppSpacing.gapVerticalSm,
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.fingerprint_outlined,
                label: 'Client ID',
                value: client.id,
                onCopy: () => _copyToClipboard(context, client.id, 'Client ID'),
                isMonospace: true,
              ),
              _InfoRow(
                icon: client.isActive
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                label: 'Status',
                value: client.isActive ? 'Active' : 'Inactive',
                valueColor:
                    client.isActive ? colorScheme.primary : colorScheme.error,
              ),
            ],
          ),
          AppSpacing.gapVerticalXxl,
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
            Icons.visibility_outlined,
            size: 20,
            color: colorScheme.tertiary,
          ),
          AppSpacing.gapHorizontalSm,
          Expanded(
            child: Text(
              'Read-only view. Edit functionality requires a dedicated client management API.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
}

class _ClientHeaderCard extends StatelessWidget {
  const _ClientHeaderCard({required this.client});

  final dynamic client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.5),
            colorScheme.primaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Large Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                client.initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          AppSpacing.gapHorizontalLg,

          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (client.fullName != client.displayName &&
                    client.fullName != client.email) ...[
                  AppSpacing.gapVerticalXs,
                  Text(
                    client.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.isMonospace = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool isMonospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          AppSpacing.gapHorizontalMd,
          Expanded(
            child: Column(
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
                  style: (isMonospace
                          ? theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            )
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
              iconSize: 18,
              color: colorScheme.onSurfaceVariant,
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
            ),
        ],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    this.onRetry,
  });

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            AppSpacing.gapVerticalLg,
            Text(
              'Error',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapVerticalLg,
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
