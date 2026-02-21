import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/router/routes.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../scheduling/domain/entities/booking.dart';
import '../providers/admin_invoices_providers.dart';

class AdminCreateInvoicePage extends ConsumerStatefulWidget {
  const AdminCreateInvoicePage({super.key});

  @override
  ConsumerState<AdminCreateInvoicePage> createState() => _AdminCreateInvoicePageState();
}

class _AdminCreateInvoicePageState extends ConsumerState<AdminCreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _paymentTermsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createInvoiceProvider.notifier).loadBookings();
      // Add initial line item
      ref.read(createInvoiceProvider.notifier).addLineItem();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(createInvoiceProvider);

    // Listen for creation success
    ref.listen<CreateInvoiceState>(createInvoiceProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.error,
          ),
        );
      }
      if (next.createdInvoice != null && previous?.createdInvoice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${next.createdInvoice!.invoiceNumber} created'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        context.pushReplacement(Routes.adminInvoiceDetailPath(next.createdInvoice!.id));
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Create Invoice'),
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
              onPressed: state.items.isEmpty ? null : _createInvoice,
              child: const Text('Create'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Booking Selection (Optional)
            const _SectionHeader(
              title: 'Link to Booking',
              subtitle: 'Optional - select a booking to auto-fill client info',
            ),
            AppSpacing.gapVerticalSm,
            _BookingSelector(
              selectedBooking: state.selectedBooking,
              bookings: state.availableBookings,
              isLoading: state.isLoadingBookings,
              onSelect: (booking) {
                ref.read(createInvoiceProvider.notifier).selectBooking(booking);
              },
            ),

            AppSpacing.gapVerticalLg,

            // Client Info
            _SectionHeader(
              title: 'Client Information',
              subtitle: state.selectedBooking != null
                  ? 'Auto-filled from booking'
                  : 'Enter client details',
            ),
            AppSpacing.gapVerticalSm,
            _ClientInfoCard(
              clientName: state.clientName,
              clientEmail: state.clientEmail,
              fromBooking: state.selectedBooking != null,
            ),

            AppSpacing.gapVerticalLg,

            // Line Items
            _SectionHeader(
              title: 'Line Items',
              subtitle: 'Add services or products',
              action: TextButton.icon(
                onPressed: () =>
                    ref.read(createInvoiceProvider.notifier).addLineItem(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Item'),
              ),
            ),
            AppSpacing.gapVerticalSm,

            if (state.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.gapVerticalSm,
                    Text(
                      'No line items yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapVerticalSm,
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(createInvoiceProvider.notifier).addLineItem(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Line Item'),
                    ),
                  ],
                ),
              )
            else
              ...state.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _LineItemCard(
                  key: ValueKey(index),
                  index: index,
                  item: item,
                  onUpdate: (updated) {
                    ref
                        .read(createInvoiceProvider.notifier)
                        .updateLineItem(index, updated);
                  },
                  onRemove: () {
                    ref.read(createInvoiceProvider.notifier).removeLineItem(index);
                  },
                  canRemove: state.items.length > 1,
                );
              }),

            AppSpacing.gapVerticalLg,

            // Tax Rate
            const _SectionHeader(
              title: 'Tax',
              subtitle: 'VAT percentage',
            ),
            AppSpacing.gapVerticalSm,
            _TaxRateField(
              value: state.taxRate,
              onChanged: (value) {
                ref.read(createInvoiceProvider.notifier).setTaxRate(value);
              },
            ),

            AppSpacing.gapVerticalLg,

            // Totals Preview
            _TotalsPreview(
              subtotal: state.subtotal,
              taxRate: state.taxRate,
              taxAmount: state.taxAmount,
              total: state.total,
            ),

            AppSpacing.gapVerticalLg,

            // Due Date
            const _SectionHeader(
              title: 'Due Date',
              subtitle: 'Payment due by',
            ),
            AppSpacing.gapVerticalSm,
            _DueDateField(
              value: state.dueDate,
              onChanged: (date) {
                ref.read(createInvoiceProvider.notifier).setDueDate(date);
              },
            ),

            AppSpacing.gapVerticalLg,

            // Notes
            const _SectionHeader(
              title: 'Notes',
              subtitle: 'Additional information for the client',
            ),
            AppSpacing.gapVerticalSm,
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Enter any notes...',
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
              ),
              maxLines: 3,
              onChanged: (value) {
                ref.read(createInvoiceProvider.notifier).setNotes(value);
              },
            ),

            AppSpacing.gapVerticalLg,

            // Payment Terms
            const _SectionHeader(
              title: 'Payment Terms',
              subtitle: 'Optional payment conditions',
            ),
            AppSpacing.gapVerticalSm,
            TextFormField(
              controller: _paymentTermsController,
              decoration: InputDecoration(
                hintText: 'e.g., Net 30, Due on receipt',
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
              ),
              onChanged: (value) {
                ref.read(createInvoiceProvider.notifier).setPaymentTerms(value);
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          child: FilledButton(
            onPressed: state.isSaving || state.items.isEmpty ? null : _createInvoice,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Draft Invoice'),
          ),
        ),
      ),
    );
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(createInvoiceProvider);

    // Validate we have client info
    if (state.selectedBooking == null &&
        (state.clientName == null || state.clientName!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a booking or enter client information'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate line items
    for (final item in state.items) {
      if (item.description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all line item descriptions'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    await ref.read(createInvoiceProvider.notifier).createInvoice();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
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
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _BookingSelector extends StatelessWidget {
  const _BookingSelector({
    required this.selectedBooking,
    required this.bookings,
    required this.isLoading,
    required this.onSelect,
  });

  final Booking? selectedBooking;
  final List<Booking> bookings;
  final bool isLoading;
  final void Function(Booking?) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading bookings...'),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Selected booking or "None"
          ListTile(
            leading: Icon(
              selectedBooking != null
                  ? Icons.calendar_today_rounded
                  : Icons.calendar_today_outlined,
              color: selectedBooking != null ? colorScheme.primary : null,
            ),
            title: Text(
              selectedBooking != null
                  ? '${dateFormat.format(selectedBooking!.date)} - ${selectedBooking!.clientName ?? 'No client'}'
                  : 'No booking selected',
            ),
            subtitle: selectedBooking?.propertyAddress != null
                ? Text(
                    selectedBooking!.propertyAddress!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: selectedBooking != null
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => onSelect(null),
                  )
                : const Icon(Icons.expand_more_rounded),
            onTap: () => _showBookingPicker(context),
          ),
        ],
      ),
    );
  }

  void _showBookingPicker(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Text(
                    'Select Booking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: bookings.isEmpty
                  ? const Center(
                      child: Text('No bookings available'),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final isSelected = booking.id == selectedBooking?.id;

                        return ListTile(
                          selected: isSelected,
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.calendar_today_outlined,
                          ),
                          title: Text(
                            '${dateFormat.format(booking.date)} - ${booking.clientName ?? 'No client'}',
                          ),
                          subtitle: booking.propertyAddress != null
                              ? Text(
                                  booking.propertyAddress!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () {
                            onSelect(booking);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard({
    required this.clientName,
    required this.clientEmail,
    required this.fromBooking,
  });

  final String? clientName;
  final String? clientEmail;
  final bool fromBooking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasInfo = clientName != null || clientEmail != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasInfo
            ? colorScheme.primaryContainer.withOpacity(0.2)
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: hasInfo
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: hasInfo
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName ?? 'Unknown',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (clientEmail != null)
                        Text(
                          clientEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (fromBooking)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'From Booking',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            )
          : Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: Text(
                    'Select a booking above to auto-fill client information',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LineItemCard extends StatefulWidget {
  const _LineItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final CreateInvoiceLineItem item;
  final void Function(CreateInvoiceLineItem) onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<_LineItemCard> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(
      text: widget.item.quantity > 0 ? widget.item.quantity.toString() : '',
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice > 0
          ? (widget.item.unitPrice / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final priceText = _priceController.text.replaceAll(',', '.');
    final pricePounds = double.tryParse(priceText) ?? 0;
    final pricePence = (pricePounds * 100).round();

    widget.onUpdate(widget.item.copyWith(
      description: _descriptionController.text,
      quantity: quantity,
      unitPrice: pricePence,
    ),);
  }

  String _formatAmount(int pence) {
    final pounds = pence / 100;
    return '\u00A3${pounds.toStringAsFixed(2)}';
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${widget.index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.canRemove)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          AppSpacing.gapVerticalSm,

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'e.g., Property Survey',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => _updateItem(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
          AppSpacing.gapVerticalSm,

          // Quantity and Price row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: const OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _updateItem(),
                ),
              ),
              AppSpacing.gapHorizontalMd,
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Unit Price (\u00A3)',
                    hintText: '0.00',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: const OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  onChanged: (_) => _updateItem(),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Amount: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatAmount(widget.item.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaxRateField extends StatefulWidget {
  const _TaxRateField({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final void Function(double) onChanged;

  @override
  State<_TaxRateField> createState() => _TaxRateFieldState();
}

class _TaxRateFieldState extends State<_TaxRateField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Slider(
            value: widget.value,
            max: 25,
            divisions: 25,
            label: '${widget.value.toStringAsFixed(0)}%',
            onChanged: (value) {
              widget.onChanged(value);
              _controller.text = value.toStringAsFixed(0);
            },
          ),
        ),
        AppSpacing.gapHorizontalMd,
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              suffixText: '%',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusSm,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final rate = double.tryParse(value) ?? 0;
              if (rate >= 0 && rate <= 25) {
                widget.onChanged(rate);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _TotalsPreview extends StatelessWidget {
  const _TotalsPreview({
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
  });

  final int subtotal;
  final double taxRate;
  final int taxAmount;
  final int total;

  String _formatAmount(int pence) {
    final pounds = pence / 100;
    return '\u00A3${pounds.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatAmount(subtotal),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          AppSpacing.gapVerticalXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VAT (${taxRate.toStringAsFixed(0)}%)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatAmount(taxAmount),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          AppSpacing.gapVerticalSm,
          Divider(color: colorScheme.outlineVariant),
          AppSpacing.gapVerticalSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatAmount(total),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final void Function(DateTime?) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.calendar_month_rounded,
          color: value != null ? colorScheme.primary : null,
        ),
        title: Text(
          value != null ? dateFormat.format(value!) : 'Select due date',
        ),
        trailing: value != null
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => onChanged(null),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now().add(const Duration(days: 30)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (date != null) {
            onChanged(date);
          }
        },
      ),
    );
  }
}
