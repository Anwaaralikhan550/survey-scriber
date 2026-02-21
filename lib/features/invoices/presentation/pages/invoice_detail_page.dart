import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';
import '../providers/invoices_providers.dart';
import '../widgets/invoice_status_chip.dart';

class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
  });

  final String invoiceId;

  static final _dateFormat = DateFormat('d MMMM yyyy');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '\u00A3',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final actionsState = ref.watch(invoiceActionsNotifierProvider);

    // Show snackbar for success/error messages
    ref.listen<InvoiceActionsState>(invoiceActionsNotifierProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(invoiceActionsNotifierProvider.notifier).clearMessages();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(invoiceActionsNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          if (actionsState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: invoiceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load invoice: $error'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (invoice) => _InvoiceDetailContent(
          invoice: invoice,
          onDownloadPdf: () => _downloadPdf(context, ref, invoice),
          onIssue: invoice.status == InvoiceStatus.draft
              ? () => _issueInvoice(context, ref)
              : null,
          onMarkPaid: invoice.status == InvoiceStatus.issued
              ? () => _markAsPaid(context, ref)
              : null,
          onCancel: invoice.status == InvoiceStatus.issued
              ? () => _cancelInvoice(context, ref)
              : null,
          onDelete: invoice.status == InvoiceStatus.draft
              ? () => _deleteInvoice(context, ref)
              : null,
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref, InvoiceDetail invoice) async {
    final bytes = await ref.read(invoiceActionsNotifierProvider.notifier).downloadPdf(invoiceId);
    if (bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: 'Invoice ${invoice.invoiceNumber}');
    }
  }

  Future<void> _issueInvoice(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Invoice'),
        content: const Text(
          'Once issued, the invoice cannot be edited. '
          'The client will be notified by email. Continue?',
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
      await ref.read(invoiceActionsNotifierProvider.notifier).issueInvoice(invoiceId);
    }
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Mark this invoice as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(invoiceActionsNotifierProvider.notifier).markAsPaid(invoiceId);
    }
  }

  Future<void> _cancelInvoice(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone. Please provide a reason:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter cancellation reason',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Invoice'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      await ref
          .read(invoiceActionsNotifierProvider.notifier)
          .cancelInvoice(invoiceId, reasonController.text);
    }
  }

  Future<void> _deleteInvoice(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('This will permanently delete this draft invoice. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(invoiceActionsNotifierProvider.notifier).deleteInvoice(invoiceId);
      if (success && context.mounted) {
        context.pop();
      }
    }
  }
}

class _InvoiceDetailContent extends StatelessWidget {
  const _InvoiceDetailContent({
    required this.invoice,
    required this.onDownloadPdf,
    this.onIssue,
    this.onMarkPaid,
    this.onCancel,
    this.onDelete,
  });

  final InvoiceDetail invoice;
  final VoidCallback onDownloadPdf;
  final VoidCallback? onIssue;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  static final _dateFormat = DateFormat('d MMMM yyyy');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '\u00A3',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InvoiceStatusChip(
                        status: invoice.status,
                        isOverdue: invoice.isOverdue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currencyFormat.format(invoice.total / 100),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Client info
          _SectionCard(
            title: 'Client',
            icon: Icons.person_outline,
            children: [
              _InfoRow(label: 'Name', value: invoice.client.displayName),
              _InfoRow(label: 'Email', value: invoice.client.email),
              if (invoice.client.phone != null)
                _InfoRow(label: 'Phone', value: invoice.client.phone!),
              if (invoice.client.company != null)
                _InfoRow(label: 'Company', value: invoice.client.company!),
            ],
          ),
          const SizedBox(height: 16),

          // Dates
          _SectionCard(
            title: 'Dates',
            icon: Icons.calendar_today_outlined,
            children: [
              _InfoRow(label: 'Created', value: _dateFormat.format(invoice.createdAt)),
              if (invoice.issueDate != null)
                _InfoRow(label: 'Issued', value: _dateFormat.format(invoice.issueDate!)),
              if (invoice.dueDate != null)
                _InfoRow(
                  label: 'Due',
                  value: _dateFormat.format(invoice.dueDate!),
                  isWarning: invoice.isOverdue,
                ),
              if (invoice.paidDate != null)
                _InfoRow(label: 'Paid', value: _dateFormat.format(invoice.paidDate!)),
              if (invoice.cancelledDate != null)
                _InfoRow(label: 'Cancelled', value: _dateFormat.format(invoice.cancelledDate!)),
            ],
          ),
          const SizedBox(height: 16),

          // Line items
          _SectionCard(
            title: 'Items',
            icon: Icons.list_alt_outlined,
            children: [
              ...invoice.items.map((item) => _LineItemRow(item: item)),
              const Divider(),
              _TotalRow(
                label: 'Subtotal',
                value: _currencyFormat.format(invoice.subtotal / 100),
              ),
              _TotalRow(
                label: 'VAT (${invoice.taxRate}%)',
                value: _currencyFormat.format(invoice.taxAmount / 100),
              ),
              _TotalRow(
                label: 'Total',
                value: _currencyFormat.format(invoice.total / 100),
                isBold: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notes & Payment terms
          if (invoice.notes != null || invoice.paymentTerms != null)
            _SectionCard(
              title: 'Additional Info',
              icon: Icons.info_outline,
              children: [
                if (invoice.paymentTerms != null)
                  _InfoRow(label: 'Payment Terms', value: invoice.paymentTerms!),
                if (invoice.notes != null) _InfoRow(label: 'Notes', value: invoice.notes!),
              ],
            ),

          if (invoice.cancellationReason != null) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Cancellation',
              icon: Icons.cancel_outlined,
              children: [
                _InfoRow(label: 'Reason', value: invoice.cancellationReason!),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          _ActionButtons(
            onDownloadPdf: onDownloadPdf,
            onIssue: onIssue,
            onMarkPaid: onMarkPaid,
            onCancel: onCancel,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isWarning ? Colors.orange.shade700 : null,
                fontWeight: isWarning ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item});

  final InvoiceItem item;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '\u00A3',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium,
                ),
                if (item.itemType != null)
                  Text(
                    item.itemType!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${item.quantity} x ${_currencyFormat.format(item.unitPrice / 100)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _currencyFormat.format(item.amount / 100),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
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
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onDownloadPdf,
    this.onIssue,
    this.onMarkPaid,
    this.onCancel,
    this.onDelete,
  });

  final VoidCallback onDownloadPdf;
  final VoidCallback? onIssue;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary actions
        if (onIssue != null)
          FilledButton.icon(
            onPressed: onIssue,
            icon: const Icon(Icons.send),
            label: const Text('Issue Invoice'),
          ),
        if (onMarkPaid != null)
          FilledButton.icon(
            onPressed: onMarkPaid,
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Paid'),
          ),

        const SizedBox(height: 8),

        // Download PDF
        OutlinedButton.icon(
          onPressed: onDownloadPdf,
          icon: const Icon(Icons.download),
          label: const Text('Download PDF'),
        ),

        // Secondary actions
        if (onCancel != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCancel,
            icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
            label: Text(
              'Cancel Invoice',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            label: Text(
              'Delete Draft',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
}
