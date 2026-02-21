import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../data/datasources/exports_datasource.dart';
import '../providers/exports_provider.dart';

/// Status options for each export type
const _bookingStatuses = ['PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'];
const _invoiceStatuses = ['DRAFT', 'ISSUED', 'PAID', 'CANCELLED'];
const _reportStatuses = [
  'DRAFT',
  'IN_PROGRESS',
  'PAUSED',
  'COMPLETED',
  'PENDING_REVIEW',
  'APPROVED',
  'REJECTED',
];

class AdminExportsPage extends ConsumerStatefulWidget {
  const AdminExportsPage({super.key});

  @override
  ConsumerState<AdminExportsPage> createState() => _AdminExportsPageState();
}

class _AdminExportsPageState extends ConsumerState<AdminExportsPage> {
  ExportEntityType _selectedEntity = ExportEntityType.bookings;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exportState = ref.watch(exportsProvider);

    // Listen for errors
    ref.listen<ExportState>(exportsProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(exportsProvider.notifier).clearError();
      }

      if (next.lastExportedFile != null &&
          previous?.lastExportedFile != next.lastExportedFile &&
          !next.isExporting) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported: ${next.lastExportedFile}'),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Data Export'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Export data to CSV format. Files can be opened in Google Sheets, Excel, or any spreadsheet application.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Entity type selector
            _SectionCard(
              title: 'Export Type',
              child: SegmentedButton<ExportEntityType>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.comfortable,
                ),
                segments: const [
                  ButtonSegment(
                    value: ExportEntityType.bookings,
                    label: Text('Bookings'),
                  ),
                  ButtonSegment(
                    value: ExportEntityType.invoices,
                    label: Text('Invoices'),
                  ),
                  ButtonSegment(
                    value: ExportEntityType.reports,
                    label: Text('Reports'),
                  ),
                ],
                selected: {_selectedEntity},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedEntity = selection.first;
                    _selectedStatus = null; // Reset status when entity changes
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Filters
            _SectionCard(
              title: 'Filters (Optional)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Date range
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'Start Date',
                          value: _startDate,
                          onChanged: (date) => setState(() => _startDate = date),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _DatePickerField(
                          label: 'End Date',
                          value: _endDate,
                          onChanged: (date) => setState(() => _endDate = date),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Status filter
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStatus,
                    items: [
                      const DropdownMenuItem(
                        child: Text('All Statuses'),
                      ),
                      ..._getStatusOptions().map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedStatus = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Export button
            FilledButton.icon(
              onPressed: exportState.isExporting ? null : _handleExport,
              icon: exportState.isExporting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                exportState.isExporting ? 'Exporting...' : 'Export to CSV',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Limit info
            Text(
              'Maximum 5,000 rows per export',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getStatusOptions() {
    switch (_selectedEntity) {
      case ExportEntityType.bookings:
        return _bookingStatuses;
      case ExportEntityType.invoices:
        return _invoiceStatuses;
      case ExportEntityType.reports:
        return _reportStatuses;
    }
  }

  Future<void> _handleExport() async {
    // Validate date range
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start date must be before end date'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(exportsProvider.notifier).exportData(
          entityType: _selectedEntity,
          startDate: _startDate,
          endDate: _endDate,
          status: _selectedStatus,
        );
  }
}

/// Section card wrapper
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// Date picker field
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = value != null
        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_month_rounded, size: 20),
        ),
        child: Text(
          displayText.isEmpty ? ' ' : displayText,
          style: theme.textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}
