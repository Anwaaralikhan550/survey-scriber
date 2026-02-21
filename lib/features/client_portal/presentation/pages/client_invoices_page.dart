import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/presentation/widgets/invoice_status_chip.dart';
import '../providers/client_invoices_providers.dart';

/// Client Invoices List Page
class ClientInvoicesPage extends ConsumerStatefulWidget {
  const ClientInvoicesPage({super.key});

  @override
  ConsumerState<ClientInvoicesPage> createState() => _ClientInvoicesPageState();
}

class _ClientInvoicesPageState extends ConsumerState<ClientInvoicesPage> {
  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() {
    ref.read(clientInvoicesNotifierProvider.notifier).loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(clientInvoicesNotifierProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'My Invoices',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadInvoices(),
        child: state.isLoading && state.invoices.isEmpty
            ? _buildLoading(colorScheme)
            : state.error != null && state.invoices.isEmpty
                ? _buildError(theme, colorScheme, state.error!)
                : state.invoices.isEmpty
                    ? _buildEmpty(theme, colorScheme)
                    : _buildList(theme, colorScheme, state),
      ),
    );
  }

  Widget _buildLoading(ColorScheme colorScheme) => Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.primary,
        ),
      ),
    );

  Widget _buildError(ThemeData theme, ColorScheme colorScheme, String error) => Center(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadInvoices,
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

  Widget _buildEmpty(ThemeData theme, ColorScheme colorScheme) => Center(
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
              'No invoices yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your invoices will appear here\nonce they are issued',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  Widget _buildList(
    ThemeData theme,
    ColorScheme colorScheme,
    ClientInvoicesState state,
  ) => NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 300 &&
            state.hasMore &&
            !state.isLoading) {
          ref.read(clientInvoicesNotifierProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.invoices.length) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          }

          final invoice = state.invoices[index];
          return _ClientInvoiceCard(
            invoice: invoice,
            onTap: () => context.go(Routes.clientInvoiceDetailPath(invoice.id)),
          );
        },
      ),
    );
}

class _ClientInvoiceCard extends StatelessWidget {
  const _ClientInvoiceCard({
    required this.invoice,
    this.onTap,
  });

  final Invoice invoice;
  final VoidCallback? onTap;

  static final _dateFormat = DateFormat('d MMM yyyy');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '\u00A3',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InvoiceStatusChip(
                            status: invoice.status,
                            isOverdue: invoice.isOverdue,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(invoice.total / 100),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dates
                if (invoice.issueDate != null) ...[
                  _DateRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Issued: ${_dateFormat.format(invoice.issueDate!)}',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 6),
                ],

                if (invoice.dueDate != null)
                  _DateRow(
                    icon: invoice.isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.event_rounded,
                    label: 'Due: ${_dateFormat.format(invoice.dueDate!)}',
                    colorScheme: colorScheme,
                    isWarning: invoice.isOverdue,
                  ),

                if (invoice.paidDate != null) ...[
                  const SizedBox(height: 6),
                  _DateRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Paid: ${_dateFormat.format(invoice.paidDate!)}',
                    colorScheme: colorScheme,
                    isSuccess: true,
                  ),
                ],

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.colorScheme,
    this.isWarning = false,
    this.isSuccess = false,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final bool isWarning;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color getColor() {
      if (isSuccess) return colorScheme.primary;
      if (isWarning) return colorScheme.tertiary;
      return colorScheme.onSurfaceVariant.withOpacity(0.7);
    }

    final color = getColor();

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: isWarning || isSuccess ? FontWeight.w500 : null,
          ),
        ),
      ],
    );
  }
}
