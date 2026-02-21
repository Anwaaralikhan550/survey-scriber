import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../invoices/domain/entities/invoice.dart';
import '../../../../invoices/domain/entities/invoice_status.dart';
import '../../../../invoices/presentation/widgets/invoice_status_chip.dart';
import '../providers/admin_invoices_providers.dart';

class AdminInvoiceDetailPage extends ConsumerStatefulWidget {
  const AdminInvoiceDetailPage({
    super.key,
    required this.invoiceId,
  });

  final String invoiceId;

  @override
  ConsumerState<AdminInvoiceDetailPage> createState() => _AdminInvoiceDetailPageState();
}

class _AdminInvoiceDetailPageState extends ConsumerState<AdminInvoiceDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminInvoiceDetailProvider.notifier).loadInvoice(widget.invoiceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(adminInvoiceDetailProvider);

    // Listen for messages
    ref.listen<AdminInvoiceDetailState>(adminInvoiceDetailProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
        ref.read(adminInvoiceDetailProvider.notifier).clearMessages();
      }
      if (next.actionSuccess != null && previous?.actionSuccess != next.actionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionSuccess!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        ref.read(adminInvoiceDetailProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(state.invoice?.invoiceNumber ?? 'Invoice'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isActioning)
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
          else if (state.invoice != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) => _handleAction(action, state.invoice!),
              itemBuilder: (context) => _buildMenuItems(state.invoice!),
            ),
        ],
      ),
      body: _buildBody(state, theme, colorScheme),
      bottomNavigationBar: state.invoice != null
          ? _ActionBar(
              invoice: state.invoice!,
              isLoading: state.isActioning,
              onIssue: () => _confirmIssue(state.invoice!),
              onMarkPaid: () => _confirmMarkPaid(state.invoice!),
              onCancel: () => _showCancelDialog(state.invoice!),
            )
          : null,
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(InvoiceDetail invoice) {
    final items = <PopupMenuEntry<String>>[];

    items.add(
      const PopupMenuItem(
        value: 'download',
        child: Row(
          children: [
            Icon(Icons.download_rounded, size: 20),
            SizedBox(width: 12),
            Text('Download PDF'),
          ],
        ),
      ),
    );

    if (invoice.status == InvoiceStatus.draft) {
      items.add(
        const PopupMenuItem(
          value: 'issue',
          child: Row(
            children: [
              Icon(Icons.send_rounded, size: 20),
              SizedBox(width: 12),
              Text('Issue Invoice'),
            ],
          ),
        ),
      );
    }

    if (invoice.status == InvoiceStatus.issued) {
      items.add(
        const PopupMenuItem(
          value: 'mark_paid',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 20),
              SizedBox(width: 12),
              Text('Mark as Paid'),
            ],
          ),
        ),
      );
    }

    if (invoice.status == InvoiceStatus.draft || invoice.status == InvoiceStatus.issued) {
      items.add(
        PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Text('Cancel Invoice', style: TextStyle(color: Colors.red.shade700)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleAction(String action, InvoiceDetail invoice) {
    switch (action) {
      case 'download':
        _downloadPdf();
        break;
      case 'issue':
        _confirmIssue(invoice);
        break;
      case 'mark_paid':
        _confirmMarkPaid(invoice);
        break;
      case 'cancel':
        _showCancelDialog(invoice);
        break;
    }
  }

  Future<void> _downloadPdf() async {
    final file = await ref.read(adminInvoiceDetailProvider.notifier).downloadPdf();
    if (file != null && mounted) {
      final state = ref.read(adminInvoiceDetailProvider);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ${state.invoice?.invoiceNumber ?? ''}',
      );
    }
  }

  Future<void> _confirmIssue(InvoiceDetail invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Invoice'),
        content: Text(
          'Are you sure you want to issue invoice ${invoice.invoiceNumber}?\n\n'
          'This will send it to the client and it can no longer be edited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Issue'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminInvoiceDetailProvider.notifier).issueInvoice();
    }
  }

  Future<void> _confirmMarkPaid(InvoiceDetail invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark invoice ${invoice.invoiceNumber} as paid?\n\n'
          'Amount: ${invoice.formattedTotal}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminInvoiceDetailProvider.notifier).markAsPaid();
    }
  }

  Future<void> _showCancelDialog(InvoiceDetail invoice) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel invoice ${invoice.invoiceNumber}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation reason',
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(adminInvoiceDetailProvider.notifier).cancelInvoice(result);
    }
  }

  Widget _buildBody(
    AdminInvoiceDetailState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.invoice == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.invoice == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
            AppSpacing.gapVerticalMd,
            Text('Failed to load invoice', style: theme.textTheme.titleMedium),
            AppSpacing.gapVerticalSm,
            FilledButton(
              onPressed: () => ref
                  .read(adminInvoiceDetailProvider.notifier)
                  .loadInvoice(widget.invoiceId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final invoice = state.invoice!;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminInvoiceDetailProvider.notifier).loadInvoice(widget.invoiceId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _HeaderCard(invoice: invoice),
            AppSpacing.gapVerticalMd,

            // Client info
            _SectionCard(
              title: 'Client',
              icon: Icons.person_outline_rounded,
              child: _ClientInfo(client: invoice.client),
            ),
            AppSpacing.gapVerticalMd,

            // Booking reference
            if (invoice.booking != null) ...[
              _SectionCard(
                title: 'Related Booking',
                icon: Icons.calendar_today_outlined,
                child: _BookingInfo(booking: invoice.booking!),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Line items
            _SectionCard(
              title: 'Line Items',
              icon: Icons.list_alt_rounded,
              child: _LineItemsTable(items: invoice.items),
            ),
            AppSpacing.gapVerticalMd,

            // Totals
            _TotalsCard(invoice: invoice),
            AppSpacing.gapVerticalMd,

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              _SectionCard(
                title: 'Notes',
                icon: Icons.notes_rounded,
                child: Text(
                  invoice.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Payment terms
            if (invoice.paymentTerms != null && invoice.paymentTerms!.isNotEmpty) ...[
              _SectionCard(
                title: 'Payment Terms',
                icon: Icons.gavel_rounded,
                child: Text(
                  invoice.paymentTerms!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Cancellation info
            if (invoice.status == InvoiceStatus.cancelled &&
                invoice.cancellationReason != null) ...[
              _SectionCard(
                title: 'Cancellation',
                icon: Icons.cancel_outlined,
                iconColor: Colors.red,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.cancellationReason!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (invoice.cancelledDate != null) ...[
                      AppSpacing.gapVerticalSm,
                      Text(
                        'Cancelled on ${DateFormat.yMMMd().format(invoice.cancelledDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Created by info
            _SectionCard(
              title: 'Created By',
              icon: Icons.badge_outlined,
              child: Text(
                '${invoice.createdBy.displayName} on ${DateFormat.yMMMd().format(invoice.createdAt)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.invoice});

  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(invoice.status).withOpacity(0.15),
            _getStatusColor(invoice.status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: _getStatusColor(invoice.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.status).withOpacity(0.2),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: _getStatusColor(invoice.status),
                  size: 24,
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapVerticalXs,
                    Text(
                      invoice.clientName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              InvoiceStatusChip(
                status: invoice.status,
                isOverdue: invoice.isOverdue,
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          Row(
            children: [
              _DateInfo(
                label: 'Issue Date',
                date: invoice.issueDate != null
                    ? dateFormat.format(invoice.issueDate!)
                    : 'Not issued',
              ),
              AppSpacing.gapHorizontalLg,
              _DateInfo(
                label: 'Due Date',
                date: invoice.dueDate != null
                    ? dateFormat.format(invoice.dueDate!)
                    : 'Not set',
                isOverdue: invoice.isOverdue,
              ),
              if (invoice.paidDate != null) ...[
                AppSpacing.gapHorizontalLg,
                _DateInfo(
                  label: 'Paid Date',
                  date: dateFormat.format(invoice.paidDate!),
                  isPaid: true,
                ),
              ],
            ],
          ),
        ],
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

class _DateInfo extends StatelessWidget {
  const _DateInfo({
    required this.label,
    required this.date,
    this.isOverdue = false,
    this.isPaid = false,
  });

  final String label;
  final String date;
  final bool isOverdue;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    var textColor = colorScheme.onSurface;
    if (isOverdue) textColor = Colors.orange.shade700;
    if (isPaid) textColor = Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                icon,
                size: 18,
                color: iconColor ?? colorScheme.primary,
              ),
              AppSpacing.gapHorizontalSm,
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          child,
        ],
      ),
    );
  }
}

class _ClientInfo extends StatelessWidget {
  const _ClientInfo({required this.client});

  final InvoiceClientInfo client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client.displayName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (client.company != null && client.company!.isNotEmpty) ...[
          AppSpacing.gapVerticalXs,
          Text(
            client.company!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        AppSpacing.gapVerticalSm,
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              client.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (client.phone != null && client.phone!.isNotEmpty) ...[
          AppSpacing.gapVerticalXs,
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                client.phone!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BookingInfo extends StatelessWidget {
  const _BookingInfo({required this.booking});

  final InvoiceBookingInfo booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateFormat.format(booking.date),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (booking.propertyAddress != null &&
            booking.propertyAddress!.isNotEmpty) ...[
          AppSpacing.gapVerticalXs,
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.propertyAddress!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LineItemsTable extends StatelessWidget {
  const _LineItemsTable({required this.items});

  final List<InvoiceItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Description',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Qty',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Price',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapVerticalSm,

        // Items
        ...items.map((item) => _LineItemRow(item: item)),
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item});

  final InvoiceItem item;

  String _formatAmount(int pence) {
    final pounds = pence / 100;
    return '\u00A3${pounds.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.description,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              '${item.quantity}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(item.unitPrice),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              _formatAmount(item.amount),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.invoice});

  final InvoiceDetail invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _TotalRow(
            label: 'Subtotal',
            value: invoice.formattedSubtotal,
          ),
          AppSpacing.gapVerticalSm,
          _TotalRow(
            label: 'VAT (${invoice.taxRate.toStringAsFixed(0)}%)',
            value: invoice.formattedTaxAmount,
          ),
          AppSpacing.gapVerticalSm,
          Divider(
            color: colorScheme.outlineVariant,
          ),
          AppSpacing.gapVerticalSm,
          _TotalRow(
            label: 'Total',
            value: invoice.formattedTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.invoice,
    required this.isLoading,
    required this.onIssue,
    required this.onMarkPaid,
    required this.onCancel,
  });

  final InvoiceDetail invoice;
  final bool isLoading;
  final VoidCallback onIssue;
  final VoidCallback onMarkPaid;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // No actions for paid or cancelled invoices
    if (invoice.status == InvoiceStatus.paid ||
        invoice.status == InvoiceStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (invoice.status == InvoiceStatus.draft ||
                invoice.status == InvoiceStatus.issued) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              AppSpacing.gapHorizontalMd,
            ],
            if (invoice.status == InvoiceStatus.draft)
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onIssue,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Issue Invoice'),
                ),
              ),
            if (invoice.status == InvoiceStatus.issued)
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onMarkPaid,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Mark as Paid'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
