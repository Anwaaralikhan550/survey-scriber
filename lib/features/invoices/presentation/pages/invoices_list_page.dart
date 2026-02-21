import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../domain/entities/invoice_status.dart';
import '../providers/invoices_providers.dart';
import '../widgets/invoice_card.dart';

class InvoicesListPage extends ConsumerStatefulWidget {
  const InvoicesListPage({super.key});

  @override
  ConsumerState<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends ConsumerState<InvoicesListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invoicesListNotifierProvider.notifier).loadInvoices(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoicesListNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Invoices',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              tooltip: 'Create Invoice',
              onPressed: () => context.push(Routes.invoicesCreate),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.invoicesCreate),
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
              ref.read(invoicesListNotifierProvider.notifier).setStatusFilter(status);
            },
            onClear: () {
              ref.read(invoicesListNotifierProvider.notifier).clearFilter();
            },
          ),

          // Invoice list
          Expanded(
            child: _buildContent(state, theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    InvoicesListState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.invoices.isEmpty) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    if (state.error != null && state.invoices.isEmpty) {
      return _buildErrorState(theme, colorScheme);
    }

    if (state.invoices.isEmpty) {
      return _buildEmptyState(state, theme, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(invoicesListNotifierProvider.notifier).loadInvoices(refresh: true);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: state.invoices.length,
        itemBuilder: (context, index) {
          final invoice = state.invoices[index];
          return InvoiceCard(
            invoice: invoice,
            onTap: () => context.push(Routes.invoiceDetailPath(invoice.id)),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load invoices',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(invoicesListNotifierProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildEmptyState(
    InvoicesListState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final hasFilter = state.selectedStatus != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilter
                  ? 'No ${state.selectedStatus!.displayName.toLowerCase()} invoices'
                  : 'No invoices yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try selecting a different filter'
                  : 'Create your first invoice to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(Routes.invoicesCreate),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create Invoice'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
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
  final ValueChanged<InvoiceStatus> onStatusSelected;
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
            context: context,
            theme: theme,
            label: 'All',
            isSelected: selectedStatus == null,
            onSelected: onClear,
          ),
          const SizedBox(width: 8),
          ...InvoiceStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  context: context,
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
    required BuildContext context,
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
