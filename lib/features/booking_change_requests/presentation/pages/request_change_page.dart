import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/booking_change_request.dart';
import '../providers/booking_change_request_providers.dart';

/// Client's Request Change Form Page
class RequestChangePage extends ConsumerStatefulWidget {
  const RequestChangePage({
    super.key,
    required this.bookingId,
    this.bookingDate,
    this.bookingTime,
    this.propertyAddress,
  });

  final String bookingId;
  final String? bookingDate;
  final String? bookingTime;
  final String? propertyAddress;

  @override
  ConsumerState<RequestChangePage> createState() => _RequestChangePageState();
}

class _RequestChangePageState extends ConsumerState<RequestChangePage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  BookingChangeRequestType _requestType = BookingChangeRequestType.reschedule;
  DateTime? _proposedDate;
  TimeOfDay? _proposedStartTime;
  TimeOfDay? _proposedEndTime;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectProposedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _proposedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _proposedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _proposedStartTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _proposedStartTime = picked;
        // Auto-set end time if not set
        _proposedEndTime ??= TimeOfDay(
            hour: (picked.hour + 2) % 24,
            minute: picked.minute,
          );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _proposedEndTime ??
          _proposedStartTime ??
          const TimeOfDay(hour: 11, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _proposedEndTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate reschedule fields
    if (_requestType.isReschedule) {
      if (_proposedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a proposed date'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_proposedStartTime == null || _proposedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select proposed time'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final success = await ref
        .read(createChangeRequestNotifierProvider.notifier)
        .submit(
          bookingId: widget.bookingId,
          type: _requestType,
          proposedDate: _requestType.isReschedule ? _proposedDate : null,
          proposedStartTime: _requestType.isReschedule && _proposedStartTime != null
              ? _formatTimeOfDay(_proposedStartTime!)
              : null,
          proposedEndTime: _requestType.isReschedule && _proposedEndTime != null
              ? _formatTimeOfDay(_proposedEndTime!)
              : null,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        );

    if (success && mounted) {
      // Refresh the list
      ref.read(clientChangeRequestsNotifierProvider.notifier).refresh();

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _requestType.isReschedule
                ? 'Reschedule request submitted successfully!'
                : 'Cancellation request submitted successfully!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(createChangeRequestNotifierProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Request Change',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
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
                          Icons.event_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Booking',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.bookingDate != null)
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: widget.bookingDate!,
                      ),
                    if (widget.bookingTime != null)
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Time',
                        value: widget.bookingTime!,
                      ),
                    if (widget.propertyAddress != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: widget.propertyAddress!,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Request Type
              Text(
                'What would you like to do?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              _RequestTypeOption(
                type: BookingChangeRequestType.reschedule,
                title: 'Reschedule',
                description: 'Request a different date and time',
                icon: Icons.schedule_rounded,
                isSelected: _requestType == BookingChangeRequestType.reschedule,
                onTap: () => setState(
                    () => _requestType = BookingChangeRequestType.reschedule,),
              ),
              const SizedBox(height: 12),
              _RequestTypeOption(
                type: BookingChangeRequestType.cancel,
                title: 'Cancel',
                description: 'Request to cancel this booking',
                icon: Icons.cancel_outlined,
                isSelected: _requestType == BookingChangeRequestType.cancel,
                onTap: () => setState(
                    () => _requestType = BookingChangeRequestType.cancel,),
              ),

              const SizedBox(height: 24),

              // Reschedule fields
              if (_requestType.isReschedule) ...[
                Text(
                  'Proposed New Date & Time',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Date picker
                _DatePickerField(
                  label: 'Proposed Date',
                  date: _proposedDate,
                  onTap: _selectProposedDate,
                ),

                const SizedBox(height: 12),

                // Time pickers
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerField(
                        label: 'Start Time',
                        time: _proposedStartTime,
                        onTap: _selectStartTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerField(
                        label: 'End Time',
                        time: _proposedEndTime,
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],

              // Reason
              Text(
                _requestType.isReschedule
                    ? 'Reason for Reschedule (Optional)'
                    : 'Reason for Cancellation (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: _requestType.isReschedule
                      ? 'Why do you need to reschedule?'
                      : 'Why do you need to cancel?',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                maxLength: 500,
              ),

              const SizedBox(height: 32),

              // Error Message
              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _requestType.isCancel
                        ? colorScheme.error
                        : colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          _requestType.isReschedule
                              ? 'Submit Reschedule Request'
                              : 'Submit Cancellation Request',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTypeOption extends StatelessWidget {
  const _RequestTypeOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final BookingChangeRequestType type;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = type.isCancel ? colorScheme.error : colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colorScheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date!.day}/${date!.month}/${date!.year}'
                        : 'Select date',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: date != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: date != null ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time != null ? _formatTime(time!) : 'Select time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: time != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontWeight: time != null ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
