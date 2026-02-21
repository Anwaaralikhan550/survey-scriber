import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../invoices/domain/entities/invoice.dart';
import '../../../../invoices/domain/entities/invoice_status.dart';
import '../../../../invoices/presentation/widgets/invoice_status_chip.dart';
import '../providers/admin_invoices_providers.dart';

class AdminInvoicesListPage extends ConsumerStatefulWidget {
  const AdminInvoicesListPage({super.key});

  @override
  ConsumerState<AdminInvoicesListPage> createState() => _AdminInvoicesListPageState();
}

class _AdminInvoicesListPageState extends ConsumerState<AdminInvoicesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminInvoicesListProvider.notifier).loadInvoices(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(adminInvoicesListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isLoading)
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
        onPressed: () => context.push(Routes.adminInvoicesCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
        shape: const StadiumBorder(),
      ),
      body: Column(
        children: [
          // Status filter chips
          _StatusFilterBar(
            selectedStatus: state.selectedStatus,
            onStatusSelected: (status) {
              ref.read(adminInvoicesListProvider.notifier).setStatusFilter(status);
            },
            onClear: () {
              ref.read(adminInvoicesListProvider.notifier).clearFilter();
            },
          ),

          // Invoice count
          if (state.total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    '${state.total} invoice${state.total == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Invoice list
          Expanded(
            child: _buildBody(state, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AdminInvoicesListState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.invoices.isEmpty) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        iconColor: colorScheme.error,
        title: 'Failed to load invoices',
        subtitle: state.error!,
        action: FilledButton.icon(
          onPressed: () => ref.read(adminInvoicesListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }

    if (state.invoices.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_outlined,
        iconColor: colorScheme.primary,
        title: 'No invoices found',
        subtitle: state.selectedStatus != null
            ? 'No ${state.selectedStatus!.displayName.toLowerCase()} invoices'
            : 'Create your first invoice to get started',
        action: state.selectedStatus != null
            ? TextButton(
                onPressed: () =>
                    ref.read(adminInvoicesListProvider.notifier).clearFilter(),
                child: const Text('Clear filter'),
              )
            : FilledButton.icon(
                onPressed: () => context.push(Routes.adminInvoicesCreate),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Invoice'),
              ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminInvoicesListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: 88,
        ),
        itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.invoices.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () =>
                            ref.read(adminInvoicesListProvider.notifier).loadMore(),
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final invoice = state.invoices[index];
          return _InvoiceCard(
            invoice: invoice,
            onTap: () => context.push(Routes.adminInvoiceDetailPath(invoice.id)),
          );
        },
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.onClear,
  });

  final InvoiceStatus? selectedStatus;
  final void Function(InvoiceStatus?) onStatusSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(
            theme: theme,
            label: 'All',
            isSelected: selectedStatus == null,
            onSelected: onClear,
          ),
          const SizedBox(width: 8),
          ...InvoiceStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  theme: theme,
                  label: status.displayName,
                  isSelected: selectedStatus == status,
                  onSelected: () => onStatusSelected(status),
                ),
              ),),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) => FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
        letterSpacing: 0.1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.5)
            : theme.colorScheme.outlineVariant.withOpacity(0.6),
        width: isSelected ? 1.5 : 1,
      ),
    );
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Invoice icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(invoice.status).withOpacity(0.1),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: _getStatusColor(invoice.status),
                        size: 20,
                      ),
                    ),
                    AppSpacing.gapHorizontalMd,

                    // Invoice number and client
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.gapVerticalXs,
                          Text(
                            invoice.clientName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Status chip
                    InvoiceStatusChip(
                      status: invoice.status,
                      isOverdue: invoice.isOverdue,
                    ),
                  ],
                ),

                AppSpacing.gapVerticalMd,

                // Footer row
                Row(
                  children: [
                    // Date
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      invoice.issueDate != null
                          ? dateFormat.format(invoice.issueDate!)
                          : 'Draft',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    // Amount
                    Text(
                      invoice.formattedTotal,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                // Overdue indicator
                if (invoice.isOverdue) ...[
                  AppSpacing.gapVerticalSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Payment overdue',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.issued:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? action;

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
            ),
            AppSpacing.gapVerticalLg,
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              AppSpacing.gapVerticalLg,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
